import { and, eq, inArray, isNull } from 'drizzle-orm';
import { alarm, alarmVehicle, alarmRecipient, device, person, incident } from '../db/schema.js';
import type { Tx, Emit } from '../realtime/realtime.js';
import type { Clock } from '../clock.js';
import type { PushSender } from '../push/push-sender.js';
import { toIncidentJson, type IncidentRow } from '../incidents/incident-json.js';
import { scriptAudience } from '../incidents/visibility.js';
import { incidentUpdatedEventOpts } from '../incidents/incident-events.js';
import { loadCurrentCrewAssignments } from '../shifts/current-crew.js';
import { emitCloseSuggestionChanges } from '../incidents/close-suggestion.js';
import { loadAlarms, type AlarmJson, type AlarmRow } from './alarm-json.js';
import type { DoubleCrewedJson } from '../routes/alarm-schemas.js';

interface Logger {
  warn: (obj: Record<string, unknown>, msg: string) => void;
}

export interface TriggerAlarmDeps {
  clock: Clock;
  pushSender: PushSender;
  log?: Logger;
}

async function loadIncidentRow(tx: Tx, id: string): Promise<IncidentRow | undefined> {
  const [row] = await tx.select().from(incident).where(eq(incident.id, id)).limit(1);
  return row as IncidentRow | undefined;
}

async function loadVehicleIdsForAlarm(tx: Tx, alarmId: string): Promise<string[]> {
  const rows = await tx
    .select({ vehicleId: alarmVehicle.vehicleId })
    .from(alarmVehicle)
    .where(eq(alarmVehicle.alarmId, alarmId));
  return rows.map(row => row.vehicleId);
}

/**
 * The single shared Auslöse-Pfad (ADR 0022), used by immediate alarming,
 * the `AlarmScheduler` (Ticket 11-2) and manual `POST /alarms/{id}/trigger`
 * (Ticket 11-2): takes an EXISTING alarm row (just-inserted, `planned` or
 * `missed`) and does the Erstalarm/Nachalarmierung state transition,
 * freezes recipients (ADR 0017/0019, deduped against earlier `triggered`
 * alarms of the incident), flips the alarm to `triggered`, emits
 * `alarm.triggered`, diffs the Abschlussvorschlag (ADR 0019) and
 * recomputes relative dependents (ADR 0022). Does NOT send push itself —
 * that happens strictly after the enclosing `realtime.mutate` commits (see
 * `dispatchAlarmPushes`); `deps.pushSender`/`deps.log` are accepted so
 * callers can pass one bundled deps object through to both.
 */
