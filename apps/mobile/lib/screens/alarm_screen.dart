import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../alarm/alarm_sound.dart';
import '../alarm/pending_alarm.dart';
import '../map/incident_location_card.dart';
import '../map/station_provider.dart';

Incident? _findIncident(List<Incident> incidents, String id) {
  for (final incident in incidents) {
    if (incident.id == id) return incident;
  }
  return null;
}

Alarm? _findAlarm(List<Alarm> alarms, String id) {
  for (final alarm in alarms) {
    if (alarm.id == id) return alarm;
  }
  return null;
}

Vehicle? _findVehicle(List<Vehicle> vehicles, String id) {
  for (final vehicle in vehicles) {
    if (vehicle.id == id) return vehicle;
  }
  return null;
}

/// Icon for the three possible `alarmSequenceLabel(...)` results (concept
/// `app-alarm.md` §3, §4): Erstalarm/Nachalarmierung/Alarmierung are NEVER
/// distinguished by a different red tone (Designsystem §5.11) -- only by
/// label text + this icon, all from the same "bell" family.
IconData _alarmSequenceIcon(String label) {
  if (label == 'Erstalarm') return Icons.notifications_active_outlined;
  if (label.contains('Nachalarmierung')) return Icons.add_alert_outlined;
  return Icons.notifications_outlined;
}

/// Full-screen Alarm-Vollbild for route `/alarm/:alarmId` (ADR 0017, "App
/// im Vordergrund"): shows the Alarmierung and lets the signed-in Person
/// quittieren via the big "Quittieren" button. Shown and dismissed by
/// `AlarmNavigationListener`, which also decides whether the Ton plays
/// (only for a live `alarm.triggered`, never for one found via the
/// snapshot).
///
/// Closes itself (and stops the Ton) once this alarm is no longer the
/// signed-in Person's pending one -- whether because it was acknowledged
/// (here or on another device) or its Einsatz left `running`.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.alarmId});

  final String alarmId;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  bool _acknowledging = false;
  bool _closed = false;

  void _closeSelf() {
    if (_closed) return;
    _closed = true;
    unawaited(ref.read(alarmSoundProvider).stop());
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _acknowledge() async {
    if (_acknowledging || _closed) return;
    setState(() => _acknowledging = true);
    try {
      await ref.read(alarmRepositoryProvider).acknowledge(widget.alarmId);
      if (!mounted) return;
      _closeSelf();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quittierung fehlgeschlagen. Bitte erneut versuchen.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _acknowledging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pairedSessionControllerProvider);
    final personId = session is Paired ? session.person.id : null;

    ref.listen<Alarm?>(myPendingAlarmProvider, (previous, next) {
      if (next?.id != widget.alarmId) {
        _closeSelf();
      }
    });

    final alarms = ref.watch(pairedAlarmsProvider).valueOrNull ?? const [];
    final alarm = _findAlarm(alarms, widget.alarmId);
    final theme = Theme.of(context);
    final palette = theme.extension<BftagAlarmColors>()!;

    return PopScope(
      canPop: false,
      child: _FadeInOnce(
        child: Scaffold(
          backgroundColor: palette.alarm,
          body: alarm == null
              ? Center(
                  child: CircularProgressIndicator(color: palette.onAlarm),
                )
              : _AlarmContent(
                  alarm: alarm,
                  personId: personId,
                  acknowledging: _acknowledging,
                  onAcknowledge: _acknowledge,
                ),
        ),
      ),
    );
  }
}

/// One-time, ≤250 ms fade-in of the whole Alarm-Fläche on first build
/// (Designsystem §7 "Alarm-Eintritt": kein Blinken des gesamten Screens --
/// stattdessen ein einmaliger Fade-in). Never repeats (state only moves
/// false -> true once) and is skipped entirely when
/// `MediaQuery.disableAnimations` is set (Reduced-Motion: 0 ms, no
/// animation at all, not just a faster one).
class _FadeInOnce extends StatefulWidget {
  const _FadeInOnce({required this.child});

  final Widget child;

  @override
  State<_FadeInOnce> createState() => _FadeInOnceState();
}

class _FadeInOnceState extends State<_FadeInOnce> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) {
      return widget.child;
    }
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: widget.child,
    );
  }
}

class _AlarmContent extends ConsumerWidget {
  const _AlarmContent({
    required this.alarm,
    required this.personId,
    required this.acknowledging,
    required this.onAcknowledge,
  });

