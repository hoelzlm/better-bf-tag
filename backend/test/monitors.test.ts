import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';

interface MonitorJson {
  id: string;
  name: string;
  paired: boolean;
  paired_at: string | null;
  last_seen_at: string | null;
  revoked_at: string | null;
  created_at: string;
}

interface MonitorPairingCodeResponse {
  monitor_id: string;
  name: string;
  code: string;
  expires_at: string;
}

async function createCrewPerson(app: TestApp, username: string) {
  return createPerson(app, {
    displayName: 'Mannschaft',
    personType: 'youth',
    permission: 'crew',
    username,
    password: 'crew-password',
  });
}

async function crewToken(app: TestApp, username: string): Promise<string> {
  const crewPerson = await createCrewPerson(app, username);
  const codeRes = await app
    .client()
    .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: await adminTokenFor(app) });
  const code = (codeRes.body as { code: string }).code;
  const pairRes = await app
    .client()
    .post('/api/v1/auth/pair', { code, platform: 'android', app_version: '1.0.0' });
  return (pairRes.body as { access_token: string }).access_token;
}

async function adminTokenFor(app: TestApp): Promise<string> {
  return loginAs(app, 'admin', 'admin-password');
}

describe('monitor admin routes', () => {
  let app: TestApp;
  let adminToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');
  });

  afterAll(async () => {
    await app.close();
  });

  it('creates, lists (sorted by name), updates and reads a monitor', async () => {
    const createB = await app
      .client()
      .post('/api/v1/monitors', { name: 'Bühne' }, { token: adminToken });
    expect(createB.status).toBe(201);
    const monitorB = createB.body as MonitorJson;
    expect(monitorB.paired).toBe(false);
    expect(monitorB.paired_at).toBeNull();
    expect(monitorB.last_seen_at).toBeNull();
    expect(monitorB.revoked_at).toBeNull();

    const createA = await app
      .client()
      .post('/api/v1/monitors', { name: 'Aufstellplatz' }, { token: adminToken });
    expect(createA.status).toBe(201);
    const monitorA = createA.body as MonitorJson;

    const listRes = await app.client().get('/api/v1/monitors', { token: adminToken });
    expect(listRes.status).toBe(200);
    const list = listRes.body as MonitorJson[];
    const names = list.filter(m => [monitorA.id, monitorB.id].includes(m.id)).map(m => m.name);
    expect(names).toEqual(['Aufstellplatz', 'Bühne']);

    const updateRes = await app
      .client()
      .patch(`/api/v1/monitors/${monitorB.id}`, { name: 'Bühne 2' }, { token: adminToken });
    expect(updateRes.status).toBe(200);
    expect((updateRes.body as MonitorJson).name).toBe('Bühne 2');
  });

  it('404s updating an unknown monitor', async () => {
    const res = await app
      .client()
      .patch(
        '/api/v1/monitors/00000000-0000-0000-0000-000000000000',
        { name: 'X' },
        { token: adminToken }
      );
    expect(res.status).toBe(404);
  });

  it('revoking a monitor is idempotent and 404s for an unknown id', async () => {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'Zeltplatz' }, { token: adminToken });
    const monitor = createRes.body as MonitorJson;

    const deleteRes = await app
      .client()
      .delete(`/api/v1/monitors/${monitor.id}`, { token: adminToken });
    expect(deleteRes.status).toBe(204);

    const deleteAgain = await app
      .client()
      .delete(`/api/v1/monitors/${monitor.id}`, { token: adminToken });
    expect(deleteAgain.status).toBe(204);

    const notFound = await app
      .client()
      .delete('/api/v1/monitors/00000000-0000-0000-0000-000000000000', { token: adminToken });
    expect(notFound.status).toBe(404);

    const listRes = await app.client().get('/api/v1/monitors', { token: adminToken });
    const listed = (listRes.body as MonitorJson[]).find(m => m.id === monitor.id)!;
    expect(listed.revoked_at).toBeTruthy();
    expect(listed.paired).toBe(false);
  });

  it('generates a monitor pairing code, even for a revoked monitor, and 404s for an unknown id', async () => {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'Einfahrt' }, { token: adminToken });
    const monitor = createRes.body as MonitorJson;

    await app.client().delete(`/api/v1/monitors/${monitor.id}`, { token: adminToken });

    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitor.id}/pairing-code`, {}, { token: adminToken });
    expect(codeRes.status).toBe(201);
    const code = codeRes.body as MonitorPairingCodeResponse;
    expect(code.monitor_id).toBe(monitor.id);
    expect(code.code).toMatch(/^[A-Z0-9]{4}-[A-Z0-9]{4}$/);

    const notFound = await app
      .client()
      .post(
        '/api/v1/monitors/00000000-0000-0000-0000-000000000000/pairing-code',
        {},
        { token: adminToken }
      );
    expect(notFound.status).toBe(404);
  });

  it('403s every /monitors route for non-admin tokens', async () => {
    const dispatchPerson = await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'dispatch-monitors',
      password: 'dispatch-password',
    });
    const dispatchToken = await loginAs(app, 'dispatch-monitors', 'dispatch-password');
    const crew = await crewToken(app, 'crew-monitors-admin-check');

    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'X' }, { token: adminToken });
    const monitor = createRes.body as MonitorJson;

    for (const token of [dispatchToken, crew]) {
      expect((await app.client().get('/api/v1/monitors', { token })).status).toBe(403);
      expect((await app.client().post('/api/v1/monitors', { name: 'Y' }, { token })).status).toBe(
        403
      );
      expect(
        (await app.client().patch(`/api/v1/monitors/${monitor.id}`, { name: 'Y' }, { token }))
          .status
      ).toBe(403);
      expect((await app.client().delete(`/api/v1/monitors/${monitor.id}`, { token })).status).toBe(
        403
      );
      expect(
        (await app.client().post(`/api/v1/monitors/${monitor.id}/pairing-code`, {}, { token }))
          .status
      ).toBe(403);
    }
    void dispatchPerson;
  });
});
