import { z } from 'zod';

/**
 * The public shape of a Durchsage (ADR 0024), shared between the
 * announcements routes and the snapshot route so the two don't drift.
 */
export const announcementSchema = z.object({
  id: z.string(),
  bf_day_id: z.string(),
  shift_id: z.string().nullable(),
  text: z.string(),
  created_by: z.string(),
  created_at: z.string(),
});

export type AnnouncementJson = z.infer<typeof announcementSchema>;

export interface AnnouncementRow {
  id: string;
  bfDayId: string;
  shiftId: string | null;
  text: string;
  createdBy: string;
  createdAt: Date;
}

export function toAnnouncementJson(row: AnnouncementRow): AnnouncementJson {
  return {
    id: row.id,
    bf_day_id: row.bfDayId,
    shift_id: row.shiftId,
    text: row.text,
    created_by: row.createdBy,
    created_at: row.createdAt.toISOString(),
  };
}
