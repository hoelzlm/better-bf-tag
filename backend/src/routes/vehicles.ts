import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, asc, desc, eq, sql } from 'drizzle-orm';
import { vehicle, vehicleStatusEvent, fireDepartment } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { vehicleSchema, toVehicleJson, type VehicleRow } from './vehicle-schemas.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';
import { allowsPatientStatus, isPatientStatus } from '../vehicles/fms-rules.js';
import { loadCurrentCrewAssignments } from '../shifts/current-crew.js';

const createVehicleBodySchema = z.object({
  call_sign: z.string().trim().min(1),
  short_name: z.string().trim().min(1),
  type: z.string().trim().min(1),
});

const updateVehicleBodySchema = z.object({
  call_sign: z.string().trim().min(1).optional(),
  short_name: z.string().trim().min(1).optional(),
  type: z.string().trim().min(1).optional(),
  active: z.boolean().optional(),
});

const reorderBodySchema = z.object({
  vehicle_ids: z.array(z.string().uuid()),
});

const setStatusBodySchema = z.object({
  status: z.number().int().min(1).max(8),
});

const statusHistoryItemSchema = z.object({
  status: z.number().int().nullable(),
  source: z.enum(['app', 'dispatch', 'system']),
  person_id: z.string().nullable(),
  at: z.string(),
});

const vehicleListResponseSchema = z.array(vehicleSchema);
const statusHistoryResponseSchema = z.array(statusHistoryItemSchema);

function vehicleNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Fahrzeug nicht gefunden.');
}

async function loadVehicle(tx: Tx, id: string): Promise<VehicleRow | undefined> {
  const [row] = await tx.select().from(vehicle).where(eq(vehicle.id, id)).limit(1);
  return row;
}

