import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/main.dart';
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

Future<void> _pumpAppAt(
  WidgetTester tester, {
  required SessionState session,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => _FakeSessionController(session),
        ),
      ],
      child: const BftagWebApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('SignedOut on /admin ends on the login screen', (tester) async {
    await _pumpAppAt(tester, session: const SessionSignedOut());

    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets('SignedIn on /admin shows the Lage screen', (tester) async {
    const person = Person(
      id: 'p1',
      displayName: 'Max Mustermann',
      personType: PersonType.supervisor,
      permission: Permission.dispatch,
    );
    await _pumpAppAt(
      tester,
      session: const SessionSignedIn(person, 'access-token'),
    );

    expect(find.text('Keine laufenden Einsätze'), findsOneWidget);
  });

  testWidgets('/monitor shows the monitor placeholder', (tester) async {
    await _pumpAppAt(tester, session: const SessionSignedOut());

    final context = tester.element(find.byKey(const Key('login-submit')));
    context.go('/monitor');
    await tester.pumpAndSettle();

    expect(find.text('Monitor – noch nicht gekoppelt'), findsOneWidget);
  });
}
