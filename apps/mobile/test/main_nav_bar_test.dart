import 'dart:io';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/widgets/main_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> _pump(
  WidgetTester tester, {
  int currentIndex = 0,
  ThemeData? theme,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            MainNavBar(currentIndex: currentIndex),
      ),
      GoRoute(
        path: '/einsaetze',
        builder: (context, state) =>
            MainNavBar(currentIndex: currentIndex),
      ),
      GoRoute(
        path: '/durchsagen',
        builder: (context, state) =>
            MainNavBar(currentIndex: currentIndex),
      ),
      GoRoute(
        path: '/tagesablauf',
        builder: (context, state) =>
            MainNavBar(currentIndex: currentIndex),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: theme ?? bftagLightTheme(),
      routerConfig: router,
    ),
  );
  return router;
}

/// WCAG contrast ratio between two colours, via relative luminance
/// (`Color.computeLuminance`) per `docs/design/tools/contrast.py`'s
/// formula (app-navigation.md AC6).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  testWidgets('has exactly four destinations', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('nav-my-vehicle')), findsOneWidget);
    expect(find.byKey(const Key('nav-incidents')), findsOneWidget);
    expect(find.byKey(const Key('nav-announcements')), findsOneWidget);
    expect(find.byKey(const Key('nav-program')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(4),
    );
  });

  testWidgets('tapping "Durchsagen" navigates to /durchsagen',
      (tester) async {
    final router = await _pump(tester, currentIndex: 0);

    await tester.tap(find.byKey(const Key('nav-announcements')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/durchsagen');
  });

  testWidgets('tapping "Ablauf" navigates to /tagesablauf', (tester) async {
    final router = await _pump(tester, currentIndex: 0);

    await tester.tap(find.byKey(const Key('nav-program')));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/tagesablauf',
    );
  });

  testWidgets('tapping "Fahrzeug" navigates to /', (tester) async {
    final router = await _pump(tester, currentIndex: 2);

    await tester.tap(find.byKey(const Key('nav-my-vehicle')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
  });

  testWidgets('tapping "Einsätze" navigates to /einsaetze', (tester) async {
    final router = await _pump(tester, currentIndex: 0);

    await tester.tap(find.byKey(const Key('nav-incidents')));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/einsaetze',
    );
  });

  testWidgets('AC2/AC3: each tab has a touch target >= 48x48 dp',
      (tester) async {
    await _pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets(
    'AC6: light theme contrast primary/onSurfaceVariant on surfaceVariant '
    'is >= 4.5:1',
    (tester) async {
      final theme = bftagLightTheme();
      final scheme = theme.colorScheme;
      // `navigationBarTheme.backgroundColor` is the design-token
      // "surfaceVariant", which this theme maps to
      // `ColorScheme.surfaceContainer` (see theme.dart).
      expect(
        _contrast(scheme.primary, scheme.surfaceContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSurfaceVariant, scheme.surfaceContainer),
        greaterThanOrEqualTo(4.5),
      );
    },
  );

  testWidgets(
    'AC6: dark theme contrast primary/onSurfaceVariant on surfaceVariant '
    'is >= 4.5:1',
    (tester) async {
      final theme = bftagDarkTheme();
      final scheme = theme.colorScheme;
      expect(
        _contrast(scheme.primary, scheme.surfaceContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSurfaceVariant, scheme.surfaceContainer),
        greaterThanOrEqualTo(4.5),
      );
    },
  );

  testWidgets('AC7: no badge widget is rendered on the nav bar',
      (tester) async {
    await _pump(tester);

    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('renders with the dark theme too', (tester) async {
    await _pump(tester, theme: bftagDarkTheme());

    expect(find.byKey(const Key('main-nav-bar')), findsOneWidget);
  });

  test(
    'AC4: MainNavBar is only used by the four top-level screens, not '
    'onboarding/pair/einsatzdetail/alarm/settings',
    () {
      final screensDir = Directory('lib/screens');
      final onboardingDir = Directory('lib/onboarding');
      final offenders = <String>[];
      for (final dir in [screensDir, onboardingDir]) {
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final content = entity.readAsStringSync();
          if (!content.contains('MainNavBar(')) continue;
          final base = entity.uri.pathSegments.last;
          const allowed = {
            'my_vehicle_screen.dart',
            'incidents_screen.dart',
            'program_screen.dart',
            'announcements_screen.dart',
          };
          if (!allowed.contains(base)) {
            offenders.add(entity.path);
          }
        }
      }
      expect(offenders, isEmpty, reason: 'Unexpected MainNavBar usage in '
          '$offenders — must stay out of onboarding/pair/einsatzdetail/'
          'alarm/settings.');
    },
  );
}
