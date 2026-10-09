import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';
import 'shifts_screen.dart' show pickDefaultBfDay;

String _stateChipLabel(IncidentState state) => state.label;

/// Einsätze screen (`/admin/einsaetze`, Berechtigung Einsatzvorbereitung,
/// Leitstelle oder Administrator, ADR 0016): BF-Tag-Auswahl, Filter nach
/// Zustand (Entwurf/laufend/abgeschlossen -- verworfen ausgeblendet),
/// Liste, Editor mit Meldebild und geheimem Drehbuch.
class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  List<BfDay>? _days;
  String? _selectedDayId;
  List<Incident>? _incidents;
  IncidentState _filter = IncidentState.draft;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDays());
  }

  BfDay? get _selectedDay {
    final days = _days;
    if (days == null) return null;
    for (final day in days) {
      if (day.id == _selectedDayId) return day;
    }
    return null;
  }

  List<Incident> get _filteredIncidents {
    final incidents = _incidents ?? const <Incident>[];
    return incidents.where((i) => i.state == _filter).toList();
  }

  Future<void> _loadDays() async {
    try {
      final days = await ref.read(bfDayAdminRepositoryProvider).list();
      if (!mounted) return;
      final defaultDay = pickDefaultBfDay(days);
      setState(() {
        _days = days;
        _loadError = null;
        _selectedDayId = defaultDay?.id;
        _incidents = null;
      });
      if (defaultDay != null) {
        await _loadDay(defaultDay.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'BF-Tage konnten nicht geladen werden.');
    }
  }

  Future<void> _loadDay(String dayId) async {
    try {
      final incidents = await ref.read(incidentRepositoryProvider).list(dayId);
      if (!mounted) return;
      setState(() => _incidents = incidents);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Einsätze konnten nicht geladen werden.');
    }
  }

  Future<void> _reload() async {
    final dayId = _selectedDayId;
    if (dayId == null) return;
    await _loadDay(dayId);
  }

  void _selectDay(String dayId) {
    if (dayId == _selectedDayId) return;
    setState(() {
      _selectedDayId = dayId;
      _incidents = null;
    });
    unawaited(_loadDay(dayId));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateDialog() async {
    final day = _selectedDay;
    if (day == null) return;
    final result = await showDialog<_IncidentFormResult>(
      context: context,
      builder: (context) => const _IncidentFormDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(incidentRepositoryProvider).create(
            day.id,
            keyword: result.keyword,
            address: result.address,
            report: result.report,
            script: result.script,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeIncidentError(error, fallback: 'Einsatz konnte nicht angelegt werden.'),
      );
    }
  }

  Future<void> _openEditDialog(Incident incident) async {
    final result = await showDialog<_IncidentFormResult>(
      context: context,
      builder: (context) => _IncidentFormDialog(incident: incident),
    );
    if (result == null) return;
    try {
      await ref.read(incidentRepositoryProvider).update(
            incident.id,
            keyword: result.keyword,
            address: result.address,
            report: result.report,
            script: result.script,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeIncidentError(error, fallback: 'Einsatz konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _openAlarmDialog(Incident incident) async {
    final triggered = await showDialog<bool>(
      context: context,
      builder: (context) => _AlarmDialog(incident: incident),
    );
    if (triggered == true) {
      await _reload();
    }
  }

  Future<void> _discard(Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einsatz verwerfen'),
        content: Text(
          'Einsatz #${incident.number} "${incident.keyword}" wirklich verwerfen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('confirm-dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(incidentRepositoryProvider).discard(incident.id);
      await _reload();
    } catch (error) {
      _showError(
        describeIncidentError(error, fallback: 'Einsatz konnte nicht verworfen werden.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canAlarm =
        permission == Permission.dispatch || permission == Permission.admin;
    final days = _days;
    final day = _selectedDay;
    final dayEnded = day?.state == BfDayState.ended;
    final incidents = _filteredIncidents;

    return Scaffold(
      appBar: AppBar(title: const Text('Einsätze')),
      floatingActionButton: day == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('create-incident'),
              onPressed: dayEnded ? null : _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Einsatz anlegen'),
            ),
      body: days == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : days.isEmpty
              ? const Center(child: Text('Keine BF-Tage angelegt.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        key: const Key('bf-day-dropdown'),
                        value: _selectedDayId,
                        items: [
                          for (final d in days)
                            DropdownMenuItem(value: d.id, child: Text(d.name)),
                        ],
                        onChanged: (value) {
                          if (value != null) _selectDay(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (day != null) ...[
                        SegmentedButton<IncidentState>(
                          key: const Key('incident-filter'),
                          segments: const [
                            ButtonSegment(
                              value: IncidentState.draft,
                              label: Text('Entwurf'),
                            ),
                            ButtonSegment(
                              value: IncidentState.running,
                              label: Text('laufend'),
                            ),
                            ButtonSegment(
                              value: IncidentState.closed,
                              label: Text('abgeschlossen'),
                            ),
                          ],
                          selected: {_filter},
                          onSelectionChanged: (selection) {
                            setState(() => _filter = selection.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_incidents == null)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (incidents.isEmpty)
                          const Expanded(
                            child: Center(child: Text('Keine Einsätze vorhanden.')),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              key: const Key('incidents-list'),
                              itemCount: incidents.length,
                              itemBuilder: (context, index) {
                                final incident = incidents[index];
                                return ListTile(
                                  key: Key('incident-${incident.id}'),
                                  title: Text(
                                    '#${incident.number} ${incident.keyword} – ${incident.address}',
                                  ),
                                  onTap: () => _openEditDialog(incident),
                                  trailing: Wrap(
                                    spacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Chip(
                                        key: Key('incident-state-${incident.id}'),
                                        label: Text(_stateChipLabel(incident.state)),
                                      ),
                                      if (incident.state == IncidentState.draft &&
                                          canAlarm)
                                        IconButton(
                                          key: Key('alarm-incident-${incident.id}'),
                                          icon: const Icon(Icons.campaign),
                                          tooltip: 'Alarmieren',
                                          onPressed: () => _openAlarmDialog(incident),
                                        ),
                                      if (incident.state == IncidentState.draft)
                                        IconButton(
                                          key: Key('discard-incident-${incident.id}'),
                                          icon: const Icon(Icons.delete_outline),
                                          tooltip: 'Verwerfen',
                                          onPressed: () => _discard(incident),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _IncidentFormResult {
  const _IncidentFormResult({
    required this.keyword,
    required this.address,
    required this.report,
    required this.script,
  });

  final String keyword;
  final String address;
  final String report;
  final String script;
}

/// Editor dialog with two clearly separated sections (ADR 0016): Meldebild
/// (Stichwort, Adresse, Lagebeschreibung) and -- in a visually distinct,
/// warning-coloured container with lock icon -- the geheime Drehbuch.
/// Read-only once the Einsatz is `closed`.
class _IncidentFormDialog extends StatefulWidget {
  const _IncidentFormDialog({this.incident});

  final Incident? incident;

  @override
  State<_IncidentFormDialog> createState() => _IncidentFormDialogState();
}

class _IncidentFormDialogState extends State<_IncidentFormDialog> {
  late final TextEditingController _keywordController;
  late final TextEditingController _addressController;
  late final TextEditingController _reportController;
  late final TextEditingController _scriptController;

  @override
  void initState() {
    super.initState();
    final incident = widget.incident;
    _keywordController = TextEditingController(text: incident?.keyword ?? '');
    _addressController = TextEditingController(text: incident?.address ?? '');
    _reportController = TextEditingController(text: incident?.report ?? '');
    _scriptController = TextEditingController(text: incident?.script ?? '');
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _addressController.dispose();
    _reportController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _IncidentFormResult(
        keyword: _keywordController.text.trim(),
        address: _addressController.text.trim(),
        report: _reportController.text.trim(),
        script: _scriptController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final isEdit = incident != null;
    final readOnly = incident?.state == IncidentState.closed;

    return AlertDialog(
      title: Text(isEdit ? 'Einsatz bearbeiten' : 'Einsatz anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meldebild', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('incident-form-keyword'),
              controller: _keywordController,
              readOnly: readOnly,
              decoration: const InputDecoration(labelText: 'Stichwort'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('incident-form-address'),
              controller: _addressController,
              readOnly: readOnly,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('incident-form-report'),
              controller: _reportController,
              readOnly: readOnly,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Lagebeschreibung'),
            ),
            const SizedBox(height: 16),
            Container(
              key: const Key('script-section'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                border: Border.all(color: Colors.amber.shade800, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Drehbuch – GEHEIM, nie für die Mannschaft sichtbar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('incident-form-script'),
                    controller: _scriptController,
                    readOnly: readOnly,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Drehbuch'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        if (!readOnly)
          FilledButton(
            key: const Key('incident-form-submit'),
            onPressed: _submit,
            child: const Text('Speichern'),
          ),
      ],
    );
  }
}

/// Alarmieren-Dialog (ADR 0017): Fahrzeugauswahl aus den aktiven
/// Fahrzeugen, Vorabwarnung bei Doppelbesetzung (berechnet aus der
/// aktuellen Schicht, ohne Serverantwort), und `POST
/// /incidents/{id}/alarms` mit einer beim Öffnen des Dialogs einmalig
/// erzeugten Idempotenz-`id` -- ein erneuter Klick auf "Jetzt alarmieren"
/// mit derselben Auswahl erzeugt keine zweite Alarmierung.
class _AlarmDialog extends ConsumerStatefulWidget {
  const _AlarmDialog({required this.incident});

  final Incident incident;

  @override
  ConsumerState<_AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends ConsumerState<_AlarmDialog> {
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
            widget.incident.id,
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
      title: Text(
        'Einsatz #${widget.incident.number} "${widget.incident.keyword}" alarmieren',
      ),
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
