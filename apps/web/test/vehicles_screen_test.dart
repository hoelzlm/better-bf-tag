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

class _ThrowingVehicleAdminRepository extends _FakeVehicleAdminRepository {
  _ThrowingVehicleAdminRepository() : super([]);

  @override
  Future<List<Vehicle>> listAll() async {
    throw StateError('boom');
  }
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
  // AC 1: Liste zeigt alle Fahrzeuge inkl. inaktiver, mit Funkrufname,
  // Kurzname, Typ, Aktiv-Schalter.
  testWidgets('lists vehicles incl. inactive', (tester) async {
    await _pump(
      tester,
      vehicles: [
        _vehicle(id: 'v1', callSign: 'Florian 1'),
        _vehicle(id: 'v2', callSign: 'Florian 2', active: false),
      ],
    );

    expect(find.textContaining('Florian 1'), findsWidgets);
    expect(find.textContaining('Florian 2'), findsWidgets);
    expect(find.textContaining('HLF 1'), findsWidgets);
    expect(find.byKey(const Key('active-switch-v1')), findsOneWidget);
    expect(find.byKey(const Key('active-switch-v2')), findsOneWidget);
  });

  // AC 2: Klick auf eine Zeile öffnet den Bearbeiten-Dialog mit
  // vorausgefüllten Werten.
  testWidgets('tapping a row opens the edit dialog with prefilled values',
      (tester) async {
    await _pump(
      tester,
      vehicles: [_vehicle(id: 'v1', callSign: 'Florian 1')],
    );

    await tester.tap(find.byKey(const ValueKey('v1')));
    await tester.pumpAndSettle();

    expect(find.text('Fahrzeug bearbeiten'), findsOneWidget);
    final callSignField = tester.widget<TextField>(
      find.byKey(const Key('vehicle-form-call-sign')),
    );
    expect(callSignField.controller!.text, 'Florian 1');
  });

  // AC 3: "Fahrzeug anlegen" (Topbar-Button, Key `create-vehicle`) öffnet
  // den Anlegen-Dialog.
  testWidgets('create-vehicle button in the AppBar opens the create dialog',
      (tester) async {
    await _pump(tester, vehicles: [_vehicle(id: 'v1')]);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('create-vehicle'))),
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('create-vehicle')));
    await tester.pumpAndSettle();

    expect(find.text('Fahrzeug anlegen'), findsWidgets);
    expect(find.byKey(const Key('vehicle-form-call-sign')), findsOneWidget);
  });

  // AC 4: Speichern im Anlegen-Dialog ruft create() mit den eingegebenen
  // Werten auf; die Liste wird danach neu geladen.
  testWidgets(
    'create dialog calls the API with the entered values',
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
    },
  );

  // AC 5: Speichern im Bearbeiten-Dialog ruft update() mit den eingegebenen
  // Werten auf.
  testWidgets(
    'editing a vehicle calls update with the entered fields',
    (tester) async {
      final repository = await _pump(
        tester,
        vehicles: [_vehicle(id: 'v1', callSign: 'Florian 1')],
      );

      await tester.tap(find.byKey(const ValueKey('v1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('vehicle-form-call-sign')),
        'Florian 1 neu',
      );
      await tester.tap(find.byKey(const Key('vehicle-form-submit')));
      await tester.pumpAndSettle();

      expect(repository.vehicles.single.callSign, 'Florian 1 neu');
      expect(find.textContaining('Florian 1 neu'), findsOneWidget);
    },
  );

  // AC 6: Umschalten des Aktiv-Schalters ruft update(active: …) auf und
  // lädt die Liste neu.
  testWidgets('toggling active calls update with active', (tester) async {
    final repository = await _pump(
      tester,
      vehicles: [_vehicle(id: 'v1')],
    );

    await tester.tap(find.byKey(const Key('active-switch-v1')));
    await tester.pumpAndSettle();

    expect(repository.activeToggleCalls, [('v1', false)]);
  });

  // AC 7: Leeres Funkrufname-, Kurzname- oder Typ-Feld zeigt einen
  // Inline-Fehler und verhindert das Absenden.
  testWidgets(
    'empty required fields show inline errors and block submit',
    (tester) async {
      final repository = await _pump(tester, vehicles: []);

      await tester.tap(find.byKey(const Key('create-vehicle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vehicle-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Pflichtfeld'), findsNWidgets(3));
      expect(repository.createCalls, isEmpty);
      // Dialog is still open.
      expect(find.byKey(const Key('vehicle-form-call-sign')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('vehicle-form-call-sign')),
        'Florian 9',
      );
      await tester.enterText(
        find.byKey(const Key('vehicle-form-short-name')),
        'LF 9',
      );
      await tester.enterText(
        find.byKey(const Key('vehicle-form-type')),
        'LF',
      );
      await tester.tap(find.byKey(const Key('vehicle-form-submit')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
    },
  );

  // AC 8: Ziehen einer Zeile an eine neue Position ruft reorder() mit der
  // neuen Reihenfolge der Fahrzeug-IDs auf.
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

  // AC 9: Ladefehler zeigt "Fahrzeuge konnten nicht geladen werden." statt
  // der Liste.
  testWidgets(
    'load error shows the error message instead of the list',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleAdminRepositoryProvider.overrideWithValue(
              _ThrowingVehicleAdminRepository(),
            ),
          ],
          child: const MaterialApp(home: VehiclesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Fahrzeuge konnten nicht geladen werden.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('vehicles-list')), findsNothing);
      expect(find.text('Erneut versuchen'), findsOneWidget);
    },
  );

  // AC 10: Leere Fahrzeugliste zeigt den Leerzustand mit Primäraktion statt
  // einer leeren Fläche.
  testWidgets(
    'empty vehicle list shows the empty state with a primary action',
    (tester) async {
      final repository = await _pump(tester, vehicles: []);

      expect(find.text('Noch keine Fahrzeuge angelegt.'), findsOneWidget);
      expect(find.byKey(const Key('vehicles-list')), findsNothing);
      expect(find.byKey(const Key('vehicles-empty-create')), findsOneWidget);

      await tester.tap(find.byKey(const Key('vehicles-empty-create')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vehicle-form-call-sign')), findsOneWidget);
      expect(repository.createCalls, isEmpty);
    },
  );

  // AC 11: Inaktive Fahrzeuge sind in der Liste optisch (Deckkraft + Label)
  // von aktiven unterscheidbar.
  testWidgets(
    'inactive vehicles are visually distinct with reduced opacity and a label',
    (tester) async {
      await _pump(
        tester,
        vehicles: [
          _vehicle(id: 'v1', callSign: 'Florian 1'),
          _vehicle(id: 'v2', callSign: 'Florian 2', active: false),
        ],
      );

      expect(find.text('inaktiv'), findsOneWidget);

      final activeOpacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const Key('active-switch-v1')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      final inactiveOpacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const Key('active-switch-v2')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(activeOpacity.opacity, 1);
      expect(inactiveOpacity.opacity, lessThan(1));
    },
  );

  testWidgets(
    'drag handle exposes a sorting Semantics label per vehicle',
    (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        vehicles: [_vehicle(id: 'v1', callSign: 'Florian 1')],
      );

      expect(
        find.bySemanticsLabel('Ziehen zum Sortieren: Florian 1'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );
}
