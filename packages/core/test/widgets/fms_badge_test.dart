// Tests for FmsBadge (Designsystem §5.5, Tabelle 2.4).
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required ThemeData theme,
    required FmsStatus status,
    String? vehicleName,
    bool large = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: FmsBadge(
            status: status,
            vehicleName: vehicleName,
            large: large,
          ),
        ),
      ),
    );
  }

  group('FmsBadge', () {
    for (final status in FmsStatus.values) {
      testWidgets('renders number + label for ${status.name}', (
        tester,
      ) async {
        await pump(tester, theme: bftagLightTheme(), status: status);

        expect(
          find.text('${status.code} ${status.label}'),
          findsOneWidget,
        );
      });

      testWidgets('background/text colors match theme extension for '
          '${status.name}', (tester) async {
        final theme = bftagLightTheme();
        await pump(tester, theme: theme, status: status);

        final statusColors = theme.extension<BftagStatusColors>()!;
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(FmsBadge),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, statusColors.colorFor(status));

        final text = tester.widget<Text>(find.byType(Text).first);
        expect(text.style?.color, statusColors.onColorFor(status));
      });
    }

    testWidgets('has no border in light theme', (tester) async {
      await pump(
        tester,
        theme: bftagLightTheme(),
        status: FmsStatus.s1,
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FmsBadge),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('has a 1px onSurface@24% border in dark theme', (
      tester,
    ) async {
      final theme = bftagDarkTheme();
      await pump(tester, theme: theme, status: FmsStatus.s1);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FmsBadge),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.width, 1);
      expect(
        border.top.color,
        theme.colorScheme.onSurface.withValues(alpha: 0.24),
      );
    });

    testWidgets('exposes a semantics label with vehicle name, number '
        'and label', (tester) async {
      await pump(
        tester,
        theme: bftagLightTheme(),
        status: FmsStatus.s3,
        vehicleName: 'HLF 20',
      );

      expect(
        tester.getSemantics(find.byType(FmsBadge)).label,
        'HLF 20 Status 3 Einsatz übernommen',
      );
    });

    testWidgets('exposes a semantics label without vehicle name', (
      tester,
    ) async {
      await pump(tester, theme: bftagLightTheme(), status: FmsStatus.s3);

      expect(
        tester.getSemantics(find.byType(FmsBadge)).label,
        'Status 3 Einsatz übernommen',
      );
    });

    testWidgets('renders the vehicle name in onSurface before the pill', (
      tester,
    ) async {
      final theme = bftagLightTheme();
      await pump(
        tester,
        theme: theme,
        status: FmsStatus.s1,
        vehicleName: 'HLF 20',
      );

      final nameText = tester.widget<Text>(find.text('HLF 20'));
      expect(nameText.style?.color, theme.colorScheme.onSurface);
    });

    testWidgets('uses the large (monitor) min height when large is true', (
      tester,
    ) async {
      await pump(
        tester,
        theme: bftagMonitorTheme(),
        status: FmsStatus.s1,
        large: true,
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FmsBadge),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.minHeight, 56);
    });
  });
}
