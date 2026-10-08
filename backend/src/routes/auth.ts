import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, eq, gt, isNull, ne } from 'drizzle-orm';
import { person, webSession, device, pairingCode, monitorDisplay } from '../db/schema.js';
import { verifyPassword } from '../access/passwords.js';
import {
  hashRefreshToken,
  newRefreshToken,
  signAccessToken,
  signMonitorAccessToken,
} from '../access/tokens.js';
import { personSummarySchema, errorResponseSchema } from '../access/schemas.js';
import { hashPairingCode } from '../access/pairing.js';
import { requireAuth } from '../access/authenticate.js';
import { monitorSummarySchema } from './monitor-schemas.js';
import { ApiError } from '../errors.js';
import type { PersonType, Permission } from '../access/types.js';

const loginBodySchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

const sessionResponseSchema = z.object({
  access_token: z.string(),
  expires_in: z.number(),
  person: personSummarySchema,
});

const pairBodySchema = z.object({
  code: z.string().min(1),
  platform: z.enum(['android', 'ios']),
  app_version: z.string().min(1),
  device_name: z.string().optional(),
});

const deviceRefreshBodySchema = z.object({
  refresh_token: z.string().min(1),
});

const monitorPairBodySchema = z.object({
  code: z.string().min(1),
});

const monitorRefreshBodySchema = z.object({
  refresh_token: z.string().min(1),
});

const monitorSessionResponseSchema = z.object({
  access_token: z.string(),
  refresh_token: z.string(),
  expires_in: z.number(),
  monitor: monitorSummarySchema,
});

