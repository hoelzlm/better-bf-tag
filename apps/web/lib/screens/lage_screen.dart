import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lage'),
        actions: [
          if (permission == Permission.admin) ...[
            IconButton(
              key: const Key('nav-fahrzeuge'),
              icon: const Icon(Icons.fire_truck),
              tooltip: 'Fahrzeuge',
              onPressed: () => context.go('/admin/fahrzeuge'),
            ),
            IconButton(
              key: const Key('nav-persons'),
              icon: const Icon(Icons.people),
              tooltip: 'Personen',
              onPressed: () => context.go('/admin/persons'),
            ),
            IconButton(
              key: const Key('nav-monitors'),
              icon: const Icon(Icons.tv),
              tooltip: 'Monitore',
              onPressed: () => context.go('/admin/monitors'),
            ),
          ],
          if (displayName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text('$displayName ($permissionLabel)'),
              ),
            ),
          IconButton(
            key: const Key('logout'),
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
          Expanded(
            child: Center(child: Text('Keine laufenden Einsätze')),
          ),
        ],
      ),
    );
  }
}