export async function triggerAlarm(
  tx: Tx,
  emit: Emit,
  deps: TriggerAlarmDeps,
  alarmId: string,
  closeSuggestedBefore: Set<string>
): Promise<{ alarm: AlarmJson; doubleCrewed: DoubleCrewedJson[] }> {
  const now = deps.clock.now();

  const [alarmRow] = await tx.select().from(alarm).where(eq(alarm.id, alarmId)).limit(1);
  if (!alarmRow) {
    throw new Error(`triggerAlarm: alarm ${alarmId} not found`);
  }
  const typedAlarmRow = alarmRow as AlarmRow;

  const incidentRow = await loadIncidentRow(tx, typedAlarmRow.incidentId);
  if (!incidentRow) {
    throw new Error(`triggerAlarm: incident for alarm ${alarmId} not found`);
  }

  let runningIncident: IncidentRow = incidentRow;
  let incidentJustStarted = false;
  if (incidentRow.state === 'draft') {
    const [updatedIncident] = await tx
      .update(incident)
      .set({ state: 'running', updatedAt: now })
      .where(and(eq(incident.id, incidentRow.id), eq(incident.state, 'draft')))
      .returning();
    if (updatedIncident) {
      runningIncident = updatedIncident as IncidentRow;
      incidentJustStarted = true;
    }
  }

  const vehicleIds = await loadVehicleIdsForAlarm(tx, typedAlarmRow.id);
  const vehicleIdSet = new Set(vehicleIds);

  // Empfänger einfrieren (ADR 0017): Besatzung der aktuellen Schicht,
  // gefiltert auf die alarmierten Fahrzeuge, pro Person dedupliziert.
  // ADR 0019: Personen, die bereits Empfänger einer `triggered`
  // Alarmierung dieses Einsatzes sind, werden ausgelassen.
  const alreadyRecipientRows = await tx
    .select({ personId: alarmRecipient.personId })
    .from(alarmRecipient)
    .innerJoin(alarm, eq(alarmRecipient.alarmId, alarm.id))
    .where(and(eq(alarm.incidentId, incidentRow.id), eq(alarm.state, 'triggered')));
  const alreadyRecipientPersonIds = new Set(alreadyRecipientRows.map(r => r.personId));

  const crew = await loadCurrentCrewAssignments(tx, now);
  const alarmedCrew = crew.filter(
    c => vehicleIdSet.has(c.vehicleId) && !alreadyRecipientPersonIds.has(c.personId)
  );

  const vehicleIdsByPerson = new Map<string, string[]>();
  const firstAssignmentByPerson = new Map<string, { vehicleId: string; function: string }>();
  for (const c of alarmedCrew) {
    if (!firstAssignmentByPerson.has(c.personId)) {
      firstAssignmentByPerson.set(c.personId, { vehicleId: c.vehicleId, function: c.function });
    }
    const list = vehicleIdsByPerson.get(c.personId) ?? [];
    if (!list.includes(c.vehicleId)) list.push(c.vehicleId);
    vehicleIdsByPerson.set(c.personId, list);
  }

  const personIds = [...firstAssignmentByPerson.keys()];
  const devicePersonIds =
    personIds.length > 0
      ? await tx
          .select({ personId: device.personId })
          .from(device)
          .where(and(inArray(device.personId, personIds), isNull(device.revokedAt)))
      : [];
  const hasDeviceSet = new Set(devicePersonIds.map(row => row.personId));

  for (const [personId, assignment] of firstAssignmentByPerson) {
    await tx.insert(alarmRecipient).values({
      alarmId: typedAlarmRow.id,
      personId,
      vehicleId: assignment.vehicleId,
      function: assignment.function,
      hasDevice: hasDeviceSet.has(personId),
      acknowledgedAt: null,
      createdAt: now,
    });
  }

  const doubleCrewedPersonIds = personIds.filter(
    id => (vehicleIdsByPerson.get(id) ?? []).length > 1
  );
  let doubleCrewed: DoubleCrewedJson[] = [];
  if (doubleCrewedPersonIds.length > 0) {
    const personRows = await tx
      .select({ id: person.id, displayName: person.displayName })
      .from(person)
      .where(inArray(person.id, doubleCrewedPersonIds));
    const nameById = new Map(personRows.map(row => [row.id, row.displayName]));
    doubleCrewed = doubleCrewedPersonIds.map(id => ({
      person_id: id,
      display_name: nameById.get(id) ?? '',
      vehicle_ids: vehicleIdsByPerson.get(id) ?? [],
    }));
  }

  await tx
    .update(alarm)
    .set({ state: 'triggered', triggeredAt: now })
    .where(eq(alarm.id, typedAlarmRow.id));

  // ADR 0019: Nachalarmierungen (running -> running) lösen kein
  // `incident.updated` aus — nur der Erstalarm (draft -> running).
  if (incidentJustStarted) {
    await emit('incident.updated', null, incidentUpdatedEventOpts(runningIncident));
  }

  const [alarmJson] = await loadAlarms(tx, { alarmIds: [typedAlarmRow.id] });
  if (!alarmJson) {
    throw new Error('triggerAlarm: triggered alarm disappeared');
  }
  await emit('alarm.triggered', null, {
    project: p => ({
      incident: toIncidentJson(runningIncident, { includeScript: scriptAudience(p) }),
      alarm: alarmJson,
    }),
  });

  await emitCloseSuggestionChanges(tx, emit, [runningIncident.id], closeSuggestedBefore);

  // Neuberechnung relativer Alarmierungen (ADR 0022): `planned` Alarmierungen,
  // die relativ zu DIESER Alarmierung geplant sind, verschieben sich auf
  // `triggered_at + offset_minutes`, egal wann/wie die Basis auslöst.
  const dependents = await tx
    .select()
    .from(alarm)
    .where(and(eq(alarm.relativeToAlarmId, typedAlarmRow.id), eq(alarm.state, 'planned')));
  for (const dependent of dependents as AlarmRow[]) {
    const offsetMinutes = dependent.offsetMinutes ?? 0;
    const newScheduledAt = new Date(now.getTime() + offsetMinutes * 60_000);
    await tx.update(alarm).set({ scheduledAt: newScheduledAt }).where(eq(alarm.id, dependent.id));
    const [dependentJson] = await loadAlarms(tx, { alarmIds: [dependent.id] });
    if (dependentJson) {
      await emit(
        'alarm.planned',
        {
          incident: toIncidentJson(runningIncident, { includeScript: true }),
          alarm: dependentJson,
        },
        { audience: scriptAudience }
      );
    }
  }

  return { alarm: alarmJson, doubleCrewed };
}
