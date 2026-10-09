import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle(
  String id, {
  String type = 'HLF',
  int sortOrder = 1,
  bool active = true,
}) {
  return Vehicle(
    id: id,
    callSign: 'Florian $id',
    shortName: 'HLF $id',
    type: type,
    status: FmsStatus.s2,
    statusChangedAt: null,
    sortOrder: sortOrder,
    active: active,
  );
}

Shift _shift(
  String id,
  String startsAt,
  String endsAt, {
  List<CrewAssignment> crew = const [],
}) {
  return Shift(
    id: id,
    bfDayId: 'day',
    name: id,
    startsAt: DateTime.parse(startsAt),
    endsAt: DateTime.parse(endsAt),
    crew: crew,
  );
}

void main() {
  final now = DateTime.parse('2026-06-01T12:00:00Z');

  group('myCrewAssignments', () {
    test('returns nothing without a current shift', () {
      final result = myCrewAssignments(
        shifts: const [],
        vehicles: [_vehicle('v1')],
        personId: 'p1',
        now: now,
      );
      expect(result, isEmpty);
    });

    test('returns nothing when the person has no crew assignment', () {
      final shift = _shift(
        's1',
        '2026-06-01T08:00:00Z',
        '2026-06-02T08:00:00Z',
        crew: [
          const CrewAssignment(
            vehicleId: 'v1',
            personId: 'other',
            displayName: 'Other',
            function: 'GF',
          ),
        ],
      );
      final result = myCrewAssignments(
        shifts: [shift],
        vehicles: [_vehicle('v1')],
        personId: 'p1',
        now: now,
      );
      expect(result, isEmpty);
    });

    test('single assignment includes the shift, vehicle, function and crew',
        () {
      final shift = _shift(
        's1',
        '2026-06-01T08:00:00Z',
        '2026-06-02T08:00:00Z',
        crew: const [
          CrewAssignment(
            vehicleId: 'v1',
            personId: 'p1',
            displayName: 'Max M.',
            function: 'GF',
          ),
          CrewAssignment(
            vehicleId: 'v1',
            personId: 'p2',
            displayName: 'Erika M.',
            function: 'MA',
          ),
          CrewAssignment(
            vehicleId: 'v2',
            personId: 'p3',
            displayName: 'Other',
            function: 'GF',
          ),
        ],
      );
      final result = myCrewAssignments(
        shifts: [shift],
        vehicles: [_vehicle('v1'), _vehicle('v2', sortOrder: 2)],
        personId: 'p1',
        now: now,
      );

      expect(result, hasLength(1));
      expect(result.single.shift.id, 's1');
      expect(result.single.vehicle.id, 'v1');
      expect(result.single.function, 'GF');
      expect(result.single.crew, hasLength(2));
      expect(
        result.single.crew.map((c) => c.displayName),
        containsAll(['Max M.', 'Erika M.']),
      );
    });

    test('double assignment returns one entry per vehicle, sorted by '
        'sort_order', () {
      final shift = _shift(
        's1',
        '2026-06-01T08:00:00Z',
        '2026-06-02T08:00:00Z',
        crew: const [
          CrewAssignment(
            vehicleId: 'v2',
            personId: 'p1',
            displayName: 'Max M.',
            function: 'MA',
          ),
          CrewAssignment(
            vehicleId: 'v1',
            personId: 'p1',
            displayName: 'Max M.',
            function: 'GF',
          ),
        ],
      );
      final result = myCrewAssignments(
        shifts: [shift],
        vehicles: [_vehicle('v2', sortOrder: 2), _vehicle('v1', sortOrder: 1)],
        personId: 'p1',
        now: now,
      );

      expect(result.map((a) => a.vehicle.id).toList(), ['v1', 'v2']);
    });

    test('skips a vehicle that is not in the (active) vehicle list', () {
      final shift = _shift(
        's1',
        '2026-06-01T08:00:00Z',
        '2026-06-02T08:00:00Z',
        crew: const [
          CrewAssignment(
            vehicleId: 'inactive',
            personId: 'p1',
            displayName: 'Max M.',
            function: 'GF',
          ),
        ],
      );
      final result = myCrewAssignments(
        shifts: [shift],
        vehicles: const [],
        personId: 'p1',
        now: now,
      );
      expect(result, isEmpty);
    });

    test('after the shift has ended, returns nothing', () {
      final shift = _shift(
        's1',
        '2026-06-01T08:00:00Z',
        '2026-06-01T12:00:00Z',
        crew: const [
          CrewAssignment(
            vehicleId: 'v1',
            personId: 'p1',
            displayName: 'Max M.',
            function: 'GF',
          ),
        ],
      );
      final result = myCrewAssignments(
        shifts: [shift],
        vehicles: [_vehicle('v1')],
        personId: 'p1',
        now: DateTime.parse('2026-06-01T12:00:00Z'),
      );
      expect(result, isEmpty);
    });

    test('an overlapping, non-current shift is not used', () {
      final defaultShift = _shift(
        'default',
        '2026-06-01T00:00:00Z',
        '2026-06-02T00:00:00Z',
        crew: const [
          CrewAssignment(
            vehicleId: 'v1',
            personId: 'p1',
            displayName: 'Max M.',
            function: 'GF',
          ),
        ],
      );
      final nightShift = _shift(
        'night',
        '2026-06-01T22:00:00Z',
        '2026-06-02T06:00:00Z',
        crew: const [],
      );
      final result = myCrewAssignments(
        shifts: [defaultShift, nightShift],
        vehicles: [_vehicle('v1')],
        personId: 'p1',
        now: DateTime.parse('2026-06-01T23:00:00Z'),
      );
      // The night shift is current and has no crew for p1.
      expect(result, isEmpty);
    });
  });
}
