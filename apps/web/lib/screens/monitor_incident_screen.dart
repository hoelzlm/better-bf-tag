import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitor/monitor_clock.dart';

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

Color _vehicleStatusColor(FmsStatus status) {
  switch (status) {
    case FmsStatus.s1:
    case FmsStatus.s2:
      return Colors.green;
    case FmsStatus.s3:
      return Colors.orange;
    case FmsStatus.s4:
      return Colors.red;
    case FmsStatus.s5:
      return Colors.amber;
    case FmsStatus.s6:
      return Colors.grey;
    case FmsStatus.s7:
    case FmsStatus.s8:
      return Colors.blue;
  }
}

IconData _ackIcon(AckState state) {
  switch (state) {
    case AckState.acknowledged:
      return Icons.check;
    case AckState.pending:
      return Icons.more_horiz;
    case AckState.noDevice:
      return Icons.remove;
  }
}

Color _ackColor(AckState state) {
  switch (state) {
    case AckState.acknowledged:
      return Colors.greenAccent;
    case AckState.pending:
      return Colors.amberAccent;
    case AckState.noDevice:
      return Colors.white38;
  }
}

Incident? _findIncident(List<Incident> incidents, String id) {
  for (final incident in incidents) {
    if (incident.id == id) return incident;
  }
  return null;
}

/// Einsatzansicht (ADR 0017; layout sketch docs/06-clients.md, "Monitor …
/// Bei einem laufenden Einsatz"): shown on the monitor while [incidentId]
/// has at least one Alarmierung. High contrast, sized for TV distance.
/// Never shows the Drehbuch -- the monitor never receives it over the
/// realtime protocol, and no field for it exists in this widget.
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        key: const Key('monitor-incident-clock'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          incident.keyword.toUpperCase(),
                          key: const Key('monitor-incident-keyword'),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (runtime != null)
                        Text(
                          'seit $runtime',
                          key: const Key('monitor-incident-runtime'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    incident.address,
                    key: const Key('monitor-incident-address'),
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Meldebild:',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    incident.report,
                                    key: const Key('monitor-incident-report'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        VerticalDivider(color: Colors.white24),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quittiert',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    key: const Key(
                                      'monitor-incident-recipients',
                                    ),
                                    spacing: 16,
                                    runSpacing: 10,
                                    children: [
                                      for (final recipient in recipients)
                                        _RecipientChip(recipient: recipient),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Wrap(
                    key: const Key('monitor-incident-vehicles'),
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      for (final vehicle in alarmedVehicles)
                        _VehicleChip(vehicle: vehicle),
                    ],
                  ),
                ],
              ),
            ),
            if (latestAlarmLabel != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  key: const Key('monitor-incident-alarm-label'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    latestAlarmLabel.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipientChip extends StatelessWidget {
  const _RecipientChip({required this.recipient});

  final AlarmRecipient recipient;

  @override
  Widget build(BuildContext context) {
    final state = recipient.ackState;
    return Row(
      key: Key('incident-recipient-${recipient.personId}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _ackIcon(state),
          key: Key('incident-ack-icon-${recipient.personId}'),
          color: _ackColor(state),
          size: 22,
        ),
        const SizedBox(width: 6),
        Text(
          recipient.displayName,
          style: TextStyle(
            color: state == AckState.noDevice ? Colors.white38 : Colors.white,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: Key('incident-vehicle-${vehicle.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          vehicle.shortName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        CircleAvatar(
          radius: 16,
          backgroundColor: _vehicleStatusColor(vehicle.status),
          child: Text(
            '${vehicle.status.code}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
