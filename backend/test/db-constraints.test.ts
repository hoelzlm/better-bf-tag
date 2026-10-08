import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';

/**
 * Allowed black-box exception per ADR 0008: these constraints are not (yet)
 * reachable through the API, so we assert on them directly via SQL against
 * a freshly migrated test database.
 */
describe('database constraints', () => {
  let app: TestApp;
  let pool: Pool;
  let fireDepartmentId: string;

  beforeAll(async () => {
    app = await startTestApp();
    pool = new Pool({ connectionString: app.databaseUrl });
    const result = await pool.query<{ id: string }>(
      `insert into fire_department (name, is_own) values ($1, true) returning id`,
      ['Test-Feuerwehr']
    );
    fireDepartmentId = result.rows[0]!.id;
  });

  afterAll(async () => {
    await pool.end();
    await app.close();
  });

  it('rejects permission=admin with person_type=youth', async () => {
    await expect(
      pool.query(
        `insert into person (fire_department_id, display_name, person_type, permission, active)
         values ($1, $2, 'youth', 'admin', true)`,
        [fireDepartmentId, 'Jugend-Admin']
      )
    ).rejects.toMatchObject({ code: '23514' });
  });

  it('allows permission=admin with person_type=supervisor', async () => {
    await expect(
      pool.query(
        `insert into person (fire_department_id, display_name, person_type, permission, active)
         values ($1, $2, 'supervisor', 'admin', true)`,
        [fireDepartmentId, 'Betreuer-Admin']
      )
    ).resolves.toBeDefined();
  });

  it('allows permission=dispatch with person_type=youth', async () => {
    await expect(
      pool.query(
        `insert into person (fire_department_id, display_name, person_type, permission, active)
         values ($1, $2, 'youth', 'dispatch', true)`,
        [fireDepartmentId, 'Jugend-Disponent']
      )
    ).resolves.toBeDefined();
  });
});
