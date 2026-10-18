import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitor/alarm_sound.dart';
import '../monitor/announcement_banner.dart';
import '../monitor/monitor_platform.dart';
import '../monitor/monitor_session.dart';
import 'monitor_alarm_screen.dart';
import 'monitor_incident_screen.dart';
import 'monitor_pairing_screen.dart';
import 'monitor_standby_screen.dart';

/// How long the Einsatzansicht stays on one Einsatz before rotating to the
/// next (ADR 0017, "Anzeige"), when several Einsätze have an Alarmierung.
const _incidentRotationInterval = Duration(seconds: 15);

/// How long the loud, full-surface Alarmzustand (`monitor-alarm.md`) is
/// shown after a live `alarm.triggered`, before automatically falling
/// back to the calmer `MonitorIncidentScreen` (concept §5 "Anzeigedauer").
const _alarmFlashDuration = Duration(seconds: 20);

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
  Announcement? _bannerAnnouncement;
  Timer? _bannerTimer;

  /// The triggering `Alarm` of the currently running loud Alarmzustand
  /// phase (concept §5 "Lebenszyklus"), or `null` outside of it. Only a
  /// live `alarm.triggered` ever sets this -- never a snapshot alarm.
  Alarm? _activeAlarm;
  Timer? _alarmTimer;

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
    _bannerTimer?.cancel();
    _alarmTimer?.cancel();
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
    final withAlarms =
        incidents
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
      final currentIndex = candidates.indexWhere(
        (i) => i.id == _shownIncidentId,
      );
      final nextIndex = currentIndex == -1
          ? 0
          : (currentIndex + 1) % candidates.length;
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
        MonitorUnpaired(revoked: final revoked) => MonitorPairingScreen(
          revokedHint: revoked,
        ),
        _ => const _MonitorConnectingScreen(),
      };
    }

    // Every live `alarm.triggered` (never snapshot content, ADR 0017)
    // plays the gong, jumps to that Einsatz, and starts (or restarts,
    // concept §4 "Zwei/mehrere alarm.triggered ... hintereinander") the
    // loud 20-s Alarmzustand phase -- pausing the Einsatzansicht rotation
    // entirely while it runs (concept §4/§5, AC9/AC12).
    ref.listen(liveAlarmTriggeredProvider, (previous, next) {
      final alarm = next.valueOrNull;
      if (alarm == null) return;
      unawaited(ref.read(alarmSoundProvider).play());
      _rotationTimer?.cancel();
      _rotationTimer = null;
      _alarmTimer?.cancel();
      _alarmTimer = Timer(_alarmFlashDuration, () {
        if (!mounted) return;
        setState(() => _activeAlarm = null);
      });
      setState(() {
        _shownIncidentId = alarm.incidentId;
        _activeAlarm = alarm;
      });
    });

    final incidents =
        ref.watch(incidentsProvider).valueOrNull ?? const <Incident>[];
    final alarms = ref.watch(alarmsProvider).valueOrNull ?? const <Alarm>[];
    final candidates = _incidentsWithAlarms(incidents, alarms);

    // AC11: the Einsatz currently shown in the loud Alarmzustand was
    // closed while the 20-s timer was still running -- cancel it
    // immediately instead of waiting it out (concept §4 "Der Einsatz
    // wird geschlossen").
    final activeAlarm = _activeAlarm;
    if (activeAlarm != null &&
        !candidates.any((i) => i.id == activeAlarm.incidentId)) {
      _alarmTimer?.cancel();
      _alarmTimer = null;
      _activeAlarm = null;
    }

    // A live `announcement.created` (never snapshot content, ADR 0024)
    // starts/replaces the standby banner timer -- but only while the
    // Einsatzansicht has no candidates to show: an Einsatz always has
    // Vorrang, and a Durchsage received while one is running is never
    // caught up on later.
    ref.listen(announcementCreatedProvider, (previous, next) {
      final announcement = next.valueOrNull;
      if (announcement == null) return;
      if (candidates.isNotEmpty) return;
      _bannerTimer?.cancel();
      setState(() => _bannerAnnouncement = announcement);
      _bannerTimer = Timer(announcementBannerDuration, () {
        if (!mounted) return;
        setState(() => _bannerAnnouncement = null);
      });
    });

    // A deleted Durchsage (ADR 0024) hides the banner immediately, even
    // mid-timer, if it's the one currently shown.
    ref.listen(announcementsProvider, (previous, next) {
      final list = next.valueOrNull;
      final current = _bannerAnnouncement;
      if (list == null || current == null) return;
      if (!list.any((a) => a.id == current.id)) {
        _bannerTimer?.cancel();
        _bannerTimer = null;
        setState(() => _bannerAnnouncement = null);
      }
    });

    if (candidates.isEmpty) {
      _shownIncidentId = null;
      _rotationTimer?.cancel();
      _rotationTimer = null;
      _alarmTimer?.cancel();
      _alarmTimer = null;
      _activeAlarm = null;
      return MonitorStandbyScreen(liveBanner: _bannerAnnouncement);
    }

    // The Einsatzansicht has Vorrang: drop any pending banner state so it
    // doesn't reappear once the Einsatz ends.
    if (_bannerAnnouncement != null || _bannerTimer != null) {
      _bannerTimer?.cancel();
      _bannerTimer = null;
      _bannerAnnouncement = null;
    }

    final stillValid = candidates.any((i) => i.id == _shownIncidentId);
    if (!stillValid) {
      _shownIncidentId = candidates.first.id;
    }

    // AC1/AC12: while the loud Alarmzustand is active, show it exclusively
    // for this Einsatz, and the 15-s rotation stays paused.
    if (_activeAlarm != null) {
      _rotationTimer?.cancel();
      _rotationTimer = null;
      return MonitorAlarmScreen(alarm: _activeAlarm!);
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
    // Concept §3.1: this is the one surface of the whole app that is
    // deliberately rendered *before* the theme is relevant -- pure black,
    // not the `surface` token -- since it must work even if no
    // Font/Theme has loaded yet.
    return Scaffold(
      backgroundColor: Colors.black,
      body: InkWell(
        key: const Key('monitor-activation-overlay'),
        onTap: onTap,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 96, color: Colors.white),
              SizedBox(height: 32),
              Text(
                'Zum Aktivieren tippen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Aktiviert Vollbild und Ton für Alarmdurchsagen.',
                style: TextStyle(color: Colors.white70, fontSize: 28),
                textAlign: TextAlign.center,
              ),
            ],
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
/// (a stored session might still be valid). Concept §4: both states show
/// the exact same text -- a unified status is deliberately preferred over
/// distinguishing "connecting" from "lost connection" here, since an
/// unattended device needs no different reaction to either.
class _MonitorConnectingScreen extends StatelessWidget {
  const _MonitorConnectingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>()!;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 96,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Verbinde …',
              key: const Key('monitor-connecting'),
              style: monitorStyles.headline.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
