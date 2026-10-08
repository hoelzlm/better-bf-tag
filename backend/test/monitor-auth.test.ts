import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

interface MonitorJson {
  id: string;
  name: string;
  paired: boolean;
}

interface MonitorPairingCodeResponse {
  monitor_id: string;
  name: string;
  code: string;
  expires_at: string;
}

interface MonitorSession {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  monitor: { id: string; name: string };
}

interface PersonPairingCodeResponse {
  person_id: string;
  code: string;
}

describe('monitor pairing and auth', () => {
  let app: TestApp;
  let adminToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');
  });

  afterAll(async () => {
    await app.close();
  });

  async function createMonitor(name: string): Promise<MonitorJson> {
    const res = await app.client().post('/api/v1/monitors', { name }, { token: adminToken });
    return res.body as MonitorJson;
  }

  async function monitorPairingCode(monitorId: string): Promise<string> {
    const res = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    return (res.body as MonitorPairingCodeResponse).code;
  }

  async function pairMonitor(code: string): Promise<MonitorSession> {
    const res = await app.client().post('/api/v1/auth/monitor/pair', { code });
    return res.body as MonitorSession;
  }

  it('pairs with a fresh code; the token works on /snapshot and /monitor/me', async () => {
    const monitor = await createMonitor('Standby 1');
    const code = await monitorPairingCode(monitor.id);

    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    expect(pairRes.status).toBe(200);
    const session = pairRes.body as MonitorSession;
    expect(session.monitor.id).toBe(monitor.id);
    expect(session.monitor.name).toBe('Standby 1');
    expect(session.access_token).toBeTruthy();
    expect(session.refresh_token).toBeTruthy();

    const snapshotRes = await app.client().get('/api/v1/snapshot', { token: session.access_token });
    expect(snapshotRes.status).toBe(200);

    const meRes = await app.client().get('/api/v1/monitor/me', { token: session.access_token });
    expect(meRes.status).toBe(200);
    expect(meRes.body).toEqual({ id: monitor.id, name: 'Standby 1' });
  });

  it('accepts a code typed without the dash and in lowercase', async () => {
    const monitor = await createMonitor('Standby lowercase');
    const code = await monitorPairingCode(monitor.id);
    const unformatted = code.replace('-', '').toLowerCase();

    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code: unformatted });
    expect(pairRes.status).toBe(200);
  });

  it('the same code cannot be used twice; concurrent redemption lets exactly one caller win', async () => {
    const monitor = await createMonitor('Standby reuse');
    const code = await monitorPairingCode(monitor.id);

    const first = await app.client().post('/api/v1/auth/monitor/pair', { code });
    expect(first.status).toBe(200);
    const second = await app.client().post('/api/v1/auth/monitor/pair', { code });
    expect(second.status).toBe(401);
    expect(second.body).toMatchObject({ error: { code: 'invalid_pairing_code' } });

    const monitor2 = await createMonitor('Standby concurrent');
    const code2 = await monitorPairingCode(monitor2.id);
    const results = await Promise.all(
      Array.from({ length: 5 }, () =>
        app.client().post('/api/v1/auth/monitor/pair', { code: code2 })
      )
    );
    expect(results.filter(r => r.status === 200)).toHaveLength(1);
    expect(results.filter(r => r.status === 401)).toHaveLength(4);
  });

  it('a code is valid just before its TTL and rejected just after', async () => {
    const localApp = await startTestApp();
    try {
      const localAdminToken = await loginAs(localApp, 'admin', 'admin-password');
      async function localCreateMonitor(name: string): Promise<MonitorJson> {
        const res = await localApp
          .client()
          .post('/api/v1/monitors', { name }, { token: localAdminToken });
        return res.body as MonitorJson;
      }
      async function localCode(monitorId: string): Promise<string> {
        const res = await localApp
          .client()
          .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: localAdminToken });
        return (res.body as MonitorPairingCodeResponse).code;
      }

      const monitor = await localCreateMonitor('Standby ttl');
      const code = await localCode(monitor.id);
      const monitor2 = await localCreateMonitor('Standby expired');
      const code2 = await localCode(monitor2.id);

      localApp.clock.advance(24 * 60 * 60 * 1000 - 1000);
      const justBefore = await localApp.client().post('/api/v1/auth/monitor/pair', { code });
      expect(justBefore.status).toBe(200);

      localApp.clock.advance(1000 + 1000);
      const expired = await localApp.client().post('/api/v1/auth/monitor/pair', { code: code2 });
      expect(expired.status).toBe(401);
      expect(expired.body).toMatchObject({ error: { code: 'invalid_pairing_code' } });
    } finally {
      await localApp.close();
    }
  });

  it('a person pairing code is rejected on /auth/monitor/pair, and vice versa for a monitor code on /auth/pair', async () => {
    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'crew-monitor-cross',
      password: 'crew-password',
    });
    const personCodeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    const personCode = (personCodeRes.body as PersonPairingCodeResponse).code;

    const monitorPairWithPersonCode = await app
      .client()
      .post('/api/v1/auth/monitor/pair', { code: personCode });
    expect(monitorPairWithPersonCode.status).toBe(401);
    expect(monitorPairWithPersonCode.body).toMatchObject({
      error: { code: 'invalid_pairing_code' },
    });

    const monitor = await createMonitor('Standby cross');
    const monitorCode = await monitorPairingCode(monitor.id);
    const personPairWithMonitorCode = await app
      .client()
      .post('/api/v1/auth/pair', { code: monitorCode, platform: 'ios', app_version: '1.0.0' });
    expect(personPairWithMonitorCode.status).toBe(401);
    expect(personPairWithMonitorCode.body).toMatchObject({
      error: { code: 'invalid_pairing_code' },
    });
  });

  it('refresh rotates the token; the old one is rejected afterwards', async () => {
    const monitor = await createMonitor('Standby refresh');
    const session = await pairMonitor(await monitorPairingCode(monitor.id));

    const refreshRes = await app
      .client()
      .post('/api/v1/auth/monitor/refresh', { refresh_token: session.refresh_token });
    expect(refreshRes.status).toBe(200);
    const refreshed = refreshRes.body as MonitorSession;
    expect(refreshed.monitor.id).toBe(monitor.id);
    expect(refreshed.refresh_token).not.toBe(session.refresh_token);

    const replay = await app
      .client()
      .post('/api/v1/auth/monitor/refresh', { refresh_token: session.refresh_token });
    expect(replay.status).toBe(401);
    expect(replay.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });

    const meRes = await app.client().get('/api/v1/monitor/me', { token: refreshed.access_token });
    expect(meRes.status).toBe(200);
  });

  it('a monitor token cannot write, and cannot use person-only read routes', async () => {
    const monitor = await createMonitor('Standby readonly');
    const session = await pairMonitor(await monitorPairingCode(monitor.id));
    const token = session.access_token;

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft RO',
      personType: 'youth',
      permission: 'crew',
      username: 'crew-monitor-ro',
      password: 'crew-password',
    });

    expect(
      (
        await app
          .client()
          .post(
            '/api/v1/vehicles',
            { call_sign: 'Florian 1', short_name: 'F1', type: 'LF' },
            { token }
          )
      ).status
    ).toBe(403);
    expect(
      (
        await app
          .client()
          .put(
            '/api/v1/vehicles/00000000-0000-0000-0000-000000000000/status',
            { status: 3 },
            { token }
          )
      ).status
    ).toBe(403);
    expect(
      (
        await app
          .client()
          .patch(`/api/v1/persons/${crewPerson.id}`, { display_name: 'x' }, { token })
      ).status
    ).toBe(403);
    expect((await app.client().get('/api/v1/persons', { token })).status).toBe(403);
    expect((await app.client().post('/api/v1/monitors', { name: 'x' }, { token })).status).toBe(
      403
    );
    expect((await app.client().get('/api/v1/me', { token })).status).toBe(403);
  });

  it('revoking a monitor ends its live /ws session (session.revoked + 4403) and invalidates its tokens, without affecting others', async () => {
    const monitorA = await createMonitor('Standby revoke A');
    const sessionA = await pairMonitor(await monitorPairingCode(monitorA.id));
    const monitorB = await createMonitor('Standby revoke B');
    const sessionB = await pairMonitor(await monitorPairingCode(monitorB.id));

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft Revoke',
      personType: 'youth',
      permission: 'crew',
      username: 'crew-monitor-revoke',
      password: 'crew-password',
    });
    const personCodeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    const personPairRes = await app.client().post('/api/v1/auth/pair', {
      code: (personCodeRes.body as PersonPairingCodeResponse).code,
      platform: 'ios',
      app_version: '1.0.0',
    });
    const personToken = (personPairRes.body as { access_token: string }).access_token;

    const wsA = await connectWs(app.baseUrl, sessionA.access_token);
    await wsA.next(m => m.type === 'hello');
    const wsB = await connectWs(app.baseUrl, sessionB.access_token);
    const helloB = await wsB.next(m => m.type === 'hello');
    const wsPerson = await connectWs(app.baseUrl, personToken);
    await wsPerson.next(m => m.type === 'hello');

    const deleteRes = await app
      .client()
      .delete(`/api/v1/monitors/${monitorA.id}`, { token: adminToken });
    expect(deleteRes.status).toBe(204);

    const revoked = await wsA.next(m => m.type === 'session.revoked', 2000);
    expect(revoked).toMatchObject({ type: 'session.revoked' });
    expect(await wsA.closeCode).toBe(4403);

    const snapshotAfter = await app
      .client()
      .get('/api/v1/snapshot', { token: sessionA.access_token });
    expect(snapshotAfter.status).toBe(401);

    const refreshAfter = await app
      .client()
      .post('/api/v1/auth/monitor/refresh', { refresh_token: sessionA.refresh_token });
    expect(refreshAfter.status).toBe(401);

    // Other monitor and the person connection are unaffected, seq unchanged.
    const meB = await app.client().get('/api/v1/monitor/me', { token: sessionB.access_token });
    expect(meB.status).toBe(200);
    const snapshot = await app.client().get('/api/v1/snapshot', { token: adminToken });
    expect((snapshot.body as { seq: number }).seq).toBe(helloB.seq);

    wsB.close();
    wsPerson.close();
  });

  it('a revoked monitor can be re-paired with a new code', async () => {
    const monitor = await createMonitor('Standby re-pair');
    await pairMonitor(await monitorPairingCode(monitor.id));
    await app.client().delete(`/api/v1/monitors/${monitor.id}`, { token: adminToken });

    const newCode = await monitorPairingCode(monitor.id);
    const rePairRes = await app.client().post('/api/v1/auth/monitor/pair', { code: newCode });
    expect(rePairRes.status).toBe(200);
    expect((rePairRes.body as MonitorSession).monitor.id).toBe(monitor.id);
  });

  it('re-pairing an already-paired monitor ends the old session (old refresh 401s, old ws gets session.revoked)', async () => {
    const monitor = await createMonitor('Standby re-pair live');
    const oldSession = await pairMonitor(await monitorPairingCode(monitor.id));

    const ws = await connectWs(app.baseUrl, oldSession.access_token);
    await ws.next(m => m.type === 'hello');

    const newCode = await monitorPairingCode(monitor.id);
    const newSession = await pairMonitor(newCode);
    expect(newSession.monitor.id).toBe(monitor.id);

    const revoked = await ws.next(m => m.type === 'session.revoked', 2000);
    expect(revoked).toMatchObject({ type: 'session.revoked' });
    expect(await ws.closeCode).toBe(4403);

    const oldRefreshRes = await app
      .client()
      .post('/api/v1/auth/monitor/refresh', { refresh_token: oldSession.refresh_token });
    expect(oldRefreshRes.status).toBe(401);

    const newMeRes = await app
      .client()
      .get('/api/v1/monitor/me', { token: newSession.access_token });
    expect(newMeRes.status).toBe(200);
  });

  it('GET /monitors reflects paired/revoked_at/last_seen_at correctly', async () => {
    const monitor = await createMonitor('Standby status fields');

    const beforePair = (await app.client().get('/api/v1/monitors', { token: adminToken }))
      .body as MonitorJson[];
    const beforeEntry = beforePair.find(m => m.id === monitor.id)!;
    expect(beforeEntry.paired).toBe(false);

    const session = await pairMonitor(await monitorPairingCode(monitor.id));

    const afterPair = (await app.client().get('/api/v1/monitors', { token: adminToken }))
      .body as Array<MonitorJson & { paired_at: string | null; last_seen_at: string | null }>;
    const afterEntry = afterPair.find(m => m.id === monitor.id)!;
    expect(afterEntry.paired).toBe(true);
    expect(afterEntry.paired_at).toBeTruthy();
    expect(afterEntry.last_seen_at).toBeTruthy();

    await app
      .client()
      .post('/api/v1/auth/monitor/refresh', { refresh_token: session.refresh_token });

    await app.client().delete(`/api/v1/monitors/${monitor.id}`, { token: adminToken });
    const afterRevoke = (await app.client().get('/api/v1/monitors', { token: adminToken }))
      .body as Array<MonitorJson & { revoked_at: string | null }>;
    const revokedEntry = afterRevoke.find(m => m.id === monitor.id)!;
    expect(revokedEntry.revoked_at).toBeTruthy();
    expect(revokedEntry.paired).toBe(false);
  });

  it('rejects an unknown monitor pairing code', async () => {
    const unknown = await app.client().post('/api/v1/auth/monitor/pair', { code: 'ZZZZ-ZZZZ' });
    expect(unknown.status).toBe(401);
    expect(unknown.body).toMatchObject({ error: { code: 'invalid_pairing_code' } });
  });

  it('rejects an unknown monitor refresh token', async () => {
    const res = await app
      .client()
      .post('/api/v1/auth/monitor/refresh', { refresh_token: 'does-not-exist' });
    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });
  });

  it('a person token on /monitor/me is rejected with 403', async () => {
    const res = await app.client().get('/api/v1/monitor/me', { token: adminToken });
    expect(res.status).toBe(403);
    expect(res.body).toMatchObject({ error: { code: 'forbidden' } });
  });
});
