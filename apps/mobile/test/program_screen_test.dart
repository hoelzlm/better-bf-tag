import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/screens/program_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProgramItem _item({
  String id = 'p1',
  String title = 'Mittagessen',
  ProgramItemType type = ProgramItemType.meal,
  // Local (not UTC) DateTimes on purpose: the screen formats via
  // `.toLocal()` and compares against `now` via `.toUtc()` internally,
  // so local input makes the formatted HH:mm deterministic regardless
  // of the test runner's timezone.
  required DateTime startsAt,
  required DateTime endsAt,
}) {
  return ProgramItem(
    id: id,
    bfDayId: 'day1',
    title: title,
    type: type,
    startsAt: startsAt,
    endsAt: endsAt,
  );
}

/// Resizes the test surface for the duration of the test (restored via
/// `addTearDown`), matching the 390x844/360x640 sizes the concepts test.
void _setSurfaceSize(WidgetTester tester, Size size) {
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });
}

/// WCAG contrast ratio between two colours, via relative luminance.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

Future<void> _pump(
  WidgetTester tester, {
  required List<ProgramItem> items,
  required DateTime now,
  StreamController<DateTime>? nowController,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pairedRealtimeClientProvider.overrideWith((ref) => null),
        pairedProgramItemsProvider.overrideWith((ref) => Stream.value(items)),
        programNowProvider.overrideWith(
          (ref) => nowController?.stream ?? Stream.value(now),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? bftagLightTheme(),
        home: const ProgramScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows empty state when there are no program items', (
    tester,
  ) async {
    await _pump(tester, items: const [], now: DateTime(2026, 6, 1, 10));

    expect(find.text('Kein Tagesablauf vorhanden.'), findsOneWidget);
  });

  testWidgets('renders items in order with time range, icon and title', (
    tester,
  ) async {
    final items = [
      _item(
        id: 'p1',
        title: 'Frühstück',
        type: ProgramItemType.meal,
        startsAt: DateTime(2026, 6, 1, 7),
        endsAt: DateTime(2026, 6, 1, 8),
      ),
      _item(
        id: 'p2',
        title: 'Ausbildung Löschangriff',
        type: ProgramItemType.training,
        startsAt: DateTime(2026, 6, 1, 9),
        endsAt: DateTime(2026, 6, 1, 11),
      ),
    ];
    await _pump(tester, items: items, now: DateTime(2026, 6, 1, 6));

    final firstTile = find.byKey(const Key('program-item-p1'));
    final secondTile = find.byKey(const Key('program-item-p2'));
    expect(firstTile, findsOneWidget);
    expect(secondTile, findsOneWidget);
    expect(
      tester.getTopLeft(firstTile).dy < tester.getTopLeft(secondTile).dy,
      isTrue,
    );
    expect(find.text('Frühstück'), findsOneWidget);
    expect(find.textContaining('07:00–08:00'), findsOneWidget);
    expect(find.text('09:00–11:00 · Ausbildung'), findsOneWidget);
  });

  testWidgets('highlights the current item and greys out past items', (
    tester,
  ) async {
    final items = [
      _item(
        id: 'p1',
        title: 'Frühstück',
        startsAt: DateTime(2026, 6, 1, 7),
        endsAt: DateTime(2026, 6, 1, 8),
      ),
      _item(
        id: 'p2',
        title: 'Ausbildung',
        type: ProgramItemType.training,
        startsAt: DateTime(2026, 6, 1, 9),
        endsAt: DateTime(2026, 6, 1, 11),
      ),
      _item(
        id: 'p3',
        title: 'Ruhe',
        type: ProgramItemType.rest,
        startsAt: DateTime(2026, 6, 1, 11),
        endsAt: DateTime(2026, 6, 1, 12),
      ),
    ];
    // 10:00 -> p1 past, p2 current, p3 upcoming.
    await _pump(tester, items: items, now: DateTime(2026, 6, 1, 10));

    expect(find.byKey(const Key('program-past-p1')), findsOneWidget);
    expect(find.byKey(const Key('program-current-p2')), findsOneWidget);
    expect(find.byKey(const Key('program-item-p3')), findsOneWidget);
    expect(find.text('Jetzt'), findsOneWidget);
  });

  testWidgets('highlight moves when the overridden clock advances', (
    tester,
  ) async {
    final items = [
      _item(
        id: 'p1',
        title: 'Frühstück',
        startsAt: DateTime(2026, 6, 1, 7),
        endsAt: DateTime(2026, 6, 1, 8),
      ),
      _item(
        id: 'p2',
        title: 'Ausbildung',
        type: ProgramItemType.training,
        startsAt: DateTime(2026, 6, 1, 9),
        endsAt: DateTime(2026, 6, 1, 11),
      ),
    ];
    final nowController = StreamController<DateTime>();
    addTearDown(nowController.close);

    await _pump(
      tester,
      items: items,
      now: DateTime(2026, 6, 1, 7, 30),
      nowController: nowController,
    );
    nowController.add(DateTime(2026, 6, 1, 7, 30));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('program-current-p1')), findsOneWidget);
    expect(find.byKey(const Key('program-item-p2')), findsOneWidget);

    nowController.add(DateTime(2026, 6, 1, 9, 30));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('program-past-p1')), findsOneWidget);
    expect(find.byKey(const Key('program-current-p2')), findsOneWidget);
  });

  testWidgets('re-renders when the provider delivers a ProgramChanged update', (
    tester,
  ) async {
    final itemsController = StreamController<List<ProgramItem>>();
    addTearDown(itemsController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pairedRealtimeClientProvider.overrideWith((ref) => null),
          pairedProgramItemsProvider.overrideWith(
            (ref) => itemsController.stream,
          ),
          programNowProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 6, 1, 10)),
          ),
        ],
        child: MaterialApp(
          theme: bftagLightTheme(),
          home: const ProgramScreen(),
        ),
      ),
    );
    await tester.pump();

    itemsController.add([
      _item(
        id: 'p1',
        title: 'Frühstück',
        startsAt: DateTime(2026, 6, 1, 7),
        endsAt: DateTime(2026, 6, 1, 8),
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Frühstück'), findsOneWidget);
    expect(find.text('Kein Tagesablauf vorhanden.'), findsNothing);

    itemsController.add([
      _item(
        id: 'p1',
        title: 'Frühstück',
        startsAt: DateTime(2026, 6, 1, 7),
        endsAt: DateTime(2026, 6, 1, 8),
      ),
      _item(
        id: 'p2',
        title: 'Ausbildung',
        type: ProgramItemType.training,
        startsAt: DateTime(2026, 6, 1, 9),
        endsAt: DateTime(2026, 6, 1, 11),
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ausbildung'), findsOneWidget);
  });

  group('app-tagesablauf.md ACs', () {
    testWidgets(
      'AC1: current item is a primaryContainer card with a "Jetzt" chip '
      'in primary/onPrimary',
      (tester) async {
        final theme = bftagLightTheme();
        final colorScheme = theme.colorScheme;
        final items = [
          _item(
            id: 'p1',
            startsAt: DateTime(2026, 6, 1, 11),
            endsAt: DateTime(2026, 6, 1, 13),
          ),
        ];
        await _pump(
          tester,
          items: items,
          now: DateTime(2026, 6, 1, 12),
          theme: theme,
        );

        final card = tester.widget<Card>(find.byType(Card));
        expect(card.color, colorScheme.primaryContainer);

        final chip = tester.widget<Chip>(find.byType(Chip));
        expect(chip.backgroundColor, colorScheme.primary);
        final chipLabel = tester.widget<Text>(
          find.descendant(of: find.byType(Chip), matching: find.byType(Text)),
        );
        expect(chipLabel.style?.color, colorScheme.onPrimary);
      },
    );

    testWidgets('AC2: past items render at 50% opacity, future items at full '
        'opacity', (tester) async {
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 7),
          endsAt: DateTime(2026, 6, 1, 8),
        ),
        _item(
          id: 'p2',
          startsAt: DateTime(2026, 6, 1, 14),
          endsAt: DateTime(2026, 6, 1, 15),
        ),
      ];
      await _pump(tester, items: items, now: DateTime(2026, 6, 1, 10));

      final pastOpacity = tester.widget<Opacity>(
        find.byKey(const Key('program-past-p1')),
      );
      expect(pastOpacity.opacity, 0.5);
      expect(find.byKey(const Key('program-item-p2')), findsOneWidget);
    });

    testWidgets(
      'AC3: the empty state shows text and a 48px icon, not bare text',
      (tester) async {
        await _pump(tester, items: const [], now: DateTime(2026, 6, 1, 10));

        expect(find.text('Kein Tagesablauf vorhanden.'), findsOneWidget);
        final icon = tester.widget<Icon>(
          find.byIcon(Icons.event_note_outlined),
        );
        expect(icon.size, 48);
      },
    );

    testWidgets('AC4: every list row is at least 48dp high', (tester) async {
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 7),
          endsAt: DateTime(2026, 6, 1, 8),
        ),
        _item(
          id: 'p2',
          startsAt: DateTime(2026, 6, 1, 11),
          endsAt: DateTime(2026, 6, 1, 12),
        ),
      ];
      await _pump(tester, items: items, now: DateTime(2026, 6, 1, 11, 30));

      final rect1 = tester.getRect(find.byKey(const Key('program-past-p1')));
      expect(rect1.height, greaterThanOrEqualTo(48));
      final rect2 = tester.getRect(find.byKey(const Key('program-current-p2')));
      expect(rect2.height, greaterThanOrEqualTo(48));
    });

    testWidgets('AC5: the highlight re-renders automatically when the clock '
        'advances without user interaction (covered above: "highlight '
        'moves when the overridden clock advances")', (tester) async {
      final nowController = StreamController<DateTime>();
      addTearDown(nowController.close);
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 7),
          endsAt: DateTime(2026, 6, 1, 8),
        ),
      ];
      await _pump(
        tester,
        items: items,
        now: DateTime(2026, 6, 1, 7, 30),
        nowController: nowController,
      );
      nowController.add(DateTime(2026, 6, 1, 7, 30));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('program-current-p1')), findsOneWidget);

      nowController.add(DateTime(2026, 6, 1, 9));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('program-past-p1')), findsOneWidget);
    });

    testWidgets('AC6: "Jetzt"-chip label reaches WCAG AA contrast in light and '
        'dark theme', (tester) async {
      for (final theme in [bftagLightTheme(), bftagDarkTheme()]) {
        final colorScheme = theme.colorScheme;
        expect(
          _contrast(colorScheme.onPrimary, colorScheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('no overflow at 390x844 and 360x640 with a filled list', (
      tester,
    ) async {
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 7),
          endsAt: DateTime(2026, 6, 1, 8),
        ),
        _item(
          id: 'p2',
          startsAt: DateTime(2026, 6, 1, 11),
          endsAt: DateTime(2026, 6, 1, 12),
        ),
      ];
      for (final size in [const Size(390, 844), const Size(360, 640)]) {
        _setSurfaceSize(tester, size);
        await _pump(tester, items: items, now: DateTime(2026, 6, 1, 11, 30));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(light, 390x844)', (tester) async {
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 11),
          endsAt: DateTime(2026, 6, 1, 12),
        ),
      ];
      await _pump(tester, items: items, now: DateTime(2026, 6, 1, 11, 30));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(dark, 360x640)', (tester) async {
      _setSurfaceSize(tester, const Size(360, 640));
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 11),
          endsAt: DateTime(2026, 6, 1, 12),
        ),
      ];
      await _pump(
        tester,
        items: items,
        now: DateTime(2026, 6, 1, 11, 30),
        theme: bftagDarkTheme(),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets textContrastGuideline (light)', (tester) async {
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 7),
          endsAt: DateTime(2026, 6, 1, 8),
        ),
        _item(
          id: 'p2',
          startsAt: DateTime(2026, 6, 1, 11),
          endsAt: DateTime(2026, 6, 1, 12),
        ),
      ];
      await _pump(tester, items: items, now: DateTime(2026, 6, 1, 11, 30));

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('meets textContrastGuideline (dark)', (tester) async {
      final items = [
        _item(
          id: 'p1',
          startsAt: DateTime(2026, 6, 1, 7),
          endsAt: DateTime(2026, 6, 1, 8),
        ),
        _item(
          id: 'p2',
          startsAt: DateTime(2026, 6, 1, 11),
          endsAt: DateTime(2026, 6, 1, 12),
        ),
      ];
      await _pump(
        tester,
        items: items,
        now: DateTime(2026, 6, 1, 11, 30),
        theme: bftagDarkTheme(),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
