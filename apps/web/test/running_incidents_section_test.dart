import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/widgets/running_incidents_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _dispatchPerson = Person(
  id: 'p-dispatch',
  displayName: 'Leitstelle',
  personType: PersonType.supervisor,
  permission: Permission.dispatch,
);

const _crewPerson = Person(
  id: 'p-crew',
  displayName: 'Mannschaft',
  personType: PersonType.youth,
  permission: Permission.crew,
);

class _FakeSessionController extends SessionController {
  _FakeSessionController(this._state);

  final SessionState _state;

  @override
  SessionState build() => _state;
}

class _FakeIncidentRepository implements IncidentRepository {
  final List<String> closeCalls = [];
  Object? closeError;

  @override
  Future<CloseIncidentResult> close(String id) async {
    closeCalls.add(id);
    if (closeError != null) throw closeError!;
    return CloseIncidentResult(
      incident: _incident(id: id, state: IncidentState.closed),
      discardedAlarmIds: const [],
    );
  }

  @override
  Future<Incident> create(
    String day, {
    required String keyword,
    required String address,
    String? report,
    String? script,
  }) =>
      throw UnimplementedError();

  @override
  Future<Incident> discard(String id) => throw UnimplementedError();

  @override
  Future<Incident> get(String id) => throw UnimplementedError();

  @override
  Future<List<Incident>> list(String day, {IncidentState? state}) =>
      throw UnimplementedError();

  @override
  Future<Incident> update(
    String id, {
    String? keyword,
    String? address,
    String? report,
    String? script,
  }) =>
      throw UnimplementedError();
}

