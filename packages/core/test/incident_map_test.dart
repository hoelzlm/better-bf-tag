import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Offline [TileProvider] (no network calls in widget tests): always
/// returns the same transparent 1x1 PNG.
class _FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

void main() {
  const incident = LatLng(52.5, 13.4);
  const station = LatLng(52.52, 13.405);

  Future<void> pump(
    WidgetTester tester, {
    LatLng? incident,
    LatLng? station,
    bool interactive = false,
    void Function(LatLng point)? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncidentMap(
            incident: incident,
            station: station,
            interactive: interactive,
            onTap: onTap,
            tileProvider: _FakeTileProvider(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('IncidentMap (ADR 0026)', () {
    testWidgets('renders the incident pin when incident is set', (
      tester,
    ) async {
      await pump(tester, incident: incident);

      expect(
        find.byKey(const Key('incident-map-incident-pin')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('incident-map-station-pin')),
        findsNothing,
      );
    });

    testWidgets('renders both pins when incident and station are set', (
      tester,
    ) async {
      await pump(tester, incident: incident, station: station);

      expect(
        find.byKey(const Key('incident-map-incident-pin')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('incident-map-station-pin')),
        findsOneWidget,
      );
    });

    testWidgets('renders no pins when neither is set', (tester) async {
      await pump(tester);

      expect(
        find.byKey(const Key('incident-map-incident-pin')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('incident-map-station-pin')),
        findsNothing,
      );
    });

    testWidgets('always shows the OSM attribution text', (tester) async {
      await pump(tester, incident: incident);

      expect(find.text(osmAttribution), findsOneWidget);
    });

    testWidgets('updates the incident pin when incident changes', (
      tester,
    ) async {
      await pump(tester, incident: incident);
      expect(
        find.byKey(const Key('incident-map-incident-pin')),
        findsOneWidget,
      );

      await pump(tester); // incident becomes null

      expect(
        find.byKey(const Key('incident-map-incident-pin')),
        findsNothing,
      );
    });
  });
}