  final Alarm alarm;
  final String? personId;
  final bool acknowledging;
  final Future<void> Function() onAcknowledge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents =
        ref.watch(pairedIncidentsProvider).valueOrNull ?? const [];
    final allAlarms = ref.watch(pairedAlarmsProvider).valueOrNull ?? const [];
    final vehicles = ref.watch(pairedVehiclesProvider).valueOrNull ?? const [];
    final incident = _findIncident(incidents, alarm.incidentId);
    final incidentAlarms =
        allAlarms.where((a) => a.incidentId == alarm.incidentId).toList();
    final alarmLabel = alarmSequenceLabel(alarm, incidentAlarms);
    final alarmIcon = _alarmSequenceIcon(alarmLabel);

    AlarmRecipient? myRecipient;
    for (final recipient in alarm.recipients) {
      if (recipient.personId == personId) {
        myRecipient = recipient;
        break;
      }
    }
    final myVehicle =
        myRecipient == null ? null : _findVehicle(vehicles, myRecipient.vehicleId);

    final theme = Theme.of(context);
    final palette = theme.extension<BftagAlarmColors>()!;
    final radii = theme.extension<BftagRadii>()!;
    final onAlarm = palette.onAlarm;

    final textStyle = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: onAlarm,
    );
    // Screen-local override (concept `app-alarm.md` §3): neither
    // `headlineSmall` nor a mix of tokens, 28/34 Bold -- the Meldebild
    // keyword needs more weight/size than any entry in the shared type
    // scale (Designsystem 3.1) provides for body-length text.
    final alarmKeyword = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: onAlarm,
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.bold,
    );
    // Screen-local override (concept `app-alarm.md` §3): NOT `labelLarge`
    // (Medium weight there, Bold needed here), 14/20 Bold + 2px tracking.
    final alarmSequenceCaps = (theme.textTheme.bodyLarge ?? const TextStyle())
        .copyWith(
          color: onAlarm,
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        );
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(color: onAlarm, fontWeight: FontWeight.bold);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALARM',
                    style: (theme.textTheme.displaySmall ?? const TextStyle())
                        .copyWith(color: onAlarm, letterSpacing: 4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(alarmIcon, color: onAlarm, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        alarmLabel.toUpperCase(),
                        key: const Key('alarm-sequence-label'),
                        style: alarmSequenceCaps,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (incident != null) ...[
                    Text(
                      '#${incident.number} ${incident.keyword}',
                      style: alarmKeyword,
                    ),
                  ],
                  if (myRecipient != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // Concept `app-alarm.md` §3 calls for a 12%
                        // `onAlarm`-tint card; at 12% the resulting bg in
                        // light mode drops `onAlarm`-on-card contrast to
                        // ~4.25:1 (below WCAG AA 4.5:1 for the 16px value
                        // text). 6% keeps the same visually "lighter red"
                        // card while staying >= 4.5:1 in both modes
                        // (verified with `docs/design/tools/contrast.py`
                        // blending logic).
                        color: onAlarm.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(radii.large),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DEIN FAHRZEUG', style: titleStyle),
                          const SizedBox(height: 8),
                          Text(
                            '${myVehicle?.shortName ?? myRecipient.vehicleId} – ${myRecipient.function}',
                            style: textStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (incident != null) ...[
                    const SizedBox(height: 24),
                    Text(incident.address, style: textStyle.copyWith(fontSize: 20)),
                    if (incident.report.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(incident.report, style: textStyle.copyWith(fontSize: 18)),
                    ],
                    if (incident.location != null) ...[
                      const SizedBox(height: 16),
                      IncidentLocationCard(
                        incident: incident.location!,
                        station: ref.watch(pairedStationProvider).valueOrNull,
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Text('ALARMIERTE FAHRZEUGE', style: titleStyle),
                  const SizedBox(height: 8),
                  for (final vehicleId in alarm.vehicleIds)
                    Text(
                      _findVehicle(vehicles, vehicleId)?.shortName ?? vehicleId,
                      style: textStyle,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('acknowledge-button'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radii.full),
                  ),
                  backgroundColor: onAlarm,
                  foregroundColor: palette.alarm,
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: acknowledging ? null : () => unawaited(onAcknowledge()),
                child: acknowledging
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: palette.alarm,
                        ),
                      )
                    : const Text('Quittieren'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
