import { and, eq, inArray, isNotNull, ne, notInArray, sql } from 'drizzle-orm';
import {
  alarm,
  alarmRecipient,
  bfDay,
  crewAssignment,
  fireDepartment,
  incident,
  pairingCode,
  participation,
  person,
  shift,
  vehicleStatusEvent,
} from '../db/schema.js';
import type { Tx } from '../realtime/realtime.js';

/** ADR 0020: the numbers the preview shows and the execution produces (same shape). */
export interface AnonymizationSummary {
  participations: number;
  crewAssignments: number;
  alarmRecipients: number;
  statusEvents: number;
  personsDeleted: number;
}

interface Scope {
  shiftIds: string[];
  alarmIds: string[];
}

async function loadScope(tx: Tx, bfDayId: string): Promise<Scope> {
  const shiftRows = await tx.select({ id: shift.id }).from(shift).where(eq(shift.bfDayId, bfDayId));
  const shiftIds = shiftRows.map(row => row.id);

  const incidentRows = await tx
    .select({ id: incident.id })
    .from(incident)
    .where(eq(incident.bfDayId, bfDayId));
  const incidentIds = incidentRows.map(row => row.id);

  let alarmIds: string[] = [];
  if (incidentIds.length > 0) {
    const alarmRows = await tx
      .select({ id: alarm.id })
      .from(alarm)
      .where(inArray(alarm.incidentId, incidentIds));
    alarmIds = alarmRows.map(row => row.id);
  }

  return { shiftIds, alarmIds };
}

/**
 * Computes what an Anonymisierung of this BF-Tag would delete/change
 * (ADR 0020), without writing anything. `anonymizeBfDay` calls this first
 * inside the same transaction and then performs exactly these changes, so
 * preview and result always agree.
 */
export async function computeAnonymization(
  tx: Tx,
  bfDayId: string,
  actorPersonId: string
): Promise<{ summary: AnonymizationSummary; personIdsToDelete: string[] }> {
  const { shiftIds, alarmIds } = await loadScope(tx, bfDayId);

  const [participationCount] = await tx
    .select({ count: sql<number>`count(*)::int` })
    .from(participation)
    .where(eq(participation.bfDayId, bfDayId));

  const [crewCount] =
    shiftIds.length > 0
      ? await tx
          .select({ count: sql<number>`count(*)::int` })
          .from(crewAssignment)
          .where(inArray(crewAssignment.shiftId, shiftIds))
      : [{ count: 0 }];

  const [alarmRecipientCount] =
    alarmIds.length > 0
      ? await tx
          .select({ count: sql<number>`count(*)::int` })
          .from(alarmRecipient)
          .where(inArray(alarmRecipient.alarmId, alarmIds))
      : [{ count: 0 }];

  const [statusEventCount] = await tx
    .select({ count: sql<number>`count(*)::int` })
    .from(vehicleStatusEvent)
    .where(and(eq(vehicleStatusEvent.bfDayId, bfDayId), isNotNull(vehicleStatusEvent.personId)));

  // Candidates (ADR 0020): persons with a Teilnahme at this day whose
  // Feuerwehr is not the own one, excluding the auslösende Person.
  const candidateRows = await tx
    .select({ id: person.id })
    .from(participation)
    .innerJoin(person, eq(participation.personId, person.id))
    .innerJoin(fireDepartment, eq(person.fireDepartmentId, fireDepartment.id))
    .where(and(eq(participation.bfDayId, bfDayId), eq(fireDepartment.isOwn, false)));
  const candidateIds = candidateRows.map(row => row.id).filter(id => id !== actorPersonId);

  const personIdsToDelete: string[] = [];
  for (const candidateId of candidateIds) {
    const [otherParticipation] = await tx
      .select({ bfDayId: participation.bfDayId })
      .from(participation)
      .where(and(eq(participation.personId, candidateId), ne(participation.bfDayId, bfDayId)))
      .limit(1);
    if (otherParticipation) continue;

    const crewWhere =
      shiftIds.length > 0
        ? and(
            eq(crewAssignment.personId, candidateId),
            notInArray(crewAssignment.shiftId, shiftIds)
          )
        : eq(crewAssignment.personId, candidateId);
    const [otherCrew] = await tx
      .select({ shiftId: crewAssignment.shiftId })
      .from(crewAssignment)
      .where(crewWhere)
      .limit(1);
    if (otherCrew) continue;

    const alarmRecipientWhere =
      alarmIds.length > 0
        ? and(
            eq(alarmRecipient.personId, candidateId),
            notInArray(alarmRecipient.alarmId, alarmIds)
          )
        : eq(alarmRecipient.personId, candidateId);
    const [otherAlarmRecipient] = await tx
      .select({ alarmId: alarmRecipient.alarmId })
      .from(alarmRecipient)
      .where(alarmRecipientWhere)
      .limit(1);
    if (otherAlarmRecipient) continue;

    personIdsToDelete.push(candidateId);
  }

  return {
    summary: {
      participations: Number(participationCount?.count ?? 0),
      crewAssignments: Number(crewCount?.count ?? 0),
      alarmRecipients: Number(alarmRecipientCount?.count ?? 0),
      statusEvents: Number(statusEventCount?.count ?? 0),
      personsDeleted: personIdsToDelete.length,
    },
    personIdsToDelete,
  };
}

/**
 * Performs the Anonymisierung (ADR 0020): deletes the Personenbezug of
 * this BF-Tag's Teilnahmen/Besatzungen/Empfänger, clears `person_id` on
 * its Statushistorie, deletes persons of other Feuerwehren that no longer
 * have any Teilnahme/Besatzung/Empfänger anywhere, and sets
 * `bf_day.anonymized_at`. Caller must already hold a lock on the bf_day
 * row (`SELECT … FOR UPDATE`) and have checked state/anonymized_at.
 */
export async function anonymizeBfDay(
  tx: Tx,
  bfDayId: string,
  actorPersonId: string,
  now: Date
): Promise<AnonymizationSummary> {
  const { shiftIds, alarmIds } = await loadScope(tx, bfDayId);
  const { summary, personIdsToDelete } = await computeAnonymization(tx, bfDayId, actorPersonId);

  if (alarmIds.length > 0) {
    await tx.delete(alarmRecipient).where(inArray(alarmRecipient.alarmId, alarmIds));
  }
  if (shiftIds.length > 0) {
    await tx.delete(crewAssignment).where(inArray(crewAssignment.shiftId, shiftIds));
  }
  await tx.delete(participation).where(eq(participation.bfDayId, bfDayId));

  await tx
    .update(vehicleStatusEvent)
    .set({ personId: null })
    .where(eq(vehicleStatusEvent.bfDayId, bfDayId));

  if (personIdsToDelete.length > 0) {
    // device/web_session cascade, vehicle_status_event.person_id is
    // already null above (and would set null on delete anyway).
    await tx
      .delete(pairingCode)
      .where(
        and(eq(pairingCode.targetType, 'person'), inArray(pairingCode.targetId, personIdsToDelete))
      );
    await tx.delete(person).where(inArray(person.id, personIdsToDelete));
  }

  await tx.update(bfDay).set({ anonymizedAt: now }).where(eq(bfDay.id, bfDayId));

  return summary;
}
