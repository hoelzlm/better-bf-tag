import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lage'),
        actions: [
          if (displayName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(displayName)),
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
      body: const Center(child: Text('Keine laufenden Einsätze')),
    );
  }
}
