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
  relative_to_alarm_id: z.string().nullable(),
  offset_minutes: z.number().int().nullable(),
});

export const doubleCrewedJsonSchema = z.object({
  person_id: z.string(),
  display_name: z.string(),
  vehicle_ids: z.array(z.string()),
});

/**
 * Body for `POST /incidents/{id}/alarms` (ADR 0022): with neither
 * `scheduled_at` nor `offset_minutes` this creates an immediate alarm (as
 * before); with exactly one of them it creates a `planned` alarm instead.
 * Both at once -> 400 `validation_error`.
 */
export const createAlarmBodySchema = z
  .object({
    id: z.string().uuid().optional(),
    vehicle_ids: z
      .array(z.string().uuid())
      .min(1)
      .max(50)
      .refine(ids => new Set(ids).size === ids.length, {
        message: 'vehicle_ids darf keine Duplikate enthalten.',
      }),
    scheduled_at: z.string().datetime().optional(),
    offset_minutes: z.number().int().min(1).max(1440).optional(),
  })
  .strict()
  .refine(body => body.scheduled_at === undefined || body.offset_minutes === undefined, {
    message: 'scheduled_at und offset_minutes schließen sich aus.',
  });

export const createAlarmResponseSchema = z.object({
  alarm: alarmJsonSchema,
  double_crewed: z.array(doubleCrewedJsonSchema),
});

/** `PATCH /alarms/{id}` (ADR 0022): only one of the two time fields may be set. */
export const updateAlarmBodySchema = z
  .object({
    scheduled_at: z.string().datetime().optional(),
    offset_minutes: z.number().int().min(1).max(1440).optional(),
    vehicle_ids: z
      .array(z.string().uuid())
      .min(1)
      .max(50)
      .refine(ids => new Set(ids).size === ids.length, {
        message: 'vehicle_ids darf keine Duplikate enthalten.',
      })
      .optional(),
  })
  .strict()
  .refine(body => body.scheduled_at === undefined || body.offset_minutes === undefined, {
    message: 'scheduled_at und offset_minutes schließen sich aus.',
  })
  .refine(
    body =>
      body.scheduled_at !== undefined ||
      body.offset_minutes !== undefined ||
      body.vehicle_ids !== undefined,
    {
      message: 'mindestens ein Feld ist erforderlich.',
    }
  );

export const updateAlarmResponseSchema = z.object({ alarm: alarmJsonSchema });

export const discardAlarmResponseSchema = z.object({ alarm: alarmJsonSchema });

export const triggerAlarmResponseSchema = z.object({
  alarm: alarmJsonSchema,
  double_crewed: z.array(doubleCrewedJsonSchema),
});

export const alarmIdParamsSchema = z.object({ id: z.string().uuid() });

export type DoubleCrewedJson = z.infer<typeof doubleCrewedJsonSchema>;
