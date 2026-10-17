import 'dart:io';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/monitor_clock.dart';
import 'package:bftag_web/monitor/monitor_session.dart';
import 'package:bftag_web/screens/monitor_standby_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'connection_banner_helper.dart';

/// Pins [MonitorSessionControllerProvider] to a fixed [MonitorPaired]
/// state -- this test pumps [MonitorStandbyScreen] directly (not through
/// [MonitorScreen]/pairing), so no `restore()`/network call should ever
/// happen.
class _FixedMonitorController extends MonitorSessionController {
  _FixedMonitorController(this._state);

  final MonitorSessionState _state;

  @override
  MonitorSessionState build() => _state;

  @override
  Future<void> restore() async {}
}

Vehicle _vehicle(String id, {FmsStatus status = FmsStatus.s2}) {
  return Vehicle(
    id: id,
    callSign: 'Florian $id',
    shortName: 'HLF $id',
    type: 'HLF',
    status: status,
    statusChangedAt: null,
    sortOrder: 0,
    active: true,
  );
}

ProgramItem _programItem({
  required String id,
  required String title,
  required DateTime startsAt,
  required DateTime endsAt,
}) {
  return ProgramItem(
    id: id,
    bfDayId: 'day1',
    title: title,
    type: ProgramItemType.other,
    startsAt: startsAt,
    endsAt: endsAt,
  );
}

List<Override> _baseOverrides({
  DateTime? clock,
  List<Vehicle> vehicles = const [],
  List<Slide> slides = const [],
  BfDay? bfDay,
  List<Shift> shifts = const [],
  List<ProgramItem> programItems = const [],
  List<Announcement> announcements = const [],
  ConnectionStatus connection = ConnectionStatus.live,
}) {
  return [
    monitorSessionControllerProvider.overrideWith(
      () => _FixedMonitorController(
        const MonitorPaired(
          monitorId: 'mon1',
          name: 'Gerätehaus',
          accessToken: 'at1',
        ),
      ),
    ),
    monitorClockProvider.overrideWith(
      (ref) => Stream.value(clock ?? DateTime.utc(2026, 10, 11, 10, 0, 0)),
    ),
    vehiclesProvider.overrideWith((ref) => Stream.value(vehicles)),
    slidesProvider.overrideWith((ref) => Stream.value(slides)),
    bfDayProvider.overrideWith((ref) => Stream.value(bfDay)),
    shiftsProvider.overrideWith((ref) => Stream.value(shifts)),
    programItemsProvider.overrideWith((ref) => Stream.value(programItems)),
    announcementsProvider.overrideWith((ref) => Stream.value(announcements)),
    realtimeConnectionProvider.overrideWith((ref) => Stream.value(connection)),
  ];
}

