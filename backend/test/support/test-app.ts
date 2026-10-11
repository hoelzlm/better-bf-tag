import { randomBytes } from 'node:crypto';
import { Pool } from 'pg';
import { inject } from 'vitest';
import type { FastifyInstance } from 'fastify';

import { buildApp, type AppDeps } from '../../src/app.js';
import { loadConfig, type Config } from '../../src/config.js';
import { createDb, type Db } from '../../src/db/client.js';
import { prepare } from '../../src/startup.js';
import type { Geocoder } from '../../src/geocoding/geocoder.js';
import { FakeClock } from './fake-clock.js';
import { RecordingPushSender } from './recording-push-sender.js';
import { ManualTimerRegistry } from './manual-timer.js';
import { HttpClient } from './http-client.js';

export interface TestAppOptions {
  config?: Partial<Config>;
  /** Reuse an existing test database to simulate a server restart. */
  databaseUrl?: string;
  /** ADR 0026: inject a fake Geocoder instead of the real-fetch default. */
  geocoder?: Geocoder;
}

export interface TestApp {
  baseUrl: string;
  databaseUrl: string;
  clock: FakeClock;
  push: RecordingPushSender;
  /** Fires pending Testalarm-Scheduler timers deterministically (ADR 0021). */
  testAlarmTimer: ManualTimerRegistry;
  client(): HttpClient;
  /** Runs the app's `AlarmScheduler.runDue()` directly (ADR 0022), bypassing
   * the real-time interval timer (disabled by default in tests). */
  runScheduler(): Promise<{ triggered: string[]; missed: string[] }>;
  restart(config?: Partial<Config>): Promise<TestApp>;
  close(): Promise<void>;
}

function buildTestConfig(databaseUrl: string, overrides?: Partial<Config>): Config {
  const base = loadConfig({
    DATABASE_URL: databaseUrl,
    JWT_SECRET: 'test-jwt-secret-at-least-32-characters-long',
    BOOTSTRAP_ADMIN_USERNAME: 'admin',
    BOOTSTRAP_ADMIN_PASSWORD: 'admin-password',
    AUTH_RATE_LIMIT_MAX: '1000',
    // ADR 0022: tests drive the AlarmScheduler explicitly via
    // `TestApp.runScheduler()`; the real-time interval timer would just
    // make test timing nondeterministic.
    ALARM_SCHEDULER_INTERVAL_MS: '0',
    // ADR 0026: no real network in tests ever; route tests that need
    // geocode results inject a fake Geocoder via `TestAppOptions.geocoder`
    // instead of enabling this.
    GEOCODING_ENABLED: 'false',
  });
  return { ...base, ...overrides };
}

async function createFreshDatabase(): Promise<string> {
  const adminUrl = inject('pgAdminUrl');
  const name = `test_${randomBytes(6).toString('hex')}`;

  const adminPool = new Pool({ connectionString: adminUrl });
  try {
    await adminPool.query(`CREATE DATABASE ${name}`);
  } finally {
    await adminPool.end();
  }

  const url = new URL(adminUrl);
  url.pathname = `/${name}`;
  return url.toString();
}

async function start(
  databaseUrl: string,
  config: Config,
  existingClock?: FakeClock,
  geocoder?: Geocoder
): Promise<TestApp> {
  const { db, pool } = createDb(databaseUrl);
  await prepare({ config, db: db as Db, pool });

  const clock = existingClock ?? new FakeClock();
  const push = new RecordingPushSender();
  const testAlarmTimer = new ManualTimerRegistry();

  const deps: AppDeps = {
    config,
    db: db as Db,
    pool,
    clock,
    pushSender: push,
    testAlarmTimer: {
      setTimer: testAlarmTimer.setTimer,
      clearTimer: testAlarmTimer.clearTimer,
    },
    ...(geocoder ? { geocoder } : {}),
  };

  const app: FastifyInstance = await buildApp(deps);
  await app.listen({ port: 0, host: '127.0.0.1' });

  const address = app.server.address();
  const port = typeof address === 'object' && address !== null ? address.port : 0;
  const baseUrl = `http://127.0.0.1:${port}`;

  let closed = false;

  return {
    baseUrl,
    databaseUrl,
    clock,
    push,
    testAlarmTimer,
    client(): HttpClient {
      return new HttpClient(baseUrl);
    },
    runScheduler(): Promise<{ triggered: string[]; missed: string[] }> {
      return app.alarmScheduler.runDue();
    },
    async restart(configOverrides?: Partial<Config>): Promise<TestApp> {
      if (!closed) {
        closed = true;
        await app.close();
        await pool.end();
      }
      // ADR 0022 (T11-2): reuse the same `FakeClock` instance so a test
      // can advance it before `restart()` and have the new app's startup
      // catch-up (`onReady` -> `alarmScheduler.start()` -> one `runDue()`)
      // observe that advanced time, not a clock reset to "now".
      return start(databaseUrl, { ...config, ...configOverrides }, clock, geocoder);
    },
    async close(): Promise<void> {
      if (closed) return;
      closed = true;
      await app.close();
      await pool.end();
    },
  };
}

export async function startTestApp(opts: TestAppOptions = {}): Promise<TestApp> {
  const databaseUrl = opts.databaseUrl ?? (await createFreshDatabase());
  const config = buildTestConfig(databaseUrl, opts.config);
  return start(databaseUrl, config, undefined, opts.geocoder);
}

export { HttpClient } from './http-client.js';
