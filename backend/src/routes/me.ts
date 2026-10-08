import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { eq } from 'drizzle-orm';
import { person } from '../db/schema.js';
import { requireAuth } from '../access/authenticate.js';
import { personSummarySchema } from '../access/schemas.js';
import { ApiError } from '../errors.js';

const meResponseSchema = z.object({
  person: personSummarySchema,
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

      return {
        person: {
          id: found.id,
          display_name: found.displayName,
          person_type: found.personType,
          permission: found.permission,
        },
      };
    }
  );
};
