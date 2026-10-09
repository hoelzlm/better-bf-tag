import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Snapshot.scheduledAlarms (ADR 0022)', () {
    test('defaults to empty when not set (older servers/tests)', () {
      final snapshot = Snapshot(seq: 1, vehicles: const []);
      expect(snapshot.scheduledAlarms, isEmpty);
    });

    test('can be set with planned/missed Alarmierungen', () {
      final incident = Incident(
        id: 'i1',
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
      final alarm = Alarm(
        id: 'a1',
        incidentId: 'i1',
        state: AlarmState.planned,
        scheduledAt: DateTime.parse('2026-10-09T10:08:00Z'),
        vehicleIds: const ['v1'],
        recipients: const [],
      );

      final snapshot = Snapshot(
        seq: 1,
        vehicles: const [],
        scheduledAlarms: [ScheduledAlarm(incident: incident, alarm: alarm)],
      );

      expect(snapshot.scheduledAlarms, hasLength(1));
      expect(snapshot.scheduledAlarms.single.alarm.id, 'a1');
      expect(snapshot.scheduledAlarms.single.incident.id, 'i1');
    });
  });
}
