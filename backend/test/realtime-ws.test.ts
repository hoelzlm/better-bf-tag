import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';
import { connectWs, type WsMessage, type WsTestClient } from './support/ws-client.js';

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

interface StatusChangedData {
  vehicle_id: string;
  status: number;
  at: string;
  source: string;
}

async function createVehicle(app: TestApp, token: string, overrides?: Record<string, string>) {
  const res = await app.client().post(
    '/api/v1/vehicles',
    {
      call_sign: 'Florian 1',
      short_name: 'HLF 1',
      type: 'HLF',
      ...overrides,
    },
    { token }
  );
  expect(res.status).toBe(201);
  return res.body as VehicleJson;
}

function assertConsecutive(events: WsMessage[]): void {
  for (let i = 1; i < events.length; i++) {
    expect(events[i]!.seq).toBe(events[i - 1]!.seq! + 1);
  }
}

describe('realtime websocket /ws', () => {
  describe('auth', () => {
    let app: TestApp;

    beforeAll(async () => {
      app = await startTestApp();
    });

    afterAll(async () => {
      await app.close();
    });

    it('closes with 4401 when no token is given', async () => {
      const client = await connectWs(app.baseUrl);
      const code = await client.closeCode;
      expect(code).toBe(4401);
    });

    it('closes with 4401 when the token is invalid', async () => {
      const client = await connectWs(app.baseUrl, 'not-a-valid-token');
      const code = await client.closeCode;
      expect(code).toBe(4401);
    });

    it('accepts a valid token: first message is hello with seq == snapshot.seq', async () => {
      const token = await loginAs(app, 'admin', 'admin-password');
      const snapshotRes = await app.client().get('/api/v1/snapshot', { token });
      const snapshotSeq = (snapshotRes.body as { seq: number }).seq;

      const client = await connectWs(app.baseUrl, token);
      const hello = await client.next();
      expect(hello).toMatchObject({ type: 'hello', seq: snapshotSeq });
      client.close();
    });
  });

  describe('events', () => {
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

      await createPerson(app, {
        displayName: 'Mannschaft',
        personType: 'youth',
        permission: 'crew',
        username: 'crew1',
        password: 'crew-password',
      });
      crewToken = await loginAs(app, 'crew1', 'crew-password');
    });

    afterAll(async () => {
      await app.close();
    });

    it('three connected clients receive vehicle.updated (create/patch) and vehicle.status_changed with identical seq and data', async () => {
      const adminWs = await connectWs(app.baseUrl, adminToken);
      await adminWs.next(m => m.type === 'hello');
      const dispatchWs = await connectWs(app.baseUrl, dispatchToken);
      await dispatchWs.next(m => m.type === 'hello');
      const crewWs = await connectWs(app.baseUrl, crewToken);
      await crewWs.next(m => m.type === 'hello');

      try {
        const created = await app
          .client()
          .post(
            '/api/v1/vehicles',
            { call_sign: 'Florian 1', short_name: 'HLF 1', type: 'HLF' },
            { token: adminToken }
          );
        expect(created.status).toBe(201);
        const vehicle = created.body as VehicleJson;

        const createdEvents = await Promise.all([
          adminWs.next(m => m.type === 'vehicle.updated'),
          dispatchWs.next(m => m.type === 'vehicle.updated'),
          crewWs.next(m => m.type === 'vehicle.updated'),
        ]);
        expect(new Set(createdEvents.map(e => e.seq)).size).toBe(1);
        for (const event of createdEvents) {
          expect((event.data as VehicleJson).id).toBe(vehicle.id);
        }

        const patched = await app
          .client()
          .patch(`/api/v1/vehicles/${vehicle.id}`, { short_name: 'HLF 1a' }, { token: adminToken });
        expect(patched.status).toBe(200);

        const patchedEvents = await Promise.all([
          adminWs.next(m => m.type === 'vehicle.updated'),
          dispatchWs.next(m => m.type === 'vehicle.updated'),
          crewWs.next(m => m.type === 'vehicle.updated'),
        ]);
        expect(new Set(patchedEvents.map(e => e.seq)).size).toBe(1);
        for (const event of patchedEvents) {
          expect((event.data as VehicleJson).short_name).toBe('HLF 1a');
        }

        const statusRes = await app
          .client()
          .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 3 }, { token: dispatchToken });
        expect(statusRes.status).toBe(200);

        const statusEvents = await Promise.all([
          adminWs.next(m => m.type === 'vehicle.status_changed'),
          dispatchWs.next(m => m.type === 'vehicle.status_changed'),
          crewWs.next(m => m.type === 'vehicle.status_changed'),
        ]);
        expect(new Set(statusEvents.map(e => e.seq)).size).toBe(1);
        for (const event of statusEvents) {
          const data = event.data as StatusChangedData;
          expect(data.vehicle_id).toBe(vehicle.id);
          expect(data.status).toBe(3);
          expect(data.source).toBe('dispatch');
          expect(data.at).toBeTruthy();
        }
      } finally {
        adminWs.close();
        dispatchWs.close();
        crewWs.close();
      }
    });

    it('seq is strictly consecutive across several mutations and matches the snapshot afterwards', async () => {
      const ws = await connectWs(app.baseUrl, adminToken);
      try {
        const hello = await ws.next(m => m.type === 'hello');
        let lastSeq = hello.seq!;

        const v1 = (
          await app
            .client()
            .post(
              '/api/v1/vehicles',
              { call_sign: 'A', short_name: 'A', type: 'HLF' },
              { token: adminToken }
            )
        ).body as VehicleJson;
        const e1 = await ws.next(m => m.type === 'vehicle.updated');
        expect(e1.seq).toBe(lastSeq + 1);
        lastSeq = e1.seq!;

        const createRes2 = await app
          .client()
          .post(
            '/api/v1/vehicles',
            { call_sign: 'B', short_name: 'B', type: 'HLF' },
            { token: adminToken }
          );
        expect(createRes2.status).toBe(201);
        const e2 = await ws.next(m => m.type === 'vehicle.updated');
        expect(e2.seq).toBe(lastSeq + 1);
        lastSeq = e2.seq!;

        const statusRes = await app
          .client()
          .put(`/api/v1/vehicles/${v1.id}/status`, { status: 4 }, { token: dispatchToken });
        expect(statusRes.status).toBe(200);
        const e3 = await ws.next(m => m.type === 'vehicle.status_changed');
        expect(e3.seq).toBe(lastSeq + 1);
        lastSeq = e3.seq!;

        const beforeList = (await app.client().get('/api/v1/vehicles', { token: adminToken }))
          .body as VehicleJson[];
        const idsBySortOrder = [...beforeList]
          .sort((a, b) => a.sort_order - b.sort_order)
          .map(v => v.id);
        // Reverse the full set so the reorder is valid (it must contain
        // exactly the existing ids) regardless of how many other tests in
        // this describe block created vehicles beforehand.
        const reversedIds = [...idsBySortOrder].reverse();
        const changedCount = reversedIds.filter((id, index) => id !== idsBySortOrder[index]).length;

        const reorderRes = await app
          .client()
          .put('/api/v1/vehicles/order', { vehicle_ids: reversedIds }, { token: adminToken });
        expect(reorderRes.status).toBe(200);

        for (let i = 0; i < changedCount; i++) {
          const event = await ws.next(m => m.type === 'vehicle.updated');
          expect(event.seq).toBe(lastSeq + 1);
          lastSeq = event.seq!;
        }

        const snapshot = await app.client().get('/api/v1/snapshot', { token: adminToken });
        const body = snapshot.body as { seq: number; vehicles: VehicleJson[] };
        expect(body.seq).toBe(lastSeq);
        const v1After = body.vehicles.find(v => v.id === v1.id);
        expect(v1After?.status).toBe(4);
      } finally {
        ws.close();
      }
    });

    it('10 concurrent status PUTs arrive at every client in strictly increasing consecutive seq order, matching the final snapshot', async () => {
      const vehicle = await createVehicle(app, adminToken, {
        call_sign: 'Concurrent',
        short_name: 'Concurrent',
      });

      const adminWs = await connectWs(app.baseUrl, adminToken);
      await adminWs.next(m => m.type === 'hello');
      const dispatchWs = await connectWs(app.baseUrl, dispatchToken);
      await dispatchWs.next(m => m.type === 'hello');
      const crewWs = await connectWs(app.baseUrl, crewToken);
      await crewWs.next(m => m.type === 'hello');

      try {
        // The vehicle was created (and its vehicle.updated event delivered)
        // before these connections attached, so there is nothing to drain.
        const statuses = [1, 2, 3, 4, 5, 6, 7, 8, 1, 2];
        const results = await Promise.all(
          statuses.map(status =>
            app
              .client()
              .put(`/api/v1/vehicles/${vehicle.id}/status`, { status }, { token: dispatchToken })
          )
        );
        for (const res of results) {
          expect(res.status).toBe(200);
        }

        async function collect(client: WsTestClient): Promise<WsMessage[]> {
          const events: WsMessage[] = [];
          for (let i = 0; i < statuses.length; i++) {
            events.push(await client.next(m => m.type === 'vehicle.status_changed'));
          }
          return events;
        }

        const [adminEvents, dispatchEvents, crewEvents] = await Promise.all([
          collect(adminWs),
          collect(dispatchWs),
          collect(crewWs),
        ]);

        assertConsecutive(adminEvents);
        assertConsecutive(dispatchEvents);
        assertConsecutive(crewEvents);
        expect(dispatchEvents.map(e => e.seq)).toEqual(adminEvents.map(e => e.seq));
        expect(crewEvents.map(e => e.seq)).toEqual(adminEvents.map(e => e.seq));

        const lastEvent = adminEvents[adminEvents.length - 1]!;
        const lastStatus = (lastEvent.data as StatusChangedData).status;

        const snapshot = await app.client().get('/api/v1/snapshot', { token: adminToken });
        const body = snapshot.body as { vehicles: VehicleJson[] };
        const vehicleAfter = body.vehicles.find(v => v.id === vehicle.id);
        expect(vehicleAfter?.status).toBe(lastStatus);
      } finally {
        adminWs.close();
        dispatchWs.close();
        crewWs.close();
      }
    });

    it('delivers the event to the client in under 1000ms after the PUT response', async () => {
      const ws = await connectWs(app.baseUrl, adminToken);
      try {
        await ws.next(m => m.type === 'hello');

        const vehicle = await createVehicle(app, adminToken, {
          call_sign: 'Latency',
          short_name: 'Latency',
        });
        await ws.next(m => m.type === 'vehicle.updated'); // creation event

        const putRes = await app
          .client()
          .put(`/api/v1/vehicles/${vehicle.id}/status`, { status: 5 }, { token: dispatchToken });
        expect(putRes.status).toBe(200);
        const afterPut = Date.now();

        await ws.next(m => m.type === 'vehicle.status_changed');
        const afterEvent = Date.now();

        expect(afterEvent - afterPut).toBeLessThan(1000);
      } finally {
        ws.close();
      }
    });
  });

  describe('heartbeat', () => {
    let app: TestApp;

    beforeAll(async () => {
      app = await startTestApp({ config: { WS_HEARTBEAT_MS: 200 } });
    });

    afterAll(async () => {
      await app.close();
    });

    it('sends a heartbeat message with the current seq', async () => {
      const token = await loginAs(app, 'admin', 'admin-password');
      const ws = await connectWs(app.baseUrl, token);
      try {
        const hello = await ws.next(m => m.type === 'hello');
        const heartbeat = await ws.next(m => m.type === 'heartbeat', 2000);
        expect(heartbeat.seq).toBe(hello.seq);
      } finally {
        ws.close();
      }
    });
  });
});
