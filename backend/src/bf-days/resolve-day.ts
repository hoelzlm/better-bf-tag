import { eq } from 'drizzle-orm';
import { bfDay } from '../db/schema.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';
import type { BfDayRow } from '../routes/bf-day-schemas.js';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function bfDayNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'BF-Tag nicht gefunden.');
}

/**
 * Resolves the `{day}` path param used by the bf-days routes (ADR 0013): a
 * UUID, or the literal `current` meaning the currently running BF-Tag.
 * Throws 404 `not_found` for an unknown UUID, a malformed value, or
 * `current` when no BF-Tag is running. Shared with T05-2's shift routes.
 */
export async function resolveBfDay(tx: Tx, day: string): Promise<BfDayRow> {
  if (day === 'current') {
    const [row] = await tx.select().from(bfDay).where(eq(bfDay.state, 'running')).limit(1);
    if (!row) throw bfDayNotFound();
    return row;
  }
  if (!UUID_RE.test(day)) {
    throw bfDayNotFound();
  }
  const [row] = await tx.select().from(bfDay).where(eq(bfDay.id, day)).limit(1);
  if (!row) throw bfDayNotFound();
  return row;
}
