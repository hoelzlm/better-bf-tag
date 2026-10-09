import { and, eq, inArray } from 'drizzle-orm';
import { alarm, alarmVehicle, alarmRecipient, vehicle, person } from '../db/schema.js';
import type { Tx } from '../realtime/realtime.js';
import { functionRank } from '../shifts/shift-json.js';

export type AlarmState = 'planned' | 'triggered' | 'missed' | 'discarded';

export interface AlarmRow {
  id: string;
  incidentId: string;
  state: AlarmState;
  scheduledAt: Date | null;
  triggeredAt: Date | null;
  createdAt: Date;
  pushDelivered: number;
  pushRejected: number;
}

export interface AlarmRecipientInput {
  personId: string;
  displayName: string;
  vehicleId: string;
  function: string;
  hasDevice: boolean;
  acknowledgedAt: Date | null;
}

export interface AlarmRecipientJson {
  person_id: string;
  display_name: string;
  vehicle_id: string;
  function: string;
  has_device: boolean;
  acknowledged_at: string | null;
}

export interface AlarmJson {
  id: string;
  incident_id: string;
  state: AlarmState;
  scheduled_at: string | null;
  triggered_at: string | null;
  vehicle_ids: string[];
  recipients: AlarmRecipientJson[];
  push_delivered: number;
  push_rejected: number;
}

/**
 * The single serializer for every Alarmierung read path (ADR 0017). Callers
 * pass already-ordered `vehicleIds` (by vehicle `sort_order`) and
 * `recipients` (by vehicle `sort_order`, Funktion-Standardreihenfolge,
 * `display_name`) — see `loadAlarms` below, the only producer of that
 * order.
 */
export function toAlarmJson(
  row: AlarmRow,
  vehicleIds: string[],
  recipients: AlarmRecipientInput[]
): AlarmJson {
  return {
    id: row.id,
    incident_id: row.incidentId,
    state: row.state,
    scheduled_at: row.scheduledAt ? row.scheduledAt.toISOString() : null,
    triggered_at: row.triggeredAt ? row.triggeredAt.toISOString() : null,
    vehicle_ids: vehicleIds,
    recipients: recipients.map(r => ({
      person_id: r.personId,
      display_name: r.displayName,
      vehicle_id: r.vehicleId,
      function: r.function,
      has_device: r.hasDevice,
      acknowledged_at: r.acknowledgedAt ? r.acknowledgedAt.toISOString() : null,
    })),
    push_delivered: row.pushDelivered,
    push_rejected: row.pushRejected,
  };
}

export interface LoadAlarmsFilter {
  incidentIds?: string[];
  alarmIds?: string[];
}

/**
 * Loads Alarmierungen with their Fahrzeuge and eingefrorene Empfänger
 * (ADR 0017), shaped via `toAlarmJson`. Filter by `incidentIds` and/or
 * `alarmIds` (both optional; an empty/absent filter set loads nothing —
 * callers always pass at least one non-empty array). The returned order
 * matches the DB's row order for `alarm`; callers that need `triggered_at`
 * order (snapshot, `GET /incidents/{id}`) sort the result themselves.
 */
export async function loadAlarms(tx: Tx, filter: LoadAlarmsFilter): Promise<AlarmJson[]> {
  const conditions = [];
  if (filter.incidentIds && filter.incidentIds.length > 0) {
    conditions.push(inArray(alarm.incidentId, filter.incidentIds));
  }
  if (filter.alarmIds && filter.alarmIds.length > 0) {
    conditions.push(inArray(alarm.id, filter.alarmIds));
  }
  if (conditions.length === 0) {
    return [];
  }

  const alarmRows = (await tx
    .select()
    .from(alarm)
    .where(conditions.length === 1 ? conditions[0] : and(...conditions))) as AlarmRow[];
  if (alarmRows.length === 0) return [];

  const alarmIds = alarmRows.map(row => row.id);

  const vehicleRows = await tx
    .select({
      alarmId: alarmVehicle.alarmId,
      vehicleId: alarmVehicle.vehicleId,
      sortOrder: vehicle.sortOrder,
    })
    .from(alarmVehicle)
    .innerJoin(vehicle, eq(alarmVehicle.vehicleId, vehicle.id))
    .where(inArray(alarmVehicle.alarmId, alarmIds));
  vehicleRows.sort((a, b) => a.sortOrder - b.sortOrder);

  const vehicleIdsByAlarm = new Map<string, string[]>();
  for (const row of vehicleRows) {
    const list = vehicleIdsByAlarm.get(row.alarmId) ?? [];
    list.push(row.vehicleId);
    vehicleIdsByAlarm.set(row.alarmId, list);
  }

  const recipientRows = await tx
    .select({
      alarmId: alarmRecipient.alarmId,
      personId: alarmRecipient.personId,
      vehicleId: alarmRecipient.vehicleId,
      function: alarmRecipient.function,
      hasDevice: alarmRecipient.hasDevice,
      acknowledgedAt: alarmRecipient.acknowledgedAt,
      displayName: person.displayName,
      vehicleSortOrder: vehicle.sortOrder,
    })
    .from(alarmRecipient)
    .innerJoin(vehicle, eq(alarmRecipient.vehicleId, vehicle.id))
    .innerJoin(person, eq(alarmRecipient.personId, person.id))
    .where(inArray(alarmRecipient.alarmId, alarmIds));

  recipientRows.sort((a, b) => {
    if (a.vehicleSortOrder !== b.vehicleSortOrder) return a.vehicleSortOrder - b.vehicleSortOrder;
    const rankA = functionRank(a.function);
    const rankB = functionRank(b.function);
    if (rankA !== rankB) return rankA - rankB;
    if (a.function !== b.function) return a.function.localeCompare(b.function);
    return a.displayName.localeCompare(b.displayName);
  });

  const recipientsByAlarm = new Map<string, AlarmRecipientInput[]>();
  for (const row of recipientRows) {
    const list = recipientsByAlarm.get(row.alarmId) ?? [];
    list.push({
      personId: row.personId,
      displayName: row.displayName,
      vehicleId: row.vehicleId,
      function: row.function,
      hasDevice: row.hasDevice,
      acknowledgedAt: row.acknowledgedAt,
    });
    recipientsByAlarm.set(row.alarmId, list);
  }

  return alarmRows.map(row =>
    toAlarmJson(row, vehicleIdsByAlarm.get(row.id) ?? [], recipientsByAlarm.get(row.id) ?? [])
  );
}
