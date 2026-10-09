import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { eq } from 'drizzle-orm';
import { person } from '../db/schema.js';
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
};
