import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, eq, inArray, isNull, or } from 'drizzle-orm';
import {
  incident,
  vehicle,
  bfDay,
  alarm,
  alarmVehicle,
  alarmRecipient,
  person,
} from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';
import { toIncidentJson, type IncidentRow } from '../incidents/incident-json.js';
import { scriptAudience } from '../incidents/visibility.js';
import {
  computeCloseSuggested,
  emitCloseSuggestionChanges,
} from '../incidents/close-suggestion.js';
import { triggerAlarm } from '../alarms/trigger.js';
import { incidentIdParamsSchema } from './incident-schemas.js';
import { dispatchAlarmPushes } from '../push/alarm-push.js';
import {
  alarmRecipientJsonSchema,
  alarmIdParamsSchema,
  createAlarmBodySchema,
  createAlarmResponseSchema,
  updateAlarmBodySchema,
  updateAlarmResponseSchema,
  discardAlarmResponseSchema,
  triggerAlarmResponseSchema,
  loadAlarms,
  type AlarmRow,
} from './alarm-schemas.js';

const acknowledgeResponseSchema = z.object({ recipient: alarmRecipientJsonSchema });

function incidentNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Einsatz nicht gefunden.');
}

function incidentNotAlarmable(): ApiError {
  return new ApiError(409, 'incident_not_alarmable', 'Einsatz ist nicht alarmierbar.');
}

function alarmNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Alarmierung nicht gefunden.');
}

async function loadIncidentRow(tx: Tx, id: string): Promise<IncidentRow | undefined> {
  const [row] = await tx.select().from(incident).where(eq(incident.id, id)).limit(1);
  return row as IncidentRow | undefined;
}

async function loadAlarmRow(tx: Tx, id: string): Promise<AlarmRow | undefined> {
  const [row] = await tx.select().from(alarm).where(eq(alarm.id, id)).limit(1);
  return row as AlarmRow | undefined;
}

async function loadDisplayName(tx: Tx, personId: string): Promise<string> {
  const [row] = await tx
    .select({ displayName: person.displayName })
    .from(person)
    .where(eq(person.id, personId))
    .limit(1);
  return row?.displayName ?? '';
}

/**
 * Vehicles already bound to a `triggered` or `planned` alarm of the given
 * incident (ADR 0022: the planned-check now also applies to immediate
 * alarming and to planning itself; `excludeAlarmId` lets `PATCH` exclude
 * the alarm being edited).
 */
async function loadAlreadyAlarmedVehicleIds(
  tx: Tx,
  incidentId: string,
  excludeAlarmId?: string
): Promise<Set<string>> {
  const conditions = [
    eq(alarm.incidentId, incidentId),
    or(eq(alarm.state, 'triggered'), eq(alarm.state, 'planned')),
  ];
  const rows = await tx
    .select({ vehicleId: alarmVehicle.vehicleId, alarmId: alarmVehicle.alarmId })
    .from(alarmVehicle)
    .innerJoin(alarm, eq(alarmVehicle.alarmId, alarm.id))
    .where(and(...conditions));
  return new Set(rows.filter(r => r.alarmId !== excludeAlarmId).map(r => r.vehicleId));
}

/** Loads/validates the Fahrzeuge of a body (unknown -> 400, inactive -> 409). */
async function loadAndValidateVehicles(tx: Tx, vehicleIds: string[]): Promise<void> {
  const vehicleRows = await tx.select().from(vehicle).where(inArray(vehicle.id, vehicleIds));
  const vehicleById = new Map(vehicleRows.map(row => [row.id, row]));
  for (const id of vehicleIds) {
    if (!vehicleById.has(id)) {
      throw new ApiError(400, 'validation_error', 'Unbekanntes Fahrzeug.');
    }
  }
  for (const id of vehicleIds) {
    const v = vehicleById.get(id);
    if (v && !v.active) {
      throw new ApiError(409, 'vehicle_inactive', 'Fahrzeug ist deaktiviert.');
    }
  }
}

