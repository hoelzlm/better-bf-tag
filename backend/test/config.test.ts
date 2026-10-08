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
});
