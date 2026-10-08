import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { asc, eq, inArray } from 'drizzle-orm';
import { vehicle, slide, slideImage } from '../db/schema.js';
import { requireAuth } from '../access/authenticate.js';
import { vehicleSchema, toVehicleJson } from './vehicle-schemas.js';
import { slideSchema, toSlideJson, type SlideRow } from './slide-schemas.js';

const snapshotResponseSchema = z.object({
  seq: z.number().int(),
  vehicles: z.array(vehicleSchema),
  slides: z.array(slideSchema),
});

export const snapshotRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/snapshot',
    {
      preHandler: requireAuth({ allowMonitor: true }),
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

          const slideRows: SlideRow[] = await tx
            .select()
            .from(slide)
            .where(eq(slide.active, true))
            .orderBy(asc(slide.sortOrder));

          let slides: ReturnType<typeof toSlideJson>[] = [];
          if (slideRows.length > 0) {
            const ids = slideRows.map(row => row.id);
            const imageRows = await tx
              .select({
                slideId: slideImage.slideId,
                contentType: slideImage.contentType,
                sizeBytes: slideImage.sizeBytes,
                sha256: slideImage.sha256,
              })
              .from(slideImage)
              .where(inArray(slideImage.slideId, ids));
            const byId = new Map(imageRows.map(row => [row.slideId, row]));
            slides = slideRows.map(row => toSlideJson(row, byId.get(row.id) ?? null));
          }

          return { seq, vehicles: vehicles.map(toVehicleJson), slides };
        },
        { isolationLevel: 'repeatable read' }
      );
    }
  );
};
