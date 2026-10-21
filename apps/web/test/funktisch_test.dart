import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/widgets/funktisch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle({
  String id = 'v1',
  String callSign = 'Florian 46/1',
  String shortName = 'HLF 1',
  String type = 'HLF',
  int status = 2,
  int sortOrder = 1,
  DateTime? statusChangedAt,
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: type,
    status: FmsStatus.fromCode(status),
    statusChangedAt: statusChangedAt,
    sortOrder: sortOrder,
    active: true,
  );
}

class _FakeVehicleAdminRepository implements VehicleAdminRepository {
  final List<(String, int)> setStatusCalls = [];
  Object? errorToThrow;

  @override
  Future<void> setStatus(String id, int status) async {
    setStatusCalls.add((id, status));
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<List<Vehicle>> listAll() async => [];

  @override
  Future<Vehicle> create({
    required String callSign,
    required String shortName,
    required String type,
  }) => throw UnimplementedError();

  @override
  Future<Vehicle> update(
    String id, {
    String? callSign,
    String? shortName,
    String? type,
    bool? active,
  }) => throw UnimplementedError();

  @override
  Future<void> reorder(List<String> vehicleIds) => throw UnimplementedError();
}

Future<_FakeVehicleAdminRepository> _pump(
  WidgetTester tester, {
  required List<Vehicle> vehicles,
}) async {
  tester.view.physicalSize = const Size(700, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final repository = _FakeVehicleAdminRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
        realtimeConnectionProvider.overrideWith(
          (ref) => Stream.value(ConnectionStatus.live),
        ),
        vehicleAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: bftagLightTheme(),
        home: const Scaffold(body: Funktisch()),
      ),
    ),
  );
  await tester.pump();
  return repository;
}

void main() {
  testWidgets('one row per vehicle with status keys 1–6 (HLF) and 1–8 (RTW)', (
    tester,
  ) async {
    await _pump(
      tester,
      vehicles: [
        _vehicle(id: 'v1'),
        _vehicle(id: 'v2', shortName: 'RTW 1', type: 'RTW', sortOrder: 2),
      ],
    );

    expect(find.byKey(const Key('funktisch-row-v1')), findsOneWidget);
    expect(find.byKey(const Key('funktisch-row-v2')), findsOneWidget);
    for (var code = 1; code <= 6; code++) {
      expect(find.byKey(Key('funktisch-v1-$code')), findsOneWidget);
    }
    expect(find.byKey(const Key('funktisch-v1-7')), findsNothing);
    expect(find.byKey(const Key('funktisch-v1-8')), findsNothing);
    expect(find.byKey(const Key('funktisch-v2-7')), findsOneWidget);
    expect(find.byKey(const Key('funktisch-v2-8')), findsOneWidget);
    expect(find.text('Florian 46/1'), findsNWidgets(2));
  });

  testWidgets('one click on a status key sets the status (no dialog)', (
    tester,
  ) async {
    final repository = await _pump(tester, vehicles: [_vehicle(id: 'v1')]);

    await tester.tap(find.byKey(const Key('funktisch-v1-3')));
    await tester.pump();

    expect(repository.setStatusCalls, [('v1', 3)]);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('shows the current status with the time it was set', (
    tester,
  ) async {
    await _pump(
      tester,
      vehicles: [
        _vehicle(
          id: 'v1',
          status: 4,
          statusChangedAt: DateTime(2026, 10, 24, 14, 32),
        ),
      ],
    );

    expect(find.text('4 Am Einsatzort · 14:32'), findsOneWidget);
  });

  testWidgets('keyboard: select a vehicle, a digit sets its status, '
      'arrow down moves to the next vehicle', (tester) async {
    final repository = await _pump(
      tester,
      vehicles: [
        _vehicle(id: 'v1'),
        _vehicle(id: 'v2', shortName: 'LF 1', sortOrder: 2),
      ],
    );

    await tester.tap(find.byKey(const Key('funktisch-select-v1')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
    await tester.pump();

    expect(repository.setStatusCalls, [('v1', 3), ('v2', 4)]);
  });

  testWidgets('keyboard: digits not offered for the vehicle type are ignored', (
    tester,
  ) async {
    final repository = await _pump(tester, vehicles: [_vehicle(id: 'v1')]);

    await tester.tap(find.byKey(const Key('funktisch-select-v1')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();

    expect(repository.setStatusCalls, isEmpty);
  });

  testWidgets('a failed request shows a SnackBar naming vehicle and status', (
    tester,
  ) async {
    final repository = await _pump(tester, vehicles: [_vehicle(id: 'v1')]);
    repository.errorToThrow = Exception('409');

    await tester.tap(find.byKey(const Key('funktisch-v1-4')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Status 4 für HLF 1 konnte nicht gesetzt werden.'),
      findsOneWidget,
    );
  });
}
