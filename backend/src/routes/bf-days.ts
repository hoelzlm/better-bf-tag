import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, asc, desc, eq, inArray } from 'drizzle-orm';
import { bfDay, participation, shift, crewAssignment, person } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import {
  bfDayJsonSchema,
  toBfDayJson,
  participantJsonSchema,
  toParticipantJson,
  type BfDayRow,
} from './bf-day-schemas.js';
import { resolveBfDay, bfDayNotFound } from '../bf-days/resolve-day.js';
import { loadShiftJson } from '../shifts/shift-json.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';

const isoDateTime = z.string().datetime({ offset: true });

const createBfDayBodySchema = z.object({
  name: z.string().trim().min(1),
  starts_at: isoDateTime,
  ends_at: isoDateTime,
});

const updateBfDayBodySchema = z.object({
  name: z.string().trim().min(1).optional(),
  starts_at: isoDateTime.optional(),
  ends_at: isoDateTime.optional(),
});

const setParticipantsBodySchema = z.object({
  person_ids: z.array(z.string().uuid()),
});

const bfDayListResponseSchema = z.array(bfDayJsonSchema);
const participantListResponseSchema = z.array(participantJsonSchema);

const dayParamsSchema = z.object({ day: z.string() });
const idParamsSchema = z.object({ id: z.string().uuid() });

/** 23505 on the partial unique index `bf_day_single_running` (ADR 0013): a race between two starts. */
function isBfDaySingleRunningViolation(error: unknown): boolean {
  const pgError = error as { code?: string; constraint?: string } | undefined;
  return (
    pgError?.code === '23505' &&
    (pgError.constraint === undefined || pgError.constraint === 'bf_day_single_running')
  );
}

async function loadBfDayById(tx: Tx, id: string): Promise<BfDayRow | undefined> {
  const [row] = await tx.select().from(bfDay).where(eq(bfDay.id, id)).limit(1);
  return row;
}

function assertEndsAfterStarts(startsAt: Date, endsAt: Date): void {
  if (endsAt <= startsAt) {
    throw new ApiError(400, 'validation_error', 'ends_at muss nach starts_at liegen.');
  }
}

