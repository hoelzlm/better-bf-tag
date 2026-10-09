import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/incidents_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BfDay _bfDay({
  String id = 'd1',
  String name = 'BF-Tag 2026',
  BfDayState state = BfDayState.running,
}) {
  return BfDay(
    id: id,
    name: name,
    startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: DateTime.now().add(const Duration(hours: 23)),
    state: state,
  );
}

Incident _incident({
  String id = 'i1',
  String bfDayId = 'd1',
  int number = 1,
  String keyword = 'Verkehrsunfall',
  String address = 'Hauptstraße 1',
  String report = 'PKW gegen Baum',
  String? script,
  IncidentState state = IncidentState.draft,
}) {
  return Incident(
    id: id,
    bfDayId: bfDayId,
    number: number,
    keyword: keyword,
    address: address,
    report: report,
    script: script,
    state: state,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

class _FakeBfDayAdminRepository implements BfDayAdminRepository {
  _FakeBfDayAdminRepository({List<BfDay>? days}) : days = days ?? [];

  List<BfDay> days;

  @override
  Future<List<BfDay>> list() async => List.of(days);

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
  Future<List<Participant>> listParticipants(String day) async => const [];

  @override
  Future<void> setParticipants(String day, List<String> personIds) =>
      throw UnimplementedError();

  @override
  Future<AnonymizationSummary> anonymizationPreview(String bfDayId) =>
      throw UnimplementedError();

  @override
  Future<BfDay> anonymize(String bfDayId) => throw UnimplementedError();
}

class _FakeIncidentRepository implements IncidentRepository {
  _FakeIncidentRepository({Map<String, List<Incident>>? incidentsByDay})
      : incidentsByDay = incidentsByDay ?? {};

  Map<String, List<Incident>> incidentsByDay;
  final List<
      ({
        String day,
        String keyword,
        String address,
        String report,
        String? script,
      })> createCalls = [];
  final List<String> discardCalls = [];
  final List<String> closeCalls = [];
  Object? createError;

  @override
  Future<List<Incident>> list(String day, {IncidentState? state}) async {
    final all = List.of(incidentsByDay[day] ?? const <Incident>[]);
    if (state == null) return all;
    return all.where((i) => i.state == state).toList();
  }

  @override
  Future<Incident> get(String id) async {
    for (final list in incidentsByDay.values) {
      for (final i in list) {
        if (i.id == id) return i;
      }
    }
    throw StateError('incident not found: $id');
  }

  @override
  Future<Incident> create(
    String day, {
    required String keyword,
    required String address,
    String? report,
    String? script,
  }) async {
    createCalls.add((
      day: day,
      keyword: keyword,
      address: address,
      report: report ?? '',
      script: script,
    ));
    final error = createError;
    if (error != null) throw error;
    final created = _incident(
      id: 'new-incident',
      bfDayId: day,
      number: (incidentsByDay[day]?.length ?? 0) + 1,
      keyword: keyword,
      address: address,
      report: report ?? '',
      script: script,
      state: IncidentState.draft,
    );
    incidentsByDay[day] = [...(incidentsByDay[day] ?? []), created];
    return created;
  }

  @override
  Future<Incident> update(
    String id, {
    String? keyword,
    String? address,
    String? report,
    String? script,
  }) async {
    for (final entry in incidentsByDay.entries) {
      final idx = entry.value.indexWhere((i) => i.id == id);
      if (idx != -1) {
        final updated = entry.value[idx].copyWith(
          keyword: keyword,
          address: address,
          report: report,
          script: script,
        );
        incidentsByDay[entry.key] = [
          for (final i in entry.value) if (i.id == id) updated else i,
        ];
        return updated;
      }
    }
    throw StateError('incident not found: $id');
  }

  @override
  Future<Incident> discard(String id) async {
    discardCalls.add(id);
    for (final entry in incidentsByDay.entries) {
      final idx = entry.value.indexWhere((i) => i.id == id);
      if (idx != -1) {
        final updated =
            entry.value[idx].copyWith(state: IncidentState.discarded);
        incidentsByDay[entry.key] = [
          for (final i in entry.value) if (i.id == id) updated else i,
        ];
        return updated;
      }
    }
    throw StateError('incident not found: $id');
  }

  @override
  Future<CloseIncidentResult> close(String id) async {
    closeCalls.add(id);
    for (final entry in incidentsByDay.entries) {
      final idx = entry.value.indexWhere((i) => i.id == id);
      if (idx != -1) {
        final updated = entry.value[idx].copyWith(state: IncidentState.closed);
        incidentsByDay[entry.key] = [
          for (final i in entry.value) if (i.id == id) updated else i,
        ];
        return CloseIncidentResult(incident: updated, discardedAlarmIds: const []);
      }
    }
    throw StateError('incident not found: $id');
  }
}

class _FakeAlarmRepository implements AlarmRepository {
  final List<(String, List<String>, String)> triggerCalls = [];
  TriggerAlarmResult Function()? resultBuilder;
  Object? triggerError;

  @override
  Future<TriggerAlarmResult> trigger(
    String incidentId,
    List<String> vehicleIds, {
    required String id,
  }) async {
    triggerCalls.add((incidentId, vehicleIds, id));
    final error = triggerError;
    if (error != null) throw error;
    final builder = resultBuilder;
    if (builder != null) return builder();
    return TriggerAlarmResult(
      alarm: Alarm(
        id: 'a1',
        incidentId: incidentId,
        state: AlarmState.triggered,
        triggeredAt: DateTime.now(),
        vehicleIds: vehicleIds,
        recipients: const [],
      ),
      doubleCrewed: const [],
    );
  }

  @override
  Future<void> acknowledge(String alarmId) => throw UnimplementedError();

  @override
  Future<Alarm> plan(
    String incidentId,
    List<String> vehicleIds, {
    String? id,
    DateTime? scheduledAt,
    int? offsetMinutes,
  }) =>
      throw UnimplementedError();

  @override
  Future<Alarm> update(
    String alarmId, {
    DateTime? scheduledAt,
    int? offsetMinutes,
    List<String>? vehicleIds,
  }) =>
      throw UnimplementedError();

  @override
  Future<Alarm> discard(String alarmId) => throw UnimplementedError();

  @override
  Future<TriggerAlarmResult> triggerNow(String alarmId) =>
      throw UnimplementedError();
}

Future<_FakeIncidentRepository> _pump(
  WidgetTester tester, {
  required List<BfDay> days,
  Map<String, List<Incident>>? incidents,
  Permission permission = Permission.admin,
  List<Vehicle>? vehicles,
  List<Shift>? shifts,
  _FakeAlarmRepository? alarmRepository,
}) async {
  final bfDayRepository = _FakeBfDayAdminRepository(days: days);
  final incidentRepository =
      _FakeIncidentRepository(incidentsByDay: incidents ?? {});
  final person = Person(
    id: 'p1',
    displayName: 'Max Mustermann',
    personType: PersonType.supervisor,
    permission: permission,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bfDayAdminRepositoryProvider.overrideWithValue(bfDayRepository),
        incidentRepositoryProvider.overrideWithValue(incidentRepository),
        sessionControllerProvider.overrideWith(
          () => _FixedSessionController(SessionSignedIn(person, 'token')),
        ),
        vehiclesProvider.overrideWith(
          (ref) => Stream.value(vehicles ?? const <Vehicle>[]),
        ),
        shiftsProvider.overrideWith(
          (ref) => Stream.value(shifts ?? const <Shift>[]),
        ),
        if (alarmRepository != null)
          alarmRepositoryProvider.overrideWithValue(alarmRepository),
      ],
      child: const MaterialApp(home: IncidentsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return incidentRepository;
}

class _FixedSessionController extends SessionController {
  _FixedSessionController(this._initial);

  final SessionState _initial;

  @override
  SessionState build() => _initial;
}

Vehicle _vehicle({
  String id = 'v1',
  String callSign = 'Florian 1',
  String shortName = 'HLF 1',
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: 'HLF',
    status: FmsStatus.fromCode(2),
    statusChangedAt: null,
    sortOrder: 1,
    active: true,
  );
}

void main() {
  testWidgets('filter switches between shown states', (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [
          _incident(id: 'i1', number: 1, state: IncidentState.draft),
          _incident(id: 'i2', number: 2, state: IncidentState.running),
        ],
      },
    );

    expect(find.text('#1 Verkehrsunfall – Hauptstraße 1'), findsOneWidget);
    expect(find.text('#2 Verkehrsunfall – Hauptstraße 1'), findsNothing);

    await tester.tap(find.text('laufend'));
    await tester.pumpAndSettle();

    expect(find.text('#1 Verkehrsunfall – Hauptstraße 1'), findsNothing);
    expect(find.text('#2 Verkehrsunfall – Hauptstraße 1'), findsOneWidget);
  });

  testWidgets('editor shows script-section with the GEHEIM header',
      (tester) async {
    await _pump(tester, days: [_bfDay()]);

    await tester.tap(find.byKey(const Key('create-incident')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('script-section')), findsOneWidget);
    expect(
      find.text('Drehbuch – GEHEIM, nie für die Mannschaft sichtbar'),
      findsOneWidget,
    );
  });

  testWidgets('discard button only shown for draft incidents',
      (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [
          _incident(id: 'i1', number: 1, state: IncidentState.draft),
        ],
      },
    );

    expect(find.byKey(const Key('discard-incident-i1')), findsOneWidget);

    await tester.tap(find.text('laufend'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discard-incident-i1')), findsNothing);
  });

  testWidgets('create calls repository with entered values', (tester) async {
    final incidentRepository = await _pump(tester, days: [_bfDay()]);

    await tester.tap(find.byKey(const Key('create-incident')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('incident-form-keyword')),
      'Zimmerbrand',
    );
    await tester.enterText(
      find.byKey(const Key('incident-form-address')),
      'Musterweg 5',
    );
    await tester.enterText(
      find.byKey(const Key('incident-form-report')),
      'Rauchentwicklung im 2. OG',
    );
    await tester.enterText(
      find.byKey(const Key('incident-form-script')),
      'Darsteller: 1 Person, leicht verletzt',
    );
    await tester.tap(find.byKey(const Key('incident-form-submit')));
    await tester.pumpAndSettle();

    expect(incidentRepository.createCalls, hasLength(1));
    final call = incidentRepository.createCalls.single;
    expect(call.day, 'd1');
    expect(call.keyword, 'Zimmerbrand');
    expect(call.address, 'Musterweg 5');
    expect(call.report, 'Rauchentwicklung im 2. OG');
    expect(call.script, 'Darsteller: 1 Person, leicht verletzt');
  });

  testWidgets('preparation does not see the Alarmieren button',
      (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
      },
      permission: Permission.preparation,
    );

    expect(find.byKey(const Key('alarm-incident-i1')), findsNothing);
  });

  testWidgets('dispatch sees the Alarmieren button for a draft incident',
      (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
      },
      permission: Permission.dispatch,
    );

    expect(find.byKey(const Key('alarm-incident-i1')), findsOneWidget);
  });

  testWidgets(
      'Alarmieren dialog shows the double-crew warning and calls the '
      'repository once even on a double tap', (tester) async {
    final shift = Shift(
      id: 's1',
      bfDayId: 'd1',
      name: 'Tagschicht',
      startsAt: DateTime.now().subtract(const Duration(hours: 1)),
      endsAt: DateTime.now().add(const Duration(hours: 1)),
      crew: const [
        CrewAssignment(
          vehicleId: 'v1',
          personId: 'p1',
          displayName: 'Erika Musterfrau',
          function: 'GF',
        ),
        CrewAssignment(
          vehicleId: 'v2',
          personId: 'p1',
          displayName: 'Erika Musterfrau',
          function: 'MA',
        ),
      ],
    );
    final alarmRepository = _FakeAlarmRepository();
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
      },
      permission: Permission.dispatch,
      vehicles: [
        _vehicle(id: 'v1', shortName: 'HLF 1'),
        _vehicle(id: 'v2', shortName: 'LF 2'),
      ],
      shifts: [shift],
      alarmRepository: alarmRepository,
    );

    await tester.tap(find.byKey(const Key('alarm-incident-i1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alarm-vehicle-v1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('alarm-vehicle-v2')));
    await tester.pump();

    expect(find.byKey(const Key('alarm-double-crewed-p1')), findsOneWidget);
    expect(
      find.text(
        'Erika Musterfrau sitzt auf mehreren ausgewählten '
        'Fahrzeugen – wird nur einmal alarmiert.',
      ),
      findsWidgets,
    );

    final submitButton = find.byKey(const Key('alarm-dialog-submit'));
    // Fire two taps back-to-back before the first request resolves/rebuilds
    // -- the dialog must disable itself so only one call reaches the
    // repository.
    await tester.tap(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(alarmRepository.triggerCalls, hasLength(1));
    final call = alarmRepository.triggerCalls.single;
    expect(call.$1, 'i1');
    expect(call.$2.toSet(), {'v1', 'v2'});
  });

  testWidgets('Jetzt alarmieren is disabled with 0 vehicles selected',
      (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
      },
      permission: Permission.dispatch,
      vehicles: [_vehicle(id: 'v1')],
    );

    await tester.tap(find.byKey(const Key('alarm-incident-i1')));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('alarm-dialog-submit')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      '409 invalid_state_transition on trigger is shown as a plain notice',
      (tester) async {
    final alarmRepository = _FakeAlarmRepository()
      ..triggerError = DioException(
        requestOptions: RequestOptions(path: '/incidents/i1/alarms'),
        response: Response(
          requestOptions: RequestOptions(path: '/incidents/i1/alarms'),
          statusCode: 409,
          data: {
            'error': {
              'code': 'invalid_state_transition',
              'message': 'Einsatz ist nicht mehr im Entwurf.',
            },
          },
        ),
      );
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
      },
      permission: Permission.dispatch,
      vehicles: [_vehicle(id: 'v1')],
      alarmRepository: alarmRepository,
    );

    await tester.tap(find.byKey(const Key('alarm-incident-i1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('alarm-vehicle-v1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('alarm-dialog-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Einsatz wurde bereits alarmiert.'), findsOneWidget);
  });
}
