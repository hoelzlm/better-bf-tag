CREATE TABLE "slide" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" text NOT NULL,
	"body" text DEFAULT '' NOT NULL,
	"duration_seconds" integer DEFAULT 10 NOT NULL,
	"sort_order" integer NOT NULL,
	"active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL,
	CONSTRAINT "slide_duration_seconds_range" CHECK ("slide"."duration_seconds" between 3 and 300)
);
--> statement-breakpoint
CREATE TABLE "slide_image" (
	"slide_id" uuid PRIMARY KEY NOT NULL,
	"content_type" text NOT NULL,
	"data" "bytea" NOT NULL,
	"sha256" text NOT NULL,
	"size_bytes" integer NOT NULL,
	"created_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
ALTER TABLE "slide_image" ADD CONSTRAINT "slide_image_slide_id_slide_id_fk" FOREIGN KEY ("slide_id") REFERENCES "public"."slide"("id") ON DELETE cascade ON UPDATE no action;