import { eq } from 'drizzle-orm';
import { crewAssignment } from '../db/schema.js';
import type { Tx } from '../realtime/realtime.js';
import type { Viewer } from '../realtime/realtime.js';

/**
 * Whether the given Viewer may see an Durchsage (ADR 0024): visible to
 * everyone when `shift_id` is null; otherwise visible to Monitore and to
 * `preparation`/`dispatch`/`admin`, plus any Person with a `crew_assignment`
 * in that Schicht (regardless of Fahrzeug/Funktion).
 */
export function announcementVisibleTo(
  viewer: Viewer,
  announcement: { shiftId: string | null },
  crewPersonIds: ReadonlySet<string>
): boolean {
  if (announcement.shiftId === null) return true;
  if (viewer.kind === 'monitor') return true;
  if (
    viewer.permission === 'preparation' ||
    viewer.permission === 'dispatch' ||
    viewer.permission === 'admin'
  ) {
    return true;
  }
  return crewPersonIds.has(viewer.personId);
}

/** Loads every `personId` with a `crew_assignment` in the given Schicht. */
export async function loadShiftCrewPersonIds(tx: Tx, shiftId: string): Promise<Set<string>> {
  const rows = await tx
    .select({ personId: crewAssignment.personId })
    .from(crewAssignment)
    .where(eq(crewAssignment.shiftId, shiftId));
  return new Set(rows.map(row => row.personId));
}
