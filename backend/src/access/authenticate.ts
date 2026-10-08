import type { FastifyReply, FastifyRequest } from 'fastify';
import { eq } from 'drizzle-orm';
import { person } from '../db/schema.js';
import { ApiError } from '../errors.js';
import { verifyAccessToken } from './tokens.js';
import type { Permission } from './types.js';

export interface AuthContext {
  personId: string;
  permission: Permission;
  /** Present for device (mobile) tokens; device table/checks land in T04-2. */
  deviceId?: string;
}

declare module 'fastify' {
  interface FastifyRequest {
    auth?: AuthContext;
  }
}

/**
 * Fastify preHandler: reads `Authorization: Bearer ***`, verifies the JWT,
 * then re-checks the person in the database (ADR 0010 "Prüfung bei jeder
 * Anfrage"): not found or inactive -> 401. The permission in `request.auth`
 * always comes from the database row, never from the token, so permission
 * changes and deactivation take effect immediately.
 */
export async function requireAuth(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
  const header = request.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
  }
  const token = header.slice('Bearer '.length).trim();
  const claims = await verifyAccessToken(
    { config: request.server.config, clock: request.server.clock },
    token
  );

  const [found] = await request.server.db
    .select({ id: person.id, permission: person.permission, active: person.active })
    .from(person)
    .where(eq(person.id, claims.personId))
    .limit(1);

  if (!found || !found.active) {
    throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
  }

  // TODO(T04-2): when claims.deviceId is present, also require the matching
  // `device` row to exist with revoked_at null (device table added in T04-2).

  request.auth = {
    personId: found.id,
    permission: found.permission,
    ...(claims.deviceId !== undefined ? { deviceId: claims.deviceId } : {}),
  };
}

/**
 * preHandler factory restricting a route to the given permissions.
 * Administrators always pass, regardless of the list. Must run after requireAuth.
 */
export function requirePermission(...permissions: Permission[]) {
  return async function requirePermissionHandler(
    request: FastifyRequest,
    _reply: FastifyReply
  ): Promise<void> {
    if (!request.auth) {
      throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
    }
    if (request.auth.permission === 'admin') return;
    if (!permissions.includes(request.auth.permission)) {
      throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
    }
  };
}
