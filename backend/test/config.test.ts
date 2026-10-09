import { describe, it, expect } from 'vitest';
import { loadConfig } from '../src/config.js';

const base = {
  DATABASE_URL: 'postgres://user:pass@localhost:5432/db',
  JWT_SECRET: 'test-jwt-secret-at-least-32-characters-long',
};

describe('config boolean env parsing', () => {
  describe('COOKIE_SECURE', () => {
    it('defaults to false when unset', () => {
      const config = loadConfig({ ...base });
      expect(config.COOKIE_SECURE).toBe(false);
    });

    it('is false for the literal string "false" (the z.coerce.boolean trap)', () => {
      const config = loadConfig({ ...base, COOKIE_SECURE: 'false' });
      expect(config.COOKIE_SECURE).toBe(false);
    });

    it('is false for an empty string', () => {
      const config = loadConfig({ ...base, COOKIE_SECURE: '' });
      expect(config.COOKIE_SECURE).toBe(false);
    });

    it('is true for "true"', () => {
      const config = loadConfig({ ...base, COOKIE_SECURE: 'true' });
      expect(config.COOKIE_SECURE).toBe(true);
    });

    it('is true for "1"', () => {
      const config = loadConfig({ ...base, COOKIE_SECURE: '1' });
      expect(config.COOKIE_SECURE).toBe(true);
    });
  });

  describe('TRUST_PROXY', () => {
    it('defaults to false when unset', () => {
      const config = loadConfig({ ...base });
      expect(config.TRUST_PROXY).toBe(false);
    });

    it('is false for the literal string "false"', () => {
      const config = loadConfig({ ...base, TRUST_PROXY: 'false' });
      expect(config.TRUST_PROXY).toBe(false);
    });

    it('is true for "true"', () => {
      const config = loadConfig({ ...base, TRUST_PROXY: 'true' });
      expect(config.TRUST_PROXY).toBe(true);
    });

    it('is true for "1"', () => {
      const config = loadConfig({ ...base, TRUST_PROXY: '1' });
      expect(config.TRUST_PROXY).toBe(true);
    });
  });

  describe('APNS_PRODUCTION', () => {
    it('defaults to false when unset', () => {
      const config = loadConfig({ ...base });
      expect(config.APNS_PRODUCTION).toBe(false);
    });

    it('is false for the literal string "false"', () => {
      const config = loadConfig({ ...base, APNS_PRODUCTION: 'false' });
      expect(config.APNS_PRODUCTION).toBe(false);
    });

    it('is true for "true"', () => {
      const config = loadConfig({ ...base, APNS_PRODUCTION: 'true' });
      expect(config.APNS_PRODUCTION).toBe(true);
    });

    it('is true for "1"', () => {
      const config = loadConfig({ ...base, APNS_PRODUCTION: '1' });
      expect(config.APNS_PRODUCTION).toBe(true);
    });
  });
});

describe('config push env vars (ADR 0018)', () => {
  it('FCM_SERVICE_ACCOUNT_FILE and APNS_* are all optional and undefined by default', () => {
    const config = loadConfig({ ...base });
    expect(config.FCM_SERVICE_ACCOUNT_FILE).toBeUndefined();
    expect(config.APNS_KEY_FILE).toBeUndefined();
    expect(config.APNS_KEY_ID).toBeUndefined();
    expect(config.APNS_TEAM_ID).toBeUndefined();
    expect(config.APNS_BUNDLE_ID).toBeUndefined();
  });

  it('parse through when set', () => {
    const config = loadConfig({
      ...base,
      FCM_SERVICE_ACCOUNT_FILE: '/secrets/fcm.json',
      APNS_KEY_FILE: '/secrets/apns.p8',
      APNS_KEY_ID: 'ABC123',
      APNS_TEAM_ID: 'TEAM123',
      APNS_BUNDLE_ID: 'de.bftag.app',
      APNS_PRODUCTION: 'true',
    });
    expect(config.FCM_SERVICE_ACCOUNT_FILE).toBe('/secrets/fcm.json');
    expect(config.APNS_KEY_FILE).toBe('/secrets/apns.p8');
    expect(config.APNS_KEY_ID).toBe('ABC123');
    expect(config.APNS_TEAM_ID).toBe('TEAM123');
    expect(config.APNS_BUNDLE_ID).toBe('de.bftag.app');
    expect(config.APNS_PRODUCTION).toBe(true);
  });
});
