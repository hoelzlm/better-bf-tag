// Tests for AdminShell against docs/design/screens/web-navigation.md
// acceptance criteria (§6).
import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeSessionController extends SessionController {
  _FakeSessionController(this._initial, this._notifier);

  final SessionState _initial;
  final ValueNotifier<SessionState> _notifier;

  @override
  SessionState build() => _initial;

  @override
  Future<void> logout() async {
    state = const SessionSignedOut();
    _notifier.value = state;
  }
}

GoRouter _router(
  Widget shellChild, {
  String initialLocation = '/admin',
  required ValueNotifier<SessionState> sessionNotifier,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: sessionNotifier,
    redirect: (context, state) {
      if (sessionNotifier.value is SessionSignedOut &&
          state.matchedLocation != '/admin/login') {
        return '/admin/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            AdminShell(location: '/admin', child: shellChild),
      ),
      GoRoute(
        path: '/admin/einsaetze',
        builder: (context, state) => AdminShell(
          location: '/admin/einsaetze',
          child: const Scaffold(
            body: Center(child: Text('Einsätze-Screen')),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/fahrzeuge',
        builder: (context, state) => AdminShell(
          location: '/admin/fahrzeuge',
          child: const Scaffold(
            body: Center(child: Text('Fahrzeuge-Screen')),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login-Screen')),
        ),
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Permission permission,
  Size size = const Size(1440, 900),
  Widget? shellChild,
  ConnectionStatus connection = ConnectionStatus.live,
}) async {
  tester.view.physicalSize = size;
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
  final sessionNotifier = ValueNotifier<SessionState>(session);
  addTearDown(sessionNotifier.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => _FakeSessionController(session, sessionNotifier),
        ),
        realtimeConnectionProvider.overrideWith(
          (ref) => Stream.value(connection),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: _router(
          shellChild ?? const Scaffold(body: Center(child: Text('Lage-Inhalt'))),
          sessionNotifier: sessionNotifier,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _existingNavKeys = [
  'nav-einsaetze',
  'nav-schichten',
  'nav-durchsagen',
  'nav-tagesablauf',
  'nav-bf-tage',
  'nav-fahrzeuge',
  'nav-persons',
  'nav-monitors',
  'nav-slides',
];

void main() {
  testWidgets(
    'AC1: every /admin/* screen renders the same sidebar via AdminShell',
    (tester) async {
      await _pump(tester, permission: Permission.admin);

      expect(find.byKey(const Key('nav-lage')), findsOneWidget);
      expect(find.text('Lage-Inhalt'), findsOneWidget);
    },
  );

  testWidgets('AC2: Permission.crew sees only nav-lage, no Verwaltung', (
    tester,
  ) async {
    await _pump(tester, permission: Permission.crew);

    expect(find.byKey(const Key('nav-lage')), findsOneWidget);
    for (final key in _existingNavKeys) {
      expect(find.byKey(Key(key)), findsNothing);
    }
    expect(find.text('Verwaltung'), findsNothing);
  });

  testWidgets(
    'AC3: Permission.preparation additionally sees nav-einsaetze only',
    (tester) async {
      await _pump(tester, permission: Permission.preparation);

      expect(find.byKey(const Key('nav-lage')), findsOneWidget);
      expect(find.byKey(const Key('nav-einsaetze')), findsOneWidget);
      for (final key in _existingNavKeys.where((k) => k != 'nav-einsaetze')) {
        expect(find.byKey(Key(key)), findsNothing);
      }
      expect(find.text('Verwaltung'), findsNothing);
    },
  );

  testWidgets(
    'AC4: Permission.dispatch sees the Betriebsablauf entries, no Verwaltung',
    (tester) async {
      await _pump(tester, permission: Permission.dispatch);

      for (final key in [
        'nav-einsaetze',
        'nav-durchsagen',
        'nav-tagesablauf',
        'nav-schichten',
        'nav-bf-tage',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget);
      }
      for (final key in [
        'nav-fahrzeuge',
        'nav-persons',
        'nav-monitors',
        'nav-slides',
      ]) {
        expect(find.byKey(Key(key)), findsNothing);
      }
      expect(find.text('Verwaltung'), findsNothing);
    },
  );

  testWidgets('AC5: Permission.admin sees all ten nav-* keys + Verwaltung', (
    tester,
  ) async {
    await _pump(tester, permission: Permission.admin);

    expect(find.byKey(const Key('nav-lage')), findsOneWidget);
    for (final key in _existingNavKeys) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.text('Verwaltung'), findsOneWidget);
  });

  testWidgets('AC7: exactly one entry is active, with primary indicator', (
    tester,
  ) async {
    await _pump(tester, permission: Permission.admin);

    final lageContainer = tester.widget<Container>(
      find.byKey(const Key('nav-lage')),
    );
    final decoration = lageContainer.decoration as BoxDecoration;
    expect(decoration.color, isNotNull);

    final einsaetzeContainer = tester.widget<Container>(
      find.byKey(const Key('nav-einsaetze')),
    );
    final einsaetzeDecoration = einsaetzeContainer.decoration as BoxDecoration;
    expect(einsaetzeDecoration.color, isNull);
  });

  testWidgets(
    'AC8: sidebar collapses to icons under 1280px, expands at/above it',
    (tester) async {
      await _pump(
        tester,
        permission: Permission.admin,
        size: const Size(1100, 900),
      );
      expect(find.byKey(const Key('nav-lage')), findsOneWidget);
      expect(find.text('Lage'), findsNothing);

      await _pump(
        tester,
        permission: Permission.admin,
        size: const Size(1440, 900),
      );
      expect(find.byKey(const Key('nav-lage')), findsOneWidget);
      expect(find.text('Lage'), findsOneWidget);
    },
  );

  testWidgets('AC9: logout triggers logout() and navigates to /admin/login', (
    tester,
  ) async {
    await _pump(tester, permission: Permission.admin);

    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();

    expect(find.text('Login-Screen'), findsOneWidget);
  });

  testWidgets(
    'AC10: footer shows displayName and permission.label',
    (tester) async {
      await _pump(tester, permission: Permission.admin);

      expect(find.textContaining('Max Mustermann'), findsOneWidget);
      expect(find.textContaining('Administrator'), findsOneWidget);
    },
  );

  testWidgets(
    'AC11: collapsed icon-only nav items keep a Tooltip with the German label',
    (tester) async {
      await _pump(
        tester,
        permission: Permission.admin,
        size: const Size(1100, 900),
      );

      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('nav-einsaetze')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, 'Einsätze');
    },
  );

  testWidgets(
    'AC12: connection-banner shown iff not live, on Lage and another screen',
    (tester) async {
      await _pump(
        tester,
        permission: Permission.admin,
        connection: ConnectionStatus.live,
      );
      expect(find.byKey(const Key('connection-banner')), findsNothing);

      // Fully unmount before re-pumping with a new ProviderScope: without
      // this, Flutter reuses the existing ProviderScope element/container
      // across pumpWidget() calls and the stale `live` StreamProvider
      // override never gets replaced by the new `reconnecting` one.
      await tester.pumpWidget(const SizedBox.shrink());

      await _pump(
        tester,
        permission: Permission.admin,
        connection: ConnectionStatus.reconnecting,
      );
      expect(find.byKey(const Key('connection-banner')), findsOneWidget);

      // Also on a non-Lage screen.
      await tester.tap(find.byKey(const Key('nav-einsaetze')));
      await tester.pumpAndSettle();
      expect(find.text('Einsätze-Screen'), findsOneWidget);
      expect(find.byKey(const Key('connection-banner')), findsOneWidget);
    },
  );

  testWidgets('AC13: icon assignment per nav-* key matches the table', (
    tester,
  ) async {
    await _pump(tester, permission: Permission.admin);

    Icon iconFor(String key) => tester.widget<Icon>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(Icon),
      ),
    );

    expect(iconFor('nav-lage').icon, Icons.home);
    expect(iconFor('nav-einsaetze').icon, Icons.local_fire_department);
    expect(iconFor('nav-durchsagen').icon, Icons.campaign);
    expect(iconFor('nav-tagesablauf').icon, Icons.event_note);
    expect(iconFor('nav-schichten').icon, Icons.schedule);
    expect(iconFor('nav-bf-tage').icon, Icons.calendar_month);
    expect(iconFor('nav-persons').icon, Icons.group);
    expect(iconFor('nav-fahrzeuge').icon, Icons.local_shipping);
    expect(iconFor('nav-monitors').icon, Icons.desktop_windows);
    expect(iconFor('nav-slides').icon, Icons.image);
  });

  testWidgets('clicking nav-fahrzeuge navigates to /admin/fahrzeuge', (
    tester,
  ) async {
    await _pump(tester, permission: Permission.admin);

    await tester.tap(find.byKey(const Key('nav-fahrzeuge')));
    await tester.pumpAndSettle();

    expect(find.text('Fahrzeuge-Screen'), findsOneWidget);
  });
}
