import 'dart:async';
import 'dart:math';

import 'package:bftag_core/bftag_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [Random] that always returns 0, so backoff delays in tests are exact.
class _ZeroRandom implements Random {
  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

class _FakeSink implements WebSocketConnectionSink {
  bool closed = false;

  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }
}

class _FakeConnection implements WebSocketConnection {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  final _FakeSink _sink = _FakeSink();

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketConnectionSink get sink => _sink;

  @override
  int? get closeCode => null;

  void emit(Map<String, dynamic> message) {
    _controller.add(message);
  }
}

class _FakeConnector {
  final List<_FakeConnection> connections = <_FakeConnection>[];

  WebSocketConnection call(Uri uri) {
    final connection = _FakeConnection();
    connections.add(connection);
    return connection;
  }
}

BfDay _bfDay({String id = 'day1', BfDayState state = BfDayState.running}) {
  return BfDay(
    id: id,
    name: 'BF-Tag',
    startsAt: DateTime.parse('2026-06-01T00:00:00Z'),
    endsAt: DateTime.parse('2026-06-02T00:00:00Z'),
    state: state,
  );
}

Incident _incident({
  String id = 'i1',
  String bfDayId = 'day1',
  int number = 1,
  IncidentState state = IncidentState.running,
}) {
  return Incident(
    id: id,
    bfDayId: bfDayId,
    number: number,
    keyword: 'Verkehrsunfall',
    address: 'Hauptstraße 1',
    report: 'PKW gegen Baum',
    script: null,
    state: state,
    createdAt: DateTime.parse('2026-10-09T08:00:00Z'),
    updatedAt: DateTime.parse('2026-10-09T08:00:00Z'),
  );
}

AlarmRecipient _recipient({
  String personId = 'p1',
  String displayName = 'Max Muster',
  String vehicleId = 'v1',
  bool hasDevice = true,
  DateTime? acknowledgedAt,
}) {
  return AlarmRecipient(
    personId: personId,
    displayName: displayName,
    vehicleId: vehicleId,
    function: 'GF',
    hasDevice: hasDevice,
    acknowledgedAt: acknowledgedAt,
  );
}

Alarm _alarm({
  String id = 'a1',
  String incidentId = 'i1',
  AlarmState state = AlarmState.triggered,
  DateTime? scheduledAt,
  DateTime? triggeredAt,
  List<String> vehicleIds = const ['v1'],
  List<AlarmRecipient> recipients = const [],
}) {
  return Alarm(
    id: id,
    incidentId: incidentId,
    state: state,
    scheduledAt: scheduledAt,
    triggeredAt: state == AlarmState.triggered
        ? (triggeredAt ?? DateTime.parse('2026-10-09T08:00:00Z'))
        : triggeredAt,
    vehicleIds: vehicleIds,
    recipients: recipients,
  );
}

Map<String, dynamic> _alarmJson(Alarm alarm) {
  return {
    'id': alarm.id,
    'incident_id': alarm.incidentId,
    'state': alarm.state.name,
    'scheduled_at': alarm.scheduledAt?.toIso8601String(),
    'triggered_at': alarm.triggeredAt?.toIso8601String(),
    'vehicle_ids': alarm.vehicleIds,
    'recipients': alarm.recipients
        .map(
          (r) => {
            'person_id': r.personId,
            'display_name': r.displayName,
            'vehicle_id': r.vehicleId,
            'function': r.function,
            'has_device': r.hasDevice,
            'acknowledged_at': r.acknowledgedAt?.toIso8601String(),
          },
        )
        .toList(),
  };
}

Map<String, dynamic> _alarmTriggeredEvent({
  required int seq,
  required Incident incident,
  required Alarm alarm,
}) {
  return {
    'seq': seq,
    'type': 'alarm.triggered',
    'at': '2026-10-09T08:00:00Z',
    'data': {
      'incident': incident.toJson(),
      'alarm': _alarmJson(alarm),
    },
  };
}

Map<String, dynamic> _alarmAcknowledgedEvent({
  required int seq,
  required String alarmId,
  required String incidentId,
  required String personId,
  required String displayName,
  required DateTime acknowledgedAt,
}) {
  return {
    'seq': seq,
    'type': 'alarm.acknowledged',
    'at': '2026-10-09T08:00:00Z',
    'data': {
      'alarm_id': alarmId,
      'incident_id': incidentId,
      'person_id': personId,
      'display_name': displayName,
      'acknowledged_at': acknowledgedAt.toIso8601String(),
    },
  };
}

