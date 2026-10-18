import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../onboarding/onboarding_store.dart';
import '../onboarding/test_alarm_panel.dart';

/// Settings screen for `/settings`: lets the person reopen the
/// Onboarding, send a Testalarm (ADR 0021), and log this device out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    // "Gerät abmelden" is destructive (Grundprinzip 1, Designsystem §5.1):
    // only the confirming dialog button gets the `alarm` style, title and
    // body text stay neutral (§5.6).
    final alarmTheme = Theme.of(context).extension<BftagAlarmColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gerät abmelden'),
        content: const Text(
          'Dieses Gerät wird abgemeldet und muss erneut gekoppelt werden.',
        ),
        actions: [
          TextButton(
            key: const Key('logout-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('logout-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: alarmTheme.alarm,
              foregroundColor: alarmTheme.onAlarm,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(pairedSessionControllerProvider.notifier).logout();
      // ADR 0021: the next Person to pair this device should go through
      // the Onboarding again.
      await ref.read(onboardingCompletedProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmTheme = Theme.of(context).extension<BftagAlarmColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              key: const Key('reopen-onboarding'),
              onPressed: () => context.push('/onboarding'),
              child: const Text('Einrichtung erneut öffnen'),
            ),
            const SizedBox(height: 24),
            const TestAlarmPanel(),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('logout-button'),
              style: FilledButton.styleFrom(
                backgroundColor: alarmTheme.alarm,
                foregroundColor: alarmTheme.onAlarm,
              ),
              onPressed: () => _confirmLogout(context, ref),
              child: const Text('Gerät abmelden'),
            ),
          ],
        ),
      ),
    );
  }
}
