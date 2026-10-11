import { describe, it, expect, beforeAll, afterAll } from 'vitest';
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

interface ProgramItemJson {
  id: string;
  bf_day_id: string;
  title: string;
  type: 'meal' | 'training' | 'maintenance' | 'rest' | 'other';
  starts_at: string;
  ends_at: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function createBfDayBody(
  overrides?: Partial<{ name: string; starts_at: string; ends_at: string }>
) {
  const startsAt = new Date('2026-06-01T08:00:00Z');
  const endsAt = new Date(startsAt.getTime() + DAY_MS);
  return {
    name: 'BF-Tag Tagesablauf',
    starts_at: startsAt.toISOString(),
    ends_at: endsAt.toISOString(),
    ...overrides,
  };
}

describe('program-items', () => {
  let app: TestApp;
  let adminToken: string;
  let dispatchToken: string;
  let crewToken: string;
  let preparationToken: string;

  beforeAll(async () => {
    app = await startTestApp();

    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'pi-dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'pi-dispatch1', 'dispatch-password');

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'pi-crew1',
      password: 'crew-password',
    });
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'pi-prep1',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'pi-prep1', 'prep-password');
  });

  afterAll(async () => {
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

  async function startBfDay(bfDayId: string): Promise<void> {
    const res = await app
      .client()
      .post(`/api/v1/bf-days/${bfDayId}/start`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function endBfDay(bfDayId: string): Promise<void> {
    const res = await app
      .client()
      .post(`/api/v1/bf-days/${bfDayId}/end`, {}, { token: adminToken });
    expect(res.status).toBe(200);
  }

  async function monitorToken(): Promise<string> {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: `Standby pi ${Math.random()}` }, { token: adminToken });
    const monitorId = (createRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    return (pairRes.body as { access_token: string }).access_token;
  }

  async function createProgramItem(
    dayId: string,
    overrides?: Partial<{ title: string; type: string; starts_at: string; ends_at: string }>,
    opts: { token?: string } = { token: dispatchToken }
  ) {
    return app.client().post(
      `/api/v1/bf-days/${dayId}/program-items`,
      {
        title: 'Mittagessen',
        type: 'meal',
        starts_at: '2026-06-01T12:00:00Z',
        ends_at: '2026-06-01T13:00:00Z',
        ...overrides,
      },
      opts
    );
  }

  describe('permissions', () => {
    it('dispatch/admin may POST/PATCH/DELETE; crew, preparation and monitor get 403; all incl. monitor can GET', async () => {
      const day = await createBfDay({ name: `Perm ${Math.random()}` });
      const monitor = await monitorToken();

      for (const token of [crewToken, preparationToken, monitor]) {
        const res = await createProgramItem(day.id, {}, { token });
        expect(res.status).toBe(403);
      }
      expect((await createProgramItem(day.id, {}, {})).status).toBe(401);

      const created = await createProgramItem(
        day.id,
        { title: 'Admin-Punkt' },
        { token: adminToken }
      );
      expect(created.status).toBe(201);
      const item = created.body as ProgramItemJson;

      for (const token of [crewToken, preparationToken, monitor]) {
        const patchRes = await app
          .client()
          .patch(`/api/v1/program-items/${item.id}`, { title: 'x' }, { token });
        expect(patchRes.status).toBe(403);
        const deleteRes = await app.client().delete(`/api/v1/program-items/${item.id}`, { token });
        expect(deleteRes.status).toBe(403);
      }

      const patched = await app
        .client()
        .patch(`/api/v1/program-items/${item.id}`, { title: 'Geändert' }, { token: dispatchToken });
      expect(patched.status).toBe(200);

      for (const token of [adminToken, dispatchToken, preparationToken, crewToken, monitor]) {
        const listRes = await app
          .client()
          .get(`/api/v1/bf-days/${day.id}/program-items`, { token });
        expect(listRes.status).toBe(200);
      }

      const deleted = await app
        .client()
        .delete(`/api/v1/program-items/${item.id}`, { token: dispatchToken });
      expect(deleted.status).toBe(204);
    });
  });

  describe('validation', () => {
    it('rejects empty title, title over 80 chars, ends<=starts, and outside the bf-day period', async () => {
      const day = await createBfDay({ name: `Validation ${Math.random()}` });

      const empty = await createProgramItem(day.id, { title: '' });
      expect(empty.status).toBe(400);
      expect(empty.body).toMatchObject({ error: { code: 'validation_error' } });

      const tooLong = await createProgramItem(day.id, { title: 'x'.repeat(81) });
      expect(tooLong.status).toBe(400);
      expect(tooLong.body).toMatchObject({ error: { code: 'validation_error' } });

      const endsBeforeStart = await createProgramItem(day.id, {
        starts_at: '2026-06-01T13:00:00Z',
        ends_at: '2026-06-01T12:00:00Z',
      });
      expect(endsBeforeStart.status).toBe(400);
      expect(endsBeforeStart.body).toMatchObject({ error: { code: 'validation_error' } });

      const endsEqualsStart = await createProgramItem(day.id, {
        starts_at: '2026-06-01T12:00:00Z',
        ends_at: '2026-06-01T12:00:00Z',
      });
      expect(endsEqualsStart.status).toBe(400);

      const outside = await createProgramItem(day.id, {
        starts_at: '2026-05-31T23:00:00Z',
        ends_at: '2026-06-01T01:00:00Z',
      });
      expect(outside.status).toBe(400);
      expect(outside.body).toMatchObject({ error: { code: 'validation_error' } });

      const outsideEnd = await createProgramItem(day.id, {
        starts_at: '2026-06-02T07:00:00Z',
        ends_at: '2026-06-02T09:00:00Z',
      });
      expect(outsideEnd.status).toBe(400);

      // PATCH-merge validation: a valid item patched with only a new ends_at
      // that pushes it outside the period is also rejected.
      const valid = await createProgramItem(day.id);
      expect(valid.status).toBe(201);
      const item = valid.body as ProgramItemJson;

      const patchOutside = await app
        .client()
        .patch(
          `/api/v1/program-items/${item.id}`,
          { ends_at: '2026-06-02T09:00:00Z' },
          { token: dispatchToken }
        );
      expect(patchOutside.status).toBe(400);
      expect(patchOutside.body).toMatchObject({ error: { code: 'validation_error' } });

      const patchEndsBeforeStart = await app
        .client()
        .patch(
          `/api/v1/program-items/${item.id}`,
          { ends_at: '2026-06-01T11:00:00Z' },
          { token: dispatchToken }
        );
      expect(patchEndsBeforeStart.status).toBe(400);
    });

    it('allows overlapping program items', async () => {
      const day = await createBfDay({ name: `Overlap ${Math.random()}` });
      const first = await createProgramItem(day.id, {
        starts_at: '2026-06-01T12:00:00Z',
        ends_at: '2026-06-01T14:00:00Z',
      });
      expect(first.status).toBe(201);
      const second = await createProgramItem(day.id, {
        starts_at: '2026-06-01T13:00:00Z',
        ends_at: '2026-06-01T15:00:00Z',
      });
      expect(second.status).toBe(201);
    });
  });

  describe('state', () => {
    it('allowed in planning and running, 409 bf_day_ended for POST/PATCH/DELETE once ended', async () => {
      const day = await createBfDay({ name: `State ${Math.random()}` });

      const planningCreate = await createProgramItem(day.id, { title: 'Planung' });
      expect(planningCreate.status).toBe(201);
      const planningItem = planningCreate.body as ProgramItemJson;

      await startBfDay(day.id);

      const runningCreate = await createProgramItem(day.id, {
        title: 'Laufend',
        starts_at: '2026-06-01T15:00:00Z',
        ends_at: '2026-06-01T16:00:00Z',
      });
      expect(runningCreate.status).toBe(201);
      const runningItem = runningCreate.body as ProgramItemJson;

      await endBfDay(day.id);

      const endedCreate = await createProgramItem(day.id, {
        title: 'Zu spät',
        starts_at: '2026-06-01T17:00:00Z',
        ends_at: '2026-06-01T18:00:00Z',
      });
      expect(endedCreate.status).toBe(409);
      expect(endedCreate.body).toMatchObject({ error: { code: 'bf_day_ended' } });

      const endedPatch = await app
        .client()
        .patch(
          `/api/v1/program-items/${planningItem.id}`,
          { title: 'x' },
          { token: dispatchToken }
        );
      expect(endedPatch.status).toBe(409);
      expect(endedPatch.body).toMatchObject({ error: { code: 'bf_day_ended' } });

      const endedDelete = await app
        .client()
        .delete(`/api/v1/program-items/${runningItem.id}`, { token: dispatchToken });
      expect(endedDelete.status).toBe(409);
      expect(endedDelete.body).toMatchObject({ error: { code: 'bf_day_ended' } });
    });
  });

  describe('404s', () => {
    it('unknown bf-day on GET/POST, unknown program-item on PATCH/DELETE', async () => {
      const unknownId = '00000000-0000-0000-0000-000000000000';

      const listRes = await app
        .client()
        .get(`/api/v1/bf-days/${unknownId}/program-items`, { token: dispatchToken });
      expect(listRes.status).toBe(404);

      const postRes = await createProgramItem(unknownId);
      expect(postRes.status).toBe(404);

      const patchRes = await app
        .client()
        .patch(`/api/v1/program-items/${unknownId}`, { title: 'x' }, { token: dispatchToken });
      expect(patchRes.status).toBe(404);

      const deleteRes = await app
        .client()
        .delete(`/api/v1/program-items/${unknownId}`, { token: dispatchToken });
      expect(deleteRes.status).toBe(404);
    });
  });

  describe('sort order', () => {
    it('GET sorts by starts_at, ends_at, id ascending', async () => {
      const day = await createBfDay({ name: `Sort ${Math.random()}` });

      const late = await createProgramItem(day.id, {
        title: 'Spät',
        starts_at: '2026-06-01T18:00:00Z',
        ends_at: '2026-06-01T19:00:00Z',
      });
      const early = await createProgramItem(day.id, {
        title: 'Früh',
        starts_at: '2026-06-01T09:00:00Z',
        ends_at: '2026-06-01T10:00:00Z',
      });
      const middle = await createProgramItem(day.id, {
        title: 'Mitte',
        starts_at: '2026-06-01T12:00:00Z',
        ends_at: '2026-06-01T13:00:00Z',
      });
      expect(late.status).toBe(201);
      expect(early.status).toBe(201);
      expect(middle.status).toBe(201);

      const listRes = await app
        .client()
        .get(`/api/v1/bf-days/${day.id}/program-items`, { token: dispatchToken });
      expect(listRes.status).toBe(200);
      const items = listRes.body as ProgramItemJson[];
      expect(items.map(i => i.title)).toEqual(['Früh', 'Mitte', 'Spät']);
    });
  });

  describe('realtime', () => {
    it('program.changed carries the full sorted list after create, update and delete', async () => {
      const day = await createBfDay({ name: `Realtime ${Math.random()}` });
      const ws = await connectWs(app.baseUrl, adminToken);
      await ws.next(m => m.type === 'hello');
      try {
        const createRes = await createProgramItem(day.id, {
          title: 'Erstes',
          starts_at: '2026-06-01T12:00:00Z',
          ends_at: '2026-06-01T13:00:00Z',
        });
        expect(createRes.status).toBe(201);
        const first = createRes.body as ProgramItemJson;

        const createdEvent = await ws.next(m => m.type === 'program.changed');
        const createdData = createdEvent.data as { bf_day_id: string; items: ProgramItemJson[] };
        expect(createdData.bf_day_id).toBe(day.id);
        expect(createdData.items.map(i => i.id)).toEqual([first.id]);

        const secondRes = await createProgramItem(day.id, {
          title: 'Zweites',
          starts_at: '2026-06-01T09:00:00Z',
          ends_at: '2026-06-01T10:00:00Z',
        });
        expect(secondRes.status).toBe(201);
        const second = secondRes.body as ProgramItemJson;

        const secondEvent = await ws.next(m => m.type === 'program.changed');
        const secondData = secondEvent.data as { bf_day_id: string; items: ProgramItemJson[] };
        expect(secondData.items.map(i => i.id)).toEqual([second.id, first.id]);

        const patchRes = await app
          .client()
          .patch(
            `/api/v1/program-items/${first.id}`,
            { title: 'Erstes geändert' },
            { token: dispatchToken }
          );
        expect(patchRes.status).toBe(200);
        const patchEvent = await ws.next(m => m.type === 'program.changed');
        const patchData = patchEvent.data as { bf_day_id: string; items: ProgramItemJson[] };
        expect(patchData.items.find(i => i.id === first.id)?.title).toBe('Erstes geändert');

        const deleteRes = await app
          .client()
          .delete(`/api/v1/program-items/${first.id}`, { token: dispatchToken });
        expect(deleteRes.status).toBe(204);
        const deleteEvent = await ws.next(m => m.type === 'program.changed');
        const deleteData = deleteEvent.data as { bf_day_id: string; items: ProgramItemJson[] };
        expect(deleteData.items.map(i => i.id)).toEqual([second.id]);
      } finally {
        ws.close();
      }
    });
  });

  describe('snapshot', () => {
    it('contains the sorted program items of the running day, [] without a running day', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const noRun = await freshApp.client().get('/api/v1/snapshot', { token: freshAdminToken });
        expect(noRun.status).toBe(200);
        expect((noRun.body as { program_items: unknown[] }).program_items).toEqual([]);

        const createRes = await freshApp
          .client()
          .post('/api/v1/bf-days', createBfDayBody({ name: 'Snapshot' }), {
            token: freshAdminToken,
          });
        const day = createRes.body as BfDayJson;

        const firstRes = await freshApp.client().post(
          `/api/v1/bf-days/${day.id}/program-items`,
          {
            title: 'Spät',
            type: 'meal',
            starts_at: '2026-06-01T18:00:00Z',
            ends_at: '2026-06-01T19:00:00Z',
          },
          { token: freshAdminToken }
        );
        expect(firstRes.status).toBe(201);
        const secondRes = await freshApp.client().post(
          `/api/v1/bf-days/${day.id}/program-items`,
          {
            title: 'Früh',
            type: 'training',
            starts_at: '2026-06-01T09:00:00Z',
            ends_at: '2026-06-01T10:00:00Z',
          },
          { token: freshAdminToken }
        );
        expect(secondRes.status).toBe(201);

        await freshApp.client().post(
          `/api/v1/bf-days/${day.id}/start`,
          {},
          {
            token: freshAdminToken,
          }
        );

        const snapshot = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        expect(snapshot.status).toBe(200);
        const programItems = (snapshot.body as { program_items: ProgramItemJson[] }).program_items;
        expect(programItems.map(i => i.title)).toEqual(['Früh', 'Spät']);
      } finally {
        await freshApp.close();
      }
    });
  });

  describe('bf-day period change', () => {
    it('409 program_item_outside_bf_day when shrinking the period would leave a program item outside it, nothing changed', async () => {
      const day = await createBfDay({ name: `PeriodChange ${Math.random()}` });
      const itemRes = await createProgramItem(day.id, {
        starts_at: '2026-06-01T18:00:00Z',
        ends_at: '2026-06-01T19:00:00Z',
      });
      expect(itemRes.status).toBe(201);

      const shrinkRes = await app
        .client()
        .patch(
          `/api/v1/bf-days/${day.id}`,
          { ends_at: '2026-06-01T12:00:00Z' },
          { token: adminToken }
        );
      expect(shrinkRes.status).toBe(409);
      expect(shrinkRes.body).toMatchObject({ error: { code: 'program_item_outside_bf_day' } });

      const reloaded = await app.client().get(`/api/v1/bf-days/${day.id}`, { token: adminToken });
      expect(reloaded.status).toBe(200);
      expect((reloaded.body as BfDayJson).ends_at).toBe(day.ends_at);

      // Widening the period (program item still fits) is fine.
      const widenRes = await app
        .client()
        .patch(
          `/api/v1/bf-days/${day.id}`,
          { ends_at: '2026-06-02T08:00:00Z' },
          { token: adminToken }
        );
      expect(widenRes.status).toBe(200);
    });
  });
});
