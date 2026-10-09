import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs, type WsTestClient } from './support/ws-client.js';

interface BfDayJson {
  id: string;
  state: 'planning' | 'running' | 'ended';
}

interface IncidentJson {
  id: string;
  bf_day_id: string;
  number: number;
  keyword: string;
  address: string;
  report: string;
  state: 'draft' | 'running' | 'closed' | 'discarded';
  created_at: string;
  updated_at: string;
  closed_at: string | null;
  script?: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;
const SCRIPT_MARKER = 'GEHEIM-XYZ-123';

/** Checks that neither the `script` key nor the Drehbuch marker leaked, per ADR 0016. */
function assertNoScript(raw: string): void {
  expect(raw.includes('"script"')).toBe(false);
  expect(raw.includes(SCRIPT_MARKER)).toBe(false);
}

describe('incidents', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;
  let dispatchToken: string;
  let preparationToken: string;
  let crewToken: string;

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

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'crew1',
      password: 'crew-password',
    });
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');
  });

  afterAll(async () => {
    await pool.end();
    await app.close();
  });

  async function createBfDay(name: string): Promise<BfDayJson> {
    const startsAt = new Date('2026-06-01T08:00:00Z');
    const endsAt = new Date(startsAt.getTime() + DAY_MS);
    const res = await app.client().post(
      '/api/v1/bf-days',
      {
        name,
        starts_at: startsAt.toISOString(),
        ends_at: endsAt.toISOString(),
      },
      { token: adminToken }
    );
    expect(res.status).toBe(201);
    return res.body as BfDayJson;
  }

  async function monitorToken(): Promise<string> {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: `Standby ${Math.random()}` }, { token: adminToken });
    const monitorId = (createRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    return (pairRes.body as { access_token: string }).access_token;
  }

  async function createIncident(
    bfDayId: string,
    overrides?: Partial<{ keyword: string; address: string; report: string; script: string }>,
    token: string = preparationToken
  ): Promise<{ status: number; body: IncidentJson }> {
    const res = await app.client().post(
      `/api/v1/bf-days/${bfDayId}/incidents`,
      {
        keyword: 'Wohnungsbrand',
        address: 'Musterstraße 1',
        report: 'Rauch aus dem Fenster',
        script: SCRIPT_MARKER,
        ...overrides,
      },
      { token }
    );
    return { status: res.status, body: res.body as IncidentJson };
  }

  async function setState(incidentId: string, state: string): Promise<void> {
    await pool.query(`update incident set state = $1 where id = $2`, [state, incidentId]);
  }

  describe('permissions', () => {
    it('preparation/dispatch/admin can create/patch/discard; crew/monitor -> 403', async () => {
      const day = await createBfDay('Perm');
      const monitor = await monitorToken();

      for (const token of [preparationToken, dispatchToken, adminToken]) {
        const created = await createIncident(day.id, {}, token);
        expect(created.status).toBe(201);

        const patched = await app
          .client()
          .patch(`/api/v1/incidents/${created.body.id}`, { keyword: 'Geändert' }, { token });
        expect(patched.status).toBe(200);

        const discarded = await app
          .client()
          .post(`/api/v1/incidents/${created.body.id}/discard`, {}, { token });
        expect(discarded.status).toBe(200);
      }

      for (const token of [crewToken, monitor]) {
        const createRes = await app
          .client()
          .post(`/api/v1/bf-days/${day.id}/incidents`, { keyword: 'x', address: 'y' }, { token });
        expect(createRes.status).toBe(403);
      }

      const draft = await createIncident(day.id);
      for (const token of [crewToken, monitor]) {
        const patched = await app
          .client()
          .patch(`/api/v1/incidents/${draft.body.id}`, { keyword: 'x' }, { token });
        expect(patched.status).toBe(403);

        const discarded = await app
          .client()
          .post(`/api/v1/incidents/${draft.body.id}/discard`, {}, { token });
        expect(discarded.status).toBe(403);
      }
    });
  });

  describe('numbering', () => {
    it('numbers 1,2,3 per bf-day independently, discarded number not reused', async () => {
      const dayA = await createBfDay('Numbering-A');
      const dayB = await createBfDay('Numbering-B');

      const a1 = await createIncident(dayA.id);
      const a2 = await createIncident(dayA.id);
      expect(a1.body.number).toBe(1);
      expect(a2.body.number).toBe(2);

      await app
        .client()
        .post(`/api/v1/incidents/${a2.body.id}/discard`, {}, { token: preparationToken });
      const a3 = await createIncident(dayA.id);
      expect(a3.body.number).toBe(3);

      const b1 = await createIncident(dayB.id);
      expect(b1.body.number).toBe(1);
    });
  });

  describe('state rules', () => {
    it('patch draft/running ok; closed/discarded -> 409 incident_not_editable', async () => {
      const day = await createBfDay('StateRules');

      const draft = await createIncident(day.id);
      const draftPatch = await app
        .client()
        .patch(`/api/v1/incidents/${draft.body.id}`, { keyword: 'x' }, { token: preparationToken });
      expect(draftPatch.status).toBe(200);

      const running = await createIncident(day.id);
      await setState(running.body.id, 'running');
      const runningPatch = await app
        .client()
        .patch(
          `/api/v1/incidents/${running.body.id}`,
          { keyword: 'x' },
          { token: preparationToken }
        );
      expect(runningPatch.status).toBe(200);

      const closed = await createIncident(day.id);
      await setState(closed.body.id, 'closed');
      const closedPatch = await app
        .client()
        .patch(
          `/api/v1/incidents/${closed.body.id}`,
          { keyword: 'x' },
          { token: preparationToken }
        );
      expect(closedPatch.status).toBe(409);
      expect(closedPatch.body).toMatchObject({ error: { code: 'incident_not_editable' } });

      const discarded = await createIncident(day.id);
      await setState(discarded.body.id, 'discarded');
      const discardedPatch = await app
        .client()
        .patch(
          `/api/v1/incidents/${discarded.body.id}`,
          { keyword: 'x' },
          { token: preparationToken }
        );
      expect(discardedPatch.status).toBe(409);
      expect(discardedPatch.body).toMatchObject({ error: { code: 'incident_not_editable' } });
    });

    it('discard running -> 409 invalid_state_transition', async () => {
      const day = await createBfDay('DiscardRunning');
      const incident = await createIncident(day.id);
      await setState(incident.body.id, 'running');

      const res = await app
        .client()
        .post(`/api/v1/incidents/${incident.body.id}/discard`, {}, { token: preparationToken });
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'invalid_state_transition' } });
    });

    it('create on an ended bf-day -> 409 bf_day_ended', async () => {
      const day = await createBfDay('EndedCreate');
      await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });
      await app.client().post(`/api/v1/bf-days/${day.id}/end`, {}, { token: adminToken });

      const res = await createIncident(day.id);
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'bf_day_ended' } });
    });

    it('validation: empty keyword and too-long script -> 400', async () => {
      const day = await createBfDay('Validation');

      const emptyKeyword = await createIncident(day.id, { keyword: '  ' });
      expect(emptyKeyword.status).toBe(400);
      expect(emptyKeyword.body).toMatchObject({ error: { code: 'validation_error' } });

      const tooLongScript = await createIncident(day.id, { script: 'x'.repeat(20001) });
      expect(tooLongScript.status).toBe(400);
      expect(tooLongScript.body).toMatchObject({ error: { code: 'validation_error' } });
    });
  });

  describe('Drehbuch filter', () => {
    async function createRunningIncident(dayId: string): Promise<IncidentJson> {
      const created = await createIncident(dayId);
      await setState(created.body.id, 'running');
      return created.body;
    }

    it('REST list/detail: crew sees no script on a running incident, preparation/dispatch do', async () => {
      const day = await createBfDay('DrehbuchRest');
      const running = await createRunningIncident(day.id);

      const crewList = await app
        .client()
        .get(`/api/v1/bf-days/${day.id}/incidents`, { token: crewToken });
      expect(crewList.status).toBe(200);
      assertNoScript(JSON.stringify(crewList.body));
      expect((crewList.body as IncidentJson[]).some(i => i.id === running.id)).toBe(true);

      const crewDetail = await app
        .client()
        .get(`/api/v1/incidents/${running.id}`, { token: crewToken });
      expect(crewDetail.status).toBe(200);
      assertNoScript(JSON.stringify(crewDetail.body));

      for (const token of [preparationToken, dispatchToken]) {
        const list = await app.client().get(`/api/v1/bf-days/${day.id}/incidents`, { token });
        const found = (list.body as IncidentJson[]).find(i => i.id === running.id);
        expect(found?.script).toBe(SCRIPT_MARKER);

        const detail = await app.client().get(`/api/v1/incidents/${running.id}`, { token });
        expect((detail.body as IncidentJson).script).toBe(SCRIPT_MARKER);
      }
    });

    it('crew list never contains drafts; crew detail of a draft -> 404', async () => {
      const day = await createBfDay('DrehbuchDraft');
      const draft = await createIncident(day.id);

      const crewList = await app
        .client()
        .get(`/api/v1/bf-days/${day.id}/incidents`, { token: crewToken });
      expect((crewList.body as IncidentJson[]).some(i => i.id === draft.body.id)).toBe(false);

      const draftFilterList = await app
        .client()
        .get(`/api/v1/bf-days/${day.id}/incidents?state=draft`, { token: crewToken });
      expect(draftFilterList.body).toEqual([]);

      const crewDetail = await app
        .client()
        .get(`/api/v1/incidents/${draft.body.id}`, { token: crewToken });
      expect(crewDetail.status).toBe(404);
    });

    it('snapshot: crew and monitor see incidents without script, dispatch sees script', async () => {
      const day = await createBfDay('DrehbuchSnapshot');
      const running = await createRunningIncident(day.id);
      await app.client().post(`/api/v1/bf-days/${day.id}/start`, {}, { token: adminToken });

      const monitor = await monitorToken();
      for (const token of [crewToken, monitor]) {
        const res = await app.client().get('/api/v1/snapshot', { token });
        expect(res.status).toBe(200);
        assertNoScript(JSON.stringify(res.body));
        const incidents = (res.body as { incidents: IncidentJson[] }).incidents;
        expect(incidents.some(i => i.id === running.id)).toBe(true);
      }

      const dispatchRes = await app.client().get('/api/v1/snapshot', { token: dispatchToken });
      const dispatchIncidents = (dispatchRes.body as { incidents: IncidentJson[] }).incidents;
      expect(dispatchIncidents.find(i => i.id === running.id)?.script).toBe(SCRIPT_MARKER);

      await app.client().post(`/api/v1/bf-days/${day.id}/end`, {}, { token: adminToken });
    });

    it('WebSocket: crew/monitor get skip for incident.created, no script on incident.updated; preparation gets script', async () => {
      const day = await createBfDay('DrehbuchWs');
      const monitor = await monitorToken();

      const crewWs = await connectWs(app.baseUrl, crewToken);
      const monitorWs = await connectWs(app.baseUrl, monitor);
      const prepWs = await connectWs(app.baseUrl, preparationToken);
      await Promise.all([
        crewWs.next(m => m.type === 'hello'),
        monitorWs.next(m => m.type === 'hello'),
        prepWs.next(m => m.type === 'hello'),
      ]);

      try {
        const created = await createIncident(day.id);

        const crewCreatedSkip = await crewWs.next(
          m => m.type === 'skip' || m.type === 'incident.created'
        );
        expect(crewCreatedSkip.type).toBe('skip');
        const monitorCreatedSkip = await monitorWs.next(
          m => m.type === 'skip' || m.type === 'incident.created'
        );
        expect(monitorCreatedSkip.type).toBe('skip');
        const prepCreated = await prepWs.next(m => m.type === 'incident.created');
        expect((prepCreated as { data: IncidentJson }).data.script).toBe(SCRIPT_MARKER);

        await setState(created.body.id, 'running');
        const patchRes = await app
          .client()
          .patch(
            `/api/v1/incidents/${created.body.id}`,
            { keyword: 'Update' },
            { token: preparationToken }
          );
        expect(patchRes.status).toBe(200);

        const crewUpdated = await crewWs.next(m => m.type === 'incident.updated');
        const raw = JSON.stringify(crewUpdated);
        expect(raw.includes('"script"')).toBe(false);
        expect(raw.includes(SCRIPT_MARKER)).toBe(false);
        expect((crewUpdated.data as IncidentJson).keyword).toBe('Update');

        const monitorUpdated = await monitorWs.next(m => m.type === 'incident.updated');
        const monitorRaw = JSON.stringify(monitorUpdated);
        expect(monitorRaw.includes('"script"')).toBe(false);
        expect(monitorRaw.includes(SCRIPT_MARKER)).toBe(false);

        const prepUpdated = await prepWs.next(m => m.type === 'incident.updated');
        expect((prepUpdated.data as IncidentJson).script).toBe(SCRIPT_MARKER);
      } finally {
        crewWs.close();
        monitorWs.close();
        prepWs.close();
      }
    });
  });

  describe('close (ADR 0019)', () => {
    async function createRunningIncident(dayId: string): Promise<IncidentJson> {
      const created = await createIncident(dayId);
      await setState(created.body.id, 'running');
      return created.body;
    }

    it('dispatch and admin can close a running incident -> 200, closed_at set, events incident.updated then incident.closed', async () => {
      for (const token of [dispatchToken, adminToken]) {
        const day = await createBfDay(`Close-${token === dispatchToken ? 'dispatch' : 'admin'}`);
        const running = await createRunningIncident(day.id);

        const ws = await connectWs(app.baseUrl, dispatchToken);
        await ws.next(m => m.type === 'hello');
        try {
          const res = await app
            .client()
            .post(`/api/v1/incidents/${running.id}/close`, {}, { token });
          expect(res.status).toBe(200);
          const body = res.body as { incident: IncidentJson; discarded_alarm_ids: string[] };
          expect(body.incident.state).toBe('closed');
          expect(body.incident.closed_at).not.toBeNull();
          expect(body.discarded_alarm_ids).toEqual([]);

          const updated = await ws.next(m => m.type === 'incident.updated');
          expect((updated.data as IncidentJson).state).toBe('closed');

          const closed = await ws.next(m => m.type === 'incident.closed');
          expect((closed.data as { id: string }).id).toBe(running.id);
        } finally {
          ws.close();
        }
      }
    });

    it('preparation and crew -> 403 forbidden', async () => {
      const day = await createBfDay('ClosePerm');
      const running = await createRunningIncident(day.id);

      for (const token of [preparationToken, crewToken]) {
        const res = await app.client().post(`/api/v1/incidents/${running.id}/close`, {}, { token });
        expect(res.status).toBe(403);
        expect(res.body).toMatchObject({ error: { code: 'forbidden' } });
      }
    });

    it('unknown incident -> 404 not_found', async () => {
      const res = await app
        .client()
        .post(
          '/api/v1/incidents/00000000-0000-4000-8000-000000000099/close',
          {},
          { token: dispatchToken }
        );
      expect(res.status).toBe(404);
    });

    it('draft incident -> 409 invalid_state_transition', async () => {
      const day = await createBfDay('CloseDraft');
      const draft = await createIncident(day.id);

      const res = await app
        .client()
        .post(`/api/v1/incidents/${draft.body.id}/close`, {}, { token: dispatchToken });
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'invalid_state_transition' } });
    });

    it('closing twice -> second time 409 invalid_state_transition', async () => {
      const day = await createBfDay('CloseTwice');
      const running = await createRunningIncident(day.id);

      const first = await app
        .client()
        .post(`/api/v1/incidents/${running.id}/close`, {}, { token: dispatchToken });
      expect(first.status).toBe(200);

      const second = await app
        .client()
        .post(`/api/v1/incidents/${running.id}/close`, {}, { token: dispatchToken });
      expect(second.status).toBe(409);
      expect(second.body).toMatchObject({ error: { code: 'invalid_state_transition' } });
    });

    it('discards planned alarms and lists them in discarded_alarm_ids', async () => {
      const day = await createBfDay('ClosePlanned');
      const running = await createRunningIncident(day.id);

      const plannedRes = await pool.query<{ id: string }>(
        `insert into alarm (incident_id, state, created_at) values ($1, 'planned', now()) returning id`,
        [running.id]
      );
      const plannedAlarmId = plannedRes.rows[0]?.id;
      expect(plannedAlarmId).toBeTruthy();

      const res = await app
        .client()
        .post(`/api/v1/incidents/${running.id}/close`, {}, { token: dispatchToken });
      expect(res.status).toBe(200);
      const body = res.body as { discarded_alarm_ids: string[] };
      expect(body.discarded_alarm_ids).toEqual([plannedAlarmId]);

      const alarmState = await pool.query<{ state: string }>(
        `select state from alarm where id = $1`,
        [plannedAlarmId]
      );
      expect(alarmState.rows[0]?.state).toBe('discarded');
    });

    it('crew sees the closed incident without the script key', async () => {
      const day = await createBfDay('CloseScript');
      const running = await createRunningIncident(day.id);
      await app
        .client()
        .post(`/api/v1/incidents/${running.id}/close`, {}, { token: dispatchToken });

      const crewDetail = await app
        .client()
        .get(`/api/v1/incidents/${running.id}`, { token: crewToken });
      expect(crewDetail.status).toBe(200);
      assertNoScript(JSON.stringify(crewDetail.body));
      expect((crewDetail.body as IncidentJson).state).toBe('closed');
    });
  });

  describe('realtime.ts: event without project unchanged', () => {
    it('existing events without a project still deliver data as-is (regression via shift.crew_changed)', async () => {
      const day = await createBfDay('RealtimeRegression');
      const ws: WsTestClient = await connectWs(app.baseUrl, adminToken);
      await ws.next(m => m.type === 'hello');
      try {
        const res = await app
          .client()
          .post(
            `/api/v1/bf-days/${day.id}/shifts`,
            { name: 'x', starts_at: '2026-06-01T08:00:00Z', ends_at: '2026-06-01T09:00:00Z' },
            { token: dispatchToken }
          );
        expect(res.status).toBe(201);
        const event = await ws.next(m => m.type === 'shift.crew_changed');
        expect((event.data as { bf_day_id: string }).bf_day_id).toBe(day.id);
      } finally {
        ws.close();
      }
    });
  });
});
