import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/admin/pairing_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildPairingCodesPdf returns non-empty bytes for 13 items (multiple pages)', () async {
    final items = [
      for (var i = 0; i < 13; i++)
        PairingCodeItem(
          personId: 'p$i',
          displayName: 'Person $i',
          code: 'ABCD-EFG$i',
          expiresAt: DateTime.utc(2026, 10, 9, 12, 0),
        ),
    ];

    final bytes = await buildPairingCodesPdf(items);

    expect(bytes, isNotEmpty);
    // A PDF file always starts with the '%PDF-' magic bytes.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('buildPairingCodesPdf returns non-empty bytes for an empty list', () async {
    final bytes = await buildPairingCodesPdf(const []);
    expect(bytes, isNotEmpty);
  });
}
