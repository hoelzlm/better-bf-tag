import type { Pool } from 'pg';
import type { Config } from './config.js';
import { runMigrations, type Db } from './db/client.js';
import { ensureBootstrap } from './access/bootstrap.js';

export interface StartupDeps {
  config: Config;
  db: Db;
  pool: Pool;
}

/**
 * Runs everything needed before the app starts listening: migrations, then
 * bootstrap (own fire department + bootstrap administrator). Both
 * src/server.ts and test/support/test-app.ts call this so tests exercise
 * the exact same startup path as production.
 */
export async function prepare(deps: StartupDeps): Promise<void> {
  await runMigrations(deps.db);
  await ensureBootstrap({ config: deps.config, db: deps.db });
}
