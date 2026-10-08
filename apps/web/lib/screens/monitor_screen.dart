import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitor/monitor_platform.dart';
import '../monitor/monitor_session.dart';
import 'monitor_pairing_screen.dart';
import 'monitor_standby_screen.dart';

/// Entry point for `/monitor` (ADR 0012, "Monitor im Browser"): shows the
/// full-screen activation overlay on every start, then the pairing or
/// standby screen depending on [MonitorSessionState]. Wrapped in its own
/// `ProviderScope` (see [monitorProviderOverrides]) by the router, so the
/// admin web session never interferes.
class MonitorScreen extends ConsumerStatefulWidget {
  const MonitorScreen({super.key});

  @override
  ConsumerState<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends ConsumerState<MonitorScreen>
    with WidgetsBindingObserver {
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () => ref.read(monitorSessionControllerProvider.notifier).restore(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_activated && state == AppLifecycleState.resumed) {
      unawaited(ref.read(monitorPlatformProvider).enableWakeLock());
    }
  }

  Future<void> _activate() async {
    final platform = ref.read(monitorPlatformProvider);
    await platform.enableWakeLock();
    await platform.requestFullscreen();
    if (!mounted) return;
    setState(() => _activated = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_activated) {
      return _ActivationOverlay(onTap: _activate);
    }
    final session = ref.watch(monitorSessionControllerProvider);
    return switch (session) {
      MonitorPaired() => const MonitorStandbyScreen(),
      MonitorUnpaired(revoked: final revoked) =>
        MonitorPairingScreen(revokedHint: revoked),
      MonitorOffline() => const _MonitorConnectingScreen(),
      MonitorUnknown() => const _MonitorConnectingScreen(),
    };
  }
}

class _ActivationOverlay extends StatelessWidget {
  const _ActivationOverlay({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: InkWell(
        key: const Key('monitor-activation-overlay'),
        onTap: onTap,
        child: const Center(
          child: Text(
            'Zum Aktivieren tippen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Shown while [MonitorSessionController.restore] is still resolving
/// ([MonitorUnknown]), or on a network error while a stored token is kept
/// for retry ([MonitorOffline]) -- neither has enough data for the standby
/// screen (no confirmed monitor name) nor should fall back to pairing
/// (a stored session might still be valid).
class _MonitorConnectingScreen extends StatelessWidget {
  const _MonitorConnectingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Verbinde …',
          key: Key('monitor-connecting'),
          style: TextStyle(color: Colors.white70, fontSize: 24),
        ),
      ),
    );
  }
}
