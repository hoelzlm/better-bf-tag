import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
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
  status: number;
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
  vehicle_ids: string[];
}

interface TriggerAlarmResponse {
  alarm: AlarmJson;
  double_crewed: unknown[];
}

interface CloseSuggestedEvent {
  id: string;
  suggested: boolean;
}

/**
 * Abschlussvorschlag (ADR 0019 "Abschlussvorschlag"): `computeCloseSuggested`
 * / `incident.close_suggested` / snapshot `close_suggested_incident_ids`.
 */
describe('close suggestion (ADR 0019)', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;
  let dispatchToken: string;
  let preparationToken: string;
  let crewToken: string;
  let monitorToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    pool = new Pool({ connectionString: app.databaseUrl });

    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'cs-dispatch',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'cs-dispatch', 'dispatch-password');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'cs-prep',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'cs-prep', 'prep-password');

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'cs-crew',
      password: 'crew-password',
    });
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');

    const monitorCreateRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'CS Standby' }, { token: adminToken });
    const monitorId = (monitorCreateRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const pairRes = await app
      .client()
      .post('/api/v1/auth/monitor/pair', { code: (codeRes.body as { code: string }).code });
    monitorToken = (pairRes.body as { access_token: string }).access_token;
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
        { keyword: 'Wohnungsbrand', address: 'Musterstraße 1', report: 'Rauch aus dem Fenster' },
        { token: preparationToken }
      );
    expect(res.status).toBe(201);
    return res.body as IncidentJson;
  }

  async function triggerAlarm(
    incidentId: string,
    vehicleIds: string[]
  ): Promise<TriggerAlarmResponse> {
    const res = await app
      .client()
      .post(
        `/api/v1/incidents/${incidentId}/alarms`,
        { vehicle_ids: vehicleIds },
        { token: dispatchToken }
      );
    expect([200, 201]).toContain(res.status);
    return res.body as TriggerAlarmResponse;
  }

  async function setVehicleStatus(vehicleId: string, status: number): Promise<void> {
    const res = await app
      .client()
      .put(`/api/v1/vehicles/${vehicleId}/status`, { status }, { token: dispatchToken });
    expect(res.status).toBe(200);
  }

  async function snapshotCloseSuggestedIds(token: string): Promise<string[]> {
    const res = await app.client().get('/api/v1/snapshot', { token });
    expect(res.status).toBe(200);
    return (res.body as { close_suggested_incident_ids: string[] }).close_suggested_incident_ids;
  }

  /** Builds a running BF-Tag with a running incident and the given vehicles. */
  async function setupRunningIncident(
    label: string,
    vehicleCount: number
  ): Promise<{ day: BfDayJson; incident: IncidentJson; vehicles: VehicleJson[] }> {
    const day = await createBfDay(label);
    const vehicles: VehicleJson[] = [];
    for (let i = 0; i < vehicleCount; i++) {
      vehicles.push(await createVehicle(`${label}-V${i + 1}`));
    }
    await startBfDay(day.id);
    const incident = await createIncident(day.id);
    return { day, incident, vehicles };
  }

  it('right after Erstalarm (vehicles still status 2 from before) -> not suggested, no event', async () => {
    const { incident, vehicles } = await setupRunningIncident('Fresh', 2);
    const ws = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      await triggerAlarm(
        incident.id,
        vehicles.map(v => v.id)
      );
      await ws.next(m => m.type === 'alarm.triggered');

      await expect(ws.next(m => m.type === 'incident.close_suggested', 300)).rejects.toThrow();

      const ids = await snapshotCloseSuggestedIds(dispatchToken);
      expect(ids).not.toContain(incident.id);
    } finally {
      ws.close();
    }
  });

  it(
    'vehicles go 3 -> 4 -> 1/2 after the alarm: suggested:true only when the LAST alarmed ' +
      'vehicle reaches 1/2; dispatch & admin WS receive it, crew/monitor/preparation do not; ' +
      'further 1<->2 change does not duplicate; Nachalarmierung sets suggested:false',
    async () => {
      const { incident, vehicles } = await setupRunningIncident('Ready', 2);
      const [v1, v2] = vehicles as [VehicleJson, VehicleJson];

      const dispatchWs = await connectWs(app.baseUrl, dispatchToken);
      const adminWs = await connectWs(app.baseUrl, adminToken);
      const crewWs = await connectWs(app.baseUrl, crewToken);
      const monitorWs = await connectWs(app.baseUrl, monitorToken);
      const prepWs = await connectWs(app.baseUrl, preparationToken);
      await Promise.all([
        dispatchWs.next(m => m.type === 'hello'),
        adminWs.next(m => m.type === 'hello'),
        crewWs.next(m => m.type === 'hello'),
        monitorWs.next(m => m.type === 'hello'),
        prepWs.next(m => m.type === 'hello'),
      ]);

      try {
        await triggerAlarm(incident.id, [v1.id, v2.id]);
        await dispatchWs.next(m => m.type === 'alarm.triggered');
        await adminWs.next(m => m.type === 'alarm.triggered');
        await crewWs.next(m => m.type === 'alarm.triggered');
        await monitorWs.next(m => m.type === 'alarm.triggered');
        await prepWs.next(m => m.type === 'alarm.triggered');

        // The FakeClock doesn't advance on its own; `status_changed_at` must
        // be strictly later than the alarm's `triggered_at` (ADR 0019).
        app.clock.advance(1000);

        // v1: 2 -> 3 -> 4 -> 1. Not the last vehicle outstanding, and even
        // once v1 is ready v2 still isn't -> no event yet.
        await setVehicleStatus(v1.id, 3);
        await setVehicleStatus(v1.id, 4);
        await setVehicleStatus(v1.id, 1);
        await expect(
          dispatchWs.next(m => m.type === 'incident.close_suggested', 300)
        ).rejects.toThrow();

        // v2: 2 -> 3 -> 4 (still not ready) -> no event.
        await setVehicleStatus(v2.id, 3);
        await setVehicleStatus(v2.id, 4);
        await expect(
          dispatchWs.next(m => m.type === 'incident.close_suggested', 300)
        ).rejects.toThrow();

        // v2 -> 2: the last outstanding vehicle becomes ready -> suggested:true,
        // exactly once, to dispatch and admin only.
        await setVehicleStatus(v2.id, 2);
        const dispatchEvent = await dispatchWs.next(m => m.type === 'incident.close_suggested');
        expect(dispatchEvent.data).toEqual({ id: incident.id, suggested: true });
        const adminEvent = await adminWs.next(m => m.type === 'incident.close_suggested');
        expect(adminEvent.data).toEqual({ id: incident.id, suggested: true });

        await expect(
          crewWs.next(m => m.type === 'incident.close_suggested', 300)
        ).rejects.toThrow();
        await expect(
          monitorWs.next(m => m.type === 'incident.close_suggested', 300)
        ).rejects.toThrow();
        await expect(
          prepWs.next(m => m.type === 'incident.close_suggested', 300)
        ).rejects.toThrow();

        const idsAfter = await snapshotCloseSuggestedIds(dispatchToken);
        expect(idsAfter).toContain(incident.id);
        const crewIds = await snapshotCloseSuggestedIds(crewToken);
        expect(crewIds).toEqual([]);

        // Further 1 <-> 2 change while suggested -> no duplicate event.
        await setVehicleStatus(v1.id, 2);
        await expect(
          dispatchWs.next(m => m.type === 'incident.close_suggested', 300)
        ).rejects.toThrow();
        await setVehicleStatus(v1.id, 1);
        await expect(
          dispatchWs.next(m => m.type === 'incident.close_suggested', 300)
        ).rejects.toThrow();

        // Nachalarmierung of a new vehicle while suggested -> suggested:false.
        const v3 = await createVehicle('Ready-V3');
        const nach = await triggerAlarm(incident.id, [v3.id]);
        expect(nach.alarm.state).toBe('triggered');
        await dispatchWs.next(m => m.type === 'alarm.triggered');
        const retracted = await dispatchWs.next(m => m.type === 'incident.close_suggested');
        expect(retracted.data).toEqual({ id: incident.id, suggested: false });

        const idsAfterNach = await snapshotCloseSuggestedIds(dispatchToken);
        expect(idsAfterNach).not.toContain(incident.id);
      } finally {
        dispatchWs.close();
        adminWs.close();
        crewWs.close();
        monitorWs.close();
        prepWs.close();
      }
    }
  );

  it('a planned alarm (inserted directly) prevents the suggestion', async () => {
    const { incident, vehicles } = await setupRunningIncident('Planned', 1);
    const [v1] = vehicles as [VehicleJson];

    await triggerAlarm(incident.id, [v1.id]);
    await pool.query(
      `insert into alarm (incident_id, state, created_at) values ($1, 'planned', now())`,
      [incident.id]
    );

    app.clock.advance(1000);
    const ws = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      await setVehicleStatus(v1.id, 3);
      await setVehicleStatus(v1.id, 4);
      await setVehicleStatus(v1.id, 1);

      await expect(ws.next(m => m.type === 'incident.close_suggested', 300)).rejects.toThrow();

      const ids = await snapshotCloseSuggestedIds(dispatchToken);
      expect(ids).not.toContain(incident.id);
    } finally {
      ws.close();
    }
  });

  it('closing while suggested -> incident.closed followed by incident.close_suggested {suggested:false}', async () => {
    const { incident, vehicles } = await setupRunningIncident('CloseSuggested', 1);
    const [v1] = vehicles as [VehicleJson];

    await triggerAlarm(incident.id, [v1.id]);
    app.clock.advance(1000);
    await setVehicleStatus(v1.id, 3);
    await setVehicleStatus(v1.id, 4);
    await setVehicleStatus(v1.id, 1);

    const ids = await snapshotCloseSuggestedIds(dispatchToken);
    expect(ids).toContain(incident.id);

    const ws: WsTestClient = await connectWs(app.baseUrl, dispatchToken);
    await ws.next(m => m.type === 'hello');
    try {
      const res = await app
        .client()
        .post(`/api/v1/incidents/${incident.id}/close`, {}, { token: dispatchToken });
      expect(res.status).toBe(200);

      const closed = await ws.next(m => m.type === 'incident.closed');
      expect((closed.data as { id: string }).id).toBe(incident.id);

      const suggestedEvent = await ws.next(m => m.type === 'incident.close_suggested');
      expect(suggestedEvent.data as CloseSuggestedEvent).toEqual({
        id: incident.id,
        suggested: false,
      });
    } finally {
      ws.close();
    }
  });
});
