import { createHash, randomBytes } from 'node:crypto';
import { SignJWT, jwtVerify } from 'jose';
import type { Clock } from '../clock.js';
import type { Config } from '../config.js';
import { ApiError } from '../errors.js';
import type { Permission } from './types.js';

export interface TokenDeps {
  config: Config;
  clock: Clock;
}

export interface SignablePerson {
  id: string;
  permission: Permission;
  /** Present for device (mobile) tokens; added to the token as claim `device_id`. */
  deviceId?: string;
}

export interface SignableMonitor {
  id: string;
}

/**
 * Access-token claims (ADR 0012): a Person token carries no `kind` claim
 * (or `kind: "person"`); a Monitor token carries `kind: "monitor"` and no
 * `permission`. Discriminated so callers can't accidentally read
 * `permission` off a monitor token.
 */
export type AccessTokenClaims =
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

function secretKey(config: Config): Uint8Array {
  return new TextEncoder().encode(config.JWT_SECRET);
}

/** Signs an access token. iat/exp are computed from deps.clock, never from the system clock. */
export async function signAccessToken(deps: TokenDeps, person: SignablePerson): Promise<string> {
  const nowSeconds = Math.floor(deps.clock.now().getTime() / 1000);
  const exp = nowSeconds + deps.config.ACCESS_TOKEN_TTL_SECONDS;

  return new SignJWT({
    permission: person.permission,
    ...(person.deviceId !== undefined ? { device_id: person.deviceId } : {}),
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(person.id)
    .setIssuedAt(nowSeconds)
    .setExpirationTime(exp)
    .sign(secretKey(deps.config));
}

/** Signs a Monitor access token (ADR 0012): `sub` = monitor id, claim `kind: "monitor"`, no `permission`. */
export async function signMonitorAccessToken(
  deps: TokenDeps,
  monitor: SignableMonitor
): Promise<string> {
  const nowSeconds = Math.floor(deps.clock.now().getTime() / 1000);
  const exp = nowSeconds + deps.config.ACCESS_TOKEN_TTL_SECONDS;

  return new SignJWT({ kind: 'monitor' })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(monitor.id)
    .setIssuedAt(nowSeconds)
    .setExpirationTime(exp)
    .sign(secretKey(deps.config));
}

/** Verifies an access token against deps.clock.now() (not the system clock) and throws 401 on any failure. */
export async function verifyAccessToken(
  deps: TokenDeps,
  token: string
): Promise<AccessTokenClaims> {
  try {
    const { payload } = await jwtVerify(token, secretKey(deps.config), {
      currentDate: deps.clock.now(),
    });

    if (payload['kind'] === 'monitor') {
      const monitorId = payload.sub;
      if (typeof monitorId !== 'string') {
        throw new Error('monitor access token missing sub claim');
      }
      return { kind: 'monitor', monitorId };
    }

    const personId = payload.sub;
    const permission = payload['permission'];
    if (typeof personId !== 'string' || typeof permission !== 'string') {
      throw new Error('access token missing required claims');
    }
    const deviceIdClaim = payload['device_id'];
    const deviceId = typeof deviceIdClaim === 'string' ? deviceIdClaim : undefined;
    return {
      kind: 'person',
      personId,
      permission: permission as Permission,
      ...(deviceId !== undefined ? { deviceId } : {}),
    };
  } catch {
    throw new ApiError(401, 'unauthorized', 'Nicht authentifiziert.');
  }
}

/** A fresh opaque refresh token plus the hash that should be stored (never the raw token). */
export function newRefreshToken(): { token: string; hash: string } {
  const token = randomBytes(32).toString('base64url');
  return { token, hash: hashRefreshToken(token) };
}

export function hashRefreshToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
