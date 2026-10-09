CREATE TYPE "public"."alarm_state" AS ENUM('planned', 'triggered', 'missed', 'discarded');--> statement-breakpoint
CREATE TABLE "alarm" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"incident_id" uuid NOT NULL,
	"state" "alarm_state" NOT NULL,
	"scheduled_at" timestamp with time zone,
	"triggered_at" timestamp with time zone,
	"created_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "alarm_recipient" (
	"alarm_id" uuid NOT NULL,
	"person_id" uuid NOT NULL,
	"vehicle_id" uuid NOT NULL,
	"function" text NOT NULL,
	"has_device" boolean NOT NULL,
	"acknowledged_at" timestamp with time zone,
	"created_at" timestamp with time zone NOT NULL,
	CONSTRAINT "alarm_recipient_alarm_id_person_id_pk" PRIMARY KEY("alarm_id","person_id")
);
--> statement-breakpoint
CREATE TABLE "alarm_vehicle" (
	"alarm_id" uuid NOT NULL,
	"vehicle_id" uuid NOT NULL,
	CONSTRAINT "alarm_vehicle_alarm_id_vehicle_id_pk" PRIMARY KEY("alarm_id","vehicle_id")
);
--> statement-breakpoint
ALTER TABLE "alarm" ADD CONSTRAINT "alarm_incident_id_incident_id_fk" FOREIGN KEY ("incident_id") REFERENCES "public"."incident"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "alarm_recipient" ADD CONSTRAINT "alarm_recipient_alarm_id_alarm_id_fk" FOREIGN KEY ("alarm_id") REFERENCES "public"."alarm"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "alarm_recipient" ADD CONSTRAINT "alarm_recipient_person_id_person_id_fk" FOREIGN KEY ("person_id") REFERENCES "public"."person"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "alarm_recipient" ADD CONSTRAINT "alarm_recipient_vehicle_id_vehicle_id_fk" FOREIGN KEY ("vehicle_id") REFERENCES "public"."vehicle"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "alarm_vehicle" ADD CONSTRAINT "alarm_vehicle_alarm_id_alarm_id_fk" FOREIGN KEY ("alarm_id") REFERENCES "public"."alarm"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "alarm_vehicle" ADD CONSTRAINT "alarm_vehicle_vehicle_id_vehicle_id_fk" FOREIGN KEY ("vehicle_id") REFERENCES "public"."vehicle"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "alarm_incident_idx" ON "alarm" USING btree ("incident_id");