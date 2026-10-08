import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Formats [dateTime] as `dd.MM.yyyy HH:mm`, matching the other admin
/// screens' "gültig bis"/"zuletzt gesehen" convention.
String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

/// Builds the druckbare Liste (A4, 3x4 Karten pro Seite) of Kopplungscodes:
/// Anzeigename, QR-Code (die 8 Code-Zeichen ohne Bindestrich, ADR 0010),
/// Code, "gültig bis".
///
/// Pure function so it is testable without a real print dialog (`Printing`
/// only works through a real browser/OS print surface).
Future<Uint8List> buildPairingCodesPdf(List<PairingCodeItem> items) async {
  final document = pw.Document();

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (context) => [
        pw.GridView(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          children: [
            for (final item in items) _pairingCodeCard(item),
          ],
        ),
      ],
    ),
  );

  return document.save();
}

pw.Widget _pairingCodeCard(PairingCodeItem item) {
  return pw.Container(
    margin: const pw.EdgeInsets.all(4),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
    ),
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          item.displayName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Expanded(
          child: pw.BarcodeWidget(
            data: item.rawCode,
            barcode: pw.Barcode.qrCode(),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          item.code,
          style: pw.TextStyle(
            font: pw.Font.courier(),
            fontSize: 14,
          ),
        ),
        pw.Text(
          'gültig bis ${_formatDateTime(item.expiresAt.toLocal())}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    ),
  );
}
