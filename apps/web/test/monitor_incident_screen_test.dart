import 'dart:io';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/map_tile_provider.dart';
import 'package:bftag_web/screens/monitor_incident_screen.dart';
import 'package:bftag_web/station_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'monitor/connection_banner_helper.dart';

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
  String report = 'Rauchentwicklung aus Fenster, 2. OG',
}) {
  return Incident(
    id: id,
    bfDayId: 'd1',
    number: number,
    keyword: 'B2 – Wohnungsbrand',
    address: 'Musterstraße 1, Musterstadt',
    report: report,
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
  Size size = const Size(1600, 900),
  List<Alarm> alarms = const [],
  List<Vehicle> vehicles = const [],
  ConnectionStatus? connection,
}) async {
  // TV-distance monitor display (ADR 0017); the default 800x600 test
  // surface is too small once the map is shown alongside the existing
  // content.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: ProviderScope(
        overrides: [
          incidentsProvider.overrideWith((ref) => Stream.value([incident])),
          alarmsProvider.overrideWith((ref) => Stream.value(alarms)),
          vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
          stationProvider.overrideWith((ref) async => station),
          mapTileProviderProvider.overrideWithValue(_FakeTileProvider()),
          if (connection != null)
            realtimeConnectionProvider.overrideWith(
              (ref) => Stream.value(connection),
            ),
        ],
        child: MaterialApp(
          theme: bftagMonitorTheme(),
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

    testWidgets(
      'shows the "Keine Standortdaten" placeholder instead of the map '
      'when the Einsatz has no coordinates (AC2)',
      (tester) async {
        await _pump(tester, incident: _incident());

        expect(find.byType(IncidentMap), findsNothing);
        expect(
          find.byKey(const Key('monitor-incident-map-placeholder')),
          findsOneWidget,
        );
        expect(find.text('Keine Standortdaten'), findsOneWidget);
        // Existing expectations unchanged.
        expect(find.text('EINSATZ 7'), findsOneWidget);
        expect(find.text('Musterstraße 1, Musterstadt'), findsOneWidget);
      },
    );

    testWidgets('the map area is at least 560 px tall at 1920x1080 (AC1)', (
      tester,
    ) async {
      await _pump(
        tester,
        incident: _incident(latitude: 52.5, longitude: 13.4),
        station: const LatLng(52.52, 13.405),
        size: const Size(1920, 1080),
      );

      final mapAreaRect = tester.getRect(
        find.byKey(const Key('monitor-incident-map-area')),
      );
      expect(mapAreaRect.height, greaterThanOrEqualTo(560));
    });
  });

  group('MonitorIncidentScreen (docs/design/screens/monitor-einsatz.md)', () {
    test(
      'does not use Colors.red/orange/amber or raw Color(0x...) directly '
      'in monitor_incident_screen.dart/monitor_incident_parts.dart (AC3)',
      () {
        final forbidden = RegExp(r'Colors\.(red|orange|amber)|Color\(0x');
        for (final path in [
          'lib/screens/monitor_incident_screen.dart',
          'lib/monitor/monitor_incident_parts.dart',
        ]) {
          final content = File(path).readAsStringSync();
          final matches = forbidden.allMatches(content).toList();
          expect(
            matches,
            isEmpty,
            reason: '$path contains hard-coded color(s): '
                '${matches.map((m) => m.group(0)).toList()}',
          );
        }
      },
    );

    testWidgets(
      'vehicle chips show the vehicle name, callSign and an FMS pill (AC5)',
      (tester) async {
        await _pump(
          tester,
          incident: _incident(),
          alarms: [
            Alarm(
              id: 'a1',
              incidentId: 'i1',
              state: AlarmState.triggered,
              triggeredAt: DateTime(2026, 10, 9, 8),
              vehicleIds: const ['v1'],
              recipients: const [],
            ),
          ],
          vehicles: const [
            Vehicle(
              id: 'v1',
              callSign: 'Florian 46/1',
              shortName: 'HLF-1',
              type: 'HLF',
              status: FmsStatus.s4,
              statusChangedAt: null,
              sortOrder: 1,
              active: true,
            ),
          ],
        );

        expect(find.byKey(const Key('incident-vehicle-v1')), findsOneWidget);
        expect(find.text('HLF-1'), findsOneWidget);
        expect(find.text('Florian 46/1'), findsOneWidget);
        final badge = tester.widget<FmsBadge>(find.byType(FmsBadge));
        expect(badge.status, FmsStatus.s4);
        expect(badge.large, isTrue);
      },
    );

    testWidgets(
      'truncates a long Meldebild to 6 lines and shows the more-indicator '
      '(AC6)',
      (tester) async {
        final longReport = List.generate(
          20,
          (i) => 'Zeile $i mit ausreichend Text, um Umbrüche zu erzwingen.',
        ).join(' ');
        await _pump(tester, incident: _incident(report: longReport));

        final reportFinder = find.byKey(const Key('monitor-incident-report'));
        expect(reportFinder, findsOneWidget);
        final text = tester.widget<Text>(reportFinder);
        expect(text.maxLines, 6);
        expect(
          find.byKey(const Key('monitor-incident-report-more')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows the shared reconnecting connection banner at the top (AC7)',
      (tester) async {
        await _pump(
          tester,
          incident: _incident(latitude: 52.5, longitude: 13.4),
          connection: ConnectionStatus.reconnecting,
        );

        await expectReconnectingBannerAtTop(tester);
      },
    );
  });
}
