import type { FastifyReply, FastifyRequest } from 'fastify';
import { and, eq, isNull } from 'drizzle-orm';
import { person, device, monitorDisplay } from '../db/schema.js';
import type { Db } from '../db/client.js';
import { ApiError } from '../errors.js';
import { verifyAccessToken, type AccessTokenClaims } from './tokens.js';
import type { Permission } from './types.js';

/**
 * The request Principal (ADR 0012): a Person (web/mobile, as before) or a
 * Monitor (read-only, no `permission`). Discriminated by `kind` so handlers
 * can't accidentally read `permission`/`personId` off a Monitor principal.
 */
export type AuthContext =
  | {
      kind: 'person';
      personId: string;
      permission: Permission;
      /** Present for device (mobile) tokens. */
      deviceId?: string;
    }
  | {
      kind: 'monitor';
      monitorId: string;
    };

declare module 'fastify' {
  interface FastifyRequest {
    auth?: AuthContext;
  }
}

/**
 * Re-checks the claims from a verified access token against the database
 * (ADR 0010 "Prüfung bei jeder Anfrage", extended by ADR 0012 for monitors):
 * for a person, not found/inactive, or (for device tokens) a revoked device
 * -> 401. For a monitor, not found, revoked, or never paired -> 401. The
 * returned Principal's fields always come from the database row, never
 * from the token, so permission changes, deactivation, and monitor
 * revocation take effect immediately. Shared between `requireAuth` (HTTP)
 * and the `/ws` connection handler.
 */
export async function resolvePrincipal(
  deps: { db: Db },
  claims: AccessTokenClaims
): Promise<AuthContext> {
  if (claims.kind === 'monitor') {
    const [found] = await deps.db
      .select({
        id: monitorDisplay.id,
        revokedAt: monitorDisplay.revokedAt,
        refreshTokenHash: monitorDisplay.refreshTokenHash,
      })
      .from(monitorDisplay)
      .where(eq(monitorDisplay.id, claims.monitorId))
      .limit(1);
    if (!found || found.revokedAt !== null || found.refreshTokenHash === null) {
      throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
    }
    return { kind: 'monitor', monitorId: found.id };
  }

  const [found] = await deps.db
    .select({ id: person.id, permission: person.permission, active: person.active })
    .from(person)
    .where(eq(person.id, claims.personId))
    .limit(1);

  if (!found || !found.active) {
    throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
  }

  if (claims.deviceId !== undefined) {
    const [deviceRow] = await deps.db
      .select({ id: device.id })
      .from(device)
      .where(and(eq(device.id, claims.deviceId), isNull(device.revokedAt)))
      .limit(1);
    if (!deviceRow) {
      throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
    }
  }

  return {
    kind: 'person',
    personId: found.id,
    permission: found.permission,
    ...(claims.deviceId !== undefined ? { deviceId: claims.deviceId } : {}),
  };
}

export interface RequireAuthOptions {
  /**
   * Opt-in for a route to accept a Monitor principal (ADR 0012 "sicher per
   * Voreinstellung"): without this, a Monitor principal is rejected with
   * 403 `forbidden` before the route handler ever runs. See
   * backend/README.md for the full list of monitor-readable routes.
   */
  allowMonitor?: boolean;
}

/**
 * Fastify preHandler factory: reads `Authorization: Bearer ***`, verifies
 * the JWT, then re-checks the principal in the database (`resolvePrincipal`).
 * By default a Monitor principal is rejected with 403 `forbidden`; pass
 * `{ allowMonitor: true }` for routes that explicitly allow monitors.
 */
export function requireAuth(options: RequireAuthOptions = {}) {
  return async function requireAuthHandler(
    request: FastifyRequest,
    _reply: FastifyReply
  ): Promise<void> {
    const header = request.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
    }
    const token = header.slice('Bearer '.length).trim();
    const claims = await verifyAccessToken(
      { config: request.server.config, clock: request.server.clock },
      token
    );

    const principal = await resolvePrincipal({ db: request.server.db }, claims);

    if (principal.kind === 'monitor' && !options.allowMonitor) {
      throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
    }

    request.auth = principal;
  };
}

/**
 * preHandler factory restricting a route to the given permissions.
 * Administrators always pass, regardless of the list. Must run after
 * requireAuth(). Only meaningful for person principals: a monitor
 * principal is rejected with 403 (routes with permission checks never
 * set `allowMonitor`, so this should be unreachable in practice, but stays
 * defensive).
 */
export function requirePermission(...permissions: Permission[]) {
  return async function requirePermissionHandler(
    request: FastifyRequest,
    _reply: FastifyReply
  ): Promise<void> {
    if (!request.auth) {
      throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
    }
    if (request.auth.kind !== 'person') {
      throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
    }
    if (request.auth.permission === 'admin') return;
    if (!permissions.includes(request.auth.permission)) {
      throw new ApiError(403, 'forbidden', 'Keine Berechtigung.');
    }
  };
}
