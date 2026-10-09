ALTER TABLE "alarm" ADD COLUMN "push_delivered" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "alarm" ADD COLUMN "push_rejected" integer DEFAULT 0 NOT NULL;