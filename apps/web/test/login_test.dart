import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _person = Person(
  id: 'p1',
  displayName: 'Max Mustermann',
  personType: PersonType.supervisor,
  permission: Permission.admin,
);

/// Fake [SessionController] simulating the backend without any network
/// calls: `admin`/`admin12345` succeeds, anything else is rejected with a
/// [LoginFailure], matching the real controller's contract.
class _FakeSessionController extends SessionController {
  @override
  SessionState build() => const SessionSignedOut();

  @override
  Future<void> restore() async {
    // No-op: tests set the initial state explicitly via build().
  }

  @override
  Future<void> login(String username, String password) async {
    if (username == 'admin' && password == 'admin12345') {
      state = const SessionSignedIn(_person, 'fake-access-token');
      return;
    }
    throw const LoginFailure('Benutzername oder Passwort falsch.');
  }

  @override
  Future<void> logout() async {
    state = const SessionSignedOut();
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  // The AppBar's nav-entry row doesn't scroll/wrap on overflow (see
  // lage_screen.dart); admin now has enough entries that the default
  // 800px test window overflows.
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_FakeSessionController.new),
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
      child: const BftagWebApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invalid login shows the error text', (tester) async {
    await _pumpApp(tester);

    await tester.enterText(find.byKey(const Key('login-username')), 'admin');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Benutzername oder Passwort falsch.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets(
    'valid login navigates to the Lage and shows no active deployments',
    (tester) async {
      await _pumpApp(tester);

      await tester.enterText(
        find.byKey(const Key('login-username')),
        'admin',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'admin12345',
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Keine laufenden Einsätze'), findsOneWidget);

      await tester.tap(find.byKey(const Key('logout')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-submit')), findsOneWidget);
    },
  );

  testWidgets('Enter key in the password field submits the form',
      (tester) async {
    await _pumpApp(tester);

    await tester.enterText(find.byKey(const Key('login-username')), 'admin');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'admin12345',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Keine laufenden Einsätze'), findsOneWidget);
  });

  testWidgets(
    'AC5 (web-login.md): the login screen renders no sidebar/nav-* keys',
    (tester) async {
      await _pumpApp(tester);

      // Login form itself is present...
      expect(find.byKey(const Key('login-username')), findsOneWidget);
      // ...but none of the AdminShell sidebar's nav-* keys (web-navigation.md
      // §7) are rendered on this route, since AdminShell only wraps
      // signed-in /admin/* routes (router.dart's ShellRoute excludes
      // /admin/login).
      for (final key in [
        'nav-lage',
        'nav-einsaetze',
        'nav-schichten',
        'nav-durchsagen',
        'nav-tagesablauf',
        'nav-bf-tage',
        'nav-fahrzeuge',
        'nav-persons',
        'nav-monitors',
        'nav-slides',
      ]) {
        expect(find.byKey(Key(key)), findsNothing);
      }
      // 'logout' lives in the sidebar footer only; absent on /admin/login.
      expect(find.byKey(const Key('logout')), findsNothing);
    },
  );
}
