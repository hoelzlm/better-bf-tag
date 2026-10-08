import { z } from 'zod';

/**
 * The public shape of a Monitor (ADR 0012), shared by the monitors/auth
 * routes so they don't drift.
 */
export const monitorJsonSchema = z.object({
  id: z.string(),
  name: z.string(),
  paired: z.boolean(),
  paired_at: z.string().nullable(),
  last_seen_at: z.string().nullable(),
  revoked_at: z.string().nullable(),
  created_at: z.string(),
});

export type MonitorJson = z.infer<typeof monitorJsonSchema>;

export const monitorSummarySchema = z.object({
  id: z.string(),
  name: z.string(),
});

export type MonitorSummary = z.infer<typeof monitorSummarySchema>;

export interface MonitorRow {
  id: string;
  name: string;
  refreshTokenHash: string | null;
  pairedAt: Date | null;
  lastSeenAt: Date | null;
  createdAt: Date;
  revokedAt: Date | null;
}

export function toMonitorJson(row: MonitorRow): MonitorJson {
  return {
    id: row.id,
    name: row.name,
    paired: row.refreshTokenHash !== null,
    paired_at: row.pairedAt ? row.pairedAt.toISOString() : null,
    last_seen_at: row.lastSeenAt ? row.lastSeenAt.toISOString() : null,
    revoked_at: row.revokedAt ? row.revokedAt.toISOString() : null,
    created_at: row.createdAt.toISOString(),
  };
}

export function toMonitorSummary(row: { id: string; name: string }): MonitorSummary {
  return { id: row.id, name: row.name };
}
