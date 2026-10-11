import { z } from 'zod';
import { programItemSchema, programItemTypeSchema } from '../program/program-item-json.js';

export { programItemSchema };
export type { ProgramItemJson, ProgramItemRow } from '../program/program-item-json.js';

export const createProgramItemBodySchema = z.object({
  title: z.string().trim().min(1).max(80),
  type: programItemTypeSchema,
  starts_at: z.string().datetime({ offset: true }),
  ends_at: z.string().datetime({ offset: true }),
});

export const updateProgramItemBodySchema = z.object({
  title: z.string().trim().min(1).max(80).optional(),
  type: programItemTypeSchema.optional(),
  starts_at: z.string().datetime({ offset: true }).optional(),
  ends_at: z.string().datetime({ offset: true }).optional(),
});

export const programItemListResponseSchema = z.array(programItemSchema);
