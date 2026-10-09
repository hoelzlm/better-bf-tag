import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, asc, eq, max } from 'drizzle-orm';
import { incident } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import type { AuthContext } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { resolveBfDay } from '../bf-days/resolve-day.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';
import { canSeeIncident, canSeeScript, scriptAudience } from '../incidents/visibility.js';
import { incidentUpdatedEventOpts } from '../incidents/incident-events.js';
import type { IncidentRow } from '../incidents/incident-json.js';
import { alarmJsonSchema, loadAlarms } from './alarm-schemas.js';
import {
  incidentJsonSchema,
  toIncidentJson,
  createIncidentBodySchema,
  updateIncidentBodySchema,
  incidentStateQuerySchema,
  dayParamsSchema,
  incidentIdParamsSchema,
} from './incident-schemas.js';

const incidentListResponseSchema = z.array(incidentJsonSchema);
const incidentWithAlarmsJsonSchema = incidentJsonSchema.extend({
  alarms: z.array(alarmJsonSchema),
});

function incidentNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Einsatz nicht gefunden.');
}

async function loadIncidentRow(tx: Tx, id: string): Promise<IncidentRow | undefined> {
  const [row] = await tx.select().from(incident).where(eq(incident.id, id)).limit(1);
  return row as IncidentRow | undefined;
}

/** Loads an Einsatz respecting Drehbuch/Zustand visibility (ADR 0016), else 404. */
async function loadVisibleIncident(
  tx: Tx,
  id: string,
  principal: AuthContext
): Promise<IncidentRow> {
  const row = await loadIncidentRow(tx, id);
  if (!row || !canSeeIncident(principal, row.state)) {
    throw incidentNotFound();
  }
  return row;
}

export const incidentRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/bf-days/:day/incidents',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'listIncidents',
        tags: ['incidents'],
        params: dayParamsSchema,
        querystring: incidentStateQuerySchema,
        response: {
          200: incidentListResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      const principal = request.auth;
      if (!principal) {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }
      return fastify.db.transaction(async tx => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        const conditions = [eq(incident.bfDayId, bfDayRow.id)];
        if (request.query.state) {
          conditions.push(eq(incident.state, request.query.state));
        }
        const rows = (await tx
          .select()
          .from(incident)
          .where(and(...conditions))
          .orderBy(asc(incident.number))) as IncidentRow[];

        return rows
          .filter(row => canSeeIncident(principal, row.state))
          .map(row => toIncidentJson(row, { includeScript: canSeeScript(principal) }));
      });
    }
  );

  fastify.get(
    '/incidents/:id',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'getIncident',
        tags: ['incidents'],
        params: incidentIdParamsSchema,
        response: {
          200: incidentWithAlarmsJsonSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      const principal = request.auth;
      if (!principal) {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }
      return fastify.db.transaction(async tx => {
        const row = await loadVisibleIncident(tx, request.params.id, principal);
        const alarms = await loadAlarms(tx, { incidentIds: [row.id] });
        alarms.sort((a, b) => {
          const at = a.triggered_at ?? '';
          const bt = b.triggered_at ?? '';
          if (at !== bt) return at.localeCompare(bt);
          return 0;
        });
        return { ...toIncidentJson(row, { includeScript: canSeeScript(principal) }), alarms };
      });
    }
  );

  fastify.post(
    '/bf-days/:day/incidents',
    {
      preHandler: [requireAuth(), requirePermission('preparation', 'dispatch')],
      schema: {
        operationId: 'createIncident',
        tags: ['incidents'],
        params: dayParamsSchema,
        body: createIncidentBodySchema,
        response: {
          201: incidentJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const created = await fastify.realtime.mutate(async (tx, emit) => {
        const bfDayRow = await resolveBfDay(tx, request.params.day);
        if (bfDayRow.state === 'ended') {
          throw new ApiError(409, 'bf_day_ended', 'BF-Tag ist bereits beendet.');
        }

        const [maxRow] = await tx
          .select({ max: max(incident.number) })
          .from(incident)
          .where(eq(incident.bfDayId, bfDayRow.id));
        const number = (maxRow?.max ?? 0) + 1;

        const now = fastify.clock.now();
        const [row] = await tx
          .insert(incident)
          .values({
            bfDayId: bfDayRow.id,
            number,
            keyword: request.body.keyword,
            address: request.body.address,
            report: request.body.report ?? '',
            script: request.body.script ?? '',
            state: 'draft',
            createdAt: now,
            updatedAt: now,
          })
          .returning();
        if (!row) {
          throw new Error('createIncident: insert returned no row');
        }

        const incidentRow = row as IncidentRow;
        await emit('incident.created', toIncidentJson(incidentRow, { includeScript: true }), {
          audience: scriptAudience,
        });
        return toIncidentJson(incidentRow, { includeScript: true });
      });

      return reply.status(201).send(created);
    }
  );

  fastify.patch(
    '/incidents/:id',
    {
      preHandler: [requireAuth(), requirePermission('preparation', 'dispatch')],
      schema: {
        operationId: 'updateIncident',
        tags: ['incidents'],
        params: incidentIdParamsSchema,
        body: updateIncidentBodySchema,
        response: {
          200: incidentJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadIncidentRow(tx, request.params.id);
        if (!existing) {
          throw incidentNotFound();
        }
        if (existing.state !== 'draft' && existing.state !== 'running') {
          throw new ApiError(409, 'incident_not_editable', 'Einsatz ist nicht mehr bearbeitbar.');
        }

        const patch: Partial<IncidentRow> = { updatedAt: fastify.clock.now() };
        if (request.body.keyword !== undefined) patch.keyword = request.body.keyword;
        if (request.body.address !== undefined) patch.address = request.body.address;
        if (request.body.report !== undefined) patch.report = request.body.report;
        if (request.body.script !== undefined) patch.script = request.body.script;

        const [row] = await tx
          .update(incident)
          .set(patch)
          .where(eq(incident.id, existing.id))
          .returning();
        if (!row) {
          throw incidentNotFound();
        }

        const incidentRow = row as IncidentRow;
        await emit('incident.updated', null, incidentUpdatedEventOpts(incidentRow));
        return toIncidentJson(incidentRow, { includeScript: true });
      });
    }
  );

  fastify.post(
    '/incidents/:id/discard',
    {
      preHandler: [requireAuth(), requirePermission('preparation', 'dispatch')],
      schema: {
        operationId: 'discardIncident',
        tags: ['incidents'],
        params: incidentIdParamsSchema,
        response: {
          200: incidentJsonSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadIncidentRow(tx, request.params.id);
        if (!existing) {
          throw incidentNotFound();
        }
        if (existing.state !== 'draft') {
          throw new ApiError(
            409,
            'invalid_state_transition',
            'Einsatz kann nur als Entwurf verworfen werden.'
          );
        }

        const [row] = await tx
          .update(incident)
          .set({ state: 'discarded', updatedAt: fastify.clock.now() })
          .where(eq(incident.id, existing.id))
          .returning();
        if (!row) {
          throw incidentNotFound();
        }

        const incidentRow = row as IncidentRow;
        await emit('incident.updated', null, incidentUpdatedEventOpts(incidentRow));
        return toIncidentJson(incidentRow, { includeScript: true });
      });
    }
  );
};
