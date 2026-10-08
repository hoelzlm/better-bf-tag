import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/bf_days_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BfDay _bfDay({
  String id = 'd1',
  String name = 'BF-Tag 2026',
  BfDayState state = BfDayState.planning,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  return BfDay(
    id: id,
    name: name,
    startsAt: startsAt ?? DateTime.utc(2026, 6, 1, 8, 0),
    endsAt: endsAt ?? DateTime.utc(2026, 6, 2, 8, 0),
    state: state,
  );
}

Person _person({
  String id = 'p1',
  String displayName = 'Max Mustermann',
  PersonType personType = PersonType.supervisor,
  Permission permission = Permission.crew,
  bool active = true,
}) {
  return Person(
    id: id,
    displayName: displayName,
    personType: personType,
    permission: permission,
    active: active,
  );
}

class _FakeBfDayAdminRepository implements BfDayAdminRepository {
  _FakeBfDayAdminRepository({List<BfDay>? days}) : days = days ?? [];

  List<BfDay> days;
  Map<String, List<String>> participants = {};
  final List<(String, DateTime, DateTime)> createCalls = [];
  final List<String> startCalls = [];
  final List<String> endCalls = [];
  final List<(String, List<String>)> setParticipantsCalls = [];
  Object? startError;

  @override
  Future<List<BfDay>> list() async => List.of(days);

  @override
  Future<BfDay> create({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    createCalls.add((name, startsAt, endsAt));
    final created = _bfDay(
      id: 'new-${days.length}',
      name: name,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    days = [...days, created];
    return created;
  }

  @override
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final index = days.indexWhere((d) => d.id == id);
    final current = days[index];
    final updated = _bfDay(
      id: current.id,
      name: name ?? current.name,
      state: current.state,
      startsAt: startsAt ?? current.startsAt,
      endsAt: endsAt ?? current.endsAt,
    );
    days = List.of(days)..[index] = updated;
    return updated;
  }

  @override
  Future<BfDay> start(String id) async {
    startCalls.add(id);
    final error = startError;
    if (error != null) {
      throw error;
    }
    final index = days.indexWhere((d) => d.id == id);
    final updated = _bfDay(
      id: days[index].id,
      name: days[index].name,
      state: BfDayState.running,
      startsAt: days[index].startsAt,
      endsAt: days[index].endsAt,
    );
    days = List.of(days)..[index] = updated;
    return updated;
  }

  @override
  Future<BfDay> end(String id) async {
    endCalls.add(id);
    final index = days.indexWhere((d) => d.id == id);
    final updated = _bfDay(
      id: days[index].id,
      name: days[index].name,
      state: BfDayState.ended,
      startsAt: days[index].startsAt,
      endsAt: days[index].endsAt,
    );
    days = List.of(days)..[index] = updated;
    return updated;
  }

  @override
  Future<List<Participant>> listParticipants(String day) async {
    final ids = participants[day] ?? const [];
    return ids
        .map(
          (id) => Participant(
            personId: id,
            displayName: 'Person $id',
            personType: PersonType.youth,
            permission: Permission.crew,
            fireDepartmentId: 'fd1',
          ),
        )
        .toList();
  }

  @override
  Future<void> setParticipants(String day, List<String> personIds) async {
    setParticipantsCalls.add((day, personIds));
    participants[day] = personIds;
  }
}

class _FakePersonAdminRepository implements PersonAdminRepository {
  _FakePersonAdminRepository(this.persons);

  final List<Person> persons;

  @override
  Future<List<Person>> listPersons() async => List.of(persons);

  @override
  Future<Person> createPerson({
    required String displayName,
    required PersonType personType,
    required Permission permission,
  }) =>
      throw UnimplementedError();

  @override
  Future<Person> updatePerson(
    String id, {
    String? displayName,
    PersonType? personType,
    Permission? permission,
    bool? active,
  }) =>
      throw UnimplementedError();

  @override
  Future<Person> setWebAccess(
    String id, {
    required String username,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> removeWebAccess(String id) => throw UnimplementedError();

  @override
  Future<PairingCodeItem> createPairingCode(String id) =>
      throw UnimplementedError();

  @override
  Future<List<PairingCodeItem>> createPairingCodes({
    List<String>? personIds,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Device>> listPersonDevices(String id) =>
      throw UnimplementedError();

  @override
  Future<void> revokeDevice(String id) => throw UnimplementedError();
}

Future<_FakeBfDayAdminRepository> _pump(
  WidgetTester tester, {
  required List<BfDay> days,
  List<Person>? persons,
}) async {
  final repository = _FakeBfDayAdminRepository(days: days);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bfDayAdminRepositoryProvider.overrideWithValue(repository),
        personAdminRepositoryProvider.overrideWithValue(
          _FakePersonAdminRepository(persons ?? []),
        ),
      ],
      child: const MaterialApp(home: BfDaysScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('lists BF-Tage with Zeitraum and Zustand chip', (tester) async {
    await _pump(
      tester,
      days: [
        _bfDay(id: 'd1', name: 'BF-Tag 2026', state: BfDayState.planning),
      ],
    );

    expect(find.textContaining('BF-Tag 2026'), findsOneWidget);
    expect(find.text('in Planung'), findsOneWidget);
  });

  testWidgets('create dialog calls the API with the entered values',
      (tester) async {
    final repository = await _pump(tester, days: []);

    await tester.tap(find.byKey(const Key('create-bf-day')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('bf-day-form-name')),
      'Neuer BF-Tag',
    );
    await tester.tap(find.byKey(const Key('bf-day-form-submit')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, hasLength(1));
    expect(repository.createCalls.single.$1, 'Neuer BF-Tag');
    expect(find.textContaining('Neuer BF-Tag'), findsOneWidget);
  });

  testWidgets('starting a BF-Tag calls start only after confirm',
      (tester) async {
    final repository = await _pump(
      tester,
      days: [_bfDay(id: 'd1', state: BfDayState.planning)],
    );

    await tester.tap(find.byKey(const Key('bf-day-start-d1')));
    await tester.pumpAndSettle();

    expect(repository.startCalls, isEmpty);

    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.startCalls, ['d1']);
    expect(find.text('läuft'), findsOneWidget);
    expect(find.byKey(const Key('bf-day-end-d1')), findsOneWidget);
  });

  testWidgets('a running BF-Tag only offers Beenden, not Starten',
      (tester) async {
    await _pump(
      tester,
      days: [_bfDay(id: 'd1', state: BfDayState.running)],
    );

    expect(find.byKey(const Key('bf-day-start-d1')), findsNothing);
    expect(find.byKey(const Key('bf-day-end-d1')), findsOneWidget);
  });

  testWidgets('starting shows the backend error message on failure',
      (tester) async {
    final repository = _FakeBfDayAdminRepository(
      days: [_bfDay(id: 'd1', state: BfDayState.planning)],
    );
    repository.startError = DioException(
      requestOptions: RequestOptions(path: '/bf-days/d1/start'),
      response: Response(
        requestOptions: RequestOptions(path: '/bf-days/d1/start'),
        statusCode: 409,
        data: {
          'error': {
            'code': 'bf_day_already_running',
            'message': 'Es läuft bereits ein BF-Tag.',
          },
        },
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bfDayAdminRepositoryProvider.overrideWithValue(repository),
          personAdminRepositoryProvider.overrideWithValue(
            _FakePersonAdminRepository([]),
          ),
        ],
        child: const MaterialApp(home: BfDaysScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bf-day-start-d1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Es läuft bereits ein BF-Tag.'), findsOneWidget);
  });

  testWidgets('participants dialog saves the selected person ids',
      (tester) async {
    final repository = await _pump(
      tester,
      days: [_bfDay(id: 'd1')],
      persons: [
        _person(id: 'p1', displayName: 'Max Mustermann'),
        _person(id: 'p2', displayName: 'Erika Musterfrau'),
      ],
    );

    await tester.tap(find.byKey(const Key('bf-day-participants-d1')));
    await tester.pumpAndSettle();

    expect(find.text('Max Mustermann'), findsOneWidget);
    expect(find.text('Erika Musterfrau'), findsOneWidget);

    await tester.tap(find.byKey(const Key('participant-p1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('participants-submit')));
    await tester.pumpAndSettle();

    expect(repository.setParticipantsCalls, hasLength(1));
    expect(repository.setParticipantsCalls.single.$1, 'd1');
    expect(repository.setParticipantsCalls.single.$2, ['p1']);
  });

  testWidgets('"Alle" selects every active person', (tester) async {
    final repository = await _pump(
      tester,
      days: [_bfDay(id: 'd1')],
      persons: [
        _person(id: 'p1'),
        _person(id: 'p2'),
      ],
    );

    await tester.tap(find.byKey(const Key('bf-day-participants-d1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('participants-select-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('participants-submit')));
    await tester.pumpAndSettle();

    expect(repository.setParticipantsCalls.single.$2, unorderedEquals(['p1', 'p2']));
  });
}
