import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { desc, eq } from 'drizzle-orm';
import { announcement, shift } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { resolveBfDay } from '../bf-days/resolve-day.js';
import {
  announcementListResponseSchema,
  announcementSchema,
  createAnnouncementBodySchema,
} from './announcement-schemas.js';
import { toAnnouncementJson, type AnnouncementRow } from '../announcements/announcement-json.js';
import { announcementVisibleTo, loadShiftCrewPersonIds } from '../announcements/visibility.js';
import { dispatchAnnouncementPushes } from '../push/announcement-push.js';
import type { Viewer } from '../realtime/realtime.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';

const dayParamsSchema = z.object({ day: z.string() });
const announcementIdParamsSchema = z.object({ id: z.string().uuid() });

function announcementNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Durchsage nicht gefunden.');
}

function bfDayNotRunning(): ApiError {
  return new ApiError(
    409,
    'bf_day_not_running',
    'Durchsagen sind nur möglich, während der BF-Tag läuft.'
  );
}

/** Builds the Viewer the realtime filter and `announcementVisibleTo` share, from the request's Principal. */
function viewerFromRequestAuth(auth: {
  kind: 'person' | 'monitor';
  personId?: string;
  permission?: string;
}): Viewer {
  if (auth.kind === 'monitor') return { kind: 'monitor', permission: 'crew' };
  return {
    kind: 'person',
    personId: auth.personId as string,
    permission: auth.permission as Viewer['permission'],
  };
}

async function loadAnnouncementRow(tx: Tx, id: string): Promise<AnnouncementRow | undefined> {
  const [row] = await tx.select().from(announcement).where(eq(announcement.id, id)).limit(1);
  return row;
}

export const announcementRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.post(
    '/bf-days/:day/announcements',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'createAnnouncement',
        tags: ['announcements'],
        params: dayParamsSchema,
        body: createAnnouncementBodySchema,
        response: {
          201: announcementSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'person') {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }

      const created = await fastify.realtime.mutate(async (tx, emit) => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        if (bfDayRow.state !== 'running') {
          throw bfDayNotRunning();
        }

        const shiftId = request.body.shift_id ?? null;
        if (shiftId !== null) {
          const [shiftRow] = await tx
            .select({ id: shift.id, bfDayId: shift.bfDayId })
            .from(shift)
            .where(eq(shift.id, shiftId))
            .limit(1);
          if (!shiftRow || shiftRow.bfDayId !== bfDayRow.id) {
            throw new ApiError(400, 'validation_error', 'shift_id gehört nicht zu diesem BF-Tag.');
          }
        }

        const [row] = await tx
          .insert(announcement)
          .values({
            bfDayId: bfDayRow.id,
            shiftId,
            text: request.body.text,
            createdBy: auth.personId,
            createdAt: fastify.clock.now(),
          })
          .returning();
        if (!row) {
          throw new Error('createAnnouncement: insert returned no row');
        }

        const crewPersonIds =
          shiftId !== null ? await loadShiftCrewPersonIds(tx, shiftId) : new Set<string>();
        const json = toAnnouncementJson(row);
        await emit('announcement.created', json, {
          audience: v => announcementVisibleTo(v, { shiftId }, crewPersonIds),
        });

        // push: ADR 0024 — fire-and-forget, after the commit above; never
        // blocks or fails the response.

        return json;
      });

      void dispatchAnnouncementPushes(
        { db: fastify.db, pushSender: fastify.pushSender, log: fastify.log },
        created.id
      ).catch(err => {
        fastify.log.warn(
          { error: err instanceof Error ? err.message : String(err), announcementId: created.id },
          'dispatchAnnouncementPushes failed'
        );
      });

      return reply.status(201).send(created);
    }
  );

  fastify.get(
    '/bf-days/:day/announcements',
    {
      preHandler: requireAuth({ allowMonitor: true }),
      schema: {
        operationId: 'listAnnouncements',
        tags: ['announcements'],
        params: dayParamsSchema,
        response: {
          200: announcementListResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      const auth = request.auth;
      if (!auth) {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }
      const viewer = viewerFromRequestAuth(auth);

      return fastify.db.transaction(async tx => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        const rows = await tx
          .select()
          .from(announcement)
          .where(eq(announcement.bfDayId, bfDayRow.id))
          .orderBy(desc(announcement.createdAt));

        const crewCacheByShift = new Map<string, Set<string>>();
        const visible: AnnouncementRow[] = [];
        for (const row of rows) {
          let crewPersonIds = new Set<string>();
          if (row.shiftId !== null) {
            const cached = crewCacheByShift.get(row.shiftId);
            if (cached) {
              crewPersonIds = cached;
            } else {
              crewPersonIds = await loadShiftCrewPersonIds(tx, row.shiftId);
              crewCacheByShift.set(row.shiftId, crewPersonIds);
            }
          }
          if (announcementVisibleTo(viewer, { shiftId: row.shiftId }, crewPersonIds)) {
            visible.push(row);
          }
        }

        return visible.map(toAnnouncementJson);
      });
    }
  );

  fastify.delete(
    '/announcements/:id',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'deleteAnnouncement',
        tags: ['announcements'],
        params: announcementIdParamsSchema,
      },
    },
    async (request, reply) => {
      await fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadAnnouncementRow(tx, request.params.id);
        if (!existing) {
          throw announcementNotFound();
        }

        const bfDayRow = await resolveBfDay(tx, existing.bfDayId);
        if (bfDayRow.state !== 'running') {
          throw bfDayNotRunning();
        }

        const crewPersonIds =
          existing.shiftId !== null
            ? await loadShiftCrewPersonIds(tx, existing.shiftId)
            : new Set<string>();

        await tx.delete(announcement).where(eq(announcement.id, existing.id));

        await emit(
          'announcement.deleted',
          { id: existing.id },
          {
            audience: v => announcementVisibleTo(v, { shiftId: existing.shiftId }, crewPersonIds),
          }
        );
      });

      return reply.status(204).send();
    }
  );
};
