import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/missed_alarms_section.dart';
import '../widgets/running_incidents_section.dart';
import '../widgets/scheduled_alarms_section.dart';
import '../widgets/vehicle_status_bar.dart';

/// Lage-Screen for `/admin`: Startseite der Leitstelle.
class LageScreen extends ConsumerWidget {
  const LageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final displayName = switch (session) {
      SessionSignedIn(person: final person) => person.displayName,
      _ => '',
    };
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final permissionLabel = permission?.label ?? '';

    // Compact so the growing number of /admin/* nav entries keeps fitting
    // the AppBar's trailing area (which doesn't scroll/wrap on overflow).
    const navButtonStyle = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lage'),
        actions: [
          if (permission == Permission.preparation ||
              permission == Permission.dispatch ||
              permission == Permission.admin)
            IconButton(
              key: const Key('nav-einsaetze'),
              style: navButtonStyle,
              icon: const Icon(Icons.local_fire_department),
              tooltip: 'Einsätze',
              onPressed: () => context.go('/admin/einsaetze'),
            ),
          if (permission == Permission.dispatch || permission == Permission.admin)
            IconButton(
              key: const Key('nav-schichten'),
              style: navButtonStyle,
              icon: const Icon(Icons.schedule),
              tooltip: 'Schichten',
              onPressed: () => context.go('/admin/schichten'),
            ),
          if (permission == Permission.dispatch || permission == Permission.admin)
            IconButton(
              key: const Key('nav-bf-tage'),
              style: navButtonStyle,
              icon: const Icon(Icons.event),
              tooltip: 'BF-Tage',
              onPressed: () => context.go('/admin/bf-tage'),
            ),
          if (permission == Permission.admin) ...[
            IconButton(
              key: const Key('nav-fahrzeuge'),
              style: navButtonStyle,
              icon: const Icon(Icons.fire_truck),
              tooltip: 'Fahrzeuge',
              onPressed: () => context.go('/admin/fahrzeuge'),
            ),
            IconButton(
              key: const Key('nav-persons'),
              style: navButtonStyle,
              icon: const Icon(Icons.people),
              tooltip: 'Personen',
              onPressed: () => context.go('/admin/persons'),
            ),
            IconButton(
              key: const Key('nav-monitors'),
              style: navButtonStyle,
              icon: const Icon(Icons.tv),
              tooltip: 'Monitore',
              onPressed: () => context.go('/admin/monitors'),
            ),
            IconButton(
              key: const Key('nav-slides'),
              style: navButtonStyle,
              icon: const Icon(Icons.slideshow),
              tooltip: 'Folien',
              onPressed: () => context.go('/admin/slides'),
            ),
          ],
          if (displayName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text('$displayName ($permissionLabel)'),
              ),
            ),
          IconButton(
            key: const Key('logout'),
            style: navButtonStyle,
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () {
              ref.read(sessionControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          VehicleStatusBar(),
          MissedAlarmsSection(),
          ScheduledAlarmsSection(),
          Expanded(child: RunningIncidentsSection()),
        ],
      ),
    );
  }
}
