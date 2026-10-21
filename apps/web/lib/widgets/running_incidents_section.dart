import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';
import 'alarm_dialog.dart';

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

/// German fragment naming the planned/missed Alarmierungen in
/// [scheduledAlarmsOfIncident] that will be discarded along with the
/// Einsatz (ADR 0022), e.g. "2 geplante und 1 verpasste Alarmierung", or
/// `null` when there are none -- used by the Einsatz schließen/verwerfen
/// confirmation dialogs.
String? scheduledAlarmsWarningFragment(
  List<ScheduledAlarm> scheduledAlarmsOfIncident,
) {
  final planned = scheduledAlarmsOfIncident
      .where((sa) => sa.alarm.isPlanned)
      .length;
  final missed = scheduledAlarmsOfIncident
      .where((sa) => sa.alarm.isMissed)
      .length;
  final parts = <String>[
    if (planned > 0) '$planned geplante Alarmierung${planned == 1 ? '' : 'en'}',
    if (missed > 0) '$missed verpasste Alarmierung${missed == 1 ? '' : 'en'}',
  ];
  if (parts.isEmpty) return null;
  return parts.join(' und ');
}

/// "Laufende Einsätze" (ADR 0017/0019, Abschnitt "Anzeige"): one card per
/// running Einsatz from [incidentsProvider], each with its Alarmierungen
/// from [alarmsProvider] -- titled with [alarmSequenceLabel], counts and a
/// per-recipient Quittierungsstatus. For `dispatch`/`admin`: a
/// "Nachalarmieren" button, an "Abschluss vorgeschlagen" highlight when the
/// Einsatz is in [closeSuggestedIncidentIdsProvider], and an
/// "Einsatz schließen" button. Empty state "Keine laufenden Einsätze".
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
    final closeSuggestedIds =
        ref.watch(closeSuggestedIncidentIdsProvider).valueOrNull ??
        const <String>{};
    final scheduledAlarms =
        ref.watch(scheduledAlarmsProvider).valueOrNull ??
        const <ScheduledAlarm>[];
    final session = ref.watch(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canDispatch = permission?.canRunIncidents ?? false;

    if (incidents.isEmpty) {
      return const BftagStateView.empty(
        icon: Icons.local_fire_department_outlined,
        title: 'Keine laufenden Einsätze',
      );
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
            scheduledAlarms: scheduledAlarms
                .where((sa) => sa.incident.id == incident.id)
                .toList(),
            vehiclesById: vehiclesById,
            now: now,
            canDispatch: canDispatch,
            allowPlanning: permission != Permission.radio,
            closeSuggested: closeSuggestedIds.contains(incident.id),
          ),
      ],
    );
  }
}

class _IncidentCard extends ConsumerWidget {
  const _IncidentCard({
    super.key,
    required this.incident,
    required this.alarms,
    required this.scheduledAlarms,
    required this.vehiclesById,
    required this.now,
    required this.canDispatch,
    required this.allowPlanning,
    required this.closeSuggested,
  });

  final Incident incident;
  final List<Alarm> alarms;
  final List<ScheduledAlarm> scheduledAlarms;
  final Map<String, Vehicle> vehiclesById;
  final DateTime now;
  final bool canDispatch;
  final bool allowPlanning;
  final bool closeSuggested;

  Future<void> _openNachalarmierenDialog(BuildContext context) async {
    final alreadyAlarmed = {
      for (final alarm in alarms)
        if (alarm.state == AlarmState.triggered) ...alarm.vehicleIds,
    };
    await showDialog<bool>(
      context: context,
      builder: (context) => AlarmDialog(
        incidentId: incident.id,
        title: 'Nachalarmierung für Einsatz #${incident.number}',
        alreadyAlarmedVehicleIds: alreadyAlarmed,
        // A laufender Einsatz has always been triggered at least once
        // (draft -> running only happens via triggerAlarm, ADR 0022).
        hasFirstAlarm: true,
        // Funktisch: nur sofort nachalarmieren, nichts planen.
        allowPlanning: allowPlanning,
      ),
    );
  }

  Future<void> _closeIncident(BuildContext context, WidgetRef ref) async {
    final warning = scheduledAlarmsWarningFragment(scheduledAlarms);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einsatz schließen?'),
        content: Text(
          warning != null
              ? 'Einsatz #${incident.number} "${incident.keyword}" wird '
                    'abgeschlossen. $warning werden verworfen.'
              : 'Einsatz #${incident.number} "${incident.keyword}" wird '
                    'abgeschlossen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('close-incident-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Einsatz schließen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(incidentRepositoryProvider).close(incident.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeApiError(error, 'Einsatz konnte nicht geschlossen werden.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alarmColors = theme.extension<BftagAlarmColors>()!;
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
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
      color: alarmColors.alarmContainer,
      margin: EdgeInsets.only(bottom: spacing.xl),
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
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (firstTriggeredAt != null)
                  Text(
                    'seit ${formatElapsedSince(firstTriggeredAt, now)}',
                    key: Key('incident-elapsed-${incident.id}'),
                  ),
              ],
            ),
            if (closeSuggested)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  key: Key('close-suggested-${incident.id}'),
                  avatar: const Icon(Icons.task_alt, size: 18),
                  label: const Text('Abschluss vorgeschlagen'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
            if (canDispatch)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.icon(
                      key: Key('nachalarmieren-incident-${incident.id}'),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          alarmColors.alarm,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          alarmColors.onAlarm,
                        ),
                      ),
                      icon: const Icon(Icons.campaign),
                      label: const Text('Nachalarmieren'),
                      onPressed: () => _openNachalarmierenDialog(context),
                    ),
                    OutlinedButton.icon(
                      key: Key('close-incident-${incident.id}'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Einsatz schließen'),
                      onPressed: () => _closeIncident(context, ref),
                    ),
                  ],
                ),
              ),
            for (final alarm in alarms)
              _AlarmSection(
                alarm: alarm,
                vehiclesById: vehiclesById,
                label: alarmSequenceLabel(alarm, alarms),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlarmSection extends StatelessWidget {
  const _AlarmSection({
    required this.alarm,
    required this.vehiclesById,
    required this.label,
  });

  final Alarm alarm;
  final Map<String, Vehicle> vehiclesById;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarmColors = theme.extension<BftagAlarmColors>()!;
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: alarmColors.alarm,
              borderRadius: BorderRadius.circular(radii.full),
            ),
            child: Text(
              key: Key('alarm-label-${alarm.id}'),
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: alarmColors.onAlarm,
              ),
            ),
          ),
          // BF-Tag ohne Handys: no Quittierung/Push counts, just who is alarmed.
          Text(
            key: Key('alarm-summary-${alarm.id}'),
            '${alarm.recipients.length} alarmiert',
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
    final theme = Theme.of(context);
    final vehicle = vehiclesById[recipient.vehicleId];
    final vehicleLabel = vehicle?.shortName ?? recipient.vehicleId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        key: Key('alarm-recipient-${recipient.personId}'),
        children: [
          Icon(
            Icons.person,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${recipient.displayName} – $vehicleLabel, ${recipient.function}',
            ),
          ),
        ],
      ),
    );
  }
}
