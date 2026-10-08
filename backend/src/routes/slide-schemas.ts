import { z } from 'zod';

/**
 * The public shape of a Folie's image metadata (ADR 0014): never the raw
 * bytes, so lists and the snapshot stay cheap. `version` is the first 16
 * hex characters of `sha256`, a short cache-busting token for clients.
 */
export const slideImageSchema = z.object({
  content_type: z.string(),
  size_bytes: z.number().int(),
  version: z.string(),
});

export type SlideImageJson = z.infer<typeof slideImageSchema>;

/**
 * The public shape of a Folie (slide), shared between the slide routes and
 * the snapshot route so the two don't drift.
 */
export const slideSchema = z.object({
  id: z.string(),
  title: z.string(),
  body: z.string(),
  duration_seconds: z.number().int(),
  sort_order: z.number().int(),
  active: z.boolean(),
  image: slideImageSchema.nullable(),
  created_at: z.string(),
  updated_at: z.string(),
});

export type SlideJson = z.infer<typeof slideSchema>;

export interface SlideRow {
  id: string;
  title: string;
  body: string;
  durationSeconds: number;
  sortOrder: number;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface SlideImageMetaRow {
  contentType: string;
  sizeBytes: number;
  sha256: string;
}

export function toSlideJson(row: SlideRow, image: SlideImageMetaRow | null): SlideJson {
  return {
    id: row.id,
    title: row.title,
    body: row.body,
    duration_seconds: row.durationSeconds,
    sort_order: row.sortOrder,
    active: row.active,
    image: image
      ? {
          content_type: image.contentType,
          size_bytes: image.sizeBytes,
          version: image.sha256.slice(0, 16),
        }
      : null,
    created_at: row.createdAt.toISOString(),
    updated_at: row.updatedAt.toISOString(),
  };
}
