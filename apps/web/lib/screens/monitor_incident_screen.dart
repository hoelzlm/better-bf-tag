import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../map_tile_provider.dart';
import '../monitor/monitor_clock.dart';
import '../monitor/monitor_connection_banner.dart';
import '../monitor/monitor_incident_parts.dart';
import '../station_provider.dart';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Formats the Laufzeit since [since] as `mm:ss` (< 1 h) or `h:mm:ss`
/// (>= 1 h) (ADR 0017, Monitor-Anzeige "seit ..."). Second-accurate, meant
/// to be recomputed every second from [monitorClockProvider].
String formatRuntime(DateTime since, DateTime now) {
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

/// Einsatzansicht (`docs/design/screens/monitor-einsatz.md`; ADR 0017):
/// shown on the monitor while [incidentId] has at least one Alarmierung.
/// High contrast, sized for TV distance. Never shows the Drehbuch -- the
/// monitor never receives it over the realtime protocol, and no field for
/// it exists in this widget.
class MonitorIncidentScreen extends ConsumerWidget {
  const MonitorIncidentScreen({super.key, required this.incidentId});

  /// The Einsatz to display; owned by [MonitorScreen]'s rotation state.
  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents =
        ref.watch(incidentsProvider).valueOrNull ?? const <Incident>[];
    final alarms = ref.watch(alarmsProvider).valueOrNull ?? const <Alarm>[];
    final vehicles =
        ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();
    final station = ref.watch(stationProvider).valueOrNull;
    final mapTileProvider = ref.watch(mapTileProviderProvider);
    final connection = ref.watch(realtimeConnectionProvider).valueOrNull;

    final incident = _findIncident(incidents, incidentId);
    if (incident == null) {
      return const SizedBox.shrink();
    }
    final incidentAlarms = alarms
        .where((a) => a.incidentId == incidentId)
        .toList();

    DateTime? earliestTriggeredAt;
    for (final alarm in incidentAlarms) {
      final triggeredAt = alarm.triggeredAt;
      if (triggeredAt == null) continue;
      if (earliestTriggeredAt == null ||
          triggeredAt.isBefore(earliestTriggeredAt)) {
        earliestTriggeredAt = triggeredAt;
      }
    }

    final recipients = <AlarmRecipient>[
      for (final alarm in incidentAlarms) ...alarm.recipients,
    ];

    final vehicleIds = <String>{
      for (final alarm in incidentAlarms) ...alarm.vehicleIds,
    };
    final vehiclesById = {for (final v in vehicles) v.id: v};
    final alarmedVehicles = [
      for (final id in vehicleIds)
        if (vehiclesById[id] != null) vehiclesById[id]!,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final orderedAlarms = triggeredAlarmsInOrder(incidentAlarms);
    final latestAlarmLabel = orderedAlarms.isEmpty
        ? null
        : alarmSequenceLabel(orderedAlarms.last, incidentAlarms);

    final time =
        '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:'
        '${_twoDigits(now.second)}';
    final runtime = earliestTriggeredAt == null
        ? null
        : formatRuntime(earliestTriggeredAt, now);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final alarmColors = theme.extension<BftagAlarmColors>();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    final headlineStyle =
        (monitorStyles?.headline ?? const TextStyle(fontSize: 40)).copyWith(
          color: colorScheme.onSurface,
        );
    final bodyStyle = (monitorStyles?.body ?? const TextStyle(fontSize: 28))
        .copyWith(color: colorScheme.onSurfaceVariant);

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'EINSATZ ${incident.number}',
                            key: const Key('monitor-incident-number'),
                            style: headlineStyle,
                          ),
                        ),
                        Text(
                          time,
                          key: const Key('monitor-incident-clock'),
                          style: bodyStyle,
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            incident.keyword.toUpperCase(),
                            key: const Key('monitor-incident-keyword'),
                            style: headlineStyle.copyWith(
                              color: alarmColors?.alarm,
                            ),
                          ),
                        ),
                        if (runtime != null)
                          Text(
                            'seit $runtime',
                            key: const Key('monitor-incident-runtime'),
                            style: bodyStyle,
                          ),
                      ],
                    ),
                    SizedBox(height: spacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            incident.address,
                            key: const Key('monitor-incident-address'),
                            style: bodyStyle,
                          ),
                        ),
                        if (latestAlarmLabel != null) ...[
                          _AlarmLabelChip(label: latestAlarmLabel),
                          SizedBox(width: spacing.md),
                        ],
                        AckProgressChip(recipients: recipients),
                      ],
                    ),
                    SizedBox(height: spacing.lg),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _ReportPanel(report: incident.report),
                                ),
                                SizedBox(height: spacing.lg),
                                Expanded(
                                  child: _RecipientsPanel(
                                    recipients: recipients,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: spacing.xl),
                          Expanded(
                            flex: 4,
                            child: _MapArea(
                              location: incident.location,
                              station: station,
                              tileProvider: mapTileProvider,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    SizedBox(
                      height: 150,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            key: const Key('monitor-incident-vehicles'),
                            spacing: spacing.lg,
                            runSpacing: spacing.sm,
                            children: [
                              for (final vehicle in alarmedVehicles)
                                IncidentVehicleChip(vehicle: vehicle),
                            ],
                          ),
                        ),
                      ),
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

/// `Key('monitor-incident-alarm-label')` (**bestehender Key, Inhalt
/// unverändert** -- concept §3 Review-Runde 1 Punkt 8): the Alarmierungs-
/// stufe (`alarmSequenceLabel`), now a neutral `surfaceContainer` chip
/// instead of the loud amber badge -- that look lives exclusively in the
/// separate Alarmzustand (`monitor-alarm.md`) from now on.
class _AlarmLabelChip extends StatelessWidget {
  const _AlarmLabelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final style = (monitorStyles?.label ?? const TextStyle(fontSize: 22))
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Container(
      key: const Key('monitor-incident-alarm-label'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radii.full),
      ),
      child: Text(label.toUpperCase(), style: style),
    );
  }
}