Incident _incident({
  String id = 'i1',
  int number = 1,
  String keyword = 'Verkehrsunfall',
  String address = 'Hauptstraße 1',
  IncidentState state = IncidentState.running,
}) {
  return Incident(
    id: id,
    bfDayId: 'd1',
    number: number,
    keyword: keyword,
    address: address,
    report: 'PKW gegen Baum',
    script: null,
    state: state,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Vehicle _vehicle({String id = 'v1', String shortName = 'HLF 1'}) {
  return Vehicle(
    id: id,
    callSign: 'Florian 1',
    shortName: shortName,
    type: 'HLF',
    status: FmsStatus.fromCode(2),
    statusChangedAt: null,
    sortOrder: 1,
    active: true,
  );
}

AlarmRecipient _recipient({
  required String personId,
  required String displayName,
  String vehicleId = 'v1',
  String function = 'GF',
  bool hasDevice = true,
  DateTime? acknowledgedAt,
}) {
  return AlarmRecipient(
    personId: personId,
    displayName: displayName,
    vehicleId: vehicleId,
    function: function,
    hasDevice: hasDevice,
    acknowledgedAt: acknowledgedAt,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Incident> incidents,
  required List<Alarm> alarms,
  List<Vehicle> vehicles = const [],
  Set<String> closeSuggestedIncidentIds = const {},
  List<ScheduledAlarm> scheduledAlarms = const [],
  SessionState session = const SessionUnknown(),
  IncidentRepository? incidentRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        incidentsProvider.overrideWith((ref) => Stream.value(incidents)),
        alarmsProvider.overrideWith((ref) => Stream.value(alarms)),
        vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
        closeSuggestedIncidentIdsProvider.overrideWith(
          (ref) => Stream.value(closeSuggestedIncidentIds),
        ),
        scheduledAlarmsProvider.overrideWith(
          (ref) => Stream.value(scheduledAlarms),
        ),
        sessionControllerProvider.overrideWith(
          () => _FakeSessionController(session),
        ),
        if (incidentRepository != null)
          incidentRepositoryProvider.overrideWithValue(incidentRepository),
      ],
      child: const MaterialApp(
        home: Scaffold(body: RunningIncidentsSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state shows "Keine laufenden Einsätze"', (tester) async {
    await _pump(tester, incidents: const [], alarms: const []);

    expect(find.text('Keine laufenden Einsätze'), findsOneWidget);
  });

  testWidgets(
      'shows the three AckStates with icons, and counts with noDevice not '
      'counted as pending', (tester) async {
    final alarm = Alarm(
      id: 'a1',
      incidentId: 'i1',
      state: AlarmState.triggered,
      triggeredAt: DateTime.now().subtract(const Duration(minutes: 5)),
      vehicleIds: const ['v1'],
      recipients: [
        _recipient(
          personId: 'p1',
          displayName: 'Max Muster',
          acknowledgedAt: DateTime.now(),
        ),
        _recipient(personId: 'p2', displayName: 'Erika Musterfrau'),
        _recipient(
          personId: 'p3',
          displayName: 'Peter Probe',
          hasDevice: false,
        ),
      ],
    );

    await _pump(
      tester,
      incidents: [_incident(id: 'i1')],
      alarms: [alarm],
      vehicles: [_vehicle(id: 'v1', shortName: 'HLF 1')],
    );

    expect(find.text('1 quittiert · 1 ausstehend · 1 kein Gerät'),
        findsOneWidget);

    expect(
      find.byKey(const Key('ack-icon-p1')),
      findsOneWidget,
      reason: 'acknowledged recipient',
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

    expect(
      find.textContaining('Max Muster – HLF 1, GF (quittiert)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Erika Musterfrau – HLF 1, GF (ausstehend)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Peter Probe – HLF 1, GF (kein Gerät)'),
      findsOneWidget,
    );
  });

  testWidgets('shows incident number, keyword, address and elapsed time',
      (tester) async {
    final alarm = Alarm(
      id: 'a1',
      incidentId: 'i1',
      state: AlarmState.triggered,
      triggeredAt: DateTime.now().subtract(const Duration(minutes: 7)),
      vehicleIds: const ['v1'],
      recipients: const [],
    );

    await _pump(
      tester,
      incidents: [
        _incident(
          id: 'i1',
          number: 3,
          keyword: 'Zimmerbrand',
          address: 'Musterweg 5',
        ),
      ],
      alarms: [alarm],
    );

    expect(find.textContaining('#3 Zimmerbrand – Musterweg 5'), findsOneWidget);
    expect(find.textContaining('seit 7 min'), findsOneWidget);
  });

  testWidgets(
      'shows "Push: X zugestellt · Y abgelehnt" and updates after an '
      'alarm.push_reported event', (tester) async {
    final alarm = Alarm(
      id: 'a1',
      incidentId: 'i1',
      state: AlarmState.triggered,
      triggeredAt: DateTime.now().subtract(const Duration(minutes: 5)),
      vehicleIds: const ['v1'],
      recipients: const [],
      pushDelivered: 3,
      pushRejected: 1,
    );
    final alarmsController = StreamController<List<Alarm>>();
    addTearDown(alarmsController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incidentsProvider
              .overrideWith((ref) => Stream.value([_incident(id: 'i1')])),
          alarmsProvider.overrideWith((ref) => alarmsController.stream),
          vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
          closeSuggestedIncidentIdsProvider.overrideWith(
            (ref) => Stream.value(const <String>{}),
          ),
          scheduledAlarmsProvider.overrideWith(
            (ref) => Stream.value(const <ScheduledAlarm>[]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RunningIncidentsSection()),
        ),
      ),
    );
    alarmsController.add([alarm]);
    await tester.pumpAndSettle();

    expect(find.text('Push: 3 zugestellt · 1 abgelehnt'), findsOneWidget);

    alarmsController.add([
      Alarm(
        id: alarm.id,
        incidentId: alarm.incidentId,
        state: alarm.state,
        triggeredAt: alarm.triggeredAt,
        vehicleIds: alarm.vehicleIds,
        recipients: alarm.recipients,
        pushDelivered: 5,
        pushRejected: 2,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Push: 5 zugestellt · 2 abgelehnt'), findsOneWidget);
  });

  testWidgets(
      'shows "Erstalarm" and "1. Nachalarmierung" titles for two alarms',
      (tester) async {
    final erst = Alarm(
      id: 'a1',
      incidentId: 'i1',
      state: AlarmState.triggered,
      triggeredAt: DateTime.now().subtract(const Duration(minutes: 10)),
      vehicleIds: const ['v1'],
      recipients: const [],
    );
    final nach = Alarm(
      id: 'a2',
      incidentId: 'i1',
      state: AlarmState.triggered,
      triggeredAt: DateTime.now().subtract(const Duration(minutes: 3)),
      vehicleIds: const ['v2'],
      recipients: const [],
    );

    await _pump(
      tester,
      incidents: [_incident(id: 'i1')],
      alarms: [erst, nach],
    );

    expect(find.text('Erstalarm'), findsOneWidget);
    expect(find.text('1. Nachalarmierung'), findsOneWidget);
  });

  testWidgets(
      '"Abschluss vorgeschlagen" banner appears and disappears with the '
      'close_suggested_incident_ids set', (tester) async {
    final closeSuggestedController = StreamController<Set<String>>();
    addTearDown(closeSuggestedController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incidentsProvider
              .overrideWith((ref) => Stream.value([_incident(id: 'i1')])),
          alarmsProvider.overrideWith((ref) => Stream.value(const [])),
          vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
          closeSuggestedIncidentIdsProvider
              .overrideWith((ref) => closeSuggestedController.stream),
          scheduledAlarmsProvider.overrideWith(
            (ref) => Stream.value(const <ScheduledAlarm>[]),
          ),
          sessionControllerProvider.overrideWith(
            () => _FakeSessionController(
              const SessionSignedIn(_dispatchPerson, 'token'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RunningIncidentsSection()),
        ),
      ),
    );
    closeSuggestedController.add(const <String>{});
    await tester.pumpAndSettle();
    expect(find.text('Abschluss vorgeschlagen'), findsNothing);

    closeSuggestedController.add(const {'i1'});
    await tester.pumpAndSettle();
    expect(find.text('Abschluss vorgeschlagen'), findsOneWidget);

    closeSuggestedController.add(const <String>{});
    await tester.pumpAndSettle();
    expect(find.text('Abschluss vorgeschlagen'), findsNothing);
  });

  testWidgets('"Einsatz schließen" calls the repository after confirming',
      (tester) async {
    final repository = _FakeIncidentRepository();

    await _pump(
      tester,
      incidents: [_incident(id: 'i1')],
      alarms: const [],
      session: const SessionSignedIn(_dispatchPerson, 'token'),
      incidentRepository: repository,
    );

    await tester.tap(find.byKey(const Key('close-incident-i1')));
    await tester.pumpAndSettle();
    expect(repository.closeCalls, isEmpty, reason: 'needs confirmation');

    await tester.tap(find.byKey(const Key('close-incident-confirm')));
    await tester.pumpAndSettle();

    expect(repository.closeCalls, ['i1']);
  });

  testWidgets(
      'dispatch sees Nachalarmieren and Einsatz schließen buttons',
      (tester) async {
    await _pump(
      tester,
      incidents: [_incident(id: 'i1')],
      alarms: const [],
      session: const SessionSignedIn(_dispatchPerson, 'token'),
    );
    expect(
      find.byKey(const Key('nachalarmieren-incident-i1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('close-incident-i1')), findsOneWidget);
  });

  testWidgets(
      'crew permission does not see Nachalarmieren/Einsatz schließen buttons',
      (tester) async {
    await _pump(
      tester,
      incidents: [_incident(id: 'i1')],
      alarms: const [],
      session: const SessionSignedIn(_crewPerson, 'token'),
    );
    expect(find.byKey(const Key('nachalarmieren-incident-i1')), findsNothing);
    expect(find.byKey(const Key('close-incident-i1')), findsNothing);
  });

  testWidgets(
      'Einsatz schließen warns with the count of planned and missed '
      'Alarmierungen', (tester) async {
    final incident = _incident(id: 'i1');
    final scheduled = [
      ScheduledAlarm(
        incident: incident,
        alarm: Alarm(
          id: 'a1',
          incidentId: 'i1',
          state: AlarmState.planned,
          scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
          vehicleIds: const ['v1'],
          recipients: const [],
        ),
      ),
      ScheduledAlarm(
        incident: incident,
        alarm: Alarm(
          id: 'a2',
          incidentId: 'i1',
          state: AlarmState.missed,
          scheduledAt: DateTime.now().subtract(const Duration(minutes: 20)),
          vehicleIds: const ['v2'],
          recipients: const [],
        ),
      ),
    ];

    await _pump(
      tester,
      incidents: [incident],
      alarms: const [],
      scheduledAlarms: scheduled,
      session: const SessionSignedIn(_dispatchPerson, 'token'),
    );

    await tester.tap(find.byKey(const Key('close-incident-i1')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        '1 geplante Alarmierung und 1 verpasste Alarmierung werden verworfen.',
      ),
      findsOneWidget,
    );
  });
}
