import { eq } from 'drizzle-orm';
import { shift, crewAssignment, vehicle, person } from '../db/schema.js';
import type { Tx } from '../realtime/realtime.js';

/**
 * The standard Funktion order (ADR 0013): the well-known abbreviations in
 * this fixed order, then anything else alphabetically.
 */
const FUNCTION_ORDER = ['GF', 'MA', 'ATF', 'ATM', 'WTF', 'WTM', 'ME'];

/** Shared with `backend/src/alarms/alarm-json.ts` (ADR 0017: Empfänger-Reihenfolge). */
export function functionRank(fn: string): number {
  const idx = FUNCTION_ORDER.indexOf(fn);
  return idx === -1 ? FUNCTION_ORDER.length : idx;
}

export interface ShiftCrewMemberJson {
  vehicle_id: string;
  person_id: string;
  display_name: string;
  function: string;
}

export interface ShiftJson {
  id: string;
  bf_day_id: string;
  name: string;
  starts_at: string;
  ends_at: string;
  crew: ShiftCrewMemberJson[];
}

/**
 * Loads a Schicht with its full Besatzung, shaped and ordered per ADR 0013:
 * `crew` sorted by vehicle `sort_order`, then Funktion in the standard
 * order (others alphabetical), then `display_name`. Returns `undefined` if
 * the shift no longer exists. Shared between the participants route here
 * (T05-1) and the shift/crew routes (T05-2) so the shape never drifts.
 */
export async function loadShiftJson(tx: Tx, shiftId: string): Promise<ShiftJson | undefined> {
  const [shiftRow] = await tx.select().from(shift).where(eq(shift.id, shiftId)).limit(1);
  if (!shiftRow) return undefined;

  const rows = await tx
    .select({
      vehicleId: crewAssignment.vehicleId,
      personId: crewAssignment.personId,
      function: crewAssignment.function,
      displayName: person.displayName,
      vehicleSortOrder: vehicle.sortOrder,
    })
    .from(crewAssignment)
    .innerJoin(vehicle, eq(crewAssignment.vehicleId, vehicle.id))
    .innerJoin(person, eq(crewAssignment.personId, person.id))
    .where(eq(crewAssignment.shiftId, shiftId));

  rows.sort((a, b) => {
    if (a.vehicleSortOrder !== b.vehicleSortOrder) return a.vehicleSortOrder - b.vehicleSortOrder;
    const rankA = functionRank(a.function);
    const rankB = functionRank(b.function);
    if (rankA !== rankB) return rankA - rankB;
    if (a.function !== b.function) return a.function.localeCompare(b.function);
    return a.displayName.localeCompare(b.displayName);
  });

  return {
    id: shiftRow.id,
    bf_day_id: shiftRow.bfDayId,
    name: shiftRow.name,
    starts_at: shiftRow.startsAt.toISOString(),
    ends_at: shiftRow.endsAt.toISOString(),
    crew: rows.map(row => ({
      vehicle_id: row.vehicleId,
      person_id: row.personId,
      display_name: row.displayName,
      function: row.function,
    })),
  };
}