/**
 * Vehicles already bound to a `triggered` alarm of the given incident
 * (ADR 0022: used by manual `POST /alarms/{id}/trigger` and the
 * scheduler — narrower than `loadAlreadyAlarmedVehicleIds`, which also
 * counts `planned`).
 */
async function loadAlreadyTriggeredVehicleIds(tx: Tx, incidentId: string): Promise<Set<string>> {
  const rows = await tx
    .select({ vehicleId: alarmVehicle.vehicleId })
    .from(alarmVehicle)
    .innerJoin(alarm, eq(alarmVehicle.alarmId, alarm.id))
    .where(and(eq(alarm.incidentId, incidentId), eq(alarm.state, 'triggered')));
  return new Set(rows.map(r => r.vehicleId));
}

interface AlarmBaseRow {
  id: string;
  scheduledAt: Date | null;
  triggeredAt: Date | null;
}

/**
 * Basis einer relativen Alarmierung (ADR 0022): die früheste `triggered`
 * Alarmierung des Einsatzes (nach `triggered_at`, `id`), sonst die
 * `planned` Alarmierung ohne eigene Basis mit dem frühesten `scheduled_at`.
 */
async function loadRelativeBase(tx: Tx, incidentId: string): Promise<AlarmBaseRow | undefined> {
  const triggeredRows = (await tx
    .select({ id: alarm.id, scheduledAt: alarm.scheduledAt, triggeredAt: alarm.triggeredAt })
    .from(alarm)
    .where(and(eq(alarm.incidentId, incidentId), eq(alarm.state, 'triggered')))) as AlarmBaseRow[];
  if (triggeredRows.length > 0) {
    triggeredRows.sort((a, b) => {
      const at = a.triggeredAt?.getTime() ?? 0;
      const bt = b.triggeredAt?.getTime() ?? 0;
      if (at !== bt) return at - bt;
      return a.id.localeCompare(b.id);
    });
    return triggeredRows[0];
  }

  const plannedRows = (await tx
    .select({ id: alarm.id, scheduledAt: alarm.scheduledAt, triggeredAt: alarm.triggeredAt })
    .from(alarm)
    .where(
      and(
        eq(alarm.incidentId, incidentId),
        eq(alarm.state, 'planned'),
        isNull(alarm.relativeToAlarmId)
      )
    )) as AlarmBaseRow[];
  if (plannedRows.length === 0) return undefined;
  plannedRows.sort((a, b) => {
    const at = a.scheduledAt?.getTime() ?? 0;
    const bt = b.scheduledAt?.getTime() ?? 0;
    if (at !== bt) return at - bt;
    return a.id.localeCompare(b.id);
  });
  return plannedRows[0];
}

