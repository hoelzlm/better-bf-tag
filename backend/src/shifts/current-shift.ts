/**
 * Implements the "aktuelle Schicht" rule (ADR 0013): among shifts with
 * `starts_at <= now < ends_at`, the one with the latest `starts_at` wins;
 * ties broken by the earlier `ends_at`, then by the smaller `id`. No
 * matching shift -> `null`. Shared logic exists identically in
 * `packages/core` (`currentShift(shifts, now)`), tested the same way in
 * both places.
 */
export function currentShift<T extends { id: string; startsAt: Date; endsAt: Date }>(
  shifts: T[],
  now: Date
): T | null {
  const nowMs = now.getTime();
  let best: T | null = null;

  for (const candidate of shifts) {
    const startsAtMs = candidate.startsAt.getTime();
    const endsAtMs = candidate.endsAt.getTime();
    if (!(startsAtMs <= nowMs && nowMs < endsAtMs)) continue;

    if (best === null) {
      best = candidate;
      continue;
    }

    if (startsAtMs !== best.startsAt.getTime()) {
      if (startsAtMs > best.startsAt.getTime()) {
        best = candidate;
      }
      continue;
    }

    if (endsAtMs !== best.endsAt.getTime()) {
      if (endsAtMs < best.endsAt.getTime()) {
        best = candidate;
      }
      continue;
    }

    if (candidate.id < best.id) {
      best = candidate;
    }
  }

  return best;
}
