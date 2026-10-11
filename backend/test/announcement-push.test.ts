import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';

interface BfDayJson {
  id: string;
  state: 'planning' | 'running' | 'ended';
}

interface ShiftJson {
  id: string;
}

interface VehicleJson {
  id: string;
}

interface AnnouncementJson {
  id: string;
  bf_day_id: string;
  shift_id: string | null;
  text: string;
  created_by: string;
  created_at: string;
}

describe('announcement push', () => {
  let app: TestApp;
  let adminToken: string;
  let dispatchPersonId: string;
  let dispatchToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');

    const dispatchPerson = await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'annpush-dispatch',
      password: 'dispatch-password',
    });
    dispatchPersonId = dispatchPerson.id;
    dispatchToken = await loginAs(app, 'annpush-dispatch', 'dispatch-password');
  });

  afterAll(async () => {
    await app.close();
  });

  async function createBfDay(name: string): Promise<BfDayJson> {
    const startsAt = new Date('2026-06-01T08:00:00Z');
    const endsAt = new Date(startsAt.getTime() + 24 * 60 * 60 * 1000);
    const res = await app
      .client()
      .post(
        '/api/v1/bf-days',
        { name, starts_at: startsAt.toISOString(), ends_at: endsAt.toISOString() },
        { token: adminToken }
      );
    expect(res.status).toBe(201);
    return res.body as BfDayJson;
  }

  async function startBfDay(id: string): Promise<void> {
    const res = await app.client().post(`/api/v1/bf-days/${id}/start`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function endBfDay(id: string): Promise<void> {
    const res = await app.client().post(`/api/v1/bf-days/${id}/end`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function getDefaultShift(bfDayId: string): Promise<ShiftJson> {
    const res = await app
      .client()
      .get(`/api/v1/bf-days/${bfDayId}/shifts`, { token: dispatchToken });
    expect(res.status).toBe(200);
    const shifts = res.body as ShiftJson[];
    expect(shifts.length).toBeGreaterThan(0);
    return shifts[0] as ShiftJson;
  }

  async function createVehicle(callSign: string): Promise<VehicleJson> {
    const res = await app
      .client()
      .post(
        '/api/v1/vehicles',
        { call_sign: callSign, short_name: callSign, type: 'HLF' },
        { token: adminToken }
      );
    expect(res.status).toBe(201);
    return res.body as VehicleJson;
  }

  async function createPersonWithPermission(
    username: string,
    permission: 'crew' | 'preparation' | 'dispatch' | 'admin'
  ): Promise<string> {
    const personType = permission === 'crew' ? 'youth' : 'supervisor';
    const person = await createPerson(app, {
      displayName: username,
      personType,
      permission,
      username,
      password: `${username}-password`,
    });
    return person.id;
  }

  async function setParticipants(bfDayId: string, personIds: string[]): Promise<void> {
    const res = await app
      .client()
      .put(
        `/api/v1/bf-days/${bfDayId}/participants`,
        { person_ids: personIds },
        { token: adminToken }
      );
    expect(res.status).toBe(200);
  }

  async function assignCrew(shiftId: string, personId: string, vehicleId: string): Promise<void> {
    const res = await app
      .client()
      .put(
        `/api/v1/shifts/${shiftId}/crew`,
        { assignments: [{ vehicle_id: vehicleId, person_id: personId, function: 'GF' }] },
        { token: dispatchToken }
      );
    expect(res.status).toBe(200);
  }

  async function pairDevice(personId: string): Promise<{ deviceId: string; token: string }> {
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${personId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app
      .client()
      .post('/api/v1/auth/pair', { code, platform: 'android', app_version: '1.0.0' });
    expect(pairRes.status).toBe(200);
    return {
      deviceId: (pairRes.body as { device_id: string }).device_id,
      token: (pairRes.body as { access_token: string }).access_token,
    };
  }

  async function setPushToken(deviceAccessToken: string, token: string): Promise<void> {
    const res = await app
      .client()
      .put('/api/v1/me/device/push-token', { token }, { token: deviceAccessToken });
    expect(res.status).toBe(204);
  }

  async function revokeDevice(deviceId: string): Promise<void> {
    const res = await app.client().delete(`/api/v1/devices/${deviceId}`, { token: adminToken });
    expect(res.status).toBe(204);
  }

  async function createAnnouncement(
    bfDayId: string,
    body: { text: string; shift_id?: string | null },
    token: string = dispatchToken
  ): Promise<AnnouncementJson> {
    const res = await app
      .client()
      .post(`/api/v1/bf-days/${bfDayId}/announcements`, body, { token });
    expect(res.status).toBe(201);
    return res.body as AnnouncementJson;
  }

  let counter = 0;
  function uniqueToken(label: string): string {
    counter += 1;
    return `ann-push-token-${label}-${counter}`;
  }

  /** Polls `app.push.sent` briefly: dispatch happens after the response, not
   * synchronously inside the POST. */
  async function waitForPush(predicate: () => boolean, timeoutMs = 2000): Promise<void> {
    const start = Date.now();
    while (!predicate()) {
      if (Date.now() - start > timeoutMs) {
        throw new Error('waitForPush: timed out waiting for expected push state');
      }
      await new Promise(resolve => setTimeout(resolve, 20));
    }
  }

  it("an all-announcement reaches every participant device except the sender's; non-participants, revoked, and tokenless devices get nothing; data.type is announcement.created", async () => {
    const day = await createBfDay(`AllAnn ${Math.random()}`);

    const p1 = await createPersonWithPermission(uniqueToken('p1').replace(/-/g, ''), 'crew');
    const p2 = await createPersonWithPermission(uniqueToken('p2').replace(/-/g, ''), 'crew');
    const p3NoToken = await createPersonWithPermission(uniqueToken('p3').replace(/-/g, ''), 'crew');
    const p4Revoked = await createPersonWithPermission(uniqueToken('p4').replace(/-/g, ''), 'crew');
    const bystander = await createPersonWithPermission(
      uniqueToken('bystander').replace(/-/g, ''),
      'crew'
    );

    await setParticipants(day.id, [p1, p2, p3NoToken, p4Revoked, dispatchPersonId]);

    const device1 = await pairDevice(p1);
    const device2 = await pairDevice(p2);
    const device3 = await pairDevice(p3NoToken); // no push token set
    const device4 = await pairDevice(p4Revoked);
    const senderDevice = await pairDevice(dispatchPersonId);
    const bystanderDevice = await pairDevice(bystander); // not a participant

    const token1 = uniqueToken('dev1');
    const token2 = uniqueToken('dev2');
    const token4 = uniqueToken('dev4');
    const senderToken = uniqueToken('sender');
    const bystanderToken = uniqueToken('bystander-dev');
    await setPushToken(device1.token, token1);
    await setPushToken(device2.token, token2);
    await setPushToken(device4.token, token4);
    await setPushToken(senderDevice.token, senderToken);
    await setPushToken(bystanderDevice.token, bystanderToken);

    await revokeDevice(device4.deviceId);

    await startBfDay(day.id);

    app.push.clear();
    const announcement = await createAnnouncement(day.id, { text: 'Achtung alle' });

    await waitForPush(() => app.push.sent.length >= 2);

    const sentDeviceIds = app.push.sent.map(m => m.deviceId);
    expect(sentDeviceIds.sort()).toEqual([device1.deviceId, device2.deviceId].sort());
    expect(sentDeviceIds).not.toContain(device3.deviceId);
    expect(sentDeviceIds).not.toContain(device4.deviceId);
    expect(sentDeviceIds).not.toContain(senderDevice.deviceId);
    expect(sentDeviceIds).not.toContain(bystanderDevice.deviceId);

    for (const message of app.push.sent) {
      expect(message.data.type).toBe('announcement.created');
      expect(message.data.type).not.toBe('alarm.triggered');
      if (message.data.type === 'announcement.created') {
        expect(message.data.announcement_id).toBe(announcement.id);
        expect(message.data.bf_day_id).toBe(day.id);
        expect(message.data.text).toBe('Achtung alle');
      }
    }

    await endBfDay(day.id);
  });

  it('a shift announcement reaches only the crew of that shift and preparation/dispatch/admin participants, not an unassigned crew person', async () => {
    const day = await createBfDay(`ShiftAnn ${Math.random()}`);
    const shift = await getDefaultShift(day.id);
    const vehicle = await createVehicle(`ShiftAnn-V-${Math.random().toString(36).slice(2, 8)}`);

    const crewMember = await createPersonWithPermission(
      uniqueToken('crew').replace(/-/g, ''),
      'crew'
    );
    const unassignedCrew = await createPersonWithPermission(
      uniqueToken('unassigned').replace(/-/g, ''),
      'crew'
    );
    const preparationPerson = await createPersonWithPermission(
      uniqueToken('prep').replace(/-/g, ''),
      'preparation'
    );
    const adminPerson = await createPersonWithPermission(
      uniqueToken('admin').replace(/-/g, ''),
      'admin'
    );

    await setParticipants(day.id, [
      crewMember,
      unassignedCrew,
      preparationPerson,
      adminPerson,
      dispatchPersonId,
    ]);
    await assignCrew(shift.id, crewMember, vehicle.id);

    const crewDevice = await pairDevice(crewMember);
    const unassignedDevice = await pairDevice(unassignedCrew);
    const preparationDevice = await pairDevice(preparationPerson);
    const adminDevice = await pairDevice(adminPerson);

    await setPushToken(crewDevice.token, uniqueToken('crew-tok'));
    await setPushToken(unassignedDevice.token, uniqueToken('unassigned-tok'));
    await setPushToken(preparationDevice.token, uniqueToken('prep-tok'));
    await setPushToken(adminDevice.token, uniqueToken('admin-tok'));

    await startBfDay(day.id);

    app.push.clear();
    await createAnnouncement(day.id, { text: 'Nur Schicht', shift_id: shift.id });

    await waitForPush(() => app.push.sent.length >= 3);

    const sentDeviceIds = app.push.sent.map(m => m.deviceId);
    expect(sentDeviceIds.sort()).toEqual(
      [crewDevice.deviceId, preparationDevice.deviceId, adminDevice.deviceId].sort()
    );
    expect(sentDeviceIds).not.toContain(unassignedDevice.deviceId);

    await endBfDay(day.id);
  });

  it('a failing/throwing push sender still yields 201 on the POST', async () => {
    const day = await createBfDay(`ThrowAnn ${Math.random()}`);
    const participant = await createPersonWithPermission(
      uniqueToken('throwp').replace(/-/g, ''),
      'crew'
    );
    await setParticipants(day.id, [participant]);
    const participantDevice = await pairDevice(participant);
    await setPushToken(participantDevice.token, uniqueToken('throw-tok'));

    await startBfDay(day.id);

    app.push.clear();
    app.push.throwOnSend();
    try {
      const res = await app
        .client()
        .post(
          `/api/v1/bf-days/${day.id}/announcements`,
          { text: 'Trotz Fehler' },
          { token: dispatchToken }
        );
      expect(res.status).toBe(201);
    } finally {
      app.push.stopThrowing();
    }

    await endBfDay(day.id);
  });
});
