import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/widgets/missed_alarms_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _dispatchPerson = Person(
  id: 'p-dispatch',
  displayName: 'Leitstelle',
  personType: PersonType.supervisor,
  permission: Permission.dispatch,
);

const _preparationPerson = Person(
  id: 'p-prep',
  displayName: 'Vorbereitung',
  personType: PersonType.supervisor,
  permission: Permission.preparation,
);

class _FakeSessionController extends SessionController {
  _FakeSessionController(this._state);

  final SessionState _state;

  @override
  SessionState build() => _state;
}

class _FakeAlarmRepository implements AlarmRepository {
  final List<String> triggerNowCalls = [];
  final List<String> discardCalls = [];

  @override
  Future<TriggerAlarmResult> trigger(
    String incidentId,
    List<String> vehicleIds, {
    required String id,
  }) =>
      throw UnimplementedError();

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
  Future<Alarm> discard(String alarmId) async {
    discardCalls.add(alarmId);
    return Alarm(
      id: alarmId,
      incidentId: 'i1',
      state: AlarmState.discarded,
      vehicleIds: const [],
      recipients: const [],
    );
  }

  @override
  Future<TriggerAlarmResult> triggerNow(String alarmId) async {
    triggerNowCalls.add(alarmId);
    return TriggerAlarmResult(
      alarm: Alarm(
        id: alarmId,
        incidentId: 'i1',
        state: AlarmState.triggered,
        triggeredAt: DateTime.now(),
        vehicleIds: const [],
        recipients: const [],
      ),
      doubleCrewed: const [],
    );
  }
}

Incident _incident({String id = 'i1', int number = 1}) {
  return Incident(
    id: id,
    bfDayId: 'd1',
    number: number,
    keyword: 'Zimmerbrand',
    address: 'Musterweg 1',
    report: '',
    script: null,
    state: IncidentState.running,
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

Future<_FakeAlarmRepository> _pump(
  WidgetTester tester, {
  required List<ScheduledAlarm> scheduledAlarms,
  List<Vehicle> vehicles = const [],
  SessionState session = const SessionSignedIn(_dispatchPerson, 'token'),
}) async {
  final repository = _FakeAlarmRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        scheduledAlarmsProvider.overrideWith(
          (ref) => Stream.value(scheduledAlarms),
        ),
        vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
        sessionControllerProvider.overrideWith(
          () => _FakeSessionController(session),
        ),
        alarmRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: Scaffold(body: MissedAlarmsSection())),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('renders nothing when there are no missed Alarmierungen',
      (tester) async {
    await _pump(tester, scheduledAlarms: const []);
    expect(find.byKey(const Key('missed-alarms-section')), findsNothing);
  });

  testWidgets('shows a missed Alarmierung with incident, vehicles and time',
      (tester) async {
    final incident = _incident(number: 4);
    final missed = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.missed,
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 15)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    await _pump(
      tester,
      scheduledAlarms: [missed],
      vehicles: [_vehicle()],
    );

    expect(find.byKey(const Key('missed-alarms-section')), findsOneWidget);
    expect(find.textContaining('#4 Zimmerbrand'), findsOneWidget);
    expect(find.text('HLF 1'), findsOneWidget);
  });

  testWidgets('"Auslösen" calls triggerNow after confirmation',
      (tester) async {
    final incident = _incident();
    final missed = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.missed,
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 15)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    final repository = await _pump(
      tester,
      scheduledAlarms: [missed],
      vehicles: [_vehicle()],
    );

    await tester.tap(find.byKey(const Key('missed-alarm-trigger-a1')));
    await tester.pumpAndSettle();
    expect(repository.triggerNowCalls, isEmpty, reason: 'needs confirmation');

    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.triggerNowCalls, ['a1']);
  });

  testWidgets('"Verwerfen" calls discard after confirmation', (tester) async {
    final incident = _incident();
    final missed = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.missed,
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 15)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    final repository = await _pump(
      tester,
      scheduledAlarms: [missed],
      vehicles: [_vehicle()],
    );

    await tester.tap(find.byKey(const Key('missed-alarm-discard-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.discardCalls, ['a1']);
  });

  testWidgets('Einsatzvorbereitung sees the list read-only', (tester) async {
    final incident = _incident();
    final missed = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.missed,
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 15)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    await _pump(
      tester,
      scheduledAlarms: [missed],
      vehicles: [_vehicle()],
      session: const SessionSignedIn(_preparationPerson, 'token'),
    );

    expect(find.byKey(const Key('missed-alarms-section')), findsOneWidget);
    expect(find.byKey(const Key('missed-alarm-trigger-a1')), findsNothing);
    expect(find.byKey(const Key('missed-alarm-discard-a1')), findsNothing);
  });
}
