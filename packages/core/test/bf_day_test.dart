import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BfDay.fromJson', () {
    test('anonymized_at absent -> anonymizedAt null, isAnonymized false', () {
      final json = {
        'id': 'd1',
        'name': 'BF-Tag 2026',
        'starts_at': '2026-06-01T08:00:00Z',
        'ends_at': '2026-06-02T08:00:00Z',
        'state': 'ended',
      };

      final day = BfDay.fromJson(json);

      expect(day.anonymizedAt, isNull);
      expect(day.isAnonymized, isFalse);
    });

    test('anonymized_at set -> anonymizedAt parsed, isAnonymized true', () {
      final json = {
        'id': 'd1',
        'name': 'BF-Tag 2026',
        'starts_at': '2026-06-01T08:00:00Z',
        'ends_at': '2026-06-02T08:00:00Z',
        'state': 'ended',
        'anonymized_at': '2026-06-03T10:00:00Z',
      };

      final day = BfDay.fromJson(json);

      expect(day.anonymizedAt, DateTime.parse('2026-06-03T10:00:00Z'));
      expect(day.isAnonymized, isTrue);
    });
  });
}
