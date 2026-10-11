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

Future<void> _pump(
  WidgetTester tester, {
  required List<ProgramItem> items,
  required DateTime now,
  StreamController<DateTime>? nowController,
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
      child: const MaterialApp(home: ProgramScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows empty state when there are no program items',
      (tester) async {
    await _pump(tester, items: const [], now: DateTime(2026, 6, 1, 10));

    expect(find.text('Kein Tagesablauf vorhanden.'), findsOneWidget);
  });

  testWidgets('renders items in order with time range, icon and title',
      (tester) async {
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

  testWidgets('highlights the current item and greys out past items',
      (tester) async {
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

  testWidgets('highlight moves when the overridden clock advances',
      (tester) async {
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

  testWidgets('re-renders when the provider delivers a ProgramChanged update',
      (tester) async {
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
        child: const MaterialApp(home: ProgramScreen()),
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
}
