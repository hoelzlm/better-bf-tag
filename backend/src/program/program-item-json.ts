import { z } from 'zod';
import { asc, eq } from 'drizzle-orm';
import { programItem } from '../db/schema.js';
import type { Emit, Tx } from '../realtime/realtime.js';

export const programItemTypeSchema = z.enum(['meal', 'training', 'maintenance', 'rest', 'other']);
export type ProgramItemType = z.infer<typeof programItemTypeSchema>;

/**
 * The public shape of a Programmpunkt (ADR 0025), shared between the
 * program-items routes and the snapshot route so the two don't drift.
 */
export const programItemSchema = z.object({
  id: z.string(),
  bf_day_id: z.string(),
  title: z.string(),
  type: programItemTypeSchema,
  starts_at: z.string(),
  ends_at: z.string(),
});

export type ProgramItemJson = z.infer<typeof programItemSchema>;

export interface ProgramItemRow {
  id: string;
  bfDayId: string;
  title: string;
  type: ProgramItemType;
  startsAt: Date;
  endsAt: Date;
}

export function toProgramItemJson(row: ProgramItemRow): ProgramItemJson {
  return {
    id: row.id,
    bf_day_id: row.bfDayId,
    title: row.title,
    type: row.type,
    starts_at: row.startsAt.toISOString(),
    ends_at: row.endsAt.toISOString(),
  };
}

/** Sorted `starts_at`, `ends_at`, `id` ascending (ADR 0025) — GET, Event and Snapshot all share this order. */
export async function loadProgramItems(tx: Tx, bfDayId: string): Promise<ProgramItemJson[]> {
  const rows = await tx
    .select()
    .from(programItem)
    .where(eq(programItem.bfDayId, bfDayId))
    .orderBy(asc(programItem.startsAt), asc(programItem.endsAt), asc(programItem.id));
  return rows.map(toProgramItemJson);
}

/** Emits the single `program.changed` event (ADR 0025) with the full sorted list of this BF-Tag. */
export async function emitProgramChanged(emit: Emit, tx: Tx, bfDayId: string): Promise<void> {
  const items = await loadProgramItems(tx, bfDayId);
  await emit('program.changed', { bf_day_id: bfDayId, items });
}
