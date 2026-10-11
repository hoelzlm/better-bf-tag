import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { eq } from 'drizzle-orm';
import { programItem, bfDay } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { resolveBfDay, bfDayNotFound } from '../bf-days/resolve-day.js';
import {
  createProgramItemBodySchema,
  programItemListResponseSchema,
  programItemSchema,
  updateProgramItemBodySchema,
} from './program-item-schemas.js';
import {
  emitProgramChanged,
  loadProgramItems,
  toProgramItemJson,
  type ProgramItemRow,
} from '../program/program-item-json.js';
import { ApiError } from '../errors.js';
import type { BfDayRow } from './bf-day-schemas.js';
import type { Tx } from '../realtime/realtime.js';

const dayParamsSchema = z.object({ day: z.string() });
const programItemIdParamsSchema = z.object({ id: z.string().uuid() });

function programItemNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Programmpunkt nicht gefunden.');
}

function bfDayEnded(): ApiError {
  return new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
}

function programItemOutsideBfDay(): ApiError {
  return new ApiError(
    400,
    'validation_error',
    'Programmpunkt muss vollständig im Zeitraum des BF-Tags liegen.'
  );
}

async function loadProgramItemRow(tx: Tx, id: string): Promise<ProgramItemRow | undefined> {
  const [row] = await tx.select().from(programItem).where(eq(programItem.id, id)).limit(1);
  return row;
}

async function loadBfDayById(tx: Tx, id: string): Promise<BfDayRow | undefined> {
  const [row] = await tx.select().from(bfDay).where(eq(bfDay.id, id)).limit(1);
  return row;
}

/** `ends_at <= starts_at` or outside `[bf_day.starts_at, bf_day.ends_at]` → 400 (ADR 0025). */
function assertWithinBfDayPeriod(startsAt: Date, endsAt: Date, bfDayRow: BfDayRow): void {
  if (endsAt <= startsAt) {
    throw new ApiError(400, 'validation_error', 'ends_at muss nach starts_at liegen.');
  }
  if (startsAt < bfDayRow.startsAt || endsAt > bfDayRow.endsAt) {
    throw programItemOutsideBfDay();
  }
}

export const programItemRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/bf-days/:day/program-items',
    {
      preHandler: requireAuth({ allowMonitor: true }),
      schema: {
        operationId: 'listProgramItems',
        tags: ['program-items'],
        params: dayParamsSchema,
        response: {
          200: programItemListResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.db.transaction(async tx => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        return loadProgramItems(tx, bfDayRow.id);
      });
    }
  );

  fastify.post(
    '/bf-days/:day/program-items',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'createProgramItem',
        tags: ['program-items'],
        params: dayParamsSchema,
        body: createProgramItemBodySchema,
        response: {
          201: programItemSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const created = await fastify.realtime.mutate(async (tx, emit) => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        if (bfDayRow.state === 'ended') {
          throw bfDayEnded();
        }

        const startsAt = new Date(request.body.starts_at);
        const endsAt = new Date(request.body.ends_at);
        assertWithinBfDayPeriod(startsAt, endsAt, bfDayRow);

        const [row] = await tx
          .insert(programItem)
          .values({
            bfDayId: bfDayRow.id,
            title: request.body.title,
            type: request.body.type,
            startsAt,
            endsAt,
          })
          .returning();
        if (!row) {
          throw new Error('createProgramItem: insert returned no row');
        }

        const json = toProgramItemJson(row);
        await emitProgramChanged(emit, tx, bfDayRow.id);
        return json;
      });

      return reply.status(201).send(created);
    }
  );

  fastify.patch(
    '/program-items/:id',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'updateProgramItem',
        tags: ['program-items'],
        params: programItemIdParamsSchema,
        body: updateProgramItemBodySchema,
        response: {
          200: programItemSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadProgramItemRow(tx, request.params.id);
        if (!existing) {
          throw programItemNotFound();
        }

        const bfDayRow = await loadBfDayById(tx, existing.bfDayId);
        if (!bfDayRow) {
          throw bfDayNotFound();
        }
        if (bfDayRow.state === 'ended') {
          throw bfDayEnded();
        }

        const nextStartsAt =
          request.body.starts_at !== undefined
            ? new Date(request.body.starts_at)
            : existing.startsAt;
        const nextEndsAt =
          request.body.ends_at !== undefined ? new Date(request.body.ends_at) : existing.endsAt;
        assertWithinBfDayPeriod(nextStartsAt, nextEndsAt, bfDayRow);

        const patch: Partial<ProgramItemRow> = {
          startsAt: nextStartsAt,
          endsAt: nextEndsAt,
        };
        if (request.body.title !== undefined) patch.title = request.body.title;
        if (request.body.type !== undefined) patch.type = request.body.type;

        const [row] = await tx
          .update(programItem)
          .set(patch)
          .where(eq(programItem.id, existing.id))
          .returning();
        if (!row) {
          throw programItemNotFound();
        }

        const json = toProgramItemJson(row);
        await emitProgramChanged(emit, tx, bfDayRow.id);
        return json;
      });
    }
  );

  fastify.delete(
    '/program-items/:id',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'deleteProgramItem',
        tags: ['program-items'],
        params: programItemIdParamsSchema,
      },
    },
    async (request, reply) => {
      await fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadProgramItemRow(tx, request.params.id);
        if (!existing) {
          throw programItemNotFound();
        }

        const bfDayRow = await loadBfDayById(tx, existing.bfDayId);
        if (!bfDayRow) {
          throw bfDayNotFound();
        }
        if (bfDayRow.state === 'ended') {
          throw bfDayEnded();
        }

        await tx.delete(programItem).where(eq(programItem.id, existing.id));

        await emitProgramChanged(emit, tx, bfDayRow.id);
      });

      return reply.status(204).send();
    }
  );
};
