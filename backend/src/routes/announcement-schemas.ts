import { z } from 'zod';
import { announcementSchema } from '../announcements/announcement-json.js';

export { announcementSchema };
export type { AnnouncementJson, AnnouncementRow } from '../announcements/announcement-json.js';

export const createAnnouncementBodySchema = z.object({
  text: z.string().trim().min(1).max(500),
  shift_id: z.string().uuid().nullable().optional(),
});

export const announcementListResponseSchema = z.array(announcementSchema);
