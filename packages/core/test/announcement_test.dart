import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  String id = 'ann1',
  String bfDayId = 'day1',
  String? shiftId,
  String text = 'Essen ist fertig',
  String createdBy = 'p1',
  String createdAt = '2026-10-11T10:00:00Z',
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'shift_id': shiftId,
    'text': text,
    'created_by': createdBy,
    'created_at': createdAt,
  };
}

void main() {
  group('Announcement.fromJson (ADR 0024)', () {
    test('parses a Durchsage without shift_id', () {
      final announcement = Announcement.fromJson(_json());

      expect(announcement.id, 'ann1');
      expect(announcement.bfDayId, 'day1');
      expect(announcement.shiftId, isNull);
      expect(announcement.text, 'Essen ist fertig');
      expect(announcement.createdBy, 'p1');
      expect(
        announcement.createdAt,
        DateTime.parse('2026-10-11T10:00:00Z'),
      );
    });

    test('parses a Durchsage with shift_id', () {
      final announcement =
          Announcement.fromJson(_json(shiftId: 'shift1'));

      expect(announcement.shiftId, 'shift1');
    });
  });

  group('Announcement equality', () {
    test('two Announcements with the same fields are equal', () {
      expect(
        Announcement.fromJson(_json()),
        Announcement.fromJson(_json()),
      );
    });

    test('a different id is not equal', () {
      expect(
        Announcement.fromJson(_json(id: 'ann1')),
        isNot(Announcement.fromJson(_json(id: 'ann2'))),
      );
    });
  });
}
