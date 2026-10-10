import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'device_settings.dart';
import 'manufacturer_hints.dart';
import 'onboarding_store.dart';
import 'test_alarm_panel.dart';
import '../push/push_service.dart';

/// Whether the device is iOS, for picking Onboarding steps (ADR 0021).
/// Defaults to [Platform.isIOS]; tests override this provider to exercise
/// both the Android and the iOS step list without depending on the host
/// platform `flutter test` runs on.
final onboardingPlatformProvider = Provider<bool>((ref) => Platform.isIOS);

enum _OnboardingStep { notifications, dnd, battery, mute, testAlarm, done }

/// Guides the Person through the system settings an alarm depends on and
/// lets them trigger a Testalarm (ADR 0021). Reachable at `/onboarding`
/// right after pairing (while `onboardingCompletedProvider` is `false`)
/// and again later from Einstellungen ("Einrichtung erneut öffnen").
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  int _stepIndex = 0;
  bool _loaded = false;
  bool _notificationsEnabled = false;
  bool _notificationsAllowTried = false;
  bool _bypassesDnd = false;
  bool _batteryOptimizationIgnored = false;
  String _manufacturer = 'unknown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshStatuses());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshStatuses());
    }
  }

  Future<void> _refreshStatuses() async {
    final settings = ref.read(deviceSettingsProvider);
    final notificationsEnabled = await settings.notificationsEnabled();
    final bypassesDnd = await settings.bypassesDnd();
    final batteryOptimizationIgnored =
        await settings.batteryOptimizationIgnored();
    final manufacturer = await settings.manufacturer();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _bypassesDnd = bypassesDnd;
      _batteryOptimizationIgnored = batteryOptimizationIgnored;
      _manufacturer = manufacturer;
      _loaded = true;
    });
  }

  List<_OnboardingStep> _steps(bool isIos) {
    return [
      _OnboardingStep.notifications,
      _OnboardingStep.dnd,
      if (!isIos) _OnboardingStep.battery,
      if (isIos) _OnboardingStep.mute,
      _OnboardingStep.testAlarm,
      _OnboardingStep.done,
    ];
  }

  void _next(List<_OnboardingStep> steps) {
    if (_stepIndex < steps.length - 1) {
      setState(() => _stepIndex++);
    }
  }

  Future<void> _allowNotifications() async {
    setState(() => _notificationsAllowTried = true);
    await ref.read(pushServiceProvider).init();
    await _refreshStatuses();
  }

  Future<void> _finish() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIos = ref.watch(onboardingPlatformProvider);
    final steps = _steps(isIos);
    final stepIndex = _stepIndex >= steps.length ? steps.length - 1 : _stepIndex;
    final step = steps[stepIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Einrichtung')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStep(step, steps),
            ),
    );
  }

  Widget _buildStep(_OnboardingStep step, List<_OnboardingStep> steps) {
    switch (step) {
      case _OnboardingStep.notifications:
        return _StatusStep(
          statusKey: 'onboarding-status-notifications',
          ok: _notificationsEnabled,
          title: 'Benachrichtigungen erlauben',
          description:
              'Ohne Benachrichtigungen kann dich die App nicht alarmieren.',
          actions: [
            if (!_notificationsEnabled)
              FilledButton(
                key: const Key('onboarding-action-notifications-allow'),
                onPressed: _allowNotifications,
                child: const Text('Erlauben'),
              ),
            if (!_notificationsEnabled && _notificationsAllowTried)
              OutlinedButton(
                key: const Key('onboarding-action-notifications-settings'),
                onPressed: () => ref
                    .read(deviceSettingsProvider)
                    .openNotificationSettings(),
                child: const Text('Einstellungen öffnen'),
              ),
          ],
          onNext: () => _next(steps),
        );
      case _OnboardingStep.dnd:
        return _StatusStep(
          statusKey: 'onboarding-status-dnd',
          ok: _bypassesDnd,
          title: 'Nicht stören umgehen',
          description: Platform.isIOS
              ? 'Aktiviere „Dringliche Mitteilungen“ (Time Sensitive) für '
                  'BF-Tag, damit der Alarmton auch bei aktiviertem Fokus '
                  'ertönt.'
              : 'Erlaube dem Kanal „Alarm“, „Nicht stören“ zu ignorieren bzw. '
                  'zu überschreiben, damit der Alarmton immer ertönt.',
          actions: [
            OutlinedButton(
              key: const Key('onboarding-action-dnd-settings'),
              onPressed: () =>
                  ref.read(deviceSettingsProvider).openDndSettings(),
              child: const Text('Einstellungen öffnen'),
            ),
          ],
          onNext: () => _next(steps),
        );
      case _OnboardingStep.battery:
        return _StatusStep(
          statusKey: 'onboarding-status-battery',
          ok: _batteryOptimizationIgnored,
          title: 'Akku-Optimierung',
          description: 'Schließe BF-Tag von der Akku-Optimierung aus, '
              'damit Alarme auch im Hintergrund ankommen.',
          extra: Text(
            batteryHintFor(_manufacturer),
            key: const Key('onboarding-battery-hint'),
          ),
          actions: [
            FilledButton(
              key: const Key('onboarding-action-battery-request'),
              onPressed: () async {
                await ref
                    .read(deviceSettingsProvider)
                    .requestIgnoreBatteryOptimization();
                await _refreshStatuses();
              },
              child: const Text('Ausnahme aktivieren'),
            ),
          ],
          onNext: () => _next(steps),
        );
      case _OnboardingStep.mute:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nicht stumm schalten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Schalte dein Handy beim BF-Tag nicht stumm (Stummschalter / '
              'Action Button) – sonst hörst du den Alarm nicht.',
              key: Key('onboarding-mute-hint'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('onboarding-next'),
                onPressed: () => _next(steps),
                child: const Text('Weiter'),
              ),
            ),
          ],
        );
      case _OnboardingStep.testAlarm:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const TestAlarmPanel(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('onboarding-next'),
                onPressed: () => _next(steps),
                child: const Text('Weiter'),
              ),
            ),
          ],
        );
      case _OnboardingStep.done:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fertig', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Die Einrichtung ist abgeschlossen.'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('onboarding-finish'),
                onPressed: _finish,
                child: const Text('Fertig'),
              ),
            ),
          ],
        );
    }
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.statusKey,
    required this.ok,
    required this.title,
    required this.description,
    required this.actions,
    required this.onNext,
    this.extra,
  });

  final String statusKey;
  final bool ok;
  final String title;
  final String description;
  final List<Widget> actions;
  final VoidCallback onNext;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.cancel,
              color: ok ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(ok ? '✓' : '✗', key: Key(statusKey)),
          ],
        ),
        const SizedBox(height: 8),
        Text(description),
        if (extra != null) ...[const SizedBox(height: 8), extra!],
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const Key('onboarding-next'),
            onPressed: onNext,
            child: const Text('Weiter'),
          ),
        ),
      ],
    );
  }
}
