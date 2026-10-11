import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { geocodeQuerySchema, geocodeResponseSchema } from './geocode-schemas.js';

/**
 * Geocoding-Proxy (ADR 0026 „Geocoding“): `GET /geocode?q=`. Berechtigungen
 * preparation/dispatch/admin (Monitore und crew -> 403). `search()` never
 * throws, so this route never produces a 5xx from the upstream.
 */
export const geocodeRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/geocode',
    {
      preHandler: [requireAuth(), requirePermission('preparation', 'dispatch')],
      schema: {
        operationId: 'geocode',
        tags: ['geocode'],
        querystring: geocodeQuerySchema,
        response: {
          200: geocodeResponseSchema,
          400: errorResponseSchema,
        },
      },
    },
    async request => {
      const results = await fastify.geocoder.search(request.query.q);
      return { results };
    }
  );
};
