import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/announcements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BfDay _bfDay({
  String id = 'd1',
  BfDayState state = BfDayState.running,
}) {
  return BfDay(
    id: id,
    name: 'BF-Tag 2026',
    startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: DateTime.now().add(const Duration(hours: 23)),
    state: state,
  );
}

Shift _shift({
  String id = 's1',
  String bfDayId = 'd1',
  String name = 'Schicht 1',
}) {
  return Shift(
    id: id,
    bfDayId: bfDayId,
    name: name,
    startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: DateTime.now().add(const Duration(hours: 23)),
    crew: const [],
  );
}

Announcement _announcement({
  String id = 'a1',
  String bfDayId = 'd1',
  String? shiftId,
  String text = 'Essen ist fertig',
  DateTime? createdAt,
}) {
  return Announcement(
    id: id,
    bfDayId: bfDayId,
    shiftId: shiftId,
    text: text,
    createdBy: 'p1',
    createdAt: createdAt ?? DateTime(2026, 10, 11, 12, 30),
  );
}

class _FakeAnnouncementRepository implements AnnouncementRepository {
  final List<(String, String, String?)> createCalls = [];
  final List<String> deleteCalls = [];
  Object? createError;
  Object? deleteError;

  @override
  Future<List<Announcement>> list(String bfDayId) async => const [];

  @override
  Future<Announcement> create(
    String bfDayId, {
    required String text,
    String? shiftId,
  }) async {
    createCalls.add((bfDayId, text, shiftId));
    final error = createError;
    if (error != null) throw error;
    return _announcement(bfDayId: bfDayId, text: text, shiftId: shiftId);
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls.add(id);
    final error = deleteError;
    if (error != null) throw error;
  }
}

Future<_FakeAnnouncementRepository> _pump(
  WidgetTester tester, {
  BfDay? bfDay,
  List<Shift> shifts = const [],
  List<Announcement> announcements = const [],
}) async {
  final repository = _FakeAnnouncementRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bfDayProvider.overrideWith((ref) => Stream.value(bfDay)),
        shiftsProvider.overrideWith((ref) => Stream.value(shifts)),
        announcementsProvider.overrideWith(
          (ref) => Stream.value(announcements),
        ),
        announcementRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: AnnouncementsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'shows the hint and a disabled form when no BF-Tag is running',
    (tester) async {
      await _pump(tester, bfDay: null);

      expect(
        find.byKey(const Key('announcements-no-running-day')),
        findsOneWidget,
      );
      expect(find.text('Kein laufender BF-Tag'), findsOneWidget);

      final textField = tester.widget<TextField>(
        find.byKey(const Key('announcement-text')),
      );
      expect(textField.enabled, isFalse);

      final sendButton = tester.widget<FilledButton>(
        find.byKey(const Key('announcement-send')),
      );
      expect(sendButton.onPressed, isNull);
    },
  );

  testWidgets(
    'sends a create with the selected shift id',
    (tester) async {
      final repository = await _pump(
        tester,
        bfDay: _bfDay(),
        shifts: [_shift(id: 's1', name: 'Tagschicht')],
      );

      await tester.enterText(
        find.byKey(const Key('announcement-text')),
        'Mittagessen ist fertig',
      );
      await tester.tap(find.byKey(const Key('announcement-target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tagschicht').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('announcement-send')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      final (bfDayId, text, shiftId) = repository.createCalls.single;
      expect(bfDayId, 'd1');
      expect(text, 'Mittagessen ist fertig');
      expect(shiftId, 's1');
    },
  );

  testWidgets(
    'sends a create with shiftId null for "Alle"',
    (tester) async {
      final repository = await _pump(tester, bfDay: _bfDay());

      await tester.enterText(
        find.byKey(const Key('announcement-text')),
        'Für alle',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('announcement-send')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      final (_, _, shiftId) = repository.createCalls.single;
      expect(shiftId, isNull);
    },
  );

  testWidgets('shows the list of announcements, newest first', (
    tester,
  ) async {
    await _pump(
      tester,
      bfDay: _bfDay(),
      announcements: [
        _announcement(
          id: 'a1',
          text: 'Erste Durchsage',
          createdAt: DateTime(2026, 10, 11, 9, 5),
        ),
        _announcement(
          id: 'a2',
          shiftId: 's1',
          text: 'Zweite Durchsage',
          createdAt: DateTime(2026, 10, 11, 10, 0),
        ),
      ],
      shifts: [_shift(id: 's1', name: 'Tagschicht')],
    );

    expect(find.text('Erste Durchsage'), findsOneWidget);
    expect(find.text('Zweite Durchsage'), findsOneWidget);
    expect(find.textContaining('09:05 · Alle'), findsOneWidget);
    expect(find.textContaining('10:00 · Tagschicht'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation before deleting', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      bfDay: _bfDay(),
      announcements: [_announcement(id: 'a1')],
    );

    await tester.tap(find.byKey(const Key('delete-announcement-a1')));
    await tester.pumpAndSettle();

    expect(find.text('Durchsage löschen'), findsOneWidget);
    expect(repository.deleteCalls, isEmpty);

    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, ['a1']);
  });

  testWidgets('cancelling the delete confirmation does not delete', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      bfDay: _bfDay(),
      announcements: [_announcement(id: 'a1')],
    );

    await tester.tap(find.byKey(const Key('delete-announcement-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, isEmpty);
  });
}
