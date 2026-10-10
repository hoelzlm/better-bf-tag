import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';

/// Wie eine Alarmierung über [AlarmDialog] ausgelöst werden soll (ADR
/// 0022): sofort (wie bisher), zu einem absoluten Zeitpunkt, oder relativ
/// zum Erstalarm (+ Minuten).
enum AlarmDialogMode { immediate, scheduled, relative }

/// Ob [incidentId] bereits einen Erstalarm hat (ADR 0022): eine
/// `triggered` Alarmierung, oder eine `planned` absolute (ohne
/// `relativeToAlarmId`) Alarmierung ohne eigene Basis. Pure Funktion, damit
/// [AlarmDialog] "Relativ zum Erstalarm" ohne Serverantwort aktivieren/
/// deaktivieren kann (sonst meldet der Server 409 `no_first_alarm`).
bool hasFirstAlarmFor(
  String incidentId,
  Iterable<Alarm> alarms,
  Iterable<ScheduledAlarm> scheduledAlarms,
) {
  final ofIncident = alarms.where((a) => a.incidentId == incidentId);
  if (triggeredAlarmsInOrder(ofIncident).isNotEmpty) return true;
  return scheduledAlarms.any(
    (sa) =>
        sa.incident.id == incidentId &&
        sa.alarm.isPlanned &&
        sa.alarm.relativeToAlarmId == null,
  );
}

/// Alarmieren-Dialog (ADR 0017, ADR 0019, ADR 0022): Fahrzeugauswahl aus
/// den aktiven Fahrzeugen, Vorabwarnung bei Doppelbesetzung (berechnet aus
/// der aktuellen Schicht, ohne Serverantwort), ein Modus "Sofort" /
/// "Zeitpunkt" / "Relativ zum Erstalarm", und eine beim Öffnen des Dialogs
/// einmalig erzeugte Idempotenz-`id` -- ein erneuter Klick mit derselben
/// Auswahl erzeugt keine zweite Alarmierung.
///
/// Used both for den Erstalarm (`incidents_screen.dart`, Einsatz noch
/// `draft`) und für die Nachalarmierung eines laufenden Einsatzes
/// (`running_incidents_section.dart`): [alreadyAlarmedVehicleIds] -- bei
/// einer Nachalarmierung die Fahrzeuge, die in einer `triggered`
/// Alarmierung dieses Einsatzes bereits stehen -- werden als deaktiviert
/// "(bereits alarmiert)" angezeigt und können nicht erneut ausgewählt
/// werden (ADR 0019, "Fahrzeuge nur einmal pro Einsatz"). [hasFirstAlarm]
/// (see [hasFirstAlarmFor]) schaltet "Relativ zum Erstalarm" frei.
class AlarmDialog extends ConsumerStatefulWidget {
  const AlarmDialog({
    super.key,
    required this.incidentId,
    required this.title,
    this.alreadyAlarmedVehicleIds = const <String>{},
    this.hasFirstAlarm = false,
  });

  final String incidentId;
  final String title;
  final Set<String> alreadyAlarmedVehicleIds;
  final bool hasFirstAlarm;

