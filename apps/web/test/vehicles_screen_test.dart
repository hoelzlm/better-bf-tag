import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/vehicles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle({
  String id = 'v1',
  String callSign = 'Florian 1',
  String shortName = 'HLF 1',
  String type = 'HLF',
  int sortOrder = 1,
  bool active = true,
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: type,
    status: FmsStatus.s2,
    statusChangedAt: null,
    sortOrder: sortOrder,
    active: active,
  );
}

class _FakeVehicleAdminRepository implements VehicleAdminRepository {
  _FakeVehicleAdminRepository(this.vehicles);

  List<Vehicle> vehicles;
  final List<(String, int, String?)> createCalls = [];
  final List<List<String>> reorderCalls = [];
  final List<(String, bool?)> activeToggleCalls = [];

  @override
  Future<List<Vehicle>> listAll() async => List.of(vehicles);

  @override
  Future<Vehicle> create({
    required String callSign,
    required String shortName,
    required String type,
  }) async {
    createCalls.add((callSign, vehicles.length, type));
    final created = Vehicle(
      id: 'new-${vehicles.length}',
      callSign: callSign,
      shortName: shortName,
      type: type,
      status: FmsStatus.s2,
      statusChangedAt: null,
      sortOrder: vehicles.length,
      active: true,
    );
    vehicles = [...vehicles, created];
    return created;
  }

  @override
  Future<Vehicle> update(
    String id, {
    String? callSign,
    String? shortName,
    String? type,
    bool? active,
  }) async {
    if (active != null) {
      activeToggleCalls.add((id, active));
    }
    final index = vehicles.indexWhere((v) => v.id == id);
    final updated = vehicles[index].copyWith(
      callSign: callSign,
      shortName: shortName,
      type: type,
      active: active,
    );
    vehicles = List.of(vehicles)..[index] = updated;
    return updated;
  }

  @override
  Future<void> reorder(List<String> vehicleIds) async {
    reorderCalls.add(vehicleIds);
    final byId = {for (final v in vehicles) v.id: v};
    vehicles = [
      for (var i = 0; i < vehicleIds.length; i++)
        byId[vehicleIds[i]]!.copyWith(sortOrder: i),
    ];
  }

  @override
  Future<void> setStatus(String id, int status) => throw UnimplementedError();
}

Future<_FakeVehicleAdminRepository> _pump(
  WidgetTester tester, {
  required List<Vehicle> vehicles,
}) async {
  final repository = _FakeVehicleAdminRepository(vehicles);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: VehiclesScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('lists vehicles incl. inactive', (tester) async {
    await _pump(
      tester,
      vehicles: [
        _vehicle(id: 'v1', callSign: 'Florian 1'),
        _vehicle(id: 'v2', callSign: 'Florian 2', active: false),
      ],
    );

    expect(find.textContaining('Florian 1'), findsOneWidget);
    expect(find.textContaining('Florian 2'), findsOneWidget);
  });

  testWidgets('create dialog calls the API with the entered values',
      (tester) async {
    final repository = await _pump(tester, vehicles: []);

    await tester.tap(find.byKey(const Key('create-vehicle')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('vehicle-form-call-sign')),
      'Florian 3',
    );
    await tester.enterText(
      find.byKey(const Key('vehicle-form-short-name')),
      'LF 3',
    );
    await tester.tap(find.byKey(const Key('type-suggestion-LF')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('vehicle-form-submit')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, hasLength(1));
    final call = repository.createCalls.single;
    expect(call.$1, 'Florian 3');
    expect(call.$3, 'LF');
    expect(find.textContaining('Florian 3'), findsOneWidget);
  });

  testWidgets('reorder calls the order API', (tester) async {
    final repository = await _pump(
      tester,
      vehicles: [
        _vehicle(id: 'v1', callSign: 'Florian 1', sortOrder: 0),
        _vehicle(id: 'v2', callSign: 'Florian 2', sortOrder: 1),
      ],
    );

    final state =
        tester.state<State<StatefulWidget>>(find.byType(VehiclesScreen));
    // Drive the private reorder handler via the public ReorderableListView
    // widget would require real drag gestures; call the API contract the
    // same way the UI does instead, confirming the handoff shape (ids in
    // the new order) matches what `onReorderItem` would produce.
    final reorderable = tester.widget<ReorderableListView>(
      find.byKey(const Key('vehicles-list')),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pumpAndSettle();

    expect(repository.reorderCalls, [
      ['v2', 'v1'],
    ]);
    expect(state, isNotNull);
  });

  testWidgets('toggling active calls update with active', (tester) async {
    final repository = await _pump(
      tester,
      vehicles: [_vehicle(id: 'v1')],
    );

    await tester.tap(find.byKey(const Key('active-switch-v1')));
    await tester.pumpAndSettle();

    expect(repository.activeToggleCalls, [('v1', false)]);
  });
}
