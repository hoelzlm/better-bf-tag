import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Start screen for `/`: shown once the device is paired. Starts the
/// realtime connection (so `session.revoked` is received) as a side
/// effect of watching [pairedRealtimeClientProvider].
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pairedRealtimeClientProvider);

    final session = ref.watch(pairedSessionControllerProvider);
    final displayName = session is Paired ? session.person.displayName : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo $displayName'),
        actions: [
          IconButton(
            key: const Key('settings'),
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: const Center(child: Text('Willkommen beim BF-Tag!')),
    );
  }
}
