import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/announcements/announcement_snackbar_listener.dart';
import 'package:bftag_mobile/screens/announcements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Announcement _announcement({
  String id = 'a1',
  String text = 'Hallo',
  String? shiftId,
  // Local (not UTC) DateTime on purpose: the screen formats via
  // `.toLocal()`, so a local input makes the formatted HH:mm
  // deterministic regardless of the test runner's timezone.
  required DateTime createdAt,
}) {
  return Announcement(
    id: id,
    bfDayId: 'day1',
    shiftId: shiftId,
    text: text,
    createdBy: 'p1',
    createdAt: createdAt,
  );
}

/// Resizes the test surface for the duration of the test (restored via
/// `addTearDown`), matching the 390x844/360x640 sizes the concepts test.
void _setSurfaceSize(WidgetTester tester, Size size) {
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });
}

/// WCAG contrast ratio between two colours, via relative luminance.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Announcement> announcements,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pairedRealtimeClientProvider.overrideWith((ref) => null),
        pairedAnnouncementsProvider.overrideWith(
          (ref) => Stream.value(announcements),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? bftagLightTheme(),
        home: const AnnouncementsScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows "Keine Durchsagen" when the list is empty', (
    tester,
  ) async {
    await _pump(tester, announcements: const []);

    expect(find.text('Keine Durchsagen'), findsOneWidget);
  });

  testWidgets('renders announcements newest first with HH:mm and text', (
    tester,
  ) async {
    // pairedAnnouncementsProvider already delivers newest-first (the
    // RealtimeClient reducer inserts at the front); the screen must
    // render in that order, not re-sort.
    final announcements = [
      _announcement(
        id: 'a2',
        text: 'Zweite Durchsage',
        createdAt: DateTime(2026, 6, 1, 10, 30),
      ),
      _announcement(
        id: 'a1',
        text: 'Erste Durchsage',
        createdAt: DateTime(2026, 6, 1, 8, 15),
      ),
    ];
    await _pump(tester, announcements: announcements);

    final listFinder = find.byKey(const Key('announcements-list'));
    expect(listFinder, findsOneWidget);

    final firstTile = find.byKey(const Key('announcement-a2'));
    final secondTile = find.byKey(const Key('announcement-a1'));
    expect(firstTile, findsOneWidget);
    expect(secondTile, findsOneWidget);
    expect(
      tester.getTopLeft(firstTile).dy < tester.getTopLeft(secondTile).dy,
      isTrue,
    );
    expect(find.text('Zweite Durchsage'), findsOneWidget);
    expect(find.text('Erste Durchsage'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('08:15'), findsOneWidget);
  });

  group('app-durchsagen.md ACs', () {
    testWidgets('AC1: each Durchsage card uses primaryContainer/campaign icon, '
        'never alarm or plain grey', (tester) async {
      final theme = bftagLightTheme();
      final colorScheme = theme.colorScheme;
      final alarmColors = theme.extension<BftagAlarmColors>()!;
      await _pump(
        tester,
        announcements: [_announcement(createdAt: DateTime(2026, 6, 1, 8))],
        theme: theme,
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, colorScheme.primaryContainer);
      expect(card.color, isNot(equals(alarmColors.alarm)));
      expect(card.color, isNot(equals(colorScheme.surfaceContainer)));

      expect(find.byIcon(Icons.campaign), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.campaign));
      expect(icon.color, colorScheme.onPrimaryContainer);
    });

    testWidgets(
      'AC2: the transient SnackBar uses the same icon/colour scheme as '
      'the list cards',
      (tester) async {
        final theme = bftagLightTheme();
        final colorScheme = theme.colorScheme;
        final messengerKey = GlobalKey<ScaffoldMessengerState>();
        final createdController = StreamController<Announcement>();
        addTearDown(createdController.close);
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: SizedBox()),
            ),
            GoRoute(
              path: '/durchsagen',
              builder: (context, state) => const AnnouncementsScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pairedAnnouncementCreatedProvider.overrideWith(
                (ref) => createdController.stream,
              ),
            ],
            child: AnnouncementSnackbarListener(
              messengerKey: messengerKey,
              router: router,
              child: MaterialApp.router(
                theme: theme,
                scaffoldMessengerKey: messengerKey,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        createdController.add(
          _announcement(text: 'Essen fertig', createdAt: DateTime(2026, 6, 1)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, colorScheme.primaryContainer);
        expect(snackBar.duration, const Duration(seconds: 8));
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byIcon(Icons.campaign),
          ),
          findsOneWidget,
        );
        final snackIcon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byIcon(Icons.campaign),
          ),
        );
        expect(snackIcon.color, colorScheme.onPrimaryContainer);
      },
    );

    testWidgets(
      'AC3: the empty state shows text and a 48px icon, not bare text',
      (tester) async {
        await _pump(tester, announcements: const []);

        expect(find.text('Keine Durchsagen'), findsOneWidget);
        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(BftagStateView),
            matching: find.byIcon(Icons.campaign_outlined),
          ),
        );
        expect(icon.size, 48);
      },
    );

    testWidgets(
      'AC4: a newly arriving announcement appears on top automatically, '
      'without a manual reload',
      (tester) async {
        final announcementsController = StreamController<List<Announcement>>();
        addTearDown(announcementsController.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pairedRealtimeClientProvider.overrideWith((ref) => null),
              pairedAnnouncementsProvider.overrideWith(
                (ref) => announcementsController.stream,
              ),
            ],
            child: MaterialApp(
              theme: bftagLightTheme(),
              home: const AnnouncementsScreen(),
            ),
          ),
        );
        await tester.pump();

        announcementsController.add([
          _announcement(
            id: 'a1',
            text: 'Erste',
            createdAt: DateTime(2026, 6, 1, 8),
          ),
        ]);
        await tester.pump();
        await tester.pump();

        expect(find.text('Erste'), findsOneWidget);

        // Realtime delivers the new one already prepended (newest-first).
        announcementsController.add([
          _announcement(
            id: 'a2',
            text: 'Zweite',
            createdAt: DateTime(2026, 6, 1, 9),
          ),
          _announcement(
            id: 'a1',
            text: 'Erste',
            createdAt: DateTime(2026, 6, 1, 8),
          ),
        ]);
        await tester.pump();
        await tester.pump();

        final firstTile = find.byKey(const Key('announcement-a2'));
        final secondTile = find.byKey(const Key('announcement-a1'));
        expect(firstTile, findsOneWidget);
        expect(secondTile, findsOneWidget);
        expect(
          tester.getTopLeft(firstTile).dy < tester.getTopLeft(secondTile).dy,
          isTrue,
        );
      },
    );

    testWidgets(
      'AC5: the SnackBar "Anzeigen" action navigates to /durchsagen',
      (tester) async {
        final messengerKey = GlobalKey<ScaffoldMessengerState>();
        final createdController = StreamController<Announcement>();
        addTearDown(createdController.close);
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: SizedBox()),
            ),
            GoRoute(
              path: '/durchsagen',
              builder: (context, state) => const AnnouncementsScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pairedRealtimeClientProvider.overrideWith((ref) => null),
              pairedAnnouncementsProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              pairedAnnouncementCreatedProvider.overrideWith(
                (ref) => createdController.stream,
              ),
            ],
            child: AnnouncementSnackbarListener(
              messengerKey: messengerKey,
              router: router,
              child: MaterialApp.router(
                theme: bftagLightTheme(),
                scaffoldMessengerKey: messengerKey,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pump();

        createdController.add(
          _announcement(text: 'Abendessen', createdAt: DateTime(2026, 6, 1)),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Anzeigen'));
        await tester.pumpAndSettle();

        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AC6: card text reaches WCAG AA contrast against primaryContainer '
      'in light and dark theme',
      (tester) async {
        for (final theme in [bftagLightTheme(), bftagDarkTheme()]) {
          final colorScheme = theme.colorScheme;
          expect(
            _contrast(
              colorScheme.onPrimaryContainer,
              colorScheme.primaryContainer,
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );

    testWidgets('no overflow at 390x844 and 360x640 with a filled list', (
      tester,
    ) async {
      final announcements = [
        _announcement(id: 'a1', createdAt: DateTime(2026, 6, 1, 8)),
        _announcement(id: 'a2', createdAt: DateTime(2026, 6, 1, 9)),
      ];
      for (final size in [const Size(390, 844), const Size(360, 640)]) {
        _setSurfaceSize(tester, size);
        await _pump(tester, announcements: announcements);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(light, 390x844)', (tester) async {
      await _pump(
        tester,
        announcements: [_announcement(createdAt: DateTime(2026, 6, 1, 8))],
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(dark, 360x640)', (tester) async {
      _setSurfaceSize(tester, const Size(360, 640));
      await _pump(
        tester,
        announcements: [_announcement(createdAt: DateTime(2026, 6, 1, 8))],
        theme: bftagDarkTheme(),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets textContrastGuideline (light)', (tester) async {
      await _pump(
        tester,
        announcements: [_announcement(createdAt: DateTime(2026, 6, 1, 8))],
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('meets textContrastGuideline (dark)', (tester) async {
      await _pump(
        tester,
        announcements: [_announcement(createdAt: DateTime(2026, 6, 1, 8))],
        theme: bftagDarkTheme(),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
