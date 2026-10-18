import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/map/incident_location_card.dart';
import 'package:bftag_mobile/map/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  const incident = LatLng(48.1, 11.5);
  const station = LatLng(48.2, 11.6);

  Future<void> pump(
    WidgetTester tester, {
    LatLng? station,
    required UriLauncher launcher,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [uriLauncherProvider.overrideWithValue(launcher)],
        child: MaterialApp(
          theme: theme ?? bftagLightTheme(),
          home: Scaffold(
            body: IncidentLocationCard(
              incident: incident,
              station: station,
              tileProvider: _FakeTileProvider(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the map and the "Navigation starten" button', (
    tester,
  ) async {
    await pump(tester, launcher: (uri) async => true);

    expect(find.byType(IncidentMap), findsOneWidget);
    expect(find.byKey(const Key('start-navigation')), findsOneWidget);
    expect(find.text('Navigation starten'), findsOneWidget);
  });

  testWidgets('tapping the button launches the expected URI', (
    tester,
  ) async {
    Uri? launched;
    await pump(
      tester,
      launcher: (uri) async {
        launched = uri;
        return true;
      },
    );

    await tester.tap(find.byKey(const Key('start-navigation')));
    await tester.pumpAndSettle();

    expect(launched, isNotNull);
    // Default test platform is Android.
    expect(launched.toString(), 'geo:48.1,11.5?q=48.1,11.5');
  });

  testWidgets(
    'shows a SnackBar when the launcher fails',
    (tester) async {
      await pump(tester, launcher: (uri) async => false);

      await tester.tap(find.byKey(const Key('start-navigation')));
      await tester.pumpAndSettle();

      expect(
        find.text('Navigation konnte nicht gestartet werden'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows the Wache pin when station is set', (tester) async {
    await pump(tester, station: station, launcher: (uri) async => true);

    expect(
      find.byKey(const Key('incident-map-station-pin')),
      findsOneWidget,
    );
  });

  for (final entry in {
    'light': bftagLightTheme(),
    'dark': bftagDarkTheme(),
  }.entries) {
    testWidgets(
      'meets Android tap target and labeled tap target guidelines '
      '(${entry.key})',
      (tester) async {
        await pump(
          tester,
          theme: entry.value,
          launcher: (uri) async => true,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      },
    );

    testWidgets(
      '"Navigation starten" reaches WCAG AA contrast (${entry.key})',
      (tester) async {
        await pump(
          tester,
          theme: entry.value,
          launcher: (uri) async => true,
        );

        await expectLater(tester, meetsGuideline(textContrastGuideline));
      },
    );
  }
}
