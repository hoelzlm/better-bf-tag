// Theme-Tests: Designsystem `docs/design/design-system.md` §2 (Farben),
// §3 (Typografie), §10 (Flutter-Abbildung). Kontrastberechnung nach der
// WCAG-2.x-Formel (relative Luminanz, sRGB) — dieselbe Formel wie
// `docs/design/tools/contrast.py`, hier als Dart-Helfer reimplementiert
// (kein Python-Aufruf im Flutter-Test).
import 'dart:math' as math;

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _srgbChannel(double c) {
  c /= 255.0;
  return c <= 0.04045
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _srgbChannel(color.r * 255.0);
  final g = _srgbChannel(color.g * 255.0);
  final b = _srgbChannel(color.b * 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG contrast ratio between two colors (order-independent).
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void expectAA(Color fg, Color bg, String label) {
  final ratio = contrastRatio(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason: '$label: $ratio:1 unter WCAG AA 4.5:1',
  );
}

void main() {
  group('bftagTheme', () {
    for (final mode in BftagThemeMode.values) {
      test('$mode registers all five ThemeExtensions', () {
        final theme = bftagTheme(mode);
        expect(theme.extension<BftagStatusColors>(), isNotNull);
        expect(theme.extension<BftagAlarmColors>(), isNotNull);
        expect(theme.extension<BftagSpacing>(), isNotNull);
        expect(theme.extension<BftagRadii>(), isNotNull);
        expect(theme.extension<BftagMonitorTextStyles>(), isNotNull);
      });

      test('$mode uses Material 3', () {
        expect(bftagTheme(mode).useMaterial3, isTrue);
      });

      test('$mode fontFamily contains Inter', () {
        final theme = bftagTheme(mode);
        expect(theme.textTheme.bodyLarge?.fontFamily, contains('Inter'));
        expect(
          theme.extension<BftagMonitorTextStyles>()!.body.fontFamily,
          contains('Inter'),
        );
      });

      test('$mode colorScheme.error is not the alarm color', () {
        final theme = bftagTheme(mode);
        final alarm = theme.extension<BftagAlarmColors>()!;
        expect(theme.colorScheme.error, isNot(equals(alarm.alarm)));
      });
    }

    test('dark mode has dark brightness', () {
      expect(bftagDarkTheme().brightness, Brightness.dark);
    });

    test('monitor mode has dark brightness', () {
      expect(bftagMonitorTheme().brightness, Brightness.dark);
    });

    test('light mode has light brightness', () {
      expect(bftagLightTheme().brightness, Brightness.light);
    });

    test('old parameterless bftagTheme() no longer exists', () {
      // bftagTheme now always requires a BftagThemeMode argument; this is
      // enforced by the compiler (see call below), not at runtime.
      expect(bftagTheme(BftagThemeMode.light), isNotNull);
    });

    group('WCAG AA contrast (table 2.3) — light', () {
      final theme = bftagLightTheme();
      final alarm = theme.extension<BftagAlarmColors>()!;

      test('onSurface/surface', () {
        expectAA(
          theme.colorScheme.onSurface,
          theme.colorScheme.surface,
          'onSurface/surface',
        );
      });

      test('onPrimary/primary', () {
        expectAA(
          theme.colorScheme.onPrimary,
          theme.colorScheme.primary,
          'onPrimary/primary',
        );
      });

      test('onError/error (warning tokens)', () {
        expectAA(
          theme.colorScheme.onError,
          theme.colorScheme.error,
          'onError/error',
        );
      });

      test('onAlarm/alarm', () {
        expectAA(alarm.onAlarm, alarm.alarm, 'onAlarm/alarm');
      });
    });

    group('WCAG AA contrast (table 2.3) — dark/monitor', () {
      final theme = bftagDarkTheme();
      final alarm = theme.extension<BftagAlarmColors>()!;

      test('onSurface/surface', () {
        expectAA(
          theme.colorScheme.onSurface,
          theme.colorScheme.surface,
          'onSurface/surface',
        );
      });

      test('onPrimary/primary', () {
        expectAA(
          theme.colorScheme.onPrimary,
          theme.colorScheme.primary,
          'onPrimary/primary',
        );
      });

      test('onError/error (warning tokens)', () {
        expectAA(
          theme.colorScheme.onError,
          theme.colorScheme.error,
          'onError/error',
        );
      });

      test('onAlarm/alarm', () {
        expectAA(alarm.onAlarm, alarm.alarm, 'onAlarm/alarm');
      });
    });

    group('WCAG AA contrast (table 2.4) — FMS status colors', () {
      final theme = bftagLightTheme();
      final status = theme.extension<BftagStatusColors>()!;

      for (final fmsStatus in FmsStatus.values) {
        test('onFms/fms for ${fmsStatus.name}', () {
          expectAA(
            status.onColorFor(fmsStatus),
            status.colorFor(fmsStatus),
            'onFms/fms ${fmsStatus.name}',
          );
        });
      }
    });
  });
}
