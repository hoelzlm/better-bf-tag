import { describe, it, expect } from 'vitest';
import { Geocoder, type GeocodeResult } from '../src/geocoding/geocoder.js';

interface FakeFetchCall {
  url: string;
  init?: RequestInit;
}

/**
 * A `now`/`sleep` pair sharing one logical clock: `sleep(ms)` advances the
 * clock by `ms` and resolves immediately (no real timers), so rate-limit
 * tests are deterministic and instant.
 */
function fakeTimers(start = 0) {
  let current = start;
  return {
    now: () => current,
    sleep: async (ms: number) => {
      current += ms;
    },
    advance: (ms: number) => {
      current += ms;
    },
  };
}

function okResponse(body: unknown): Response {
  return {
    ok: true,
    status: 200,
    json: async () => body,
  } as unknown as Response;
}

function nominatimEntry(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    display_name: 'Hauptstr 1, Musterstadt',
    lat: '48.1234',
    lon: '11.5678',
    ...overrides,
  };
}

function makeFetch(impl: (url: string, init?: RequestInit) => Promise<Response>): {
  fetch: typeof fetch;
  calls: FakeFetchCall[];
} {
  const calls: FakeFetchCall[] = [];
  const fakeFetch = (async (url: string | URL, init?: RequestInit) => {
    calls.push({ url: url.toString(), init });
    return impl(url.toString(), init);
  }) as unknown as typeof fetch;
  return { fetch: fakeFetch, calls };
}

function baseOptions(overrides: Partial<ConstructorParameters<typeof Geocoder>[0]> = {}) {
  const timers = fakeTimers();
  return {
    enabled: true,
    baseUrl: 'https://nominatim.example.org',
    countryCodes: 'de',
    now: timers.now,
    sleep: timers.sleep,
    ...overrides,
  };
}

