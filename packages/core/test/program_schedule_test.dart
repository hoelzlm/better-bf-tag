import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

ProgramItem _item({
  required String id,
  String bfDayId = 'day1',
  String title = 'Programmpunkt',
  ProgramItemType type = ProgramItemType.other,
  required String startsAt,
  required String endsAt,
}) {
  return ProgramItem(
    id: id,
    bfDayId: bfDayId,
    title: title,
    type: type,
    startsAt: DateTime.parse(startsAt),
    endsAt: DateTime.parse(endsAt),
  );
}

void main() {
  group('isCurrentProgramItem (ADR 0025)', () {
    final item = _item(
      id: 'pi1',
      startsAt: '2026-10-11T10:00:00Z',
      endsAt: '2026-10-11T11:00:00Z',
    );

    test('starts_at == now is current', () {
      expect(
        isCurrentProgramItem(item, DateTime.parse('2026-10-11T10:00:00Z')),
        isTrue,
      );
    });

    test('between starts_at and ends_at is current', () {
      expect(
        isCurrentProgramItem(item, DateTime.parse('2026-10-11T10:30:00Z')),
        isTrue,
      );
    });

    test('ends_at == now is not current (and past)', () {
      final now = DateTime.parse('2026-10-11T11:00:00Z');
      expect(isCurrentProgramItem(item, now), isFalse);
      expect(isPastProgramItem(item, now), isTrue);
    });

    test('before starts_at is not current', () {
      expect(
        isCurrentProgramItem(item, DateTime.parse('2026-10-11T09:59:00Z')),
        isFalse,
      );
    });

    test('after ends_at is not current', () {
      expect(
        isCurrentProgramItem(item, DateTime.parse('2026-10-11T12:00:00Z')),
        isFalse,
      );
    });
  });

  group('isPastProgramItem (ADR 0025)', () {
    final item = _item(
      id: 'pi1',
      startsAt: '2026-10-11T10:00:00Z',
      endsAt: '2026-10-11T11:00:00Z',
    );

    test('before ends_at is not past', () {
      expect(
        isPastProgramItem(item, DateTime.parse('2026-10-11T10:30:00Z')),
        isFalse,
      );
    });

    test('ends_at == now is past', () {
      expect(
        isPastProgramItem(item, DateTime.parse('2026-10-11T11:00:00Z')),
        isTrue,
      );
    });

    test('after ends_at is past', () {
      expect(
        isPastProgramItem(item, DateTime.parse('2026-10-11T12:00:00Z')),
        isTrue,
      );
    });
  });

  group('currentAndNext (ADR 0025)', () {
    test('empty list: no current, no next', () {
      final result = currentAndNext(const [], DateTime.parse('2026-10-11T10:00:00Z'));
      expect(result.current, isNull);
      expect(result.next, isNull);
    });

    test('finds the current item and the next upcoming item', () {
      final a = _item(
        id: 'a',
        startsAt: '2026-10-11T08:00:00Z',
        endsAt: '2026-10-11T09:00:00Z',
      );
      final b = _item(
        id: 'b',
        startsAt: '2026-10-11T09:00:00Z',
        endsAt: '2026-10-11T10:00:00Z',
      );
      final c = _item(
        id: 'c',
        startsAt: '2026-10-11T10:00:00Z',
        endsAt: '2026-10-11T11:00:00Z',
      );
      final sorted = [a, b, c];

      final result = currentAndNext(sorted, DateTime.parse('2026-10-11T09:30:00Z'));
      expect(result.current, b);
      expect(result.next, c);
    });

    test('no current item: next is the first item with starts_at > now', () {
      final a = _item(
        id: 'a',
        startsAt: '2026-10-11T08:00:00Z',
        endsAt: '2026-10-11T09:00:00Z',
      );
      final b = _item(
        id: 'b',
        startsAt: '2026-10-11T10:00:00Z',
        endsAt: '2026-10-11T11:00:00Z',
      );
      final sorted = [a, b];

      final result = currentAndNext(sorted, DateTime.parse('2026-10-11T09:30:00Z'));
      expect(result.current, isNull);
      expect(result.next, b);
    });

    test('no items after now: next is null', () {
      final a = _item(
        id: 'a',
        startsAt: '2026-10-11T08:00:00Z',
        endsAt: '2026-10-11T09:00:00Z',
      );

      final result = currentAndNext([a], DateTime.parse('2026-10-11T10:00:00Z'));
      expect(result.current, isNull);
      expect(result.next, isNull);
    });

    test('overlap: picks the one with the latest starts_at', () {
      final a = _item(
        id: 'a',
        startsAt: '2026-10-11T08:00:00Z',
        endsAt: '2026-10-11T11:00:00Z',
      );
      final b = _item(
        id: 'b',
        startsAt: '2026-10-11T09:00:00Z',
        endsAt: '2026-10-11T10:00:00Z',
      );
      final sorted = [a, b];

      final result = currentAndNext(sorted, DateTime.parse('2026-10-11T09:30:00Z'));
      expect(result.current, b);
    });

    test('overlap with tied starts_at: picks the first in the sorted list', () {
      final a = _item(
        id: 'a',
        startsAt: '2026-10-11T09:00:00Z',
        endsAt: '2026-10-11T11:00:00Z',
      );
      final b = _item(
        id: 'b',
        startsAt: '2026-10-11T09:00:00Z',
        endsAt: '2026-10-11T10:00:00Z',
      );
      final sorted = [a, b];

      final result = currentAndNext(sorted, DateTime.parse('2026-10-11T09:30:00Z'));
      expect(result.current, a);
    });
  });
}
