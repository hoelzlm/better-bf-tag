import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const SCRIPT_MARKER = 'GEHEIM-PUSH-789';

interface BfDayJson {
  id: string;
  state: 'planning' | 'running' | 'ended';
}

interface ShiftJson {
  id: string;
  bf_day_id: string;
  starts_at: string;
  ends_at: string;
  crew: Array<{ vehicle_id: string; person_id: string; display_name: string; function: string }>;
}

interface VehicleJson {
  id: string;
  call_sign: string;
  active: boolean;
  sort_order: number;
}

interface IncidentJson {
  id: string;
  bf_day_id: string;
  state: string;
  script?: string;
}

interface AlarmJson {
  id: string;
  incident_id: string;
  state: string;
  triggered_at: string | null;
  vehicle_ids: string[];
  recipients: Array<{ person_id: string; display_name: string }>;
  push_delivered: number;
  push_rejected: number;
}

interface TriggerAlarmResponse {
  alarm: AlarmJson;
  double_crewed: unknown[];
}

describe('push', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;
  let dispatchToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    pool = new Pool({ connectionString: app.databaseUrl });

    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'dispatch-push',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'dispatch-push', 'dispatch-password');
  });

  afterAll(async () => {
    await pool.end();
    await app.close();
  });

  async function createBfDay(name: string): Promise<BfDayJson> {
    const startsAt = app.clock.now();
    const endsAt = new Date(startsAt.getTime() + DAY_MS);
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
    await pool.query(`update bf_day set state = 'ended' where state = 'running' and id != $1`, [
      id,
    ]);
    const res = await app.client().post(`/api/v1/bf-days/${id}/start`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function getDefaultShift(bfDayId: string): Promise<ShiftJson> {
    const res = await app
      .client()
      .get(`/api/v1/bf-days/${bfDayId}/shifts`, { token: dispatchToken });
    expect(res.status).toBe(200);
    const shifts = res.body as ShiftJson[];
    expect(shifts).toHaveLength(1);
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

  async function createParticipant(username: string): Promise<string> {
    const person = await createPerson(app, {
      displayName: username,
      personType: 'youth',
      permission: 'crew',
      username,
      password: 'participant-password',
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

  async function setCrew(
    shiftId: string,
    assignments: Array<{ vehicle_id: string; person_id: string; function: string }>
  ): Promise<void> {
    const res = await app
      .client()
      .put(`/api/v1/shifts/${shiftId}/crew`, { assignments }, { token: dispatchToken });
    expect(res.status).toBe(200);
  }

  /** Pairs a brand-new Device for the given Person via the real /auth/pair flow. */
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

  async function createIncident(bfDayId: string, script?: string): Promise<IncidentJson> {
    const res = await app.client().post(
      `/api/v1/bf-days/${bfDayId}/incidents`,
      {
        keyword: 'Wohnungsbrand',
        address: 'Musterstraße 1',
        report: 'Rauch aus dem Fenster',
        ...(script !== undefined ? { script } : {}),
      },
      { token: dispatchToken }
    );
    expect(res.status).toBe(201);
    return res.body as IncidentJson;
  }

  async function triggerAlarm(
    incidentId: string,
    vehicleIds: string[],
    opts?: { id?: string }
  ): Promise<{ status: number; body: TriggerAlarmResponse }> {
    const res = await app
      .client()
      .post(
        `/api/v1/incidents/${incidentId}/alarms`,
        { vehicle_ids: vehicleIds, ...(opts?.id !== undefined ? { id: opts.id } : {}) },
        { token: dispatchToken }
      );
    return { status: res.status, body: res.body as TriggerAlarmResponse };
  }

  let counter = 0;
  function uniqueToken(label: string): string {
    counter += 1;
    return `push-token-${label}-${counter}`;
  }

  it('PUT /me/device/push-token: 204 for device session, 403 for web session, moves token between devices', async () => {
    const personId = await createParticipant('push-token-person');
    const day = await createBfDay('PushToken');
    await setParticipants(day.id, [personId]);
    const { token: deviceAToken } = await pairDevice(personId);
    const { deviceId: deviceBId, token: deviceBToken } = await pairDevice(personId);

    const webRes = await app
      .client()
      .put('/api/v1/me/device/push-token', { token: uniqueToken('web') }, { token: adminToken });
    expect(webRes.status).toBe(403);
    expect((webRes.body as { error: { code: string } }).error.code).toBe('forbidden');

    const sharedToken = uniqueToken('shared');
    await setPushToken(deviceAToken, sharedToken);

    // Device B claims the same token (e.g. reinstall): Device A must lose it.
    await setPushToken(deviceBToken, sharedToken);

    const [rowA, rowB] = await Promise.all([
      pool.query(`select push_token from device where id != $1 and person_id = $2`, [
        deviceBId,
        personId,
      ]),
      pool.query(`select push_token from device where id = $1`, [deviceBId]),
    ]);
    expect(rowA.rows[0]?.push_token).toBeNull();
    expect(rowB.rows[0]?.push_token).toBe(sharedToken);
  });

  it('builds a running BF-Tag with crewed vehicles, double crew, two devices, and sends exactly one push per device', async () => {
    const day = await createBfDay('PushAlarm');
    const shift = await getDefaultShift(day.id);
    const v1 = await createVehicle('PushAlarm-V1');
    const v2 = await createVehicle('PushAlarm-V2');

    const p1 = await createParticipant('push-p1'); // one device, token set
    const p2 = await createParticipant('push-p2'); // double-crewed, one device
    const p3 = await createParticipant('push-p3'); // two devices, both with tokens
    const p4 = await createParticipant('push-p4'); // device without a token
    const p5 = await createParticipant('push-p5'); // revoked device
    const bystander = await createParticipant('push-bystander'); // not a recipient

    await setParticipants(day.id, [p1, p2, p3, p4, p5, bystander]);

    const device1 = await pairDevice(p1);
    const device2 = await pairDevice(p2);
    const device3a = await pairDevice(p3);
    const device3b = await pairDevice(p3);
    const device4 = await pairDevice(p4); // no token set
    const device5 = await pairDevice(p5);
    const bystanderDevice = await pairDevice(bystander);

    const token1 = uniqueToken('p1');
    const token2 = uniqueToken('p2');
    const token3a = uniqueToken('p3a');
    const token3b = uniqueToken('p3b');
    const token5 = uniqueToken('p5');
    const tokenBystander = uniqueToken('bystander');
    await setPushToken(device1.token, token1);
    await setPushToken(device2.token, token2);
    await setPushToken(device3a.token, token3a);
    await setPushToken(device3b.token, token3b);
    await setPushToken(device5.token, token5);
    await setPushToken(bystanderDevice.token, tokenBystander);

    await revokeDevice(device5.deviceId);

    // p2 sits on both alarmed vehicles (Doppelbesetzung), p3 only on v2.
    await setCrew(shift.id, [
      { vehicle_id: v1.id, person_id: p1, function: 'GF' },
      { vehicle_id: v1.id, person_id: p2, function: 'MA' },
      { vehicle_id: v2.id, person_id: p2, function: 'GF' },
      { vehicle_id: v2.id, person_id: p3, function: 'MA' },
      { vehicle_id: v2.id, person_id: p4, function: 'ATF' },
      { vehicle_id: v2.id, person_id: p5, function: 'ATM' },
    ]);

    await startBfDay(day.id);
    const incident = await createIncident(day.id, SCRIPT_MARKER);

    const ws = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      const res = await triggerAlarm(incident.id, [v1.id, v2.id]);
      expect(res.status).toBe(201);
      expect(res.body.alarm.push_delivered).toBe(4); // p1, p2, p3 (x2 devices)
      expect(res.body.alarm.push_rejected).toBe(0);

      const sentDeviceIds = app.push.sent.map(m => m.deviceId);
      expect(sentDeviceIds.sort()).toEqual(
        [device1.deviceId, device2.deviceId, device3a.deviceId, device3b.deviceId].sort()
      );
      // Non-recipient, no-token, and revoked devices never got a push.
      expect(sentDeviceIds).not.toContain(device4.deviceId);
      expect(sentDeviceIds).not.toContain(device5.deviceId);
      expect(sentDeviceIds).not.toContain(bystanderDevice.deviceId);
      // Exactly one push per device, including the double-crewed p2.
      expect(app.push.sentTo(device2.deviceId)).toHaveLength(1);

      for (const message of app.push.sent) {
        const raw = JSON.stringify(message);
        expect(raw).toContain(incident.id);
        expect(raw).toContain(res.body.alarm.id);
        expect(raw).toContain('Wohnungsbrand');
        expect(raw).toContain('Musterstraße 1');
        expect(raw.includes(SCRIPT_MARKER)).toBe(false);
        expect(raw.includes('"script"')).toBe(false);
        expect(raw.includes('"display_name"')).toBe(false);
      }

      const reportedEvent = await ws.next(m => m.type === 'alarm.push_reported');
      expect(reportedEvent.data).toEqual({
        alarm_id: res.body.alarm.id,
        incident_id: incident.id,
        push_delivered: 4,
        push_rejected: 0,
      });

      const snapshot = await app.client().get('/api/v1/snapshot', { token: dispatchToken });
      const snapAlarm = (snapshot.body as { alarms: AlarmJson[] }).alarms.find(
        a => a.id === res.body.alarm.id
      );
      expect(snapAlarm?.push_delivered).toBe(4);
      expect(snapAlarm?.push_rejected).toBe(0);

      // Idempotent repeat sends no additional push.
      app.push.clear();
      const repeat = await triggerAlarm(incident.id, [v1.id, v2.id], { id: res.body.alarm.id });
      expect(repeat.status).toBe(200);
      expect(app.push.sent).toHaveLength(0);
    } finally {
      ws.close();
    }
  });

  it('an invalid token counts as rejected, is cleared, and receives nothing on the next alarm', async () => {
    const day = await createBfDay('PushInvalid');
    const shift = await getDefaultShift(day.id);
    const v1 = await createVehicle('PushInvalid-V1');
    const p1 = await createParticipant('push-invalid-p1');
    await setParticipants(day.id, [p1]);

    const device1 = await pairDevice(p1);
    const token1 = uniqueToken('invalid');
    await setPushToken(device1.token, token1);
    app.push.markInvalid(token1);

    await setCrew(shift.id, [{ vehicle_id: v1.id, person_id: p1, function: 'GF' }]);
    await startBfDay(day.id);
    const incident = await createIncident(day.id);

    const first = await triggerAlarm(incident.id, [v1.id]);
    expect(first.status).toBe(201);
    expect(first.body.alarm.push_delivered).toBe(0);
    expect(first.body.alarm.push_rejected).toBe(1);

    const [deviceRow] = (
      await pool.query(`select push_token from device where id = $1`, [device1.deviceId])
    ).rows;
    expect(deviceRow?.push_token).toBeNull();

    // Second alarm: the device no longer has a token, so nothing is sent to it.
    app.push.clear();
    const incident2 = await createIncident(day.id);
    const second = await triggerAlarm(incident2.id, [v1.id]);
    expect(second.status).toBe(201);
    expect(second.body.alarm.push_delivered).toBe(0);
    expect(second.body.alarm.push_rejected).toBe(0);
    expect(app.push.sentTo(device1.deviceId)).toHaveLength(0);
  });
});
