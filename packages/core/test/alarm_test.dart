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
  DateTime? triggeredAt,
  List<String> vehicleIds = const ['v1'],
  List<AlarmRecipient> recipients = const [],
}) {
  return Alarm(
    id: id,
    incidentId: incidentId,
    state: state,
    triggeredAt: triggeredAt,
    vehicleIds: vehicleIds,
    recipients: recipients,
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
}
