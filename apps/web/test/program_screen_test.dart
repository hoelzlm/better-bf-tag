import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/program_screen.dart';
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
    startsAt: DateTime(2026, 10, 11, 8),
    endsAt: DateTime(2026, 10, 12, 8),
    state: state,
  );
}

ProgramItem _item({
  String id = 'p1',
  String bfDayId = 'd1',
  String title = 'Mittagessen',
  ProgramItemType type = ProgramItemType.meal,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  return ProgramItem(
    id: id,
    bfDayId: bfDayId,
    title: title,
    type: type,
    startsAt: startsAt ?? DateTime.utc(2026, 10, 11, 12),
    endsAt: endsAt ?? DateTime.utc(2026, 10, 11, 13),
  );
}

class _FakeBfDayAdminRepository implements BfDayAdminRepository {
  _FakeBfDayAdminRepository(this.days);

  final List<BfDay> days;

  @override
  Future<List<BfDay>> list() async => days;

  @override
  Future<BfDay> create({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> start(String id) => throw UnimplementedError();

  @override
  Future<BfDay> end(String id) => throw UnimplementedError();

  @override
  Future<List<Participant>> listParticipants(String day) =>
      throw UnimplementedError();

  @override
  Future<void> setParticipants(String day, List<String> personIds) =>
      throw UnimplementedError();

  @override
  Future<AnonymizationSummary> anonymizationPreview(String bfDayId) =>
      throw UnimplementedError();

  @override
  Future<BfDay> anonymize(String bfDayId) => throw UnimplementedError();
}

class _FakeProgramItemRepository implements ProgramItemRepository {
  _FakeProgramItemRepository(this.items);

  List<ProgramItem> items;
  final List<String> listCalls = [];
  final List<(String, String, ProgramItemType, DateTime, DateTime)>
      createCalls = [];
  final List<(String, String?, ProgramItemType?, DateTime?, DateTime?)>
      updateCalls = [];
  final List<String> deleteCalls = [];
  Object? createError;
  Object? updateError;
  Object? deleteError;

  @override
  Future<List<ProgramItem>> list(String bfDayId) async {
    listCalls.add(bfDayId);
    return items.where((i) => i.bfDayId == bfDayId).toList();
  }

  @override
  Future<ProgramItem> create(
    String bfDayId, {
    required String title,
    required ProgramItemType type,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    createCalls.add((bfDayId, title, type, startsAt, endsAt));
    final error = createError;
    if (error != null) throw error;
    final created = ProgramItem(
      id: 'new-${createCalls.length}',
      bfDayId: bfDayId,
      title: title,
      type: type,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    items = [...items, created];
    return created;
  }

  @override
  Future<ProgramItem> update(
    String id, {
    String? title,
    ProgramItemType? type,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    updateCalls.add((id, title, type, startsAt, endsAt));
    final error = updateError;
    if (error != null) throw error;
    final existing = items.firstWhere((i) => i.id == id);
    final updated = ProgramItem(
      id: existing.id,
      bfDayId: existing.bfDayId,
      title: title ?? existing.title,
      type: type ?? existing.type,
      startsAt: startsAt ?? existing.startsAt,
      endsAt: endsAt ?? existing.endsAt,
    );
    items = [for (final i in items) if (i.id == id) updated else i];
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls.add(id);
    final error = deleteError;
    if (error != null) throw error;
    items = items.where((i) => i.id != id).toList();
  }
}

Future<_FakeProgramItemRepository> _pump(
  WidgetTester tester, {
  List<BfDay> days = const [],
  List<ProgramItem> items = const [],
}) async {
  final repository = _FakeProgramItemRepository(items);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bfDayAdminRepositoryProvider.overrideWithValue(
          _FakeBfDayAdminRepository(days),
        ),
        programItemRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: ProgramScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('shows the Programmpunkte of the default BF-Tag sorted by time', (
    tester,
  ) async {
    await _pump(
      tester,
      days: [_bfDay()],
      items: [
        _item(
          id: 'p2',
          title: 'Ausbildung',
          type: ProgramItemType.training,
          startsAt: DateTime.utc(2026, 10, 11, 14),
          endsAt: DateTime.utc(2026, 10, 11, 15),
        ),
        _item(
          id: 'p1',
          title: 'Mittagessen',
          type: ProgramItemType.meal,
          startsAt: DateTime.utc(2026, 10, 11, 12),
          endsAt: DateTime.utc(2026, 10, 11, 13),
        ),
      ],
    );

    final titles = tester
        .widgetList<Text>(find.descendant(
          of: find.byKey(const Key('program-list')),
          matching: find.byType(Text),
        ))
        .map((t) => t.data)
        .whereType<String>()
        .toList();

    expect(titles.indexOf('Mittagessen') < titles.indexOf('Ausbildung'), true);
  });

  testWidgets('create dialog calls the repository with the entered data', (
    tester,
  ) async {
    final repository = await _pump(tester, days: [_bfDay()], items: const []);

    await tester.tap(find.byKey(const Key('program-add')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('program-form-title')),
      'Abendessen',
    );
    await tester.tap(find.byKey(const Key('program-form-submit')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, hasLength(1));
    final (bfDayId, title, type, _, _) = repository.createCalls.single;
    expect(bfDayId, 'd1');
    expect(title, 'Abendessen');
    expect(type, ProgramItemType.other);
  });

  testWidgets('edit dialog calls update with the item id', (tester) async {
    final repository = await _pump(
      tester,
      days: [_bfDay()],
      items: [_item(id: 'p1', title: 'Mittagessen')],
    );

    await tester.tap(find.byKey(const Key('program-edit-p1')));
    await tester.pumpAndSettle();

    expect(find.text('Mittagessen'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('program-form-title')),
      'Mittagessen (verschoben)',
    );
    await tester.tap(find.byKey(const Key('program-form-submit')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, hasLength(1));
    final (id, title, _, _, _) = repository.updateCalls.single;
    expect(id, 'p1');
    expect(title, 'Mittagessen (verschoben)');
  });

  testWidgets('delete asks for confirmation before deleting', (tester) async {
    final repository = await _pump(
      tester,
      days: [_bfDay()],
      items: [_item(id: 'p1')],
    );

    await tester.tap(find.byKey(const Key('program-delete-p1')));
    await tester.pumpAndSettle();

    expect(find.text('Programmpunkt löschen'), findsOneWidget);
    expect(repository.deleteCalls, isEmpty);

    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, ['p1']);
  });

  testWidgets('an ended BF-Tag is read-only: no add/edit/delete buttons', (
    tester,
  ) async {
    await _pump(
      tester,
      days: [_bfDay(state: BfDayState.ended)],
      items: [_item(id: 'p1')],
    );

    expect(find.byKey(const Key('program-add')), findsOneWidget);
    final addButton = tester.widget<FilledButton>(
      find.byKey(const Key('program-add')),
    );
    expect(addButton.onPressed, isNull);

    expect(find.byKey(const Key('program-edit-p1')), findsNothing);
    expect(find.byKey(const Key('program-delete-p1')), findsNothing);
  });

  testWidgets('Leerzustand: no BF-Tage shows a message', (tester) async {
    await _pump(tester, days: const [], items: const []);

    expect(find.text('Keine BF-Tage angelegt.'), findsOneWidget);
  });

  testWidgets('Leerzustand: no Programmpunkte shows a message', (
    tester,
  ) async {
    await _pump(tester, days: [_bfDay()], items: const []);

    expect(find.text('Keine Programmpunkte vorhanden.'), findsOneWidget);
  });

  testWidgets('Fehlerzustand: BF-Tage load error shows a message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bfDayAdminRepositoryProvider.overrideWithValue(
            _ThrowingBfDayAdminRepository(),
          ),
          programItemRepositoryProvider.overrideWithValue(
            _FakeProgramItemRepository(const []),
          ),
        ],
        child: const MaterialApp(home: ProgramScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('BF-Tage konnten nicht geladen werden.'),
      findsOneWidget,
    );
  });

  testWidgets('Fehlerzustand: create error shows a SnackBar', (tester) async {
    final repository = await _pump(tester, days: [_bfDay()], items: const []);
    repository.createError = Exception('boom');

    await tester.tap(find.byKey(const Key('program-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('program-form-title')),
      'Abendessen',
    );
    await tester.tap(find.byKey(const Key('program-form-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Fehlerzustand: delete error shows a SnackBar', (tester) async {
    final repository = await _pump(
      tester,
      days: [_bfDay()],
      items: [_item(id: 'p1')],
    );
    repository.deleteError = Exception('boom');

    await tester.tap(find.byKey(const Key('program-delete-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}

class _ThrowingBfDayAdminRepository implements BfDayAdminRepository {
  @override
  Future<List<BfDay>> list() async => throw Exception('boom');

  @override
  Future<BfDay> create({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> start(String id) => throw UnimplementedError();

  @override
  Future<BfDay> end(String id) => throw UnimplementedError();

  @override
  Future<List<Participant>> listParticipants(String day) =>
      throw UnimplementedError();

  @override
  Future<void> setParticipants(String day, List<String> personIds) =>
      throw UnimplementedError();

  @override
  Future<AnonymizationSummary> anonymizationPreview(String bfDayId) =>
      throw UnimplementedError();

  @override
  Future<BfDay> anonymize(String bfDayId) => throw UnimplementedError();
}
