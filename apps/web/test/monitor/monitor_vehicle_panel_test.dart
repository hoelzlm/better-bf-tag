import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/monitor_vehicle_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle _vehicle(String id, {String shortName = 'HLF 1'}) {
  return Vehicle(
    id: id,
    callSign: 'Florian $id',
    shortName: shortName,
    type: 'HLF',
    status: FmsStatus.s2,
    statusChangedAt: null,
    sortOrder: 0,
    active: true,
  );
}

CrewAssignment _crew(String vehicleId, String function, String name) {
  return CrewAssignment(
    vehicleId: vehicleId,
    personId: '$vehicleId-$function',
    displayName: name,
    function: function,
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<Vehicle> vehicles, {
  Map<String, List<CrewAssignment>> crewByVehicleId = const {},
  String? shiftLabel,
  Duration pageDuration = const Duration(seconds: 10),
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: bftagMonitorTheme(),
      home: Scaffold(
        body: MonitorVehiclePanel(
          vehicles: vehicles,
          crewByVehicleId: crewByVehicleId,
          shiftLabel: shiftLabel,
          pageDuration: pageDuration,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('MonitorVehiclePanel', () {
    testWidgets(
      // AC1: a vertical, non-scrolling list -- all rows present at once
      // for <= 7 vehicles, found without scrollUntilVisible.
      '<= 7 vehicles are all present simultaneously without scrolling '
      '(AC1)',
      (tester) async {
        final vehicles = [for (var i = 1; i <= 7; i++) _vehicle('v$i')];
        await _pump(tester, vehicles);

        for (final vehicle in vehicles) {
          expect(find.byKey(Key('crew-vehicle-${vehicle.id}')), findsOneWidget);
        }
        expect(
          find.byKey(const Key('vehicle-status-page-indicator')),
          findsNothing,
        );
      },
    );

    testWidgets(
      // AC2: > 7 vehicles page instead of scrolling, rotating at most
      // every 10 s -- a vehicle on page 2 is invisible before the timer,
      // visible after.
      '> 7 vehicles page, rotating after the configured duration (AC2)',
      (tester) async {
        final vehicles = [for (var i = 1; i <= 9; i++) _vehicle('v$i')];
        await _pump(tester, vehicles, pageDuration: const Duration(seconds: 1));

        for (var i = 1; i <= 7; i++) {
          expect(find.byKey(Key('crew-vehicle-v$i')), findsOneWidget);
        }
        expect(find.byKey(const Key('crew-vehicle-v8')), findsNothing);
        expect(find.byKey(const Key('crew-vehicle-v9')), findsNothing);
        expect(
          find.byKey(const Key('vehicle-status-page-indicator')),
          findsOneWidget,
        );

        await tester.pump(const Duration(seconds: 1));

        expect(find.byKey(const Key('crew-vehicle-v8')), findsOneWidget);
        expect(find.byKey(const Key('crew-vehicle-v9')), findsOneWidget);
        for (var i = 1; i <= 7; i++) {
          expect(find.byKey(Key('crew-vehicle-v$i')), findsNothing);
        }
      },
    );

    testWidgets(
      // AC7: a long crew list stays on one line with ellipsis -- the row
      // height must not grow (no second text line in the layout).
      'a long crew list stays on one line (ellipsis), row height constant '
      '(AC7)',
      (tester) async {
        final longCrew = [
          _crew('v1', 'GF', 'Maximilian Musterfrau-Mustermann'),
          _crew('v1', 'MA', 'Erika Musterfrau-Mustermann-Langnamig'),
          _crew('v1', 'ATF', 'Weitere Person Mit Sehr Langem Namen'),
          _crew('v1', 'ATM', 'Noch Mehr Sehr Lange Namen Hier Auch'),
        ];
        await _pump(
          tester,
          [_vehicle('v1')],
          crewByVehicleId: {'v1': longCrew},
        );

        final rowFinder = find.byKey(const Key('crew-vehicle-v1'));
        expect(rowFinder, findsOneWidget);
        final rowHeight = tester.getSize(rowFinder).height;
        // Single-line crew text: row stays at its minimum height (96 px,
        // concept §3), never grows to fit a second line.
        expect(rowHeight, lessThanOrEqualTo(120));

        final textWidget = tester.widget<Text>(
          find.descendant(
            of: rowFinder,
            matching: find.textContaining('GF Maximilian'),
          ),
        );
        expect(textWidget.maxLines, 1);
        expect(textWidget.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      // AC8: heading without/with the Schicht-Zusatz.
      'heading shows with and without the Schicht-Zusatz (AC8)',
      (tester) async {
        await _pump(tester, [_vehicle('v1')]);
        expect(find.text('Fahrzeugstatus & Besatzung'), findsOneWidget);

        await _pump(tester, [
          _vehicle('v1'),
        ], shiftLabel: 'Schicht 2 · 08:00–12:00');
        expect(
          find.text('Fahrzeugstatus & Besatzung · Schicht 2 · 08:00–12:00'),
          findsOneWidget,
        );
      },
    );

    testWidgets('empty crew renders a dash instead of a name', (tester) async {
      await _pump(tester, [_vehicle('v1')]);
      expect(
        find.descendant(
          of: find.byKey(const Key('crew-vehicle-v1')),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
    });
  });
}
