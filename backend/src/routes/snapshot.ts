import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { asc, eq, inArray } from 'drizzle-orm';
import { vehicle, slide, slideImage, bfDay, shift } from '../db/schema.js';
import { requireAuth } from '../access/authenticate.js';
import { vehicleSchema, toVehicleJson } from './vehicle-schemas.js';
import { slideSchema, toSlideJson, type SlideRow } from './slide-schemas.js';
import { bfDayJsonSchema, toBfDayJson } from './bf-day-schemas.js';
import { loadShiftJson, shiftJsonSchema } from './shift-schemas.js';
import { currentShift } from '../shifts/current-shift.js';

const snapshotResponseSchema = z.object({
  seq: z.number().int(),
  vehicles: z.array(vehicleSchema),
  slides: z.array(slideSchema),
  bf_day: bfDayJsonSchema.nullable(),
  shifts: z.array(shiftJsonSchema),
  current_shift_id: z.string().nullable(),
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

          const [runningBfDay] = await tx
            .select()
            .from(bfDay)
            .where(eq(bfDay.state, 'running'))
            .limit(1);

          let shiftsJson: Array<Awaited<ReturnType<typeof loadShiftJson>>> = [];
          let currentShiftId: string | null = null;

          if (runningBfDay) {
            const shiftRows = await tx
              .select()
              .from(shift)
              .where(eq(shift.bfDayId, runningBfDay.id));

            const loaded = [];
            for (const row of shiftRows) {
              const json = await loadShiftJson(tx, row.id);
              if (json) loaded.push(json);
            }
            shiftsJson = loaded;

            const current = currentShift(
              shiftRows.map(row => ({
                id: row.id,
                startsAt: row.startsAt,
                endsAt: row.endsAt,
              })),
              fastify.clock.now()
            );
            currentShiftId = current ? current.id : null;
          }

          return {
            seq,
            vehicles: vehicles.map(toVehicleJson),
            slides,
            bf_day: runningBfDay ? toBfDayJson(runningBfDay) : null,
            shifts: shiftsJson.filter((s): s is NonNullable<typeof s> => s !== undefined),
            current_shift_id: currentShiftId,
          };
        },
        { isolationLevel: 'repeatable read' }
      );
    }
  );
};
