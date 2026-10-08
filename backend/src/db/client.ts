import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';
import { drizzle, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';

export type Db = NodePgDatabase<Record<string, unknown>>;

export function createDb(databaseUrl: string): { db: Db; pool: Pool } {
  const pool = new Pool({ connectionString: databaseUrl });
  const db = drizzle(pool, { casing: 'snake_case' });
  return { db, pool };
}

export async function runMigrations(db: Db): Promise<void> {
  const migrationsFolder = resolveMigrationsFolder();
  await migrate(db, { migrationsFolder });
}

function resolveMigrationsFolder(): string {
  // Resolve the path relative to this package, so it works from both
  // src/db/client.ts (via tsx) and dist/db/client.js (compiled).
  // In both cases this file lives two levels below the backend package
  // root (src/db or dist/db), where the sibling `drizzle/` folder is.
  const __dirname = path.dirname(fileURLToPath(import.meta.url));
  return path.resolve(__dirname, '..', '..', 'drizzle');
}
