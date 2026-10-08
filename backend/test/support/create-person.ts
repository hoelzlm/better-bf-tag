import { Pool } from 'pg';
import { hashPassword } from '../../src/access/passwords.js';
import { signAccessToken } from '../../src/access/tokens.js';
import { loadConfig } from '../../src/config.js';
import type { Permission, PersonType } from '../../src/access/types.js';
import type { TestApp } from './test-app.js';

export interface CreatePersonOptions {
  displayName: string;
  personType: PersonType;
  permission: Permission;
  username: string;
  password: string;
}

/**
 * Inserts a Person directly via SQL (allowed exception per ADR 0008 / test
 * README: there is no API yet to create Personen with arbitrary
 * Berechtigung). Returns the new person's id. Call `login()` afterwards to
 * get a bearer token through the real /auth/login endpoint.
 */
export async function createPerson(
  app: TestApp,
  opts: CreatePersonOptions
): Promise<{ id: string }> {
  const pool = new Pool({ connectionString: app.databaseUrl });
  try {
    const passwordHash = await hashPassword(opts.password);
    const result = await pool.query<{ id: string }>(
      `insert into person (fire_department_id, display_name, person_type, permission, username, password_hash, active)
       select fd.id, $1, $2, $3, $4, $5, true from fire_department fd where fd.is_own = true limit 1
       returning id`,
      [opts.displayName, opts.personType, opts.permission, opts.username, passwordHash]
    );
    const row = result.rows[0];
    if (!row) {
      throw new Error('createPerson: insert returned no row (no own fire department?)');
    }
    return row;
  } finally {
    await pool.end();
  }
}

/** Logs in via the real /auth/login endpoint and returns the access token. */
export async function loginAs(app: TestApp, username: string, password: string): Promise<string> {
  const res = await app.client().post('/api/v1/auth/login', { username, password });
  if (res.status !== 200) {
    throw new Error(`loginAs(${username}): login failed with status ${res.status}`);
  }
  return (res.body as { access_token: string }).access_token;
}

/**
 * Signs an access token directly, bypassing `/auth/login`. Needed because
 * ADR 0010 forbids web login entirely for permission=crew — there is no
 * HTTP path to obtain a bearer token for a crew Person (device/mobile auth
 * lands in T04-2). `requireAuth` reloads the actual permission from the DB
 * on every request, so the `permission` claim here only has to be well
 * formed, not correct; it is never trusted.
 */
export function signTestAccessToken(
  app: TestApp,
  personId: string,
  permission: Permission = 'crew'
): Promise<string> {
  const config = loadConfig({
    DATABASE_URL: app.databaseUrl,
    JWT_SECRET: 'test-jwt-secret-at-least-32-characters-long',
  });
  return signAccessToken({ config, clock: app.clock }, { id: personId, permission });
}