Future<void> _pumpStandby(
  WidgetTester tester, {
  required List<Override> overrides,
  Announcement? liveBanner,
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: bftagMonitorTheme(),
          home: MonitorStandbyScreen(liveBanner: liveBanner),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // AC3: no raw Colors.red/orange/amber or Color(0x...) literal for FMS-
  // or Durchsage-Flächen in the touched monitor files -- only theme
  // tokens. Source-grep, mirrors the card's acceptance-criteria grep.
  test('no raw Colors.red/orange/amber or Color(0x...) literal in the '
      'touched monitor files (AC3)', () {
    final forbidden = RegExp(r'Colors\.(red|orange|amber)|Color\(0x');
    for (final path in [
      'lib/screens/monitor_standby_screen.dart',
      'lib/monitor/monitor_vehicle_panel.dart',
      'lib/monitor/announcement_banner.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        forbidden.hasMatch(source),
        isFalse,
        reason: '$path contains a forbidden raw color literal',
      );
    }
  });

  group('MonitorStandbyScreen', () {
    testWidgets(
      // AC4: the shared MonitorConnectionBanner, topmost, >= 56 px,
      // never red/alarm -- identical assertion on all three monitor
      // screens via the shared helper.
      'reconnecting banner is shown at the top, never red/alarm (AC4)',
      (tester) async {
        await _pumpStandby(
          tester,
          overrides: _baseOverrides(connection: ConnectionStatus.reconnecting),
        );
        await tester.pump();

        await expectReconnectingBannerAtTop(tester);
      },
    );

    testWidgets(
      // AC5: the live Durchsage banner uses primaryContainer, not amber.
      'the live Durchsage banner uses primaryContainer, not amber (AC5)',
      (tester) async {
        final announcement = Announcement(
          id: 'ann1',
          bfDayId: 'day1',
          text: 'Essen ist fertig',
          createdBy: 'p1',
          createdAt: DateTime.utc(2026, 10, 11, 9, 0, 0),
        );
        await _pumpStandby(
          tester,
          overrides: _baseOverrides(),
          liveBanner: announcement,
        );
        await tester.pump();

        final bannerFinder = find.byKey(const Key('announcement-banner'));
        expect(bannerFinder, findsOneWidget);
        final container = tester.widget<Container>(bannerFinder);
        final theme = Theme.of(tester.element(bannerFinder));
        expect(container.color, theme.colorScheme.primaryContainer);
        expect(container.color, isNot(equals(Colors.amber)));
        expect(find.text('Essen ist fertig'), findsOneWidget);
      },
    );

    testWidgets(
      // AC6: monitor-name and monitor-date render at >= 22 px.
      'monitor-name and monitor-date render at >= 22 px (AC6)',
      (tester) async {
        await _pumpStandby(tester, overrides: _baseOverrides());
        await tester.pump();

        final nameText = tester.widget<Text>(
          find.byKey(const Key('monitor-name')),
        );
        final dateText = tester.widget<Text>(
          find.byKey(const Key('monitor-date')),
        );
        expect(nameText.style!.fontSize, greaterThanOrEqualTo(22));
        expect(dateText.style!.fontSize, greaterThanOrEqualTo(22));
      },
    );

    testWidgets(
      // AC9: a past Programmpunkt (ends_at already in the past, and not
      // the current one) never appears in the Tagesablauf column.
      'a past Programmpunkt never appears in the Tagesablauf column (AC9)',
      (tester) async {
        final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
        await _pumpStandby(
          tester,
          overrides: _baseOverrides(
            clock: now,
            programItems: [
              _programItem(
                id: 'past',
                title: 'Vergangener Punkt',
                startsAt: now.subtract(const Duration(hours: 3)),
                endsAt: now.subtract(const Duration(hours: 1)),
              ),
              _programItem(
                id: 'current',
                title: 'Aktueller Punkt',
                startsAt: now.subtract(const Duration(minutes: 30)),
                endsAt: now.add(const Duration(minutes: 30)),
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.textContaining('Vergangener Punkt'), findsNothing);
        expect(find.textContaining('Aktueller Punkt'), findsOneWidget);
      },
    );

    testWidgets(
      // AC10: with slides present, the Folienfläche is >= 900x440 and
      // shows both a >= 40 px title and a >= 28 px Markdown body.
      'the Folienfläche has a minimum size of 900x440 with title >= 40 '
      'px and body >= 28 px (AC10)',
      (tester) async {
        await _pumpStandby(
          tester,
          overrides: _baseOverrides(
            slides: [
              Slide(
                id: 'sl1',
                title: 'Hinweis',
                body: 'Willkommen beim **BF-Tag**',
                durationSeconds: 30,
                sortOrder: 1,
                active: true,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final slideFinder = find.byKey(const Key('slide-sl1'));
        expect(slideFinder, findsOneWidget);

        final titleFinder = find.byKey(const Key('slide-title'));
        final titleWidget = tester.widget<Text>(titleFinder);
        expect(titleWidget.style!.fontSize, greaterThanOrEqualTo(40));

        final bodyFinder = find.byKey(const Key('slide-body'));
        final bodyWidget = tester.widget<MarkdownBody>(bodyFinder);
        expect(bodyWidget.styleSheet!.p!.fontSize, greaterThanOrEqualTo(28));

        // The slide area itself (the sized ancestor enforcing the
        // minimum) is at least 900x440 (concept §3/§6 AC10).
        final slideAreaSize = tester.getSize(
          find.byKey(const Key('monitor-slide-area')),
        );
        expect(slideAreaSize.width, greaterThanOrEqualTo(900));
        expect(slideAreaSize.height, greaterThanOrEqualTo(440));
      },
    );

    testWidgets('empty Tagesablauf shows the "Kein Tagesablauf" hint', (
      tester,
    ) async {
      await _pumpStandby(tester, overrides: _baseOverrides());
      await tester.pump();

      expect(find.byKey(const Key('program-standby-panel')), findsOneWidget);
      expect(find.text('Kein Tagesablauf für heute.'), findsOneWidget);
    });

    testWidgets('vehicles are shown via the new MonitorVehiclePanel', (
      tester,
    ) async {
      await _pumpStandby(
        tester,
        overrides: _baseOverrides(vehicles: [_vehicle('v1')]),
      );
      await tester.pump();

      expect(find.byKey(const Key('crew-panel-vehicles')), findsOneWidget);
      expect(find.byKey(const Key('crew-vehicle-v1')), findsOneWidget);
      expect(find.byKey(const Key('vehicle-status-bar')), findsNothing);
    });
  });
}
