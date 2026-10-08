import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';

const REFRESH_COOKIE = 'bftag_refresh';

describe('auth session (refresh, logout, rate limiting)', () => {
  let app: TestApp;

  beforeAll(async () => {
    app = await startTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  async function login(client = app.client()) {
    const res = await client.post('/api/v1/auth/login', {
      username: 'admin',
      password: 'admin-password',
    });
    expect(res.status).toBe(200);
    return client;
  }

  it('rotates the refresh token and the new access token works on /me', async () => {
    const client = await login();
    const oldRefresh = client.getCookie(REFRESH_COOKIE);
    expect(oldRefresh).toBeTruthy();

    const refreshRes = await client.post('/api/v1/auth/refresh');
    expect(refreshRes.status).toBe(200);
    expect(refreshRes.body).toMatchObject({
      access_token: expect.any(String),
      person: { permission: 'admin', person_type: 'supervisor' },
    });

    const setCookie = refreshRes.headers.get('set-cookie');
    expect(setCookie).toBeTruthy();
    expect(setCookie).toContain(`${REFRESH_COOKIE}=`);

    const newRefresh = client.getCookie(REFRESH_COOKIE);
    expect(newRefresh).toBeTruthy();
    expect(newRefresh).not.toBe(oldRefresh);

    const token = (refreshRes.body as { access_token: string }).access_token;
    const meRes = await client.get('/api/v1/me', { token });
    expect(meRes.status).toBe(200);
  });

  it('rejects the old refresh token after rotation (replay)', async () => {
    const client = await login();
    const oldRefresh = client.getCookie(REFRESH_COOKIE);
    expect(oldRefresh).toBeTruthy();

    const firstRefresh = await client.post('/api/v1/auth/refresh');
    expect(firstRefresh.status).toBe(200);

    // Replay the pre-rotation token manually.
    client.setCookie(REFRESH_COOKIE, oldRefresh as string);
    const replay = await client.post('/api/v1/auth/refresh');
    expect(replay.status).toBe(401);
    expect(replay.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });
  });

  it('rejects refresh without a cookie', async () => {
    const client = app.client();
    const res = await client.post('/api/v1/auth/refresh');
    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });
  });

  it('logs out, revoking the session so a replayed refresh is rejected', async () => {
    const client = await login();
    const refreshToken = client.getCookie(REFRESH_COOKIE);
    expect(refreshToken).toBeTruthy();

    const logoutRes = await client.post('/api/v1/auth/logout');
    expect(logoutRes.status).toBe(204);

    client.setCookie(REFRESH_COOKIE, refreshToken as string);
    const refreshAfterLogout = await client.post('/api/v1/auth/refresh');
    expect(refreshAfterLogout.status).toBe(401);
    expect(refreshAfterLogout.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });
  });

  it('rejects refresh once the refresh token has expired', async () => {
    const freshApp = await startTestApp();
    try {
      const client = await login(freshApp.client());

      freshApp.clock.advance(14 * 24 * 60 * 60 * 1000 + 60 * 1000);

      const res = await client.post('/api/v1/auth/refresh');
      expect(res.status).toBe(401);
      expect(res.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });
    } finally {
      await freshApp.close();
    }
  });

  it('rate limits repeated failed logins', async () => {
    const limitedApp = await startTestApp({ config: { AUTH_RATE_LIMIT_MAX: 3 } });
    try {
      const client = limitedApp.client();
      for (let i = 0; i < 3; i++) {
        const res = await client.post('/api/v1/auth/login', {
          username: 'admin',
          password: 'wrong-password',
        });
        expect(res.status).toBe(401);
      }

      const fourth = await client.post('/api/v1/auth/login', {
        username: 'admin',
        password: 'wrong-password',
      });
      expect(fourth.status).toBe(429);
      expect(fourth.body).toMatchObject({ error: { code: 'rate_limited' } });
    } finally {
      await limitedApp.close();
    }
  });
});
