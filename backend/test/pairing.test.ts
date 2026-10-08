import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';

interface PairingCodeResponse {
  person_id: string;
  display_name: string;
  code: string;
  expires_at: string;
}

interface DeviceSession {
  access_token: string;
  person: { id: string; display_name: string; person_type: string; permission: string };
}

async function createCrewPerson(
  app: TestApp,
  overrides?: Partial<Parameters<typeof createPerson>[1]>
) {
  return createPerson(app, {
    displayName: 'Mannschaft',
    personType: 'youth',
    permission: 'crew',
    username: 'crew-pairing',
    password: 'crew-password',
    ...overrides,
  });
}

describe('device pairing', () => {
  let app: TestApp;
  let adminToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');
  });

  afterAll(async () => {
    await app.close();
  });

  it('generates a pairing code for a person, usable exactly once in /auth/pair', async () => {
    const crewPerson = await createCrewPerson(app);

    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    expect(codeRes.status).toBe(201);
    const code = codeRes.body as PairingCodeResponse;
    expect(code.person_id).toBe(crewPerson.id);
    expect(code.code).toMatch(/^[A-Z0-9]{4}-[A-Z0-9]{4}$/);

    const pairRes = await app.client().post('/api/v1/auth/pair', {
      code: code.code,
      platform: 'ios',
      app_version: '1.0.0',
      device_name: 'iPhone von Max',
    });
    expect(pairRes.status).toBe(200);
    const session = pairRes.body as DeviceSession;
    expect(session.person.id).toBe(crewPerson.id);
    expect(session.access_token).toBeTruthy();

    // The device access token works on an authenticated endpoint.
    const meRes = await app.client().get('/api/v1/me', { token: session.access_token });
    expect(meRes.status).toBe(200);

    // The code is now used up; pairing again with the same code fails.
    const secondPair = await app.client().post('/api/v1/auth/pair', {
      code: code.code,
      platform: 'ios',
      app_version: '1.0.0',
    });
    expect(secondPair.status).toBe(401);
    expect(secondPair.body).toMatchObject({ error: { code: 'invalid_pairing_code' } });
  });

  it('accepts a code typed without the dash and in lowercase', async () => {
    const crewPerson = await createCrewPerson(app, { username: 'crew-pairing-2' });
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as PairingCodeResponse).code;
    const unformatted = code.replace('-', '').toLowerCase();

    const pairRes = await app.client().post('/api/v1/auth/pair', {
      code: unformatted,
      platform: 'android',
      app_version: '2.0.0',
    });
    expect(pairRes.status).toBe(200);
  });

  it('concurrent double redemption of the same code lets exactly one caller win', async () => {
    const crewPerson = await createCrewPerson(app, { username: 'crew-pairing-concurrent' });
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as PairingCodeResponse).code;

    const results = await Promise.all(
      Array.from({ length: 5 }, () =>
        app.client().post('/api/v1/auth/pair', {
          code,
          platform: 'ios',
          app_version: '1.0.0',
        })
      )
    );
    const successes = results.filter(r => r.status === 200);
    const failures = results.filter(r => r.status === 401);
    expect(successes).toHaveLength(1);
    expect(failures).toHaveLength(4);
  });

  it('rejects an unknown code', async () => {
    const unknown = await app.client().post('/api/v1/auth/pair', {
      code: 'ZZZZ-ZZZZ',
      platform: 'ios',
      app_version: '1.0.0',
    });
    expect(unknown.status).toBe(401);
    expect(unknown.body).toMatchObject({ error: { code: 'invalid_pairing_code' } });
  });

  it('a code is still valid just before its TTL and rejected just after', async () => {
    const freshApp = await startTestApp();
    try {
      const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
      const crewPerson = await createCrewPerson(freshApp, { username: 'crew-pairing-3' });
      const codeRes = await freshApp
        .client()
        .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: freshAdminToken });
      const code = (codeRes.body as PairingCodeResponse).code;

      // Just before expiry (TTL default 24h) the code still works.
      freshApp.clock.advance(24 * 60 * 60 * 1000 - 1000);
      const justBefore = await freshApp.client().post('/api/v1/auth/pair', {
        code,
        platform: 'ios',
        app_version: '1.0.0',
      });
      expect(justBefore.status).toBe(200);
    } finally {
      await freshApp.close();
    }
  });

  it('rejects a code once its TTL has elapsed', async () => {
    const freshApp = await startTestApp();
    try {
      const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
      const crewPerson = await createCrewPerson(freshApp, { username: 'crew-pairing-expired' });
      const codeRes = await freshApp
        .client()
        .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: freshAdminToken });
      const code = (codeRes.body as PairingCodeResponse).code;

      freshApp.clock.advance(24 * 60 * 60 * 1000 + 1000);

      const expired = await freshApp.client().post('/api/v1/auth/pair', {
        code,
        platform: 'ios',
        app_version: '1.0.0',
      });
      expect(expired.status).toBe(401);
      expect(expired.body).toMatchObject({ error: { code: 'invalid_pairing_code' } });
    } finally {
      await freshApp.close();
    }
  });

  it('generating a new pairing code invalidates the person older unused code', async () => {
    const crewPerson = await createCrewPerson(app, { username: 'crew-pairing-4' });

    const first = (
      await app
        .client()
        .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken })
    ).body as PairingCodeResponse;
    const second = (
      await app
        .client()
        .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken })
    ).body as PairingCodeResponse;
    expect(second.code).not.toBe(first.code);

    const pairWithFirst = await app.client().post('/api/v1/auth/pair', {
      code: first.code,
      platform: 'ios',
      app_version: '1.0.0',
    });
    expect(pairWithFirst.status).toBe(401);

    const pairWithSecond = await app.client().post('/api/v1/auth/pair', {
      code: second.code,
      platform: 'ios',
      app_version: '1.0.0',
    });
    expect(pairWithSecond.status).toBe(200);
  });

  it('403s for a non-admin and 404s for an unknown person', async () => {
    const crewPerson = await createCrewPerson(app, { username: 'crew-pairing-5' });
    const crewToken = await app
      .client()
      .post('/api/v1/auth/pair', {
        code: (
          (
            await app
              .client()
              .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken })
          ).body as PairingCodeResponse
        ).code,
        platform: 'ios',
        app_version: '1.0.0',
      })
      .then(res => (res.body as DeviceSession).access_token);

    const forbidden = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: crewToken });
    expect(forbidden.status).toBe(403);

    const forbiddenBulk = await app
      .client()
      .post('/api/v1/persons/pairing-codes', {}, { token: crewToken });
    expect(forbiddenBulk.status).toBe(403);

    const notFound = await app
      .client()
      .post(
        '/api/v1/persons/00000000-0000-0000-0000-000000000000/pairing-code',
        {},
        { token: adminToken }
      );
    expect(notFound.status).toBe(404);
  });

  it('409s for an inactive person', async () => {
    const crewPerson = await createCrewPerson(app, { username: 'crew-pairing-6' });
    const deactivate = await app
      .client()
      .patch(`/api/v1/persons/${crewPerson.id}`, { active: false }, { token: adminToken });
    expect(deactivate.status).toBe(200);

    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${crewPerson.id}/pairing-code`, {}, { token: adminToken });
    expect(codeRes.status).toBe(409);
    expect(codeRes.body).toMatchObject({ error: { code: 'person_inactive' } });
  });

  it('bulk-generates pairing codes for every active person when no ids are given, excluding inactive ones', async () => {
    const freshApp = await startTestApp();
    try {
      const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
      const crewPerson = await createCrewPerson(freshApp, { username: 'crew-bulk' });
      const inactivePerson = await createCrewPerson(freshApp, { username: 'crew-bulk-inactive' });
      const deactivate = await freshApp
        .client()
        .patch(
          `/api/v1/persons/${inactivePerson.id}`,
          { active: false },
          { token: freshAdminToken }
        );
      expect(deactivate.status).toBe(200);

      const bulkRes = await freshApp
        .client()
        .post('/api/v1/persons/pairing-codes', {}, { token: freshAdminToken });
      expect(bulkRes.status).toBe(201);
      const items = (bulkRes.body as { items: PairingCodeResponse[] }).items;
      const ids = items.map(i => i.person_id);
      expect(ids).toContain(crewPerson.id);
      expect(ids).not.toContain(inactivePerson.id);

      const adminPersonRes = await freshApp.client().get('/api/v1/me', { token: freshAdminToken });
      const adminId = (adminPersonRes.body as { person: { id: string } }).person.id;
      expect(ids).toContain(adminId);
    } finally {
      await freshApp.close();
    }
  });

  it('bulk-generates pairing codes for only the given ids', async () => {
    const crewPerson = await createCrewPerson(app, { username: 'crew-bulk-2' });
    const bulkRes = await app
      .client()
      .post(
        '/api/v1/persons/pairing-codes',
        { person_ids: [crewPerson.id] },
        { token: adminToken }
      );
    expect(bulkRes.status).toBe(201);
    const items = (bulkRes.body as { items: PairingCodeResponse[] }).items;
    expect(items).toHaveLength(1);
    expect(items[0]!.person_id).toBe(crewPerson.id);
  });

  it('bulk-generation 404s if one of the given ids does not exist', async () => {
    const crewPerson = await createCrewPerson(app, { username: 'crew-bulk-3' });
    const bulkRes = await app
      .client()
      .post(
        '/api/v1/persons/pairing-codes',
        { person_ids: [crewPerson.id, '00000000-0000-0000-0000-000000000000'] },
        { token: adminToken }
      );
    expect(bulkRes.status).toBe(404);
  });
});
