import {
  pgTable,
  uuid,
  text,
  boolean,
  timestamp,
  pgEnum,
  check,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const personTypeEnum = pgEnum('person_type', ['youth', 'supervisor']);
export const permissionEnum = pgEnum('permission', ['crew', 'preparation', 'dispatch', 'admin']);

export const fireDepartment = pgTable(
  'fire_department',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: text('name').notNull(),
    isOwn: boolean('is_own').notNull().default(false),
  },
  table => [
    uniqueIndex('fire_department_is_own_unique')
      .on(table.isOwn)
      .where(sql`${table.isOwn} = true`),
  ]
);

export const person = pgTable(
  'person',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    fireDepartmentId: uuid('fire_department_id')
      .notNull()
      .references(() => fireDepartment.id),
    displayName: text('display_name').notNull(),
    personType: personTypeEnum('person_type').notNull(),
    permission: permissionEnum('permission').notNull(),
    username: text('username').unique(),
    passwordHash: text('password_hash'),
    active: boolean('active').notNull().default(true),
  },
  table => [
    check(
      'person_admin_requires_supervisor',
      sql`${table.permission} <> 'admin' OR ${table.personType} = 'supervisor'`
    ),
  ]
);

export const webSession = pgTable('web_session', {
  id: uuid('id').primaryKey().defaultRandom(),
  personId: uuid('person_id')
    .notNull()
    .references(() => person.id, { onDelete: 'cascade' }),
  refreshTokenHash: text('refresh_token_hash').notNull().unique(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
});
