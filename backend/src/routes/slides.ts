import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { createHash } from 'node:crypto';
import { asc, eq, inArray, sql } from 'drizzle-orm';
import { slide, slideImage } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import {
  slideSchema,
  toSlideJson,
  type SlideRow,
  type SlideImageMetaRow,
} from './slide-schemas.js';
import { ApiError } from '../errors.js';
import type { Emit, Tx } from '../realtime/realtime.js';

const createSlideBodySchema = z.object({
  title: z.string().trim().min(1).max(200),
  body: z.string().max(5000).optional(),
  duration_seconds: z.number().int().min(3).max(300).optional(),
  active: z.boolean().optional(),
});

const updateSlideBodySchema = z.object({
  title: z.string().trim().min(1).max(200).optional(),
  body: z.string().max(5000).optional(),
  duration_seconds: z.number().int().min(3).max(300).optional(),
  active: z.boolean().optional(),
});

const reorderBodySchema = z.object({
  slide_ids: z.array(z.string().uuid()),
});

const slideListResponseSchema = z.array(slideSchema);

const PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const JPEG_MAGIC = Buffer.from([0xff, 0xd8, 0xff]);

function detectImageContentType(buf: Buffer): string | null {
  if (buf.length >= PNG_MAGIC.length && buf.subarray(0, PNG_MAGIC.length).equals(PNG_MAGIC)) {
    return 'image/png';
  }
  if (buf.length >= JPEG_MAGIC.length && buf.subarray(0, JPEG_MAGIC.length).equals(JPEG_MAGIC)) {
    return 'image/jpeg';
  }
  if (
    buf.length >= 12 &&
    buf.toString('ascii', 0, 4) === 'RIFF' &&
    buf.toString('ascii', 8, 12) === 'WEBP'
  ) {
    return 'image/webp';
  }
  return null;
}

function slideNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Folie nicht gefunden.');
}

function unsupportedImageType(): ApiError {
  return new ApiError(
    415,
    'unsupported_image_type',
    'Nicht unterstützter Bildtyp oder Magic Bytes stimmen nicht zum Content-Type.'
  );
}

async function loadSlide(tx: Tx, id: string): Promise<SlideRow | undefined> {
  const [row] = await tx.select().from(slide).where(eq(slide.id, id)).limit(1);
  return row;
}

async function attachImageMeta(
  tx: Tx,
  rows: SlideRow[]
): Promise<Array<{ slide: SlideRow; image: SlideImageMetaRow | null }>> {
  if (rows.length === 0) return [];
  const ids = rows.map(row => row.id);
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
  return rows.map(row => ({ slide: row, image: byId.get(row.id) ?? null }));
}

async function loadAllSlidesJson(tx: Tx) {
  const rows = await tx.select().from(slide).orderBy(asc(slide.sortOrder));
  const withImages = await attachImageMeta(tx, rows);
  return withImages.map(({ slide: row, image }) => toSlideJson(row, image));
}

async function loadActiveSlidesJson(tx: Tx) {
  const rows = await tx
    .select()
    .from(slide)
    .where(eq(slide.active, true))
    .orderBy(asc(slide.sortOrder));
  const withImages = await attachImageMeta(tx, rows);
  return withImages.map(({ slide: row, image }) => toSlideJson(row, image));
}

/** Emits the single `slides.changed` event (ADR 0014) with the full active list. */
async function emitSlidesChanged(tx: Tx, emit: Emit): Promise<void> {
  const slides = await loadActiveSlidesJson(tx);
  await emit('slides.changed', { slides });
}

