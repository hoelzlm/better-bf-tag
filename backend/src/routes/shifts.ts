import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, asc, eq } from 'drizzle-orm';
import { shift, crewAssignment, vehicle, participation } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { resolveBfDay } from '../bf-days/resolve-day.js';
import { loadShiftJson, shiftJsonSchema, setShiftCrewBodySchema } from './shift-schemas.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';

const isoDateTime = z.string().datetime({ offset: true });

const createShiftBodySchema = z.object({
  name: z.string().trim().min(1),
  starts_at: isoDateTime,
  ends_at: isoDateTime,
});

const updateShiftBodySchema = z.object({
  name: z.string().trim().min(1).optional(),
  starts_at: isoDateTime.optional(),
  ends_at: isoDateTime.optional(),
});

const shiftListResponseSchema = z.array(shiftJsonSchema);

const dayParamsSchema = z.object({ day: z.string() });
const dayShiftParamsSchema = z.object({ day: z.string(), id: z.string().uuid() });
const shiftIdParamsSchema = z.object({ id: z.string().uuid() });

interface ShiftRow {
  id: string;
  bfDayId: string;
  name: string;
  startsAt: Date;
  endsAt: Date;
  createdAt: Date;
}

function shiftNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Schicht nicht gefunden.');
}

function assertEndsAfterStarts(startsAt: Date, endsAt: Date): void {
  if (endsAt <= startsAt) {
    throw new ApiError(400, 'validation_error', 'ends_at muss nach starts_at liegen.');
  }
}

function assertWithinBfDayPeriod(
  startsAt: Date,
  endsAt: Date,
  bfDay: { startsAt: Date; endsAt: Date }
): void {
  if (startsAt.getTime() < bfDay.startsAt.getTime() || endsAt.getTime() > bfDay.endsAt.getTime()) {
    throw new ApiError(
      409,
      'shift_outside_bf_day',
      'Schicht muss vollständig im Zeitraum des BF-Tags liegen.'
    );
  }
}

async function loadShiftRow(tx: Tx, id: string): Promise<ShiftRow | undefined> {
  const [row] = await tx.select().from(shift).where(eq(shift.id, id)).limit(1);
  return row;
}

/** Loads the shift and asserts it belongs to the given BF-Tag, else 404. */
async function loadShiftInDay(tx: Tx, bfDayId: string, id: string): Promise<ShiftRow> {
  const row = await loadShiftRow(tx, id);
  if (!row || row.bfDayId !== bfDayId) {
    throw shiftNotFound();
  }
  return row;
}

