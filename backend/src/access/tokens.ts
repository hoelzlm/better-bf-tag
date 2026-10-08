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

export interface AccessTokenClaims {
  personId: string;
  permission: Permission;
  /** Present for device (mobile) tokens; device table/checks land in T04-2. */
  deviceId?: string;
}

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

/** Verifies an access token against deps.clock.now() (not the system clock) and throws 401 on any failure. */
export async function verifyAccessToken(
  deps: TokenDeps,
  token: string
): Promise<AccessTokenClaims> {
  try {
    const { payload } = await jwtVerify(token, secretKey(deps.config), {
      currentDate: deps.clock.now(),
    });
    const personId = payload.sub;
    const permission = payload['permission'];
    if (typeof personId !== 'string' || typeof permission !== 'string') {
      throw new Error('access token missing required claims');
    }
    const deviceIdClaim = payload['device_id'];
    const deviceId = typeof deviceIdClaim === 'string' ? deviceIdClaim : undefined;
    return {
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
