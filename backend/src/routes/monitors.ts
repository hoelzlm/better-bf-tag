import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { asc, eq } from 'drizzle-orm';
import { monitorDisplay } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { createPairingCodeForTarget, formatPairingCode } from '../access/pairing.js';
import { monitorJsonSchema, toMonitorJson } from './monitor-schemas.js';
import { ApiError } from '../errors.js';

const createMonitorBodySchema = z.object({
  name: z.string().trim().min(1).max(100),
});

const updateMonitorBodySchema = z.object({
  name: z.string().trim().min(1).max(100),
});

const monitorListResponseSchema = z.array(monitorJsonSchema);

const monitorPairingCodeResponseSchema = z.object({
  monitor_id: z.string(),
  name: z.string(),
  code: z.string(),
  expires_at: z.string(),
});

function monitorNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Monitor nicht gefunden.');
}

/**
 * Admin routes for Monitore (ADR 0012). `POST /monitors/{id}/pairing-code`
 * reuses `createPairingCodeForTarget` from T04-2 with `targetType:
 * 'monitor'` — same code generation/hashing, no duplication. The
 * `/auth/monitor/*` endpoints that redeem these codes live in
 * `routes/auth.ts` (tag `auth`), not here.
 */
export const monitorRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/monitors',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'listMonitors',
        tags: ['monitors'],
        response: {
          200: monitorListResponseSchema,
        },
      },
    },
    async () => {
      const rows = await fastify.db.select().from(monitorDisplay).orderBy(asc(monitorDisplay.name));
      return rows.map(toMonitorJson);
    }
  );

  fastify.post(
    '/monitors',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'createMonitor',
        tags: ['monitors'],
        body: createMonitorBodySchema,
        response: {
          201: monitorJsonSchema,
        },
      },
    },
    async (request, reply) => {
      const now = fastify.clock.now();
      const [row] = await fastify.db
        .insert(monitorDisplay)
        .values({
          name: request.body.name,
          refreshTokenHash: null,
          pairedAt: null,
          lastSeenAt: null,
          createdAt: now,
          revokedAt: null,
        })
        .returning();
      if (!row) {
        throw new Error('createMonitor: insert returned no row');
      }
      return reply.status(201).send(toMonitorJson(row));
    }
  );

  fastify.patch(
    '/monitors/:id',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'updateMonitor',
        tags: ['monitors'],
        params: z.object({ id: z.string().uuid() }),
        body: updateMonitorBodySchema,
        response: {
          200: monitorJsonSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      const [row] = await fastify.db
        .update(monitorDisplay)
        .set({ name: request.body.name })
        .where(eq(monitorDisplay.id, request.params.id))
        .returning();
      if (!row) {
        throw monitorNotFound();
      }
      return toMonitorJson(row);
    }
  );

  fastify.delete(
    '/monitors/:id',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'revokeMonitor',
        tags: ['monitors'],
        params: z.object({ id: z.string().uuid() }),
      },
    },
    async (request, reply) => {
      const [existing] = await fastify.db
        .select({ id: monitorDisplay.id })
        .from(monitorDisplay)
        .where(eq(monitorDisplay.id, request.params.id))
        .limit(1);
      if (!existing) {
        throw monitorNotFound();
      }

      await fastify.db
        .update(monitorDisplay)
        .set({ revokedAt: fastify.clock.now(), refreshTokenHash: null })
        .where(eq(monitorDisplay.id, existing.id));

      // Idempotent: calling this again on an already-revoked monitor is a
      // no-op in the DB, but still safe/harmless to broadcast again.
      fastify.wsHub.revokeMonitor(existing.id);

      return reply.status(204).send();
    }
  );

  fastify.post(
    '/monitors/:id/pairing-code',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'createMonitorPairingCode',
        tags: ['monitors'],
        params: z.object({ id: z.string().uuid() }),
        response: {
          201: monitorPairingCodeResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const [existing] = await fastify.db
        .select()
        .from(monitorDisplay)
        .where(eq(monitorDisplay.id, request.params.id))
        .limit(1);
      if (!existing) {
        throw monitorNotFound();
      }

      // Allowed for a revoked monitor too (ADR 0012): redeeming the code
      // lifts the revocation without a new row.
      const result = await fastify.db.transaction(async tx => {
        const { code, expiresAt } = await createPairingCodeForTarget(
          tx,
          { clock: fastify.clock, config: fastify.config },
          'monitor',
          existing.id
        );
        return { code, expiresAt };
      });

      return reply.status(201).send({
        monitor_id: existing.id,
        name: existing.name,
        code: formatPairingCode(result.code),
        expires_at: result.expiresAt.toISOString(),
      });
    }
  );
};
