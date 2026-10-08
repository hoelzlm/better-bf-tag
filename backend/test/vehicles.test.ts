import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';

interface VehicleJson {
  id: string;
  call_sign: string;
  short_name: string;
  type: string;
  status: number;
  status_changed_at: string | null;
  sort_order: number;
  active: boolean;
}

describe('vehicles', () => {
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
      username: 'dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'dispatch1', 'dispatch-password');

    await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'crew1',
      password: 'crew-password',
    });
    crewToken = await loginAs(app, 'crew1', 'crew-password');

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
    await app.close();
  });

  async function createVehicle(overrides?: Partial<Record<string, string>>) {
    const res = await app.client().post(
      '/api/v1/vehicles',
      {
        call_sign: 'Florian 1',
        short_name: 'HLF 1',
        type: 'HLF',
        ...overrides,
      },
      { token: adminToken }
    );
    expect(res.status).toBe(201);
    return res.body as VehicleJson;
  }

  describe('permissions', () => {
    it('only admin can list vehicles', async () => {
      expect((await app.client().get('/api/v1/vehicles', { token: adminToken })).status).toBe(200);
      expect((await app.client().get('/api/v1/vehicles', { token: dispatchToken })).status).toBe(
        403
      );
      expect((await app.client().get('/api/v1/vehicles', { token: crewToken })).status).toBe(403);
      expect((await app.client().get('/api/v1/vehicles')).status).toBe(401);
    });

    it('only admin can create vehicles', async () => {
      const body = { call_sign: 'X', short_name: 'X', type: 'X' };
      expect(
        (await app.client().post('/api/v1/vehicles', body, { token: dispatchToken })).status
      ).toBe(403);
      expect((await app.client().post('/api/v1/vehicles', body)).status).toBe(401);
    });

    it('only admin can patch vehicles', async () => {
      const vehicle = await createVehicle();
      const res = await app
        .client()
        .patch(`/api/v1/vehicles/${vehicle.id}`, { active: false }, { token: dispatchToken });
      expect(res.status).toBe(403);
      expect(
        (await app.client().patch(`/api/v1/vehicles/${vehicle.id}`, { active: false })).status
      ).toBe(401);
    });

    it('only admin can reorder vehicles', async () => {
      const res = await app
        .client()
        .put('/api/v1/vehicles/order', { vehicle_ids: [] }, { token: dispatchToken });
      expect(res.status).toBe(403);
      expect((await app.client().put('/api/v1/vehicles/order', { vehicle_ids: [] })).status).toBe(
        401
      );
    });
  });

  describe('lifecycle', () => {
    it('create appears in GET /vehicles and in the snapshot; deactivate removes it from the snapshot only', async () => {
      const created = await createVehicle({ call_sign: 'Florian 2', short_name: 'LF 2' });
      expect(created).toMatchObject({
        call_sign: 'Florian 2',
        short_name: 'LF 2',
        type: 'HLF',
        status: 2,
        status_changed_at: null,
        active: true,
      });

      const list = await app.client().get('/api/v1/vehicles', { token: adminToken });
      expect(list.status).toBe(200);
      expect((list.body as VehicleJson[]).some(v => v.id === created.id)).toBe(true);

      const snapshotBefore = await app.client().get('/api/v1/snapshot', { token: adminToken });
      expect(snapshotBefore.status).toBe(200);
      expect(
        (snapshotBefore.body as { vehicles: VehicleJson[] }).vehicles.some(v => v.id === created.id)
      ).toBe(true);

      const patched = await app
        .client()
        .patch(`/api/v1/vehicles/${created.id}`, { active: false }, { token: adminToken });
      expect(patched.status).toBe(200);
      expect((patched.body as VehicleJson).active).toBe(false);

      const snapshotAfter = await app.client().get('/api/v1/snapshot', { token: adminToken });
      expect(
        (snapshotAfter.body as { vehicles: VehicleJson[] }).vehicles.some(v => v.id === created.id)
      ).toBe(false);

      const listAfter = await app.client().get('/api/v1/vehicles', { token: adminToken });
      expect((listAfter.body as VehicleJson[]).some(v => v.id === created.id)).toBe(true);
    });

    it('patch on an unknown vehicle returns 404', async () => {
      const res = await app
        .client()
        .patch(
          '/api/v1/vehicles/00000000-0000-0000-0000-000000000000',
          { active: false },
          { token: adminToken }
        );
      expect(res.status).toBe(404);
      expect(res.body).toMatchObject({ error: { code: 'not_found' } });
    });

    it('has no DELETE route', async () => {
      const created = await createVehicle();
      const res = await app
        .client()
        .delete(`/api/v1/vehicles/${created.id}`, { token: adminToken });
      expect([404, 405]).toContain(res.status);
    });
  });

  describe('reorder', () => {
    it('reordering changes order in the snapshot; an invalid id set is rejected', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const createOne = async (callSign: string) => {
          const res = await freshApp
            .client()
            .post(
              '/api/v1/vehicles',
              { call_sign: callSign, short_name: callSign, type: 'HLF' },
              { token: freshAdminToken }
            );
          expect(res.status).toBe(201);
          return res.body as VehicleJson;
        };

        const first = await createOne('A');
        const second = await createOne('B');
        const third = await createOne('C');

        const invalid = await freshApp
          .client()
          .put(
            '/api/v1/vehicles/order',
            { vehicle_ids: [first.id, second.id] },
            { token: freshAdminToken }
          );
        expect(invalid.status).toBe(400);
        expect(invalid.body).toMatchObject({ error: { code: 'validation_error' } });

        const reordered = await freshApp
          .client()
          .put(
            '/api/v1/vehicles/order',
            { vehicle_ids: [third.id, first.id, second.id] },
            { token: freshAdminToken }
          );
        expect(reordered.status).toBe(200);
        const orderedIds = (reordered.body as VehicleJson[]).map(v => v.id);
        expect(orderedIds).toEqual([third.id, first.id, second.id]);

        const snapshot = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        const snapshotIds = (snapshot.body as { vehicles: VehicleJson[] }).vehicles.map(v => v.id);
        expect(snapshotIds).toEqual([third.id, first.id, second.id]);
      } finally {
        await freshApp.close();
      }
    });
  });

  describe('status', () => {
    it('dispatch and admin can set status; crew/preparation get 403', async () => {
      const vehicle = await createVehicle();

      const byDispatch = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: dispatchToken });
      expect(byDispatch.status).toBe(200);
      expect((byDispatch.body as VehicleJson).status).toBe(3);
      expect((byDispatch.body as VehicleJson).status_changed_at).toBeTruthy();

      const byAdmin = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 4 }, { token: adminToken });
      expect(byAdmin.status).toBe(200);

      const byCrew = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 1 }, { token: crewToken });
      expect(byCrew.status).toBe(403);

      const byPreparation = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 1 }, { token: preparationToken });
      expect(byPreparation.status).toBe(403);
    });

    it('rejects status 0 and 9 with 400', async () => {
      const vehicle = await createVehicle();
      const low = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 0 }, { token: dispatchToken });
      expect(low.status).toBe(400);
      const high = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 9 }, { token: dispatchToken });
      expect(high.status).toBe(400);
    });

    it('rejects setting the status of an inactive vehicle with 409', async () => {
      const vehicle = await createVehicle();
      await app
        .client()
        .patch(`/api/v1/vehicles/${vehicle.id}`, { active: false }, { token: adminToken });

      const res = await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: dispatchToken });
      expect(res.status).toBe(409);
      expect(res.body).toMatchObject({ error: { code: 'vehicle_inactive' } });
    });

    it('status history contains dispatch-sourced entries with the acting person, newest first', async () => {
      const vehicle = await createVehicle();

      await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: dispatchToken });
      app.clock.advance(1000);
      await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 4 }, { token: dispatchToken });
      app.clock.advance(1000);
      // Same status again must still be recorded.
      await app
        .client()
        .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 4 }, { token: dispatchToken });

      const history = await app
        .client()
        .get(`/api/v1/vehicles/${vehicle.id}/status-history`, { token: dispatchToken });
      expect(history.status).toBe(200);
      const items = history.body as Array<{
        status: number;
        source: string;
        person_id: string | null;
        at: string;
      }>;
      expect(items.length).toBe(3);
      expect(items.map(item => item.status)).toEqual([4, 4, 3]);
      for (const item of items) {
        expect(item.source).toBe('dispatch');
        expect(item.person_id).toBeTruthy();
      }
      // newest first
      expect(new Date(items[0]!.at).getTime()).toBeGreaterThanOrEqual(
        new Date(items[1]!.at).getTime()
      );
      expect(new Date(items[1]!.at).getTime()).toBeGreaterThanOrEqual(
        new Date(items[2]!.at).getTime()
      );
    });
  });

  describe('seq / snapshot consistency', () => {
    it('seq increases by exactly the number of events per mutation and survives a restart', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');

        await createPerson(freshApp, {
          displayName: 'Leitstelle',
          personType: 'supervisor',
          permission: 'dispatch',
          username: 'dispatch1',
          password: 'dispatch-password',
        });
        const freshDispatchToken = await loginAs(freshApp, 'dispatch1', 'dispatch-password');

        const snapshot0 = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        const seq0 = (snapshot0.body as { seq: number }).seq;

        const createRes = await freshApp
          .client()
          .post(
            '/api/v1/vehicles',
            { call_sign: 'A', short_name: 'A', type: 'HLF' },
            { token: freshAdminToken }
          );
        const vehicleA = createRes.body as VehicleJson;
        const snapshot1 = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        const seq1 = (snapshot1.body as { seq: number }).seq;
        expect(seq1).toBe(seq0 + 1);

        const createRes2 = await freshApp
          .client()
          .post(
            '/api/v1/vehicles',
            { call_sign: 'B', short_name: 'B', type: 'HLF' },
            { token: freshAdminToken }
          );
        const vehicleB = createRes2.body as VehicleJson;
        const snapshot2 = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        const seq2 = (snapshot2.body as { seq: number }).seq;
        expect(seq2).toBe(seq1 + 1);

        await freshApp
          .client()
          .put(
            `/api/v1/vehicles/${vehicleA.id}/status`,
            { status: 3 },
            { token: freshDispatchToken }
          );
        const snapshot3 = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        const seq3 = (snapshot3.body as { seq: number }).seq;
        expect(seq3).toBe(seq2 + 1);

        const reorderRes = await freshApp
          .client()
          .put(
            '/api/v1/vehicles/order',
            { vehicle_ids: [vehicleB.id, vehicleA.id] },
            { token: freshAdminToken }
          );
        expect(reorderRes.status).toBe(200);
        const snapshot4 = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshAdminToken });
        const seq4 = (snapshot4.body as { seq: number }).seq;
        // Both vehicles change sort_order (0<->1), so exactly 2 events.
        expect(seq4).toBe(seq3 + 2);

        const restarted = await freshApp.restart();
        try {
          const snapshotAfterRestart = await restarted
            .client()
            .get('/api/v1/snapshot', { token: freshAdminToken });
          expect((snapshotAfterRestart.body as { seq: number }).seq).toBe(seq4);
        } finally {
          await restarted.close();
        }
      } finally {
        await freshApp.close();
      }
    });
  });
});
