CREATE TYPE "public"."vehicle_status_event_kind" AS ENUM('status', 'talk_request');--> statement-breakpoint
CREATE TYPE "public"."vehicle_status_source" AS ENUM('app', 'dispatch', 'system');--> statement-breakpoint
CREATE TABLE "realtime_state" (
	"id" smallint PRIMARY KEY NOT NULL,
	"seq" bigint DEFAULT 0 NOT NULL,
	CONSTRAINT "realtime_state_single_row" CHECK ("realtime_state"."id" = 1)
);
--> statement-breakpoint
CREATE TABLE "vehicle" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"fire_department_id" uuid NOT NULL,
	"call_sign" text NOT NULL,
	"short_name" text NOT NULL,
	"type" text NOT NULL,
	"status" smallint DEFAULT 2 NOT NULL,
	"status_changed_at" timestamp with time zone,
	"sort_order" integer NOT NULL,
	"active" boolean DEFAULT true NOT NULL,
	CONSTRAINT "vehicle_status_range" CHECK ("vehicle"."status" between 1 and 8)
);
--> statement-breakpoint
CREATE TABLE "vehicle_status_event" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"vehicle_id" uuid NOT NULL,
	"kind" "vehicle_status_event_kind" NOT NULL,
	"status" smallint,
	"source" "vehicle_status_source" NOT NULL,
	"person_id" uuid,
	"created_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
ALTER TABLE "vehicle" ADD CONSTRAINT "vehicle_fire_department_id_fire_department_id_fk" FOREIGN KEY ("fire_department_id") REFERENCES "public"."fire_department"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vehicle_status_event" ADD CONSTRAINT "vehicle_status_event_vehicle_id_vehicle_id_fk" FOREIGN KEY ("vehicle_id") REFERENCES "public"."vehicle"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "vehicle_status_event" ADD CONSTRAINT "vehicle_status_event_person_id_person_id_fk" FOREIGN KEY ("person_id") REFERENCES "public"."person"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
INSERT INTO "realtime_state" ("id", "seq") VALUES (1, 0);