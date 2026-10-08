import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Builds the QR scanner widget shown on the pairing screen. Kept as an
/// injectable function (rather than a hardcoded [MobileScanner]) behind
/// [qrScannerBuilderProvider] so widget tests can override it with a
/// camera-free fake (tests never get a real camera/platform channel).
typedef QrScannerBuilder =
    Widget Function(void Function(String code) onDetected);

/// Default [QrScannerBuilder]: a live camera preview via `mobile_scanner`.
/// The pairing code is the raw QR content (8 characters, per ADR 0010).
Widget defaultQrScannerBuilder(void Function(String code) onDetected) {
  return MobileScanner(
    onDetect: (capture) {
      for (final barcode in capture.barcodes) {
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          onDetected(raw);
          return;
        }
      }
    },
  );
}

/// The [QrScannerBuilder] used by the pairing screen; override in tests to
/// avoid ever constructing a real [MobileScanner].
final qrScannerBuilderProvider = Provider<QrScannerBuilder>(
  (ref) => defaultQrScannerBuilder,
);
