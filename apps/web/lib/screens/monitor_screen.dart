import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitor/alarm_sound.dart';
import '../monitor/monitor_platform.dart';
import '../monitor/monitor_session.dart';
import 'monitor_incident_screen.dart';
import 'monitor_pairing_screen.dart';
import 'monitor_standby_screen.dart';

/// How long the Einsatzansicht stays on one Einsatz before rotating to the
/// next (ADR 0017, "Anzeige"), when several Einsätze have an Alarmierung.
const _incidentRotationInterval = Duration(seconds: 15);

/// Entry point for `/monitor` (ADR 0012, "Monitor im Browser"): shows the
/// full-screen activation overlay on every start, then the pairing,
/// standby, or Einsatzansicht screen depending on [MonitorSessionState]
/// and whether there is a running Einsatz with an Alarmierung (ADR 0017).
/// Wrapped in its own `ProviderScope` (see [monitorProviderOverrides]) by
/// the router, so the admin web session never interferes.
class MonitorScreen extends ConsumerStatefulWidget {
  const MonitorScreen({super.key});

  @override
  ConsumerState<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends ConsumerState<MonitorScreen>
    with WidgetsBindingObserver {
  bool _activated = false;
  Timer? _rotationTimer;
  String? _shownIncidentId;

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
    _rotationTimer?.cancel();
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
    // Browser autoplay policy: this tap is a genuine user gesture, so it
    // can unlock audio playback for the rest of the session (ADR 0017).
    unawaited(ref.read(alarmSoundProvider).unlock());
    if (!mounted) return;
    setState(() => _activated = true);
  }

  List<Incident> _incidentsWithAlarms(
    List<Incident> incidents,
    List<Alarm> alarms,
  ) {
    final incidentIdsWithAlarms = alarms.map((a) => a.incidentId).toSet();
    final withAlarms = incidents
        .where((incident) => incidentIdsWithAlarms.contains(incident.id))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return withAlarms;
  }

  /// Arms a one-shot timer for the next rotation; re-armed from [build]
  /// once it fires (so it never resets on unrelated rebuilds while
  /// running -- only [_rotationTimer] being `null` triggers a new one).
  void _scheduleRotation() {
    _rotationTimer = Timer(_incidentRotationInterval, () {
      if (!mounted) return;
      final incidents =
          ref.read(incidentsProvider).valueOrNull ?? const <Incident>[];
      final alarms = ref.read(alarmsProvider).valueOrNull ?? const <Alarm>[];
      final candidates = _incidentsWithAlarms(incidents, alarms);
      if (candidates.isEmpty) {
        setState(() {
          _shownIncidentId = null;
          _rotationTimer = null;
        });
        return;
      }
      final currentIndex =
          candidates.indexWhere((i) => i.id == _shownIncidentId);
      final nextIndex =
          currentIndex == -1 ? 0 : (currentIndex + 1) % candidates.length;
      setState(() {
        _shownIncidentId = candidates[nextIndex].id;
        _rotationTimer = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_activated) {
      return _ActivationOverlay(onTap: _activate);
    }
    final session = ref.watch(monitorSessionControllerProvider);
    if (session is! MonitorPaired) {
      return switch (session) {
        MonitorUnpaired(revoked: final revoked) =>
          MonitorPairingScreen(revokedHint: revoked),
        _ => const _MonitorConnectingScreen(),
      };
    }

    // Every live `alarm.triggered` (never snapshot content, ADR 0017)
    // plays the gong and jumps the Einsatzansicht to that Einsatz.
    ref.listen(liveAlarmTriggeredProvider, (previous, next) {
      final alarm = next.valueOrNull;
      if (alarm == null) return;
      unawaited(ref.read(alarmSoundProvider).play());
      setState(() => _shownIncidentId = alarm.incidentId);
    });

    final incidents =
        ref.watch(incidentsProvider).valueOrNull ?? const <Incident>[];
    final alarms = ref.watch(alarmsProvider).valueOrNull ?? const <Alarm>[];
    final candidates = _incidentsWithAlarms(incidents, alarms);

    if (candidates.isEmpty) {
      _shownIncidentId = null;
      _rotationTimer?.cancel();
      _rotationTimer = null;
      return const MonitorStandbyScreen();
    }

    final stillValid = candidates.any((i) => i.id == _shownIncidentId);
    if (!stillValid) {
      _shownIncidentId = candidates.first.id;
    }

    if (candidates.length < 2) {
      _rotationTimer?.cancel();
      _rotationTimer = null;
    } else if (_rotationTimer == null) {
      _scheduleRotation();
    }

    return MonitorIncidentScreen(incidentId: _shownIncidentId!);
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
