import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, eq, inArray, isNull } from 'drizzle-orm';
import {
  incident,
  vehicle,
  bfDay,
  alarm,
  alarmVehicle,
  alarmRecipient,
  device,
  person,
} from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';
import { toIncidentJson, type IncidentRow } from '../incidents/incident-json.js';
import { scriptAudience } from '../incidents/visibility.js';
import { incidentUpdatedEventOpts } from '../incidents/incident-events.js';
import { loadCurrentCrewAssignments } from '../shifts/current-crew.js';
import { incidentIdParamsSchema } from './incident-schemas.js';
import { dispatchAlarmPushes } from '../push/alarm-push.js';
import {
  alarmRecipientJsonSchema,
  alarmIdParamsSchema,
  triggerAlarmBodySchema,
  triggerAlarmResponseSchema,
  type DoubleCrewedJson,
  loadAlarms,
  type AlarmRow,
} from './alarm-schemas.js';

const acknowledgeResponseSchema = z.object({ recipient: alarmRecipientJsonSchema });

function incidentNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Einsatz nicht gefunden.');
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

export const alarmRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.post(
    '/incidents/:id/alarms',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'triggerAlarm',
        tags: ['alarms'],
        params: incidentIdParamsSchema,
        body: triggerAlarmBodySchema,
        response: {
          200: triggerAlarmResponseSchema,
          201: triggerAlarmResponseSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
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
              throw new Error('triggerAlarm: idempotent alarm disappeared');
            }
            return { status: 200 as const, body: { alarm: alarmJson, double_crewed: [] } };
          }
        }

        const [bfDayRow] = await tx
          .select({ state: bfDay.state })
          .from(bfDay)
          .where(eq(bfDay.id, incidentRow.bfDayId))
          .limit(1);

        const vehicleIds = request.body.vehicle_ids;
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

        if (!bfDayRow || bfDayRow.state !== 'running') {
          throw new ApiError(409, 'bf_day_not_running', 'BF-Tag läuft nicht.');
        }

        const now = fastify.clock.now();
        const [updatedIncident] = await tx
          .update(incident)
          .set({ state: 'running', updatedAt: now })
          .where(and(eq(incident.id, incidentRow.id), eq(incident.state, 'draft')))
          .returning();
        if (!updatedIncident) {
          throw new ApiError(409, 'invalid_state_transition', 'Einsatz wurde bereits alarmiert.');
        }
        const runningIncident = updatedIncident as IncidentRow;

        const [alarmRow] = await tx
          .insert(alarm)
          .values({
            ...(request.body.id !== undefined ? { id: request.body.id } : {}),
            incidentId: runningIncident.id,
            state: 'triggered',
            scheduledAt: null,
            triggeredAt: now,
            createdAt: now,
          })
          .returning();
        if (!alarmRow) {
          throw new Error('triggerAlarm: insert alarm returned no row');
        }

        for (const id of vehicleIds) {
          await tx.insert(alarmVehicle).values({ alarmId: alarmRow.id, vehicleId: id });
        }

        // Empfänger einfrieren (ADR 0017): Besatzung der aktuellen Schicht,
        // gefiltert auf die alarmierten Fahrzeuge, pro Person dedupliziert
        // (erstes Fahrzeug nach sort_order — `loadCurrentCrewAssignments`
        // already orders by vehicle.sort_order).
        const vehicleIdSet = new Set(vehicleIds);
        const crew = await loadCurrentCrewAssignments(tx, now);
        const alarmedCrew = crew.filter(c => vehicleIdSet.has(c.vehicleId));

        const vehicleIdsByPerson = new Map<string, string[]>();
        const firstAssignmentByPerson = new Map<string, { vehicleId: string; function: string }>();
        for (const c of alarmedCrew) {
          if (!firstAssignmentByPerson.has(c.personId)) {
            firstAssignmentByPerson.set(c.personId, {
              vehicleId: c.vehicleId,
              function: c.function,
            });
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
            alarmId: alarmRow.id,
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

        await emit('incident.updated', null, incidentUpdatedEventOpts(runningIncident));

        const [alarmJson] = await loadAlarms(tx, { alarmIds: [alarmRow.id] });
        if (!alarmJson) {
          throw new Error('triggerAlarm: freshly inserted alarm disappeared');
        }
        await emit('alarm.triggered', null, {
          project: p => ({
            incident: toIncidentJson(runningIncident, { includeScript: scriptAudience(p) }),
            alarm: alarmJson,
          }),
        });

        return { status: 201 as const, body: { alarm: alarmJson, double_crewed: doubleCrewed } };
      });

      if (result.status === 201) {
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