Map<String, dynamic> _alarmPushReportedEvent({
  required int seq,
  required String alarmId,
  required String incidentId,
  required int pushDelivered,
  required int pushRejected,
}) {
  return {
    'seq': seq,
    'type': 'alarm.push_reported',
    'at': '2026-10-09T08:00:00Z',
    'data': {
      'alarm_id': alarmId,
      'incident_id': incidentId,
      'push_delivered': pushDelivered,
      'push_rejected': pushRejected,
    },
  };
}

Map<String, dynamic> _alarmPlannedEvent({
  required int seq,
  required Incident incident,
  required Alarm alarm,
}) {
  return {
    'seq': seq,
    'type': 'alarm.planned',
    'at': '2026-10-09T08:00:00Z',
    'data': {
      'incident': incident.toJson(),
      'alarm': _alarmJson(alarm),
    },
  };
}

Map<String, dynamic> _alarmMissedEvent({
  required int seq,
  required Incident incident,
  required Alarm alarm,
}) {
  return {
    'seq': seq,
    'type': 'alarm.missed',
    'at': '2026-10-09T08:00:00Z',
    'data': {
      'incident': incident.toJson(),
      'alarm': _alarmJson(alarm),
    },
  };
}

Map<String, dynamic> _alarmDiscardedEvent({
  required int seq,
  required String alarmId,
  required String incidentId,
}) {
  return {
    'seq': seq,
    'type': 'alarm.discarded',
    'at': '2026-10-09T08:00:00Z',
    'data': {
      'alarm_id': alarmId,
      'incident_id': incidentId,
    },
  };
}

RealtimeClient _buildClient({
  required List<Completer<Snapshot>> snapshotCompleters,
  required _FakeConnector connector,
}) {
  return RealtimeClient(
    wsEndpoint: Uri.parse('ws://api.test/ws'),
    loadSnapshot: () {
      final completer = Completer<Snapshot>();
      snapshotCompleters.add(completer);
      return completer.future;
    },
    accessToken: () async => 'token-123',
    refreshSession: () async {},
    connector: connector.call,
    heartbeatInterval: const Duration(seconds: 10),
    random: _ZeroRandom(),
  );
}

