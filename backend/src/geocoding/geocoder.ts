/**
 * Geocoding-Proxy (ADR 0026 „Geocoding“). One instance per app
 * (`fastify.geocoder`) so the rate limit and cache are global. `search()`
 * never throws — every failure (disabled, rate-limit wait too long,
 * timeout, HTTP error, invalid JSON) resolves to `[]`.
 */

export interface GeocodeResult {
  label: string;
  latitude: number;
  longitude: number;
}

export interface GeocoderOptions {
  enabled: boolean;
  baseUrl: string;
  contact?: string;
  countryCodes: string;
  /** Injectable for tests; defaults to the global `fetch`. */
  fetch?: typeof fetch;
  /** Injectable clock (ms since epoch); defaults to `Date.now`. */
  now?: () => number;
  /** Injectable delay; defaults to a real `setTimeout`-based sleep. */
  sleep?: (ms: number) => Promise<void>;
  /** Minimum ms between two upstream request *starts* (default 1000). */
  minIntervalMs?: number;
  /** Give up (without calling upstream) if the wait for a slot would exceed this (default 3000). */
  maxWaitMs?: number;
  /** Upstream request timeout via `AbortController` (default 5000). */
  timeoutMs?: number;
  /** Cache TTL per entry (default 24h). */
  cacheTtlMs?: number;
  /** Max cache entries; oldest evicted first (default 500). */
  cacheMax?: number;
}

interface CacheEntry {
  results: GeocodeResult[];
  expiresAt: number;
}

type RateLimitOutcome = { ok: true; results: GeocodeResult[] } | { ok: false };

const USER_AGENT_PREFIX = 'better-bf-tag/1.0 (+https://github.com/hoelzlm/better-bf-tag';

function normalizeKey(q: string): string {
  return q.trim().toLowerCase().replace(/\s+/g, ' ');
}

function defaultSleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function mapUpstreamResults(data: unknown): GeocodeResult[] {
  if (!Array.isArray(data)) return [];
  const results: GeocodeResult[] = [];
  for (const entry of data) {
    if (typeof entry !== 'object' || entry === null) continue;
    const record = entry as Record<string, unknown>;
    const label = record['display_name'];
    const latitude = Number(record['lat']);
    const longitude = Number(record['lon']);
    if (typeof label !== 'string' || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      continue;
    }
    results.push({ label, latitude, longitude });
  }
  return results.slice(0, 5);
}

export class Geocoder {
  private readonly enabled: boolean;
  private readonly baseUrl: string;
  private readonly contact: string | undefined;
  private readonly countryCodes: string;
  private readonly fetchFn: typeof fetch;
  private readonly now: () => number;
  private readonly sleep: (ms: number) => Promise<void>;
  private readonly minIntervalMs: number;
  private readonly maxWaitMs: number;
  private readonly timeoutMs: number;
  private readonly cacheTtlMs: number;
  private readonly cacheMax: number;

  private readonly cache = new Map<string, CacheEntry>();
  private lastRequestStart = -Infinity;
  private queueTail: Promise<unknown> = Promise.resolve();

  constructor(opts: GeocoderOptions) {
    this.enabled = opts.enabled;
    this.baseUrl = opts.baseUrl;
    this.contact = opts.contact;
    this.countryCodes = opts.countryCodes;
    this.fetchFn = opts.fetch ?? fetch;
    this.now = opts.now ?? Date.now;
    this.sleep = opts.sleep ?? defaultSleep;
    this.minIntervalMs = opts.minIntervalMs ?? 1000;
    this.maxWaitMs = opts.maxWaitMs ?? 3000;
    this.timeoutMs = opts.timeoutMs ?? 5000;
    this.cacheTtlMs = opts.cacheTtlMs ?? 24 * 60 * 60 * 1000;
    this.cacheMax = opts.cacheMax ?? 500;
  }

  async search(q: string): Promise<GeocodeResult[]> {
    if (!this.enabled) return [];
    const trimmed = q.trim();
    const key = normalizeKey(trimmed);

    const cached = this.cacheGet(key);
    if (cached !== undefined) return cached;

    let outcome: RateLimitOutcome;
    try {
      outcome = await this.withRateLimit(() => this.fetchUpstream(trimmed));
    } catch {
      return [];
    }
    if (!outcome.ok) return [];

    this.cacheSet(key, outcome.results);
    return outcome.results;
  }

  private cacheGet(key: string): GeocodeResult[] | undefined {
    const entry = this.cache.get(key);
    if (!entry) return undefined;
    if (entry.expiresAt <= this.now()) {
      this.cache.delete(key);
      return undefined;
    }
    return entry.results;
  }

  private cacheSet(key: string, results: GeocodeResult[]): void {
    this.cache.delete(key);
    this.cache.set(key, { results, expiresAt: this.now() + this.cacheTtlMs });
    while (this.cache.size > this.cacheMax) {
      const oldestKey = this.cache.keys().next().value as string | undefined;
      if (oldestKey === undefined) break;
      this.cache.delete(oldestKey);
    }
  }

  /**
   * Serializes upstream requests through a single queue so slots are
   * global: each call's wait is computed against the last *actual*
   * request start. If the wait would exceed `maxWaitMs`, the slot is not
   * consumed (`lastRequestStart` stays untouched) and the caller gets
   * `{ ok: false }` without the upstream `fn` ever running.
   */
  private withRateLimit(fn: () => Promise<GeocodeResult[]>): Promise<RateLimitOutcome> {
    const task = this.queueTail.then(async (): Promise<RateLimitOutcome> => {
      const wait = Math.max(0, this.lastRequestStart + this.minIntervalMs - this.now());
      if (wait > this.maxWaitMs) {
        return { ok: false };
      }
      if (wait > 0) {
        await this.sleep(wait);
      }
      this.lastRequestStart = this.now();
      const results = await fn();
      return { ok: true, results };
    });
    // Keep the queue alive regardless of outcome/error so later callers
    // aren't stuck behind a rejected task.
    this.queueTail = task.catch(() => undefined);
    return task;
  }

  private buildUrl(q: string): string {
    const url = new URL('/search', this.baseUrl);
    url.searchParams.set('q', q);
    url.searchParams.set('format', 'jsonv2');
    url.searchParams.set('limit', '5');
    url.searchParams.set('accept-language', 'de');
    if (this.countryCodes) {
      url.searchParams.set('countrycodes', this.countryCodes);
    }
    if (this.contact) {
      url.searchParams.set('email', this.contact);
    }
    return url.toString();
  }

  private buildUserAgent(): string {
    return this.contact ? `${USER_AGENT_PREFIX}; ${this.contact})` : `${USER_AGENT_PREFIX})`;
  }

  private async fetchUpstream(q: string): Promise<GeocodeResult[]> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await this.fetchFn(this.buildUrl(q), {
        headers: { 'User-Agent': this.buildUserAgent() },
        signal: controller.signal,
      });
      if (!response.ok) {
        // Treated as a failure (ADR 0026: "Fehler" are not cached), not as
        // an empty-but-successful result.
        throw new Error(`geocoding upstream returned HTTP ${response.status}`);
      }
      const data: unknown = await response.json();
      return mapUpstreamResults(data);
    } finally {
      clearTimeout(timer);
    }
  }
}
