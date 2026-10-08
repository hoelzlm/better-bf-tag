import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';

import { loadConfig } from '../src/config.js';
import { buildApp, type AppDeps } from '../src/app.js';
import { systemClock } from '../src/clock.js';
import { noopPushSender } from '../src/push/push-sender.js';
import type { Db } from '../src/db/client.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OPENAPI_JSON_PATH = path.resolve(__dirname, '..', 'openapi.json');

/**
 * Builds the app with a dummy config and a pg Pool that is never connected
 * (pg Pools are lazy — they only dial out on the first query, and this
 * script never queries), then returns `app.swagger()` as pretty JSON with a
 * trailing newline.
 */
export async function generateOpenApiJson(): Promise<string> {
  const config = loadConfig({
    DATABASE_URL: 'postgres://user:pass@localhost:5432/not_connected',
    JWT_SECRET: 'openapi-generation-dummy-secret-not-used-00000',
  });

  const pool = new Pool({ connectionString: config.DATABASE_URL });
  const db = drizzle(pool, { casing: 'snake_case' }) as Db;

  const deps: AppDeps = {
    config,
    db,
    pool,
    clock: systemClock,
    pushSender: noopPushSender,
  };

  const app = await buildApp(deps);
  await app.ready();

  const spec = app.swagger();
  const json = `${JSON.stringify(spec, null, 2)}\n`;

  await app.close();
  await pool.end();

  return json;
}

async function main(): Promise<void> {
  const check = process.argv.includes('--check');
  const generated = await generateOpenApiJson();

  if (!check) {
    writeFileSync(OPENAPI_JSON_PATH, generated);
    console.log(`Wrote ${OPENAPI_JSON_PATH}`);
    return;
  }

  let committed: string;
  try {
    committed = readFileSync(OPENAPI_JSON_PATH, 'utf8');
  } catch {
    console.error(`Missing ${OPENAPI_JSON_PATH}. Run \`npm run openapi\` first.`);
    process.exit(1);
    return;
  }

  if (generated !== committed) {
    console.error(
      'backend/openapi.json is out of date. Run `npm run openapi` and commit the result.'
    );
    process.exit(1);
    return;
  }

  console.log('backend/openapi.json is up to date.');
}

main();
