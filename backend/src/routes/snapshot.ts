import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, asc, desc, eq, inArray } from 'drizzle-orm';
import { vehicle, slide, slideImage, bfDay, shift, incident, announcement } from '../db/schema.js';
import { requireAuth } from '../access/authenticate.js';
import { vehicleSchema, toVehicleJson } from './vehicle-schemas.js';
import { slideSchema, toSlideJson, type SlideRow } from './slide-schemas.js';
import { bfDayJsonSchema, toBfDayJson } from './bf-day-schemas.js';
import { loadShiftJson, shiftJsonSchema } from './shift-schemas.js';
import { incidentJsonSchema, toIncidentJson, type IncidentRow } from './incident-schemas.js';
import { alarmJsonSchema, loadAlarms } from './alarm-schemas.js';
import { canSeeScript } from '../incidents/visibility.js';
import { currentShift } from '../shifts/current-shift.js';
import { computeCloseSuggested } from '../incidents/close-suggestion.js';
import { closeSuggestedAudience } from '../incidents/visibility.js';
import { announcementSchema, toAnnouncementJson } from '../announcements/announcement-json.js';
import { announcementVisibleTo, loadShiftCrewPersonIds } from '../announcements/visibility.js';
import { programItemSchema, loadProgramItems } from '../program/program-item-json.js';
import type { Viewer } from '../realtime/realtime.js';

const SNAPSHOT_ANNOUNCEMENT_LIMIT = 20;

const snapshotResponseSchema = z.object({
  seq: z.number().int(),
  vehicles: z.array(vehicleSchema),
  slides: z.array(slideSchema),
  bf_day: bfDayJsonSchema.nullable(),
  shifts: z.array(shiftJsonSchema),
  current_shift_id: z.string().nullable(),
  incidents: z.array(incidentJsonSchema),
  alarms: z.array(alarmJsonSchema),
  close_suggested_incident_ids: z.array(z.string()),
  scheduled_alarms: z.array(z.object({ incident: incidentJsonSchema, alarm: alarmJsonSchema })),
  announcements: z.array(announcementSchema),
  program_items: z.array(programItemSchema),
  station: z.object({ latitude: z.number(), longitude: z.number() }).nullable(),
});

