import 'shift.dart';

/// Implements the "aktuelle Schicht" rule (ADR 0013): among shifts with
/// `starts_at <= now < ends_at`, the one with the latest `starts_at` wins;
/// ties broken by the earlier `ends_at`, then by the smaller `id`. No
/// matching shift -> `null`. Identical rule to
/// `backend/src/shifts/current-shift.ts`, tested the same way in both
/// places.
Shift? currentShift(List<Shift> shifts, DateTime now) {
  Shift? best;

  for (final candidate in shifts) {
    final isActive = !candidate.startsAt.isAfter(now) &&
        candidate.endsAt.isAfter(now);
    if (!isActive) continue;

    if (best == null) {
      best = candidate;
      continue;
    }

    if (candidate.startsAt != best.startsAt) {
      if (candidate.startsAt.isAfter(best.startsAt)) {
        best = candidate;
      }
      continue;
    }

    if (candidate.endsAt != best.endsAt) {
      if (candidate.endsAt.isBefore(best.endsAt)) {
        best = candidate;
      }
      continue;
    }

    if (candidate.id.compareTo(best.id) < 0) {
      best = candidate;
    }
  }

  return best;
}
