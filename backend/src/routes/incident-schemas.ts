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

export const createIncidentBodySchema = z.object({
  keyword: keywordSchema,
  address: addressSchema,
  report: reportSchema.optional(),
  script: scriptSchema.optional(),
});

export const updateIncidentBodySchema = z.object({
  keyword: keywordSchema.optional(),
  address: addressSchema.optional(),
  report: reportSchema.optional(),
  script: scriptSchema.optional(),
});

export const incidentStateQuerySchema = z.object({
  state: z.enum(['draft', 'running', 'closed', 'discarded']).optional(),
});

export const dayParamsSchema = z.object({ day: z.string() });
export const incidentIdParamsSchema = z.object({ id: z.string().uuid() });
