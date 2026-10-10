import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs, type WsTestClient } from './support/ws-client.js';

const DAY_MS = 24 * 60 * 60 * 1000;

interface BfDayJson {
  id: string;
  state: 'planning' | 'running' | 'ended';
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
}

describe('alarm planning (ADR 0022)', () => {
  let app: TestApp;
  let adminToken: string;
  let dispatchToken: string;
  let crewToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'dispatch1', 'dispatch-password');

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
    const listRes = await app.client().get('/api/v1/bf-days', { token: adminToken });
    const days = listRes.body as BfDayJson[];
    for (const d of days) {
      if (d.state === 'running' && d.id !== id) {
        const endRes = await app
          .client()
          .post(`/api/v1/bf-days/${d.id}/end`, {}, { token: adminToken });
        expect(endRes.status).toBe(200);
      }
    }
    const res = await app.client().post(`/api/v1/bf-days/${id}/start`, {}, { token: adminToken });
    expect(res.status).toBe(200);
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

  async function plan(
    incidentId: string,
    body: Record<string, unknown>,
    token = dispatchToken
  ): Promise<{ status: number; body: unknown }> {
    const res = await app.client().post(`/api/v1/incidents/${incidentId}/alarms`, body, { token });
    return { status: res.status, body: res.body };
  }

  async function setup(
    label: string
  ): Promise<{ day: BfDayJson; incident: IncidentJson; v1: VehicleJson; v2: VehicleJson }> {
    const day = await createBfDay(label);
    const v1 = await createVehicle(`${label}-V1`);
    const v2 = await createVehicle(`${label}-V2`);
    await startBfDay(day.id);
    const incident = await createIncident(day.id);
    return { day, incident, v1, v2 };
  }

  it('plans an absolute alarm: 201, state planned, no recipients yet', async () => {
    const { incident, v1 } = await setup('Abs');
    const scheduledAt = new Date(app.clock.now().getTime() + 10 * 60_000);
    const res = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: scheduledAt.toISOString(),
    });
    expect(res.status).toBe(201);
    const alarm = (res.body as { alarm: AlarmJson }).alarm;
    expect(alarm.state).toBe('planned');
    expect(alarm.scheduled_at).toBe(scheduledAt.toISOString());
    expect(alarm.triggered_at).toBeNull();
  });

  it('plans a relative alarm against a planned Erstalarm: scheduled_at = base.scheduled_at + offset', async () => {
    const { incident, v1, v2 } = await setup('Rel');
    const baseAt = new Date(app.clock.now().getTime() + 10 * 60_000);
    const baseRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: baseAt.toISOString(),
    });
    expect(baseRes.status).toBe(201);

    const relRes = await plan(incident.id, { vehicle_ids: [v2.id], offset_minutes: 8 });
    expect(relRes.status).toBe(201);
    const relAlarm = (relRes.body as { alarm: AlarmJson }).alarm;
    expect(relAlarm.offset_minutes).toBe(8);
    expect(relAlarm.scheduled_at).toBe(new Date(baseAt.getTime() + 8 * 60_000).toISOString());
    expect(relAlarm.relative_to_alarm_id).toBe((baseRes.body as { alarm: AlarmJson }).alarm.id);
  });

  it('relative alarm with no base at all -> 409 no_first_alarm', async () => {
    const { incident, v1 } = await setup('NoBase');
    const res = await plan(incident.id, { vehicle_ids: [v1.id], offset_minutes: 5 });
    expect(res.status).toBe(409);
    expect((res.body as { error: { code: string } }).error.code).toBe('no_first_alarm');
  });

  it('scheduled_at in the past -> 409 scheduled_at_in_past', async () => {
    const { incident, v1 } = await setup('Past');
    const past = new Date(app.clock.now().getTime() - 60_000);
    const res = await plan(incident.id, { vehicle_ids: [v1.id], scheduled_at: past.toISOString() });
    expect(res.status).toBe(409);
    expect((res.body as { error: { code: string } }).error.code).toBe('scheduled_at_in_past');
  });

  it('scheduled_at and offset_minutes both set -> 400 validation_error', async () => {
    const { incident, v1 } = await setup('Mutex');
    const res = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: new Date(app.clock.now().getTime() + 60_000).toISOString(),
      offset_minutes: 5,
    });
    expect(res.status).toBe(400);
    expect((res.body as { error: { code: string } }).error.code).toBe('validation_error');
  });

  it('vehicle conflicts: a vehicle in a planned alarm cannot be re-alarmed immediately or re-planned', async () => {
    const { incident, v1 } = await setup('Conflict');
    const planned = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: new Date(app.clock.now().getTime() + 60_000).toISOString(),
    });
    expect(planned.status).toBe(201);

    const immediate = await plan(incident.id, { vehicle_ids: [v1.id] });
    expect(immediate.status).toBe(409);
    expect((immediate.body as { error: { code: string } }).error.code).toBe(
      'vehicle_already_alarmed'
    );

    const anotherPlan = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: new Date(app.clock.now().getTime() + 120_000).toISOString(),
    });
    expect(anotherPlan.status).toBe(409);
    expect((anotherPlan.body as { error: { code: string } }).error.code).toBe(
      'vehicle_already_alarmed'
    );
  });

  it('vehicle already in a triggered alarm cannot be planned again', async () => {
    const { incident, v1 } = await setup('ConflictRev');
    const immediate = await plan(incident.id, { vehicle_ids: [v1.id] });
    expect(immediate.status).toBe(201);

    const planned = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: new Date(app.clock.now().getTime() + 60_000).toISOString(),
    });
    expect(planned.status).toBe(409);
    expect((planned.body as { error: { code: string } }).error.code).toBe(
      'vehicle_already_alarmed'
    );
  });

  it('PATCH changes scheduled_at and recomputes relative dependents', async () => {
    const { incident, v1, v2 } = await setup('Patch');
    const baseAt = new Date(app.clock.now().getTime() + 10 * 60_000);
    const baseRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: baseAt.toISOString(),
    });
    const base = (baseRes.body as { alarm: AlarmJson }).alarm;
    const relRes = await plan(incident.id, { vehicle_ids: [v2.id], offset_minutes: 8 });
    const rel = (relRes.body as { alarm: AlarmJson }).alarm;
    expect(rel.scheduled_at).toBe(new Date(baseAt.getTime() + 8 * 60_000).toISOString());

    const newBaseAt = new Date(app.clock.now().getTime() + 20 * 60_000);
    const patchRes = await app
      .client()
      .patch(
        `/api/v1/alarms/${base.id}`,
        { scheduled_at: newBaseAt.toISOString() },
        { token: dispatchToken }
      );
    expect(patchRes.status).toBe(200);
    expect((patchRes.body as { alarm: AlarmJson }).alarm.scheduled_at).toBe(
      newBaseAt.toISOString()
    );

    const getRes = await app
      .client()
      .get(`/api/v1/incidents/${incident.id}`, { token: dispatchToken });
    const alarms = (getRes.body as { alarms: AlarmJson[] }).alarms;
    const updatedRel = alarms.find(a => a.id === rel.id);
    expect(updatedRel?.scheduled_at).toBe(new Date(newBaseAt.getTime() + 8 * 60_000).toISOString());
  });

  it('PATCH on a triggered alarm -> 409 alarm_not_planned', async () => {
    const { incident, v1 } = await setup('PatchTriggered');
    const triggerRes = await plan(incident.id, { vehicle_ids: [v1.id] });
    const alarmId = (triggerRes.body as { alarm: AlarmJson }).alarm.id;
    const patchRes = await app
      .client()
      .patch(
        `/api/v1/alarms/${alarmId}`,
        { scheduled_at: new Date(app.clock.now().getTime() + 60_000).toISOString() },
        { token: dispatchToken }
      );
    expect(patchRes.status).toBe(409);
    expect((patchRes.body as { error: { code: string } }).error.code).toBe('alarm_not_planned');
  });

  it('discard removes a planned alarm and cascades to relative dependents', async () => {
    const { incident, v1, v2 } = await setup('Discard');
    const baseRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: new Date(app.clock.now().getTime() + 10 * 60_000).toISOString(),
    });
    const base = (baseRes.body as { alarm: AlarmJson }).alarm;
    const relRes = await plan(incident.id, { vehicle_ids: [v2.id], offset_minutes: 8 });
    const rel = (relRes.body as { alarm: AlarmJson }).alarm;

    const discardRes = await app
      .client()
      .post(`/api/v1/alarms/${base.id}/discard`, {}, { token: dispatchToken });
    expect(discardRes.status).toBe(200);
    expect((discardRes.body as { alarm: AlarmJson }).alarm.state).toBe('discarded');

    const getRes = await app
      .client()
      .get(`/api/v1/incidents/${incident.id}`, { token: dispatchToken });
    const alarms = (getRes.body as { alarms: AlarmJson[] }).alarms;
    expect(alarms.find(a => a.id === rel.id)?.state).toBe('discarded');
  });

  it('closing an incident discards all planned alarms and reports them', async () => {
    const { incident, v1, v2 } = await setup('Close');
    await plan(incident.id, { vehicle_ids: [v1.id] }); // immediate -> incident running
    const plannedRes = await plan(incident.id, {
      vehicle_ids: [v2.id],
      scheduled_at: new Date(app.clock.now().getTime() + 10 * 60_000).toISOString(),
    });
    const planned = (plannedRes.body as { alarm: AlarmJson }).alarm;

    const closeRes = await app
      .client()
      .post(`/api/v1/incidents/${incident.id}/close`, {}, { token: dispatchToken });
    expect(closeRes.status).toBe(200);
    expect((closeRes.body as { discarded_alarm_ids: string[] }).discarded_alarm_ids).toContain(
      planned.id
    );
  });

  it('discarding a draft incident with a planned alarm discards the alarm too', async () => {
    const { incident, v1 } = await setup('IncidentDiscard');
    const plannedRes = await plan(incident.id, {
      vehicle_ids: [v1.id],
      scheduled_at: new Date(app.clock.now().getTime() + 10 * 60_000).toISOString(),
    });
    const planned = (plannedRes.body as { alarm: AlarmJson }).alarm;

    const discardRes = await app
      .client()
      .post(`/api/v1/incidents/${incident.id}/discard`, {}, { token: dispatchToken });
    expect(discardRes.status).toBe(200);

    const getRes = await app
      .client()
      .get(`/api/v1/incidents/${incident.id}`, { token: adminToken });
    const alarms = (getRes.body as { alarms: AlarmJson[] }).alarms;
    expect(alarms.find(a => a.id === planned.id)?.state).toBe('discarded');
  });

  it('crew gets 403 on plan/patch/discard, receives no alarm.planned event, and sees empty scheduled_alarms', async () => {
    const { incident, v1 } = await setup('CrewForbidden');
    const scheduledAt = new Date(app.clock.now().getTime() + 10 * 60_000).toISOString();

    const planRes = await plan(
      incident.id,
      { vehicle_ids: [v1.id], scheduled_at: scheduledAt },
      crewToken
    );
    expect(planRes.status).toBe(403);

    const dispatchWs: WsTestClient = await connectWs(app.baseUrl, dispatchToken);
    await dispatchWs.next(m => m.type === 'hello');
    try {
      const dispatchPlanRes = await plan(incident.id, {
        vehicle_ids: [v1.id],
        scheduled_at: scheduledAt,
      });
      expect(dispatchPlanRes.status).toBe(201);
      const alarm = (dispatchPlanRes.body as { alarm: AlarmJson }).alarm;

      const patchRes = await app
        .client()
        .patch(`/api/v1/alarms/${alarm.id}`, { vehicle_ids: [v1.id] }, { token: crewToken });
      expect(patchRes.status).toBe(403);

      const discardRes = await app
        .client()
        .post(`/api/v1/alarms/${alarm.id}/discard`, {}, { token: crewToken });
      expect(discardRes.status).toBe(403);

      const snapRes = await app.client().get('/api/v1/snapshot', { token: crewToken });
      expect(snapRes.status).toBe(200);
      expect((snapRes.body as { scheduled_alarms: unknown[] }).scheduled_alarms).toEqual([]);

      const dispatchSnapRes = await app.client().get('/api/v1/snapshot', { token: dispatchToken });
      const scheduled = (dispatchSnapRes.body as { scheduled_alarms: Array<{ alarm: AlarmJson }> })
        .scheduled_alarms;
      expect(scheduled.some(entry => entry.alarm.id === alarm.id)).toBe(true);
    } finally {
      dispatchWs.close();
    }
  });

  it('close-suggested goes false while a planned alarm exists and true again after discard', async () => {
    const { incident, v1, v2 } = await setup('CloseSuggested');
    const triggerRes = await plan(incident.id, { vehicle_ids: [v1.id] });
    expect(triggerRes.status).toBe(201);

    const dispatchWs: WsTestClient = await connectWs(app.baseUrl, dispatchToken);
    await dispatchWs.next(m => m.type === 'hello');
    try {
      await app.clock.advance(1000);
      await app
        .client()
        .put(`/api/v1/vehicles/${v1.id}/status`, { status: 1 }, { token: dispatchToken });
      const suggestedTrue = await dispatchWs.next(m => m.type === 'incident.close_suggested');
      expect(suggestedTrue.data).toEqual({ id: incident.id, suggested: true });

      const plannedRes = await plan(incident.id, {
        vehicle_ids: [v2.id],
        scheduled_at: new Date(app.clock.now().getTime() + 10 * 60_000).toISOString(),
      });
      expect(plannedRes.status).toBe(201);
      const planned = (plannedRes.body as { alarm: AlarmJson }).alarm;
      const suggestedFalse = await dispatchWs.next(m => m.type === 'incident.close_suggested');
      expect(suggestedFalse.data).toEqual({ id: incident.id, suggested: false });

      const discardRes = await app
        .client()
        .post(`/api/v1/alarms/${planned.id}/discard`, {}, { token: dispatchToken });
      expect(discardRes.status).toBe(200);
      const suggestedTrueAgain = await dispatchWs.next(m => m.type === 'incident.close_suggested');
      expect(suggestedTrueAgain.data).toEqual({ id: incident.id, suggested: true });
    } finally {
      dispatchWs.close();
    }
  });
});
