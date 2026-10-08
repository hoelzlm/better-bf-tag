import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';

describe('auth login', () => {
  let app: TestApp;

  beforeAll(async () => {
    app = await startTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('logs in with the bootstrap administrator', async () => {
    const res = await app.client().post('/api/v1/auth/login', {
      username: 'admin',
      password: 'admin-password',
    });

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      access_token: expect.any(String),
      person: {
        permission: 'admin',
        person_type: 'supervisor',
      },
    });

    const setCookie = res.headers.get('set-cookie');
    expect(setCookie).toBeTruthy();
    expect(setCookie).toContain('bftag_refresh=');
    expect(setCookie).toMatch(/HttpOnly/i);
    expect(setCookie).toContain('Path=/api/v1/auth');
  });

  it('rejects a wrong password with invalid_credentials', async () => {
    const res = await app.client().post('/api/v1/auth/login', {
      username: 'admin',
      password: 'wrong-password',
    });

    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ error: { code: 'invalid_credentials' } });
  });

  it('rejects an unknown username with the same invalid_credentials body', async () => {
    const res = await app.client().post('/api/v1/auth/login', {
      username: 'nobody',
      password: 'whatever',
    });

    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({
      error: {
        code: 'invalid_credentials',
        message: 'Benutzername oder Passwort falsch.',
      },
    });
  });

  it('returns the admin person from /me with a valid access token', async () => {
    const loginRes = await app.client().post('/api/v1/auth/login', {
      username: 'admin',
      password: 'admin-password',
    });
    const token = (loginRes.body as { access_token: string }).access_token;

    const meRes = await app.client().get('/api/v1/me', { token });
    expect(meRes.status).toBe(200);
    expect(meRes.body).toMatchObject({
      person: { permission: 'admin', person_type: 'supervisor' },
    });
  });

  it('rejects /me without a token', async () => {
    const res = await app.client().get('/api/v1/me');
    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ error: { code: 'unauthorized' } });
  });

  it('accepts the access token right before expiry and rejects it after', async () => {
    const freshApp = await startTestApp();
    try {
      const loginRes = await freshApp.client().post('/api/v1/auth/login', {
        username: 'admin',
        password: 'admin-password',
      });
      const token = (loginRes.body as { access_token: string }).access_token;

      freshApp.clock.advance(14 * 60 * 1000);
      const stillValid = await freshApp.client().get('/api/v1/me', { token });
      expect(stillValid.status).toBe(200);

      freshApp.clock.advance(1 * 60 * 1000 + 1000);
      const expired = await freshApp.client().get('/api/v1/me', { token });
      expect(expired.status).toBe(401);
      expect(expired.body).toMatchObject({ error: { code: 'unauthorized' } });
    } finally {
      await freshApp.close();
    }
  });

  it('is idempotent across restarts: a second BOOTSTRAP_ADMIN_* does not create a second admin', async () => {
    const freshApp = await startTestApp();
    try {
      const restarted = await freshApp.restart({
        BOOTSTRAP_ADMIN_USERNAME: 'second',
        BOOTSTRAP_ADMIN_PASSWORD: 'second-password',
      });
      try {
        const secondLogin = await restarted.client().post('/api/v1/auth/login', {
          username: 'second',
          password: 'second-password',
        });
        expect(secondLogin.status).toBe(401);

        const adminLogin = await restarted.client().post('/api/v1/auth/login', {
          username: 'admin',
          password: 'admin-password',
        });
        expect(adminLogin.status).toBe(200);
      } finally {
        await restarted.close();
      }
    } finally {
      // freshApp was already replaced by restart(); closing restarted above is enough,
      // but guard in case restart() ever throws before replacing it.
    }
  });

  it('starts fine without BOOTSTRAP_* vars on an empty database', async () => {
    const noBootstrapApp = await startTestApp({
      config: { BOOTSTRAP_ADMIN_USERNAME: undefined, BOOTSTRAP_ADMIN_PASSWORD: undefined },
    });
    try {
      const res = await noBootstrapApp.client().get('/api/v1/health');
      expect(res.status).toBe(200);
    } finally {
      await noBootstrapApp.close();
    }
  });
});