void main() {
  group('RealtimeClient alarms', () {
    test('alarm.triggered live upserts the alarm and the incident', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay()),
        );
        async.flushMicrotasks();
        expect(states.last.incidents, isEmpty);
        expect(states.last.alarms, isEmpty);

        final incident = _incident(state: IncidentState.running);
        final alarm = _alarm(recipients: [_recipient()]);
        connector.connections.single.emit(
          _alarmTriggeredEvent(seq: 11, incident: incident, alarm: alarm),
        );
        async.flushMicrotasks();

        expect(states.last.incidents, hasLength(1));
        expect(states.last.incidents.single.id, 'i1');
        expect(states.last.alarms, hasLength(1));
        expect(states.last.alarms.single.id, 'a1');

        client.dispose();
      });
    });

    test('alarm.acknowledged sets acknowledgedAt on the matching recipient',
        () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final alarm = _alarm(
          recipients: [
            _recipient(personId: 'p1'),
            _recipient(personId: 'p2', displayName: 'Erika Musterfrau'),
          ],
        );

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [_incident(state: IncidentState.running)],
            alarms: [alarm],
          ),
        );
        async.flushMicrotasks();

        connector.connections.single.emit(
          _alarmAcknowledgedEvent(
            seq: 11,
            alarmId: alarm.id,
            incidentId: alarm.incidentId,
            personId: 'p1',
            displayName: 'Max Muster',
            acknowledgedAt: DateTime.parse('2026-10-09T09:00:00Z'),
          ),
        );
        async.flushMicrotasks();

        final updated = states.last.alarms.single;
        final p1 = updated.recipients.firstWhere((r) => r.personId == 'p1');
        final p2 = updated.recipients.firstWhere((r) => r.personId == 'p2');
        expect(p1.acknowledgedAt, DateTime.parse('2026-10-09T09:00:00Z'));
        expect(p1.ackState, AckState.acknowledged);
        expect(p2.acknowledgedAt, isNull);

        client.dispose();
      });
    });

    test('incident leaving running drops its alarms', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final alarm = _alarm();

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [_incident(state: IncidentState.running)],
            alarms: [alarm],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.alarms, hasLength(1));

        connector.connections.single.emit({
          'seq': 11,
          'type': 'incident.updated',
          'at': '2026-10-09T08:00:00Z',
          'data': _incident(state: IncidentState.closed).toJson(),
        });
        async.flushMicrotasks();

        expect(states.last.incidents, isEmpty);
        expect(states.last.alarms, isEmpty);

        client.dispose();
      });
    });

    test('liveAlarmTriggered fires for a live event, not for snapshot content',
        () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final liveAlarms = <Alarm>[];
        client.liveAlarmTriggered.listen(liveAlarms.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [_incident(state: IncidentState.running)],
            alarms: [_alarm(id: 'from-snapshot')],
          ),
        );
        async.flushMicrotasks();

        expect(liveAlarms, isEmpty, reason: 'snapshot content never fires');

        final liveAlarm = _alarm(id: 'from-live-event');
        connector.connections.single.emit(
          _alarmTriggeredEvent(
            seq: 11,
            incident: _incident(state: IncidentState.running),
            alarm: liveAlarm,
          ),
        );
        async.flushMicrotasks();

        expect(liveAlarms, hasLength(1));
        expect(liveAlarms.single.id, 'from-live-event');

        client.dispose();
      });
    });

    test('a gap-triggered snapshot reload does not re-fire liveAlarmTriggered',
        () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final liveAlarms = <Alarm>[];
        client.liveAlarmTriggered.listen(liveAlarms.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay()),
        );
        async.flushMicrotasks();

        // Force a gap -> reload, whose snapshot already contains an
        // alarm. That must not be reported as live.
        connector.connections.single.emit({
          'seq': 20,
          'type': 'vehicle.status_changed',
          'at': '2026-10-09T08:00:00Z',
          'data': {'vehicle_id': 'v1', 'status': 2, 'source': 'app'},
        });
        async.flushMicrotasks();
        expect(completers, hasLength(2));

        completers[1].complete(
          Snapshot(
            seq: 20,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [_incident(state: IncidentState.running)],
            alarms: [_alarm(id: 'reloaded')],
          ),
        );
        async.flushMicrotasks();

        expect(liveAlarms, isEmpty);

        client.dispose();
      });
    });

    test('alarm.push_reported updates the counters on the matching alarm',
        () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final alarm = _alarm();

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [_incident(state: IncidentState.running)],
            alarms: [alarm],
          ),
        );
        async.flushMicrotasks();

        connector.connections.single.emit(
          _alarmPushReportedEvent(
            seq: 11,
            alarmId: alarm.id,
            incidentId: alarm.incidentId,
            pushDelivered: 3,
            pushRejected: 1,
          ),
        );
        async.flushMicrotasks();

        final updated = states.last.alarms.single;
        expect(updated.pushDelivered, 3);
        expect(updated.pushRejected, 1);

        client.dispose();
      });
    });

    test('alarm.push_reported for an unknown alarm id is ignored', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final alarm = _alarm();

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [_incident(state: IncidentState.running)],
            alarms: [alarm],
          ),
        );
        async.flushMicrotasks();

        connector.connections.single.emit(
          _alarmPushReportedEvent(
            seq: 11,
            alarmId: 'unknown-alarm',
            incidentId: alarm.incidentId,
            pushDelivered: 5,
            pushRejected: 2,
          ),
        );
        async.flushMicrotasks();

        final unchanged = states.last.alarms.single;
        expect(unchanged.pushDelivered, 0);
        expect(unchanged.pushRejected, 0);

        client.dispose();
      });
    });

    test('alarm.planned upserts into scheduledAlarms', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [_incident(state: IncidentState.draft)],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.scheduledAlarms, isEmpty);

        final incident = _incident(state: IncidentState.draft);
        final alarm = _alarm(
          state: AlarmState.planned,
          scheduledAt: DateTime.parse('2026-10-09T08:08:00Z'),
        );
        connector.connections.single.emit(
          _alarmPlannedEvent(seq: 11, incident: incident, alarm: alarm),
        );
        async.flushMicrotasks();

        expect(states.last.scheduledAlarms, hasLength(1));
        expect(states.last.scheduledAlarms.single.alarm.id, 'a1');
        expect(states.last.scheduledAlarms.single.incident.id, 'i1');

        client.dispose();
      });
    });

    test(
      'alarm.planned re-plan with a new time re-sorts scheduledAlarms',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          final incident = _incident(state: IncidentState.draft);
          final a1 = _alarm(
            id: 'a1',
            state: AlarmState.planned,
            scheduledAt: DateTime.parse('2026-10-09T08:05:00Z'),
          );
          final a2 = _alarm(
            id: 'a2',
            state: AlarmState.planned,
            scheduledAt: DateTime.parse('2026-10-09T08:10:00Z'),
          );
          completers[0].complete(
            Snapshot(
              seq: 10,
              vehicles: const [],
              bfDay: _bfDay(),
              incidents: [incident],
              scheduledAlarms: [
                ScheduledAlarm(incident: incident, alarm: a1),
                ScheduledAlarm(incident: incident, alarm: a2),
              ],
            ),
          );
          async.flushMicrotasks();
          expect(
            states.last.scheduledAlarms.map((sa) => sa.alarm.id),
            ['a1', 'a2'],
          );

          // Re-plan a1 to a later time than a2 -> must re-sort.
          final a1Replanned = _alarm(
            id: 'a1',
            state: AlarmState.planned,
            scheduledAt: DateTime.parse('2026-10-09T08:20:00Z'),
          );
          connector.connections.single.emit(
            _alarmPlannedEvent(seq: 11, incident: incident, alarm: a1Replanned),
          );
          async.flushMicrotasks();

          expect(
            states.last.scheduledAlarms.map((sa) => sa.alarm.id),
            ['a2', 'a1'],
          );
          expect(
            states.last.scheduledAlarms.last.alarm.scheduledAt,
            DateTime.parse('2026-10-09T08:20:00Z'),
          );

          client.dispose();
        });
      },
    );

    test('alarm.missed upserts into scheduledAlarms', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        final incident = _incident(state: IncidentState.draft);
        final alarm = _alarm(
          state: AlarmState.planned,
          scheduledAt: DateTime.parse('2026-10-09T08:00:00Z'),
        );
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [incident],
            scheduledAlarms: [ScheduledAlarm(incident: incident, alarm: alarm)],
          ),
        );
        async.flushMicrotasks();

        final missedAlarm = _alarm(state: AlarmState.missed);
        connector.connections.single.emit(
          _alarmMissedEvent(seq: 11, incident: incident, alarm: missedAlarm),
        );
        async.flushMicrotasks();

        expect(states.last.scheduledAlarms, hasLength(1));
        expect(states.last.scheduledAlarms.single.alarm.state, AlarmState.missed);

        client.dispose();
      });
    });

    test('alarm.discarded removes the matching entry from scheduledAlarms',
        () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        final incident = _incident(state: IncidentState.draft);
        final alarm = _alarm(state: AlarmState.planned);
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [incident],
            scheduledAlarms: [ScheduledAlarm(incident: incident, alarm: alarm)],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.scheduledAlarms, hasLength(1));

        connector.connections.single.emit(
          _alarmDiscardedEvent(
            seq: 11,
            alarmId: alarm.id,
            incidentId: incident.id,
          ),
        );
        async.flushMicrotasks();

        expect(states.last.scheduledAlarms, isEmpty);

        client.dispose();
      });
    });

    test('alarm.triggered removes the matching id from scheduledAlarms', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        final incident = _incident(state: IncidentState.draft);
        final planned = _alarm(state: AlarmState.planned);
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [incident],
            scheduledAlarms: [
              ScheduledAlarm(incident: incident, alarm: planned),
            ],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.scheduledAlarms, hasLength(1));

        final triggered = _alarm(id: planned.id, state: AlarmState.triggered);
        connector.connections.single.emit(
          _alarmTriggeredEvent(
            seq: 11,
            incident: _incident(state: IncidentState.running),
            alarm: triggered,
          ),
        );
        async.flushMicrotasks();

        expect(states.last.scheduledAlarms, isEmpty);
        expect(states.last.alarms, hasLength(1));
        expect(states.last.alarms.single.id, planned.id);

        client.dispose();
      });
    });

    test('incident closed removes its scheduled alarms', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        final incident = _incident(state: IncidentState.draft);
        final alarm = _alarm(state: AlarmState.planned);
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [incident],
            scheduledAlarms: [ScheduledAlarm(incident: incident, alarm: alarm)],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.scheduledAlarms, hasLength(1));

        connector.connections.single.emit({
          'seq': 11,
          'type': 'incident.updated',
          'at': '2026-10-09T08:00:00Z',
          'data': _incident(state: IncidentState.closed).toJson(),
        });
        async.flushMicrotasks();

        expect(states.last.scheduledAlarms, isEmpty);

        client.dispose();
      });
    });

    test('incident discarded removes its scheduled alarms', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        final incident = _incident(state: IncidentState.draft);
        final alarm = _alarm(state: AlarmState.planned);
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            incidents: [incident],
            scheduledAlarms: [ScheduledAlarm(incident: incident, alarm: alarm)],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.scheduledAlarms, hasLength(1));

        connector.connections.single.emit({
          'seq': 11,
          'type': 'incident.updated',
          'at': '2026-10-09T08:00:00Z',
          'data': _incident(state: IncidentState.discarded).toJson(),
        });
        async.flushMicrotasks();

        expect(states.last.scheduledAlarms, isEmpty);

        client.dispose();
      });
    });
  });
}
