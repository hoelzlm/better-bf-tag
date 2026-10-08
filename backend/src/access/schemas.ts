import { z } from 'zod';

/**
 * The public shape of a Person returned from login/me. Shared so the two
 * routes don't drift, and because these schemas feed OpenAPI generation.
 */
export const personSummarySchema = z.object({
  id: z.string(),
  display_name: z.string(),
  person_type: z.enum(['youth', 'supervisor']),
  permission: z.enum(['crew', 'preparation', 'dispatch', 'admin']),
});

export const errorResponseSchema = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
  }),
});
