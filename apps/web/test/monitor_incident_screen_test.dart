import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/map_tile_provider.dart';
import 'package:bftag_web/screens/monitor_incident_screen.dart';
import 'package:bftag_web/station_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Offline [TileProvider] (no network calls in widget tests), mirrors
/// packages/core/test/incident_map_test.dart.
class _FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

Incident _incident({
  String id = 'i1',
  int number = 7,
  double? latitude,
  double? longitude,
}) {
  return Incident(
    id: id,
    bfDayId: 'd1',
    number: number,
    keyword: 'B2 – Wohnungsbrand',
    address: 'Musterstraße 1, Musterstadt',
    report: 'Rauchentwicklung aus Fenster, 2. OG',
    script: null,
    state: IncidentState.running,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    latitude: latitude,
    longitude: longitude,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Incident incident,
  LatLng? station,
}) async {
  // TV-distance monitor display (ADR 0017); the default 800x600 test
  // surface is too small once the map is shown alongside the existing
  // content.
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: ProviderScope(
        overrides: [
          incidentsProvider.overrideWith((ref) => Stream.value([incident])),
          alarmsProvider.overrideWith((ref) => Stream.value(const [])),
          vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
          stationProvider.overrideWith((ref) async => station),
          mapTileProviderProvider.overrideWithValue(_FakeTileProvider()),
        ],
        child: MaterialApp(
          home: MonitorIncidentScreen(incidentId: incident.id),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MonitorIncidentScreen map (ADR 0026)', () {
    testWidgets(
      'shows the map with the incident pin (and station pin) when the '
      'Einsatz has coordinates',
      (tester) async {
        await _pump(
          tester,
          incident: _incident(latitude: 52.5, longitude: 13.4),
          station: const LatLng(52.52, 13.405),
        );

        expect(find.byType(IncidentMap), findsOneWidget);
        expect(
          find.byKey(const Key('incident-map-incident-pin')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('incident-map-station-pin')),
          findsOneWidget,
        );
        expect(find.text(osmAttribution), findsOneWidget);
      },
    );

    testWidgets('shows the incident pin without a station pin when no Wache is '
        'configured', (tester) async {
      await _pump(
        tester,
        incident: _incident(latitude: 52.5, longitude: 13.4),
        station: null,
      );

      expect(find.byType(IncidentMap), findsOneWidget);
      expect(
        find.byKey(const Key('incident-map-incident-pin')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('incident-map-station-pin')), findsNothing);
    });

    testWidgets('shows no map when the Einsatz has no coordinates', (
      tester,
    ) async {
      await _pump(tester, incident: _incident());

      expect(find.byType(IncidentMap), findsNothing);
      // Existing expectations unchanged.
      expect(find.text('EINSATZ 7'), findsOneWidget);
      expect(find.text('Musterstraße 1, Musterstadt'), findsOneWidget);
    });
  });
}
