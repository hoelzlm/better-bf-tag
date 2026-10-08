import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, eq, gt, isNull, ne } from 'drizzle-orm';
import { person, webSession } from '../db/schema.js';
import { verifyPassword } from '../access/passwords.js';
import { hashRefreshToken, newRefreshToken, signAccessToken } from '../access/tokens.js';
import { personSummarySchema, errorResponseSchema } from '../access/schemas.js';
import { ApiError } from '../errors.js';

const loginBodySchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

const sessionResponseSchema = z.object({
  access_token: z.string(),
  expires_in: z.number(),
  person: personSummarySchema,
});

const REFRESH_COOKIE_NAME = 'bftag_refresh';
const REFRESH_COOKIE_PATH = '/api/v1/auth';

function invalidCredentials(): ApiError {
  return new ApiError(401, 'invalid_credentials', 'Benutzername oder Passwort falsch.');
}

function invalidRefreshToken(): ApiError {
  return new ApiError(401, 'invalid_refresh_token', 'Ungültiges oder abgelaufenes Refresh-Token.');
}

export const authRoutes: FastifyPluginAsyncZod = async fastify => {
  function rateLimitConfig() {
    return {
      rateLimit: {
        max: fastify.config.AUTH_RATE_LIMIT_MAX,
        timeWindow: fastify.config.AUTH_RATE_LIMIT_WINDOW_MS,
        keyGenerator: (request: { ip: string }) => request.ip,
      },
    };
  }

  function clearRefreshCookie(reply: {
    clearCookie: (name: string, opts: { path: string }) => void;
  }) {
    reply.clearCookie(REFRESH_COOKIE_NAME, { path: REFRESH_COOKIE_PATH });
  }

  function setRefreshCookie(
    reply: {
      setCookie: (
        name: string,
        value: string,
        opts: {
          httpOnly: boolean;
          sameSite: 'strict';
          path: string;
          secure: boolean;
          maxAge: number;
        }
      ) => void;
    },
    token: string,
    maxAgeSeconds: number
  ) {
    reply.setCookie(REFRESH_COOKIE_NAME, token, {
      httpOnly: true,
      sameSite: 'strict',
      path: REFRESH_COOKIE_PATH,
      secure: fastify.config.COOKIE_SECURE,
      maxAge: Math.max(0, Math.floor(maxAgeSeconds)),
    });
  }

  fastify.post(
    '/auth/login',
    {
      config: rateLimitConfig(),
      schema: {
        operationId: 'login',
        tags: ['auth'],
        body: loginBodySchema,
        response: {
          200: sessionResponseSchema,
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

      if (!found || !found.active || !found.passwordHash || found.permission === 'crew') {
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

      setRefreshCookie(reply, refreshToken, refreshTtlMs / 1000);

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

  fastify.post(
    '/auth/refresh',
    {
      config: rateLimitConfig(),
      schema: {
        operationId: 'refresh',
        tags: ['auth'],
        response: {
          200: sessionResponseSchema,
          401: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const cookieToken = request.cookies[REFRESH_COOKIE_NAME];
      if (!cookieToken) {
        clearRefreshCookie(reply);
        throw invalidRefreshToken();
      }

      const oldHash = hashRefreshToken(cookieToken);
      const now = fastify.clock.now();

      const [row] = await fastify.db
        .select({ session: webSession, person })
        .from(webSession)
        .innerJoin(person, eq(webSession.personId, person.id))
        .where(
          and(
            eq(webSession.refreshTokenHash, oldHash),
            isNull(webSession.revokedAt),
            gt(webSession.expiresAt, now),
            eq(person.active, true),
            ne(person.permission, 'crew')
          )
        )
        .limit(1);

      if (!row) {
        clearRefreshCookie(reply);
        throw invalidRefreshToken();
      }

      const { token: newToken, hash: newHash } = newRefreshToken();

      const updated = await fastify.db
        .update(webSession)
        .set({ refreshTokenHash: newHash })
        .where(eq(webSession.refreshTokenHash, oldHash))
        .returning({ id: webSession.id });

      if (updated.length === 0) {
        clearRefreshCookie(reply);
        throw invalidRefreshToken();
      }

      const accessToken = await signAccessToken(
        { config: fastify.config, clock: fastify.clock },
        { id: row.person.id, permission: row.person.permission }
      );

      const remainingMs = row.session.expiresAt.getTime() - now.getTime();
      setRefreshCookie(reply, newToken, remainingMs / 1000);

      return reply.status(200).send({
        access_token: accessToken,
        expires_in: fastify.config.ACCESS_TOKEN_TTL_SECONDS,
        person: {
          id: row.person.id,
          display_name: row.person.displayName,
          person_type: row.person.personType,
          permission: row.person.permission,
        },
      });
    }
  );

  fastify.post(
    '/auth/logout',
    {
      config: rateLimitConfig(),
      schema: {
        operationId: 'logout',
        tags: ['auth'],
      },
    },
    async (request, reply) => {
      const cookieToken = request.cookies[REFRESH_COOKIE_NAME];
      if (cookieToken) {
        const hash = hashRefreshToken(cookieToken);
        await fastify.db
          .update(webSession)
          .set({ revokedAt: fastify.clock.now() })
          .where(eq(webSession.refreshTokenHash, hash));
      }

      clearRefreshCookie(reply);
      return reply.status(204).send();
    }
  );
};
