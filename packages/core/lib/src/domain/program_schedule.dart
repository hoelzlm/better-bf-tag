import 'program_item.dart';

/// Result of [currentAndNext]: the "aktuelle" and "nächste" Programmpunkte
/// at a given point in time (ADR 0025, "Aktuell / nächster / vergangen").
class ProgramNow {
  const ProgramNow({this.current, this.next});

  final ProgramItem? current;
  final ProgramItem? next;
}

/// Whether [item] is "aktuell" at [now]: `starts_at <= now < ends_at`.
/// Compared in UTC.
bool isCurrentProgramItem(ProgramItem item, DateTime now) {
  final utcNow = now.toUtc();
  return !item.startsAt.isAfter(utcNow) && item.endsAt.isAfter(utcNow);
}

/// Whether [item] is "vergangen" at [now]: `ends_at <= now`. Compared in
/// UTC.
bool isPastProgramItem(ProgramItem item, DateTime now) {
  final utcNow = now.toUtc();
  return !item.endsAt.isAfter(utcNow);
}

/// Computes the "aktuelle" and "nächste" Programmpunkte at [now] (ADR 0025).
///
/// [sortedItems] must already be sorted the way the backend sorts them
/// (`starts_at`, then `ends_at`, then `id`).
///
/// "aktuell": among items with `starts_at <= now < ends_at`, the one with
/// the latest `starts_at` (ties broken by picking the first of those in
/// [sortedItems]).
///
/// "nächster": the first item in [sortedItems] with `starts_at > now`.
///
/// Compared in UTC.
ProgramNow currentAndNext(List<ProgramItem> sortedItems, DateTime now) {
  final utcNow = now.toUtc();

  ProgramItem? current;
  for (final item in sortedItems) {
    if (!isCurrentProgramItem(item, utcNow)) continue;
    if (current == null || item.startsAt.isAfter(current.startsAt)) {
      current = item;
    }
  }

  ProgramItem? next;
  for (final item in sortedItems) {
    if (item.startsAt.isAfter(utcNow)) {
      next = item;
      break;
    }
  }

  return ProgramNow(current: current, next: next);
}
