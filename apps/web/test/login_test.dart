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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_FakeSessionController.new),
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
}