export const vehicleRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/vehicles',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'listVehicles',
        tags: ['vehicles'],
        response: {
          200: vehicleListResponseSchema,
        },
      },
    },
    async () => {
      const rows = await fastify.db.select().from(vehicle).orderBy(asc(vehicle.sortOrder));
      return rows.map(toVehicleJson);
    }
  );

  fastify.post(
    '/vehicles',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'createVehicle',
        tags: ['vehicles'],
        body: createVehicleBodySchema,
        response: {
          201: vehicleSchema,
        },
      },
    },
    async (request, reply) => {
      const created = await fastify.realtime.mutate(async (tx, emit) => {
        const [own] = await tx
          .select({ id: fireDepartment.id })
          .from(fireDepartment)
          .where(eq(fireDepartment.isOwn, true))
          .limit(1);
        if (!own) {
          throw new Error('createVehicle: own fire department is missing');
        }

        const [maxRow] = await tx
          .select({ max: sql<number | null>`max(${vehicle.sortOrder})` })
          .from(vehicle);
        const nextSortOrder = (maxRow?.max ?? -1) + 1;

        const [row] = await tx
          .insert(vehicle)
          .values({
            fireDepartmentId: own.id,
            callSign: request.body.call_sign,
            shortName: request.body.short_name,
            type: request.body.type,
            status: 2,
            statusChangedAt: null,
            sortOrder: nextSortOrder,
            active: true,
          })
          .returning();
        if (!row) {
          throw new Error('createVehicle: insert returned no row');
        }

        const json = toVehicleJson(row);
        await emit('vehicle.updated', json);
        return json;
      });

      return reply.status(201).send(created);
    }
  );

  fastify.patch(
    '/vehicles/:id',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'updateVehicle',
        tags: ['vehicles'],
        params: z.object({ id: z.string().uuid() }),
        body: updateVehicleBodySchema,
        response: {
          200: vehicleSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadVehicle(tx, request.params.id);
        if (!existing) {
          throw vehicleNotFound();
        }

        const patch: Partial<VehicleRow> = {};
        if (request.body.call_sign !== undefined) patch.callSign = request.body.call_sign;
        if (request.body.short_name !== undefined) patch.shortName = request.body.short_name;
        if (request.body.type !== undefined) patch.type = request.body.type;
        if (request.body.active !== undefined) patch.active = request.body.active;

        const [row] = await tx
          .update(vehicle)
          .set(patch)
          .where(eq(vehicle.id, request.params.id))
          .returning();
        if (!row) {
          throw vehicleNotFound();
        }

        const json = toVehicleJson(row);
        await emit('vehicle.updated', json);
        return json;
      });
    }
  );

  fastify.put(
    '/vehicles/order',
    {
      preHandler: [requireAuth(), requirePermission('admin')],
      schema: {
        operationId: 'reorderVehicles',
        tags: ['vehicles'],
        body: reorderBodySchema,
        response: {
          200: vehicleListResponseSchema,
          400: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await tx.select().from(vehicle);
        const existingIds = new Set(existing.map(row => row.id));
        const requestedIds = request.body.vehicle_ids;
        const requestedSet = new Set(requestedIds);

        if (
          requestedIds.length !== existingIds.size ||
          requestedSet.size !== requestedIds.length ||
          [...existingIds].some(id => !requestedSet.has(id))
        ) {
          throw new ApiError(
            400,
            'validation_error',
            'vehicle_ids muss genau die Menge aller Fahrzeug-IDs enthalten.'
          );
        }

        const byId = new Map(existing.map(row => [row.id, row]));
        const updated: VehicleRow[] = [];

        for (let index = 0; index < requestedIds.length; index++) {
          const id = requestedIds[index];
          if (id === undefined) continue;
          const current = byId.get(id);
          if (!current || current.sortOrder === index) {
            if (current) updated.push(current);
            continue;
          }
          const [row] = await tx
            .update(vehicle)
            .set({ sortOrder: index })
            .where(eq(vehicle.id, id))
            .returning();
          if (!row) continue;
          updated.push(row);
          await emit('vehicle.updated', toVehicleJson(row));
        }

        const ordered = updated.sort((a, b) => a.sortOrder - b.sortOrder);
        return ordered.map(toVehicleJson);
      });
    }
  );

  fastify.put(
    '/vehicles/:id/status',
    {
      preHandler: [requireAuth()],
      schema: {
        operationId: 'setVehicleStatus',
        tags: ['vehicles'],
        params: z.object({ id: z.string().uuid() }),
        body: setStatusBodySchema,
        response: {
          200: vehicleSchema,
          403: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'person') {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }

      return fastify.realtime.mutate(async (tx, emit) => {
        const existing = await loadVehicle(tx, request.params.id);
        if (!existing) {
          throw vehicleNotFound();
        }
        if (!existing.active) {
          throw new ApiError(409, 'vehicle_inactive', 'Fahrzeug ist deaktiviert.');
        }
        if (isPatientStatus(request.body.status) && !allowsPatientStatus(existing.type)) {
          throw new ApiError(
            409,
            'status_not_allowed',
            'Status nicht erlaubt für dieses Fahrzeug.'
          );
        }

        const now = fastify.clock.now();

        const crew = await loadCurrentCrewAssignments(tx, now, auth.personId);
        const isCrew = crew.some(assignment => assignment.vehicleId === existing.id);

        let source: 'app' | 'dispatch';
        if (isCrew) {
          source = 'app';
        } else if (auth.permission === 'dispatch' || auth.permission === 'admin') {
          source = 'dispatch';
        } else {
          throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
        }

        const [row] = await tx
          .update(vehicle)
          .set({ status: request.body.status, statusChangedAt: now })
          .where(eq(vehicle.id, request.params.id))
          .returning();
        if (!row) {
          throw vehicleNotFound();
        }

        await tx.insert(vehicleStatusEvent).values({
          vehicleId: row.id,
          kind: 'status',
          status: request.body.status,
          source,
          personId: auth.personId,
          createdAt: now,
        });

        const json = toVehicleJson(row);
        await emit('vehicle.status_changed', {
          vehicle_id: row.id,
          status: row.status,
          at: now.toISOString(),
          source,
        });
        return json;
      });
    }
  );

  fastify.get(
    '/vehicles/:id/status-history',
    {
      preHandler: [requireAuth(), requirePermission('dispatch')],
      schema: {
        operationId: 'getVehicleStatusHistory',
        tags: ['vehicles'],
        params: z.object({ id: z.string().uuid() }),
        response: {
          200: statusHistoryResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      const [existing] = await fastify.db
        .select({ id: vehicle.id })
        .from(vehicle)
        .where(eq(vehicle.id, request.params.id))
        .limit(1);
      if (!existing) {
        throw vehicleNotFound();
      }

      const rows = await fastify.db
        .select()
        .from(vehicleStatusEvent)
        .where(
          and(
            eq(vehicleStatusEvent.vehicleId, request.params.id),
            eq(vehicleStatusEvent.kind, 'status')
          )
        )
        .orderBy(desc(vehicleStatusEvent.createdAt));

      return rows.map(row => ({
        status: row.status,
        source: row.source,
        person_id: row.personId,
        at: row.createdAt.toISOString(),
      }));
    }
  );

  // No DELETE route for vehicles: deactivation only (ADR 0009). The global
  // not-found handler answers unregistered DELETE /vehicles/{id} with 404.
};
