import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { asc, eq } from 'drizzle-orm';
import { vehicle } from '../db/schema.js';
import { requireAuth } from '../access/authenticate.js';
import { vehicleSchema, toVehicleJson } from './vehicle-schemas.js';

const snapshotResponseSchema = z.object({
  seq: z.number().int(),
  vehicles: z.array(vehicleSchema),
});

export const snapshotRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/snapshot',
    {
      preHandler: requireAuth,
      schema: {
        operationId: 'getSnapshot',
        tags: ['snapshot'],
        response: {
          200: snapshotResponseSchema,
        },
      },
    },
    async () => {
      return fastify.db.transaction(
        async tx => {
          const seq = await fastify.realtime.currentSeq(tx);
          const vehicles = await tx
            .select()
            .from(vehicle)
            .where(eq(vehicle.active, true))
            .orderBy(asc(vehicle.sortOrder));

          return { seq, vehicles: vehicles.map(toVehicleJson) };
        },
        { isolationLevel: 'repeatable read' }
      );
    }
  );
};
