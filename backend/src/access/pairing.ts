import { randomInt, createHash } from 'node:crypto';
import { and, eq, isNull } from 'drizzle-orm';
import { pairingCode } from '../db/schema.js';
import type { Tx } from '../realtime/realtime.js';
import type { Clock } from '../clock.js';
import type { Config } from '../config.js';

/** Excludes 0/O/1/I to avoid ambiguity when read aloud or handwritten (ADR 0010). */
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 8;

export type PairingTargetType = 'person' | 'monitor';

/** 8 cryptographically random characters from ALPHABET (ADR 0010). */
export function generatePairingCode(): string {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += ALPHABET[randomInt(ALPHABET.length)];
  }
  return code;
}

/** Normalizes user input for comparison/hashing: uppercase, strip spaces and hyphens. */
export function normalizePairingCode(input: string): string {
  return input.toUpperCase().replace(/[\s-]/g, '');
}

/** SHA-256 hex digest of the normalized code; this is what's stored as `pairing_code.code_hash`. */
export function hashPairingCode(code: string): string {
  return createHash('sha256').update(normalizePairingCode(code)).digest('hex');
}

/** Formats the raw 8-character code for display/QR as `ABCD-EFGH`. */
export function formatPairingCode(code: string): string {
  return `${code.slice(0, 4)}-${code.slice(4)}`;
}

/**
 * Creates a fresh pairing code for a target, deleting that target's older
 * unused codes first (ADR 0010: "ein neuer Code [...] macht ihre älteren,
 * unbenutzten Codes ungültig"). Returns the raw code (only ever returned to
 * the caller that created it) and its expiry.
 */
export async function createPairingCodeForTarget(
  tx: Tx,
  deps: { clock: Clock; config: Config },
  targetType: PairingTargetType,
  targetId: string
): Promise<{ code: string; expiresAt: Date }> {
  await tx
    .delete(pairingCode)
    .where(
      and(
        eq(pairingCode.targetType, targetType),
        eq(pairingCode.targetId, targetId),
        isNull(pairingCode.usedAt)
      )
    );

  const code = generatePairingCode();
  const now = deps.clock.now();
  const expiresAt = new Date(now.getTime() + deps.config.PAIRING_CODE_TTL_HOURS * 60 * 60 * 1000);

  await tx.insert(pairingCode).values({
    codeHash: hashPairingCode(code),
    targetType,
    targetId,
    createdAt: now,
    expiresAt,
    usedAt: null,
  });

  return { code, expiresAt };
}
