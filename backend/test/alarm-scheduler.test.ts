import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';
import { connectWs, type WsTestClient } from './support/ws-client.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const MIN_MS = 60_000;

interface BfDayJson {
  id: string;
  state: 'planning' | 'running' | 'ended';
}

interface ShiftJson {
  id: string;
  bf_day_id: string;
}

interface VehicleJson {
  id: string;
  call_sign: string;
}

interface IncidentJson {
  id: string;
  bf_day_id: string;
  state: string;
}

interface AlarmJson {
  id: string;
  incident_id: string;
  state: string;
  scheduled_at: string | null;
  triggered_at: string | null;
  relative_to_alarm_id: string | null;
  offset_minutes: number | null;
  vehicle_ids: string[];
  recipients: Array<{ person_id: string; vehicle_id: string }>;
}

describe('alarm scheduler (ADR 0022)', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;
  let dispatchToken: string;

  beforeAll(async () => {
    // ADR 0008: tests drive the clock explicitly and advance it by many
    // minutes across this file's scenarios — a 900s access token would
    // expire partway through. Give it plenty of headroom.
    app = await startTestApp({ config: { ACCESS_TOKEN_TTL_SECONDS: 100_000_000 } });
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

  async function createIncident(bfDayId: string): Promise<IncidentJson> {
    const res = await app
      .client()
      .post(
        `/api/v1/bf-days/${bfDayId}/incidents`,
        { keyword: 'Wohnungsbrand', address: 'Musterstraße 1', report: 'Rauch' },
        { token: dispatchToken }
      );
    expect(res.status).toBe(201);
    return res.body as IncidentJson;
  }

  async function pairDevice(personId: string): Promise<{ deviceId: string; deviceToken: string }> {
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${personId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app
      .client()
      .post('/api/v1/auth/pair', { code, platform: 'android', app_version: '1.0.0' });
    expect(pairRes.status).toBe(200);
    const deviceId = (pairRes.body as { device_id: string }).device_id;
    const deviceToken = (pairRes.body as { access_token: string }).access_token;
    const tokenRes = await app
      .client()
      .put('/api/v1/me/device/push-token', { token: `push-${deviceId}` }, { token: deviceToken });
    expect(tokenRes.status).toBe(204);
    return { deviceId, deviceToken };
  }

  /** A running BF-Tag with two vehicles, one crewed vehicle (v1/p1/device1). */
  async function setup(label: string): Promise<{
    day: BfDayJson;
    incident: IncidentJson;
    v1: VehicleJson;
    v2: VehicleJson;
    p1: string;
    device1: string;
  }> {
    const day = await createBfDay(label);
    const shift = await getDefaultShift(day.id);
    const v1 = await createVehicle(`${label}-V1`);
    const v2 = await createVehicle(`${label}-V2`);

    const p1 = await createPerson(app, {
      displayName: `${label}-p1`,
      personType: 'youth',
      permission: 'crew',
      username: `${label}-p1`,
      password: 'participant-password',
    });
    await setParticipants(day.id, [p1.id]);
    const { deviceId: device1 } = await pairDevice(p1.id);
    await setCrew(shift.id, [{ vehicle_id: v1.id, person_id: p1.id, function: 'GF' }]);

    await startBfDay(day.id);
    const incident = await createIncident(day.id);

    return { day, incident, v1, v2, p1: p1.id, device1 };
  }

  async function plan(
    incidentId: string,
    body: Record<string, unknown>
  ): Promise<{ status: number; body: unknown }> {
    const res = await app
      .client()
      .post(`/api/v1/incidents/${incidentId}/alarms`, body, { token: dispatchToken });
    return { status: res.status, body: res.body };
  }

  async function getIncident(incidentId: string): Promise<{
    incident: IncidentJson;
    alarms: AlarmJson[];
  }> {
    const res = await app.client().get(`/api/v1/incidents/${incidentId}`, { token: dispatchToken });
    expect(res.status).toBe(200);
    const body = res.body as IncidentJson & { alarms: AlarmJson[] };
    return { incident: body, alarms: body.alarms };
  }

  it('triggers exactly at scheduled_at, not before; recipients frozen, push recorded', async () => {
    const { incident, v1, p1, device1 } = await setup('OnTime');
    const scheduledAt = new Date(app.clock.now().getTime() + 5 * MIN_MS);
    const planRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    expect(planRes.status).toBe(201);
    const alarmId = (planRes.body as { alarm: AlarmJson }).alarm.id;

    // Before the scheduled time: nothing happens.
    app.clock.advance(4 * MIN_MS);
    const before = await app.runScheduler();
    expect(before.triggered).not.toContain(alarmId);
    expect(before.missed).not.toContain(alarmId);
    expect((await getIncident(incident.id)).incident.state).toBe('draft');

    // Exactly at the scheduled time: triggers.
    app.clock.advance(1 * MIN_MS);
    const at = await app.runScheduler();
    expect(at.triggered).toEqual([alarmId]);
    expect(at.missed).toEqual([]);

    const { incident: reloadedIncident, alarms } = await getIncident(incident.id);
    expect(reloadedIncident.state).toBe('running');
    const triggeredAlarm = alarms.find(a => a.id === alarmId);
    expect(triggeredAlarm?.state).toBe('triggered');
    expect(triggeredAlarm?.recipients.map(r => r.person_id)).toEqual([p1]);

    expect(app.push.sentTo(device1)).toHaveLength(1);
  });

  it('relative Nachalarmierung +8min reschedules on the base trigger and fires at the new time', async () => {
    const { incident, v1, v2 } = await setup('Relative');
    const baseAt = new Date(app.clock.now().getTime() + 5 * MIN_MS);
    const baseRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: baseAt.toISOString(),
    });
    const baseId = (baseRes.body as { alarm: AlarmJson }).alarm.id;

    const relRes = await plan(incident.id, { vehicle_ids: [v2.id], offset_minutes: 8 });
    const relId = (relRes.body as { alarm: AlarmJson }).alarm.id;
    expect((relRes.body as { alarm: AlarmJson }).alarm.scheduled_at).toBe(
      new Date(baseAt.getTime() + 8 * MIN_MS).toISOString()
    );

    // The base triggers 2 minutes late (still well under the 10 min missed window).
    app.clock.advance(7 * MIN_MS);
    const first = await app.runScheduler();
    expect(first.triggered).toEqual([baseId]);

    const triggeredAt = app.clock.now();
    const { alarms: afterBase } = await getIncident(incident.id);
    const dependent = afterBase.find(a => a.id === relId);
    expect(dependent?.state).toBe('planned');
    expect(dependent?.scheduled_at).toBe(
      new Date(triggeredAt.getTime() + 8 * MIN_MS).toISOString()
    );

    // Before the rescheduled time: nothing.
    app.clock.advance(7 * MIN_MS);
    const tooEarly = await app.runScheduler();
    expect(tooEarly.triggered).not.toContain(relId);

    // At the rescheduled time: fires.
    app.clock.advance(1 * MIN_MS);
    const second = await app.runScheduler();
    expect(second.triggered).toEqual([relId]);
  });

  it('restart with a 5 min delay triggers the catch-up on startup', async () => {
    const { incident, v1 } = await setup('Restart5');
    const scheduledAt = new Date(app.clock.now().getTime() + 2 * MIN_MS);
    const planRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    const alarmId = (planRes.body as { alarm: AlarmJson }).alarm.id;

    app.clock.advance(7 * MIN_MS); // 5 min past scheduled_at
    app = await app.restart();

    const { alarms } = await getIncident(incident.id);
    expect(alarms.find(a => a.id === alarmId)?.state).toBe('triggered');
  });

  it('restart with a 15 min delay misses it; manual trigger and discard still work on missed alarms', async () => {
    const { incident, v1, v2 } = await setup('Restart15');
    const scheduledAt = new Date(app.clock.now().getTime() + 2 * MIN_MS);
    const missedRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    const missedAlarmId = (missedRes.body as { alarm: AlarmJson }).alarm.id;

    const secondRes = await plan(incident.id, {
      vehicle_ids: [v2.id],
      scheduled_at: new Date(scheduledAt.getTime() + MIN_MS).toISOString(),
    });
    const secondAlarmId = (secondRes.body as { alarm: AlarmJson }).alarm.id;

    const ws: WsTestClient = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      app.clock.advance(17 * MIN_MS); // 15 min past scheduled_at
      app = await app.restart();

      const missedEvent = await ws.next(m => m.type === 'alarm.missed', 5000).catch(() => null);
      // The ws connection doesn't survive the restart; re-verify via HTTP instead.
      void missedEvent;
    } finally {
      ws.close();
    }

    const { alarms } = await getIncident(incident.id);
    expect(alarms.find(a => a.id === missedAlarmId)?.state).toBe('missed');
    expect(alarms.find(a => a.id === secondAlarmId)?.state).toBe('missed');

    const triggerRes = await app
      .client()
      .post(`/api/v1/alarms/${missedAlarmId}/trigger`, {}, { token: dispatchToken });
    expect(triggerRes.status).toBe(200);
    expect((triggerRes.body as { alarm: AlarmJson }).alarm.state).toBe('triggered');

    const discardRes = await app
      .client()
      .post(`/api/v1/alarms/${secondAlarmId}/discard`, {}, { token: dispatchToken });
    expect(discardRes.status).toBe(200);
    expect((discardRes.body as { alarm: AlarmJson }).alarm.state).toBe('discarded');
  });

  it('exactly 10 minutes late still triggers', async () => {
    const { incident, v1 } = await setup('ExactlyTen');
    const scheduledAt = new Date(app.clock.now().getTime() + MIN_MS);
    const planRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    const alarmId = (planRes.body as { alarm: AlarmJson }).alarm.id;

    // now - scheduled_at == 600_000 exactly.
    app.clock.advance(MIN_MS + 600_000);
    const result = await app.runScheduler();
    expect(result.triggered).toEqual([alarmId]);
    expect(result.missed).toEqual([]);
  });

  it('11 minutes late is missed', async () => {
    const { incident, v1 } = await setup('ElevenLate');
    const scheduledAt = new Date(app.clock.now().getTime() + MIN_MS);
    const planRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    const alarmId = (planRes.body as { alarm: AlarmJson }).alarm.id;

    app.clock.advance(MIN_MS + 11 * MIN_MS);
    const result = await app.runScheduler();
    expect(result.missed).toEqual([alarmId]);
    expect(result.triggered).toEqual([]);
  });

  it('bf_day not running at the due time is missed', async () => {
    const { day, incident, v1 } = await setup('BfDayEnded');
    const scheduledAt = new Date(app.clock.now().getTime() + 2 * MIN_MS);
    const planRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    const alarmId = (planRes.body as { alarm: AlarmJson }).alarm.id;

    await endBfDay(day.id);
    app.clock.advance(3 * MIN_MS);
    const result = await app.runScheduler();
    expect(result.missed).toEqual([alarmId]);
  });

  it('closing the incident discards the planned alarm; the scheduler later does nothing', async () => {
    const { incident, v1, v2 } = await setup('CloseDiscards');
    const triggerNow = await plan(incident.id, { vehicle_ids: [v1.id] }); // immediate -> running
    expect(triggerNow.status).toBe(201);
    const plannedRes = await plan(incident.id, {
      vehicle_ids: [v2.id],
      scheduled_at: new Date(app.clock.now().getTime() + 2 * MIN_MS).toISOString(),
    });
    const plannedId = (plannedRes.body as { alarm: AlarmJson }).alarm.id;

    const closeRes = await app
      .client()
      .post(`/api/v1/incidents/${incident.id}/close`, {}, { token: dispatchToken });
    expect(closeRes.status).toBe(200);

    app.clock.advance(3 * MIN_MS);
    const result = await app.runScheduler();
    expect(result.triggered).not.toContain(plannedId);
    expect(result.missed).not.toContain(plannedId);

    const { alarms } = await getIncident(incident.id);
    expect(alarms.find(a => a.id === plannedId)?.state).toBe('discarded');
  });

  it('close-suggested stays false while a planned Nachalarmierung exists, true after it triggers/is discarded', async () => {
    const { incident, v1, v2 } = await setup('CloseSuggested');
    const triggerNow = await plan(incident.id, { vehicle_ids: [v1.id] });
    expect(triggerNow.status).toBe(201);

    const ws: WsTestClient = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      app.clock.advance(1000);
      await app
        .client()
        .put(`/api/v1/vehicles/${v1.id}/status`, { status: 1 }, { token: dispatchToken });
      const suggestedTrue = await ws.next(m => m.type === 'incident.close_suggested');
      expect(suggestedTrue.data).toEqual({ id: incident.id, suggested: true });

      const plannedRes = await plan(incident.id, {
        vehicle_ids: [v2.id],
        scheduled_at: new Date(app.clock.now().getTime() + 2 * MIN_MS).toISOString(),
      });
      const plannedId = (plannedRes.body as { alarm: AlarmJson }).alarm.id;
      const suggestedFalse = await ws.next(m => m.type === 'incident.close_suggested', 3000);
      expect(suggestedFalse.data).toEqual({ id: incident.id, suggested: false });

      app.clock.advance(2 * MIN_MS);
      const result = await app.runScheduler();
      expect(result.triggered).toEqual([plannedId]);
      const suggestedFalseStill = await ws
        .next(m => m.type === 'incident.close_suggested', 300)
        .catch(() => null);
      // v2 hasn't returned to status 1/2 yet, so no change is expected here
      // (still false) — only assert if an event unexpectedly did arrive.
      if (suggestedFalseStill) {
        expect(suggestedFalseStill.data).toEqual({ id: incident.id, suggested: false });
      }

      app.clock.advance(1000);
      await app
        .client()
        .put(`/api/v1/vehicles/${v2.id}/status`, { status: 1 }, { token: dispatchToken });
      const suggestedTrueAgain = await ws.next(m => m.type === 'incident.close_suggested', 3000);
      expect(suggestedTrueAgain.data).toEqual({ id: incident.id, suggested: true });
    } finally {
      ws.close();
    }
  });

  it('running the scheduler twice does not double-trigger', async () => {
    const { incident, v1 } = await setup('DoubleRun');
    const scheduledAt = new Date(app.clock.now().getTime() + 2 * MIN_MS);
    const planRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    const alarmId = (planRes.body as { alarm: AlarmJson }).alarm.id;

    app.clock.advance(3 * MIN_MS);
    const first = await app.runScheduler();
    expect(first.triggered).toEqual([alarmId]);

    const second = await app.runScheduler();
    expect(second.triggered).toEqual([]);
    expect(second.missed).toEqual([]);

    const { alarms } = await getIncident(incident.id);
    expect(alarms.find(a => a.id === alarmId)?.state).toBe('triggered');
  });
});
