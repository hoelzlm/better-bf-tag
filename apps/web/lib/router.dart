import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/lage_screen.dart';
import 'screens/login_screen.dart';
import 'screens/monitor_placeholder_screen.dart';
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
          if (isFahrzeugeRoute && person.permission != Permission.admin) {
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
        path: '/monitor',
        builder: (context, state) => const MonitorPlaceholderScreen(),
      ),
    ],
  );
});
