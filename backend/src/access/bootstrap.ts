import { eq } from 'drizzle-orm';
import type { Config } from '../config.js';
import type { Db } from '../db/client.js';
import { fireDepartment, person } from '../db/schema.js';
import { hashPassword } from './passwords.js';

export interface BootstrapDeps {
  config: Config;
  db: Db;
}

/**
 * Ensures the own fire department exists and, if no administrator exists
 * yet and BOOTSTRAP_ADMIN_USERNAME/PASSWORD are configured, creates the
 * bootstrap administrator. Idempotent: safe to call on every startup.
 */
export async function ensureBootstrap(deps: BootstrapDeps): Promise<void> {
  const { config, db } = deps;

  const [existingOwn] = await db
    .select({ id: fireDepartment.id })
    .from(fireDepartment)
    .where(eq(fireDepartment.isOwn, true))
    .limit(1);

  let ownFireDepartmentId = existingOwn?.id;
  if (!ownFireDepartmentId) {
    const [created] = await db
      .insert(fireDepartment)
      .values({ name: config.OWN_FIRE_DEPARTMENT_NAME, isOwn: true })
      .returning({ id: fireDepartment.id });
    ownFireDepartmentId = created?.id;
  }

  const [existingAdmin] = await db
    .select({ id: person.id })
    .from(person)
    .where(eq(person.permission, 'admin'))
    .limit(1);

  if (!existingAdmin && config.BOOTSTRAP_ADMIN_USERNAME && config.BOOTSTRAP_ADMIN_PASSWORD) {
    if (!ownFireDepartmentId) {
      throw new Error('ensureBootstrap: own fire department is missing');
    }
    const passwordHash = await hashPassword(config.BOOTSTRAP_ADMIN_PASSWORD);
    await db.insert(person).values({
      fireDepartmentId: ownFireDepartmentId,
      displayName: 'Administrator',
      personType: 'supervisor',
      permission: 'admin',
      username: config.BOOTSTRAP_ADMIN_USERNAME,
      passwordHash,
      active: true,
    });
    console.info(
      `[bootstrap] created bootstrap administrator (username=${config.BOOTSTRAP_ADMIN_USERNAME})`
    );
  }
}