export const snapshotRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/snapshot',
    {
      preHandler: requireAuth({ allowMonitor: true }),
      schema: {
        operationId: 'getSnapshot',
        tags: ['snapshot'],
        response: {
          200: snapshotResponseSchema,
        },
      },
    },
    async request => {
      return fastify.db.transaction(
        async tx => {
          const seq = await fastify.realtime.currentSeq(tx);
          const vehicles = await tx
            .select()
            .from(vehicle)
            .where(eq(vehicle.active, true))
            .orderBy(asc(vehicle.sortOrder));

          const slideRows: SlideRow[] = await tx
            .select()
            .from(slide)
            .where(eq(slide.active, true))
            .orderBy(asc(slide.sortOrder));

          let slides: ReturnType<typeof toSlideJson>[] = [];
          if (slideRows.length > 0) {
            const ids = slideRows.map(row => row.id);
            const imageRows = await tx
              .select({
                slideId: slideImage.slideId,
                contentType: slideImage.contentType,
                sizeBytes: slideImage.sizeBytes,
                sha256: slideImage.sha256,
              })
              .from(slideImage)
              .where(inArray(slideImage.slideId, ids));
            const byId = new Map(imageRows.map(row => [row.slideId, row]));
            slides = slideRows.map(row => toSlideJson(row, byId.get(row.id) ?? null));
          }

          const [runningBfDay] = await tx
            .select()
            .from(bfDay)
            .where(eq(bfDay.state, 'running'))
            .limit(1);

          let shiftsJson: Array<Awaited<ReturnType<typeof loadShiftJson>>> = [];
          let currentShiftId: string | null = null;
          let incidentsJson: ReturnType<typeof toIncidentJson>[] = [];
          let alarmsJson: Awaited<ReturnType<typeof loadAlarms>> = [];
          let closeSuggestedIncidentIds: string[] = [];
          let scheduledAlarmsJson: Array<{
            incident: ReturnType<typeof toIncidentJson>;
            alarm: Awaited<ReturnType<typeof loadAlarms>>[number];
          }> = [];
          let announcementsJson: ReturnType<typeof toAnnouncementJson>[] = [];

          let programItemsJson: Awaited<ReturnType<typeof loadProgramItems>> = [];

          if (runningBfDay) {
            const shiftRows = await tx
              .select()
              .from(shift)
              .where(eq(shift.bfDayId, runningBfDay.id));

            const loaded = [];
            for (const row of shiftRows) {
              const json = await loadShiftJson(tx, row.id);
              if (json) loaded.push(json);
            }
            shiftsJson = loaded;

            const current = currentShift(
              shiftRows.map(row => ({
                id: row.id,
                startsAt: row.startsAt,
                endsAt: row.endsAt,
              })),
              fastify.clock.now()
            );
            currentShiftId = current ? current.id : null;

            const includeScript = request.auth ? canSeeScript(request.auth) : false;
            const incidentRows = (await tx
              .select()
              .from(incident)
              .where(and(eq(incident.bfDayId, runningBfDay.id), eq(incident.state, 'running')))
              .orderBy(asc(incident.number))) as IncidentRow[];
            incidentsJson = incidentRows.map(row => toIncidentJson(row, { includeScript }));

            if (incidentRows.length > 0) {
              const loadedAlarms = await loadAlarms(tx, {
                incidentIds: incidentRows.map(row => row.id),
              });
              alarmsJson = loadedAlarms
                .filter(a => a.state === 'triggered')
                .sort((a, b) => {
                  const at = a.triggered_at ?? '';
                  const bt = b.triggered_at ?? '';
                  return at.localeCompare(bt);
                });
            }

            const canSeeCloseSuggested = request.auth
              ? request.auth.kind === 'person' &&
                closeSuggestedAudience({
                  kind: 'person',
                  personId: request.auth.personId,
                  permission: request.auth.permission,
                })
              : false;
            if (canSeeCloseSuggested && incidentRows.length > 0) {
              const suggested = await computeCloseSuggested(
                tx,
                incidentRows.map(row => row.id)
              );
              closeSuggestedIncidentIds = [...suggested];
            }

            // Geplante/verpasste Alarmierungen (ADR 0022): nur fürs
            // Drehbuch (preparation/dispatch/admin), sonst `[]`.
            const canSeeScheduledAlarms = includeScript;
            if (canSeeScheduledAlarms) {
              const draftIncidentRows = (await tx
                .select()
                .from(incident)
                .where(
                  and(eq(incident.bfDayId, runningBfDay.id), eq(incident.state, 'draft'))
                )) as IncidentRow[];
              const scheduledIncidentRows = [...incidentRows, ...draftIncidentRows];
              const incidentJsonById = new Map(
                scheduledIncidentRows.map(row => [
                  row.id,
                  toIncidentJson(row, { includeScript: true }),
                ])
              );
              if (scheduledIncidentRows.length > 0) {
                const loadedScheduled = await loadAlarms(tx, {
                  incidentIds: scheduledIncidentRows.map(row => row.id),
                });
                scheduledAlarmsJson = loadedScheduled
                  .filter(a => a.state === 'planned' || a.state === 'missed')
                  .sort((a, b) => {
                    const at = a.scheduled_at ?? '';
                    const bt = b.scheduled_at ?? '';
                    if (at !== bt) return at.localeCompare(bt);
                    return a.id.localeCompare(b.id);
                  })
                  .map(a => ({
                    incident: incidentJsonById.get(a.incident_id)!,
                    alarm: a,
                  }));
              }
            }

            // Letzte 20 sichtbare Durchsagen, neueste zuerst (ADR 0024).
            const viewer: Viewer = request.auth
              ? request.auth.kind === 'monitor'
                ? { kind: 'monitor', permission: 'crew' }
                : {
                    kind: 'person',
                    personId: request.auth.personId,
                    permission: request.auth.permission,
                  }
              : { kind: 'monitor', permission: 'crew' };

            const announcementRows = await tx
              .select()
              .from(announcement)
              .where(eq(announcement.bfDayId, runningBfDay.id))
              .orderBy(desc(announcement.createdAt));

            const crewCacheByShift = new Map<string, Set<string>>();
            const visibleAnnouncements = [];
            for (const row of announcementRows) {
              let crewPersonIds = new Set<string>();
              if (row.shiftId !== null) {
                const cached = crewCacheByShift.get(row.shiftId);
                if (cached) {
                  crewPersonIds = cached;
                } else {
                  crewPersonIds = await loadShiftCrewPersonIds(tx, row.shiftId);
                  crewCacheByShift.set(row.shiftId, crewPersonIds);
                }
              }
              if (announcementVisibleTo(viewer, { shiftId: row.shiftId }, crewPersonIds)) {
                visibleAnnouncements.push(row);
                if (visibleAnnouncements.length >= SNAPSHOT_ANNOUNCEMENT_LIMIT) break;
              }
            }
            announcementsJson = visibleAnnouncements.map(toAnnouncementJson);

            programItemsJson = await loadProgramItems(tx, runningBfDay.id);
          }

          return {
            seq,
            vehicles: vehicles.map(toVehicleJson),
            slides,
            bf_day: runningBfDay ? toBfDayJson(runningBfDay) : null,
            shifts: shiftsJson.filter((s): s is NonNullable<typeof s> => s !== undefined),
            current_shift_id: currentShiftId,
            incidents: incidentsJson,
            alarms: alarmsJson,
            close_suggested_incident_ids: closeSuggestedIncidentIds,
            scheduled_alarms: scheduledAlarmsJson,
            announcements: announcementsJson,
            program_items: programItemsJson,
            station:
              fastify.config.STATION_LATITUDE !== undefined &&
              fastify.config.STATION_LONGITUDE !== undefined
                ? {
                    latitude: fastify.config.STATION_LATITUDE,
                    longitude: fastify.config.STATION_LONGITUDE,
                  }
                : null,
          };
        },
        { isolationLevel: 'repeatable read' }
      );
    }
  );
};
