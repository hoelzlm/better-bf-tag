import { and, asc, eq } from 'drizzle-orm';
import { bfDay, shift, crewAssignment, vehicle } from '../db/schema.js';
import type { Db } from '../db/client.js';
import type { Tx } from '../realtime/realtime.js';
import { currentShift } from './current-shift.js';

export interface CurrentCrewAssignment {
  shiftId: string;
  vehicleId: string;
  personId: string;
  function: string;
}

/**
 * Besatzung (ADR 0015): eine Person gehört zur Besatzung eines Fahrzeugs
 * genau dann, wenn es einen laufenden BF-Tag gibt, dessen aktuelle Schicht
 * (ADR 0013, `currentShift`) eine `crew_assignment` für dieses Fahrzeug und
 * diese Person enthält. Ohne laufenden BF-Tag oder ohne aktuelle Schicht:
 * leere Liste. Ergebnis ist nach Fahrzeug-`sort_order` sortiert. Genutzt
 * von `/me` und der Statusprüfung auf `PUT /vehicles/{id}/status`.
 */
export async function loadCurrentCrewAssignments(
  db: Db | Tx,
  now: Date,
  personId?: string
): Promise<CurrentCrewAssignment[]> {
  const [runningBfDay] = await db
    .select({ id: bfDay.id })
    .from(bfDay)
    .where(eq(bfDay.state, 'running'))
    .limit(1);
  if (!runningBfDay) return [];

  const shiftRows = await db
    .select({ id: shift.id, startsAt: shift.startsAt, endsAt: shift.endsAt })
    .from(shift)
    .where(eq(shift.bfDayId, runningBfDay.id));

  const current = currentShift(shiftRows, now);
  if (!current) return [];

  const rows = await db
    .select({
      shiftId: crewAssignment.shiftId,
      vehicleId: crewAssignment.vehicleId,
      personId: crewAssignment.personId,
      function: crewAssignment.function,
      vehicleSortOrder: vehicle.sortOrder,
    })
    .from(crewAssignment)
    .innerJoin(vehicle, eq(crewAssignment.vehicleId, vehicle.id))
    .where(
      personId !== undefined
        ? and(eq(crewAssignment.shiftId, current.id), eq(crewAssignment.personId, personId))
        : eq(crewAssignment.shiftId, current.id)
    )
    .orderBy(asc(vehicle.sortOrder));

  return rows.map(row => ({
    shiftId: row.shiftId,
    vehicleId: row.vehicleId,
    personId: row.personId,
    function: row.function,
  }));
}
