import {
  pgTable,
  uuid,
  text,
  boolean,
  timestamp,
  pgEnum,
  check,
  uniqueIndex,
  smallint,
  integer,
  bigint,
} from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

export const personTypeEnum = pgEnum('person_type', ['youth', 'supervisor']);
export const permissionEnum = pgEnum('permission', ['crew', 'preparation', 'dispatch', 'admin']);
export const vehicleStatusEventKindEnum = pgEnum('vehicle_status_event_kind', [
  'status',
  'talk_request',
]);
export const vehicleStatusSourceEnum = pgEnum('vehicle_status_source', [
  'app',
  'dispatch',
  'system',
]);

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

export const vehicle = pgTable(
  'vehicle',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    fireDepartmentId: uuid('fire_department_id')
      .notNull()
      .references(() => fireDepartment.id),
    callSign: text('call_sign').notNull(),
    shortName: text('short_name').notNull(),
    type: text('type').notNull(),
    status: smallint('status').notNull().default(2),
    statusChangedAt: timestamp('status_changed_at', { withTimezone: true }),
    sortOrder: integer('sort_order').notNull(),
    active: boolean('active').notNull().default(true),
  },
  table => [check('vehicle_status_range', sql`${table.status} between 1 and 8`)]
);

export const vehicleStatusEvent = pgTable('vehicle_status_event', {
  id: uuid('id').primaryKey().defaultRandom(),
  vehicleId: uuid('vehicle_id')
    .notNull()
    .references(() => vehicle.id),
  kind: vehicleStatusEventKindEnum('kind').notNull(),
  status: smallint('status'),
  source: vehicleStatusSourceEnum('source').notNull(),
  personId: uuid('person_id').references(() => person.id, { onDelete: 'set null' }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
});

export const realtimeState = pgTable(
  'realtime_state',
  {
    id: smallint('id').primaryKey(),
    seq: bigint('seq', { mode: 'number' }).notNull().default(0),
  },
  table => [check('realtime_state_single_row', sql`${table.id} = 1`)]
);
