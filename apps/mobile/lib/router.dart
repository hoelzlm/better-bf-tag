import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'onboarding/onboarding_screen.dart';
import 'onboarding/onboarding_store.dart';
import 'screens/alarm_screen.dart';
import 'screens/incident_detail_screen.dart';
import 'screens/incidents_screen.dart';
import 'screens/my_vehicle_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/settings_screen.dart';

/// Bridges [PairedSessionController] and [onboardingCompletedProvider]
/// changes into a [Listenable] that go_router's `refreshListenable` can
/// subscribe to, so route redirects re-evaluate whenever either changes.
/// Also kicks off [OnboardingCompletedNotifier.load] once the session is
/// [Paired] (on construction, or on the first such transition), so the
/// redirect has a loaded value as soon as possible -- while it's still
/// `null`, the redirect must not act on it (ADR 0021).
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Ref ref) {
    ref.listen<PairedSessionState>(pairedSessionControllerProvider, (
      previous,
      next,
    ) {
      if (next is Paired) {
        _ensureOnboardingLoaded(ref);
      }
      notifyListeners();
    });
    ref.listen<bool?>(onboardingCompletedProvider, (previous, next) {
      notifyListeners();
    });
    if (ref.read(pairedSessionControllerProvider) is Paired) {
      _ensureOnboardingLoaded(ref);
    }
  }

  void _ensureOnboardingLoaded(Ref ref) {
    if (ref.read(onboardingCompletedProvider) == null) {
      ref.read(onboardingCompletedProvider.notifier).load();
    }
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
      final isHomeRoute = state.matchedLocation == '/';

      switch (session) {
        case PairedUnknown():
          return null;
        case Paired():
          final onboardingCompleted = ref.read(onboardingCompletedProvider);
          // ADR 0021: redirect to /onboarding only once the flag is
          // loaded (not null) and explicitly false, and only from '/'
          // or '/pair' -- never from /alarm/:id, /einsaetze*, /settings
          // or /onboarding itself. While still loading (null), fall
          // through to the existing "/pair" -> "/" redirect below.
          if (onboardingCompleted == false && (isPairRoute || isHomeRoute)) {
            return '/onboarding';
          }
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
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            const _SessionGate(child: OnboardingScreen()),
      ),
      GoRoute(
        path: '/einsaetze',
        builder: (context, state) =>
            const _SessionGate(child: IncidentsScreen()),
      ),
      GoRoute(
        path: '/einsaetze/:id',
        builder: (context, state) => _SessionGate(
          child: IncidentDetailScreen(incidentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/alarm/:alarmId',
        builder: (context, state) => _SessionGate(
          child: AlarmScreen(alarmId: state.pathParameters['alarmId']!),
        ),
      ),
    ],
  );
});
