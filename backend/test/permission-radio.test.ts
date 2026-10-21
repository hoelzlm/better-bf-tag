import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const MIN_MS = 60 * 1000;

interface IdJson {
  id: string;
}
interface IncidentJson {
  id: string;
  state: string;
}
interface AlarmJson {
  id: string;
  state: string;
}

/**
 * Berechtigung `radio` (Funktisch, BF-Tag ohne Handys): setzt Fahrzeugstatus,
 * sieht laufende + abgeschlossene Einsätze, alarmiert nach und schließt;
 * sieht keine Entwürfe / geplanten Alarmierungen und legt nichts an.
 */
describe('permission radio (Funktisch)', () => {
  let app: TestApp;
  let adminToken: string;
  let prepToken: string;
  let dispatchToken: string;
  let radioToken: string;
  let dayId: string;
  let vehicleId: string;
  let runningIncident: IncidentJson;
  let draftIncident: IncidentJson;
  let plannedAlarm: AlarmJson;

  async function post(path: string, body: unknown, token: string) {
    return app.client().post(`/api/v1${path}`, body, { token });
  }

  async function newIncident(keyword: string): Promise<IncidentJson> {
    const res = await post(
      `/bf-days/${dayId}/incidents`,
      { keyword, address: 'Musterstraße 1', report: 'Übung' },
      prepToken
    );
    expect(res.status).toBe(201);
    return res.body as IncidentJson;
  }

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');
    const people: Array<[string, 'preparation' | 'dispatch' | 'radio']> = [
      ['r-prep', 'preparation'],
      ['r-dispatch', 'dispatch'],
      ['r-radio', 'radio'],
    ];
    for (const [username, permission] of people) {
      await createPerson(app, {
        displayName: username,
        personType: 'supervisor',
        permission,
        username,
        password: `${username}-password`,
      });
    }
    prepToken = await loginAs(app, 'r-prep', 'r-prep-password');
    dispatchToken = await loginAs(app, 'r-dispatch', 'r-dispatch-password');
    radioToken = await loginAs(app, 'r-radio', 'r-radio-password');

    const now = app.clock.now();
    const dayRes = await post(
      '/bf-days',
      {
        name: 'Funktisch',
        starts_at: now.toISOString(),
        ends_at: new Date(now.getTime() + DAY_MS).toISOString(),
      },
      adminToken
    );
    expect(dayRes.status).toBe(201);
    dayId = (dayRes.body as IdJson).id;
    const vehicleRes = await post(
      '/vehicles',
      { call_sign: 'Florian 1', short_name: 'HLF-1', type: 'HLF' },
      adminToken
    );
    expect(vehicleRes.status).toBe(201);
    vehicleId = (vehicleRes.body as IdJson).id;
    expect((await post(`/bf-days/${dayId}/start`, {}, adminToken)).status).toBe(200);

    // Laufender Einsatz (Erstalarm sofort) ...
    runningIncident = await newIncident('B2 Laufend');
    const triggerRes = await post(
      `/incidents/${runningIncident.id}/alarms`,
      { vehicle_ids: [vehicleId] },
      dispatchToken
    );
    expect([200, 201]).toContain(triggerRes.status);
    // ... und ein Entwurf mit geplanter Alarmierung.
    draftIncident = await newIncident('TH Geplant');
    const planRes = await post(
      `/incidents/${draftIncident.id}/alarms`,
      {
        vehicle_ids: [vehicleId],
        scheduled_at: new Date(now.getTime() + 60 * MIN_MS).toISOString(),
      },
      dispatchToken
    );
    expect(planRes.status).toBe(201);
    plannedAlarm = (planRes.body as { alarm: AlarmJson }).alarm;
  });

  afterAll(async () => {
    await app.close();
  });

  it('logs in and reports permission radio', async () => {
    const res = await app
      .client()
      .post('/api/v1/auth/login', { username: 'r-radio', password: 'r-radio-password' });
    expect(res.status).toBe(200);
    expect((res.body as { person: { permission: string } }).person.permission).toBe('radio');
  });

  it('sets vehicle status (source dispatch) and reads the status history', async () => {
    const res = await app
      .client()
      .put(`/api/v1/vehicles/${vehicleId}/status`, { status: 3 }, { token: radioToken });
    expect(res.status).toBe(200);
    const history = await app
      .client()
      .get(`/api/v1/vehicles/${vehicleId}/status-history`, { token: radioToken });
    expect(history.status).toBe(200);
    const items = history.body as Array<{ status: number; source: string }>;
    expect(items[0]).toMatchObject({ status: 3, source: 'dispatch' });
  });

  it('sees the running incident but neither drafts nor planned alarms', async () => {
    const list = await app
      .client()
      .get(`/api/v1/bf-days/${dayId}/incidents`, { token: radioToken });
    expect(list.status).toBe(200);
    const ids = (list.body as IncidentJson[]).map(i => i.id);
    expect(ids).toContain(runningIncident.id);
    expect(ids).not.toContain(draftIncident.id);

    const draft = await app
      .client()
      .get(`/api/v1/incidents/${draftIncident.id}`, { token: radioToken });
    expect(draft.status).toBe(404);

    const snap = await app.client().get('/api/v1/snapshot', { token: radioToken });
    expect(snap.status).toBe(200);
    expect((snap.body as { scheduled_alarms: unknown[] }).scheduled_alarms).toEqual([]);
    expect(JSON.stringify(snap.body)).not.toContain(plannedAlarm.id);
    expect(JSON.stringify(snap.body)).not.toContain(draftIncident.id);
  });

  it('cannot create incidents or plan / touch planned alarms', async () => {
    const create = await post(
      `/bf-days/${dayId}/incidents`,
      { keyword: 'Neu', address: 'X', report: 'Y' },
      radioToken
    );
    expect(create.status).toBe(403);

    const planOnRunning = await post(
      `/incidents/${runningIncident.id}/alarms`,
      {
        vehicle_ids: [vehicleId],
        scheduled_at: new Date(app.clock.now().getTime() + 30 * MIN_MS).toISOString(),
      },
      radioToken
    );
    expect(planOnRunning.status).toBe(403);

    const alarmOnDraft = await post(
      `/incidents/${draftIncident.id}/alarms`,
      { vehicle_ids: [vehicleId] },
      radioToken
    );
    expect(alarmOnDraft.status).toBe(404);

    const edit = await app.client().patch(
      `/api/v1/incidents/${runningIncident.id}`,
      { report: 'geändert' },
      {
        token: radioToken,
      }
    );
    expect(edit.status).toBe(403);

    const discard = await post(`/alarms/${plannedAlarm.id}/discard`, {}, radioToken);
    expect(discard.status).toBe(403);
    const trigger = await post(`/alarms/${plannedAlarm.id}/trigger`, {}, radioToken);
    expect(trigger.status).toBe(403);

    const closeDraft = await post(`/incidents/${draftIncident.id}/close`, {}, radioToken);
    expect(closeDraft.status).toBe(404);
  });

  it('alarms more vehicles into the running incident (Nachalarmierung)', async () => {
    const vehicleRes = await post(
      '/vehicles',
      { call_sign: 'Florian 2', short_name: 'LF-2', type: 'LF' },
      adminToken
    );
    const extra = (vehicleRes.body as IdJson).id;
    const res = await post(
      `/incidents/${runningIncident.id}/alarms`,
      { vehicle_ids: [extra] },
      radioToken
    );
    expect([200, 201]).toContain(res.status);
  });

  it('closes the running incident and still sees it afterwards', async () => {
    const close = await post(`/incidents/${runningIncident.id}/close`, {}, radioToken);
    expect(close.status).toBe(200);
    const list = await app
      .client()
      .get(`/api/v1/bf-days/${dayId}/incidents`, { token: radioToken });
    const closed = (list.body as IncidentJson[]).find(i => i.id === runningIncident.id);
    expect(closed?.state).toBe('closed');
  });
});
