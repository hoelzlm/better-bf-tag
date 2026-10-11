import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  String id = 'pi1',
  String bfDayId = 'day1',
  String title = 'Mittagessen',
  String type = 'meal',
  String startsAt = '2026-10-11T11:00:00Z',
  String endsAt = '2026-10-11T12:00:00Z',
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'title': title,
    'type': type,
    'starts_at': startsAt,
    'ends_at': endsAt,
  };
}

void main() {
  group('ProgramItem.fromJson/toJson (ADR 0025)', () {
    test('roundtrips through JSON', () {
      final item = ProgramItem.fromJson(_json());

      expect(item.id, 'pi1');
      expect(item.bfDayId, 'day1');
      expect(item.title, 'Mittagessen');
      expect(item.type, ProgramItemType.meal);
      expect(item.startsAt, DateTime.parse('2026-10-11T11:00:00Z'));
      expect(item.endsAt, DateTime.parse('2026-10-11T12:00:00Z'));

      final roundTripped = ProgramItem.fromJson(item.toJson());
      expect(roundTripped, item);
    });

    test('parses DateTimes as UTC', () {
      final item = ProgramItem.fromJson(_json());

      expect(item.startsAt.isUtc, isTrue);
      expect(item.endsAt.isUtc, isTrue);
    });

    test('sends DateTimes as UTC', () {
      final item = ProgramItem.fromJson(_json());
      final json = item.toJson();

      expect(json['starts_at'], '2026-10-11T11:00:00.000Z');
      expect(json['ends_at'], '2026-10-11T12:00:00.000Z');
    });
  });

  group('ProgramItemType.label (ADR 0025)', () {
    test('has the German labels', () {
      expect(ProgramItemType.meal.label, 'Essen');
      expect(ProgramItemType.training.label, 'Ausbildung');
      expect(ProgramItemType.maintenance.label, 'Fahrzeugpflege');
      expect(ProgramItemType.rest.label, 'Ruhe');
      expect(ProgramItemType.other.label, 'Sonstiges');
    });
  });

  group('ProgramItemType wire parse/serialize', () {
    test('parses every wire value', () {
      for (final type in ProgramItemType.values) {
        expect(ProgramItemType.fromWire(type.toWire()), type);
      }
    });

    test('throws on an unknown wire value', () {
      expect(() => ProgramItemType.fromWire('unknown'), throwsArgumentError);
    });
  });

  group('ProgramItem equality', () {
    test('two ProgramItems with the same fields are equal', () {
      expect(ProgramItem.fromJson(_json()), ProgramItem.fromJson(_json()));
    });

    test('a different id is not equal', () {
      expect(
        ProgramItem.fromJson(_json(id: 'pi1')),
        isNot(ProgramItem.fromJson(_json(id: 'pi2'))),
      );
    });

    test('a different type is not equal', () {
      expect(
        ProgramItem.fromJson(_json(type: 'meal')),
        isNot(ProgramItem.fromJson(_json(type: 'training'))),
      );
    });
  });
}
