import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

interface BfDayJson {
  id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  state: 'planning' | 'running' | 'ended';
  anonymized_at: string | null;
  created_at: string;
}

interface ParticipantJson {
  person_id: string;
  display_name: string;
  person_type: 'youth' | 'supervisor';
  permission: 'crew' | 'preparation' | 'dispatch' | 'admin';
  fire_department_id: string;
}

interface ShiftJson {
  id: string;
  bf_day_id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  crew: Array<{ vehicle_id: string; person_id: string; display_name: string; function: string }>;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function createBfDayBody(
  overrides?: Partial<{ name: string; starts_at: string; ends_at: string }>
) {
  const startsAt = new Date('2026-06-01T08:00:00Z');
  const endsAt = new Date(startsAt.getTime() + DAY_MS);
  return {
    name: 'BF-Tag Juni',
    starts_at: startsAt.toISOString(),
    ends_at: endsAt.toISOString(),
    ...overrides,
  };
}

describe('bf-days', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;
  let dispatchToken: string;
  let crewToken: string;
  let preparationToken: string;

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

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'crew1',
      password: 'crew-password',
    });
    // permission=crew cannot log in (ADR 0010); sign a token directly.
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'prep1',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'prep1', 'prep-password');
  });

  afterAll(async () => {
    await pool.end();
    await app.close();
  });

  async function createBfDay(
    overrides?: Partial<{ name: string; starts_at: string; ends_at: string }>
  ): Promise<BfDayJson> {
    const res = await app
      .client()
      .post('/api/v1/bf-days', createBfDayBody(overrides), { token: adminToken });
    expect(res.status).toBe(201);
    return res.body as BfDayJson;
  }

  async function monitorToken(): Promise<string> {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'Standby bf-days' }, { token: adminToken });
    const monitorId = (createRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    return (pairRes.body as { access_token: string }).access_token;
  }

  describe('create', () => {
    it('creates a BF-Tag in planning with a default shift over the full period', async () => {
      const created = await createBfDay({ name: 'Erstellungstest' });
      expect(created).toMatchObject({
        name: 'Erstellungstest',
        state: 'planning',
        anonymized_at: null,
      });
      expect(created.id).toBeTruthy();

      const shifts = await pool.query<{
        name: string;
        starts_at: Date;
        ends_at: Date;
      }>('select name, starts_at, ends_at from shift where bf_day_id = $1', [created.id]);
      expect(shifts.rows).toHaveLength(1);
      expect(shifts.rows[0]!.name).toBe('Schicht 1');
      expect(shifts.rows[0]!.starts_at.toISOString()).toBe(created.starts_at);
      expect(shifts.rows[0]!.ends_at.toISOString()).toBe(created.ends_at);
    });

    it('rejects ends_at <= starts_at with 400', async () => {
      const res = await app
        .client()
        .post(
          '/api/v1/bf-days',
          createBfDayBody({ starts_at: '2026-06-01T08:00:00Z', ends_at: '2026-06-01T08:00:00Z' }),
          { token: adminToken }
        );
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'validation_error' } });
    });

    it('appears in GET /bf-days and GET /bf-days/{id}', async () => {
      const created = await createBfDay({ name: 'Listentest' });

      const list = await app.client().get('/api/v1/bf-days', { token: dispatchToken });
      expect(list.status).toBe(200);
      expect((list.body as BfDayJson[]).some(d => d.id === created.id)).toBe(true);

      const get = await app.client().get(`/api/v1/bf-days/${created.id}`, { token: crewToken });
      expect(get.status).toBe(200);
      expect((get.body as BfDayJson).id).toBe(created.id);
    });
  });

  describe('current resolution', () => {
    it('404s for current when nothing is running, and resolves once started', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const notRunning = await freshApp
          .client()
          .get('/api/v1/bf-days/current', { token: freshAdminToken });
        expect(notRunning.status).toBe(404);
        expect(notRunning.body).toMatchObject({ error: { code: 'not_found' } });

        const createRes = await freshApp
          .client()
          .post('/api/v1/bf-days', createBfDayBody(), { token: freshAdminToken });
        const created = createRes.body as BfDayJson;

        await freshApp
          .client()
          .post(`/api/v1/bf-days/${created.id}/start`, {}, { token: freshAdminToken });

        const running = await freshApp
          .client()
          .get('/api/v1/bf-days/current', { token: freshAdminToken });
        expect(running.status).toBe(200);
        expect((running.body as BfDayJson).id).toBe(created.id);
      } finally {
        await freshApp.close();
      }
    });

    it('404s for an unknown or malformed id', async () => {
      const unknown = await app
        .client()
        .get('/api/v1/bf-days/00000000-0000-0000-0000-000000000000', { token: adminToken });
      expect(unknown.status).toBe(404);

      const malformed = await app.client().get('/api/v1/bf-days/not-a-uuid', { token: adminToken });
      expect(malformed.status).toBe(404);
    });
  });

  describe('state transitions', () => {
    it('starts from planning; a second bf-day cannot start while one is running (409)', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const first = (
          await freshApp.client().post('/api/v1/bf-days', createBfDayBody({ name: 'Erster' }), {
            token: freshAdminToken,
          })
        ).body as BfDayJson;
        const second = (
          await freshApp.client().post(
            '/api/v1/bf-days',
            createBfDayBody({
              name: 'Zweiter',
              starts_at: '2026-07-01T08:00:00Z',
              ends_at: '2026-07-02T08:00:00Z',
            }),
            { token: freshAdminToken }
          )
        ).body as BfDayJson;

        const startFirst = await freshApp
          .client()
          .post(`/api/v1/bf-days/${first.id}/start`, {}, { token: freshAdminToken });
        expect(startFirst.status).toBe(200);
        expect((startFirst.body as BfDayJson).state).toBe('running');

        const startSecond = await freshApp
          .client()
          .post(`/api/v1/bf-days/${second.id}/start`, {}, { token: freshAdminToken });
        expect(startSecond.status).toBe(409);
        expect(startSecond.body).toMatchObject({ error: { code: 'bf_day_already_running' } });
      } finally {
        await freshApp.close();
      }
    });

    it('rejects invalid transitions: end from planning, start/end from ended, start twice', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const created = (
          await freshApp
            .client()
            .post('/api/v1/bf-days', createBfDayBody(), { token: freshAdminToken })
        ).body as BfDayJson;

        const endFromPlanning = await freshApp
          .client()
          .post(`/api/v1/bf-days/${created.id}/end`, {}, { token: freshAdminToken });
        expect(endFromPlanning.status).toBe(409);
        expect(endFromPlanning.body).toMatchObject({
          error: { code: 'invalid_state_transition' },
        });

        await freshApp
          .client()
          .post(`/api/v1/bf-days/${created.id}/start`, {}, { token: freshAdminToken });

        const startAgain = await freshApp
          .client()
          .post(`/api/v1/bf-days/${created.id}/start`, {}, { token: freshAdminToken });
        expect(startAgain.status).toBe(409);
        expect(startAgain.body).toMatchObject({ error: { code: 'invalid_state_transition' } });

        const end = await freshApp
          .client()
          .post(`/api/v1/bf-days/${created.id}/end`, {}, { token: freshAdminToken });
        expect(end.status).toBe(200);
        expect((end.body as BfDayJson).state).toBe('ended');

        const startAfterEnd = await freshApp
          .client()
          .post(`/api/v1/bf-days/${created.id}/start`, {}, { token: freshAdminToken });
        expect(startAfterEnd.status).toBe(409);
        expect(startAfterEnd.body).toMatchObject({ error: { code: 'invalid_state_transition' } });

        const endAgain = await freshApp
          .client()
          .post(`/api/v1/bf-days/${created.id}/end`, {}, { token: freshAdminToken });
        expect(endAgain.status).toBe(409);
        expect(endAgain.body).toMatchObject({ error: { code: 'invalid_state_transition' } });
      } finally {
        await freshApp.close();
      }
    });
  });

  describe('database constraints', () => {
    it('the partial unique index rejects a second running row inserted directly via SQL', async () => {
      const a = await pool.query<{ id: string }>(
        `insert into bf_day (name, starts_at, ends_at, state, created_at)
         values ($1, $2, $3, 'running', now()) returning id`,
        ['SQL A', '2026-08-01T00:00:00Z', '2026-08-02T00:00:00Z']
      );
      expect(a.rows).toHaveLength(1);

      await expect(
        pool.query(
          `insert into bf_day (name, starts_at, ends_at, state, created_at)
           values ($1, $2, $3, 'running', now())`,
          ['SQL B', '2026-09-01T00:00:00Z', '2026-09-02T00:00:00Z']
        )
      ).rejects.toMatchObject({ code: '23505' });

      // Clean up so this doesn't interfere with later tests in this file.
      await pool.query(`update bf_day set state = 'ended' where id = $1`, [a.rows[0]!.id]);
    });
  });

  describe('patch', () => {
    it('patches name and period when the shift still fits', async () => {
      const created = await createBfDay({
        name: 'Patch-Test',
        starts_at: '2026-06-01T08:00:00Z',
        ends_at: '2026-06-02T08:00:00Z',
      });

      const patched = await app
        .client()
        .patch(
          `/api/v1/bf-days/${created.id}`,
          { name: 'Patch-Test geändert' },
          { token: adminToken }
        );
      expect(patched.status).toBe(200);
      expect((patched.body as BfDayJson).name).toBe('Patch-Test geändert');
    });

    it('moving the bf-day boundary moves a shift boundary that was exactly on it', async () => {
      const created = await createBfDay({
        name: 'Boundary-Move',
        starts_at: '2026-06-01T08:00:00Z',
        ends_at: '2026-06-02T08:00:00Z',
      });

      const newEndsAt = '2026-06-02T10:00:00Z';
      const patched = await app
        .client()
        .patch(`/api/v1/bf-days/${created.id}`, { ends_at: newEndsAt }, { token: adminToken });
      expect(patched.status).toBe(200);
      expect((patched.body as BfDayJson).ends_at).toBe(new Date(newEndsAt).toISOString());

      const shifts = await pool.query<{ ends_at: Date }>(
        'select ends_at from shift where bf_day_id = $1',
        [created.id]
      );
      expect(shifts.rows).toHaveLength(1);
      expect(shifts.rows[0]!.ends_at.toISOString()).toBe(new Date(newEndsAt).toISOString());
    });

    it('rejects a period change that would leave a shift outside the bf-day (409 shift_outside_bf_day), changing nothing', async () => {
      const created = await createBfDay({
        name: 'Boundary-Reject',
        starts_at: '2026-06-01T08:00:00Z',
        ends_at: '2026-06-02T08:00:00Z',
      });

      // Insert a second shift with boundaries NOT on the bf-day's edges, so
      // shrinking the period leaves it outside.
      await pool.query(
        `insert into shift (bf_day_id, name, starts_at, ends_at, created_at)
         values ($1, 'Nachtschicht', '2026-06-01T22:00:00Z', '2026-06-02T06:00:00Z', now())`,
        [created.id]
      );

      const patched = await app
        .client()
        .patch(
          `/api/v1/bf-days/${created.id}`,
          { ends_at: '2026-06-02T01:00:00Z' },
          { token: adminToken }
        );
      expect(patched.status).toBe(409);
      expect(patched.body).toMatchObject({ error: { code: 'shift_outside_bf_day' } });

      // Nothing changed: the bf-day keeps its original period.
      const reloaded = await app
        .client()
        .get(`/api/v1/bf-days/${created.id}`, { token: adminToken });
      expect((reloaded.body as BfDayJson).ends_at).toBe('2026-06-02T08:00:00.000Z');
    });

    it('rejects patching an ended bf-day with 409 bf_day_ended', async () => {
      const created = await createBfDay({ name: 'Ended-Patch' });
      await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: adminToken });
      await app.client().post(`/api/v1/bf-days/${created.id}/end`, {}, { token: adminToken });

      const patched = await app
        .client()
        .patch(`/api/v1/bf-days/${created.id}`, { name: 'x' }, { token: adminToken });
      expect(patched.status).toBe(409);
      expect(patched.body).toMatchObject({ error: { code: 'bf_day_ended' } });
    });
  });

  describe('participants', () => {
    it('replaces the full set, is idempotent, rejects unknown/inactive persons being added with 400', async () => {
      const created = await createBfDay({ name: 'Teilnahme' });

      const p1 = await createPerson(app, {
        displayName: 'Teilnehmer A',
        personType: 'youth',
        permission: 'crew',
        username: 'teilnehmer-a',
        password: 'teilnehmer-a-password',
      });
      const p2 = await createPerson(app, {
        displayName: 'Teilnehmer B',
        personType: 'supervisor',
        permission: 'crew',
        username: 'teilnehmer-b',
        password: 'teilnehmer-b-password',
      });

      const setRes = await app
        .client()
        .put(
          `/api/v1/bf-days/${created.id}/participants`,
          { person_ids: [p1.id, p2.id] },
          { token: adminToken }
        );
      expect(setRes.status).toBe(200);
      const participants = setRes.body as ParticipantJson[];
      expect(participants.map(p => p.person_id).sort()).toEqual([p1.id, p2.id].sort());
      // sorted by display_name
      expect(participants.map(p => p.display_name)).toEqual(['Teilnehmer A', 'Teilnehmer B']);

      // idempotent replace with the same set
      const again = await app
        .client()
        .put(
          `/api/v1/bf-days/${created.id}/participants`,
          { person_ids: [p1.id, p2.id] },
          { token: adminToken }
        );
      expect(again.status).toBe(200);
      expect((again.body as ParticipantJson[]).map(p => p.person_id).sort()).toEqual(
        [p1.id, p2.id].sort()
      );

      const getRes = await app
        .client()
        .get(`/api/v1/bf-days/${created.id}/participants`, { token: dispatchToken });
      expect(getRes.status).toBe(200);
      expect((getRes.body as ParticipantJson[]).map(p => p.person_id).sort()).toEqual(
        [p1.id, p2.id].sort()
      );

      // unknown id
      const unknownId = '00000000-0000-0000-0000-000000000000';
      const withUnknown = await app
        .client()
        .put(
          `/api/v1/bf-days/${created.id}/participants`,
          { person_ids: [p1.id, unknownId] },
          { token: adminToken }
        );
      expect(withUnknown.status).toBe(400);
      expect(withUnknown.body).toMatchObject({ error: { code: 'validation_error' } });

      // inactive person being added
      const inactivePerson = await createPerson(app, {
        displayName: 'Inaktiv',
        personType: 'youth',
        permission: 'crew',
        username: 'inaktiv-teilnahme',
        password: 'inaktiv-password',
      });
      await pool.query('update person set active = false where id = $1', [inactivePerson.id]);
      const withInactive = await app
        .client()
        .put(
          `/api/v1/bf-days/${created.id}/participants`,
          { person_ids: [p1.id, inactivePerson.id] },
          { token: adminToken }
        );
      expect(withInactive.status).toBe(400);
      expect(withInactive.body).toMatchObject({ error: { code: 'validation_error' } });
    });

    it('removing a participant deletes their crew assignments and emits shift.crew_changed per affected shift', async () => {
      const created = await createBfDay({ name: 'Teilnahme entfernen' });

      const p1 = await createPerson(app, {
        displayName: 'Crew A',
        personType: 'youth',
        permission: 'crew',
        username: 'crew-a-remove',
        password: 'crew-a-password',
      });
      const p2 = await createPerson(app, {
        displayName: 'Crew B',
        personType: 'youth',
        permission: 'crew',
        username: 'crew-b-remove',
        password: 'crew-b-password',
      });

      await app
        .client()
        .put(
          `/api/v1/bf-days/${created.id}/participants`,
          { person_ids: [p1.id, p2.id] },
          { token: adminToken }
        );

      const vehicleRes = await app
        .client()
        .post(
          '/api/v1/vehicles',
          { call_sign: 'Teilnahme-Fahrzeug', short_name: 'TF', type: 'HLF' },
          { token: adminToken }
        );
      const vehicleId = (vehicleRes.body as { id: string }).id;

      const shiftRow = await pool.query<{ id: string }>(
        'select id from shift where bf_day_id = $1',
        [created.id]
      );
      const shiftId = shiftRow.rows[0]!.id;

      await pool.query(
        `insert into crew_assignment (shift_id, vehicle_id, person_id, "function")
         values ($1, $2, $3, 'GF'), ($1, $2, $4, 'MA')`,
        [shiftId, vehicleId, p1.id, p2.id]
      );

      const ws = await connectWs(app.baseUrl, adminToken);
      await ws.next(m => m.type === 'hello');
      try {
        const removeRes = await app
          .client()
          .put(
            `/api/v1/bf-days/${created.id}/participants`,
            { person_ids: [p2.id] },
            { token: adminToken }
          );
        expect(removeRes.status).toBe(200);
        expect((removeRes.body as ParticipantJson[]).map(p => p.person_id)).toEqual([p2.id]);

        const event = await ws.next(m => m.type === 'shift.crew_changed');
        const shiftJson = event.data as ShiftJson;
        expect(shiftJson.id).toBe(shiftId);
        expect(shiftJson.crew.map(c => c.person_id)).toEqual([p2.id]);

        const remaining = await pool.query(
          'select person_id from crew_assignment where shift_id = $1',
          [shiftId]
        );
        expect(remaining.rows.map(r => r.person_id)).toEqual([p2.id]);
      } finally {
        ws.close();
      }
    });

    it('rejects participants writes on an ended bf-day with 409 bf_day_ended', async () => {
      const created = await createBfDay({ name: 'Ended-Teilnahme' });
      await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: adminToken });
      await app.client().post(`/api/v1/bf-days/${created.id}/end`, {}, { token: adminToken });

      const res = await app
        .client()
        .put(
          `/api/v1/bf-days/${created.id}/participants`,
          { person_ids: [] },
          { token: adminToken }
        );
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'bf_day_ended' } });
    });
  });

  describe('permissions', () => {
    it('GET /bf-days and GET /bf-days/{day} are open to any authenticated Person, 401 without a token, 403 for a monitor', async () => {
      const created = await createBfDay({ name: 'Permission-Get' });
      const token = await monitorToken();

      for (const t of [adminToken, dispatchToken, crewToken, preparationToken]) {
        expect((await app.client().get('/api/v1/bf-days', { token: t })).status).toBe(200);
        expect((await app.client().get(`/api/v1/bf-days/${created.id}`, { token: t })).status).toBe(
          200
        );
      }
      expect((await app.client().get('/api/v1/bf-days')).status).toBe(401);
      expect((await app.client().get('/api/v1/bf-days', { token })).status).toBe(403);
      expect((await app.client().get(`/api/v1/bf-days/${created.id}`, { token })).status).toBe(403);
    });

    it('only admin can create/patch/start/end a bf-day; monitor gets 403', async () => {
      const monitor = await monitorToken();
      const created = await createBfDay({ name: 'Permission-Write' });

      for (const t of [dispatchToken, crewToken, preparationToken]) {
        expect(
          (await app.client().post('/api/v1/bf-days', createBfDayBody(), { token: t })).status
        ).toBe(403);
        expect(
          (await app.client().patch(`/api/v1/bf-days/${created.id}`, { name: 'x' }, { token: t }))
            .status
        ).toBe(403);
        expect(
          (await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: t })).status
        ).toBe(403);
        expect(
          (await app.client().post(`/api/v1/bf-days/${created.id}/end`, {}, { token: t })).status
        ).toBe(403);
      }

      expect(
        (await app.client().post('/api/v1/bf-days', createBfDayBody(), { token: monitor })).status
      ).toBe(403);
      expect(
        (
          await app
            .client()
            .patch(`/api/v1/bf-days/${created.id}`, { name: 'x' }, { token: monitor })
        ).status
      ).toBe(403);
      expect(
        (await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: monitor }))
          .status
      ).toBe(403);
      expect((await app.client().post('/api/v1/bf-days', createBfDayBody())).status).toBe(401);
    });

    it('participants GET allows admin and dispatch, 403 for crew/preparation/monitor; PUT is admin-only', async () => {
      const created = await createBfDay({ name: 'Permission-Participants' });
      const monitor = await monitorToken();

      expect(
        (
          await app
            .client()
            .get(`/api/v1/bf-days/${created.id}/participants`, { token: adminToken })
        ).status
      ).toBe(200);
      expect(
        (
          await app
            .client()
            .get(`/api/v1/bf-days/${created.id}/participants`, { token: dispatchToken })
        ).status
      ).toBe(200);
      expect(
        (await app.client().get(`/api/v1/bf-days/${created.id}/participants`, { token: crewToken }))
          .status
      ).toBe(403);
      expect(
        (
          await app
            .client()
            .get(`/api/v1/bf-days/${created.id}/participants`, { token: preparationToken })
        ).status
      ).toBe(403);
      expect(
        (await app.client().get(`/api/v1/bf-days/${created.id}/participants`, { token: monitor }))
          .status
      ).toBe(403);
      expect((await app.client().get(`/api/v1/bf-days/${created.id}/participants`)).status).toBe(
        401
      );

      expect(
        (
          await app
            .client()
            .put(
              `/api/v1/bf-days/${created.id}/participants`,
              { person_ids: [] },
              { token: dispatchToken }
            )
        ).status
      ).toBe(403);
      expect(
        (
          await app
            .client()
            .put(
              `/api/v1/bf-days/${created.id}/participants`,
              { person_ids: [] },
              { token: monitor }
            )
        ).status
      ).toBe(403);
    });
  });

  describe('realtime', () => {
    it('emits bf_day.updated on create, patch, start and end', async () => {
      const ws = await connectWs(app.baseUrl, adminToken);
      await ws.next(m => m.type === 'hello');
      try {
        const createRes = await app
          .client()
          .post('/api/v1/bf-days', createBfDayBody({ name: 'Realtime' }), { token: adminToken });
        const created = createRes.body as BfDayJson;
        const createdEvent = await ws.next(m => m.type === 'bf_day.updated');
        expect((createdEvent.data as BfDayJson).id).toBe(created.id);
        expect((createdEvent.data as BfDayJson).state).toBe('planning');

        await app
          .client()
          .patch(
            `/api/v1/bf-days/${created.id}`,
            { name: 'Realtime geändert' },
            { token: adminToken }
          );
        const patchedEvent = await ws.next(m => m.type === 'bf_day.updated');
        expect((patchedEvent.data as BfDayJson).name).toBe('Realtime geändert');

        await app.client().post(`/api/v1/bf-days/${created.id}/start`, {}, { token: adminToken });
        const startedEvent = await ws.next(m => m.type === 'bf_day.updated');
        expect((startedEvent.data as BfDayJson).state).toBe('running');

        await app.client().post(`/api/v1/bf-days/${created.id}/end`, {}, { token: adminToken });
        const endedEvent = await ws.next(m => m.type === 'bf_day.updated');
        expect((endedEvent.data as BfDayJson).state).toBe('ended');
      } finally {
        ws.close();
      }
    });
  });
});
