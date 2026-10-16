import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/lage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeSessionController extends SessionController {
  _FakeSessionController(this._initial);

  final SessionState _initial;

  @override
  SessionState build() => _initial;
}

/// Minimal router so LageScreen's `context.go(...)` nav buttons land on a
/// recognizable target screen without pulling in the full app router (and
/// its many provider dependencies) -- same spirit as router_test.dart but
/// scoped to just the routes LageScreen itself links to.
GoRouter _router(SessionState session) {
  return GoRouter(
    initialLocation: '/admin',
    routes: [
      GoRoute(
        path: '/admin',
        builder: (context, state) => const LageScreen(),
      ),
      GoRoute(
        path: '/admin/einsaetze',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Einsätze-Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/monitors',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Monitore-Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/slides',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Folien-Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/persons',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Personen-Screen')),
        ),
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Permission permission,
}) async {
  // The AppBar's nav-entry row doesn't scroll/wrap on overflow (see
  // lage_screen.dart); admin has enough entries that the default 800px
  // test window overflows.
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  const person = Person(
    id: 'p1',
    displayName: 'Max Mustermann',
    personType: PersonType.supervisor,
    permission: Permission.admin,
  );
  final session = SessionSignedIn(
    Person(
      id: person.id,
      displayName: person.displayName,
      personType: person.personType,
      permission: permission,
    ),
    'access-token',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => _FakeSessionController(session),
        ),
        vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
        realtimeConnectionProvider.overrideWith(
          (ref) => Stream.value(ConnectionStatus.live),
        ),
        incidentsProvider.overrideWith((ref) => Stream.value(const [])),
        alarmsProvider.overrideWith((ref) => Stream.value(const [])),
        closeSuggestedIncidentIdsProvider.overrideWith(
          (ref) => Stream.value(const <String>{}),
        ),
        scheduledAlarmsProvider.overrideWith(
          (ref) => Stream.value(const <ScheduledAlarm>[]),
        ),
      ],
      child: MaterialApp.router(routerConfig: _router(session)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('anzeigen: shows the signed-in person and Berechtigung',
      (tester) async {
    await _pump(tester, permission: Permission.admin);

    expect(find.textContaining('Max Mustermann'), findsOneWidget);
    expect(find.textContaining('Administrator'), findsOneWidget);
  });

  testWidgets('Navigation: nav-einsaetze goes to the Einsätze screen',
      (tester) async {
    await _pump(tester, permission: Permission.admin);

    await tester.tap(find.byKey(const Key('nav-einsaetze')));
    await tester.pumpAndSettle();

    expect(find.text('Einsätze-Screen'), findsOneWidget);
  });

  testWidgets('Navigation: nav-monitors goes to the Monitore screen',
      (tester) async {
    await _pump(tester, permission: Permission.admin);

    await tester.tap(find.byKey(const Key('nav-monitors')));
    await tester.pumpAndSettle();

    expect(find.text('Monitore-Screen'), findsOneWidget);
  });

  testWidgets('Navigation: nav-slides goes to the Folien screen',
      (tester) async {
    await _pump(tester, permission: Permission.admin);

    await tester.tap(find.byKey(const Key('nav-slides')));
    await tester.pumpAndSettle();

    expect(find.text('Folien-Screen'), findsOneWidget);
  });

  testWidgets('Navigation: nav-persons goes to the Personen screen',
      (tester) async {
    await _pump(tester, permission: Permission.admin);

    await tester.tap(find.byKey(const Key('nav-persons')));
    await tester.pumpAndSettle();

    expect(find.text('Personen-Screen'), findsOneWidget);
  });

  testWidgets(
      'Navigation: non-admin dispatch does not see admin-only nav entries',
      (tester) async {
    await _pump(tester, permission: Permission.dispatch);

    expect(find.byKey(const Key('nav-fahrzeuge')), findsNothing);
    expect(find.byKey(const Key('nav-persons')), findsNothing);
    expect(find.byKey(const Key('nav-monitors')), findsNothing);
    expect(find.byKey(const Key('nav-slides')), findsNothing);
    expect(find.byKey(const Key('nav-einsaetze')), findsOneWidget);
  });
}
