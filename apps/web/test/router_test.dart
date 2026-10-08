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

  @override
  Future<void> restore() async {
    // No-op: router_test exercises the router directly off a fixed initial
    // state; restore() calling out to the real backend is covered in
    // login_test.dart via a different fake.
  }
}

class _FakeVehicleAdminRepository implements VehicleAdminRepository {
  @override
  Future<List<Vehicle>> listAll() async => const [];

  @override
  Future<Vehicle> create({
    required String callSign,
    required String shortName,
    required String type,
  }) =>
      throw UnimplementedError();

  @override
  Future<Vehicle> update(
    String id, {
    String? callSign,
    String? shortName,
    String? type,
    bool? active,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> reorder(List<String> vehicleIds) => throw UnimplementedError();

  @override
  Future<void> setStatus(String id, int status) => throw UnimplementedError();
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
        // LageScreen embeds VehicleStatusBar, which otherwise pulls in the
        // real RealtimeClient (and a real WebSocket connection attempt).
        // These tests only exercise routing/redirects, so stub it out.
        vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
        realtimeConnectionProvider.overrideWith(
          (ref) => Stream.value(ConnectionStatus.live),
        ),
        vehicleAdminRepositoryProvider.overrideWithValue(
          _FakeVehicleAdminRepository(),
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

  testWidgets(
    'non-admin navigating to /admin/fahrzeuge is redirected to /admin',
    (tester) async {
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

      final context = tester.element(find.text('Keine laufenden Einsätze'));
      context.go('/admin/fahrzeuge');
      await tester.pumpAndSettle();

      expect(find.text('Keine laufenden Einsätze'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    },
  );

  testWidgets(
    'the Fahrzeuge nav entry is hidden for non-admin permissions',
    (tester) async {
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

      expect(find.byKey(const Key('nav-fahrzeuge')), findsNothing);
    },
  );

  testWidgets(
    'admin can navigate to /admin/fahrzeuge via the nav entry',
    (tester) async {
      const person = Person(
        id: 'p1',
        displayName: 'Max Mustermann',
        personType: PersonType.supervisor,
        permission: Permission.admin,
      );
      await _pumpAppAt(
        tester,
        session: const SessionSignedIn(person, 'access-token'),
      );

      expect(find.byKey(const Key('nav-fahrzeuge')), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-fahrzeuge')));
      await tester.pumpAndSettle();

      expect(find.text('Fahrzeuge'), findsOneWidget);
    },
  );
}
