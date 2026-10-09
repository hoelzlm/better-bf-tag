import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Formats the elapsed time since [since] as `"X min"` (< 60 min) or
/// `"Hh MMmin"` (ADR 0017, Lage-Anzeige "seit Erstalarm").
String formatElapsedSince(DateTime since, DateTime now) {
  var elapsed = now.difference(since);
  if (elapsed.isNegative) elapsed = Duration.zero;
  final totalMinutes = elapsed.inMinutes;
  if (totalMinutes < 60) {
    return '$totalMinutes min';
  }
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h ${minutes}min';
}

IconData _ackIcon(AckState state) {
  switch (state) {
    case AckState.acknowledged:
      return Icons.check_circle;
    case AckState.pending:
      return Icons.more_horiz;
    case AckState.noDevice:
      return Icons.remove_circle_outline;
  }
}

Color _ackColor(AckState state) {
  switch (state) {
    case AckState.acknowledged:
      return Colors.green;
    case AckState.pending:
      return Colors.orange;
    case AckState.noDevice:
      return Colors.grey;
  }
}

String _ackLabel(AckState state) {
  switch (state) {
    case AckState.acknowledged:
      return 'quittiert';
    case AckState.pending:
      return 'ausstehend';
    case AckState.noDevice:
      return 'kein Gerät';
  }
}

/// "Laufende Einsätze" (ADR 0017, Abschnitt "Anzeige"): one card per
/// running Einsatz from [incidentsProvider], each with its Alarmierungen
/// from [alarmsProvider] -- counts and a per-recipient Quittierungsstatus.
/// Empty state "Keine laufenden Einsätze".
class RunningIncidentsSection extends ConsumerWidget {
  const RunningIncidentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents =
        ref.watch(incidentsProvider).valueOrNull ?? const <Incident>[];
    final alarms = ref.watch(alarmsProvider).valueOrNull ?? const <Alarm>[];
    final vehicles =
        ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final vehiclesById = {for (final v in vehicles) v.id: v};

    if (incidents.isEmpty) {
      return const Center(child: Text('Keine laufenden Einsätze'));
    }

    final now = DateTime.now();

    return ListView(
      key: const Key('running-incidents-section'),
      padding: const EdgeInsets.all(16),
      children: [
        for (final incident in incidents)
          _IncidentCard(
            key: Key('running-incident-${incident.id}'),
            incident: incident,
            alarms: alarms.where((a) => a.incidentId == incident.id).toList(),
            vehiclesById: vehiclesById,
            now: now,
          ),
      ],
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    super.key,
    required this.incident,
    required this.alarms,
    required this.vehiclesById,
    required this.now,
  });

  final Incident incident;
  final List<Alarm> alarms;
  final Map<String, Vehicle> vehiclesById;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final triggerTimes = [
      for (final alarm in alarms)
        if (alarm.triggeredAt != null) alarm.triggeredAt!,
    ];
    DateTime? firstTriggeredAt;
    for (final t in triggerTimes) {
      if (firstTriggeredAt == null || t.isBefore(firstTriggeredAt)) {
        firstTriggeredAt = t;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${incident.number} ${incident.keyword} – ${incident.address}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (firstTriggeredAt != null)
                  Text(
                    'seit ${formatElapsedSince(firstTriggeredAt, now)}',
                    key: Key('incident-elapsed-${incident.id}'),
                  ),
              ],
            ),
            for (final alarm in alarms) _AlarmSection(alarm: alarm, vehiclesById: vehiclesById),
          ],
        ),
      ),
    );
  }
}

class _AlarmSection extends StatelessWidget {
  const _AlarmSection({required this.alarm, required this.vehiclesById});

  final Alarm alarm;
  final Map<String, Vehicle> vehiclesById;

  @override
  Widget build(BuildContext context) {
    final summary = alarm.summary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key: Key('alarm-summary-${alarm.id}'),
            '${summary.acknowledged} quittiert · ${summary.pending} ausstehend · '
            '${summary.noDevice} kein Gerät',
          ),
          const SizedBox(height: 4),
          for (final recipient in alarm.recipients)
            _RecipientRow(recipient: recipient, vehiclesById: vehiclesById),
        ],
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({required this.recipient, required this.vehiclesById});

  final AlarmRecipient recipient;
  final Map<String, Vehicle> vehiclesById;

  @override
  Widget build(BuildContext context) {
    final state = recipient.ackState;
    final vehicle = vehiclesById[recipient.vehicleId];
    final vehicleLabel = vehicle?.shortName ?? recipient.vehicleId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        key: Key('alarm-recipient-${recipient.personId}'),
        children: [
          Icon(
            _ackIcon(state),
            key: Key('ack-icon-${recipient.personId}'),
            size: 18,
            color: _ackColor(state),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${recipient.displayName} – $vehicleLabel, ${recipient.function} '
              '(${_ackLabel(state)})',
            ),
          ),
        ],
      ),
    );
  }
}
