import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import type { GeocodeResult, GeocoderOptions } from '../src/geocoding/geocoder.js';
import { Geocoder } from '../src/geocoding/geocoder.js';

/** A Geocoder whose `search()` is fully controlled by the test, no fetch. */
class FakeGeocoder extends Geocoder {
  results: GeocodeResult[] = [];

  constructor() {
    // enabled is irrelevant here: search() is overridden below.
    super({
      enabled: true,
      baseUrl: 'http://unused.invalid',
      countryCodes: 'de',
    } satisfies GeocoderOptions);
  }

  override async search(): Promise<GeocodeResult[]> {
    return this.results;
  }
}

describe('geocode route', () => {
  let app: TestApp;
  let fakeGeocoder: FakeGeocoder;
  let adminToken: string;
  let dispatchToken: string;
  let preparationToken: string;
  let crewToken: string;

  beforeAll(async () => {
    fakeGeocoder = new FakeGeocoder();
    app = await startTestApp({ geocoder: fakeGeocoder });

    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'geo-dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'geo-dispatch1', 'dispatch-password');

    await createPerson(app, {
      displayName: 'Vorbereitung',
      personType: 'supervisor',
      permission: 'preparation',
      username: 'geo-prep1',
      password: 'prep-password',
    });
    preparationToken = await loginAs(app, 'geo-prep1', 'prep-password');

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'geo-crew1',
      password: 'crew-password',
    });
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');
  });

  afterAll(async () => {
    await app.close();
  });

  async function monitorToken(): Promise<string> {
    const createRes = await app
      .client()
      .post('/api/v1/monitors', { name: `Standby geo ${Math.random()}` }, { token: adminToken });
    const monitorId = (createRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    return (pairRes.body as { access_token: string }).access_token;
  }

  describe('permissions', () => {
    it('401 unauthenticated, 403 for crew and monitor, 200 for preparation/dispatch/admin', async () => {
      const monitor = await monitorToken();

      const unauthenticated = await app.client().get('/api/v1/geocode?q=Hauptstr%201');
      expect(unauthenticated.status).toBe(401);

      for (const token of [crewToken, monitor]) {
        const res = await app.client().get('/api/v1/geocode?q=Hauptstr%201', { token });
        expect(res.status).toBe(403);
      }

      for (const token of [preparationToken, dispatchToken, adminToken]) {
        const res = await app.client().get('/api/v1/geocode?q=Hauptstr%201', { token });
        expect(res.status).toBe(200);
      }
    });
  });

  describe('validation', () => {
    it('400 validation_error for q shorter than 3 or longer than 200 chars', async () => {
      const tooShort = await app.client().get('/api/v1/geocode?q=ab', { token: dispatchToken });
      expect(tooShort.status).toBe(400);
      expect(tooShort.body).toMatchObject({ error: { code: 'validation_error' } });

      const tooLong = await app
        .client()
        .get(`/api/v1/geocode?q=${'a'.repeat(201)}`, { token: dispatchToken });
      expect(tooLong.status).toBe(400);
      expect(tooLong.body).toMatchObject({ error: { code: 'validation_error' } });

      const justRight = await app
        .client()
        .get(`/api/v1/geocode?q=${'a'.repeat(200)}`, { token: dispatchToken });
      expect(justRight.status).toBe(200);
    });
  });

  describe('results', () => {
    it('passes through whatever the injected geocoder returns', async () => {
      fakeGeocoder.results = [
        { label: 'Hauptstr 1, Musterstadt', latitude: 48.1, longitude: 11.5 },
      ];

      const res = await app
        .client()
        .get('/api/v1/geocode?q=Hauptstr%201', { token: dispatchToken });

      expect(res.status).toBe(200);
      expect(res.body).toEqual({
        results: [{ label: 'Hauptstr 1, Musterstadt', latitude: 48.1, longitude: 11.5 }],
      });

      fakeGeocoder.results = [];
    });
  });

  describe('disabled', () => {
    it('returns {results: []} when geocoding is disabled (test default)', async () => {
      const disabledApp = await startTestApp();
      try {
        const token = await loginAs(disabledApp, 'admin', 'admin-password');
        const res = await disabledApp.client().get('/api/v1/geocode?q=Hauptstr%201', { token });
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ results: [] });
      } finally {
        await disabledApp.close();
      }
    });
  });
});
