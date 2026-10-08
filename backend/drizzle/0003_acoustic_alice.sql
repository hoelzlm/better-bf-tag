CREATE TABLE "monitor_display" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"refresh_token_hash" text,
	"paired_at" timestamp with time zone,
	"last_seen_at" timestamp with time zone,
	"created_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone,
	CONSTRAINT "monitor_display_refresh_token_hash_unique" UNIQUE("refresh_token_hash")
);
