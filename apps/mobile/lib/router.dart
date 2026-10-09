import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/my_vehicle_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/settings_screen.dart';

/// Bridges [PairedSessionController] changes into a [Listenable] that
/// go_router's `refreshListenable` can subscribe to, so route redirects
/// re-evaluate whenever [PairedSessionState] changes.
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Ref ref) {
    ref.listen<PairedSessionState>(pairedSessionControllerProvider, (
      previous,
      next,
    ) {
      notifyListeners();
    });
  }
}

/// Shows a loading indicator while [PairedSessionState] is still
/// [PairedUnknown] (before [PairedSessionController.restore] has
/// resolved), otherwise renders [child].
class _SessionGate extends ConsumerWidget {
  const _SessionGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(pairedSessionControllerProvider);
    if (session is PairedUnknown) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}

final mobileGoRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/pair',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = ref.read(pairedSessionControllerProvider);
      final isPairRoute = state.matchedLocation == '/pair';

      switch (session) {
        case PairedUnknown():
          return null;
        case Paired():
          return isPairRoute ? '/' : null;
        case PairedUnpaired():
        case PairedOffline():
          // PairedOffline has no fresh person data to show a Start
          // screen with (see paired_session.dart); treat it like
          // Unpaired for navigation and let the pairing screen's own
          // retry (future work) or a background `restore()` resolve it.
          return isPairRoute ? null : '/pair';
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const _SessionGate(child: MyVehicleScreen()),
      ),
      GoRoute(
        path: '/pair',
        builder: (context, state) =>
            const _SessionGate(child: PairingScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const _SessionGate(child: SettingsScreen()),
      ),
    ],
  );
});
