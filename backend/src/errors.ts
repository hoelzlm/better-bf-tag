import type { FastifyError, FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { hasZodFastifySchemaValidationErrors } from 'fastify-type-provider-zod';

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

    // Request (body/params/query) validation failures from
    // fastify-type-provider-zod: Fastify wraps these as a FastifyError with
    // a `validation` array rather than throwing the ZodError directly.
    if (hasZodFastifySchemaValidationErrors(error)) {
      const issues = error.validation.map(issue => ({
        path: issue.instancePath,
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

    // Raw image-upload routes (ADR 0014) rely on Fastify's own body-size
    // and content-type-parser errors rather than throwing ApiError, so map
    // their statusCodes to our `{error:{code,message}}` shape here too.
    if (statusCode === 413) {
      return reply.status(413).send({
        error: {
          code: 'image_too_large' as const,
          message: 'Bild ist zu groß.',
        },
      });
    }

    if (statusCode === 415) {
      return reply.status(415).send({
        error: {
          code: 'unsupported_image_type' as const,
          message: 'Nicht unterstützter Bildtyp.',
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
