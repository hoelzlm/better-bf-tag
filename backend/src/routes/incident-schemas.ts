import { z } from 'zod';

export {
  type IncidentState,
  type IncidentRow,
  type IncidentJson,
  incidentJsonSchema,
  toIncidentJson,
} from '../incidents/incident-json.js';

const keywordSchema = z.string().trim().min(1).max(80);
const addressSchema = z.string().trim().min(1).max(200);
const reportSchema = z.string().trim().max(4000);
const scriptSchema = z.string().trim().max(20000);
const latitudeSchema = z.number().min(-90).max(90).nullable();
const longitudeSchema = z.number().min(-180).max(180).nullable();

/**
 * Einsatzort (ADR 0026): genau eine der beiden Koordinaten gesetzt (nicht
 * null) -> 400 `validation_error`. Beide `undefined` (nicht angegeben) oder
 * beide `null`/gesetzt sind erlaubt.
 */
function exactlyOneCoordinateIsInvalid(
  latitude: number | null | undefined,
  longitude: number | null | undefined
): boolean {
  const latSet = latitude !== undefined && latitude !== null;
  const lngSet = longitude !== undefined && longitude !== null;
  return latSet !== lngSet;
}

export const createIncidentBodySchema = z
  .object({
    keyword: keywordSchema,
    address: addressSchema,
    report: reportSchema.optional(),
    script: scriptSchema.optional(),
    latitude: latitudeSchema.optional(),
    longitude: longitudeSchema.optional(),
  })
  .refine(body => !exactlyOneCoordinateIsInvalid(body.latitude, body.longitude), {
    message: 'latitude und longitude müssen gemeinsam gesetzt sein.',
  });

export const updateIncidentBodySchema = z.object({
  keyword: keywordSchema.optional(),
  address: addressSchema.optional(),
  report: reportSchema.optional(),
  script: scriptSchema.optional(),
  latitude: latitudeSchema.optional(),
  longitude: longitudeSchema.optional(),
});

export const incidentStateQuerySchema = z.object({
  state: z.enum(['draft', 'running', 'closed', 'discarded']).optional(),
});

export const dayParamsSchema = z.object({ day: z.string() });
export const incidentIdParamsSchema = z.object({ id: z.string().uuid() });