describe('Geocoder', () => {
  it('maps display_name/lat/lon and drops entries with non-finite numbers', async () => {
    const { fetch: fakeFetch } = makeFetch(async () =>
      okResponse([
        nominatimEntry(),
        nominatimEntry({ lat: 'not-a-number' }),
        nominatimEntry({ lon: 'not-a-number' }),
      ])
    );
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch }));

    const results = await geocoder.search('Hauptstr 1');

    expect(results).toEqual<GeocodeResult[]>([
      { label: 'Hauptstr 1, Musterstadt', latitude: 48.1234, longitude: 11.5678 },
    ]);
  });

  it('builds the upstream URL and User-Agent header correctly', async () => {
    const { fetch: fakeFetch, calls } = makeFetch(async () => okResponse([nominatimEntry()]));
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch, contact: 'admin@example.org' }));

    await geocoder.search('Hauptstraße 1');

    expect(calls).toHaveLength(1);
    const { url, init } = calls[0]!;
    expect(url).toContain('q=Hauptstra');
    expect(url).toContain('format=jsonv2');
    expect(url).toContain('limit=5');
    expect(url).toContain('accept-language=de');
    expect(url).toContain('countrycodes=de');
    expect(url).toContain('email=admin%40example.org');
    const headers = init?.headers as Record<string, string>;
    expect(headers['User-Agent']).toBe(
      'better-bf-tag/1.0 (+https://github.com/hoelzlm/better-bf-tag; admin@example.org)'
    );
  });

  it('omits email from the URL and User-Agent when no contact is configured', async () => {
    const { fetch: fakeFetch, calls } = makeFetch(async () => okResponse([]));
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch }));

    await geocoder.search('Hauptstr 1');

    const { url, init } = calls[0]!;
    expect(url).not.toContain('email=');
    const headers = init?.headers as Record<string, string>;
    expect(headers['User-Agent']).toBe(
      'better-bf-tag/1.0 (+https://github.com/hoelzlm/better-bf-tag)'
    );
  });

  it('returns [] and never calls fetch when disabled', async () => {
    const { fetch: fakeFetch, calls } = makeFetch(async () => okResponse([nominatimEntry()]));
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch, enabled: false }));

    const results = await geocoder.search('Hauptstr 1');

    expect(results).toEqual([]);
    expect(calls).toHaveLength(0);
  });

  it('caches successful responses with a normalised key, calling fetch only once', async () => {
    const { fetch: fakeFetch, calls } = makeFetch(async () => okResponse([nominatimEntry()]));
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch }));

    const first = await geocoder.search('  Hauptstr 1 ');
    const second = await geocoder.search('hauptstr  1');

    expect(first).toEqual(second);
    expect(calls).toHaveLength(1);
  });

  it('does not cache error responses (HTTP 500 retried on next call)', async () => {
    let callCount = 0;
    const { fetch: fakeFetch } = makeFetch(async () => {
      callCount += 1;
      return { ok: false, status: 500, json: async () => ({}) } as unknown as Response;
    });
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch, minIntervalMs: 0 }));

    const first = await geocoder.search('Fehlerstraße 1');
    const second = await geocoder.search('Fehlerstraße 1');

    expect(first).toEqual([]);
    expect(second).toEqual([]);
    expect(callCount).toBe(2);
  });

  it('returns [] on HTTP 500', async () => {
    const { fetch: fakeFetch } = makeFetch(
      async () => ({ ok: false, status: 500, json: async () => ({}) }) as unknown as Response
    );
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch }));
    expect(await geocoder.search('abc def')).toEqual([]);
  });

  it('returns [] on invalid JSON', async () => {
    const { fetch: fakeFetch } = makeFetch(
      async () =>
        ({
          ok: true,
          status: 200,
          json: async () => {
            throw new Error('invalid json');
          },
        }) as unknown as Response
    );
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch }));
    expect(await geocoder.search('abc def')).toEqual([]);
  });

  it('returns [] when fetch throws', async () => {
    const fakeFetch = (async () => {
      throw new Error('network down');
    }) as unknown as typeof fetch;
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch }));
    expect(await geocoder.search('abc def')).toEqual([]);
  });

  it('returns [] when the upstream request times out (abort)', async () => {
    const fakeFetch = ((_url: string, init?: RequestInit) =>
      new Promise<Response>((_resolve, reject) => {
        const signal = init?.signal;
        signal?.addEventListener('abort', () => {
          const err = new Error('aborted');
          err.name = 'AbortError';
          reject(err);
        });
      })) as unknown as typeof fetch;
    const geocoder = new Geocoder(baseOptions({ fetch: fakeFetch, timeoutMs: 5 }));

    const results = await geocoder.search('abc def');

    expect(results).toEqual([]);
  });

  it('serializes upstream requests >=1000ms apart (global rate limit)', async () => {
    const timers = fakeTimers();
    const starts: number[] = [];
    const { fetch: fakeFetch } = makeFetch(async () => {
      starts.push(timers.now());
      return okResponse([nominatimEntry()]);
    });
    const geocoder = new Geocoder(
      baseOptions({ fetch: fakeFetch, now: timers.now, sleep: timers.sleep })
    );

    await Promise.all([geocoder.search('query one'), geocoder.search('query two')]);

    expect(starts).toHaveLength(2);
    expect(starts[1]! - starts[0]!).toBeGreaterThanOrEqual(1000);
  });

  it('gives up without calling fetch when the rate-limit wait would exceed maxWaitMs', async () => {
    const timers = fakeTimers();
    const { fetch: fakeFetch, calls } = makeFetch(async () => okResponse([nominatimEntry()]));
    const geocoder = new Geocoder(
      baseOptions({
        fetch: fakeFetch,
        now: timers.now,
        // sleep that never advances the clock: simulates the second
        // caller arriving long after the window but the *wait computed
        // at dequeue time* still exceeding maxWaitMs for a crowded queue.
        sleep: async () => {},
        minIntervalMs: 5000,
        maxWaitMs: 3000,
      })
    );

    const first = await geocoder.search('query one');
    expect(first).toEqual([
      { label: 'Hauptstr 1, Musterstadt', latitude: 48.1234, longitude: 11.5678 },
    ]);
    expect(calls).toHaveLength(1);

    // Second call starts immediately after (now() unchanged): wait would be
    // minIntervalMs (5000) > maxWaitMs (3000) -> gives up, no fetch call.
    const second = await geocoder.search('query two');
    expect(second).toEqual([]);
    expect(calls).toHaveLength(1);
  });

  it('cache hits do not consume a rate-limit slot', async () => {
    const timers = fakeTimers();
    const { fetch: fakeFetch, calls } = makeFetch(async () => okResponse([nominatimEntry()]));
    const geocoder = new Geocoder(
      baseOptions({ fetch: fakeFetch, now: timers.now, sleep: timers.sleep, minIntervalMs: 1000 })
    );

    await geocoder.search('same query');
    await geocoder.search('same query');

    expect(calls).toHaveLength(1);
  });
});
