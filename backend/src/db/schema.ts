import {
  pgTable,
  uuid,
  text,
  boolean,
  timestamp,
  pgEnum,
  check,
  uniqueIndex,
  index,
  smallint,
  integer,
  bigint,
  primaryKey,
  customType,
} from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

/** Raw binary data (ADR 0014): Folienbilder liegen als `bytea` in Postgres. */
const bytea = customType<{ data: Buffer }>({
  dataType() {
    return 'bytea';
  },
});

export const personTypeEnum = pgEnum('person_type', ['youth', 'supervisor']);
export const permissionEnum = pgEnum('permission', ['crew', 'preparation', 'dispatch', 'admin']);
export const devicePlatformEnum = pgEnum('device_platform', ['android', 'ios']);
export const pairingTargetTypeEnum = pgEnum('pairing_target_type', ['person', 'monitor']);
export const vehicleStatusEventKindEnum = pgEnum('vehicle_status_event_kind', [
  'status',
  'talk_request',
]);
export const vehicleStatusSourceEnum = pgEnum('vehicle_status_source', [
  'app',
  'dispatch',
  'system',
]);
export const bfDayStateEnum = pgEnum('bf_day_state', ['planning', 'running', 'ended']);
export const incidentStateEnum = pgEnum('incident_state', [
  'draft',
  'running',
  'closed',
  'discarded',
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

export const device = pgTable('device', {
  id: uuid('id').primaryKey().defaultRandom(),
  personId: uuid('person_id')
    .notNull()
    .references(() => person.id, { onDelete: 'cascade' }),
  platform: devicePlatformEnum('platform').notNull(),
  deviceName: text('device_name'),
  appVersion: text('app_version').notNull(),
  pushToken: text('push_token'),
  refreshTokenHash: text('refresh_token_hash').notNull().unique(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
});

export const monitorDisplay = pgTable('monitor_display', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  refreshTokenHash: text('refresh_token_hash').unique(),
  pairedAt: timestamp('paired_at', { withTimezone: true }),
  lastSeenAt: timestamp('last_seen_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
});

export const pairingCode = pgTable(
  'pairing_code',
  {
    codeHash: text('code_hash').primaryKey(),
    targetType: pairingTargetTypeEnum('target_type').notNull(),
    targetId: uuid('target_id').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    usedAt: timestamp('used_at', { withTimezone: true }),
  },
  table => [index('pairing_code_target_idx').on(table.targetType, table.targetId)]
);

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

export const bfDay = pgTable(
  'bf_day',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: text('name').notNull(),
    startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
    endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
    state: bfDayStateEnum('state').notNull().default('planning'),
    anonymizedAt: timestamp('anonymized_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  },
  table => [
    check('bf_day_period', sql`${table.endsAt} > ${table.startsAt}`),
    // Partial unique index (ADR 0013): the database guarantees at most one
    // running BF-Tag; the race is caught here and mapped to 409
    // bf_day_already_running at the route layer.
    uniqueIndex('bf_day_single_running')
      .on(table.state)
      .where(sql`${table.state} = 'running'`),
  ]
);

export const participation = pgTable(
  'participation',
  {
    bfDayId: uuid('bf_day_id')
      .notNull()
      .references(() => bfDay.id, { onDelete: 'cascade' }),
    personId: uuid('person_id')
      .notNull()
      .references(() => person.id),
  },
  table => [primaryKey({ columns: [table.bfDayId, table.personId] })]
);

export const shift = pgTable(
  'shift',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    bfDayId: uuid('bf_day_id')
      .notNull()
      .references(() => bfDay.id, { onDelete: 'cascade' }),
    name: text('name').notNull(),
    startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
    endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  },
  table => [
    check('shift_period', sql`${table.endsAt} > ${table.startsAt}`),
    index('shift_bf_day_idx').on(table.bfDayId),
  ]
);

export const crewAssignment = pgTable(
  'crew_assignment',
  {
    shiftId: uuid('shift_id')
      .notNull()
      .references(() => shift.id, { onDelete: 'cascade' }),
    vehicleId: uuid('vehicle_id')
      .notNull()
      .references(() => vehicle.id),
    personId: uuid('person_id')
      .notNull()
      .references(() => person.id),
    function: text('function').notNull(),
  },
  table => [primaryKey({ columns: [table.shiftId, table.vehicleId, table.personId] })]
);

export const slide = pgTable(
  'slide',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    title: text('title').notNull(),
    body: text('body').notNull().default(''),
    durationSeconds: integer('duration_seconds').notNull().default(10),
    sortOrder: integer('sort_order').notNull(),
    active: boolean('active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull(),
  },
  table => [check('slide_duration_seconds_range', sql`${table.durationSeconds} between 3 and 300`)]
);

export const incident = pgTable(
  'incident',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    bfDayId: uuid('bf_day_id')
      .notNull()
      .references(() => bfDay.id, { onDelete: 'cascade' }),
    number: integer('number').notNull(),
    keyword: text('keyword').notNull(),
    address: text('address').notNull(),
    report: text('report').notNull().default(''),
    script: text('script').notNull().default(''),
    state: incidentStateEnum('state').notNull().default('draft'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull(),
  },
  table => [
    uniqueIndex('incident_bf_day_number_unique').on(table.bfDayId, table.number),
    index('incident_bf_day_state_idx').on(table.bfDayId, table.state),
  ]
);

export const slideImage = pgTable('slide_image', {
  slideId: uuid('slide_id')
    .primaryKey()
    .references(() => slide.id, { onDelete: 'cascade' }),
  contentType: text('content_type').notNull(),
  data: bytea('data').notNull(),
  sha256: text('sha256').notNull(),
  sizeBytes: integer('size_bytes').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
});
