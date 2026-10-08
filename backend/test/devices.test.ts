import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

interface PairingCodeResponse {
  person_id: string;
  display_name: string;
  code: string;
  expires_at: string;
}

interface DeviceSession {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  device_id: string;
  person: { id: string; display_name: string; person_type: string; permission: string };
}

interface DeviceJson {
  id: string;
  platform: string;
  device_name: string | null;
  app_version: string;
  created_at: string;
  last_seen_at: string;
  revoked_at: string | null;
}

async function createCrewPerson(
  app: TestApp,
  overrides?: Partial<Parameters<typeof createPerson>[1]>
) {
  return createPerson(app, {
    displayName: 'Mannschaft',
    personType: 'youth',
    permission: 'crew',
    username: 'crew-devices',
    password: 'crew-password',
    ...overrides,
  });
}

describe('device sessions', () => {
  let app: TestApp;
  let adminToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');
  });

  afterAll(async () => {
    await app.close();
  });

  async function pairNewDevice(): Promise<DeviceSession> {
    const crewPerson = await createCrewPerson(app, {
      username: `crew-${Date.now()}-${Math.random()}`,
    });
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as PairingCodeResponse).code;
    const pairRes = await app.client().post('/api/v1/auth/pair', {
      code,
      platform: 'android',
      app_version: '1.0.0',
    });
    return pairRes.body as DeviceSession;
  }

  it('rotates the device refresh token and the old one can no longer be used', async () => {
    const session = await pairNewDevice();

    const refreshRes = await app
      .client()
      .post('/api/v1/auth/device/refresh', { refresh_token: session.refresh_token });
    expect(refreshRes.status).toBe(200);
    const refreshed = refreshRes.body as DeviceSession;
    expect(refreshed.device_id).toBe(session.device_id);
    expect(refreshed.refresh_token).not.toBe(session.refresh_token);

    const replay = await app
      .client()
      .post('/api/v1/auth/device/refresh', { refresh_token: session.refresh_token });
    expect(replay.status).toBe(401);
    expect(replay.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });
  });

  it('device/logout revokes the device: its access token is rejected and a live /ws connection is dropped', async () => {
    const session = await pairNewDevice();

    const ws = await connectWs(app.baseUrl, session.access_token);
    await ws.next(m => m.type === 'hello');

    const logoutRes = await app
      .client()
      .post('/api/v1/auth/device/logout', {}, { token: session.access_token });
    expect(logoutRes.status).toBe(204);

    const revoked = await ws.next(m => m.type === 'session.revoked', 2000);
    expect(revoked).toMatchObject({ type: 'session.revoked' });
    const closeCode = await ws.closeCode;
    expect(closeCode).toBe(4403);

    const meRes = await app.client().get('/api/v1/me', { token: session.access_token });
    expect(meRes.status).toBe(401);

    const refreshAfterLogout = await app
      .client()
      .post('/api/v1/auth/device/refresh', { refresh_token: session.refresh_token });
    expect(refreshAfterLogout.status).toBe(401);
  });

  it('another device of the same person is unaffected by that device logout, seq unchanged', async () => {
    const crewPerson = await createCrewPerson(app, { username: `crew-multi-${Date.now()}` });

    async function pairThisPerson(): Promise<DeviceSession> {
      const codeRes = await app
        .client()
        .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
      const code = (codeRes.body as PairingCodeResponse).code;
      const pairRes = await app
        .client()
        .post('/api/v1/auth/pair', { code, platform: 'ios', app_version: '1.0.0' });
      return pairRes.body as DeviceSession;
    }

    const deviceA = await pairThisPerson();
    const deviceB = await pairThisPerson();

    const wsOther = await connectWs(app.baseUrl, adminToken);
    const otherHello = await wsOther.next(m => m.type === 'hello');

    const wsB = await connectWs(app.baseUrl, deviceB.access_token);
    await wsB.next(m => m.type === 'hello');

    const logoutRes = await app
      .client()
      .post('/api/v1/auth/device/logout', {}, { token: deviceA.access_token });
    expect(logoutRes.status).toBe(204);

    const meResB = await app.client().get('/api/v1/me', { token: deviceB.access_token });
    expect(meResB.status).toBe(200);

    const snapshot = await app.client().get('/api/v1/snapshot', { token: adminToken });
    expect((snapshot.body as { seq: number }).seq).toBe(otherHello.seq);

    wsOther.close();
    wsB.close();
  });

  it('deactivating a person revokes their devices too (session.revoked + 401 on reuse)', async () => {
    const crewPerson = await createCrewPerson(app, { username: `crew-deact-${Date.now()}` });
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as PairingCodeResponse).code;
    const pairRes = await app
      .client()
      .post('/api/v1/auth/pair', { code, platform: 'ios', app_version: '1.0.0' });
    const session = pairRes.body as DeviceSession;

    const ws = await connectWs(app.baseUrl, session.access_token);
    await ws.next(m => m.type === 'hello');

    const deactivate = await app
      .client()
      .patch(`/api/v1/persons/${crewPerson.id}`, { active: false }, { token: adminToken });
    expect(deactivate.status).toBe(200);

    const revoked = await ws.next(m => m.type === 'session.revoked', 2000);
    expect(revoked).toMatchObject({ type: 'session.revoked' });
    const closeCode = await ws.closeCode;
    expect(closeCode).toBe(4403);

    const meRes = await app.client().get('/api/v1/me', { token: session.access_token });
    expect(meRes.status).toBe(401);
  });

  it('admin can list a person devices (platform/app_version/revoked_at) and revoke one via DELETE /devices/{id}', async () => {
    const session = await pairNewDevice();
    const personId = session.person.id;

    const listRes = await app.client().get(`/api/v1/persons/${personId}/devices`, {
      token: adminToken,
    });
    expect(listRes.status).toBe(200);
    const devices = listRes.body as DeviceJson[];
    expect(devices.map(d => d.id)).toContain(session.device_id);
    const listed = devices.find(d => d.id === session.device_id)!;
    expect(listed.platform).toBe('android');
    expect(listed.app_version).toBe('1.0.0');
    expect(listed.revoked_at).toBeNull();

    const deleteRes = await app
      .client()
      .delete(`/api/v1/devices/${session.device_id}`, { token: adminToken });
    expect(deleteRes.status).toBe(204);

    const meRes = await app.client().get('/api/v1/me', { token: session.access_token });
    expect(meRes.status).toBe(401);

    const listAfter = await app.client().get(`/api/v1/persons/${personId}/devices`, {
      token: adminToken,
    });
    const revokedListed = (listAfter.body as DeviceJson[]).find(d => d.id === session.device_id)!;
    expect(revokedListed.revoked_at).toBeTruthy();

    // Deleting again is idempotent.
    const deleteAgain = await app
      .client()
      .delete(`/api/v1/devices/${session.device_id}`, { token: adminToken });
    expect(deleteAgain.status).toBe(204);
  });

  it('404s for an unknown device id', async () => {
    const deleteRes = await app
      .client()
      .delete('/api/v1/devices/00000000-0000-0000-0000-000000000000', { token: adminToken });
    expect(deleteRes.status).toBe(404);
  });

  it('a non-admin cannot list devices or revoke a device', async () => {
    const session = await pairNewDevice();

    const listRes = await app
      .client()
      .get(`/api/v1/persons/${session.person.id}/devices`, { token: session.access_token });
    expect(listRes.status).toBe(403);

    const deleteRes = await app
      .client()
      .delete(`/api/v1/devices/${session.device_id}`, { token: session.access_token });
    expect(deleteRes.status).toBe(403);
  });
});
