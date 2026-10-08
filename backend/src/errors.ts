import type { FastifyError, FastifyInstance } from 'fastify';
import { ZodError } from 'zod';

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string
  ) {
    super(message);
    this.name = 'ApiError';
    Error.captureStackTrace(this, ApiError);
  }
}

export function createErrorHandler(app: FastifyInstance) {
  app.setErrorHandler((error: FastifyError, request, reply) => {
    if (error instanceof ZodError) {
      const issues = error.issues.map(issue => ({
        path: issue.path,
        message: issue.message,
      }));
      return reply.status(400).send({
        error: {
          code: 'validation_error' as const,
          message: 'Validation failed',
          issues,
        },
      });
    }

    if (error instanceof ApiError) {
      return reply.status(error.statusCode).send({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }

    // Fastify's own http errors (e.g. 404 from missing route)
    const statusCode = (error as { statusCode?: number }).statusCode ?? 500;
    if (statusCode === 404) {
      return reply.status(404).send({
        error: {
          code: 'not_found' as const,
          message: 'Resource not found',
        },
      });
    }

    if (statusCode === 429) {
      return reply.status(429).send({
        error: {
          code: 'rate_limited' as const,
          message: 'Too many requests',
        },
      });
    }

    // Unknown error — log and return generic 500
    request.log.warn({ error: error.message }, 'Unhandled error');
    return reply.status(500).send({
      error: {
        code: 'internal_error' as const,
        message: 'Internal server error',
      },
    });
  });
}

export function createNotFoundHandler(app: FastifyInstance) {
  app.setNotFoundHandler((request, reply) => {
    return reply.status(404).send({
      error: {
        code: 'not_found' as const,
        message: `Route ${request.method}:${request.url} not found`,
      },
    });
  });
}
