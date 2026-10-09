import { randomBytes } from 'node:crypto';
import { Pool } from 'pg';
import { inject } from 'vitest';
import type { FastifyInstance } from 'fastify';

import { buildApp, type AppDeps } from '../../src/app.js';
import { loadConfig, type Config } from '../../src/config.js';
import { createDb, type Db } from '../../src/db/client.js';
import { prepare } from '../../src/startup.js';
import { FakeClock } from './fake-clock.js';
import { RecordingPushSender } from './recording-push-sender.js';
import { ManualTimerRegistry } from './manual-timer.js';
import { HttpClient } from './http-client.js';

export interface TestAppOptions {
  config?: Partial<Config>;
  /** Reuse an existing test database to simulate a server restart. */
  databaseUrl?: string;
}

export interface TestApp {
  baseUrl: string;
  databaseUrl: string;
  clock: FakeClock;
  push: RecordingPushSender;
  /** Fires pending Testalarm-Scheduler timers deterministically (ADR 0021). */
  testAlarmTimer: ManualTimerRegistry;
  client(): HttpClient;
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

async function start(databaseUrl: string, config: Config): Promise<TestApp> {
  const { db, pool } = createDb(databaseUrl);
  await prepare({ config, db: db as Db, pool });

  const clock = new FakeClock();
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
    async restart(configOverrides?: Partial<Config>): Promise<TestApp> {
      if (!closed) {
        closed = true;
        await app.close();
        await pool.end();
      }
      return start(databaseUrl, { ...config, ...configOverrides });
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
  return start(databaseUrl, config);
}

export { HttpClient } from './http-client.js';
