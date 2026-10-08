import { z } from 'zod';
import type { PersonType, Permission } from '../access/types.js';

/**
 * The public shape of a Person (never password data), shared by the
 * persons routes so they don't drift.
 */
export const personJsonSchema = z.object({
  id: z.string(),
  display_name: z.string(),
  person_type: z.enum(['youth', 'supervisor']),
  permission: z.enum(['crew', 'preparation', 'dispatch', 'admin']),
  active: z.boolean(),
  has_web_access: z.boolean(),
  username: z.string().nullable(),
});

export type PersonJson = z.infer<typeof personJsonSchema>;

export interface PersonRow {
  id: string;
  displayName: string;
  personType: PersonType;
  permission: Permission;
  username: string | null;
  passwordHash: string | null;
  active: boolean;
}

export function toPersonJson(row: PersonRow): PersonJson {
  return {
    id: row.id,
    display_name: row.displayName,
    person_type: row.personType,
    permission: row.permission,
    active: row.active,
    has_web_access: row.username !== null,
    username: row.username,
  };
}
