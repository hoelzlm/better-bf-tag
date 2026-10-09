import { z } from 'zod';
import type { PersonType, Permission } from '../access/types.js';

export const bfDayStateSchema = z.enum(['planning', 'running', 'ended']);
export type BfDayState = z.infer<typeof bfDayStateSchema>;

/**
 * The public shape of a BF-Tag, shared between the bf-days routes so they
 * don't drift (ADR 0013).
 */
export const bfDayJsonSchema = z.object({
  id: z.string(),
  name: z.string(),
  starts_at: z.string(),
  ends_at: z.string(),
  state: bfDayStateSchema,
  anonymized_at: z.string().nullable(),
  created_at: z.string(),
});

export type BfDayJson = z.infer<typeof bfDayJsonSchema>;

export interface BfDayRow {
  id: string;
  name: string;
  startsAt: Date;
  endsAt: Date;
  state: BfDayState;
  anonymizedAt: Date | null;
  createdAt: Date;
}

export function toBfDayJson(row: BfDayRow): BfDayJson {
  return {
    id: row.id,
    name: row.name,
    starts_at: row.startsAt.toISOString(),
    ends_at: row.endsAt.toISOString(),
    state: row.state,
    anonymized_at: row.anonymizedAt ? row.anonymizedAt.toISOString() : null,
    created_at: row.createdAt.toISOString(),
  };
}

/** A Teilnahme list entry (ADR 0013): the Person plus the fields the Leitstelle needs to assign crew. */
export const participantJsonSchema = z.object({
  person_id: z.string(),
  display_name: z.string(),
  person_type: z.enum(['youth', 'supervisor']),
  permission: z.enum(['crew', 'preparation', 'dispatch', 'admin']),
  fire_department_id: z.string(),
});

export type ParticipantJson = z.infer<typeof participantJsonSchema>;

export interface ParticipantRow {
  id: string;
  displayName: string;
  personType: PersonType;
  permission: Permission;
  fireDepartmentId: string;
}

export function toParticipantJson(row: ParticipantRow): ParticipantJson {
  return {
    person_id: row.id,
    display_name: row.displayName,
    person_type: row.personType,
    permission: row.permission,
    fire_department_id: row.fireDepartmentId,
  };
}

/** ADR 0020: the Anonymisierung preview/result shape, shared by both routes. */
export const anonymizationSummaryJsonSchema = z.object({
  participations: z.number().int().nonnegative(),
  crew_assignments: z.number().int().nonnegative(),
  alarm_recipients: z.number().int().nonnegative(),
  status_events: z.number().int().nonnegative(),
  persons_deleted: z.number().int().nonnegative(),
});

export type AnonymizationSummaryJson = z.infer<typeof anonymizationSummaryJsonSchema>;

export const anonymizeBfDayResponseSchema = z.object({
  bf_day: bfDayJsonSchema,
  summary: anonymizationSummaryJsonSchema,
});

export function toAnonymizationSummaryJson(summary: {
  participations: number;
  crewAssignments: number;
  alarmRecipients: number;
  statusEvents: number;
  personsDeleted: number;
}): AnonymizationSummaryJson {
  return {
    participations: summary.participations,
    crew_assignments: summary.crewAssignments,
    alarm_recipients: summary.alarmRecipients,
    status_events: summary.statusEvents,
    persons_deleted: summary.personsDeleted,
  };
}
