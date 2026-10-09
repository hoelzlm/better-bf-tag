CREATE TYPE "public"."incident_state" AS ENUM('draft', 'running', 'closed', 'discarded');--> statement-breakpoint
CREATE TABLE "incident" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"bf_day_id" uuid NOT NULL,
	"number" integer NOT NULL,
	"keyword" text NOT NULL,
	"address" text NOT NULL,
	"report" text DEFAULT '' NOT NULL,
	"script" text DEFAULT '' NOT NULL,
	"state" "incident_state" DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
ALTER TABLE "incident" ADD CONSTRAINT "incident_bf_day_id_bf_day_id_fk" FOREIGN KEY ("bf_day_id") REFERENCES "public"."bf_day"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "incident_bf_day_number_unique" ON "incident" USING btree ("bf_day_id","number");--> statement-breakpoint
CREATE INDEX "incident_bf_day_state_idx" ON "incident" USING btree ("bf_day_id","state");