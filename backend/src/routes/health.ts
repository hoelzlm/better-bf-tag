import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

const healthResponseSchema = z.object({
  status: z.literal('ok'),
  database: z.literal('ok'),
});

const healthErrorResponseSchema = z.object({
  status: z.literal('error'),
  database: z.literal('error'),
});

export const healthRoutes: FastifyPluginAsync<{ prefix?: string }> = async fastify => {
  fastify.get(
    '/health',
    {
      schema: {
        operationId: 'getHealth',
        tags: ['health'],
        response: {
          200: healthResponseSchema,
          503: healthErrorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      try {
        await fastify.pool.query('SELECT 1');
        return { status: 'ok' as const, database: 'ok' as const };
      } catch {
        return reply.status(503).send({ status: 'error' as const, database: 'error' as const });
      }
    }
  );
};
