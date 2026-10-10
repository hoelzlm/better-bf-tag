import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';
import 'confirm_dialog.dart';

/// "Verpasste Alarmierungen" (ADR 0022), visually highlighted: shown only
/// when [missedAlarmsProvider] is non-empty. "Auslösen"/"Verwerfen" only
/// for Leitstelle/Administrator -- Einsatzvorbereitung sees the list
/// read-only.
class MissedAlarmsSection extends ConsumerWidget {
  const MissedAlarmsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missed = ref.watch(missedAlarmsProvider);
    if (missed.isEmpty) return const SizedBox.shrink();

    final vehicles =
        ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final vehiclesById = {for (final v in vehicles) v.id: v};
    final session = ref.watch(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canAct =
        permission == Permission.dispatch || permission == Permission.admin;

    return Container(
      key: const Key('missed-alarms-section'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.shade700, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Verpasste Alarmierungen',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.red.shade700),
              ),
            ],
          ),
          for (final sa in missed)
            _MissedAlarmRow(
              key: Key('missed-alarm-${sa.alarm.id}'),
              scheduledAlarm: sa,
              vehiclesById: vehiclesById,
              canAct: canAct,
            ),
        ],
      ),
    );
  }
}

class _MissedAlarmRow extends ConsumerWidget {
  const _MissedAlarmRow({
    super.key,
    required this.scheduledAlarm,
    required this.vehiclesById,
    required this.canAct,
  });

  final ScheduledAlarm scheduledAlarm;
  final Map<String, Vehicle> vehiclesById;
  final bool canAct;

  Future<void> _triggerNow(BuildContext context, WidgetRef ref) async {
    final alarm = scheduledAlarm.alarm;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Verpasste Alarmierung auslösen?',
      message: 'Die verpasste Alarmierung für Einsatz '
          '#${scheduledAlarm.incident.number} wird jetzt ausgelöst.',
      confirmLabel: 'Auslösen',
    );
    if (confirmed != true) return;
    try {
      await ref.read(alarmRepositoryProvider).triggerNow(alarm.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeAlarmTriggerError(error))),
      );
    }
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final alarm = scheduledAlarm.alarm;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Verpasste Alarmierung verwerfen?',
      message: 'Die verpasste Alarmierung für Einsatz '
          '#${scheduledAlarm.incident.number} wird verworfen.',
      confirmLabel: 'Verwerfen',
    );
    if (confirmed != true) return;
    try {
      await ref.read(alarmRepositoryProvider).discard(alarm.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeApiError(error, 'Alarmierung konnte nicht verworfen werden.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarm = scheduledAlarm.alarm;
    final incident = scheduledAlarm.incident;
    final vehicleNames = alarm.vehicleIds
        .map((id) => vehiclesById[id]?.shortName ?? id)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${incident.number} ${incident.keyword}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(vehicleNames),
                Text('geplant für ${scheduledAlarmTimeLabel(alarm)}'),
              ],
            ),
          ),
          if (canAct)
            Wrap(
              spacing: 4,
              children: [
                OutlinedButton(
                  key: Key('missed-alarm-trigger-${alarm.id}'),
                  onPressed: () => _triggerNow(context, ref),
                  child: const Text('Auslösen'),
                ),
                OutlinedButton(
                  key: Key('missed-alarm-discard-${alarm.id}'),
                  onPressed: () => _discard(context, ref),
                  child: const Text('Verwerfen'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
