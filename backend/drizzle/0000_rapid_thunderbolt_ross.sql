CREATE TYPE "public"."permission" AS ENUM('crew', 'preparation', 'dispatch', 'admin');--> statement-breakpoint
CREATE TYPE "public"."person_type" AS ENUM('youth', 'supervisor');--> statement-breakpoint
CREATE TABLE "fire_department" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"is_own" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE TABLE "person" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"fire_department_id" uuid NOT NULL,
	"display_name" text NOT NULL,
	"person_type" "person_type" NOT NULL,
	"permission" "permission" NOT NULL,
	"username" text,
	"password_hash" text,
	"active" boolean DEFAULT true NOT NULL,
	CONSTRAINT "person_username_unique" UNIQUE("username"),
	CONSTRAINT "person_admin_requires_supervisor" CHECK ("person"."permission" <> 'admin' OR "person"."person_type" = 'supervisor')
);
--> statement-breakpoint
CREATE TABLE "web_session" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"person_id" uuid NOT NULL,
	"refresh_token_hash" text NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone,
	CONSTRAINT "web_session_refresh_token_hash_unique" UNIQUE("refresh_token_hash")
);
--> statement-breakpoint
ALTER TABLE "person" ADD CONSTRAINT "person_fire_department_id_fire_department_id_fk" FOREIGN KEY ("fire_department_id") REFERENCES "public"."fire_department"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "web_session" ADD CONSTRAINT "web_session_person_id_person_id_fk" FOREIGN KEY ("person_id") REFERENCES "public"."person"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "fire_department_is_own_unique" ON "fire_department" USING btree ("is_own") WHERE "fire_department"."is_own" = true;