/// Meldebild panel (concept §3/§6 AC6): `monitorBody`, max 6 lines, with a
/// fade + "⌄" more-indicator (`Key('monitor-incident-report-more')`) once
/// the text would overflow -- the monitor can't scroll.
class _ReportPanel extends StatelessWidget {
  const _ReportPanel({required this.report});

  final String report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final labelStyle = (monitorStyles?.label ?? const TextStyle(fontSize: 22))
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    final bodyStyle = (monitorStyles?.body ?? const TextStyle(fontSize: 28))
        .copyWith(color: theme.colorScheme.onSurface);
    final panelColor = theme.colorScheme.surfaceContainer;

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(radii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meldebild', style: labelStyle),
          SizedBox(height: spacing.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(text: report, style: bodyStyle),
                  maxLines: 6,
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: constraints.maxWidth);
                final overflowing = painter.didExceedMaxLines;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Text(
                        report,
                        key: const Key('monitor-incident-report'),
                        maxLines: 6,
                        overflow: TextOverflow.clip,
                        style: bodyStyle,
                      ),
                    ),
                    if (overflowing)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 32,
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                panelColor.withValues(alpha: 0),
                                panelColor,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.expand_more,
                            key: const Key('monitor-incident-report-more'),
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Alarmiert panel (concept §3; BF-Tag ohne Handys: names only, no ack state): `surfaceContainer` card, the recipient
/// chips wrap inside -- the live progress count lives in the header's
/// `Key('monitor-incident-ack-progress')` chip, not duplicated here.
class _RecipientsPanel extends StatelessWidget {
  const _RecipientsPanel({required this.recipients});

  final List<AlarmRecipient> recipients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final labelStyle = (monitorStyles?.label ?? const TextStyle(fontSize: 22))
        .copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alarmiert', style: labelStyle),
          SizedBox(height: spacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                key: const Key('monitor-incident-recipients'),
                spacing: spacing.lg,
                runSpacing: spacing.sm,
                children: [
                  for (final recipient in recipients)
                    _RecipientChip(recipient: recipient),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartenfläche (concept §3/§6 AC1/AC2): fixed height via the parent
/// `Expanded` (≥ 560 px at 1920×1080), either the real [IncidentMap] or a
/// neutral `Key('monitor-incident-map-placeholder')` fallback when
/// [location] is `null` -- never a blank area, never the raw tile-provider
/// error text.
class _MapArea extends StatelessWidget {
  const _MapArea({
    required this.location,
    required this.station,
    required this.tileProvider,
  });

  final LatLng? location;
  final LatLng? station;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final location = this.location;
    return ClipRRect(
      key: const Key('monitor-incident-map-area'),
      borderRadius: BorderRadius.circular(radii.medium),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: location == null
            ? const _MapPlaceholder(
                key: Key('monitor-incident-map-placeholder'),
                text: 'Keine Standortdaten',
              )
            : IncidentMap(
                incident: location,
                station: station,
                interactive: false,
                tileProvider: tileProvider,
              ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final bodyStyle = (monitorStyles?.body ?? const TextStyle(fontSize: 28))
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Container(
      color: theme.colorScheme.surfaceContainer,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(text, style: bodyStyle),
        ],
      ),
    );
  }
}

class _RecipientChip extends StatelessWidget {
  const _RecipientChip({required this.recipient});

  final AlarmRecipient recipient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    return Row(
      key: Key('incident-recipient-${recipient.personId}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 22),
        const SizedBox(width: 6),
        Text(
          recipient.displayName,
          style: (monitorStyles?.label ?? const TextStyle(fontSize: 22))
              .copyWith(color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}
