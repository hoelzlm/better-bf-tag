// Alarmzustand (`docs/design/screens/monitor-alarm.md`; ADR 0017): the
// loud, full-surface `alarm`/`onAlarm` screen shown for exactly
// `_alarmFlashDuration` (monitor_screen.dart) after a *live*
// `alarm.triggered` event, before the monitor automatically falls back to
// the calmer `MonitorIncidentScreen`. Never shown for Alarme that only
// arrived via the initial snapshot (ADR 0017's existing gong exception
// applies here too, concept §5 "Auslöser").
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitor/monitor_clock.dart';
import '../monitor/monitor_connection_banner.dart';
import '../monitor/monitor_incident_parts.dart';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Formats the Laufzeit since [since] as `mm:ss` (< 1 h) or `h:mm:ss`
/// (>= 1 h) -- mirrors `monitor_incident_screen.dart`'s `formatRuntime`,
/// but here `since` is always *this* Alarmierung's `triggeredAt`
/// (concept §3 "Fußzeile"), never the Einsatz's earliest one.
String formatAlarmRuntime(DateTime since, DateTime now) {
  var elapsed = now.difference(since);
  if (elapsed.isNegative) elapsed = Duration.zero;
  final totalSeconds = elapsed.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }
  return '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
}

Incident? _findIncident(List<Incident> incidents, String id) {
  for (final incident in incidents) {
    if (incident.id == id) return incident;
  }
  return null;
}

