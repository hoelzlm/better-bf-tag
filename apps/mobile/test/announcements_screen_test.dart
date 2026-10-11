import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/screens/announcements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Announcement _announcement({
  String id = 'a1',
  String text = 'Hallo',
  String? shiftId,
  // Local (not UTC) DateTime on purpose: the screen formats via
  // `.toLocal()`, so a local input makes the formatted HH:mm
  // deterministic regardless of the test runner's timezone.
  required DateTime createdAt,
}) {
  return Announcement(
    id: id,
    bfDayId: 'day1',
    shiftId: shiftId,
    text: text,
    createdBy: 'p1',
    createdAt: createdAt,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Announcement> announcements,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pairedRealtimeClientProvider.overrideWith((ref) => null),
        pairedAnnouncementsProvider.overrideWith(
          (ref) => Stream.value(announcements),
        ),
      ],
      child: const MaterialApp(home: AnnouncementsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows "Keine Durchsagen" when the list is empty',
      (tester) async {
    await _pump(tester, announcements: const []);

    expect(find.text('Keine Durchsagen'), findsOneWidget);
  });

  testWidgets('renders announcements newest first with HH:mm and text',
      (tester) async {
    // pairedAnnouncementsProvider already delivers newest-first (the
    // RealtimeClient reducer inserts at the front); the screen must
    // render in that order, not re-sort.
    final announcements = [
      _announcement(
        id: 'a2',
        text: 'Zweite Durchsage',
        createdAt: DateTime(2026, 6, 1, 10, 30),
      ),
      _announcement(
        id: 'a1',
        text: 'Erste Durchsage',
        createdAt: DateTime(2026, 6, 1, 8, 15),
      ),
    ];
    await _pump(tester, announcements: announcements);

    final listFinder = find.byKey(const Key('announcements-list'));
    expect(listFinder, findsOneWidget);

    final firstTile = find.byKey(const Key('announcement-a2'));
    final secondTile = find.byKey(const Key('announcement-a1'));
    expect(firstTile, findsOneWidget);
    expect(secondTile, findsOneWidget);
    expect(
      tester.getTopLeft(firstTile).dy < tester.getTopLeft(secondTile).dy,
      isTrue,
    );
    expect(find.text('Zweite Durchsage'), findsOneWidget);
    expect(find.text('Erste Durchsage'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('08:15'), findsOneWidget);
  });
}
