import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/screens/my_vehicle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle({
  String id = 'v1',
  String callSign = 'Florian 1',
  String shortName = 'HLF 1',
  String type = 'HLF',
  int status = 2,
  int sortOrder = 1,
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: type,
    status: FmsStatus.fromCode(status),
    statusChangedAt: null,
    sortOrder: sortOrder,
    active: true,
  );
}

Shift _shift() {
  return Shift(
    id: 's1',
    bfDayId: 'day1',
    name: 'Schicht',
    startsAt: DateTime.parse('2026-06-01T08:00:00Z'),
    endsAt: DateTime.parse('2026-06-02T08:00:00Z'),
    crew: const [],
  );
}

MyCrewAssignment _assignment({
  required Vehicle vehicle,
  String function = 'GF',
  List<CrewAssignment> crew = const [],
}) {
  return MyCrewAssignment(
    shift: _shift(),
    vehicle: vehicle,
    function: function,
    crew: crew,
  );
}

class _FakeVehicleAdminRepository implements VehicleAdminRepository {
  final List<(String, int)> setStatusCalls = [];
  Object? errorToThrow;

  @override
  Future<void> setStatus(String id, int status) async {
    setStatusCalls.add((id, status));
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<List<Vehicle>> listAll() async => [];

  @override
  Future<Vehicle> create({
    required String callSign,
    required String shortName,
    required String type,
  }) =>
      throw UnimplementedError();

  @override
  Future<Vehicle> update(
    String id, {
    String? callSign,
    String? shortName,
    String? type,
    bool? active,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> reorder(List<String> vehicleIds) => throw UnimplementedError();
}

Future<void> _pump(
  WidgetTester tester, {
  required List<MyCrewAssignment> assignments,
  _FakeVehicleAdminRepository? repository,
}) async {
  // The screen now has a bottom NavigationBar (T07-3); grow the test
  // surface so the FMS keys stay within the visible/tappable area at
  // the default test window size.
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pairedRealtimeClientProvider.overrideWith((ref) => null),
        myCrewAssignmentsProvider.overrideWithValue(assignments),
        if (repository != null)
          vehicleAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: MyVehicleScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the no-assignment text when there is none',
      (tester) async {
    await _pump(tester, assignments: const []);

    expect(
      find.text('Du bist aktuell keinem Fahrzeug zugeteilt.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'single HLF assignment shows vehicle, function, crew and keys 1-6 only',
    (tester) async {
      final vehicle = _vehicle(type: 'HLF');
      await _pump(
        tester,
        assignments: [
          _assignment(
            vehicle: vehicle,
            function: 'GF',
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
            ],
          ),
        ],
      );

      expect(find.text('Florian 1'), findsOneWidget);
      expect(find.text('Deine Funktion: GF'), findsOneWidget);
      expect(find.text('GF Max M.'), findsOneWidget);
      expect(find.text('MA Erika M.'), findsOneWidget);

      for (var code = 1; code <= 6; code++) {
        expect(find.byKey(Key('fms-$code')), findsOneWidget);
      }
      expect(find.byKey(const Key('fms-7')), findsNothing);
      expect(find.byKey(const Key('fms-8')), findsNothing);
    },
  );

  testWidgets('RTW assignment shows fms-7 and fms-8', (tester) async {
    final vehicle = _vehicle(type: 'RTW');
    await _pump(tester, assignments: [_assignment(vehicle: vehicle)]);

    expect(find.byKey(const Key('fms-7')), findsOneWidget);
    expect(find.byKey(const Key('fms-8')), findsOneWidget);
  });

  testWidgets('tapping fms-3 calls the repository with (vehicleId, 3)',
      (tester) async {
    final vehicle = _vehicle(id: 'v1', type: 'HLF');
    final repository = _FakeVehicleAdminRepository();
    await _pump(
      tester,
      assignments: [_assignment(vehicle: vehicle)],
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('fms-3')));
    await tester.pumpAndSettle();

    expect(repository.setStatusCalls, [('v1', 3)]);
  });

  testWidgets('a failed status change shows an error SnackBar',
      (tester) async {
    final vehicle = _vehicle(id: 'v1', type: 'HLF');
    final repository = _FakeVehicleAdminRepository()
      ..errorToThrow = Exception('boom');
    await _pump(
      tester,
      assignments: [_assignment(vehicle: vehicle)],
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('fms-3')));
    await tester.pumpAndSettle();

    expect(
      find.text('Status konnte nicht gesetzt werden.'),
      findsOneWidget,
    );
  });

  testWidgets('double assignment shows the vehicle switcher', (tester) async {
    final v1 = _vehicle(
      id: 'v1',
      callSign: 'Florian 1',
      shortName: 'HLF 1',
      sortOrder: 1,
    );
    final v2 = _vehicle(
      id: 'v2',
      callSign: 'Florian 2',
      shortName: 'RTW 1',
      type: 'RTW',
      sortOrder: 2,
    );
    await _pump(
      tester,
      assignments: [
        _assignment(vehicle: v1),
        _assignment(vehicle: v2),
      ],
    );

    expect(find.byKey(const Key('vehicle-switcher')), findsOneWidget);
    expect(find.text('HLF 1'), findsOneWidget);
    expect(find.text('RTW 1'), findsOneWidget);
    expect(find.text('Florian 1'), findsOneWidget);

    await tester.tap(find.text('RTW 1'));
    await tester.pumpAndSettle();

    expect(find.text('Florian 2'), findsOneWidget);
    expect(find.text('Florian 1'), findsNothing);
  });
}
