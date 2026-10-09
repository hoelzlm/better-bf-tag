import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/shifts_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BfDay _bfDay({
  String id = 'd1',
  String name = 'BF-Tag 2026',
  BfDayState state = BfDayState.running,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  return BfDay(
    id: id,
    name: name,
    startsAt: startsAt ?? DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: endsAt ?? DateTime.now().add(const Duration(hours: 23)),
    state: state,
  );
}

Shift _shift({
  String id = 's1',
  String bfDayId = 'd1',
  String name = 'Schicht 1',
  DateTime? startsAt,
  DateTime? endsAt,
  List<CrewAssignment> crew = const [],
}) {
  return Shift(
    id: id,
    bfDayId: bfDayId,
    name: name,
    startsAt: startsAt ?? DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: endsAt ?? DateTime.now().add(const Duration(hours: 23)),
    crew: crew,
  );
}

Vehicle _vehicle({
  String id = 'v1',
  String shortName = 'HLF 1',
  int sortOrder = 1,
}) {
  return Vehicle(
    id: id,
    callSign: 'Florian $shortName',
    shortName: shortName,
    type: 'HLF',
    status: FmsStatus.s2,
    statusChangedAt: null,
    sortOrder: sortOrder,
    active: true,
  );
}

Participant _participant({
  String personId = 'p1',
  String displayName = 'Max Mustermann',
}) {
  return Participant(
    personId: personId,
    displayName: displayName,
    personType: PersonType.youth,
    permission: Permission.crew,
    fireDepartmentId: 'fd1',
  );
}

class _FakeBfDayAdminRepository implements BfDayAdminRepository {
  _FakeBfDayAdminRepository({
    List<BfDay>? days,
    Map<String, List<Participant>>? participants,
  })  : days = days ?? [],
        participants = participants ?? {};

  List<BfDay> days;
  Map<String, List<Participant>> participants;

  @override
  Future<List<BfDay>> list() async => List.of(days);

  @override
  Future<BfDay> create({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> start(String id) => throw UnimplementedError();

  @override
  Future<BfDay> end(String id) => throw UnimplementedError();

  @override
  Future<List<Participant>> listParticipants(String day) async =>
      List.of(participants[day] ?? const []);

  @override
  Future<void> setParticipants(String day, List<String> personIds) =>
      throw UnimplementedError();

  @override
  Future<AnonymizationSummary> anonymizationPreview(String bfDayId) =>
      throw UnimplementedError();

  @override
  Future<BfDay> anonymize(String bfDayId) => throw UnimplementedError();
}

class _FakeShiftRepository implements ShiftRepository {
  _FakeShiftRepository({Map<String, List<Shift>>? shiftsByDay})
      : shiftsByDay = shiftsByDay ?? {};

  Map<String, List<Shift>> shiftsByDay;
  final List<(String, List<CrewAssignmentInput>)> setCrewCalls = [];
  final List<(String, String, DateTime, DateTime)> createCalls = [];
  Object? setCrewError;

  @override
  Future<List<Shift>> listShifts(String day) async =>
      List.of(shiftsByDay[day] ?? const []);

  @override
  Future<Shift> createShift(
    String day, {
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    createCalls.add((day, name, startsAt, endsAt));
    final created = _shift(
      id: 'new-shift',
      bfDayId: day,
      name: name,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    shiftsByDay[day] = [...(shiftsByDay[day] ?? []), created];
    return created;
  }

  @override
  Future<Shift> updateShift(
    String day,
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteShift(String day, String id) async {}

  @override
  Future<Shift> setCrew(
    String shiftId,
    List<CrewAssignmentInput> assignments,
  ) async {
    setCrewCalls.add((shiftId, assignments));
    final error = setCrewError;
    if (error != null) {
      throw error;
    }
    Shift? found;
    String? foundDay;
    for (final entry in shiftsByDay.entries) {
      for (final s in entry.value) {
        if (s.id == shiftId) {
          found = s;
          foundDay = entry.key;
        }
      }
    }
    if (found == null || foundDay == null) {
      throw StateError('shift not found: $shiftId');
    }
    final updated = found.copyWith(
      crew: [
        for (final a in assignments)
          CrewAssignment(
            vehicleId: a.vehicleId,
            personId: a.personId,
            displayName: 'Person ${a.personId}',
            function: a.function,
          ),
      ],
    );
    shiftsByDay[foundDay] = [
      for (final s in shiftsByDay[foundDay]!)
        if (s.id == shiftId) updated else s,
    ];
    return updated;
  }
}

Future<(
  _FakeBfDayAdminRepository,
  _FakeShiftRepository,
)> _pump(
  WidgetTester tester, {
  required List<BfDay> days,
  Map<String, List<Shift>>? shifts,
  Map<String, List<Participant>>? participants,
  List<Vehicle>? vehicles,
}) async {
  final bfDayRepository = _FakeBfDayAdminRepository(
    days: days,
    participants: participants,
  );
  final shiftRepository = _FakeShiftRepository(shiftsByDay: shifts ?? {});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bfDayAdminRepositoryProvider.overrideWithValue(bfDayRepository),
        shiftRepositoryProvider.overrideWithValue(shiftRepository),
        vehiclesProvider.overrideWith((ref) => Stream.value(vehicles ?? const [])),
        shiftsProvider.overrideWith((ref) => Stream.value(const [])),
        bfDayProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: const MaterialApp(home: ShiftsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return (bfDayRepository, shiftRepository);
}

void main() {
  testWidgets('renders shifts as tabs and crew per vehicle', (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      shifts: {
        'd1': [
          _shift(
            crew: const [
              CrewAssignment(
                vehicleId: 'v1',
                personId: 'p1',
                displayName: 'Max Mustermann',
                function: 'GF',
              ),
            ],
          ),
        ],
      },
      participants: {
        'd1': [_participant()],
      },
      vehicles: [_vehicle()],
    );

    expect(find.text('Schicht 1 (aktuell)'), findsOneWidget);
    expect(find.text('GF Max Mustermann'), findsOneWidget);
    expect(find.text('HLF 1'), findsOneWidget);
  });

  testWidgets(
    'dragging a participant onto a vehicle opens the function dialog and '
    'calls setCrew with the full expected list',
    (tester) async {
      final (_, shiftRepository) = await _pump(
        tester,
        days: [_bfDay()],
        shifts: {
          'd1': [_shift()],
        },
        participants: {
          'd1': [_participant(personId: 'p1', displayName: 'Max Mustermann')],
        },
        vehicles: [_vehicle(id: 'v1', shortName: 'HLF 1')],
      );

      final draggable = find.byKey(const Key('participant-draggable-p1'));
      final target = find.byKey(const Key('vehicle-dropzone-v1'));
      final from = tester.getCenter(draggable);
      final to = tester.getCenter(target);
      await tester.timedDrag(draggable, to - from, const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Funktion wählen'), findsOneWidget);

      await tester.tap(find.byKey(const Key('function-btn-GF')));
      await tester.pumpAndSettle();

      expect(shiftRepository.setCrewCalls, hasLength(1));
      final (shiftId, assignments) = shiftRepository.setCrewCalls.single;
      expect(shiftId, 's1');
      expect(assignments, hasLength(1));
      expect(assignments.single.vehicleId, 'v1');
      expect(assignments.single.personId, 'p1');
      expect(assignments.single.function, 'GF');
    },
  );

  testWidgets('a person on two vehicles shows the double-booking marker',
      (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      shifts: {
        'd1': [
          _shift(
            crew: const [
              CrewAssignment(
                vehicleId: 'v1',
                personId: 'p1',
                displayName: 'Max Mustermann',
                function: 'GF',
              ),
              CrewAssignment(
                vehicleId: 'v2',
                personId: 'p1',
                displayName: 'Max Mustermann',
                function: 'MA',
              ),
            ],
          ),
        ],
      },
      participants: {
        'd1': [_participant()],
      },
      vehicles: [
        _vehicle(id: 'v1', shortName: 'HLF 1', sortOrder: 1),
        _vehicle(id: 'v2', shortName: 'HLF 2', sortOrder: 2),
      ],
    );

    // Two crew chips (one per vehicle) plus the participant chip.
    expect(find.byIcon(Icons.warning), findsNWidgets(3));
  });

  testWidgets('removing an assignment calls setCrew with the filtered list',
      (tester) async {
    final (_, shiftRepository) = await _pump(
      tester,
      days: [_bfDay()],
      shifts: {
        'd1': [
          _shift(
            crew: const [
              CrewAssignment(
                vehicleId: 'v1',
                personId: 'p1',
                displayName: 'Max Mustermann',
                function: 'GF',
              ),
            ],
          ),
        ],
      },
      participants: {
        'd1': [_participant()],
      },
      vehicles: [_vehicle()],
    );

    await tester.tap(find.byKey(const Key('crew-menu-v1-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('entfernen'));
    await tester.pumpAndSettle();

    expect(shiftRepository.setCrewCalls, hasLength(1));
    final (shiftId, assignments) = shiftRepository.setCrewCalls.single;
    expect(shiftId, 's1');
    expect(assignments, isEmpty);
  });

  testWidgets('create shift dialog calls createShift', (tester) async {
    final (_, shiftRepository) = await _pump(
      tester,
      days: [_bfDay()],
      shifts: {
        'd1': [_shift()],
      },
      participants: {
        'd1': [_participant()],
      },
      vehicles: [_vehicle()],
    );

    await tester.tap(find.byKey(const Key('create-shift')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('shift-form-name')),
      'Nachtschicht',
    );
    await tester.tap(find.byKey(const Key('shift-form-submit')));
    await tester.pumpAndSettle();

    expect(shiftRepository.createCalls, hasLength(1));
    expect(shiftRepository.createCalls.single.$2, 'Nachtschicht');
  });

  testWidgets('a 409 error from setCrew shows a SnackBar', (tester) async {
    final bfDayRepository = _FakeBfDayAdminRepository(
      days: [_bfDay()],
      participants: {'d1': [_participant()]},
    );
    final shiftRepository = _FakeShiftRepository(
      shiftsByDay: {
        'd1': [_shift()],
      },
    );
    shiftRepository.setCrewError = DioException(
      requestOptions: RequestOptions(path: '/shifts/s1/crew'),
      response: Response(
        requestOptions: RequestOptions(path: '/shifts/s1/crew'),
        statusCode: 409,
        data: {
          'error': {
            'code': 'person_not_participant',
            'message': 'Die Person nimmt nicht am BF-Tag teil.',
          },
        },
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bfDayAdminRepositoryProvider.overrideWithValue(bfDayRepository),
          shiftRepositoryProvider.overrideWithValue(shiftRepository),
          vehiclesProvider.overrideWith((ref) => Stream.value([_vehicle()])),
          shiftsProvider.overrideWith((ref) => Stream.value(const [])),
          bfDayProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: ShiftsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final draggable = find.byKey(const Key('participant-draggable-p1'));
    final target = find.byKey(const Key('vehicle-dropzone-v1'));
    final from = tester.getCenter(draggable);
    final to = tester.getCenter(target);
    await tester.timedDrag(draggable, to - from, const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('function-btn-GF')));
    await tester.pumpAndSettle();

    expect(find.text('Die Person nimmt nicht am BF-Tag teil.'), findsOneWidget);
  });
}
