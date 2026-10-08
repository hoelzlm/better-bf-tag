import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';

/**
 * Black-box test for ADR 0011 / TRUST_PROXY: when the backend sits behind
 * Caddy, Fastify must key the auth rate limit off the real client IP from
 * X-Forwarded-For, not the proxy's IP. Two different XFF IPs must not share
 * a rate-limit bucket.
 */
async function loginAs(baseUrl: string, xForwardedFor: string): Promise<Response> {
  return fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-forwarded-for': xForwardedFor,
    },
    body: JSON.stringify({ username: 'nobody', password: 'whatever' }),
  });
}

describe('auth rate limit with TRUST_PROXY', () => {
  const RATE_LIMIT_MAX = 2;

  let trustingApp: TestApp;
  let defaultApp: TestApp;

  beforeAll(async () => {
    trustingApp = await startTestApp({
      config: { TRUST_PROXY: true, AUTH_RATE_LIMIT_MAX: RATE_LIMIT_MAX },
    });
    defaultApp = await startTestApp({
      config: { TRUST_PROXY: false, AUTH_RATE_LIMIT_MAX: RATE_LIMIT_MAX },
    });
  });

  afterAll(async () => {
    await trustingApp.close();
    await defaultApp.close();
  });

  it('keys the bucket per X-Forwarded-For IP when TRUST_PROXY=true', async () => {
    // Exhaust the bucket for the first "client" IP.
    for (let i = 0; i < RATE_LIMIT_MAX; i++) {
      const res = await loginAs(trustingApp.baseUrl, '203.0.113.1');
      expect(res.status).toBe(401);
    }
    const limited = await loginAs(trustingApp.baseUrl, '203.0.113.1');
    expect(limited.status).toBe(429);

    // A different "client" IP must not be affected.
    const otherIp = await loginAs(trustingApp.baseUrl, '203.0.113.2');
    expect(otherIp.status).toBe(401);
  });

  it('without TRUST_PROXY, different X-Forwarded-For values share the same bucket (socket IP)', async () => {
    for (let i = 0; i < RATE_LIMIT_MAX; i++) {
      const res = await loginAs(defaultApp.baseUrl, '203.0.113.9');
      expect(res.status).toBe(401);
    }
    // A different XFF value is ignored when TRUST_PROXY is off: the real
    // (loopback) socket IP is shared, so this request also hits the limit.
    const stillLimited = await loginAs(defaultApp.baseUrl, '203.0.113.10');
    expect(stillLimited.status).toBe(429);
  });
});
