import { and, eq, isNull } from 'drizzle-orm';
import { webSession, device } from '../db/schema.js';
import type { Tx } from '../realtime/realtime.js';

/**
 * Revokes every still-active web session of a person. Called when a person
 * is deactivated or loses/changes their Web-Zugang (ADR 0010). When
 * `revokeDevices` is set (deactivation only — a permission downgrade to
 * crew keeps the mobile app usable), also revokes every still-active
 * device of the person; the caller is responsible for calling
 * `app.wsHub.revokePerson(personId)` after the transaction commits.
 */
export async function deactivatePersonSessions(
  tx: Tx,
  personId: string,
  now: Date,
  opts?: { revokeDevices?: boolean }
): Promise<void> {
  await tx
    .update(webSession)
    .set({ revokedAt: now })
    .where(and(eq(webSession.personId, personId), isNull(webSession.revokedAt)));

  if (opts?.revokeDevices) {
    await tx
      .update(device)
      .set({ revokedAt: now })
      .where(and(eq(device.personId, personId), isNull(device.revokedAt)));
  }
}
