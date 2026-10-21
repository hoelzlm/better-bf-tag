import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/map_tile_provider.dart';
import 'package:bftag_web/screens/incidents_screen.dart';
import 'package:bftag_web/station_provider.dart';
import 'package:bftag_web/widgets/alarm_dialog.dart' show AlarmDialogMode;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Offline [TileProvider] (no network calls in widget tests), mirrors
/// packages/core/test/incident_map_test.dart.
class _FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

class _FakeGeocodeRepository implements GeocodeRepository {
  _FakeGeocodeRepository({List<GeocodeSuggestion>? results})
    : results = results ?? const [];

  List<GeocodeSuggestion> results;
  final List<String> queries = [];

  @override
  Future<List<GeocodeSuggestion>> search(String q) async {
    queries.add(q);
    return results;
  }
}

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
  }) => throw UnimplementedError();

  @override
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) => throw UnimplementedError();

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

class _ThrowingBfDayAdminRepository extends _FakeBfDayAdminRepository {
  @override
  Future<List<BfDay>> list() async {
    throw StateError('boom');
  }
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
      double? latitude,
      double? longitude,
    })
  >
  createCalls = [];
  final List<
    ({String id, double? latitude, double? longitude, bool clearLocation})
  >
  updateCalls = [];
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
    double? latitude,
    double? longitude,
  }) async {
    createCalls.add((
      day: day,
      keyword: keyword,
      address: address,
      report: report ?? '',
      script: script,
      latitude: latitude,
      longitude: longitude,
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
    double? latitude,
    double? longitude,
    bool clearLocation = false,
  }) async {
    updateCalls.add((
      id: id,
      latitude: latitude,
      longitude: longitude,
      clearLocation: clearLocation,
    ));
    for (final entry in incidentsByDay.entries) {
      final idx = entry.value.indexWhere((i) => i.id == id);
      if (idx != -1) {
        final updated = entry.value[idx].copyWith(
          keyword: keyword,
          address: address,
          report: report,
          script: script,
          latitude: latitude,
          longitude: longitude,
        );
        incidentsByDay[entry.key] = [
          for (final i in entry.value)
            if (i.id == id) updated else i,
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
        final updated = entry.value[idx].copyWith(
          state: IncidentState.discarded,
        );
        incidentsByDay[entry.key] = [
          for (final i in entry.value)
            if (i.id == id) updated else i,
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
          for (final i in entry.value)
            if (i.id == id) updated else i,
        ];
        return CloseIncidentResult(
          incident: updated,
          discardedAlarmIds: const [],
        );
      }
    }
    throw StateError('incident not found: $id');
  }
}

class _FakeAlarmRepository implements AlarmRepository {
  final List<(String, List<String>, String)> triggerCalls = [];
  final List<
    ({
      String incidentId,
      List<String> vehicleIds,
      String? id,
      DateTime? scheduledAt,
      int? offsetMinutes,
    })
  >
  planCalls = [];
  TriggerAlarmResult Function()? resultBuilder;
  Object? triggerError;
  Object? planError;

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
  }) async {
    planCalls.add((
      incidentId: incidentId,
      vehicleIds: vehicleIds,
      id: id,
      scheduledAt: scheduledAt,
      offsetMinutes: offsetMinutes,
    ));
    final error = planError;
    if (error != null) throw error;
    return Alarm(
      id: 'planned-a1',
      incidentId: incidentId,
      state: AlarmState.planned,
      scheduledAt: scheduledAt,
      offsetMinutes: offsetMinutes,
      vehicleIds: vehicleIds,
      recipients: const [],
    );
  }

  @override
  Future<Alarm> update(
    String alarmId, {
    DateTime? scheduledAt,
    int? offsetMinutes,
    List<String>? vehicleIds,
  }) => throw UnimplementedError();

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
  List<Alarm>? alarms,
  List<ScheduledAlarm>? scheduledAlarms,
  _FakeAlarmRepository? alarmRepository,
  GeocodeRepository? geocodeRepository,
  LatLng? station,
}) async {
  final bfDayRepository = _FakeBfDayAdminRepository(days: days);
  final incidentRepository = _FakeIncidentRepository(
    incidentsByDay: incidents ?? {},
  );
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
        alarmsProvider.overrideWith(
          (ref) => Stream.value(alarms ?? const <Alarm>[]),
        ),
        geocodeRepositoryProvider.overrideWithValue(
          geocodeRepository ?? _FakeGeocodeRepository(),
        ),
        stationProvider.overrideWith((ref) async => station),
        mapTileProviderProvider.overrideWithValue(_FakeTileProvider()),
        scheduledAlarmsProvider.overrideWith(
          (ref) => Stream.value(scheduledAlarms ?? const <ScheduledAlarm>[]),
        ),
        if (alarmRepository != null)
          alarmRepositoryProvider.overrideWithValue(alarmRepository),
      ],
      child: MaterialApp(
        theme: bftagLightTheme(),
        home: const IncidentsScreen(),
      ),
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
  testWidgets('AC1: filter switches between shown states', (tester) async {
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

    expect(find.byKey(const Key('incident-i1')), findsOneWidget);
    expect(find.byKey(const Key('incident-i2')), findsNothing);

    await tester.tap(find.text('laufend'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('incident-i1')), findsNothing);
    expect(find.byKey(const Key('incident-i2')), findsOneWidget);
  });

  testWidgets('editor shows script-section with the GEHEIM header', (
    tester,
  ) async {
    await _pump(tester, days: [_bfDay()]);

    await tester.tap(find.byKey(const Key('create-incident')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('script-section')), findsOneWidget);
    expect(
      find.text('Drehbuch – GEHEIM, nie für die Mannschaft sichtbar'),
      findsOneWidget,
    );
  });

  testWidgets('AC7: discard button only shown for draft incidents', (
    tester,
  ) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
      },
    );

    expect(find.byKey(const Key('discard-incident-i1')), findsOneWidget);

    await tester.tap(find.text('laufend'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discard-incident-i1')), findsNothing);
  });

  testWidgets('AC3: create calls repository with entered values', (
    tester,
  ) async {
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

  testWidgets('AC22: preparation does not see the Alarmieren button', (
    tester,
  ) async {
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

  testWidgets('AC5: dispatch sees the Alarmieren button for a draft incident', (
    tester,
  ) async {
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
    'AC9/AC10: Alarmieren dialog shows the double-crew warning and calls '
    'the repository once even on a double tap',
    (tester) async {
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
    },
  );

  testWidgets('AC8: Jetzt alarmieren is disabled with 0 vehicles selected', (
    tester,
  ) async {
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
    'AC10: 409 invalid_state_transition on trigger is shown as a plain '
    'notice',
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
    },
  );

  testWidgets(
    'AC8: "Relativ zum Erstalarm" is disabled without an Erstalarm, enabled '
    'once one exists',
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

      final relativeTileBefore = tester.widget<RadioListTile<AlarmDialogMode>>(
        find.byKey(const Key('alarm-mode-relative')),
      );
      // ignore: deprecated_member_use
      expect(relativeTileBefore.onChanged, isNull);
    },
  );

  testWidgets(
    'AC6/AC11: "Relativ zum Erstalarm" is enabled when the incident already '
    'has a triggered Erstalarm, and plans with offset_minutes',
    (tester) async {
      final alarmRepository = _FakeAlarmRepository();
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [_incident(id: 'i1', number: 1, state: IncidentState.running)],
        },
        permission: Permission.dispatch,
        vehicles: [
          _vehicle(id: 'v1'),
          _vehicle(id: 'v2', shortName: 'LF 2'),
        ],
        alarms: [
          Alarm(
            id: 'a1',
            incidentId: 'i1',
            state: AlarmState.triggered,
            triggeredAt: DateTime.now().subtract(const Duration(minutes: 10)),
            vehicleIds: const ['v1'],
            recipients: const [],
          ),
        ],
        alarmRepository: alarmRepository,
      );

      await tester.tap(find.text('laufend'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nachalarmieren-incident-i1')));
      await tester.pumpAndSettle();

      final relativeTile = tester.widget<RadioListTile<AlarmDialogMode>>(
        find.byKey(const Key('alarm-mode-relative')),
      );
      // ignore: deprecated_member_use
      expect(relativeTile.onChanged, isNotNull);

      await tester.tap(find.byKey(const Key('alarm-vehicle-v2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('alarm-mode-relative')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('alarm-offset-minutes')),
        '15',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('alarm-dialog-submit')));
      await tester.pumpAndSettle();

      expect(alarmRepository.planCalls, hasLength(1));
      final call = alarmRepository.planCalls.single;
      expect(call.incidentId, 'i1');
      expect(call.vehicleIds, ['v2']);
      expect(call.offsetMinutes, 15);
      expect(call.scheduledAt, isNull);
    },
  );

  testWidgets(
    'AC11: "Zeitpunkt" mode plans with the picked scheduledAt converted to '
    'UTC',
    (tester) async {
      final alarmRepository = _FakeAlarmRepository();
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
      await tester.tap(find.byKey(const Key('alarm-mode-scheduled')));
      await tester.pump();

      final submitButtonDisabled = tester.widget<FilledButton>(
        find.byKey(const Key('alarm-dialog-submit')),
      );
      expect(
        submitButtonDisabled.onPressed,
        isNull,
        reason: 'no date/time picked yet',
      );
    },
  );

  testWidgets(
    'AC7: Einsatz verwerfen warns with the count of planned Alarmierungen '
    'for a draft incident',
    (tester) async {
      final incident = _incident(
        id: 'i1',
        number: 1,
        state: IncidentState.draft,
      );
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [incident],
        },
        permission: Permission.dispatch,
        scheduledAlarms: [
          ScheduledAlarm(
            incident: incident,
            alarm: Alarm(
              id: 'sa1',
              incidentId: 'i1',
              state: AlarmState.planned,
              scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
              vehicleIds: const ['v1'],
              recipients: const [],
            ),
          ),
        ],
      );

      await tester.tap(find.byKey(const Key('discard-incident-i1')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          '1 geplante Alarmierung werden ebenfalls verworfen.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC7: Einsatz verwerfen calls discard on the repository after confirm',
    (tester) async {
      final incidentRepository = await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
        },
      );

      await tester.tap(find.byKey(const Key('discard-incident-i1')));
      await tester.pumpAndSettle();

      expect(incidentRepository.discardCalls, isEmpty);

      await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
      await tester.pumpAndSettle();

      expect(incidentRepository.discardCalls, ['i1']);
    },
  );

  testWidgets(
    'AC12: empty incidents list shows "Keine Einsätze im Zustand Entwurf."',
    (tester) async {
      await _pump(tester, days: [_bfDay()], incidents: {'d1': []});

      expect(find.text('Keine Einsätze im Zustand Entwurf.'), findsOneWidget);
    },
  );

  testWidgets('no BF-Tage shows "Keine BF-Tage angelegt."', (tester) async {
    await _pump(tester, days: []);

    expect(find.text('Keine BF-Tage angelegt.'), findsOneWidget);
  });

  testWidgets('AC13: BF-Tage load error shows the error message instead of the '
      'dropdown', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bfDayAdminRepositoryProvider.overrideWithValue(
            _ThrowingBfDayAdminRepository(),
          ),
          incidentRepositoryProvider.overrideWithValue(
            _FakeIncidentRepository(),
          ),
          sessionControllerProvider.overrideWith(
            () => _FixedSessionController(
              SessionSignedIn(
                Person(
                  id: 'p1',
                  displayName: 'Max Mustermann',
                  personType: PersonType.supervisor,
                  permission: Permission.admin,
                ),
                'token',
              ),
            ),
          ),
          vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
          shiftsProvider.overrideWith((ref) => Stream.value(const [])),
          alarmsProvider.overrideWith((ref) => Stream.value(const [])),
          geocodeRepositoryProvider.overrideWithValue(_FakeGeocodeRepository()),
          stationProvider.overrideWith((ref) async => null),
          mapTileProviderProvider.overrideWithValue(_FakeTileProvider()),
          scheduledAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: bftagLightTheme(),
          home: const IncidentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BF-Tage konnten nicht geladen werden.'), findsOneWidget);
    expect(find.byKey(const Key('bf-day-dropdown')), findsNothing);
  });

  group('Einsatzort (Karte) (ADR 0026)', () {
    testWidgets('search finds a suggestion, selecting it and saving sends its '
        'coordinates', (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final geocodeRepository = _FakeGeocodeRepository(
        results: const [
          GeocodeSuggestion(
            label: 'Musterweg 5, Musterstadt',
            latitude: 52.5,
            longitude: 13.4,
          ),
        ],
      );
      final incidentRepository = await _pump(
        tester,
        days: [_bfDay()],
        geocodeRepository: geocodeRepository,
      );

      await tester.tap(find.byKey(const Key('create-incident')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('incident-form-address')),
        'Musterweg 5',
      );
      await tester.tap(
        find.byKey(const Key('incident-form-location-search-button')),
      );
      await tester.pumpAndSettle();

      expect(geocodeRepository.queries, ['Musterweg 5']);
      // The address field itself is never overwritten by the search.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('incident-form-address')))
            .controller!
            .text,
        'Musterweg 5',
      );

      await tester.tap(find.text('Musterweg 5, Musterstadt'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('incident-form-submit')));
      await tester.pumpAndSettle();

      expect(incidentRepository.createCalls, hasLength(1));
      final call = incidentRepository.createCalls.single;
      expect(call.latitude, 52.5);
      expect(call.longitude, 13.4);
    });

    testWidgets(
        'BF-Tag: one address field -- saving with an Adresse but no pin '
        'geocodes it and sends the best match as coordinates', (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final geocodeRepository = _FakeGeocodeRepository(
        results: const [
          GeocodeSuggestion(
            label: 'Musterweg 5, Musterstadt',
            latitude: 52.5,
            longitude: 13.4,
          ),
        ],
      );
      final incidentRepository = await _pump(
        tester,
        days: [_bfDay()],
        geocodeRepository: geocodeRepository,
      );

      await tester.tap(find.byKey(const Key('create-incident')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incident-form-location-search')), findsNothing);
      expect(find.text('Adresssuche'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('incident-form-address')),
        'Musterweg 5',
      );
      await tester.tap(find.byKey(const Key('incident-form-submit')));
      await tester.pumpAndSettle();

      expect(geocodeRepository.queries, ['Musterweg 5']);
      final call = incidentRepository.createCalls.single;
      expect(call.address, 'Musterweg 5');
      expect(call.latitude, 52.5);
      expect(call.longitude, 13.4);
    });

    testWidgets('saving still works when the address cannot be found',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final incidentRepository = await _pump(
        tester,
        days: [_bfDay()],
        geocodeRepository: _FakeGeocodeRepository(results: const []),
      );

      await tester.tap(find.byKey(const Key('create-incident')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('incident-form-address')),
        'Nirgendwo',
      );
      await tester.tap(find.byKey(const Key('incident-form-submit')));
      await tester.pumpAndSettle();

      final call = incidentRepository.createCalls.single;
      expect(call.latitude, isNull);
      expect(call.longitude, isNull);
    });

    testWidgets('empty search results show "Keine Vorschläge"', (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(
        tester,
        days: [_bfDay()],
        geocodeRepository: _FakeGeocodeRepository(results: const []),
      );

      await tester.tap(find.byKey(const Key('create-incident')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('incident-form-address')),
        'Nirgendwo',
      );
      await tester.tap(
        find.byKey(const Key('incident-form-location-search-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keine Vorschläge'), findsOneWidget);
    });

    testWidgets('"Pin entfernen" removes an existing pin and save sends null '
        'coordinates', (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final incident = _incident(
        id: 'i1',
        number: 1,
        state: IncidentState.draft,
      ).copyWith(latitude: 52.5, longitude: 13.4);
      final incidentRepository = await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [incident],
        },
      );

      await tester.tap(find.byKey(const Key('incident-i1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incident-form-remove-pin')), findsOneWidget);
      await tester.tap(find.byKey(const Key('incident-form-remove-pin')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incident-form-remove-pin')), findsNothing);

      await tester.tap(find.byKey(const Key('incident-form-submit')));
      await tester.pumpAndSettle();

      expect(incidentRepository.updateCalls, hasLength(1));
      final call = incidentRepository.updateCalls.single;
      expect(call.latitude, isNull);
      expect(call.longitude, isNull);
      expect(call.clearLocation, isTrue);
    });
  });

  testWidgets('AC15/AC16: successful create switches the filter to Entwurf, '
      'highlights the new card and moves focus to its Alarmieren button '
      '(concept §3.4a/§5)', (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.running)],
      },
      permission: Permission.dispatch,
    );

    await tester.tap(find.text('laufend'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('incident-i1')), findsOneWidget);

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
    await tester.tap(find.byKey(const Key('incident-form-submit')));
    await tester.pumpAndSettle();

    // Filter switched to "Entwurf": the running incident is now
    // hidden, the new draft is shown.
    expect(find.byKey(const Key('incident-i1')), findsNothing);
    expect(find.byKey(const Key('incident-new-incident')), findsOneWidget);

    // Briefly highlighted (primaryContainer) right after creation.
    BoxDecoration decorationOf(Key key) =>
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byKey(key),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration
            as BoxDecoration;

    final theme = bftagLightTheme();
    expect(
      decorationOf(const Key('incident-new-incident')).color,
      theme.colorScheme.primaryContainer,
    );

    // Keyboard focus moved onto the new card's Alarmieren button: Enter
    // opens its AlarmDialog without any further tap.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Einsatz #2 "Zimmerbrand" alarmieren'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    // Highlight clears again after ~700ms.
    await tester.pump(const Duration(milliseconds: 750));
    expect(
      decorationOf(const Key('incident-new-incident')).color,
      isNot(theme.colorScheme.primaryContainer),
    );
  });

  testWidgets(
    'AC19: a successful Sofort-Erstalarm (not a Nachalarmierung) switches '
    'the filter to "laufend" (concept §3.4c)',
    (tester) async {
      final alarmRepository = _FakeAlarmRepository();
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
        },
        permission: Permission.dispatch,
        vehicles: [_vehicle(id: 'v1', shortName: 'HLF 1')],
        alarmRepository: alarmRepository,
      );

      await tester.tap(find.byKey(const Key('alarm-incident-i1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alarm-vehicle-v1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('alarm-dialog-submit')));
      await tester.pumpAndSettle();

      expect(alarmRepository.triggerCalls, hasLength(1));
      final filter = tester.widget<SegmentedButton<IncidentState>>(
        find.byKey(const Key('incident-filter')),
      );
      expect(filter.selected, {IncidentState.running});
    },
  );

  testWidgets('AC17/AC18: AlarmDialog opens with focus on the first vehicle '
      'checkbox; Space then Enter triggers the alarm without a single tap '
      '(concept §3.4b)', (tester) async {
    final alarmRepository = _FakeAlarmRepository();
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
      },
      permission: Permission.dispatch,
      vehicles: [_vehicle(id: 'v1', shortName: 'HLF 1')],
      alarmRepository: alarmRepository,
    );

    await tester.tap(find.byKey(const Key('alarm-incident-i1')));
    await tester.pumpAndSettle();

    // Enter with no vehicle selected does nothing (invalid submit).
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(alarmRepository.triggerCalls, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(alarmRepository.triggerCalls, hasLength(1));
    expect(alarmRepository.triggerCalls.single.$2, ['v1']);
  });

  testWidgets(
    'AC2: "Einsatz anlegen" only opens the create dialog when a BF-Tag is '
    'selected and not ended',
    (tester) async {
      await _pump(
        tester,
        days: [_bfDay(state: BfDayState.ended)],
        incidents: {'d1': []},
      );

      final buttonEnded = tester.widget<FilledButton>(
        find.byKey(const Key('create-incident')),
      );
      expect(buttonEnded.onPressed, isNull);

      await tester.tap(find.byKey(const Key('create-incident')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('incident-form-keyword')), findsNothing);
    },
  );

  testWidgets(
    'AC4: tapping a card (outside the action buttons) opens the Bearbeiten '
    'dialog prefilled',
    (tester) async {
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [
            _incident(
              id: 'i1',
              number: 1,
              keyword: 'Zimmerbrand',
              address: 'Musterweg 5',
            ),
          ],
        },
      );

      await tester.tap(find.byKey(const Key('incident-i1')));
      await tester.pumpAndSettle();

      expect(find.text('Einsatz bearbeiten'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('incident-form-keyword')))
            .controller!
            .text,
        'Zimmerbrand',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('incident-form-address')))
            .controller!
            .text,
        'Musterweg 5',
      );
    },
  );

  testWidgets(
    'AC6: Nachalarmieren preselects already-alarmed vehicles disabled as '
    '"bereits alarmiert"',
    (tester) async {
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [_incident(id: 'i1', number: 1, state: IncidentState.running)],
        },
        permission: Permission.dispatch,
        vehicles: [
          _vehicle(id: 'v1'),
          _vehicle(id: 'v2', shortName: 'LF 2'),
        ],
        alarms: [
          Alarm(
            id: 'a1',
            incidentId: 'i1',
            state: AlarmState.triggered,
            triggeredAt: DateTime.now().subtract(const Duration(minutes: 5)),
            vehicleIds: const ['v1'],
            recipients: const [],
          ),
        ],
      );

      await tester.tap(find.text('laufend'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nachalarmieren-incident-i1')));
      await tester.pumpAndSettle();

      expect(find.text('Nachalarmierung für Einsatz #1'), findsOneWidget);
      final alreadyAlarmed = tester.widget<CheckboxListTile>(
        find.byKey(const Key('alarm-vehicle-v1')),
      );
      expect(alreadyAlarmed.value, isTrue);
      expect(alreadyAlarmed.onChanged, isNull);
      final other = tester.widget<CheckboxListTile>(
        find.byKey(const Key('alarm-vehicle-v2')),
      );
      expect(other.value, isFalse);
      expect(other.onChanged, isNotNull);
    },
  );

  testWidgets(
    'AC14: closed incidents show all fields readOnly in the Bearbeiten '
    'dialog with no Speichern button',
    (tester) async {
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [_incident(id: 'i1', number: 1, state: IncidentState.closed)],
        },
      );

      await tester.tap(find.text('abgeschlossen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('incident-i1')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('incident-form-keyword')))
            .readOnly,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('incident-form-script')))
            .readOnly,
        isTrue,
      );
      expect(find.byKey(const Key('incident-form-submit')), findsNothing);
    },
  );

  testWidgets(
    'AC20: every card shows a Zustands-Label with key incident-state-\$id '
    'regardless of the active filter',
    (tester) async {
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [_incident(id: 'i1', number: 1, state: IncidentState.draft)],
        },
      );

      expect(find.byKey(const Key('incident-state-i1')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('incident-state-i1')),
          matching: find.text('Entwurf'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC21: a running incident with a triggered Alarm shows "seit X min", '
    'computed from the earliest triggeredAt; without one the meta is '
    'absent',
    (tester) async {
      await _pump(
        tester,
        days: [_bfDay()],
        incidents: {
          'd1': [
            _incident(id: 'i1', number: 1, state: IncidentState.running),
            _incident(id: 'i2', number: 2, state: IncidentState.running),
          ],
        },
        alarms: [
          Alarm(
            id: 'a1',
            incidentId: 'i1',
            state: AlarmState.triggered,
            triggeredAt: DateTime.now().subtract(const Duration(minutes: 7)),
            vehicleIds: const ['v1'],
            recipients: const [],
          ),
        ],
      );

      await tester.tap(find.text('laufend'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incident-elapsed-i1')), findsOneWidget);
      expect(find.text('seit 7 min'), findsOneWidget);
      expect(find.byKey(const Key('incident-elapsed-i2')), findsNothing);
    },
  );
}
