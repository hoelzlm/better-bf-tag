CREATE TYPE "public"."bf_day_state" AS ENUM('planning', 'running', 'ended');--> statement-breakpoint
CREATE TABLE "bf_day" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"starts_at" timestamp with time zone NOT NULL,
	"ends_at" timestamp with time zone NOT NULL,
	"state" "bf_day_state" DEFAULT 'planning' NOT NULL,
	"anonymized_at" timestamp with time zone,
	"created_at" timestamp with time zone NOT NULL,
	CONSTRAINT "bf_day_period" CHECK ("bf_day"."ends_at" > "bf_day"."starts_at")
);
--> statement-breakpoint
CREATE TABLE "crew_assignment" (
	"shift_id" uuid NOT NULL,
	"vehicle_id" uuid NOT NULL,
	"person_id" uuid NOT NULL,
	"function" text NOT NULL,
	CONSTRAINT "crew_assignment_shift_id_vehicle_id_person_id_pk" PRIMARY KEY("shift_id","vehicle_id","person_id")
);
--> statement-breakpoint
CREATE TABLE "participation" (
	"bf_day_id" uuid NOT NULL,
	"person_id" uuid NOT NULL,
	CONSTRAINT "participation_bf_day_id_person_id_pk" PRIMARY KEY("bf_day_id","person_id")
);
--> statement-breakpoint
CREATE TABLE "shift" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"bf_day_id" uuid NOT NULL,
	"name" text NOT NULL,
	"starts_at" timestamp with time zone NOT NULL,
	"ends_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	CONSTRAINT "shift_period" CHECK ("shift"."ends_at" > "shift"."starts_at")
);
--> statement-breakpoint
ALTER TABLE "crew_assignment" ADD CONSTRAINT "crew_assignment_shift_id_shift_id_fk" FOREIGN KEY ("shift_id") REFERENCES "public"."shift"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "crew_assignment" ADD CONSTRAINT "crew_assignment_vehicle_id_vehicle_id_fk" FOREIGN KEY ("vehicle_id") REFERENCES "public"."vehicle"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "crew_assignment" ADD CONSTRAINT "crew_assignment_person_id_person_id_fk" FOREIGN KEY ("person_id") REFERENCES "public"."person"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "participation" ADD CONSTRAINT "participation_bf_day_id_bf_day_id_fk" FOREIGN KEY ("bf_day_id") REFERENCES "public"."bf_day"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "participation" ADD CONSTRAINT "participation_person_id_person_id_fk" FOREIGN KEY ("person_id") REFERENCES "public"."person"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "shift" ADD CONSTRAINT "shift_bf_day_id_bf_day_id_fk" FOREIGN KEY ("bf_day_id") REFERENCES "public"."bf_day"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "bf_day_single_running" ON "bf_day" USING btree ("state") WHERE "bf_day"."state" = 'running';--> statement-breakpoint
CREATE INDEX "shift_bf_day_idx" ON "shift" USING btree ("bf_day_id");