/// Alarmzustand screen (concept §3): shown for [alarm] -- the `Alarm`
/// object whose live `alarm.triggered` started (or restarted) the
/// currently running 20-s timer in `MonitorScreen`. The vehicle list is
/// exactly [Alarm.vehicleIds] of this object (concept §3 "Datenquelle der
/// Fahrzeugliste", §6 AC7/AC13) -- never derived from the Einsatz.
class MonitorAlarmScreen extends ConsumerWidget {
  const MonitorAlarmScreen({super.key, required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents =
        ref.watch(incidentsProvider).valueOrNull ?? const <Incident>[];
    final alarms = ref.watch(alarmsProvider).valueOrNull ?? const <Alarm>[];
    final vehicles =
        ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();
    final connection = ref.watch(realtimeConnectionProvider).valueOrNull;

    final incident = _findIncident(incidents, alarm.incidentId);
    if (incident == null) {
      return const SizedBox.shrink();
    }

    final incidentAlarms = alarms
        .where((a) => a.incidentId == alarm.incidentId)
        .toList();
    // The badge reflects this alarm's position among all of the Einsatz's
    // Alarmierungen (concept §3 "Badge ... Text via alarmSequenceLabel");
    // falls back to the alarm as given if it isn't (yet) in [alarms]
    // (e.g. a test that injects the alarm directly).
    final alarmsForLabel = incidentAlarms.any((a) => a.id == alarm.id)
        ? incidentAlarms
        : [...incidentAlarms, alarm];
    final badgeLabel = alarmSequenceLabel(alarm, alarmsForLabel).toUpperCase();

    final vehiclesById = {for (final v in vehicles) v.id: v};
    final alarmVehicles = [
      for (final id in alarm.vehicleIds)
        if (vehiclesById[id] != null) vehiclesById[id]!,
    ];

    // "X/Y quittiert" lebt von denselben Daten wie in monitor-einsatz.md
    // (concept §3 "Fußzeile") -- alle Empfänger aller Alarmierungen dieses
    // Einsatzes, nicht nur dieser einen Alarmierung.
    final recipients = <AlarmRecipient>[
      for (final a in incidentAlarms) ...a.recipients,
    ];

    final triggeredAt = alarm.triggeredAt;
    final runtime = triggeredAt == null
        ? null
        : formatAlarmRuntime(triggeredAt, now);
    final time =
        '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:'
        '${_twoDigits(now.second)}';

    final theme = Theme.of(context);
    final alarmColors = theme.extension<BftagAlarmColors>();
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final alarmColor = alarmColors?.alarm ?? theme.colorScheme.surface;
    final onAlarm = alarmColors?.onAlarm ?? theme.colorScheme.onSurface;

    final keywordStyle =
        (monitorStyles?.alarmTitle ?? const TextStyle(fontSize: 96)).copyWith(
          color: onAlarm,
        );
    final addressStyle =
        (monitorStyles?.display ?? const TextStyle(fontSize: 64)).copyWith(
          color: onAlarm,
        );
    // §6 AC10: Meldebild ≥ 40 px -- the shared `monitorBody` default (28
    // px) is deliberately overridden here, this is the loudest surface.
    final reportStyle = (monitorStyles?.body ?? const TextStyle(fontSize: 28))
        .copyWith(fontSize: 40, color: onAlarm);
    final clockStyle = (monitorStyles?.display ?? const TextStyle(fontSize: 64))
        .copyWith(color: onAlarm);
    final footerStyle = (monitorStyles?.body ?? const TextStyle(fontSize: 28))
        .copyWith(fontSize: 28, color: onAlarm.withValues(alpha: 0.9));

    return Scaffold(
      backgroundColor: alarmColor,
      body: SafeArea(
        child: Column(
          children: [
            MonitorConnectionBanner(status: connection),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _AlarmBadge(label: badgeLabel),
                        const Spacer(),
                        Text(
                          time,
                          key: const Key('monitor-alarm-clock'),
                          style: clockStyle,
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.xxl),
                    _ScalingKeyword(
                      text: incident.keyword.toUpperCase(),
                      style: keywordStyle,
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      incident.address,
                      key: const Key('monitor-alarm-address'),
                      style: addressStyle,
                    ),
                    SizedBox(height: spacing.md),
                    Text(
                      incident.report,
                      key: const Key('monitor-alarm-report'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: reportStyle,
                    ),
                    const Spacer(),
                    Wrap(
                      key: const Key('monitor-alarm-vehicles'),
                      spacing: spacing.lg,
                      runSpacing: spacing.sm,
                      children: [
                        for (final vehicle in alarmVehicles)
                          _AlarmVehicleChip(
                            vehicle: vehicle,
                            nameFontSize: alarmVehicles.length > 10
                                ? (monitorStyles?.headline.fontSize ?? 40)
                                : (monitorStyles?.alarmTitle.fontSize ?? 96) *
                                      (56 / 96),
                          ),
                      ],
                    ),
                    SizedBox(height: spacing.lg),
                    Row(
                      children: [
                        if (runtime != null)
                          Text(
                            'seit $runtime',
                            key: const Key('monitor-alarm-runtime'),
                            style: footerStyle,
                          ),
                        if (runtime != null) SizedBox(width: spacing.lg),
                        Text(
                          ackProgressLabel(recipients),
                          key: const Key('monitor-alarm-ack-progress'),
                          style: footerStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stichwort (concept §3/§6 AC5): `monitorAlarmTitle` 96 px, auto-scaled
/// down to minimum `monitorDisplay` 64 px (never smaller) when it doesn't
/// fit on one line, then wraps to 2 lines at the 64-px floor.
class _ScalingKeyword extends StatelessWidget {
  const _ScalingKeyword({required this.text, required this.style});

  final String text;
  final TextStyle style;

  static const double _minFontSize = 64;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final baseFontSize = style.fontSize ?? 96;
        double fontSize = baseFontSize;

        double widthAt(double size) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: style.copyWith(fontSize: size),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: double.infinity);
          return painter.width;
        }

        final widthAtBase = widthAt(baseFontSize);
        if (widthAtBase > maxWidth && maxWidth.isFinite) {
          final scaled = baseFontSize * (maxWidth / widthAtBase);
          fontSize = scaled.clamp(_minFontSize, baseFontSize);
        }

        final fitsOneLine = !maxWidth.isFinite || widthAt(fontSize) <= maxWidth;

        return Text(
          text,
          key: const Key('monitor-alarm-keyword'),
          style: style.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
          maxLines: fitsOneLine ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// Badge "ERSTALARM"/"N. NACHALARMIERUNG" (concept §3, §6 AC3/AC6):
/// `onAlarm`-on-`alarm` pill with the pulsing "notification_important"
/// icon. The icon pulses at <=1 Hz via an [AnimationController] -- but
/// never when `MediaQuery.disableAnimations` is set (concept §4 "Reduced-
/// Motion aktiv"), where it stays statically visible instead.
class _AlarmBadge extends StatefulWidget {
  const _AlarmBadge({required this.label});

  final String label;

  @override
  State<_AlarmBadge> createState() => _AlarmBadgeState();
}

class _AlarmBadgeState extends State<_AlarmBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reducedMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.55,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _controller.stop();
      _controller.value = 1.0;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarmColors = theme.extension<BftagAlarmColors>();
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final onAlarm = alarmColors?.onAlarm ?? theme.colorScheme.onSurface;
    final textStyle = (monitorStyles?.headline ?? const TextStyle(fontSize: 40))
        .copyWith(color: onAlarm, fontWeight: FontWeight.bold);

    return Container(
      key: const Key('monitor-alarm-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: onAlarm.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final reducedMotion = _reducedMotion ?? false;
              final opacity = reducedMotion ? 1.0 : _controller.value;
              return Opacity(opacity: opacity, child: child);
            },
            child: Icon(Icons.notification_important, color: onAlarm, size: 32),
          ),
          const SizedBox(width: 12),
          Text(widget.label, style: textStyle),
        ],
      ),
    );
  }
}

/// Fahrzeugchip im Alarmzustand (concept §3 "Fahrzeugchips", §6 AC7/AC10/
/// AC13): Fahrzeugname in [nameFontSize] (>= 56 px in the normal case,
/// concept's own >10-vehicles edge case explicitly reduces this below
/// that floor to 32 px, down to the Designsystem-Minimum 22 px), fixed
/// "alarmiert" sub-label -- deliberately no FMS-Pille here (concept §3).
class _AlarmVehicleChip extends StatelessWidget {
  const _AlarmVehicleChip({required this.vehicle, required this.nameFontSize});

  final Vehicle vehicle;
  final double nameFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarmColors = theme.extension<BftagAlarmColors>();
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final onAlarm = alarmColors?.onAlarm ?? theme.colorScheme.onSurface;
    final nameStyle =
        (monitorStyles?.alarmTitle ?? const TextStyle(fontSize: 96)).copyWith(
          fontSize: nameFontSize,
          color: onAlarm,
        );
    final subStyle = (monitorStyles?.label ?? const TextStyle(fontSize: 22))
        .copyWith(fontSize: 28, color: onAlarm);
    return Container(
      key: Key('monitor-alarm-vehicle-${vehicle.id}'),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        color: onAlarm.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radii.medium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vehicle.shortName, style: nameStyle),
          Text('alarmiert', style: subStyle),
        ],
      ),
    );
  }
}
