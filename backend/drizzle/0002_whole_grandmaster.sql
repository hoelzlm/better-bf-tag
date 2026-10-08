CREATE TYPE "public"."device_platform" AS ENUM('android', 'ios');--> statement-breakpoint
CREATE TYPE "public"."pairing_target_type" AS ENUM('person', 'monitor');--> statement-breakpoint
CREATE TABLE "device" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"person_id" uuid NOT NULL,
	"platform" "device_platform" NOT NULL,
	"device_name" text,
	"app_version" text NOT NULL,
	"push_token" text,
	"refresh_token_hash" text NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"last_seen_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone,
	CONSTRAINT "device_refresh_token_hash_unique" UNIQUE("refresh_token_hash")
);
--> statement-breakpoint
CREATE TABLE "pairing_code" (
	"code_hash" text PRIMARY KEY NOT NULL,
	"target_type" "pairing_target_type" NOT NULL,
	"target_id" uuid NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"used_at" timestamp with time zone
);
--> statement-breakpoint
ALTER TABLE "device" ADD CONSTRAINT "device_person_id_person_id_fk" FOREIGN KEY ("person_id") REFERENCES "public"."person"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "pairing_code_target_idx" ON "pairing_code" USING btree ("target_type","target_id");