import { z } from 'zod';

export const geocodeQuerySchema = z.object({
  q: z
    .string()
    .trim()
    .min(3, 'q muss mindestens 3 Zeichen lang sein.')
    .max(200, 'q darf höchstens 200 Zeichen lang sein.'),
});

export const geocodeResultSchema = z.object({
  label: z.string(),
  latitude: z.number(),
  longitude: z.number(),
});

export const geocodeResponseSchema = z.object({
  results: z.array(geocodeResultSchema),
});
