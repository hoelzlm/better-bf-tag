import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/widgets/vehicle_status_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle({
  String id = 'v1',
  String callSign = 'Florian 1',
  String shortName = 'HLF 1',
  int status = 2,
  int sortOrder = 1,
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: 'HLF',
    status: FmsStatus.fromCode(status),
    statusChangedAt: null,
    sortOrder: sortOrder,
    active: true,
  );
}

/// Records every [setStatus] call instead of hitting the network.
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
  required Stream<List<Vehicle>> vehicles,
  required Permission permission,
  _FakeVehicleAdminRepository? repository,
  Stream<ConnectionStatus>? connection,
}) async {
  final person = Person(
    id: 'p1',
    displayName: 'Max Mustermann',
    personType: PersonType.supervisor,
    permission: permission,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehiclesProvider.overrideWith((ref) => vehicles),
        realtimeConnectionProvider.overrideWith(
          (ref) => connection ?? Stream.value(ConnectionStatus.live),
        ),
        sessionControllerProvider.overrideWith(
          () => _FixedSessionController(SessionSignedIn(person, 'token')),
        ),
        if (repository != null)
          vehicleAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: Scaffold(body: const VehicleStatusBar()),
      ),
    ),
  );
  await tester.pump();
}

class _FixedSessionController extends SessionController {
  _FixedSessionController(this._initial);

  final SessionState _initial;

  @override
  SessionState build() => _initial;
}

void main() {
  testWidgets('renders a tile per active vehicle from the fake stream',
      (tester) async {
    await _pump(
      tester,
      vehicles: Stream.value([
        _vehicle(id: 'v1', shortName: 'HLF 1', status: 2),
        _vehicle(id: 'v2', shortName: 'DLK', status: 4, sortOrder: 2),
      ]),
      permission: Permission.crew,
    );

    expect(find.byKey(const Key('vehicle-tile-v1')), findsOneWidget);
    expect(find.byKey(const Key('vehicle-tile-v2')), findsOneWidget);
    expect(find.text('HLF 1'), findsOneWidget);
    expect(find.text('DLK'), findsOneWidget);
  });

  testWidgets('re-renders when the vehicles stream emits a new state',
      (tester) async {
    final controller = StreamController<List<Vehicle>>();
    addTearDown(controller.close);
    await _pump(
      tester,
      vehicles: controller.stream,
      permission: Permission.crew,
    );

    controller.add([_vehicle(status: 2)]);
    await tester.pump();
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    controller.add([_vehicle(status: 4)]);
    await tester.pump();
    await tester.pump();
    expect(find.text('2'), findsNothing);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('shows the live connection indicator', (tester) async {
    await _pump(
      tester,
      vehicles: Stream.value([_vehicle()]),
      permission: Permission.crew,
      connection: Stream.value(ConnectionStatus.live),
    );

    expect(find.text('live'), findsOneWidget);
  });

  testWidgets('shows the reconnecting indicator', (tester) async {
    await _pump(
      tester,
      vehicles: Stream.value([_vehicle()]),
      permission: Permission.crew,
      connection: Stream.value(ConnectionStatus.reconnecting),
    );

    expect(find.text('verbinde neu…'), findsOneWidget);
  });

  testWidgets(
    'dispatch can open the status picker and PUTs the chosen status',
    (tester) async {
      final repository = _FakeVehicleAdminRepository();
      await _pump(
        tester,
        vehicles: Stream.value([_vehicle(id: 'v1', status: 2)]),
        permission: Permission.dispatch,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('vehicle-tile-v1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('status-option-3')), findsOneWidget);

      await tester.tap(find.byKey(const Key('status-option-3')));
      await tester.pumpAndSettle();

      expect(repository.setStatusCalls, [('v1', 3)]);
    },
  );

  testWidgets('admin can also open the status picker', (tester) async {
    final repository = _FakeVehicleAdminRepository();
    await _pump(
      tester,
      vehicles: Stream.value([_vehicle(id: 'v1', status: 2)]),
      permission: Permission.admin,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('vehicle-tile-v1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('status-option-5')), findsOneWidget);
  });

  testWidgets(
    'the status picker hides 7/8 for a non-RTW/KTW vehicle',
    (tester) async {
      final repository = _FakeVehicleAdminRepository();
      await _pump(
        tester,
        vehicles: Stream.value([_vehicle(id: 'v1', status: 2)]),
        permission: Permission.dispatch,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('vehicle-tile-v1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('status-option-6')), findsOneWidget);
      expect(find.byKey(const Key('status-option-7')), findsNothing);
      expect(find.byKey(const Key('status-option-8')), findsNothing);
    },
  );

  testWidgets(
    'the status picker offers 7/8 for a RTW vehicle',
    (tester) async {
      final repository = _FakeVehicleAdminRepository();
      await _pump(
        tester,
        vehicles: Stream.value([
          Vehicle(
            id: 'v1',
            callSign: 'Rettung 1',
            shortName: 'RTW 1',
            type: 'RTW',
            status: FmsStatus.fromCode(2),
            statusChangedAt: null,
            sortOrder: 1,
            active: true,
          ),
        ]),
        permission: Permission.dispatch,
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('vehicle-tile-v1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('status-option-7')), findsOneWidget);
      expect(find.byKey(const Key('status-option-8')), findsOneWidget);
    },
  );

  testWidgets('crew cannot open the status picker', (tester) async {
    final repository = _FakeVehicleAdminRepository();
    await _pump(
      tester,
      vehicles: Stream.value([_vehicle(id: 'v1', status: 2)]),
      permission: Permission.crew,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('vehicle-tile-v1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('status-option-3')), findsNothing);
    expect(repository.setStatusCalls, isEmpty);
  });

  testWidgets('preparation cannot open the status picker', (tester) async {
    final repository = _FakeVehicleAdminRepository();
    await _pump(
      tester,
      vehicles: Stream.value([_vehicle(id: 'v1', status: 2)]),
      permission: Permission.preparation,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('vehicle-tile-v1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('status-option-3')), findsNothing);
    expect(repository.setStatusCalls, isEmpty);
  });

  testWidgets('a failed PUT shows an error SnackBar', (tester) async {
    final repository = _FakeVehicleAdminRepository()
      ..errorToThrow = Exception('boom');
    await _pump(
      tester,
      vehicles: Stream.value([_vehicle(id: 'v1', status: 2)]),
      permission: Permission.dispatch,
      repository: repository,
    );

    await tester.tap(find.byKey(const Key('vehicle-tile-v1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('status-option-3')));
    await tester.pumpAndSettle();

    expect(
      find.text('Status konnte nicht gesetzt werden.'),
      findsOneWidget,
    );
  });
}
