CREATE TYPE "public"."program_item_type" AS ENUM('meal', 'training', 'maintenance', 'rest', 'other');--> statement-breakpoint
CREATE TABLE "program_item" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"bf_day_id" uuid NOT NULL,
	"title" varchar(80) NOT NULL,
	"type" "program_item_type" NOT NULL,
	"starts_at" timestamp with time zone NOT NULL,
	"ends_at" timestamp with time zone NOT NULL,
	CONSTRAINT "program_item_period" CHECK ("program_item"."ends_at" > "program_item"."starts_at")
);
--> statement-breakpoint
ALTER TABLE "program_item" ADD CONSTRAINT "program_item_bf_day_id_bf_day_id_fk" FOREIGN KEY ("bf_day_id") REFERENCES "public"."bf_day"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "program_item_bf_day_starts_at_idx" ON "program_item" USING btree ("bf_day_id","starts_at");