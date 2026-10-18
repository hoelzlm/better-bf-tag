import 'dart:async';
import 'dart:io' show Platform;

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../alarm/alarm_sound.dart';
import '../push/push_service.dart';

/// Shared Testalarm widget (ADR 0021) used in both the Onboarding and the
/// Einstellungen screen: triggers `POST /me/device/test-alarm` via
/// [testAlarmRepositoryProvider] and shows the outcome. Also listens to
/// [PushService.onTestAlarmReceived] so a Testalarm push arriving while
/// the app is in the foreground shows a notice and (on Android) plays the
/// alarm Ton once, since FCM doesn't show a system notification there.
class TestAlarmPanel extends ConsumerStatefulWidget {
  const TestAlarmPanel({super.key});

  @override
  ConsumerState<TestAlarmPanel> createState() => _TestAlarmPanelState();
}

class _TestAlarmPanelState extends ConsumerState<TestAlarmPanel> {
  StreamSubscription<void>? _receivedSub;
  bool _busy = false;
  String? _resultText;
  bool _resultIsError = false;
  bool _showLockScreenHint = false;

  @override
  void initState() {
    super.initState();
    _receivedSub = ref
        .read(pushServiceProvider)
        .onTestAlarmReceived
        .listen((_) => unawaited(_onTestAlarmReceived()));
  }

  @override
  void dispose() {
    _receivedSub?.cancel();
    super.dispose();
  }

  Future<void> _onTestAlarmReceived() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testalarm empfangen')),
    );
    if (Platform.isAndroid) {
      final sound = ref.read(alarmSoundProvider);
      await sound.play();
      await Future<void>.delayed(const Duration(seconds: 5));
      if (mounted) {
        await sound.stop();
      }
    }
  }

  Future<void> _trigger(int delaySeconds) async {
    setState(() {
      _busy = true;
      _resultText = null;
      _showLockScreenHint = delaySeconds > 0;
    });
    try {
      final outcome = await ref
          .read(testAlarmRepositoryProvider)
          .trigger(delaySeconds: delaySeconds);
      if (!mounted) return;
      final (text, isError) = switch (outcome) {
        TestAlarmOutcome.delivered => (
            'Push zugestellt – hast du den Alarmton gehört?',
            false,
          ),
        TestAlarmOutcome.scheduled => (
            'Testalarm wird in $delaySeconds Sekunden gesendet.',
            false,
          ),
        TestAlarmOutcome.rejected ||
        TestAlarmOutcome.invalidToken => (
            'Push konnte nicht zugestellt werden.',
            true,
          ),
      };
      setState(() {
        _busy = false;
        _resultText = text;
        _resultIsError = isError;
      });
    } on TestAlarmException catch (error) {
      if (!mounted) return;
      final text = switch (error.code) {
        'no_push_token' => 'Push ist auf diesem Gerät nicht eingerichtet.',
        'test_alarm_cooldown' => 'Bitte kurz warten und erneut versuchen.',
        _ => 'Push konnte nicht zugestellt werden.',
      };
      setState(() {
        _busy = false;
        _resultText = text;
        _resultIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radii = Theme.of(context).extension<BftagRadii>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Testalarm', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'Löst einen echten Push mit Alarmton nur an dieses Gerät aus, '
          'ohne Einsatz.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const Key('test-alarm-now'),
              onPressed: _busy ? null : () => _trigger(0),
              child: const Text('Testalarm jetzt'),
            ),
            OutlinedButton(
              key: const Key('test-alarm-delayed'),
              onPressed: _busy ? null : () => _trigger(10),
              child: const Text('Testalarm in 10 Sekunden'),
            ),
          ],
        ),
        if (_showLockScreenHint)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Architect decision: "surfaceVariant box". `_buildTheme()`
                // (packages/core/lib/src/theme.dart) maps the design-token
                // `surfaceVariant` to `ColorScheme.surfaceContainer` (the
                // deprecated `ColorScheme.surfaceVariant` getter is not
                // wired to this design token and must stay unused) — this
                // is the correct token, not a literal-name match.
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(radii?.medium ?? 12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sperre jetzt den Bildschirm.',
                    key: const Key('test-alarm-lock-hint'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ),
        if (_resultText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _resultIsError
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(radii?.medium ?? 12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _resultIsError
                        ? Icons.warning_amber
                        : Icons.check_circle,
                    color: _resultIsError
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _resultText!,
                      key: const Key('test-alarm-result'),
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _resultIsError
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onPrimaryContainer,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
