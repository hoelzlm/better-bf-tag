ALTER TABLE "incident" ADD COLUMN "latitude" double precision;--> statement-breakpoint
ALTER TABLE "incident" ADD COLUMN "longitude" double precision;--> statement-breakpoint
ALTER TABLE "incident" ADD CONSTRAINT "incident_coordinates_pair" CHECK (("incident"."latitude" is null) = ("incident"."longitude" is null));--> statement-breakpoint
ALTER TABLE "incident" ADD CONSTRAINT "incident_latitude_range" CHECK ("incident"."latitude" between -90 and 90);--> statement-breakpoint
ALTER TABLE "incident" ADD CONSTRAINT "incident_longitude_range" CHECK ("incident"."longitude" between -180 and 180);