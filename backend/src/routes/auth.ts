import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { eq } from 'drizzle-orm';
import { person, webSession } from '../db/schema.js';
import { verifyPassword } from '../access/passwords.js';
import { newRefreshToken, signAccessToken } from '../access/tokens.js';
import { personSummarySchema, errorResponseSchema } from '../access/schemas.js';
import { ApiError } from '../errors.js';

const loginBodySchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

const loginResponseSchema = z.object({
  access_token: z.string(),
  expires_in: z.number(),
  person: personSummarySchema,
});

function invalidCredentials(): ApiError {
  return new ApiError(401, 'invalid_credentials', 'Benutzername oder Passwort falsch.');
}

export const authRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.post(
    '/auth/login',
    {
      schema: {
        operationId: 'login',
        tags: ['auth'],
        body: loginBodySchema,
        response: {
          200: loginResponseSchema,
          401: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { username, password } = request.body;

      const [found] = await fastify.db
        .select()
        .from(person)
        .where(eq(person.username, username))
        .limit(1);

      if (!found || !found.active || !found.passwordHash) {
        throw invalidCredentials();
      }

      const passwordOk = await verifyPassword(found.passwordHash, password);
      if (!passwordOk) {
        throw invalidCredentials();
      }

      const accessToken = await signAccessToken(
        { config: fastify.config, clock: fastify.clock },
        { id: found.id, permission: found.permission }
      );

      const { token: refreshToken, hash: refreshTokenHash } = newRefreshToken();
      const now = fastify.clock.now();
      const refreshTtlMs = fastify.config.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000;
      const expiresAt = new Date(now.getTime() + refreshTtlMs);

      await fastify.db.insert(webSession).values({
        personId: found.id,
        refreshTokenHash,
        createdAt: now,
        expiresAt,
      });

      reply.setCookie('bftag_refresh', refreshToken, {
        httpOnly: true,
        sameSite: 'strict',
        path: '/api/v1/auth',
        secure: fastify.config.COOKIE_SECURE,
        maxAge: Math.floor(refreshTtlMs / 1000),
      });

      return reply.status(200).send({
        access_token: accessToken,
        expires_in: fastify.config.ACCESS_TOKEN_TTL_SECONDS,
        person: {
          id: found.id,
          display_name: found.displayName,
          person_type: found.personType,
          permission: found.permission,
        },
      });
    }
  );
};
