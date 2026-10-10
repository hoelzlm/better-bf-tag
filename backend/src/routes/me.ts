import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, eq, ne } from 'drizzle-orm';
import { person, device } from '../db/schema.js';
import { requireAuth } from '../access/authenticate.js';
import { personSummarySchema } from '../access/schemas.js';
import { ApiError } from '../errors.js';
import { loadCurrentCrewAssignments } from '../shifts/current-crew.js';

const crewAssignmentSummarySchema = z.object({
  shift_id: z.string(),
  vehicle_id: z.string(),
  function: z.string(),
});

const meResponseSchema = z.object({
  person: personSummarySchema,
  crew_assignments: z.array(crewAssignmentSummarySchema),
});

const updatePushTokenBodySchema = z.object({
  token: z.string().min(1).max(4096),
});

const testAlarmBodySchema = z
  .object({
    delay_seconds: z.number().int().min(0).max(30).optional(),
  })
  .strict();

const testAlarmResultSchema = z.object({
  outcome: z.enum(['delivered', 'rejected', 'invalid_token']),
});

const testAlarmScheduledSchema = z.object({
  scheduled: z.literal(true),
});

export const meRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/me',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'getMe',
        tags: ['auth'],
        response: {
          200: meResponseSchema,
        },
      },
    },
    async request => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'person') {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }

      const [found] = await fastify.db
        .select()
        .from(person)
        .where(eq(person.id, auth.personId))
        .limit(1);

      if (!found) {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }

      const crewAssignments = await loadCurrentCrewAssignments(
        fastify.db,
        fastify.clock.now(),
        auth.personId
      );

      return {
        person: {
          id: found.id,
          display_name: found.displayName,
          person_type: found.personType,
          permission: found.permission,
        },
        crew_assignments: crewAssignments.map(assignment => ({
          shift_id: assignment.shiftId,
          vehicle_id: assignment.vehicleId,
          function: assignment.function,
        })),
      };
    }
  );

  fastify.put(
    '/me/device/push-token',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'updatePushToken',
        tags: ['auth'],
        body: updatePushTokenBodySchema,
      },
    },
    async (request, reply) => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'person' || auth.deviceId === undefined) {
        throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
      }

      const token = request.body.token;
      const deviceId = auth.deviceId;

      await fastify.db.transaction(async tx => {
        // A token belongs to exactly one device (ADR 0018): clear it from
        // any other device row first, then set it on the caller's own
        // device.
        await tx
          .update(device)
          .set({ pushToken: null })
          .where(and(eq(device.pushToken, token), ne(device.id, deviceId)));

        await tx.update(device).set({ pushToken: token }).where(eq(device.id, deviceId));
      });

      return reply.status(204).send();
    }
  );

  fastify.post(
    '/me/device/test-alarm',
    {
      preHandler: requireAuth(),
      schema: {
        operationId: 'triggerTestAlarm',
        tags: ['auth'],
        body: testAlarmBodySchema,
        response: {
          200: testAlarmResultSchema,
          202: testAlarmScheduledSchema,
        },
      },
    },
    async (request, reply) => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'person' || auth.deviceId === undefined) {
        throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
      }

      const deviceId = auth.deviceId;
      const delaySeconds = request.body.delay_seconds ?? 0;

      const [deviceRow] = await fastify.db
        .select({ pushToken: device.pushToken })
        .from(device)
        .where(eq(device.id, deviceId))
        .limit(1);

      if (!deviceRow || deviceRow.pushToken === null) {
        throw new ApiError(409, 'no_push_token', 'Push ist auf diesem Gerät nicht eingerichtet.');
      }

      if (fastify.testAlarmScheduler.isBlocked(deviceId)) {
        throw new ApiError(429, 'test_alarm_cooldown', 'Bitte kurz warten und erneut versuchen.');
      }

      if (delaySeconds === 0) {
        const outcome = await fastify.testAlarmScheduler.sendNow(deviceId);
        return reply.status(200).send({ outcome });
      }

      fastify.testAlarmScheduler.schedule(deviceId, delaySeconds);
      return reply.status(202).send({ scheduled: true });
    }
  );
};
