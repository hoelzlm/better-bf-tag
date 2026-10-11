import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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

  group('Snapshot.announcements (ADR 0024)', () {
    test('defaults to empty when not set (older servers/tests)', () {
      final snapshot = Snapshot(seq: 1, vehicles: const []);
      expect(snapshot.announcements, isEmpty);
    });

    test('can be set with Durchsagen', () {
      final announcement = Announcement(
        id: 'ann1',
        bfDayId: 'day1',
        text: 'Essen ist fertig',
        createdBy: 'p1',
        createdAt: DateTime.parse('2026-10-11T10:00:00Z'),
      );

      final snapshot = Snapshot(
        seq: 1,
        vehicles: const [],
        announcements: [announcement],
      );

      expect(snapshot.announcements, [announcement]);
    });

    test('copyWith replaces only the given fields', () {
      final announcement = Announcement(
        id: 'ann1',
        bfDayId: 'day1',
        text: 'Essen ist fertig',
        createdBy: 'p1',
        createdAt: DateTime.parse('2026-10-11T10:00:00Z'),
      );
      const original = Snapshot(seq: 1, vehicles: []);

      final updated = original.copyWith(announcements: [announcement]);

      expect(updated.seq, original.seq);
      expect(updated.vehicles, original.vehicles);
      expect(updated.announcements, [announcement]);
    });
  });

  group('Snapshot.programItems (ADR 0025)', () {
    test('defaults to empty when not set (older servers/tests)', () {
      final snapshot = Snapshot(seq: 1, vehicles: const []);
      expect(snapshot.programItems, isEmpty);
    });

    test('can be set with Programmpunkte', () {
      final item = ProgramItem(
        id: 'pi1',
        bfDayId: 'day1',
        title: 'Mittagessen',
        type: ProgramItemType.meal,
        startsAt: DateTime.parse('2026-10-11T11:00:00Z'),
        endsAt: DateTime.parse('2026-10-11T12:00:00Z'),
      );

      final snapshot = Snapshot(
        seq: 1,
        vehicles: const [],
        programItems: [item],
      );

      expect(snapshot.programItems, [item]);
    });

    test('copyWith replaces only the given fields', () {
      final item = ProgramItem(
        id: 'pi1',
        bfDayId: 'day1',
        title: 'Mittagessen',
        type: ProgramItemType.meal,
        startsAt: DateTime.parse('2026-10-11T11:00:00Z'),
        endsAt: DateTime.parse('2026-10-11T12:00:00Z'),
      );
      const original = Snapshot(seq: 1, vehicles: []);

      final updated = original.copyWith(programItems: [item]);

      expect(updated.seq, original.seq);
      expect(updated.vehicles, original.vehicles);
      expect(updated.programItems, [item]);
    });
  });

  group('Snapshot.station (ADR 0026)', () {
    test('defaults to null (no Wache configured)', () {
      const snapshot = Snapshot(seq: 1, vehicles: []);
      expect(snapshot.station, isNull);
    });

    test('can be set to the Wache coordinates', () {
      const snapshot = Snapshot(
        seq: 1,
        vehicles: [],
        station: LatLng(52.5, 13.4),
      );

      expect(snapshot.station, const LatLng(52.5, 13.4));
    });

    test('copyWith replaces only the given fields', () {
      const original = Snapshot(seq: 1, vehicles: []);

      final updated = original.copyWith(station: const LatLng(52.5, 13.4));

      expect(updated.seq, original.seq);
      expect(updated.vehicles, original.vehicles);
      expect(updated.station, const LatLng(52.5, 13.4));
    });
  });
}
