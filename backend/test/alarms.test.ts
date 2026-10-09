import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const SCRIPT_MARKER = 'GEHEIM-ALARM-456';

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

interface AlarmRecipientJson {
  person_id: string;
  display_name: string;
  vehicle_id: string;
  function: string;
  has_device: boolean;
  acknowledged_at: string | null;
}

interface AlarmJson {
  id: string;
  incident_id: string;
  state: string;
  scheduled_at: string | null;
  triggered_at: string | null;
  vehicle_ids: string[];
  recipients: AlarmRecipientJson[];
}

interface TriggerAlarmResponse {
  alarm: AlarmJson;
  double_crewed: Array<{ person_id: string; display_name: string; vehicle_ids: string[] }>;
}

/** Checks that neither the `script` key nor the Drehbuch marker leaked, per ADR 0016. */
function assertNoScript(raw: string): void {
  expect(raw.includes('"script"')).toBe(false);
  expect(raw.includes(SCRIPT_MARKER)).toBe(false);
}

describe('alarms', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;
  let dispatchToken: string;
  let preparationToken: string;
  let crewToken: string; // not a recipient of anything, used for permission/403 checks

  beforeAll(async () => {
    app = await startTestApp();
    pool = new Pool({ connectionString: app.databaseUrl });

    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'dispatch1', 'dispatch-password');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'prep1',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'prep1', 'prep-password');

    const bystander = await createPerson(app, {
      displayName: 'Unbeteiligt',
      personType: 'youth',
      permission: 'crew',
      username: 'bystander',
      password: 'bystander-password',
    });
    crewToken = await signTestAccessToken(app, bystander.id, 'crew');
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
    // At most one BF-Tag may be `running` at a time; end whichever one is
    // currently running (if any, from an earlier test in this file) first.
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
  async function pairDevice(personId: string): Promise<{ deviceId: string }> {
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${personId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app
      .client()
      .post('/api/v1/auth/pair', { code, platform: 'android', app_version: '1.0.0' });
    expect(pairRes.status).toBe(200);
    return { deviceId: (pairRes.body as { device_id: string }).device_id };
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
      { token: preparationToken }
    );
    expect(res.status).toBe(201);
    return res.body as IncidentJson;
  }

  async function triggerAlarm(
    incidentId: string,
    vehicleIds: string[],
    opts?: { id?: string; token?: string }
  ): Promise<{ status: number; body: TriggerAlarmResponse | { error: { code: string } } }> {
    const res = await app
      .client()
      .post(
        `/api/v1/incidents/${incidentId}/alarms`,
        { vehicle_ids: vehicleIds, ...(opts?.id !== undefined ? { id: opts.id } : {}) },
        { token: opts?.token ?? dispatchToken }
      );
    return { status: res.status, body: res.body as TriggerAlarmResponse };
  }

  /** Builds a fully running BF-Tag with two crewed vehicles and a Doppelbesetzung. */
  async function setupAlarmedIncident(label: string): Promise<{
    day: BfDayJson;
    incident: IncidentJson;
    v1: VehicleJson;
    v2: VehicleJson;
    p1: string;
    p2: string;
    p3: string;
    device1: string;
    device2: string;
  }> {
    const day = await createBfDay(label);
    const shift = await getDefaultShift(day.id);
    const v1 = await createVehicle(`${label}-V1`);
    const v2 = await createVehicle(`${label}-V2`);

    const p1 = await createParticipant(`${label}-p1`);
    const p2 = await createParticipant(`${label}-p2`);
    const p3 = await createParticipant(`${label}-p3`);
    await setParticipants(day.id, [p1, p2, p3]);

    const { deviceId: device1 } = await pairDevice(p1);
    const { deviceId: device2 } = await pairDevice(p2);
    await revokeDevice(device2);

    // p2 sits on both alarmed vehicles (Doppelbesetzung), listed first on v1
    // (lower sort_order) per ADR 0017.
    await setCrew(shift.id, [
      { vehicle_id: v1.id, person_id: p1, function: 'GF' },
      { vehicle_id: v1.id, person_id: p2, function: 'MA' },
      { vehicle_id: v2.id, person_id: p2, function: 'GF' },
      { vehicle_id: v2.id, person_id: p3, function: 'MA' },
    ]);

    await startBfDay(day.id);
    const incident = await createIncident(day.id, SCRIPT_MARKER);

    return { day, incident, v1, v2, p1, p2, p3, device1, device2 };
  }

  it('happy path: draft->running, 201, recipients frozen, has_device, double_crewed, event order', async () => {
    const { incident, v1, v2, p1, p2, p3 } = await setupAlarmedIncident('Happy');

    const ws = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      const res = await triggerAlarm(incident.id, [v1.id, v2.id]);
      expect(res.status).toBe(201);
      const body = res.body as TriggerAlarmResponse;
      expect(body.alarm.state).toBe('triggered');
      expect(body.alarm.triggered_at).not.toBeNull();
      expect(body.alarm.vehicle_ids).toEqual([v1.id, v2.id]);
      expect(body.alarm.recipients).toHaveLength(3);

      const byPerson = new Map(body.alarm.recipients.map(r => [r.person_id, r]));
      expect(byPerson.get(p1)).toMatchObject({
        function: 'GF',
        vehicle_id: v1.id,
        has_device: true,
      });
      expect(byPerson.get(p2)).toMatchObject({
        function: 'MA',
        vehicle_id: v1.id,
        has_device: false,
      });
      expect(byPerson.get(p3)).toMatchObject({
        function: 'MA',
        vehicle_id: v2.id,
        has_device: false,
      });

      expect(body.double_crewed).toHaveLength(1);
      expect(body.double_crewed[0]?.person_id).toBe(p2);
      expect(body.double_crewed[0]?.vehicle_ids.slice().sort()).toEqual(
        [v1.id, v2.id].slice().sort()
      );

      const incidentUpdated = await ws.next(m => m.type === 'incident.updated');
      expect((incidentUpdated.data as IncidentJson).state).toBe('running');
      const alarmTriggered = await ws.next(m => m.type === 'alarm.triggered');
      expect((alarmTriggered.data as { alarm: AlarmJson }).alarm.id).toBe(body.alarm.id);
      expect((incidentUpdated.seq as number) < (alarmTriggered.seq as number)).toBe(true);

      const detail = await app
        .client()
        .get(`/api/v1/incidents/${incident.id}`, { token: dispatchToken });
      expect(detail.status).toBe(200);
      const detailBody = detail.body as IncidentJson & { alarms: AlarmJson[] };
      expect(detailBody.state).toBe('running');
      expect(detailBody.alarms).toHaveLength(1);
      expect(detailBody.alarms[0]?.id).toBe(body.alarm.id);
    } finally {
      ws.close();
    }
  });

  it('recipients stay frozen after the crew/shift changes', async () => {
    const dayStart = app.clock.now();
    try {
      const { day, incident, v1, v2, p1 } = await setupAlarmedIncident('Frozen');
      const triggered = await triggerAlarm(incident.id, [v1.id, v2.id]);
      expect(triggered.status).toBe(201);
      const original = (triggered.body as TriggerAlarmResponse).alarm;

      // A later shift (starts_at wins the "aktuelle Schicht" tie-break) with
      // a completely different crew, still inside the same BF-Tag.
      const laterStart = new Date(dayStart.getTime() + 12 * 60 * 60 * 1000);
      const laterEnd = new Date(dayStart.getTime() + DAY_MS);
      const shiftRes = await app.client().post(
        `/api/v1/bf-days/${day.id}/shifts`,
        {
          name: 'Nachtschicht',
          starts_at: laterStart.toISOString(),
          ends_at: laterEnd.toISOString(),
        },
        { token: dispatchToken }
      );
      expect(shiftRes.status).toBe(201);
      app.clock.set(new Date(laterStart.getTime() + 60_000));

      // Access tokens have a 15-minute TTL (business clock); re-mint one
      // after jumping forward 12h so these reads aren't rejected as expired.
      const freshDispatchToken = await loginAs(app, 'dispatch1', 'dispatch-password');

      const detail = await app
        .client()
        .get(`/api/v1/incidents/${incident.id}`, { token: freshDispatchToken });
      const detailBody = detail.body as { alarms: AlarmJson[] };
      expect(detailBody.alarms[0]?.recipients).toEqual(original.recipients);

      const snapshot = await app.client().get('/api/v1/snapshot', { token: freshDispatchToken });
      const snapAlarm = (snapshot.body as { alarms: AlarmJson[] }).alarms.find(
        a => a.id === original.id
      );
      expect(snapAlarm?.recipients).toEqual(original.recipients);
      expect(snapAlarm?.recipients.some(r => r.person_id === p1)).toBe(true);
    } finally {
      app.clock.set(dayStart);
    }
  });

  it('idempotency: same id twice -> 201 then 200, exactly one alarm.triggered; without id on an already-running incident -> 409', async () => {
    const { incident, v1 } = await setupAlarmedIncident('Idem');
    const ws = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      const alarmId = '11111111-1111-4111-8111-111111111111';
      const first = await triggerAlarm(incident.id, [v1.id], { id: alarmId });
      expect(first.status).toBe(201);
      await ws.next(m => m.type === 'alarm.triggered');

      const second = await triggerAlarm(incident.id, [v1.id], { id: alarmId });
      expect(second.status).toBe(200);
      expect((second.body as TriggerAlarmResponse).alarm.id).toBe(alarmId);
      expect((second.body as TriggerAlarmResponse).double_crewed).toEqual([]);

      // No second alarm.triggered event: incident.updated (from the initial
      // transition) was the last thing emitted on this connection before
      // the idempotent repeat, which emits nothing.
      await expect(ws.next(m => m.type === 'alarm.triggered', 300)).rejects.toThrow();

      const third = await triggerAlarm(incident.id, [v1.id]);
      expect(third.status).toBe(409);
      expect((third.body as { error: { code: string } }).error.code).toBe(
        'invalid_state_transition'
      );

      const detail = await app
        .client()
        .get(`/api/v1/incidents/${incident.id}`, { token: dispatchToken });
      expect((detail.body as { alarms: AlarmJson[] }).alarms).toHaveLength(1);
    } finally {
      ws.close();
    }
  });

  it('idempotency: same id for a different incident -> 409 conflict', async () => {
    const setup = await setupAlarmedIncident('Conflict');
    const incidentB = await createIncident(setup.day.id);
    const alarmId = '22222222-2222-4222-8222-222222222222';

    const first = await triggerAlarm(setup.incident.id, [setup.v1.id], { id: alarmId });
    expect(first.status).toBe(201);

    const second = await triggerAlarm(incidentB.id, [setup.v1.id], { id: alarmId });
    expect(second.status).toBe(409);
    expect((second.body as { error: { code: string } }).error.code).toBe('conflict');
  });

  it('concurrent double POST (Promise.all) results in exactly one alarm', async () => {
    const { incident, v1 } = await setupAlarmedIncident('Concurrent');

    const [a, b] = await Promise.all([
      triggerAlarm(incident.id, [v1.id]),
      triggerAlarm(incident.id, [v1.id]),
    ]);
    const statuses = [a.status, b.status].sort();
    expect(statuses).toEqual([201, 409]);

    const detail = await app
      .client()
      .get(`/api/v1/incidents/${incident.id}`, { token: dispatchToken });
    expect((detail.body as { alarms: AlarmJson[] }).alarms).toHaveLength(1);
  });

  it('permissions: crew and preparation -> 403, monitor -> 403, dispatch and admin OK', async () => {
    const { incident: incidentForPrep, v1: v1Prep } = await setupAlarmedIncident('PermPrep');
    const prepRes = await triggerAlarm(incidentForPrep.id, [v1Prep.id], {
      token: preparationToken,
    });
    expect(prepRes.status).toBe(403);

    const { incident: incidentForCrew, v1: v1Crew } = await setupAlarmedIncident('PermCrew');
    const crewRes = await triggerAlarm(incidentForCrew.id, [v1Crew.id], { token: crewToken });
    expect(crewRes.status).toBe(403);

    const monitorCreateRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'Standby' }, { token: adminToken });
    const monitorId = (monitorCreateRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const monitorPairRes = await app
      .client()
      .post('/api/v1/auth/monitor/pair', { code: (codeRes.body as { code: string }).code });
    const monitorToken = (monitorPairRes.body as { access_token: string }).access_token;

    const { incident: incidentForMonitor, v1: v1Monitor } =
      await setupAlarmedIncident('PermMonitor');
    const monitorRes = await triggerAlarm(incidentForMonitor.id, [v1Monitor.id], {
      token: monitorToken,
    });
    expect(monitorRes.status).toBe(403);

    const { incident: incidentForDispatch, v1: v1Dispatch } =
      await setupAlarmedIncident('PermDispatch');
    const dispatchRes = await triggerAlarm(incidentForDispatch.id, [v1Dispatch.id], {
      token: dispatchToken,
    });
    expect(dispatchRes.status).toBe(201);

    const { incident: incidentForAdmin, v1: v1Admin } = await setupAlarmedIncident('PermAdmin');
    const adminRes = await triggerAlarm(incidentForAdmin.id, [v1Admin.id], { token: adminToken });
    expect(adminRes.status).toBe(201);
  });

  it('scheduled_at present -> 400 validation_error', async () => {
    const { incident, v1 } = await setupAlarmedIncident('ScheduledAt');
    const res = await app
      .client()
      .post(
        `/api/v1/incidents/${incident.id}/alarms`,
        { vehicle_ids: [v1.id], scheduled_at: '2026-06-01T09:00:00Z' },
        { token: dispatchToken }
      );
    expect(res.status).toBe(400);
    expect((res.body as { error: { code: string } }).error.code).toBe('validation_error');
  });

  it('inactive vehicle -> 409 vehicle_inactive', async () => {
    const { incident, v1 } = await setupAlarmedIncident('InactiveVehicle');
    await app.client().patch(`/api/v1/vehicles/${v1.id}`, { active: false }, { token: adminToken });
    const res = await triggerAlarm(incident.id, [v1.id]);
    expect(res.status).toBe(409);
    expect((res.body as { error: { code: string } }).error.code).toBe('vehicle_inactive');
  });

  it('unknown vehicle -> 400 validation_error', async () => {
    const { incident } = await setupAlarmedIncident('UnknownVehicle');
    const res = await triggerAlarm(incident.id, ['00000000-0000-4000-8000-000000000000']);
    expect(res.status).toBe(400);
    expect((res.body as { error: { code: string } }).error.code).toBe('validation_error');
  });

  it('bf_day not running -> 409 bf_day_not_running', async () => {
    const day = await createBfDay('NotRunning');
    const v1 = await createVehicle('NotRunning-V1');
    const incident = await createIncident(day.id);
    const res = await triggerAlarm(incident.id, [v1.id]);
    expect(res.status).toBe(409);
    expect((res.body as { error: { code: string } }).error.code).toBe('bf_day_not_running');
  });

  it('unknown incident -> 404', async () => {
    const res = await triggerAlarm('00000000-0000-4000-8000-000000000001', [
      '00000000-0000-4000-8000-000000000002',
    ]);
    expect(res.status).toBe(404);
  });

  describe('acknowledge', () => {
    it('only the recipient can acknowledge, idempotently (one event), others get 403 not_recipient', async () => {
      const { incident, v1, p1 } = await setupAlarmedIncident('Ack');
      const triggered = await triggerAlarm(incident.id, [v1.id]);
      const alarm = (triggered.body as TriggerAlarmResponse).alarm;
      const p1Token = await signTestAccessToken(app, p1, 'crew');

      const ws = await connectWs(app.baseUrl, dispatchToken);
      await ws.next(m => m.type === 'hello');
      try {
        const nonRecipient = await app
          .client()
          .post(`/api/v1/alarms/${alarm.id}/acknowledge`, {}, { token: crewToken });
        expect(nonRecipient.status).toBe(403);
        expect((nonRecipient.body as { error: { code: string } }).error.code).toBe('not_recipient');

        const ack = await app
          .client()
          .post(`/api/v1/alarms/${alarm.id}/acknowledge`, {}, { token: p1Token });
        expect(ack.status).toBe(200);
        const recipient = (ack.body as { recipient: AlarmRecipientJson }).recipient;
        expect(recipient.person_id).toBe(p1);
        expect(recipient.acknowledged_at).not.toBeNull();

        const event = await ws.next(m => m.type === 'alarm.acknowledged');
        expect((event.data as { person_id: string }).person_id).toBe(p1);

        const ackAgain = await app
          .client()
          .post(`/api/v1/alarms/${alarm.id}/acknowledge`, {}, { token: p1Token });
        expect(ackAgain.status).toBe(200);
        expect((ackAgain.body as { recipient: AlarmRecipientJson }).recipient.acknowledged_at).toBe(
          recipient.acknowledged_at
        );

        await expect(ws.next(m => m.type === 'alarm.acknowledged', 300)).rejects.toThrow();
      } finally {
        ws.close();
      }
    });

    it('monitor -> 403; unknown alarm -> 404; non-active alarm -> 409 alarm_not_active', async () => {
      const { incident, v1, p1 } = await setupAlarmedIncident('AckState');
      const triggered = await triggerAlarm(incident.id, [v1.id]);
      const alarm = (triggered.body as TriggerAlarmResponse).alarm;
      const p1Token = await signTestAccessToken(app, p1, 'crew');

      const monitorCreateRes = await app
        .client()
        .post('/api/v1/monitors', { name: 'Standby 2' }, { token: adminToken });
      const monitorId = (monitorCreateRes.body as { id: string }).id;
      const codeRes = await app
        .client()
        .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
      const monitorPairRes = await app
        .client()
        .post('/api/v1/auth/monitor/pair', { code: (codeRes.body as { code: string }).code });
      const monitorToken = (monitorPairRes.body as { access_token: string }).access_token;

      const monitorRes = await app
        .client()
        .post(`/api/v1/alarms/${alarm.id}/acknowledge`, {}, { token: monitorToken });
      expect(monitorRes.status).toBe(403);

      const unknownRes = await app
        .client()
        .post(
          '/api/v1/alarms/00000000-0000-4000-8000-000000000003/acknowledge',
          {},
          { token: p1Token }
        );
      expect(unknownRes.status).toBe(404);

      await pool.query(`update alarm set state = 'missed' where id = $1`, [alarm.id]);
      const inactiveRes = await app
        .client()
        .post(`/api/v1/alarms/${alarm.id}/acknowledge`, {}, { token: p1Token });
      expect(inactiveRes.status).toBe(409);
      expect((inactiveRes.body as { error: { code: string } }).error.code).toBe('alarm_not_active');
    });
  });

  describe('Drehbuch filter', () => {
    it('crew/monitor never see the script in alarm.triggered, incident detail, or snapshot; dispatch does', async () => {
      const { incident, v1 } = await setupAlarmedIncident('DrehbuchAlarm');

      const monitorCreateRes = await app
        .client()
        .post('/api/v1/monitors', { name: 'Standby 3' }, { token: adminToken });
      const monitorId = (monitorCreateRes.body as { id: string }).id;
      const codeRes = await app
        .client()
        .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
      const monitorPairRes = await app
        .client()
        .post('/api/v1/auth/monitor/pair', { code: (codeRes.body as { code: string }).code });
      const monitorToken = (monitorPairRes.body as { access_token: string }).access_token;

      const crewWs = await connectWs(app.baseUrl, crewToken);
      const monitorWs = await connectWs(app.baseUrl, monitorToken);
      const dispatchWs = await connectWs(app.baseUrl, dispatchToken);
      await Promise.all([
        crewWs.next(m => m.type === 'hello'),
        monitorWs.next(m => m.type === 'hello'),
        dispatchWs.next(m => m.type === 'hello'),
      ]);

      try {
        const triggered = await triggerAlarm(incident.id, [v1.id]);
        expect(triggered.status).toBe(201);

        const crewEvent = await crewWs.next(m => m.type === 'alarm.triggered');
        assertNoScript(JSON.stringify(crewEvent));
        const monitorEvent = await monitorWs.next(m => m.type === 'alarm.triggered');
        assertNoScript(JSON.stringify(monitorEvent));
        const dispatchEvent = await dispatchWs.next(m => m.type === 'alarm.triggered');
        expect((dispatchEvent.data as { incident: IncidentJson }).incident.script).toBe(
          SCRIPT_MARKER
        );

        const crewDetail = await app
          .client()
          .get(`/api/v1/incidents/${incident.id}`, { token: crewToken });
        assertNoScript(JSON.stringify(crewDetail.body));

        const snapshot = await app.client().get('/api/v1/snapshot', { token: crewToken });
        assertNoScript(JSON.stringify(snapshot.body));
        expect(
          (snapshot.body as { alarms: AlarmJson[] }).alarms.some(a => a.incident_id === incident.id)
        ).toBe(true);
      } finally {
        crewWs.close();
        monitorWs.close();
        dispatchWs.close();
      }
    });
  });
});
