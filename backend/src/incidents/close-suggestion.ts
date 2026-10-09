import { inArray } from 'drizzle-orm';
import { incident, alarm, alarmVehicle, vehicle } from '../db/schema.js';
import type { Tx, Emit } from '../realtime/realtime.js';
import { closeSuggestedAudience } from './visibility.js';

/**
 * Abschlussvorschlag (ADR 0019 "Abschlussvorschlag"): an incident id is in
 * the returned set iff the incident is `running`, has at least one
 * `triggered` alarm, has no `planned` alarm, and every vehicle of all its
 * `triggered` alarms has `status ∈ {1, 2}` with `status_changed_at` later
 * than the `triggered_at` of the FIRST `triggered` alarm of that incident
 * containing that vehicle. This is the only place implementing the rule;
 * callers diff a before/after set to decide whether to emit
 * `incident.close_suggested`.
 *
 * Set-based (a handful of queries over `incidentIds`), no per-vehicle N+1.
 */
export async function computeCloseSuggested(tx: Tx, incidentIds: string[]): Promise<Set<string>> {
  if (incidentIds.length === 0) return new Set();

  const incidentRows = await tx
    .select({ id: incident.id, state: incident.state })
    .from(incident)
    .where(inArray(incident.id, incidentIds));
  const runningIds = new Set(
    incidentRows.filter(row => row.state === 'running').map(row => row.id)
  );
  if (runningIds.size === 0) return new Set();

  const alarmRows = await tx
    .select({
      id: alarm.id,
      incidentId: alarm.incidentId,
      state: alarm.state,
      triggeredAt: alarm.triggeredAt,
    })
    .from(alarm)
    .where(inArray(alarm.incidentId, [...runningIds]));

  const hasTriggered = new Set<string>();
  const hasPlanned = new Set<string>();
  const triggeredAlarmIds: string[] = [];
  const triggeredAtByAlarmId = new Map<string, Date>();
  const incidentIdByAlarmId = new Map<string, string>();
  for (const row of alarmRows) {
    incidentIdByAlarmId.set(row.id, row.incidentId);
    if (row.state === 'triggered') {
      hasTriggered.add(row.incidentId);
      if (row.triggeredAt) {
        triggeredAlarmIds.push(row.id);
        triggeredAtByAlarmId.set(row.id, row.triggeredAt);
      }
    } else if (row.state === 'planned') {
      hasPlanned.add(row.incidentId);
    }
  }

  const candidateIds = new Set(
    [...runningIds].filter(id => hasTriggered.has(id) && !hasPlanned.has(id))
  );
  if (candidateIds.size === 0) return new Set();

  const alarmVehicleRows =
    triggeredAlarmIds.length > 0
      ? await tx
          .select({ alarmId: alarmVehicle.alarmId, vehicleId: alarmVehicle.vehicleId })
          .from(alarmVehicle)
          .where(inArray(alarmVehicle.alarmId, triggeredAlarmIds))
      : [];

  // incidentId -> vehicleId -> earliest triggered_at among triggered alarms
  // of that incident containing that vehicle.
  const firstTriggeredAtByIncidentVehicle = new Map<string, Map<string, Date>>();
  for (const row of alarmVehicleRows) {
    const incidentId = incidentIdByAlarmId.get(row.alarmId);
    if (!incidentId || !candidateIds.has(incidentId)) continue;
    const triggeredAt = triggeredAtByAlarmId.get(row.alarmId);
    if (!triggeredAt) continue;
    let perVehicle = firstTriggeredAtByIncidentVehicle.get(incidentId);
    if (!perVehicle) {
      perVehicle = new Map();
      firstTriggeredAtByIncidentVehicle.set(incidentId, perVehicle);
    }
    const existing = perVehicle.get(row.vehicleId);
    if (!existing || triggeredAt < existing) {
      perVehicle.set(row.vehicleId, triggeredAt);
    }
  }

  const allVehicleIds = new Set<string>();
  for (const perVehicle of firstTriggeredAtByIncidentVehicle.values()) {
    for (const vehicleId of perVehicle.keys()) allVehicleIds.add(vehicleId);
  }

  const vehicleRows =
    allVehicleIds.size > 0
      ? await tx
          .select({
            id: vehicle.id,
            status: vehicle.status,
            statusChangedAt: vehicle.statusChangedAt,
          })
          .from(vehicle)
          .where(inArray(vehicle.id, [...allVehicleIds]))
      : [];
  const vehicleById = new Map(vehicleRows.map(row => [row.id, row]));

  const result = new Set<string>();
  for (const incidentId of candidateIds) {
    const perVehicle = firstTriggeredAtByIncidentVehicle.get(incidentId);
    if (!perVehicle || perVehicle.size === 0) continue;
    let allReady = true;
    for (const [vehicleId, triggeredAt] of perVehicle) {
      const row = vehicleById.get(vehicleId);
      const ready =
        row !== undefined &&
        (row.status === 1 || row.status === 2) &&
        row.statusChangedAt !== null &&
        row.statusChangedAt > triggeredAt;
      if (!ready) {
        allReady = false;
        break;
      }
    }
    if (allReady) result.add(incidentId);
  }

  return result;
}

/**
 * Recomputes `computeCloseSuggested` over `incidentIds` and emits
 * `incident.close_suggested { id, suggested }` (audience Leitstelle/Admin
 * only) for each id whose membership in the set changed relative to
 * `before`.
 */
export async function emitCloseSuggestionChanges(
  tx: Tx,
  emit: Emit,
  incidentIds: string[],
  before: Set<string>
): Promise<void> {
  if (incidentIds.length === 0) return;
  const after = await computeCloseSuggested(tx, incidentIds);
  for (const id of incidentIds) {
    const wasSuggested = before.has(id);
    const isSuggested = after.has(id);
    if (wasSuggested !== isSuggested) {
      await emit(
        'incident.close_suggested',
        { id, suggested: isSuggested },
        { audience: closeSuggestedAudience }
      );
    }
  }
}
