import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { eq } from 'drizzle-orm';
import { device } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { ApiError } from '../errors.js';

/**
 * `DELETE /devices/{id}` (ADR 0010): the person-scoped device routes
 * (`/persons/{id}/pairing-code`, `/persons/pairing-codes`,
 * `/persons/{id}/devices`) live in `routes/persons.ts`; this file only
 * covers the `/devices/{id}` resource itself, which isn't nested under a
 * person in its path.
 */
export const deviceRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.delete(
    '/devices/:id',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'revokeDevice',
        tags: ['devices'],
        params: z.object({ id: z.string().uuid() }),
      },
    },
    async (request, reply) => {
      const [existing] = await fastify.db
        .select({ id: device.id, revokedAt: device.revokedAt })
        .from(device)
        .where(eq(device.id, request.params.id))
        .limit(1);
      if (!existing) {
        throw new ApiError(404, 'not_found', 'Gerät nicht gefunden.');
      }

      if (!existing.revokedAt) {
        await fastify.db
          .update(device)
          .set({ revokedAt: fastify.clock.now() })
          .where(eq(device.id, existing.id));
      }

      // Idempotent: calling this again on an already-revoked device is a
      // no-op in the DB, but still safe/harmless to broadcast again.
      fastify.wsHub.revokeDevice(existing.id);

      return reply.status(204).send();
    }
  );
};
