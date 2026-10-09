import { z } from 'zod';
import type { AlarmJson } from '../alarms/alarm-json.js';

export {
  type AlarmState,
  type AlarmRow,
  type AlarmJson,
  type AlarmRecipientJson,
  type AlarmRecipientInput,
  toAlarmJson,
  loadAlarms,
} from '../alarms/alarm-json.js';

export const alarmRecipientJsonSchema = z.object({
  person_id: z.string(),
  display_name: z.string(),
  vehicle_id: z.string(),
  function: z.string(),
  has_device: z.boolean(),
  acknowledged_at: z.string().nullable(),
});

/**
 * The public shape of an Alarmierung (ADR 0017), shared between the alarm
 * routes, `GET /incidents/{id}` and the snapshot route. Backed by
 * `toAlarmJson`/`loadAlarms`, which already produce this shape.
 */
export const alarmJsonSchema: z.ZodType<AlarmJson> = z.object({
  id: z.string(),
  incident_id: z.string(),
  state: z.enum(['planned', 'triggered', 'missed', 'discarded']),
  scheduled_at: z.string().nullable(),
  triggered_at: z.string().nullable(),
  vehicle_ids: z.array(z.string()),
  recipients: z.array(alarmRecipientJsonSchema),
  push_delivered: z.number().int(),
  push_rejected: z.number().int(),
});

export const doubleCrewedJsonSchema = z.object({
  person_id: z.string(),
  display_name: z.string(),
  vehicle_ids: z.array(z.string()),
});

export const triggerAlarmBodySchema = z
  .object({
    id: z.string().uuid().optional(),
    vehicle_ids: z
      .array(z.string().uuid())
      .min(1)
      .max(50)
      .refine(ids => new Set(ids).size === ids.length, {
        message: 'vehicle_ids darf keine Duplikate enthalten.',
      }),
  })
  .strict();

export const triggerAlarmResponseSchema = z.object({
  alarm: alarmJsonSchema,
  double_crewed: z.array(doubleCrewedJsonSchema),
});

export const alarmIdParamsSchema = z.object({ id: z.string().uuid() });

export type DoubleCrewedJson = z.infer<typeof doubleCrewedJsonSchema>;
