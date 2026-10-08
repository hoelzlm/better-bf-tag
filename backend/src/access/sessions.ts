import { and, eq, isNull } from 'drizzle-orm';
import { webSession } from '../db/schema.js';
import type { Tx } from '../realtime/realtime.js';

/**
 * Revokes every still-active web session of a person. Called when a person
 * is deactivated or loses/changes their Web-Zugang (ADR 0010). T04-2 will
 * extend this same function to also revoke the person's devices.
 */
export async function deactivatePersonSessions(tx: Tx, personId: string, now: Date): Promise<void> {
  await tx
    .update(webSession)
    .set({ revokedAt: now })
    .where(and(eq(webSession.personId, personId), isNull(webSession.revokedAt)));
}