export const slideRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/slides',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'listSlides',
        tags: ['slides'],
        response: {
          200: slideListResponseSchema,
        },
      },
    },
    async () => {
      return loadAllSlidesJson(fastify.db as unknown as Tx);
    }
  );

  fastify.post(
    '/slides',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'createSlide',
        tags: ['slides'],
        body: createSlideBodySchema,
        response: {
          201: slideSchema,
        },
      },
    },
    async (request, reply) => {
      const created = await fastify.realtime.mutate(async (tx, emit) => {
        const [maxRow] = await tx
          .select({ max: sql<number | null>`max(${slide.sortOrder})` })
          .from(slide);
        const nextSortOrder = (maxRow?.max ?? -1) + 1;
        const now = fastify.clock.now();

        const [row] = await tx
          .insert(slide)
          .values({
            title: request.body.title,
            body: request.body.body ?? '',
            durationSeconds: request.body.duration_seconds ?? 10,
            sortOrder: nextSortOrder,
            active: request.body.active ?? true,
            createdAt: now,
            updatedAt: now,
          })
          .returning();
        if (!row) {
          throw new Error('createSlide: insert returned no row');
        }

        await emitSlidesChanged(tx, emit);
        return toSlideJson(row, null);
      });

      return reply.status(201).send(created);
    }
  );

  fastify.patch(
    '/slides/:id',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'updateSlide',
        tags: ['slides'],
        params: z.object({ id: z.string().uuid() }),
        body: updateSlideBodySchema,
        response: {
          200: slideSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadSlide(tx, request.params.id);
        if (!existing) {
          throw slideNotFound();
        }

        const patch: Partial<SlideRow> = { updatedAt: fastify.clock.now() };
        if (request.body.title !== undefined) patch.title = request.body.title;
        if (request.body.body !== undefined) patch.body = request.body.body;
        if (request.body.duration_seconds !== undefined) {
          patch.durationSeconds = request.body.duration_seconds;
        }
        if (request.body.active !== undefined) patch.active = request.body.active;

        const [row] = await tx
          .update(slide)
          .set(patch)
          .where(eq(slide.id, request.params.id))
          .returning();
        if (!row) {
          throw slideNotFound();
        }

        const [imageRows] = await attachImageMeta(tx, [row]);
        await emitSlidesChanged(tx, emit);
        return toSlideJson(row, imageRows?.image ?? null);
      });
    }
  );

  fastify.delete(
    '/slides/:id',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'deleteSlide',
        tags: ['slides'],
        params: z.object({ id: z.string().uuid() }),
      },
    },
    async (request, reply) => {
      await fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadSlide(tx, request.params.id);
        if (!existing) {
          throw slideNotFound();
        }

        await tx.delete(slide).where(eq(slide.id, request.params.id));
        await emitSlidesChanged(tx, emit);
      });

      return reply.status(204).send();
    }
  );

  fastify.put(
    '/slides/order',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'reorderSlides',
        tags: ['slides'],
        body: reorderBodySchema,
        response: {
          200: slideListResponseSchema,
          400: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await tx.select().from(slide);
        const existingIds = new Set(existing.map(row => row.id));
        const requestedIds = request.body.slide_ids;
        const requestedSet = new Set(requestedIds);

        if (
          requestedIds.length !== existingIds.size ||
          requestedSet.size !== requestedIds.length ||
          [...existingIds].some(id => !requestedSet.has(id))
        ) {
          throw new ApiError(
            400,
            'validation_error',
            'slide_ids muss genau die Menge aller Folien-IDs enthalten.'
          );
        }

        const byId = new Map(existing.map(row => [row.id, row]));
        for (let index = 0; index < requestedIds.length; index++) {
          const id = requestedIds[index];
          if (id === undefined) continue;
          const current = byId.get(id);
          if (!current || current.sortOrder === index) continue;
          await tx.update(slide).set({ sortOrder: index }).where(eq(slide.id, id));
        }

        await emitSlidesChanged(tx, emit);
        return loadAllSlidesJson(tx);
      });
    }
  );

  await fastify.register(async imageUpload => {
    imageUpload.addContentTypeParser(
      ['image/png', 'image/jpeg', 'image/webp'],
      { parseAs: 'buffer' },
      (_request, body, done) => done(null, body)
    );
    // Anything else (image/gif, text/plain, missing content-type, …) is
    // rejected as unsupported before the handler ever runs (ADR 0014).
    imageUpload.addContentTypeParser('*', { parseAs: 'buffer' }, (_request, _body, done) => {
      done(unsupportedImageType());
    });

    imageUpload.post(
      '/slides/:id/image',
      {
        preHandler: [requireAuth(), requirePermission('admin')],
        bodyLimit: fastify.config.SLIDE_IMAGE_MAX_BYTES,
        schema: {
          operationId: 'setSlideImage',
          tags: ['slides'],
          params: z.object({ id: z.string().uuid() }),
          response: {
            200: slideSchema,
            400: errorResponseSchema,
            404: errorResponseSchema,
            413: errorResponseSchema,
            415: errorResponseSchema,
          },
        },
      },
      async request => {
        const { id } = request.params as { id: string };
        const buf = request.body as Buffer;
        if (!Buffer.isBuffer(buf) || buf.length === 0) {
          throw new ApiError(400, 'validation_error', 'Leerer Bild-Upload.');
        }

        const rawContentType = request.headers['content-type'] ?? '';
        const contentType = rawContentType.split(';')[0]?.trim() ?? '';
        const detected = detectImageContentType(buf);
        if (detected === null || detected !== contentType) {
          throw unsupportedImageType();
        }

        return fastify.realtime.mutate(async (tx, emit) => {
          const existing = await loadSlide(tx, id);
          if (!existing) {
            throw slideNotFound();
          }

          const sha256 = createHash('sha256').update(buf).digest('hex');
          const now = fastify.clock.now();

          await tx
            .insert(slideImage)
            .values({
              slideId: existing.id,
              contentType: detected,
              data: buf,
              sha256,
              sizeBytes: buf.length,
              createdAt: now,
            })
            .onConflictDoUpdate({
              target: slideImage.slideId,
              set: { contentType: detected, data: buf, sha256, sizeBytes: buf.length },
            });

          await emitSlidesChanged(tx, emit);
          return toSlideJson(existing, { contentType: detected, sizeBytes: buf.length, sha256 });
        });
      }
    );
  });

  fastify.delete(
    '/slides/:id/image',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'deleteSlideImage',
        tags: ['slides'],
        params: z.object({ id: z.string().uuid() }),
      },
    },
    async (request, reply) => {
      await fastify.realtime.mutate(async (tx, emit) => {
        await tx.delete(slideImage).where(eq(slideImage.slideId, request.params.id));
        await emitSlidesChanged(tx, emit);
      });

      return reply.status(204).send();
    }
  );

  fastify.get(
    '/slides/:id/image',
    {
      preHandler: [
        requireAuth({ allowMonitor: true }),
        async request => {
          const auth = request.auth;
          if (auth && auth.kind === 'person' && auth.permission !== 'admin') {
            throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
          }
        },
      ],
      schema: {
        operationId: 'getSlideImage',
        tags: ['slides'],
        params: z.object({ id: z.string().uuid() }),
      },
    },
    async (request, reply) => {
      const [existingSlide] = await fastify.db
        .select({ id: slide.id })
        .from(slide)
        .where(eq(slide.id, request.params.id))
        .limit(1);
      if (!existingSlide) {
        throw slideNotFound();
      }

      const [imageRow] = await fastify.db
        .select()
        .from(slideImage)
        .where(eq(slideImage.slideId, request.params.id))
        .limit(1);
      if (!imageRow) {
        throw new ApiError(404, 'not_found', 'Kein Bild vorhanden.');
      }

      const etag = `"${imageRow.sha256}"`;
      reply.header('ETag', etag);
      reply.header('Cache-Control', 'private, max-age=0, must-revalidate');

      if (request.headers['if-none-match'] === etag) {
        return reply.status(304).send();
      }

      reply.header('Content-Type', imageRow.contentType);
      return reply.status(200).send(imageRow.data);
    }
  );
};