const deviceSessionResponseSchema = z.object({
  access_token: z.string(),
  refresh_token: z.string(),
  expires_in: z.number(),
  device_id: z.string(),
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

function invalidPairingCode(): ApiError {
  return new ApiError(
    401,
    'invalid_pairing_code',
    'Ungültiger, abgelaufener oder bereits benutzter Kopplungscode.'
  );
}

function invalidMonitorRefreshToken(): ApiError {
  return new ApiError(401, 'invalid_refresh_token', 'Ungültiges oder widerrufenes Refresh-Token.');
}

interface PersonSummarySource {
  id: string;
  displayName: string;
  personType: PersonType;
  permission: Permission;
}

function toPersonSummary(row: PersonSummarySource) {
  return {
    id: row.id,
    display_name: row.displayName,
    person_type: row.personType,
    permission: row.permission,
  };
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

  fastify.post(
    '/auth/pair',
    {
      config: rateLimitConfig(),
      schema: {
        operationId: 'pair',
        tags: ['auth'],
        body: pairBodySchema,
        response: {
          200: deviceSessionResponseSchema,
          401: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const codeHash = hashPairingCode(request.body.code);
      const now = fastify.clock.now();

      const result = await fastify.db.transaction(async tx => {
        const [row] = await tx
          .select()
          .from(pairingCode)
          .where(eq(pairingCode.codeHash, codeHash))
          .limit(1);
        if (!row) {
          throw invalidPairingCode();
        }
        // /auth/pair is person-only (ADR 0012): a monitor code is rejected
        // the same way an invalid code would be. /auth/monitor/pair below
        // is the converse: it rejects person codes.
        if (row.targetType !== 'person') {
          throw invalidPairingCode();
        }
        if (row.usedAt !== null || row.expiresAt <= now) {
          throw invalidPairingCode();
        }

        // Conditional update (`used_at IS NULL`): under READ COMMITTED,
        // a concurrent redemption that already committed its own update
        // makes this UPDATE affect 0 rows once it re-evaluates the WHERE
        // clause after the row lock is released, so exactly one caller
        // wins (ADR 0010).
        const updated = await tx
          .update(pairingCode)
          .set({ usedAt: now })
          .where(and(eq(pairingCode.codeHash, codeHash), isNull(pairingCode.usedAt)))
          .returning({ codeHash: pairingCode.codeHash });
        if (updated.length === 0) {
          throw invalidPairingCode();
        }

        const [personRow] = await tx
          .select()
          .from(person)
          .where(eq(person.id, row.targetId))
          .limit(1);
        if (!personRow || !personRow.active) {
          throw invalidPairingCode();
        }

        const { token: refreshToken, hash: refreshTokenHash } = newRefreshToken();
        const [deviceRow] = await tx
          .insert(device)
          .values({
            personId: personRow.id,
            platform: request.body.platform,
            deviceName: request.body.device_name ?? null,
            appVersion: request.body.app_version,
            pushToken: null,
            refreshTokenHash,
            createdAt: now,
            lastSeenAt: now,
            revokedAt: null,
          })
          .returning();
        if (!deviceRow) {
          throw new Error('pair: insert device returned no row');
        }

        const accessToken = await signAccessToken(
          { config: fastify.config, clock: fastify.clock },
          { id: personRow.id, permission: personRow.permission, deviceId: deviceRow.id }
        );

        return {
          access_token: accessToken,
          refresh_token: refreshToken,
          expires_in: fastify.config.ACCESS_TOKEN_TTL_SECONDS,
          device_id: deviceRow.id,
          person: toPersonSummary(personRow),
        };
      });

      return reply.status(200).send(result);
    }
  );

  fastify.post(
    '/auth/device/refresh',
    {
      config: rateLimitConfig(),
      schema: {
        operationId: 'deviceRefresh',
        tags: ['auth'],
        body: deviceRefreshBodySchema,
        response: {
          200: deviceSessionResponseSchema,
          401: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const oldHash = hashRefreshToken(request.body.refresh_token);
      const now = fastify.clock.now();

      const result = await fastify.db.transaction(async tx => {
        const [row] = await tx
          .select({ device, person })
          .from(device)
          .innerJoin(person, eq(device.personId, person.id))
          .where(
            and(
              eq(device.refreshTokenHash, oldHash),
              isNull(device.revokedAt),
              eq(person.active, true)
            )
          )
          .limit(1);
        if (!row) {
          throw invalidRefreshToken();
        }

        const { token: newToken, hash: newHash } = newRefreshToken();
        const updated = await tx
          .update(device)
          .set({ refreshTokenHash: newHash, lastSeenAt: now })
          .where(eq(device.refreshTokenHash, oldHash))
          .returning({ id: device.id });
        if (updated.length === 0) {
          throw invalidRefreshToken();
        }

        const accessToken = await signAccessToken(
          { config: fastify.config, clock: fastify.clock },
          { id: row.person.id, permission: row.person.permission, deviceId: row.device.id }
        );

        return {
          access_token: accessToken,
          refresh_token: newToken,
          expires_in: fastify.config.ACCESS_TOKEN_TTL_SECONDS,
          device_id: row.device.id,
          person: toPersonSummary(row.person),
        };
      });

      return reply.status(200).send(result);
    }
  );

  fastify.post(
    '/auth/device/logout',
    {
      config: rateLimitConfig(),
      preHandler: [requireAuth()],
      schema: {
        operationId: 'deviceLogout',
        tags: ['auth'],
      },
    },
    async (request, reply) => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'person' || !auth.deviceId) {
        throw new ApiError(400, 'not_a_device_session', 'Kein Geräte-Zugriffstoken.');
      }

      await fastify.db
        .update(device)
        .set({ revokedAt: fastify.clock.now() })
        .where(and(eq(device.id, auth.deviceId), isNull(device.revokedAt)));

      fastify.wsHub.revokeDevice(auth.deviceId);

      return reply.status(204).send();
    }
  );

  fastify.post(
    '/auth/monitor/pair',
    {
      config: rateLimitConfig(),
      schema: {
        operationId: 'monitorPair',
        tags: ['auth'],
        body: monitorPairBodySchema,
        response: {
          200: monitorSessionResponseSchema,
          401: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const codeHash = hashPairingCode(request.body.code);
      const now = fastify.clock.now();

      const result = await fastify.db.transaction(async tx => {
        const [row] = await tx
          .select()
          .from(pairingCode)
          .where(eq(pairingCode.codeHash, codeHash))
          .limit(1);
        if (!row) {
          throw invalidPairingCode();
        }
        // /auth/monitor/pair is monitor-only (ADR 0012): a person code is
        // rejected the same way an invalid code would be.
        if (row.targetType !== 'monitor') {
          throw invalidPairingCode();
        }
        if (row.usedAt !== null || row.expiresAt <= now) {
          throw invalidPairingCode();
        }

        // Conditional update (`used_at IS NULL`), same reasoning as
        // /auth/pair above: exactly one concurrent redemption wins.
        const updated = await tx
          .update(pairingCode)
          .set({ usedAt: now })
          .where(and(eq(pairingCode.codeHash, codeHash), isNull(pairingCode.usedAt)))
          .returning({ codeHash: pairingCode.codeHash });
        if (updated.length === 0) {
          throw invalidPairingCode();
        }

        const [monitorRow] = await tx
          .select()
          .from(monitorDisplay)
          .where(eq(monitorDisplay.id, row.targetId))
          .limit(1);
        if (!monitorRow) {
          throw invalidPairingCode();
        }

        // A monitor has exactly one active session (ADR 0012): a previous
        // hash means a previous session exists and must be ended.
        const hadPreviousSession = monitorRow.refreshTokenHash !== null;

        const { token: refreshToken, hash: refreshTokenHash } = newRefreshToken();
        const [updatedMonitor] = await tx
          .update(monitorDisplay)
          .set({
            refreshTokenHash,
            pairedAt: now,
            lastSeenAt: now,
            revokedAt: null,
          })
          .where(eq(monitorDisplay.id, monitorRow.id))
          .returning();
        if (!updatedMonitor) {
          throw new Error('monitorPair: update returned no row');
        }

        const accessToken = await signMonitorAccessToken(
          { config: fastify.config, clock: fastify.clock },
          { id: updatedMonitor.id }
        );

        return {
          hadPreviousSession,
          session: {
            access_token: accessToken,
            refresh_token: refreshToken,
            expires_in: fastify.config.ACCESS_TOKEN_TTL_SECONDS,
            monitor: { id: updatedMonitor.id, name: updatedMonitor.name },
          },
        };
      });

      // Right after commit, before any new client could connect with the
      // new token (ADR 0012): end the monitor's previous session, if any.
      if (result.hadPreviousSession) {
        fastify.wsHub.revokeMonitor(result.session.monitor.id);
      }

      return reply.status(200).send(result.session);
    }
  );

  fastify.post(
    '/auth/monitor/refresh',
    {
      config: rateLimitConfig(),
      schema: {
        operationId: 'monitorRefresh',
        tags: ['auth'],
        body: monitorRefreshBodySchema,
        response: {
          200: monitorSessionResponseSchema,
          401: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const oldHash = hashRefreshToken(request.body.refresh_token);
      const now = fastify.clock.now();

      const result = await fastify.db.transaction(async tx => {
        const [row] = await tx
          .select()
          .from(monitorDisplay)
          .where(
            and(eq(monitorDisplay.refreshTokenHash, oldHash), isNull(monitorDisplay.revokedAt))
          )
          .limit(1);
        if (!row) {
          throw invalidMonitorRefreshToken();
        }

        const { token: newToken, hash: newHash } = newRefreshToken();
        const updated = await tx
          .update(monitorDisplay)
          .set({ refreshTokenHash: newHash, lastSeenAt: now })
          .where(eq(monitorDisplay.refreshTokenHash, oldHash))
          .returning();
        if (updated.length === 0) {
          throw invalidMonitorRefreshToken();
        }
        const updatedRow = updated[0]!;

        const accessToken = await signMonitorAccessToken(
          { config: fastify.config, clock: fastify.clock },
          { id: updatedRow.id }
        );

        return {
          access_token: accessToken,
          refresh_token: newToken,
          expires_in: fastify.config.ACCESS_TOKEN_TTL_SECONDS,
          monitor: { id: updatedRow.id, name: updatedRow.name },
        };
      });

      return reply.status(200).send(result);
    }
  );

  fastify.get(
    '/monitor/me',
    {
      preHandler: [requireAuth({ allowMonitor: true })],
      schema: {
        operationId: 'getMonitorMe',
        tags: ['auth'],
        response: {
          200: monitorSummarySchema,
          403: errorResponseSchema,
        },
      },
    },
    async request => {
      const auth = request.auth;
      if (!auth || auth.kind !== 'monitor') {
        throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
      }

      const [found] = await fastify.db
        .select()
        .from(monitorDisplay)
        .where(eq(monitorDisplay.id, auth.monitorId))
        .limit(1);
      if (!found) {
        throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
      }

      return { id: found.id, name: found.name };
    }
  );
};
