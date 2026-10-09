import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';

/// Alarmieren-Dialog (ADR 0017, ADR 0019): Fahrzeugauswahl aus den aktiven
/// Fahrzeugen, Vorabwarnung bei Doppelbesetzung (berechnet aus der
/// aktuellen Schicht, ohne Serverantwort), und `POST
/// /incidents/{id}/alarms` mit einer beim Öffnen des Dialogs einmalig
/// erzeugten Idempotenz-`id` -- ein erneuter Klick auf "Jetzt alarmieren"
/// mit derselben Auswahl erzeugt keine zweite Alarmierung.
///
/// Used both for den Erstalarm (`incidents_screen.dart`, Einsatz noch
/// `draft`) und für die Nachalarmierung eines laufenden Einsatzes
/// (`running_incidents_section.dart`): [alreadyAlarmedVehicleIds] -- bei
/// einer Nachalarmierung die Fahrzeuge, die in einer `triggered`
/// Alarmierung dieses Einsatzes bereits stehen -- werden als deaktiviert
/// "(bereits alarmiert)" angezeigt und können nicht erneut ausgewählt
/// werden (ADR 0019, "Fahrzeuge nur einmal pro Einsatz").
class AlarmDialog extends ConsumerStatefulWidget {
  const AlarmDialog({
    super.key,
    required this.incidentId,
    required this.title,
    this.alreadyAlarmedVehicleIds = const <String>{},
  });

  final String incidentId;
  final String title;
  final Set<String> alreadyAlarmedVehicleIds;

  @override
  ConsumerState<AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends ConsumerState<AlarmDialog> {
  late final String _idempotencyId;
  final Set<String> _selected = <String>{};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _idempotencyId = newIdempotencyId();
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref.read(alarmRepositoryProvider).trigger(
            widget.incidentId,
            _selected.toList(),
            id: _idempotencyId,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      final doubleCrewed = result.doubleCrewed;
      if (doubleCrewed.isNotEmpty) {
        for (final d in doubleCrewed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${d.displayName} sitzt auf mehreren ausgewählten '
                'Fahrzeugen – wird nur einmal alarmiert.',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      final message = describeAlarmTriggerError(error);
      if (message == 'Einsatz wurde bereits alarmiert.') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _submitting = false;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final shifts = ref.watch(shiftsProvider).valueOrNull ?? const <Shift>[];
    final shift = currentShift(shifts, DateTime.now());
    final doubleCrewed = doubleCrewedIn(shift, _selected);

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
          onPressed: (_selected.isEmpty || _submitting) ? null : _submit,
          child: const Text('Jetzt alarmieren'),
        ),
      ],
    );
  }
}
