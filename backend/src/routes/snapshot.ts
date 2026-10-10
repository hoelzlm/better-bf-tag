import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, asc, eq, inArray } from 'drizzle-orm';
import { vehicle, slide, slideImage, bfDay, shift, incident } from '../db/schema.js';
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
              ? request.auth.kind === 'person' && closeSuggestedAudience(request.auth.permission)
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
          };
        },
        { isolationLevel: 'repeatable read' }
      );
    }
  );
};
