import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/monitor_clock.dart';
import 'package:bftag_web/widgets/scheduled_alarms_section.dart';
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
  final List<({String id, DateTime? scheduledAt, int? offsetMinutes, List<String>? vehicleIds})>
      updateCalls = [];

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
  }) async {
    updateCalls.add((
      id: alarmId,
      scheduledAt: scheduledAt,
      offsetMinutes: offsetMinutes,
      vehicleIds: vehicleIds,
    ));
    return Alarm(
      id: alarmId,
      incidentId: 'i1',
      state: AlarmState.planned,
      scheduledAt: scheduledAt,
      offsetMinutes: offsetMinutes,
      vehicleIds: vehicleIds ?? const [],
      recipients: const [],
    );
  }

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

Incident _incident({
  String id = 'i1',
  int number = 1,
  String keyword = 'Zimmerbrand',
  IncidentState state = IncidentState.running,
}) {
  return Incident(
    id: id,
    bfDayId: 'd1',
    number: number,
    keyword: keyword,
    address: 'Musterweg 1',
    report: '',
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
        monitorClockProvider.overrideWith(
          (ref) => Stream.value(DateTime.now()),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ScheduledAlarmsSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('renders nothing when there are no planned Alarmierungen',
      (tester) async {
    await _pump(tester, scheduledAlarms: const []);
    expect(find.byKey(const Key('scheduled-alarms-section')), findsNothing);
  });

  testWidgets('shows the next planned alarm first, sorted', (tester) async {
    final incident = _incident();
    final earlier = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a-early',
        incidentId: incident.id,
        state: AlarmState.planned,
        scheduledAt: DateTime.now().add(const Duration(minutes: 2)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );
    final later = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a-late',
        incidentId: incident.id,
        state: AlarmState.planned,
        scheduledAt: DateTime.now().add(const Duration(minutes: 20)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    await _pump(
      tester,
      scheduledAlarms: [earlier, later],
      vehicles: [_vehicle()],
    );

    final rows = tester.widgetList(find.byType(Row));
    expect(rows, isNotEmpty);
    expect(find.byKey(const Key('scheduled-alarm-a-early')), findsOneWidget);
    expect(find.byKey(const Key('scheduled-alarm-a-late')), findsOneWidget);
  });

  testWidgets('"Jetzt auslösen" calls triggerNow after confirmation',
      (tester) async {
    final incident = _incident();
    final scheduled = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.planned,
        scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    final repository = await _pump(
      tester,
      scheduledAlarms: [scheduled],
      vehicles: [_vehicle()],
    );

    await tester.tap(find.byKey(const Key('scheduled-alarm-trigger-a1')));
    await tester.pumpAndSettle();
    expect(repository.triggerNowCalls, isEmpty, reason: 'needs confirmation');

    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.triggerNowCalls, ['a1']);
  });

  testWidgets('"Verwerfen" calls discard after confirmation', (tester) async {
    final incident = _incident();
    final scheduled = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.planned,
        scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    final repository = await _pump(
      tester,
      scheduledAlarms: [scheduled],
      vehicles: [_vehicle()],
    );

    await tester.tap(find.byKey(const Key('scheduled-alarm-discard-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.discardCalls, ['a1']);
  });

  testWidgets('Einsatzvorbereitung sees the list read-only', (tester) async {
    final incident = _incident();
    final scheduled = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.planned,
        scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    await _pump(
      tester,
      scheduledAlarms: [scheduled],
      vehicles: [_vehicle()],
      session: const SessionSignedIn(_preparationPerson, 'token'),
    );

    expect(find.byKey(const Key('scheduled-alarm-trigger-a1')), findsNothing);
    expect(find.byKey(const Key('scheduled-alarm-change-a1')), findsNothing);
    expect(find.byKey(const Key('scheduled-alarm-discard-a1')), findsNothing);
  });

  testWidgets('"Ändern" updates offset_minutes for a relative Alarmierung',
      (tester) async {
    final incident = _incident();
    final scheduled = ScheduledAlarm(
      incident: incident,
      alarm: Alarm(
        id: 'a1',
        incidentId: incident.id,
        state: AlarmState.planned,
        scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
        offsetMinutes: 5,
        vehicleIds: const ['v1'],
        recipients: const [],
      ),
    );

    final repository = await _pump(
      tester,
      scheduledAlarms: [scheduled],
      vehicles: [_vehicle()],
    );

    await tester.tap(find.byKey(const Key('scheduled-alarm-change-a1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('change-alarm-offset-minutes')),
      '42',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('change-alarm-submit')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, hasLength(1));
    expect(repository.updateCalls.single.id, 'a1');
    expect(repository.updateCalls.single.offsetMinutes, 42);
  });
}