export const bfDayRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/bf-days',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'listBfDays',
        tags: ['bf-days'],
        response: {
          200: bfDayListResponseSchema,
        },
      },
    },
    async () => {
      const rows = await fastify.db.select().from(bfDay).orderBy(desc(bfDay.startsAt));
      return rows.map(toBfDayJson);
    }
  );

  fastify.get(
    '/bf-days/:day',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'getBfDay',
        tags: ['bf-days'],
        params: dayParamsSchema,
        response: {
          200: bfDayJsonSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      const row = await fastify.db.transaction(tx => resolveBfDay(tx, request.params.day));
      return toBfDayJson(row);
    }
  );

  fastify.post(
    '/bf-days',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'createBfDay',
        tags: ['bf-days'],
        body: createBfDayBodySchema,
        response: {
          201: bfDayJsonSchema,
          400: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const startsAt = new Date(request.body.starts_at);
      const endsAt = new Date(request.body.ends_at);
      assertEndsAfterStarts(startsAt, endsAt);

      const created = await fastify.realtime.mutate(async (tx, emit) => {
        const now = fastify.clock.now();
        const [row] = await tx
          .insert(bfDay)
          .values({
            name: request.body.name,
            startsAt,
            endsAt,
            state: 'planning',
            anonymizedAt: null,
            createdAt: now,
          })
          .returning();
        if (!row) {
          throw new Error('createBfDay: insert returned no row');
        }

        // The default shift over the full period is created in the same
        // transaction (ADR 0013); its routes come in T05-2.
        await tx.insert(shift).values({
          bfDayId: row.id,
          name: 'Schicht 1',
          startsAt,
          endsAt,
          createdAt: now,
        });

        const json = toBfDayJson(row);
        await emit('bf_day.updated', json);
        return json;
      });

      return reply.status(201).send(created);
    }
  );

  fastify.patch(
    '/bf-days/:id',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'updateBfDay',
        tags: ['bf-days'],
        params: idParamsSchema,
        body: updateBfDayBodySchema,
        response: {
          200: bfDayJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadBfDayById(tx, request.params.id);
        if (!existing) {
          throw bfDayNotFound();
        }
        if (existing.state === 'ended') {
          throw new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
        }

        const nextStartsAt =
          request.body.starts_at !== undefined
            ? new Date(request.body.starts_at)
            : existing.startsAt;
        const nextEndsAt =
          request.body.ends_at !== undefined ? new Date(request.body.ends_at) : existing.endsAt;
        assertEndsAfterStarts(nextStartsAt, nextEndsAt);

        const periodChanged =
          request.body.starts_at !== undefined || request.body.ends_at !== undefined;

        if (periodChanged) {
          // Schichtgrenzen, die genau auf der alten BF-Tag-Grenze lagen,
          // wandern mit; danach muss jede Schicht vollständig im neuen
          // Zeitraum liegen und darf nicht leer sein (ADR 0013). Violated ->
          // 409 shift_outside_bf_day, nothing is changed (the transaction
          // rolls back).
          const shifts = await tx.select().from(shift).where(eq(shift.bfDayId, existing.id));
          const shiftUpdates: Array<{ id: string; startsAt: Date; endsAt: Date }> = [];

          for (const row of shifts) {
            let newShiftStart = row.startsAt;
            let newShiftEnd = row.endsAt;
            if (row.startsAt.getTime() === existing.startsAt.getTime()) {
              newShiftStart = nextStartsAt;
            }
            if (row.endsAt.getTime() === existing.endsAt.getTime()) {
              newShiftEnd = nextEndsAt;
            }

            const fitsInPeriod =
              newShiftStart.getTime() >= nextStartsAt.getTime() &&
              newShiftEnd.getTime() <= nextEndsAt.getTime();
            const isNotEmpty = newShiftEnd.getTime() > newShiftStart.getTime();
            if (!fitsInPeriod || !isNotEmpty) {
              throw new ApiError(
                409,
                'shift_outside_bf_day',
                'Schicht liegt nicht mehr vollständig im Zeitraum des BF-Tags.'
              );
            }

            if (
              newShiftStart.getTime() !== row.startsAt.getTime() ||
              newShiftEnd.getTime() !== row.endsAt.getTime()
            ) {
              shiftUpdates.push({ id: row.id, startsAt: newShiftStart, endsAt: newShiftEnd });
            }
          }

          for (const update of shiftUpdates) {
            await tx
              .update(shift)
              .set({ startsAt: update.startsAt, endsAt: update.endsAt })
              .where(eq(shift.id, update.id));
          }
        }

        const patch: Partial<BfDayRow> = {};
        if (request.body.name !== undefined) patch.name = request.body.name;
        if (request.body.starts_at !== undefined) patch.startsAt = nextStartsAt;
        if (request.body.ends_at !== undefined) patch.endsAt = nextEndsAt;

        const [row] = await tx
          .update(bfDay)
          .set(patch)
          .where(eq(bfDay.id, existing.id))
          .returning();
        if (!row) {
          throw bfDayNotFound();
        }

        const json = toBfDayJson(row);
        await emit('bf_day.updated', json);
        return json;
      });
    }
  );

  fastify.post(
    '/bf-days/:id/start',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'startBfDay',
        tags: ['bf-days'],
        params: idParamsSchema,
        response: {
          200: bfDayJsonSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadBfDayById(tx, request.params.id);
        if (!existing) {
          throw bfDayNotFound();
        }
        if (existing.state !== 'planning') {
          throw new ApiError(
            409,
            'invalid_state_transition',
            'BF-Tag kann nur aus Planung gestartet werden.'
          );
        }

        const [runningOther] = await tx
          .select({ id: bfDay.id })
          .from(bfDay)
          .where(eq(bfDay.state, 'running'))
          .limit(1);
        if (runningOther) {
          throw new ApiError(409, 'bf_day_already_running', 'Es läuft bereits ein BF-Tag.');
        }

        let row: BfDayRow | undefined;
        try {
          [row] = await tx
            .update(bfDay)
            .set({ state: 'running' })
            .where(eq(bfDay.id, existing.id))
            .returning();
        } catch (error) {
          if (isBfDaySingleRunningViolation(error)) {
            throw new ApiError(409, 'bf_day_already_running', 'Es läuft bereits ein BF-Tag.');
          }
          throw error;
        }
        if (!row) {
          throw bfDayNotFound();
        }

        const json = toBfDayJson(row);
        await emit('bf_day.updated', json);
        return json;
      });
    }
  );

  fastify.post(
    '/bf-days/:id/end',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'endBfDay',
        tags: ['bf-days'],
        params: idParamsSchema,
        response: {
          200: bfDayJsonSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadBfDayById(tx, request.params.id);
        if (!existing) {
          throw bfDayNotFound();
        }
        if (existing.state !== 'running') {
          throw new ApiError(
            409,
            'invalid_state_transition',
            'BF-Tag kann nur beendet werden, während er läuft.'
          );
        }

        const [row] = await tx
          .update(bfDay)
          .set({ state: 'ended' })
          .where(eq(bfDay.id, existing.id))
          .returning();
        if (!row) {
          throw bfDayNotFound();
        }

        const json = toBfDayJson(row);
        await emit('bf_day.updated', json);
        return json;
      });
    }
  );

  fastify.get(
    '/bf-days/:day/participants',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'listParticipants',
        tags: ['bf-days'],
        params: dayParamsSchema,
        response: {
          200: participantListResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.db.transaction(async tx => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);

        const rows = await tx
          .select({
            id: person.id,
            displayName: person.displayName,
            personType: person.personType,
            permission: person.permission,
            fireDepartmentId: person.fireDepartmentId,
          })
          .from(participation)
          .innerJoin(person, eq(participation.personId, person.id))
          .where(eq(participation.bfDayId, bfDayRow.id))
          .orderBy(asc(person.displayName));

        return rows.map(toParticipantJson);
      });
    }
  );

  fastify.put(
    '/bf-days/:day/participants',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'setParticipants',
        tags: ['bf-days'],
        params: dayParamsSchema,
        body: setParticipantsBodySchema,
        response: {
          200: participantListResponseSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        if (bfDayRow.state === 'ended') {
          throw new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
        }

        const requestedIds = new Set(request.body.person_ids);

        const existingRows = await tx
          .select({ personId: participation.personId })
          .from(participation)
          .where(eq(participation.bfDayId, bfDayRow.id));
        const existingIds = new Set(existingRows.map(row => row.personId));

        const toAdd = [...requestedIds].filter(id => !existingIds.has(id));
        const toRemove = [...existingIds].filter(id => !requestedIds.has(id));

        if (toAdd.length > 0) {
          const addedPersons = await tx
            .select({ id: person.id, active: person.active })
            .from(person)
            .where(inArray(person.id, toAdd));
          const addedById = new Map(addedPersons.map(row => [row.id, row]));
          for (const id of toAdd) {
            const found = addedById.get(id);
            if (!found || !found.active) {
              throw new ApiError(
                400,
                'validation_error',
                'Unbekannte oder deaktivierte Person kann nicht als Teilnahme hinzugefügt werden.'
              );
            }
          }
        }

        if (toAdd.length > 0) {
          await tx
            .insert(participation)
            .values(toAdd.map(personId => ({ bfDayId: bfDayRow.id, personId })));
        }

        if (toRemove.length > 0) {
          // Removing a participant also removes their crew assignments in
          // every shift of this BF-Tag (ADR 0013), emitting
          // shift.crew_changed per affected shift.
          const removedCrewRows = await tx
            .select({ shiftId: crewAssignment.shiftId })
            .from(crewAssignment)
            .innerJoin(shift, eq(crewAssignment.shiftId, shift.id))
            .where(and(eq(shift.bfDayId, bfDayRow.id), inArray(crewAssignment.personId, toRemove)));
          const affectedShiftIds = [...new Set(removedCrewRows.map(row => row.shiftId))];

          await tx
            .delete(participation)
            .where(
              and(eq(participation.bfDayId, bfDayRow.id), inArray(participation.personId, toRemove))
            );

          if (affectedShiftIds.length > 0) {
            await tx
              .delete(crewAssignment)
              .where(
                and(
                  inArray(crewAssignment.shiftId, affectedShiftIds),
                  inArray(crewAssignment.personId, toRemove)
                )
              );
          }

          for (const shiftId of affectedShiftIds) {
            const shiftJson = await loadShiftJson(tx, shiftId);
            if (shiftJson) {
              await emit('shift.crew_changed', shiftJson);
            }
          }
        }

        const rows = await tx
          .select({
            id: person.id,
            displayName: person.displayName,
            personType: person.personType,
            permission: person.permission,
            fireDepartmentId: person.fireDepartmentId,
          })
          .from(participation)
          .innerJoin(person, eq(participation.personId, person.id))
          .where(eq(participation.bfDayId, bfDayRow.id))
          .orderBy(asc(person.displayName));

        return rows.map(toParticipantJson);
      });
    }
  );
};