export const alarmRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.post(
    '/incidents/:id/alarms',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'createAlarm',
        tags: ['alarms'],
        params: incidentIdParamsSchema,
        body: createAlarmBodySchema,
        response: {
          200: createAlarmResponseSchema,
          201: createAlarmResponseSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const planning =
        request.body.scheduled_at !== undefined || request.body.offset_minutes !== undefined;

      const result = await fastify.realtime.mutate(async (tx, emit) => {
        const incidentRow = await loadIncidentRow(tx, request.params.id);
        if (!incidentRow) {
          throw incidentNotFound();
        }

        // Idempotency (ADR 0017): a repeat with the same client-generated
        // `id` for the same incident returns the existing alarm, no event.
        // For a different incident it is a conflict. Checked before the
        // state transition so a confirmed double-click never re-triggers.
        if (request.body.id !== undefined) {
          const existing = await loadAlarmRow(tx, request.body.id);
          if (existing) {
            if (existing.incidentId !== incidentRow.id) {
              throw new ApiError(
                409,
                'conflict',
                'Idempotenz-Schlüssel ist bereits für einen anderen Einsatz vergeben.'
              );
            }
            const [alarmJson] = await loadAlarms(tx, { alarmIds: [existing.id] });
            if (!alarmJson) {
              throw new Error('createAlarm: idempotent alarm disappeared');
            }
            return { status: 200 as const, body: { alarm: alarmJson, double_crewed: [] } };
          }
        }

        // Abschlussvorschlag (ADR 0019): `before` wird vor jeder Änderung
        // berechnet (für `draft` ohnehin immer leer, da nicht `running`).
        const closeSuggestedBefore = await computeCloseSuggested(tx, [incidentRow.id]);

        const [bfDayRow] = await tx
          .select({ state: bfDay.state })
          .from(bfDay)
          .where(eq(bfDay.id, incidentRow.bfDayId))
          .limit(1);

        const vehicleIds = request.body.vehicle_ids;
        await loadAndValidateVehicles(tx, vehicleIds);

        // Planen ist schon vor Beginn des BF-Tags erlaubt (ADR 0022);
        // sofortiges Alarmieren weiterhin nur, während der BF-Tag läuft.
        if (planning) {
          if (!bfDayRow || (bfDayRow.state !== 'planning' && bfDayRow.state !== 'running')) {
            throw new ApiError(
              409,
              'bf_day_not_running',
              'BF-Tag ist nicht geplant oder läuft nicht.'
            );
          }
        } else if (!bfDayRow || bfDayRow.state !== 'running') {
          throw new ApiError(409, 'bf_day_not_running', 'BF-Tag läuft nicht.');
        }

        // ADR 0019: Nachalarmierung bei laufendem Einsatz. `closed`/
        // `discarded` sind nie alarmierbar; `draft` löst den Erstalarm aus
        // (Zustandswechsel), `running` eine Nachalarmierung (kein
        // Zustandswechsel).
        if (incidentRow.state === 'closed' || incidentRow.state === 'discarded') {
          throw incidentNotAlarmable();
        }

        // Fahrzeuge nur einmal pro Einsatz (ADR 0019/0022): auch gegen
        // `planned` Alarmierungen, nicht nur `triggered`.
        const alreadyAlarmedVehicleIds = await loadAlreadyAlarmedVehicleIds(tx, incidentRow.id);
        for (const id of vehicleIds) {
          if (alreadyAlarmedVehicleIds.has(id)) {
            throw new ApiError(
              409,
              'vehicle_already_alarmed',
              'Fahrzeug ist bereits bei diesem Einsatz alarmiert.'
            );
          }
        }

        const now = fastify.clock.now();

        if (planning) {
          let scheduledAt: Date;
          let relativeToAlarmId: string | null = null;
          let offsetMinutes: number | null = null;

          if (request.body.offset_minutes !== undefined) {
            const base = await loadRelativeBase(tx, incidentRow.id);
            if (!base) {
              throw new ApiError(
                409,
                'no_first_alarm',
                'Es gibt noch keinen Erstalarm oder geplanten Erstalarm für diesen Einsatz.'
              );
            }
            const baseTime = base.triggeredAt ?? base.scheduledAt;
            if (!baseTime) {
              throw new Error(
                'createAlarm: relative base has neither triggered_at nor scheduled_at'
              );
            }
            scheduledAt = new Date(baseTime.getTime() + request.body.offset_minutes * 60_000);
            relativeToAlarmId = base.id;
            offsetMinutes = request.body.offset_minutes;
          } else {
            scheduledAt = new Date(request.body.scheduled_at as string);
          }

          if (scheduledAt.getTime() <= now.getTime()) {
            throw new ApiError(
              409,
              'scheduled_at_in_past',
              'Der Zeitpunkt der Alarmierung liegt nicht in der Zukunft.'
            );
          }

          const [alarmRow] = await tx
            .insert(alarm)
            .values({
              ...(request.body.id !== undefined ? { id: request.body.id } : {}),
              incidentId: incidentRow.id,
              state: 'planned',
              scheduledAt,
              triggeredAt: null,
              createdAt: now,
              relativeToAlarmId,
              offsetMinutes,
            })
            .returning();
          if (!alarmRow) {
            throw new Error('createAlarm: insert planned alarm returned no row');
          }
          for (const id of vehicleIds) {
            await tx.insert(alarmVehicle).values({ alarmId: alarmRow.id, vehicleId: id });
          }

          const [alarmJson] = await loadAlarms(tx, { alarmIds: [alarmRow.id] });
          if (!alarmJson) {
            throw new Error('createAlarm: freshly inserted planned alarm disappeared');
          }
          await emit(
            'alarm.planned',
            { incident: toIncidentJson(incidentRow, { includeScript: true }), alarm: alarmJson },
            { audience: scriptAudience }
          );

          await emitCloseSuggestionChanges(tx, emit, [incidentRow.id], closeSuggestedBefore);

          return { status: 201 as const, body: { alarm: alarmJson, double_crewed: [] } };
        }

        // Immediate alarming: insert a placeholder row (never visible —
        // `triggerAlarm` flips it to `triggered` inside this same
        // transaction before any event is emitted) then run the shared
        // Auslöse-Pfad.
        const [alarmRow] = await tx
          .insert(alarm)
          .values({
            ...(request.body.id !== undefined ? { id: request.body.id } : {}),
            incidentId: incidentRow.id,
            state: 'planned',
            scheduledAt: null,
            triggeredAt: null,
            createdAt: now,
            relativeToAlarmId: null,
            offsetMinutes: null,
          })
          .returning();
        if (!alarmRow) {
          throw new Error('createAlarm: insert alarm returned no row');
        }
        for (const id of vehicleIds) {
          await tx.insert(alarmVehicle).values({ alarmId: alarmRow.id, vehicleId: id });
        }

        const { alarm: alarmJson, doubleCrewed } = await triggerAlarm(
          tx,
          emit,
          { clock: fastify.clock, pushSender: fastify.pushSender, log: fastify.log },
          alarmRow.id,
          closeSuggestedBefore
        );

        return { status: 201 as const, body: { alarm: alarmJson, double_crewed: doubleCrewed } };
      });

      if (result.status === 201 && !planning) {
        await dispatchAlarmPushes(
          {
            db: fastify.db,
            pushSender: fastify.pushSender,
            realtime: fastify.realtime,
            log: fastify.log,
          },
          result.body.alarm.id
        );
        const [reloaded] = await fastify.db.transaction(tx =>
          loadAlarms(tx, { alarmIds: [result.body.alarm.id] })
        );
        if (reloaded) {
          result.body.alarm = reloaded;
        }
      }

      return reply.status(result.status).send(result.body);
    }
  );

  fastify.patch(
    '/alarms/:id',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'updateAlarm',
        tags: ['alarms'],
        params: alarmIdParamsSchema,
        body: updateAlarmBodySchema,
        response: {
          200: updateAlarmResponseSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadAlarmRow(tx, request.params.id);
        if (!existing) {
          throw alarmNotFound();
        }
        if (existing.state !== 'planned') {
          throw new ApiError(409, 'alarm_not_planned', 'Alarmierung ist nicht mehr geplant.');
        }

        if (request.body.scheduled_at !== undefined && existing.relativeToAlarmId !== null) {
          throw new ApiError(
            400,
            'validation_error',
            'scheduled_at ist nur für absolute Alarmierungen erlaubt.'
          );
        }
        if (request.body.offset_minutes !== undefined && existing.relativeToAlarmId === null) {
          throw new ApiError(
            400,
            'validation_error',
            'offset_minutes ist nur für relative Alarmierungen erlaubt.'
          );
        }

        const incidentRow = await loadIncidentRow(tx, existing.incidentId);
        if (!incidentRow) {
          throw incidentNotFound();
        }

        const closeSuggestedBefore = await computeCloseSuggested(tx, [incidentRow.id]);

        const [bfDayRow] = await tx
          .select({ state: bfDay.state })
          .from(bfDay)
          .where(eq(bfDay.id, incidentRow.bfDayId))
          .limit(1);
        if (!bfDayRow || (bfDayRow.state !== 'planning' && bfDayRow.state !== 'running')) {
          throw new ApiError(
            409,
            'bf_day_not_running',
            'BF-Tag ist nicht geplant oder läuft nicht.'
          );
        }
        if (incidentRow.state === 'closed' || incidentRow.state === 'discarded') {
          throw incidentNotAlarmable();
        }

        const vehicleIds = request.body.vehicle_ids;
        if (vehicleIds !== undefined) {
          await loadAndValidateVehicles(tx, vehicleIds);
          const alreadyAlarmedVehicleIds = await loadAlreadyAlarmedVehicleIds(
            tx,
            incidentRow.id,
            existing.id
          );
          for (const id of vehicleIds) {
            if (alreadyAlarmedVehicleIds.has(id)) {
              throw new ApiError(
                409,
                'vehicle_already_alarmed',
                'Fahrzeug ist bereits bei diesem Einsatz alarmiert.'
              );
            }
          }
        }

        const now = fastify.clock.now();
        let scheduledAt = existing.scheduledAt as Date;
        if (request.body.offset_minutes !== undefined) {
          const base = await loadRelativeBase(tx, incidentRow.id);
          if (!base) {
            throw new ApiError(
              409,
              'no_first_alarm',
              'Es gibt noch keinen Erstalarm oder geplanten Erstalarm für diesen Einsatz.'
            );
          }
          const baseTime = base.triggeredAt ?? base.scheduledAt;
          if (!baseTime) {
            throw new Error('updateAlarm: relative base has neither triggered_at nor scheduled_at');
          }
          scheduledAt = new Date(baseTime.getTime() + request.body.offset_minutes * 60_000);
        } else if (request.body.scheduled_at !== undefined) {
          scheduledAt = new Date(request.body.scheduled_at);
        }
        if (scheduledAt.getTime() <= now.getTime()) {
          throw new ApiError(
            409,
            'scheduled_at_in_past',
            'Der Zeitpunkt der Alarmierung liegt nicht in der Zukunft.'
          );
        }

        const timeChanged = scheduledAt.getTime() !== (existing.scheduledAt?.getTime() ?? NaN);

        await tx
          .update(alarm)
          .set({
            scheduledAt,
            ...(request.body.offset_minutes !== undefined
              ? { offsetMinutes: request.body.offset_minutes }
              : {}),
          })
          .where(eq(alarm.id, existing.id));

        if (vehicleIds !== undefined) {
          await tx.delete(alarmVehicle).where(eq(alarmVehicle.alarmId, existing.id));
          for (const id of vehicleIds) {
            await tx.insert(alarmVehicle).values({ alarmId: existing.id, vehicleId: id });
          }
        }

        const [alarmJson] = await loadAlarms(tx, { alarmIds: [existing.id] });
        if (!alarmJson) {
          throw new Error('updateAlarm: updated alarm disappeared');
        }
        await emit(
          'alarm.planned',
          { incident: toIncidentJson(incidentRow, { includeScript: true }), alarm: alarmJson },
          { audience: scriptAudience }
        );

        // Basis geändert Zeit -> abhängige `planned` Alarmierungen neu
        // berechnen (ADR 0022).
        if (timeChanged) {
          const dependents = (await tx
            .select()
            .from(alarm)
            .where(
              and(eq(alarm.relativeToAlarmId, existing.id), eq(alarm.state, 'planned'))
            )) as AlarmRow[];
          for (const dependent of dependents) {
            const offset = dependent.offsetMinutes ?? 0;
            const dependentScheduledAt = new Date(scheduledAt.getTime() + offset * 60_000);
            await tx
              .update(alarm)
              .set({ scheduledAt: dependentScheduledAt })
              .where(eq(alarm.id, dependent.id));
            const [dependentJson] = await loadAlarms(tx, { alarmIds: [dependent.id] });
            if (dependentJson) {
              await emit(
                'alarm.planned',
                {
                  incident: toIncidentJson(incidentRow, { includeScript: true }),
                  alarm: dependentJson,
                },
                { audience: scriptAudience }
              );
            }
          }
        }

        await emitCloseSuggestionChanges(tx, emit, [incidentRow.id], closeSuggestedBefore);

        return { alarm: alarmJson };
      });
    }
  );

  fastify.post(
    '/alarms/:id/discard',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'discardAlarm',
        tags: ['alarms'],
        params: alarmIdParamsSchema,
        response: {
          200: discardAlarmResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadAlarmRow(tx, request.params.id);
        if (!existing) {
          throw alarmNotFound();
        }
        if (existing.state !== 'planned' && existing.state !== 'missed') {
          throw new ApiError(
            409,
            'invalid_state_transition',
            'Alarmierung kann nicht mehr verworfen werden.'
          );
        }

        const closeSuggestedBefore = await computeCloseSuggested(tx, [existing.incidentId]);

        const [row] = await tx
          .update(alarm)
          .set({ state: 'discarded' })
          .where(eq(alarm.id, existing.id))
          .returning();
        if (!row) {
          throw alarmNotFound();
        }
        const alarmRow = row as AlarmRow;

        await emit(
          'alarm.discarded',
          { alarm_id: alarmRow.id, incident_id: alarmRow.incidentId },
          { audience: scriptAudience }
        );

        // Kaskade auf relative Alarmierungen (ADR 0022).
        const dependents = (await tx
          .select()
          .from(alarm)
          .where(
            and(eq(alarm.relativeToAlarmId, alarmRow.id), eq(alarm.state, 'planned'))
          )) as AlarmRow[];
        for (const dependent of dependents) {
          await tx.update(alarm).set({ state: 'discarded' }).where(eq(alarm.id, dependent.id));
          await emit(
            'alarm.discarded',
            { alarm_id: dependent.id, incident_id: alarmRow.incidentId },
            { audience: scriptAudience }
          );
        }

        await emitCloseSuggestionChanges(tx, emit, [alarmRow.incidentId], closeSuggestedBefore);

        const [alarmJson] = await loadAlarms(tx, { alarmIds: [alarmRow.id] });
        if (!alarmJson) {
          throw new Error('discardAlarm: discarded alarm disappeared');
        }
        return { alarm: alarmJson };
      });
    }
  );

  fastify.post(
    '/alarms/:id/trigger',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'triggerAlarm',
        tags: ['alarms'],
        params: alarmIdParamsSchema,
        response: {
          200: triggerAlarmResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const result = await fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadAlarmRow(tx, request.params.id);
        if (!existing) {
          throw alarmNotFound();
        }
        if (existing.state !== 'planned' && existing.state !== 'missed') {
          throw new ApiError(
            409,
            'invalid_state_transition',
            'Alarmierung kann nicht mehr ausgelöst werden.'
          );
        }

        const incidentRow = await loadIncidentRow(tx, existing.incidentId);
        if (!incidentRow) {
          throw incidentNotFound();
        }

        const [bfDayRow] = await tx
          .select({ state: bfDay.state })
          .from(bfDay)
          .where(eq(bfDay.id, incidentRow.bfDayId))
          .limit(1);
        if (!bfDayRow || bfDayRow.state !== 'running') {
          throw new ApiError(409, 'bf_day_not_running', 'BF-Tag läuft nicht.');
        }

        if (incidentRow.state !== 'draft' && incidentRow.state !== 'running') {
          throw incidentNotAlarmable();
        }

        const vehicleIds = await tx
          .select({ vehicleId: alarmVehicle.vehicleId })
          .from(alarmVehicle)
          .where(eq(alarmVehicle.alarmId, existing.id));
        const alreadyTriggeredVehicleIds = await loadAlreadyTriggeredVehicleIds(tx, incidentRow.id);
        for (const { vehicleId } of vehicleIds) {
          if (alreadyTriggeredVehicleIds.has(vehicleId)) {
            throw new ApiError(
              409,
              'vehicle_already_alarmed',
              'Fahrzeug ist bereits bei diesem Einsatz alarmiert.'
            );
          }
        }

        const closeSuggestedBefore = await computeCloseSuggested(tx, [incidentRow.id]);
        const { alarm: alarmJson, doubleCrewed } = await triggerAlarm(
          tx,
          emit,
          { clock: fastify.clock, pushSender: fastify.pushSender, log: fastify.log },
          existing.id,
          closeSuggestedBefore
        );

        return { alarm: alarmJson, double_crewed: doubleCrewed };
      });

      await dispatchAlarmPushes(
        {
          db: fastify.db,
          pushSender: fastify.pushSender,
          realtime: fastify.realtime,
          log: fastify.log,
        },
        result.alarm.id
      );
      const [reloaded] = await fastify.db.transaction(tx =>
        loadAlarms(tx, { alarmIds: [result.alarm.id] })
      );
      if (reloaded) {
        result.alarm = reloaded;
      }

      return reply.status(200).send(result);
    }
  );

  fastify.post(
    '/alarms/:id/acknowledge',
    {
      preHandler: [requireAuth()],
      schema: {
        operationId: 'acknowledgeAlarm',
        tags: ['alarms'],
        params: alarmIdParamsSchema,
        response: {
          200: acknowledgeResponseSchema,
          403: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'person') {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }
      const personId = auth.personId;

      return fastify.realtime.mutate(async (tx, emit) => {
        const alarmRow = await loadAlarmRow(tx, request.params.id);
        if (!alarmRow) {
          throw alarmNotFound();
        }

        const [recipientRow] = await tx
          .select()
          .from(alarmRecipient)
          .where(
            and(eq(alarmRecipient.alarmId, alarmRow.id), eq(alarmRecipient.personId, personId))
          )
          .limit(1);
        if (!recipientRow) {
          throw new ApiError(
            403,
            'not_recipient',
            'Keine Empfängerin/kein Empfänger dieser Alarmierung.'
          );
        }

        const incidentRow = await loadIncidentRow(tx, alarmRow.incidentId);
        if (!incidentRow || alarmRow.state !== 'triggered' || incidentRow.state !== 'running') {
          throw new ApiError(409, 'alarm_not_active', 'Alarmierung ist nicht mehr aktiv.');
        }

        const now = fastify.clock.now();
        const [updated] = await tx
          .update(alarmRecipient)
          .set({ acknowledgedAt: now })
          .where(
            and(
              eq(alarmRecipient.alarmId, alarmRow.id),
              eq(alarmRecipient.personId, personId),
              isNull(alarmRecipient.acknowledgedAt)
            )
          )
          .returning();

        const finalRow = updated ?? recipientRow;

        if (updated) {
          const displayName = await loadDisplayName(tx, personId);
          await emit('alarm.acknowledged', {
            alarm_id: alarmRow.id,
            incident_id: alarmRow.incidentId,
            person_id: personId,
            display_name: displayName,
            acknowledged_at: now.toISOString(),
          });
        }

        const recipient = {
          person_id: finalRow.personId,
          display_name: await loadDisplayName(tx, personId),
          vehicle_id: finalRow.vehicleId,
          function: finalRow.function,
          has_device: finalRow.hasDevice,
          acknowledged_at: finalRow.acknowledgedAt ? finalRow.acknowledgedAt.toISOString() : null,
        };

        return { recipient };
      });
    }
  );
};
