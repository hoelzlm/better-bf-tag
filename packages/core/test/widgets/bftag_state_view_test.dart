// Tests for BftagStateView (Designsystem §5.10).
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(theme: bftagLightTheme(), home: Scaffold(body: child)),
    );
  }

  group('BftagStateView.loading', () {
    testWidgets('shows a centered CircularProgressIndicator', (
      tester,
    ) async {
      await pump(tester, const BftagStateView.loading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the optional message', (tester) async {
      await pump(
        tester,
        const BftagStateView.loading(message: 'Lädt …'),
      );

      expect(find.text('Lädt …'), findsOneWidget);
    });
  });

  group('BftagStateView.empty', () {
    testWidgets('shows title, message, icon and action', (tester) async {
      await pump(
        tester,
        BftagStateView.empty(
          title: 'Keine Einträge',
          message: 'Es gibt noch nichts zu sehen.',
          action: const Text('Hinzufügen'),
        ),
      );

      expect(find.text('Keine Einträge'), findsOneWidget);
      expect(find.text('Es gibt noch nichts zu sehen.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('Hinzufügen'), findsOneWidget);
    });

    testWidgets('supports a custom icon', (tester) async {
      await pump(
        tester,
        const BftagStateView.empty(
          title: 'Keine Fahrzeuge',
          icon: Icons.local_shipping_outlined,
        ),
      );

      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });
  });

  group('BftagStateView.error', () {
    testWidgets('shows message, warning icon and retry button', (
      tester,
    ) async {
      var retried = false;
      await pump(
        tester,
        BftagStateView.error(
          message: 'Etwas ist schiefgelaufen.',
          onRetry: () => retried = true,
        ),
      );

      expect(find.text('Etwas ist schiefgelaufen.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);

      await tester.tap(find.text('Erneut versuchen'));
      expect(retried, isTrue);
    });

    testWidgets('supports a custom retry label', (tester) async {
      await pump(
        tester,
        BftagStateView.error(
          message: 'Fehler',
          onRetry: () {},
          retryLabel: 'Nochmal',
        ),
      );

      expect(find.text('Nochmal'), findsOneWidget);
    });

    testWidgets('error icon color is the warning token, not alarm', (
      tester,
    ) async {
      final theme = bftagLightTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: BftagStateView.error(message: 'Fehler', onRetry: () {}),
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.warning_amber_outlined),
      );
      final alarmColors = theme.extension<BftagAlarmColors>()!;
      expect(icon.color, theme.colorScheme.error);
      expect(icon.color, isNot(equals(alarmColors.alarm)));
    });
  });
}
