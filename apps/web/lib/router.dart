import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'monitor/local_storage_token_store.dart';
import 'monitor/monitor_session.dart';
import 'screens/bf_days_screen.dart';
import 'screens/incidents_screen.dart';
import 'screens/lage_screen.dart';
import 'screens/login_screen.dart';
import 'screens/monitor_screen.dart';
import 'screens/monitors_screen.dart';
import 'screens/persons_screen.dart';
import 'screens/shifts_screen.dart';
import 'screens/slides_screen.dart';
import 'screens/vehicles_screen.dart';

/// Bridges a Riverpod provider's changes into a [Listenable] that go_router's
/// `refreshListenable` can subscribe to, so route redirects re-evaluate
/// whenever [SessionState] changes.
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Ref ref) {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Shows a loading indicator while [SessionState] is still [SessionUnknown],
/// otherwise renders [child]. Used to gate the /admin screens so we never
/// flash the login screen or Lage screen before the session has restored.
class _SessionGate extends ConsumerWidget {
  const _SessionGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session is SessionUnknown) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/admin',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final isLoginRoute = state.matchedLocation == '/admin/login';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      switch (session) {
        case SessionUnknown():
          return null;
        case SessionSignedOut():
          if (isAdminRoute && !isLoginRoute) {
            return '/admin/login';
          }
          return null;
        case SessionSignedIn(person: final person):
          if (isLoginRoute) {
            return '/admin';
          }
          final isFahrzeugeRoute =
              state.matchedLocation == '/admin/fahrzeuge';
          final isPersonsRoute = state.matchedLocation == '/admin/persons';
          final isMonitorsRoute =
              state.matchedLocation == '/admin/monitors';
          final isBfTageRoute = state.matchedLocation == '/admin/bf-tage';
          final isSlidesRoute = state.matchedLocation == '/admin/slides';
          if ((isFahrzeugeRoute ||
                  isPersonsRoute ||
                  isMonitorsRoute ||
                  isSlidesRoute) &&
              person.permission != Permission.admin) {
            return '/admin';
          }
          if (isBfTageRoute &&
              person.permission != Permission.admin &&
              person.permission != Permission.dispatch) {
            return '/admin';
          }
          final isSchichtenRoute = state.matchedLocation == '/admin/schichten';
          if (isSchichtenRoute &&
              person.permission != Permission.admin &&
              person.permission != Permission.dispatch) {
            return '/admin';
          }
          final isEinsaetzeRoute = state.matchedLocation == '/admin/einsaetze';
          if (isEinsaetzeRoute && person.permission == Permission.crew) {
            return '/admin';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/admin',
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) =>
            const _SessionGate(child: LoginScreen()),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const _SessionGate(child: LageScreen()),
      ),
      GoRoute(
        path: '/admin/fahrzeuge',
        builder: (context, state) =>
            const _SessionGate(child: VehiclesScreen()),
      ),
      GoRoute(
        path: '/admin/persons',
        builder: (context, state) =>
            const _SessionGate(child: PersonsScreen()),
      ),
      GoRoute(
        path: '/admin/monitors',
        builder: (context, state) =>
            const _SessionGate(child: MonitorsScreen()),
      ),
      GoRoute(
        path: '/admin/bf-tage',
        builder: (context, state) =>
            const _SessionGate(child: BfDaysScreen()),
      ),
      GoRoute(
        path: '/admin/slides',
        builder: (context, state) =>
            const _SessionGate(child: SlidesScreen()),
      ),
      GoRoute(
        path: '/admin/schichten',
        builder: (context, state) =>
            const _SessionGate(child: ShiftsScreen()),
      ),
      GoRoute(
        path: '/admin/einsaetze',
        builder: (context, state) =>
            const _SessionGate(child: IncidentsScreen()),
      ),
      GoRoute(
        path: '/monitor',
        builder: (context, state) => ProviderScope(
          overrides: monitorProviderOverrides(
            tokenStore: LocalStorageTokenStore(),
          ),
          child: const MonitorScreen(),
        ),
      ),
    ],
  );
});
