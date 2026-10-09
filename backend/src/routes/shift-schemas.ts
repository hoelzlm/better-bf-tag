import { z } from 'zod';
import type { ShiftJson } from '../shifts/shift-json.js';

export { type ShiftJson, type ShiftCrewMemberJson, loadShiftJson } from '../shifts/shift-json.js';

const shiftCrewMemberJsonSchema = z.object({
  vehicle_id: z.string(),
  person_id: z.string(),
  display_name: z.string(),
  function: z.string(),
});

/**
 * The public shape of a Schicht with Besatzung (ADR 0013), shared between
 * the shift routes and the snapshot route so the two don't drift. Backed
 * by `loadShiftJson`, which already produces this shape.
 */
export const shiftJsonSchema: z.ZodType<ShiftJson> = z.object({
  id: z.string(),
  bf_day_id: z.string(),
  name: z.string(),
  starts_at: z.string(),
  ends_at: z.string(),
  crew: z.array(shiftCrewMemberJsonSchema),
});

export const crewAssignmentInputSchema = z.object({
  vehicle_id: z.string().uuid(),
  person_id: z.string().uuid(),
  function: z.string().trim().min(1).max(16),
});

export const setShiftCrewBodySchema = z.object({
  assignments: z.array(crewAssignmentInputSchema),
});

export const shiftDeletedEventSchema = z.object({
  id: z.string(),
  bf_day_id: z.string(),
});
