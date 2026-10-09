import { z } from 'zod';

export type IncidentState = 'draft' | 'running' | 'closed' | 'discarded';

export interface IncidentRow {
  id: string;
  bfDayId: string;
  number: number;
  keyword: string;
  address: string;
  report: string;
  script: string;
  state: IncidentState;
  createdAt: Date;
  updatedAt: Date;
  closedAt: Date | null;
}

/**
 * The public shape of an Einsatz (ADR 0016). `script` is OPTIONAL: when the
 * caller doesn't pass `includeScript: true` to `toIncidentJson`, the key is
 * absent entirely (not `null`, not empty) — this is how the Drehbuch stays
 * out of every response for Mannschaft and Monitore.
 */
export const incidentJsonSchema = z.object({
  id: z.string(),
  bf_day_id: z.string(),
  number: z.number().int(),
  keyword: z.string(),
  address: z.string(),
  report: z.string(),
  state: z.enum(['draft', 'running', 'closed', 'discarded']),
  created_at: z.string(),
  updated_at: z.string(),
  closed_at: z.string().nullable(),
  script: z.string().optional(),
});

export type IncidentJson = z.infer<typeof incidentJsonSchema>;

/**
 * The single serializer for every Einsatz read path (REST, snapshot,
 * realtime projection — ADR 0016). Without `includeScript: true` the
 * `script` key is omitted entirely, never `null`/empty, so a direct row
 * export elsewhere would be the only way to leak it.
 */
export function toIncidentJson(row: IncidentRow, opts: { includeScript: boolean }): IncidentJson {
  return {
    id: row.id,
    bf_day_id: row.bfDayId,
    number: row.number,
    keyword: row.keyword,
    address: row.address,
    report: row.report,
    state: row.state,
    created_at: row.createdAt.toISOString(),
    updated_at: row.updatedAt.toISOString(),
    closed_at: row.closedAt ? row.closedAt.toISOString() : null,
    ...(opts.includeScript ? { script: row.script } : {}),
  };
}
