ALTER TABLE "alarm" ADD COLUMN "relative_to_alarm_id" uuid;--> statement-breakpoint
ALTER TABLE "alarm" ADD COLUMN "offset_minutes" integer;--> statement-breakpoint
ALTER TABLE "alarm" ADD CONSTRAINT "alarm_relative_to_alarm_id_alarm_id_fk" FOREIGN KEY ("relative_to_alarm_id") REFERENCES "public"."alarm"("id") ON DELETE set null ON UPDATE no action;