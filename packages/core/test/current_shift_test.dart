import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

// Ported 1:1 from backend/test/current-shift.test.ts (ADR 0013).
Shift _shift(String id, String startsAt, String endsAt) {
  return Shift(
    id: id,
    bfDayId: 'day',
    name: id,
    startsAt: DateTime.parse(startsAt),
    endsAt: DateTime.parse(endsAt),
    crew: const [],
  );
}

void main() {
  group('currentShift', () {
    test('returns null when there are no shifts', () {
      expect(currentShift([], DateTime.parse('2026-06-01T12:00:00Z')), isNull);
    });

    test('returns null when now is before all shifts', () {
      final shifts = [_shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
      expect(
        currentShift(shifts, DateTime.parse('2026-06-01T07:59:59.999Z')),
        isNull,
      );
    });

    test('returns null when now is after all shifts', () {
      final shifts = [_shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
      expect(
        currentShift(shifts, DateTime.parse('2026-06-02T08:00:00.001Z')),
        isNull,
      );
    });

    test('includes the boundary exactly at starts_at', () {
      final shifts = [_shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
      final result =
          currentShift(shifts, DateTime.parse('2026-06-01T08:00:00.000Z'));
      expect(result?.id, 'a');
    });

    test('excludes the boundary exactly at ends_at', () {
      final shifts = [_shift('a', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z')];
      final result =
          currentShift(shifts, DateTime.parse('2026-06-02T08:00:00.000Z'));
      expect(result, isNull);
    });

    test('prefers the overlapping night shift over the default 24h shift', () {
      final defaultShift =
          _shift('default', '2026-06-01T00:00:00Z', '2026-06-02T00:00:00Z');
      final nightShift =
          _shift('night', '2026-06-01T22:00:00Z', '2026-06-02T06:00:00Z');
      final result = currentShift(
        [defaultShift, nightShift],
        DateTime.parse('2026-06-01T23:00:00Z'),
      );
      expect(result?.id, 'night');
    });

    test('breaks a starts_at tie by the earlier ends_at', () {
      final longer =
          _shift('longer', '2026-06-01T08:00:00Z', '2026-06-02T08:00:00Z');
      final shorter =
          _shift('shorter', '2026-06-01T08:00:00Z', '2026-06-01T12:00:00Z');
      final result = currentShift(
        [longer, shorter],
        DateTime.parse('2026-06-01T09:00:00Z'),
      );
      expect(result?.id, 'shorter');
    });

    test('breaks a starts_at and ends_at tie by the smaller id', () {
      final b = _shift('b', '2026-06-01T08:00:00Z', '2026-06-01T12:00:00Z');
      final a = _shift('a', '2026-06-01T08:00:00Z', '2026-06-01T12:00:00Z');
      final result =
          currentShift([b, a], DateTime.parse('2026-06-01T09:00:00Z'));
      expect(result?.id, 'a');
    });
  });
}