  @override
  ConsumerState<AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends ConsumerState<AlarmDialog> {
  late final String _idempotencyId;
  final Set<String> _selected = <String>{};
  AlarmDialogMode _mode = AlarmDialogMode.immediate;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  final TextEditingController _offsetController = TextEditingController(
    text: '10',
  );
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _idempotencyId = newIdempotencyId();
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
    switch (_mode) {
      case AlarmDialogMode.immediate:
        return true;
      case AlarmDialogMode.scheduled:
        return _scheduledAtLocal != null;
      case AlarmDialogMode.relative:
        return widget.hasFirstAlarm && _offsetMinutes != null;
    }
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
    if (_mode == AlarmDialogMode.immediate) {
      try {
        final result = await ref
            .read(alarmRepositoryProvider)
            .trigger(widget.incidentId, _selected.toList(), id: _idempotencyId);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        for (final d in result.doubleCrewed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${d.displayName} sitzt auf mehreren ausgewählten '
                'Fahrzeugen – wird nur einmal alarmiert.',
              ),
            ),
          );
        }
      } catch (error) {
        if (!mounted) return;
        final message = describeAlarmTriggerError(error);
        if (message == 'Einsatz wurde bereits alarmiert.') {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
          Navigator.of(context).pop(true);
          return;
        }
        setState(() {
          _submitting = false;
          _error = message;
        });
      }
      return;
    }

    try {
      await ref.read(alarmRepositoryProvider).plan(
            widget.incidentId,
            _selected.toList(),
            id: _idempotencyId,
            scheduledAt: _mode == AlarmDialogMode.scheduled
                ? _scheduledAtLocal!.toUtc()
                : null,
            offsetMinutes:
                _mode == AlarmDialogMode.relative ? _offsetMinutes : null,
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
    final shifts = ref.watch(shiftsProvider).valueOrNull ?? const <Shift>[];
    final shift = currentShift(shifts, DateTime.now());
    final doubleCrewed = doubleCrewedIn(shift, _selected);
    final scheduledAt = _scheduledAtLocal;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fahrzeuge auswählen'),
            const SizedBox(height: 8),
            for (final vehicle in vehicles)
              CheckboxListTile(
                key: Key('alarm-vehicle-${vehicle.id}'),
                title: Text(
                  widget.alreadyAlarmedVehicleIds.contains(vehicle.id)
                      ? '${vehicle.shortName} (${vehicle.callSign}) – bereits alarmiert'
                      : '${vehicle.shortName} (${vehicle.callSign})',
                ),
                value: widget.alreadyAlarmedVehicleIds.contains(vehicle.id) ||
                    _selected.contains(vehicle.id),
                onChanged: (_submitting ||
                        widget.alreadyAlarmedVehicleIds.contains(vehicle.id))
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
            if (doubleCrewed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('alarm-double-crewed-warning'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.orange.shade800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Doppelbesetzung',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    for (final d in doubleCrewed)
                      Text(
                        key: Key('alarm-double-crewed-${d.personId}'),
                        '${d.displayName} sitzt auf mehreren ausgewählten '
                        'Fahrzeugen – wird nur einmal alarmiert.',
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Wann?', style: TextStyle(fontWeight: FontWeight.bold)),
            // Note: RadioListTile's groupValue/onChanged are deprecated in
            // favor of RadioGroup, but migrating would lose the per-tile
            // enabled/disabled distinction needed here (immediate/scheduled
            // vs. relative without Erstalarm) -- ignored below instead.
            RadioListTile<AlarmDialogMode>(
              key: const Key('alarm-mode-immediate'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Sofort'),
              value: AlarmDialogMode.immediate,
              // ignore: deprecated_member_use
              groupValue: _mode,
              // ignore: deprecated_member_use
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _mode = value!),
            ),
            RadioListTile<AlarmDialogMode>(
              key: const Key('alarm-mode-scheduled'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Zeitpunkt'),
              value: AlarmDialogMode.scheduled,
              // ignore: deprecated_member_use
              groupValue: _mode,
              // ignore: deprecated_member_use
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _mode = value!),
            ),
            RadioListTile<AlarmDialogMode>(
              key: const Key('alarm-mode-relative'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Relativ zum Erstalarm'),
              subtitle: widget.hasFirstAlarm
                  ? null
                  : const Text('Erst verfügbar, sobald es einen Erstalarm gibt.'),
              value: AlarmDialogMode.relative,
              // ignore: deprecated_member_use
              groupValue: _mode,
              // ignore: deprecated_member_use
              onChanged: (_submitting || !widget.hasFirstAlarm)
                  ? null
                  : (value) => setState(() => _mode = value!),
            ),
            if (_mode == AlarmDialogMode.scheduled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('alarm-pick-date'),
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
                      key: const Key('alarm-pick-time'),
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
              if (scheduledAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'geplant für ${scheduledAt.day.toString().padLeft(2, '0')}.'
                    '${scheduledAt.month.toString().padLeft(2, '0')}.'
                    '${scheduledAt.year} '
                    '${scheduledAt.hour.toString().padLeft(2, '0')}:'
                    '${scheduledAt.minute.toString().padLeft(2, '0')} Uhr',
                  ),
                ),
            ],
            if (_mode == AlarmDialogMode.relative) ...[
              const SizedBox(height: 8),
              TextField(
                key: const Key('alarm-offset-minutes'),
                controller: _offsetController,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minuten nach Erstalarm',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
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
          key: const Key('alarm-dialog-submit'),
          onPressed: _canSubmit ? _submit : null,
          child: Text(
            _mode == AlarmDialogMode.immediate ? 'Jetzt alarmieren' : 'Planen',
          ),
        ),
      ],
    );
  }
}
