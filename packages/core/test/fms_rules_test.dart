import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('allowsPatientStatus', () {
    test('RTW allows patient status', () {
      expect(allowsPatientStatus('RTW'), isTrue);
    });

    test('is trimmed and case-insensitive', () {
      expect(allowsPatientStatus(' ktw '), isTrue);
    });

    test('HLF does not allow patient status', () {
      expect(allowsPatientStatus('HLF'), isFalse);
    });

    test('free-text variants like "RTW 2" do not match', () {
      expect(allowsPatientStatus('RTW 2'), isFalse);
    });
  });

  group('offeredStatuses', () {
    test('HLF offers only s1..s6', () {
      expect(
        offeredStatuses('HLF'),
        [
          FmsStatus.s1,
          FmsStatus.s2,
          FmsStatus.s3,
          FmsStatus.s4,
          FmsStatus.s5,
          FmsStatus.s6,
        ],
      );
    });

    test('RTW offers s1..s8', () {
      expect(
        offeredStatuses('RTW'),
        [
          FmsStatus.s1,
          FmsStatus.s2,
          FmsStatus.s3,
          FmsStatus.s4,
          FmsStatus.s5,
          FmsStatus.s6,
          FmsStatus.s7,
          FmsStatus.s8,
        ],
      );
    });

    test('KTW offers s1..s8', () {
      expect(offeredStatuses(' ktw ').length, 8);
    });

    test('"RTW 2" offers only s1..s6', () {
      expect(offeredStatuses('RTW 2').length, 6);
    });
  });
}
