import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

AlarmRecipient _recipient({
  String personId = 'p1',
  String displayName = 'Max Muster',
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

Alarm _alarm({
  String id = 'a1',
  String incidentId = 'i1',
  AlarmState state = AlarmState.triggered,
  DateTime? scheduledAt,
  DateTime? triggeredAt,
  List<String> vehicleIds = const ['v1'],
  List<AlarmRecipient> recipients = const [],
  String? relativeToAlarmId,
  int? offsetMinutes,
}) {
  return Alarm(
    id: id,
    incidentId: incidentId,
    state: state,
    scheduledAt: scheduledAt,
    triggeredAt: triggeredAt,
    vehicleIds: vehicleIds,
    recipients: recipients,
    relativeToAlarmId: relativeToAlarmId,
    offsetMinutes: offsetMinutes,
  );
}

void main() {
  group('AckState', () {
    test('acknowledged when acknowledgedAt is set', () {
      final recipient = _recipient(
        acknowledgedAt: DateTime.parse('2026-10-09T10:00:00Z'),
        hasDevice: true,
      );
      expect(recipient.ackState, AckState.acknowledged);
    });

    test('pending when not acknowledged but has a device', () {
      final recipient = _recipient(hasDevice: true);
      expect(recipient.ackState, AckState.pending);
    });

    test('noDevice when not acknowledged and has no device', () {
      final recipient = _recipient(hasDevice: false);
      expect(recipient.ackState, AckState.noDevice);
    });

    test('acknowledged wins even without a device (acknowledged late)', () {
      final recipient = _recipient(
        hasDevice: false,
        acknowledgedAt: DateTime.parse('2026-10-09T10:00:00Z'),
      );
      expect(recipient.ackState, AckState.acknowledged);
    });
  });

  group('Alarm.summary', () {
    test('counts each AckState; noDevice never counts as pending', () {
      final alarm = _alarm(
        recipients: [
          _recipient(
            personId: 'p1',
            hasDevice: true,
            acknowledgedAt: DateTime.parse('2026-10-09T10:00:00Z'),
          ),
          _recipient(personId: 'p2', hasDevice: true),
          _recipient(personId: 'p3', hasDevice: true),
          _recipient(personId: 'p4', hasDevice: false),
        ],
      );

      final summary = alarm.summary;
      expect(summary.acknowledged, 1);
      expect(summary.pending, 2);
      expect(summary.noDevice, 1);
    });

    test('empty recipients -> all zero', () {
      final alarm = _alarm(recipients: const []);
      final summary = alarm.summary;
      expect(summary.acknowledged, 0);
      expect(summary.pending, 0);
      expect(summary.noDevice, 0);
    });
  });

  group('Alarm.fromJson / toJson roundtrip shape', () {
    test('parses id/incident_id/state/vehicle_ids/recipients', () {
      final json = {
        'id': 'a1',
        'incident_id': 'i1',
        'state': 'triggered',
        'scheduled_at': null,
        'triggered_at': '2026-10-09T10:00:00Z',
        'vehicle_ids': ['v1', 'v2'],
        'recipients': [
          {
            'person_id': 'p1',
            'display_name': 'Max Muster',
            'vehicle_id': 'v1',
            'function': 'GF',
            'has_device': true,
            'acknowledged_at': null,
          },
        ],
      };

      final alarm = Alarm.fromJson(json);
      expect(alarm.id, 'a1');
      expect(alarm.incidentId, 'i1');
      expect(alarm.state, AlarmState.triggered);
      expect(alarm.triggeredAt, DateTime.parse('2026-10-09T10:00:00Z'));
      expect(alarm.vehicleIds, ['v1', 'v2']);
      expect(alarm.recipients, hasLength(1));
      expect(alarm.recipients.single.displayName, 'Max Muster');
      expect(alarm.recipients.single.ackState, AckState.pending);
      expect(alarm.pushDelivered, 0);
      expect(alarm.pushRejected, 0);
    });

    test('parses push_delivered/push_rejected when present', () {
      final json = {
        'id': 'a1',
        'incident_id': 'i1',
        'state': 'triggered',
        'scheduled_at': null,
        'triggered_at': '2026-10-09T10:00:00Z',
        'vehicle_ids': ['v1'],
        'recipients': const <Map<String, dynamic>>[],
        'push_delivered': 3,
        'push_rejected': 1,
      };

      final alarm = Alarm.fromJson(json);
      expect(alarm.pushDelivered, 3);
      expect(alarm.pushRejected, 1);
    });
  });

  group('doubleCrewedIn', () {
    Shift shiftWith(List<CrewAssignment> crew) {
      return Shift(
        id: 'shift1',
        bfDayId: 'day1',
        name: 'Tagschicht',
        startsAt: DateTime.parse('2026-10-09T08:00:00Z'),
        endsAt: DateTime.parse('2026-10-09T20:00:00Z'),
        crew: crew,
      );
    }

    test('null shift -> no warning', () {
      expect(doubleCrewedIn(null, ['v1', 'v2']), isEmpty);
    });

    test('person on two selected vehicles is reported once', () {
      final shift = shiftWith([
        const CrewAssignment(
          vehicleId: 'v1',
          personId: 'p1',
          displayName: 'Max Muster',
          function: 'GF',
        ),
        const CrewAssignment(
          vehicleId: 'v2',
          personId: 'p1',
          displayName: 'Max Muster',
          function: 'MA',
        ),
        const CrewAssignment(
          vehicleId: 'v1',
          personId: 'p2',
          displayName: 'Erika Musterfrau',
          function: 'MA',
        ),
      ]);

      final result = doubleCrewedIn(shift, ['v1', 'v2']);
      expect(result, hasLength(1));
      expect(result.single.personId, 'p1');
      expect(result.single.vehicleIds, ['v1', 'v2']);
    });

    test('person on an unselected second vehicle is not reported', () {
      final shift = shiftWith([
        const CrewAssignment(
          vehicleId: 'v1',
          personId: 'p1',
          displayName: 'Max Muster',
          function: 'GF',
        ),
        const CrewAssignment(
          vehicleId: 'v3',
          personId: 'p1',
          displayName: 'Max Muster',
          function: 'MA',
        ),
      ]);

      expect(doubleCrewedIn(shift, ['v1', 'v2']), isEmpty);
    });

    test('empty vehicleIds -> no warning', () {
      final shift = shiftWith([
        const CrewAssignment(
          vehicleId: 'v1',
          personId: 'p1',
          displayName: 'Max Muster',
          function: 'GF',
        ),
      ]);
      expect(doubleCrewedIn(shift, const []), isEmpty);
    });
  });

  group('triggeredAlarmsInOrder / alarmSequenceLabel', () {
    test('sorts triggered alarms by triggeredAt, then id', () {
      final a1 = _alarm(
        id: 'a2',
        triggeredAt: DateTime.parse('2026-10-09T10:05:00Z'),
      );
      final a2 = _alarm(
        id: 'a1',
        triggeredAt: DateTime.parse('2026-10-09T10:05:00Z'),
      );
      final a3 = _alarm(
        id: 'a3',
        triggeredAt: DateTime.parse('2026-10-09T10:00:00Z'),
      );

      final ordered = triggeredAlarmsInOrder([a1, a2, a3]);
      expect(ordered.map((a) => a.id).toList(), ['a3', 'a1', 'a2']);
    });

    test('excludes non-triggered alarms', () {
      final planned = _alarm(id: 'a1', state: AlarmState.planned);
      final triggered = _alarm(
        id: 'a2',
        triggeredAt: DateTime.parse('2026-10-09T10:00:00Z'),
      );

      expect(
        triggeredAlarmsInOrder([planned, triggered]).map((a) => a.id),
        ['a2'],
      );
    });

    test('alarmSequenceLabel: Erstalarm, 1./2. Nachalarmierung', () {
      final erst = _alarm(
        id: 'a1',
        triggeredAt: DateTime.parse('2026-10-09T10:00:00Z'),
      );
      final nach1 = _alarm(
        id: 'a2',
        triggeredAt: DateTime.parse('2026-10-09T10:05:00Z'),
      );
      final nach2 = _alarm(
        id: 'a3',
        triggeredAt: DateTime.parse('2026-10-09T10:10:00Z'),
      );
      final alarms = [erst, nach1, nach2];

      expect(alarmSequenceLabel(erst, alarms), 'Erstalarm');
      expect(alarmSequenceLabel(nach1, alarms), '1. Nachalarmierung');
      expect(alarmSequenceLabel(nach2, alarms), '2. Nachalarmierung');
    });

    test('alarmSequenceLabel falls back to "Alarmierung" for a planned alarm', () {
      final planned = _alarm(id: 'a1', state: AlarmState.planned);
      expect(alarmSequenceLabel(planned, [planned]), 'Alarmierung');
    });
  });

  group('Alarm.fromJson relative_to_alarm_id / offset_minutes (ADR 0022)', () {
    test('absent -> null (older servers/tests)', () {
      final json = {
        'id': 'a1',
        'incident_id': 'i1',
        'state': 'triggered',
        'scheduled_at': null,
        'triggered_at': '2026-10-09T10:00:00Z',
        'vehicle_ids': ['v1'],
        'recipients': const <Map<String, dynamic>>[],
      };
      final alarm = Alarm.fromJson(json);
      expect(alarm.relativeToAlarmId, isNull);
      expect(alarm.offsetMinutes, isNull);
    });

    test('present -> parsed', () {
      final json = {
        'id': 'a2',
        'incident_id': 'i1',
        'state': 'planned',
        'scheduled_at': '2026-10-09T10:08:00Z',
        'triggered_at': null,
        'vehicle_ids': ['v2'],
        'recipients': const <Map<String, dynamic>>[],
        'relative_to_alarm_id': 'a1',
        'offset_minutes': 8,
      };
      final alarm = Alarm.fromJson(json);
      expect(alarm.relativeToAlarmId, 'a1');
      expect(alarm.offsetMinutes, 8);
    });
  });

  group('Alarm.isPlanned / isMissed (ADR 0022)', () {
    test('isPlanned true only for state planned', () {
      expect(_alarm(state: AlarmState.planned).isPlanned, isTrue);
      expect(_alarm(state: AlarmState.triggered).isPlanned, isFalse);
      expect(_alarm(state: AlarmState.missed).isPlanned, isFalse);
    });

    test('isMissed true only for state missed', () {
      expect(_alarm(state: AlarmState.missed).isMissed, isTrue);
      expect(_alarm(state: AlarmState.planned).isMissed, isFalse);
      expect(_alarm(state: AlarmState.triggered).isMissed, isFalse);
    });
  });

  group('countdown (ADR 0022)', () {
    test('null without scheduledAt', () {
      final alarm = _alarm(state: AlarmState.triggered, scheduledAt: null);
      expect(countdown(alarm, DateTime.parse('2026-10-09T10:00:00Z')), isNull);
    });

    test('positive before scheduledAt', () {
      final alarm = _alarm(
        state: AlarmState.planned,
        scheduledAt: DateTime.parse('2026-10-09T10:08:00Z'),
      );
      expect(
        countdown(alarm, DateTime.parse('2026-10-09T10:00:00Z')),
        const Duration(minutes: 8),
      );
    });

    test('negative after scheduledAt has passed', () {
      final alarm = _alarm(
        state: AlarmState.missed,
        scheduledAt: DateTime.parse('2026-10-09T10:00:00Z'),
      );
      expect(
        countdown(alarm, DateTime.parse('2026-10-09T10:15:00Z')),
        const Duration(minutes: -15),
      );
    });
  });

  group('scheduledAlarmTimeLabel (ADR 0022)', () {
    test('relative Alarmierung -> "+N min nach Erstalarm"', () {
      final alarm = _alarm(
        state: AlarmState.planned,
        scheduledAt: DateTime.parse('2026-10-09T10:08:00Z'),
        relativeToAlarmId: 'a1',
        offsetMinutes: 8,
      );
      expect(scheduledAlarmTimeLabel(alarm), '+8 min nach Erstalarm');
    });

    test('absolute Alarmierung -> HH:MM', () {
      final alarm = _alarm(
        state: AlarmState.planned,
        scheduledAt: DateTime.parse('2026-10-09T10:08:00Z').toUtc(),
      );
      expect(
        scheduledAlarmTimeLabel(alarm),
        '${DateTime.parse('2026-10-09T10:08:00Z').toLocal().hour.toString().padLeft(2, '0')}:'
        '${DateTime.parse('2026-10-09T10:08:00Z').toLocal().minute.toString().padLeft(2, '0')}',
      );
    });

    test('no scheduledAt -> empty string', () {
      final alarm = _alarm(state: AlarmState.triggered, scheduledAt: null);
      expect(scheduledAlarmTimeLabel(alarm), '');
    });
  });

  group('ScheduledAlarm (ADR 0022)', () {
    Incident incident({String id = 'i1'}) {
      return Incident(
        id: id,
        bfDayId: 'day1',
        number: 1,
        keyword: 'Verkehrsunfall',
        address: 'Hauptstraße 1',
        report: 'PKW gegen Baum',
        script: null,
        state: IncidentState.draft,
        createdAt: DateTime.parse('2026-10-09T08:00:00Z'),
        updatedAt: DateTime.parse('2026-10-09T08:00:00Z'),
      );
    }

    test('equality is value-based', () {
      final a = ScheduledAlarm(
        incident: incident(),
        alarm: _alarm(state: AlarmState.planned),
      );
      final b = ScheduledAlarm(
        incident: incident(),
        alarm: _alarm(state: AlarmState.planned),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
