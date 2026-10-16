// Tests for ConnectionBanner (Designsystem §5.10).
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool connected,
    String? text,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? bftagLightTheme(),
        home: Scaffold(
          body: ConnectionBanner(
            connected: connected,
            text: text ?? 'Verbindung verloren — verbinde erneut …',
          ),
        ),
      ),
    );
  }

  group('ConnectionBanner', () {
    testWidgets('renders nothing when connected', (tester) async {
      await pump(tester, connected: true);

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      expect(
        find.text('Verbindung verloren — verbinde erneut …'),
        findsNothing,
      );
    });

    testWidgets('renders icon and text when disconnected', (tester) async {
      await pump(tester, connected: false);

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(
        find.text('Verbindung verloren — verbinde erneut …'),
        findsOneWidget,
      );
    });

    testWidgets('renders a custom message', (tester) async {
      await pump(tester, connected: false, text: 'Keine Verbindung');

      expect(find.text('Keine Verbindung'), findsOneWidget);
    });

    testWidgets('is wrapped in a live-region Semantics node', (
      tester,
    ) async {
      await pump(tester, connected: false);

      final semantics = tester.getSemantics(find.byType(ConnectionBanner));
      expect(
        semantics.flagsCollection.isLiveRegion,
        isTrue,
      );
    });

    testWidgets('does not use the alarm color in light or dark theme', (
      tester,
    ) async {
      for (final theme in [bftagLightTheme(), bftagDarkTheme()]) {
        await pump(tester, connected: false, theme: theme);

        final alarmColors = theme.extension<BftagAlarmColors>()!;
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(ConnectionBanner),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(container.color, isNot(equals(alarmColors.alarm)));

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.cloud_off_outlined),
        );
        expect(icon.color, isNot(equals(alarmColors.alarm)));
      }
    });
  });
}
