import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';

interface PersonJson {
  id: string;
  display_name: string;
  person_type: 'youth' | 'supervisor';
  permission: 'crew' | 'preparation' | 'dispatch' | 'admin';
  active: boolean;
  has_web_access: boolean;
  username: string | null;
}

describe('persons', () => {
  let app: TestApp;
  let adminToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    adminToken = await loginAs(app, 'admin', 'admin-password');
  });

  afterAll(async () => {
    await app.close();
  });

  async function createPersonViaApi(body: {
    display_name: string;
    person_type: 'youth' | 'supervisor';
    permission: 'crew' | 'preparation' | 'dispatch' | 'admin';
  }): Promise<PersonJson> {
    const res = await app.client().post('/api/v1/persons', body, { token: adminToken });
    expect(res.status).toBe(201);
    return res.body as PersonJson;
  }

  async function setWebAccess(
    personId: string,
    username: string,
    password: string
  ): Promise<{ status: number; body: unknown }> {
    return app
      .client()
      .put(`/api/v1/persons/${personId}/web-access`, { username, password }, { token: adminToken });
  }

  describe('permissions', () => {
    let crewToken: string;
    let preparationToken: string;
    let dispatchToken: string;

    beforeAll(async () => {
      const crew = await createPersonViaApi({
        display_name: 'Mannschaft Perm',
        person_type: 'youth',
        permission: 'crew',
      });
      crewToken = await signTestAccessToken(app, crew.id, 'crew');

      const preparation = await createPersonViaApi({
        display_name: 'Vorbereitung Perm',
        person_type: 'supervisor',
        permission: 'preparation',
      });
      await setWebAccess(preparation.id, 'prep-perm', 'prep-perm-password');
      preparationToken = await loginAs(app, 'prep-perm', 'prep-perm-password');

      const dispatch = await createPersonViaApi({
        display_name: 'Leitstelle Perm',
        person_type: 'supervisor',
        permission: 'dispatch',
      });
      await setWebAccess(dispatch.id, 'dispatch-perm', 'dispatch-perm-password');
      dispatchToken = await loginAs(app, 'dispatch-perm', 'dispatch-perm-password');
    });

    it('non-admin tokens get 403 and missing token gets 401 on every /persons route', async () => {
      const otherPerson = await createPersonViaApi({
        display_name: 'Ziel',
        person_type: 'youth',
        permission: 'crew',
      });

      for (const token of [crewToken, preparationToken, dispatchToken]) {
        expect((await app.client().get('/api/v1/persons', { token })).status).toBe(403);
        expect(
          (await app.client().get(`/api/v1/persons/${otherPerson.id}`, { token })).status
        ).toBe(403);
        expect(
          (
            await app
              .client()
              .post(
                '/api/v1/persons',
                { display_name: 'X', person_type: 'youth', permission: 'crew' },
                { token }
              )
          ).status
        ).toBe(403);
        expect(
          (
            await app
              .client()
              .patch(`/api/v1/persons/${otherPerson.id}`, { display_name: 'Y' }, { token })
          ).status
        ).toBe(403);
        expect(
          (
            await app
              .client()
              .put(
                `/api/v1/persons/${otherPerson.id}/web-access`,
                { username: 'blocked', password: 'blocked-password' },
                { token }
              )
          ).status
        ).toBe(403);
        expect(
          (await app.client().delete(`/api/v1/persons/${otherPerson.id}/web-access`, { token }))
            .status
        ).toBe(403);
      }

      expect((await app.client().get('/api/v1/persons')).status).toBe(401);
      expect((await app.client().get(`/api/v1/persons/${otherPerson.id}`)).status).toBe(401);
      expect(
        (
          await app.client().post('/api/v1/persons', {
            display_name: 'X',
            person_type: 'youth',
            permission: 'crew',
          })
        ).status
      ).toBe(401);
      expect(
        (await app.client().patch(`/api/v1/persons/${otherPerson.id}`, { display_name: 'Y' }))
          .status
      ).toBe(401);
      expect(
        (
          await app.client().put(`/api/v1/persons/${otherPerson.id}/web-access`, {
            username: 'blocked',
            password: 'blocked-password',
          })
        ).status
      ).toBe(401);
      expect(
        (await app.client().delete(`/api/v1/persons/${otherPerson.id}/web-access`)).status
      ).toBe(401);
    });
  });

  describe('lifecycle', () => {
    it('create/list/get/patch round trip', async () => {
      const created = await createPersonViaApi({
        display_name: 'Max M.',
        person_type: 'youth',
        permission: 'crew',
      });
      expect(created).toMatchObject({
        display_name: 'Max M.',
        person_type: 'youth',
        permission: 'crew',
        active: true,
        has_web_access: false,
        username: null,
      });

      const list = await app.client().get('/api/v1/persons', { token: adminToken });
      expect(list.status).toBe(200);
      expect((list.body as PersonJson[]).some(p => p.id === created.id)).toBe(true);
      const names = (list.body as PersonJson[]).map(p => p.display_name);
      expect([...names].sort()).toEqual(names);

      const got = await app.client().get(`/api/v1/persons/${created.id}`, { token: adminToken });
      expect(got.status).toBe(200);
      expect(got.body).toMatchObject({ id: created.id, display_name: 'Max M.' });

      const patched = await app
        .client()
        .patch(
          `/api/v1/persons/${created.id}`,
          { display_name: 'Max Muster' },
          { token: adminToken }
        );
      expect(patched.status).toBe(200);
      expect((patched.body as PersonJson).display_name).toBe('Max Muster');
    });

    it('get on an unknown person returns 404', async () => {
      const res = await app
        .client()
        .get('/api/v1/persons/00000000-0000-0000-0000-000000000000', { token: adminToken });
      expect(res.status).toBe(404);
      expect(res.body).toMatchObject({ error: { code: 'not_found' } });
    });

    it('rejects invalid create bodies with 400', async () => {
      const empty = await app
        .client()
        .post(
          '/api/v1/persons',
          { display_name: '', person_type: 'youth', permission: 'crew' },
          { token: adminToken }
        );
      expect(empty.status).toBe(400);

      const tooLong = await app
        .client()
        .post(
          '/api/v1/persons',
          { display_name: 'x'.repeat(61), person_type: 'youth', permission: 'crew' },
          { token: adminToken }
        );
      expect(tooLong.status).toBe(400);

      const badPermission = await app
        .client()
        .post(
          '/api/v1/persons',
          { display_name: 'X', person_type: 'youth', permission: 'nope' },
          { token: adminToken }
        );
      expect(badPermission.status).toBe(400);
    });

    it('has no DELETE route', async () => {
      const created = await createPersonViaApi({
        display_name: 'Nie löschbar',
        person_type: 'youth',
        permission: 'crew',
      });
      const res = await app.client().delete(`/api/v1/persons/${created.id}`, { token: adminToken });
      expect([404, 405]).toContain(res.status);
    });
  });

  describe('admin_requires_supervisor', () => {
    it('rejects creating an admin with person_type youth', async () => {
      const res = await app
        .client()
        .post(
          '/api/v1/persons',
          { display_name: 'Jugend-Admin', person_type: 'youth', permission: 'admin' },
          { token: adminToken }
        );
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'admin_requires_supervisor' } });
    });

    it('rejects patching an admin down to person_type youth', async () => {
      const created = await createPersonViaApi({
        display_name: 'Betreuer-Admin',
        person_type: 'supervisor',
        permission: 'admin',
      });

      const res = await app
        .client()
        .patch(`/api/v1/persons/${created.id}`, { person_type: 'youth' }, { token: adminToken });
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'admin_requires_supervisor' } });
    });
  });

  describe('last_admin', () => {
    it('cannot deactivate the last active admin, but can once a second admin exists', async () => {
      // The bootstrap admin is the only admin in a fresh app.
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const meRes = await freshApp.client().get('/api/v1/me', { token: freshAdminToken });
        const adminId = (meRes.body as { person: { id: string } }).person.id;

        const deactivateAlone = await freshApp
          .client()
          .patch(`/api/v1/persons/${adminId}`, { active: false }, { token: freshAdminToken });
        expect(deactivateAlone.status).toBe(409);
        expect(deactivateAlone.body).toMatchObject({ error: { code: 'last_admin' } });

        const demoteAlone = await freshApp
          .client()
          .patch(
            `/api/v1/persons/${adminId}`,
            { permission: 'dispatch' },
            { token: freshAdminToken }
          );
        expect(demoteAlone.status).toBe(409);
        expect(demoteAlone.body).toMatchObject({ error: { code: 'last_admin' } });

        const secondAdminRes = await freshApp
          .client()
          .post(
            '/api/v1/persons',
            { display_name: 'Zweiter Admin', person_type: 'supervisor', permission: 'admin' },
            { token: freshAdminToken }
          );
        expect(secondAdminRes.status).toBe(201);

        const demoteNow = await freshApp
          .client()
          .patch(
            `/api/v1/persons/${adminId}`,
            { permission: 'dispatch' },
            { token: freshAdminToken }
          );
        expect(demoteNow.status).toBe(200);
        expect((demoteNow.body as PersonJson).permission).toBe('dispatch');
      } finally {
        await freshApp.close();
      }
    });

    it('cannot demote the last active admin by deactivation either', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const meRes = await freshApp.client().get('/api/v1/me', { token: freshAdminToken });
        const adminId = (meRes.body as { person: { id: string } }).person.id;

        const res = await freshApp
          .client()
          .patch(`/api/v1/persons/${adminId}`, { active: false }, { token: freshAdminToken });
        expect(res.status).toBe(409);
        expect(res.body).toMatchObject({ error: { code: 'last_admin' } });
      } finally {
        await freshApp.close();
      }
    });
  });

  describe('web access', () => {
    it('set for dispatch allows login; set for crew is rejected; duplicate username is rejected', async () => {
      const dispatchPerson = await createPersonViaApi({
        display_name: 'Disponentin',
        person_type: 'supervisor',
        permission: 'dispatch',
      });
      const setRes = await setWebAccess(dispatchPerson.id, 'disponentin1', 'disponentin-password');
      expect(setRes.status).toBe(200);
      expect(setRes.body).toMatchObject({ has_web_access: true, username: 'disponentin1' });

      const loginRes = await app
        .client()
        .post('/api/v1/auth/login', { username: 'disponentin1', password: 'disponentin-password' });
      expect(loginRes.status).toBe(200);

      const crewPerson = await createPersonViaApi({
        display_name: 'Mannschaft Web',
        person_type: 'youth',
        permission: 'crew',
      });
      const crewRes = await setWebAccess(crewPerson.id, 'mannschaftweb', 'mannschaft-password');
      expect(crewRes.status).toBe(400);
      expect(crewRes.body).toMatchObject({ error: { code: 'web_access_not_allowed' } });

      const otherDispatch = await createPersonViaApi({
        display_name: 'Zweite Disponentin',
        person_type: 'supervisor',
        permission: 'dispatch',
      });
      const takenRes = await setWebAccess(otherDispatch.id, 'disponentin1', 'another-password');
      expect(takenRes.status).toBe(409);
      expect(takenRes.body).toMatchObject({ error: { code: 'username_taken' } });
    });

    it('removing web access makes login fail', async () => {
      const person = await createPersonViaApi({
        display_name: 'Entzogen',
        person_type: 'supervisor',
        permission: 'preparation',
      });
      await setWebAccess(person.id, 'entzogen1', 'entzogen-password');
      const removeRes = await app
        .client()
        .delete(`/api/v1/persons/${person.id}/web-access`, { token: adminToken });
      expect(removeRes.status).toBe(204);

      const loginRes = await app
        .client()
        .post('/api/v1/auth/login', { username: 'entzogen1', password: 'entzogen-password' });
      expect(loginRes.status).toBe(401);
    });

    it('changing permission to crew removes web access and existing refresh cookie stops working', async () => {
      const person = await createPersonViaApi({
        display_name: 'Herabgestuft',
        person_type: 'supervisor',
        permission: 'preparation',
      });
      await setWebAccess(person.id, 'herabgestuft1', 'herabgestuft-password');

      const client = app.client();
      const loginRes = await client.post('/api/v1/auth/login', {
        username: 'herabgestuft1',
        password: 'herabgestuft-password',
      });
      expect(loginRes.status).toBe(200);

      const patchRes = await app
        .client()
        .patch(`/api/v1/persons/${person.id}`, { permission: 'crew' }, { token: adminToken });
      expect(patchRes.status).toBe(200);
      expect(patchRes.body).toMatchObject({
        permission: 'crew',
        has_web_access: false,
        username: null,
      });

      const refreshRes = await client.post('/api/v1/auth/refresh');
      expect(refreshRes.status).toBe(401);
      expect(refreshRes.body).toMatchObject({ error: { code: 'invalid_refresh_token' } });

      const reloginRes = await app.client().post('/api/v1/auth/login', {
        username: 'herabgestuft1',
        password: 'herabgestuft-password',
      });
      expect(reloginRes.status).toBe(401);
    });

    it('a permission=crew person with credentials inserted directly in the DB cannot log in', async () => {
      await createPerson(app, {
        displayName: 'Direkt eingefügt',
        personType: 'youth',
        permission: 'crew',
        username: 'direkt-crew',
        password: 'direkt-password',
      });

      const res = await app
        .client()
        .post('/api/v1/auth/login', { username: 'direkt-crew', password: 'direkt-password' });
      expect(res.status).toBe(401);
      expect(res.body).toMatchObject({ error: { code: 'invalid_credentials' } });
    });
  });

  describe('deactivation takes effect immediately', () => {
    it('an existing access token gets 401 on GET /me immediately, and refresh fails', async () => {
      const person = await createPersonViaApi({
        display_name: 'Sofort gesperrt',
        person_type: 'supervisor',
        permission: 'dispatch',
      });
      await setWebAccess(person.id, 'sofort-gesperrt', 'sofort-password');

      const client = app.client();
      const loginRes = await client.post('/api/v1/auth/login', {
        username: 'sofort-gesperrt',
        password: 'sofort-password',
      });
      expect(loginRes.status).toBe(200);
      const token = (loginRes.body as { access_token: string }).access_token;

      const meBefore = await app.client().get('/api/v1/me', { token });
      expect(meBefore.status).toBe(200);

      const deactivateRes = await app
        .client()
        .patch(`/api/v1/persons/${person.id}`, { active: false }, { token: adminToken });
      expect(deactivateRes.status).toBe(200);

      // No clock advance: deactivation must take effect without waiting for
      // the access token to expire (ADR 0010 "Prüfung bei jeder Anfrage").
      const meAfter = await app.client().get('/api/v1/me', { token });
      expect(meAfter.status).toBe(401);

      const refreshRes = await client.post('/api/v1/auth/refresh');
      expect(refreshRes.status).toBe(401);
    });

    it('permission change takes effect immediately: dispatch token loses vehicle status access right after PATCH to crew', async () => {
      const person = await createPersonViaApi({
        display_name: 'Direkt wirksam',
        person_type: 'supervisor',
        permission: 'dispatch',
      });
      await setWebAccess(person.id, 'direkt-wirksam', 'direkt-wirksam-password');
      const token = await loginAs(app, 'direkt-wirksam', 'direkt-wirksam-password');

      const vehicleRes = await app
        .client()
        .post(
          '/api/v1/vehicles',
          { call_sign: 'Florian 9', short_name: 'LF 9', type: 'LF' },
          { token: adminToken }
        );
      expect(vehicleRes.status).toBe(201);
      const vehicleId = (vehicleRes.body as { id: string }).id;

      const statusBefore = await app
        .client()
        .put(`/api/v1/vehicles/${vehicleId}/status`, { status: 3 }, { token });
      expect(statusBefore.status).toBe(200);

      const patchRes = await app
        .client()
        .patch(`/api/v1/persons/${person.id}`, { permission: 'crew' }, { token: adminToken });
      expect(patchRes.status).toBe(200);

      const statusAfter = await app
        .client()
        .put(`/api/v1/vehicles/${vehicleId}/status`, { status: 4 }, { token });
      expect(statusAfter.status).toBe(403);
    });
  });
});
