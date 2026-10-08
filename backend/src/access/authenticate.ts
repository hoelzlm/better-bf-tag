import type { FastifyReply, FastifyRequest } from 'fastify';
import { ApiError } from '../errors.js';
import { verifyAccessToken } from './tokens.js';
import type { Permission } from './types.js';

export interface AuthContext {
  personId: string;
  permission: Permission;
}

declare module 'fastify' {
  interface FastifyRequest {
    auth?: AuthContext;
  }
}

/** Fastify preHandler: reads `Authorization: Bearer <jwt>`, sets request.auth, or throws 401. */
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
  request.auth = { personId: claims.personId, permission: claims.permission };
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