export const shiftRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/bf-days/:day/shifts',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'listShifts',
        tags: ['shifts'],
        params: dayParamsSchema,
        response: {
          200: shiftListResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.db.transaction(async tx => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        const rows = await tx
          .select({ id: shift.id })
          .from(shift)
          .where(eq(shift.bfDayId, bfDayRow.id))
          .orderBy(asc(shift.startsAt), asc(shift.name));

        const shifts = [];
        for (const row of rows) {
          const json = await loadShiftJson(tx, row.id);
          if (json) shifts.push(json);
        }
        return shifts;
      });
    }
  );

  fastify.post(
    '/bf-days/:day/shifts',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'createShift',
        tags: ['shifts'],
        params: dayParamsSchema,
        body: createShiftBodySchema,
        response: {
          201: shiftJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const startsAt = new Date(request.body.starts_at);
      const endsAt = new Date(request.body.ends_at);
      assertEndsAfterStarts(startsAt, endsAt);

      const created = await fastify.realtime.mutate(async (tx, emit) => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        if (bfDayRow.state === 'ended') {
          throw new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
        }
        assertWithinBfDayPeriod(startsAt, endsAt, bfDayRow);

        const [row] = await tx
          .insert(shift)
          .values({
            bfDayId: bfDayRow.id,
            name: request.body.name,
            startsAt,
            endsAt,
            createdAt: fastify.clock.now(),
          })
          .returning();
        if (!row) {
          throw new Error('createShift: insert returned no row');
        }

        const json = await loadShiftJson(tx, row.id);
        if (!json) {
          throw new Error('createShift: loadShiftJson returned nothing for a just-inserted shift');
        }
        await emit('shift.crew_changed', json);
        return json;
      });

      return reply.status(201).send(created);
    }
  );

  fastify.patch(
    '/bf-days/:day/shifts/:id',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'updateShift',
        tags: ['shifts'],
        params: dayShiftParamsSchema,
        body: updateShiftBodySchema,
        response: {
          200: shiftJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        const existing = await loadShiftInDay(tx, bfDayRow.id, request.params.id);
        if (bfDayRow.state === 'ended') {
          throw new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
        }

        const nextStartsAt =
          request.body.starts_at !== undefined
            ? new Date(request.body.starts_at)
            : existing.startsAt;
        const nextEndsAt =
          request.body.ends_at !== undefined ? new Date(request.body.ends_at) : existing.endsAt;
        assertEndsAfterStarts(nextStartsAt, nextEndsAt);
        assertWithinBfDayPeriod(nextStartsAt, nextEndsAt, bfDayRow);

        const patch: Partial<ShiftRow> = {};
        if (request.body.name !== undefined) patch.name = request.body.name;
        if (request.body.starts_at !== undefined) patch.startsAt = nextStartsAt;
        if (request.body.ends_at !== undefined) patch.endsAt = nextEndsAt;

        const [row] = await tx
          .update(shift)
          .set(patch)
          .where(eq(shift.id, existing.id))
          .returning();
        if (!row) {
          throw shiftNotFound();
        }

        const json = await loadShiftJson(tx, row.id);
        if (!json) {
          throw new Error('updateShift: loadShiftJson returned nothing for an updated shift');
        }
        await emit('shift.crew_changed', json);
        return json;
      });
    }
  );

  fastify.delete(
    '/bf-days/:day/shifts/:id',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'deleteShift',
        tags: ['shifts'],
        params: dayShiftParamsSchema,
      },
    },
    async (request, reply) => {
      await fastify.realtime.mutate(async (tx, emit) => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        const existing = await loadShiftInDay(tx, bfDayRow.id, request.params.id);
        if (bfDayRow.state === 'ended') {
          throw new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
        }

        const otherShifts = await tx
          .select({ id: shift.id })
          .from(shift)
          .where(eq(shift.bfDayId, bfDayRow.id));
        if (otherShifts.length <= 1) {
          throw new ApiError(
            409,
            'last_shift',
            'Die letzte Schicht eines BF-Tags kann nicht gelöscht werden.'
          );
        }

        await tx.delete(shift).where(eq(shift.id, existing.id));
        await emit('shift.deleted', { id: existing.id, bf_day_id: bfDayRow.id });
      });

      return reply.status(204).send();
    }
  );

  fastify.put(
    '/shifts/:id/crew',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'setShiftCrew',
        tags: ['shifts'],
        params: shiftIdParamsSchema,
        body: setShiftCrewBodySchema,
        response: {
          200: shiftJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadShiftRow(tx, request.params.id);
        if (!existing) {
          throw shiftNotFound();
        }

        const bfDayRow = await resolveBfDay(tx, existing.bfDayId);
        if (bfDayRow.state === 'ended') {
          throw new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
        }

        const assignments = request.body.assignments;

        const seenPairs = new Set<string>();
        for (const assignment of assignments) {
          const key = `${assignment.vehicle_id}:${assignment.person_id}`;
          if (seenPairs.has(key)) {
            throw new ApiError(
              400,
              'validation_error',
              'Doppelte Zuweisung (vehicle_id, person_id) in der Besatzung.'
            );
          }
          seenPairs.add(key);
        }

        const vehicleIds = [...new Set(assignments.map(a => a.vehicle_id))];
        // Load each referenced vehicle individually (small lists expected).
        for (const vehicleId of vehicleIds) {
          const [row] = await tx.select().from(vehicle).where(eq(vehicle.id, vehicleId)).limit(1);
          if (!row) {
            throw new ApiError(400, 'validation_error', `Unbekanntes Fahrzeug: ${vehicleId}.`);
          }
          if (!row.active) {
            throw new ApiError(409, 'vehicle_inactive', 'Fahrzeug ist deaktiviert.');
          }
        }

        const personIds = [...new Set(assignments.map(a => a.person_id))];
        for (const personId of personIds) {
          const [participationRow] = await tx
            .select({ personId: participation.personId })
            .from(participation)
            .where(
              and(eq(participation.bfDayId, bfDayRow.id), eq(participation.personId, personId))
            )
            .limit(1);
          if (!participationRow) {
            throw new ApiError(
              409,
              'person_not_participant',
              'Person nimmt nicht am BF-Tag dieser Schicht teil.'
            );
          }
        }

        await tx.delete(crewAssignment).where(eq(crewAssignment.shiftId, existing.id));
        if (assignments.length > 0) {
          await tx.insert(crewAssignment).values(
            assignments.map(a => ({
              shiftId: existing.id,
              vehicleId: a.vehicle_id,
              personId: a.person_id,
              function: a.function,
            }))
          );
        }

        const json = await loadShiftJson(tx, existing.id);
        if (!json) {
          throw new Error('setShiftCrew: loadShiftJson returned nothing after replacing crew');
        }
        await emit('shift.crew_changed', json);
        return json;
      });
    }
  );
};
