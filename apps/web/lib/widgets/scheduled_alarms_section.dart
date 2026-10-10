import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';
import '../monitor/monitor_clock.dart';
import 'confirm_dialog.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Formats [remaining] as `mm:ss` (< 1 h) or `Hh MMmin SSs` (ADR 0022,
/// Lage-Anzeige "Geplante Alarmierungen"). Negative durations (already due,
/// waiting for the next Scheduler-Tick) are clamped to zero.
String formatCountdown(Duration remaining) {
  final clamped = remaining.isNegative ? Duration.zero : remaining;
  final totalSeconds = clamped.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours}h ${_two(minutes)}min ${_two(seconds)}s';
  }
  return '${_two(minutes)}:${_two(seconds)}';
}

/// "Geplante Alarmierungen" (ADR 0022): [nextPlannedAlarmsProvider] is
/// already sorted nächste zuerst; each row ticks its countdown from
/// [monitorClockProvider] every second. "Jetzt auslösen"/"Ändern"/
/// "Verwerfen" only for Leitstelle/Administrator -- Einsatzvorbereitung
/// (and everyone else) sees the list read-only. Renders nothing when
/// there are none.
class ScheduledAlarmsSection extends ConsumerWidget {
  const ScheduledAlarmsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduled = ref.watch(nextPlannedAlarmsProvider);
    if (scheduled.isEmpty) return const SizedBox.shrink();

    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();
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

    return Card(
      key: const Key('scheduled-alarms-section'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Geplante Alarmierungen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final sa in scheduled)
              _ScheduledAlarmRow(
                key: Key('scheduled-alarm-${sa.alarm.id}'),
                scheduledAlarm: sa,
                vehiclesById: vehiclesById,
                now: now,
                canAct: canAct,
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledAlarmRow extends ConsumerWidget {
  const _ScheduledAlarmRow({
    super.key,
    required this.scheduledAlarm,
    required this.vehiclesById,
    required this.now,
    required this.canAct,
  });

  final ScheduledAlarm scheduledAlarm;
  final Map<String, Vehicle> vehiclesById;
  final DateTime now;
  final bool canAct;

  Future<void> _triggerNow(BuildContext context, WidgetRef ref) async {
    final alarm = scheduledAlarm.alarm;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Jetzt auslösen?',
      message: 'Die geplante Alarmierung für Einsatz '
          '#${scheduledAlarm.incident.number} wird sofort ausgelöst.',
      confirmLabel: 'Jetzt auslösen',
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
      title: 'Alarmierung verwerfen?',
      message: 'Die geplante Alarmierung für Einsatz '
          '#${scheduledAlarm.incident.number} wird verworfen.',
      confirmLabel: 'Verwerfen',
    );
    if (confirmed != true) return;
    try {
      await ref.read(alarmRepositoryProvider).discard(alarm.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(error, 'Alarmierung konnte nicht verworfen werden.'))),
      );
    }
  }

  Future<void> _openChangeDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => ChangeScheduledAlarmDialog(alarm: scheduledAlarm.alarm),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarm = scheduledAlarm.alarm;
    final incident = scheduledAlarm.incident;
    final remaining = countdown(alarm, now) ?? Duration.zero;
    final vehicleNames = alarm.vehicleIds
        .map((id) => vehiclesById[id]?.shortName ?? id)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                Text(
                  key: Key('scheduled-alarm-countdown-${alarm.id}'),
                  '${scheduledAlarmTimeLabel(alarm)} '
                  '(in ${formatCountdown(remaining)})',
                ),
              ],
            ),
          ),
          if (canAct)
            Wrap(
              spacing: 4,
              children: [
                OutlinedButton(
                  key: Key('scheduled-alarm-trigger-${alarm.id}'),
                  onPressed: () => _triggerNow(context, ref),
                  child: const Text('Jetzt auslösen'),
                ),
                OutlinedButton(
                  key: Key('scheduled-alarm-change-${alarm.id}'),
                  onPressed: () => _openChangeDialog(context),
                  child: const Text('Ändern'),
                ),
                OutlinedButton(
                  key: Key('scheduled-alarm-discard-${alarm.id}'),
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

/// "Ändern" dialog for a `planned` Alarmierung (ADR 0022): edits either the
/// absolute Zeitpunkt or the relative Minuten-Versatz -- whichever [alarm]
/// already uses -- and the Fahrzeuge, then calls [AlarmRepository.update].
class ChangeScheduledAlarmDialog extends ConsumerStatefulWidget {
  const ChangeScheduledAlarmDialog({super.key, required this.alarm});

  final Alarm alarm;

  @override
  ConsumerState<ChangeScheduledAlarmDialog> createState() =>
      _ChangeScheduledAlarmDialogState();
}

class _ChangeScheduledAlarmDialogState
    extends ConsumerState<ChangeScheduledAlarmDialog> {
  late bool _isRelative;
  late Set<String> _selected;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  late final TextEditingController _offsetController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isRelative = widget.alarm.offsetMinutes != null;
    _selected = widget.alarm.vehicleIds.toSet();
    final scheduledAt = widget.alarm.scheduledAt;
    if (!_isRelative && scheduledAt != null) {
      final local = scheduledAt.toLocal();
      _scheduledDate = DateTime(local.year, local.month, local.day);
      _scheduledTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
    _offsetController = TextEditingController(
      text: (widget.alarm.offsetMinutes ?? 10).toString(),
    );
  }

  @override
  void dispose() {
    _offsetController.dispose();
    super.dispose();
  }

  DateTime? get _scheduledAtLocal {
    final date = _scheduledDate;
    final time = _scheduledTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  int? get _offsetMinutes {
    final value = int.tryParse(_offsetController.text.trim());
    if (value == null || value < 1 || value > 1440) return null;
    return value;
  }

  bool get _canSubmit {
    if (_selected.isEmpty || _submitting) return false;
    return _isRelative ? _offsetMinutes != null : _scheduledAtLocal != null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(alarmRepositoryProvider).update(
            widget.alarm.id,
            scheduledAt: _isRelative ? null : _scheduledAtLocal!.toUtc(),
            offsetMinutes: _isRelative ? _offsetMinutes : null,
            vehicleIds: _selected.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = describeAlarmPlanError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];

    return AlertDialog(
      title: const Text('Geplante Alarmierung ändern'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fahrzeuge'),
            for (final vehicle in vehicles)
              CheckboxListTile(
                key: Key('change-alarm-vehicle-${vehicle.id}'),
                title: Text('${vehicle.shortName} (${vehicle.callSign})'),
                value: _selected.contains(vehicle.id),
                onChanged: _submitting
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(vehicle.id);
                          } else {
                            _selected.remove(vehicle.id);
                          }
                        });
                      },
              ),
            const SizedBox(height: 8),
            if (_isRelative)
              TextField(
                key: const Key('change-alarm-offset-minutes'),
                controller: _offsetController,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minuten nach Erstalarm',
                ),
                onChanged: (_) => setState(() {}),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('change-alarm-pick-date'),
                      onPressed: _submitting ? null : _pickDate,
                      child: Text(
                        _scheduledDate == null
                            ? 'Datum wählen'
                            : '${_scheduledDate!.day.toString().padLeft(2, '0')}.'
                                '${_scheduledDate!.month.toString().padLeft(2, '0')}.'
                                '${_scheduledDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('change-alarm-pick-time'),
                      onPressed: _submitting ? null : _pickTime,
                      child: Text(
                        _scheduledTime == null
                            ? 'Uhrzeit wählen'
                            : _scheduledTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('change-alarm-submit'),
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
