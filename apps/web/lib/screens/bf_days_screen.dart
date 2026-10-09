import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';

String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

/// Next full hour after [now], i.e. the default `starts_at` for a new
/// BF-Tag (card spec).
DateTime _nextFullHour(DateTime now) {
  final truncated = DateTime(now.year, now.month, now.day, now.hour);
  return truncated.add(const Duration(hours: 1));
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ja',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('confirm-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<DateTime?> _pickDateTime(
  BuildContext context,
  DateTime initial,
) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(initial.year - 1),
    lastDate: DateTime(initial.year + 2),
  );
  if (date == null) return null;
  if (!context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// BF-Tage admin screen (`/admin/bf-tage`, Berechtigung Leitstelle oder
/// Administrator, ADR 0013/0020): BF-Tage anlegen/bearbeiten,
/// starten/beenden, Teilnahmen verwalten und anonymisieren. Anlegen,
/// Bearbeiten, Starten/Beenden und Teilnahmen bleiben nur für
/// Administratoren sichtbar; Anonymisieren ist auch für die Leitstelle
/// verfügbar.
///
/// Loads `GET /bf-days` once on entry and after every mutation -- there is
/// no realtime subscription here (same pattern as VehiclesScreen).
class BfDaysScreen extends ConsumerStatefulWidget {
  const BfDaysScreen({super.key});

  @override
  ConsumerState<BfDaysScreen> createState() => _BfDaysScreenState();
}

class _BfDaysScreenState extends ConsumerState<BfDaysScreen> {
  List<BfDay>? _days;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final days = await ref.read(bfDayAdminRepositoryProvider).list();
      if (!mounted) return;
      setState(() {
        _days = days;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'BF-Tage konnten nicht geladen werden.';
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateDialog() async {
    final now = DateTime.now();
    final start = _nextFullHour(now);
    final result = await showDialog<_BfDayFormResult>(
      context: context,
      builder: (context) => _BfDayFormDialog(
        initialStart: start,
        initialEnd: start.add(const Duration(hours: 24)),
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(bfDayAdminRepositoryProvider)
          .create(
            name: result.name,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'BF-Tag konnte nicht angelegt werden.'),
      );
    }
  }

  Future<void> _openEditDialog(BfDay day) async {
    final result = await showDialog<_BfDayFormResult>(
      context: context,
      builder: (context) => _BfDayFormDialog(
        name: day.name,
        initialStart: day.startsAt,
        initialEnd: day.endsAt,
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(bfDayAdminRepositoryProvider)
          .update(
            day.id,
            name: result.name,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'BF-Tag konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _start(BfDay day) async {
    final confirmed = await _confirm(
      context,
      title: 'BF-Tag starten',
      message: '"${day.name}" jetzt starten?',
      confirmLabel: 'Starten',
    );
    if (!confirmed) return;
    try {
      await ref.read(bfDayAdminRepositoryProvider).start(day.id);
      await _reload();
    } catch (error) {
      _showError(describeApiError(error, 'BF-Tag konnte nicht gestartet werden.'));
    }
  }

  Future<void> _end(BfDay day) async {
    final confirmed = await _confirm(
      context,
      title: 'BF-Tag beenden',
      message: '"${day.name}" jetzt beenden?',
      confirmLabel: 'Beenden',
    );
    if (!confirmed) return;
    try {
      await ref.read(bfDayAdminRepositoryProvider).end(day.id);
      await _reload();
    } catch (error) {
      _showError(describeApiError(error, 'BF-Tag konnte nicht beendet werden.'));
    }
  }

  Future<void> _openParticipantsDialog(BfDay day) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ParticipantsDialog(day: day),
    );
  }

  Future<void> _openAnonymizeDialog(BfDay day) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _AnonymizeDialog(day: day),
    );
    if (confirmed != true) return;
    try {
      await ref.read(bfDayAdminRepositoryProvider).anonymize(day.id);
      await _reload();
      _showError('BF-Tag anonymisiert.');
    } catch (error) {
      _showError(describeAnonymizationError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final isAdmin = permission == Permission.admin;
    final isDispatchOrAdmin =
        isAdmin || permission == Permission.dispatch;
    final days = _days;
    return Scaffold(
      appBar: AppBar(title: const Text('BF-Tage')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              key: const Key('create-bf-day'),
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('BF-Tag anlegen'),
            )
          : null,
      body: days == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : ListView.builder(
              key: const Key('bf-days-list'),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isPlanning = day.state == BfDayState.planning;
                final isRunning = day.state == BfDayState.running;
                final isEnded = day.state == BfDayState.ended;
                return ListTile(
                  key: Key('bf-day-${day.id}'),
                  title: Text(day.name),
                  subtitle: Text(
                    '${_formatDateTime(day.startsAt)} – '
                    '${_formatDateTime(day.endsAt)}',
                  ),
                  onTap: isPlanning && isAdmin
                      ? () => _openEditDialog(day)
                      : null,
                  trailing: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        key: Key('bf-day-state-${day.id}'),
                        label: Text(day.state.label),
                      ),
                      if (isAdmin)
                        IconButton(
                          key: Key('bf-day-participants-${day.id}'),
                          icon: const Icon(Icons.groups),
                          tooltip: 'Teilnahmen',
                          onPressed: () => _openParticipantsDialog(day),
                        ),
                      if (isPlanning && isAdmin)
                        TextButton(
                          key: Key('bf-day-start-${day.id}'),
                          onPressed: () => _start(day),
                          child: const Text('Starten'),
                        ),
                      if (isRunning && isAdmin)
                        TextButton(
                          key: Key('bf-day-end-${day.id}'),
                          onPressed: () => _end(day),
                          child: const Text('Beenden'),
                        ),
                      if (isEnded && day.isAnonymized)
                        Text(
                          key: Key('bf-day-anonymized-${day.id}'),
                          'Anonymisiert am '
                          '${_formatDateTime(day.anonymizedAt!)}',
                        ),
                      if (isEnded && !day.isAnonymized && isDispatchOrAdmin)
                        TextButton(
                          key: Key('bf-day-anonymize-${day.id}'),
                          onPressed: () => _openAnonymizeDialog(day),
                          child: const Text('Anonymisieren'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _BfDayFormResult {
  const _BfDayFormResult({
    required this.name,
    required this.startsAt,
    required this.endsAt,
  });

  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
}

class _BfDayFormDialog extends StatefulWidget {
  const _BfDayFormDialog({
    this.name,
    required this.initialStart,
    required this.initialEnd,
  });

  final String? name;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_BfDayFormDialog> createState() => _BfDayFormDialogState();
}

class _BfDayFormDialogState extends State<_BfDayFormDialog> {
  late final TextEditingController _nameController;
  late DateTime _startsAt;
  late DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name ?? '');
    _startsAt = widget.initialStart;
    _endsAt = widget.initialEnd;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(context, _startsAt);
    if (picked != null) setState(() => _startsAt = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(context, _endsAt);
    if (picked != null) setState(() => _endsAt = picked);
  }

  void _submit() {
    Navigator.of(context).pop(
      _BfDayFormResult(
        name: _nameController.text.trim(),
        startsAt: _startsAt,
        endsAt: _endsAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.name != null;
    return AlertDialog(
      title: Text(isEdit ? 'BF-Tag bearbeiten' : 'BF-Tag anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('bf-day-form-name'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('bf-day-form-start'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Start'),
              subtitle: Text(_formatDateTime(_startsAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickStart,
            ),
            ListTile(
              key: const Key('bf-day-form-end'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Ende'),
              subtitle: Text(_formatDateTime(_endsAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickEnd,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('bf-day-form-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _ParticipantsDialog extends ConsumerStatefulWidget {
  const _ParticipantsDialog({required this.day});

  final BfDay day;

  @override
  ConsumerState<_ParticipantsDialog> createState() =>
      _ParticipantsDialogState();
}

class _ParticipantsDialogState extends ConsumerState<_ParticipantsDialog> {
  List<Person>? _persons;
  Set<String>? _selectedPersonIds;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repository = ref.read(bfDayAdminRepositoryProvider);
      final persons =
          await ref.read(personAdminRepositoryProvider).listPersons();
      final participants = await repository.listParticipants(widget.day.id);
      if (!mounted) return;
      setState(() {
        _persons = persons.where((p) => p.active).toList();
        _selectedPersonIds = participants.map((p) => p.personId).toSet();
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Teilnahmen konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _save() async {
    final selected = _selectedPersonIds;
    if (selected == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(bfDayAdminRepositoryProvider)
          .setParticipants(widget.day.id, selected.toList());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeApiError(
              error,
              'Teilnahmen konnten nicht gespeichert werden.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persons = _persons;
    final selected = _selectedPersonIds;
    return AlertDialog(
      title: Text('Teilnahmen · ${widget.day.name}'),
      content: SizedBox(
        width: 420,
        child: persons == null || selected == null
            ? SizedBox(
                height: 80,
                child: Center(
                  child: _error != null
                      ? Text(_error!)
                      : const CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      TextButton(
                        key: const Key('participants-select-all'),
                        onPressed: () => setState(
                          () => selected
                            ..clear()
                            ..addAll(persons.map((p) => p.id)),
                        ),
                        child: const Text('Alle'),
                      ),
                      TextButton(
                        key: const Key('participants-select-none'),
                        onPressed: () => setState(selected.clear),
                        child: const Text('Keine'),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      key: const Key('participants-list'),
                      itemCount: persons.length,
                      itemBuilder: (context, index) {
                        final person = persons[index];
                        return CheckboxListTile(
                          key: Key('participant-${person.id}'),
                          title: Text(person.displayName),
                          subtitle: Text(person.personType.label),
                          value: selected.contains(person.id),
                          onChanged: (value) => setState(() {
                            if (value ?? false) {
                              selected.add(person.id);
                            } else {
                              selected.remove(person.id);
                            }
                          }),
                        );
                      },
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
        FilledButton(
          key: const Key('participants-submit'),
          onPressed: _saving || selected == null ? null : _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

/// Bestätigungsdialog für die Anonymisierung eines beendeten BF-Tags (ADR
/// 0020): lädt `GET /bf-days/{id}/anonymization-preview` und zeigt, was
/// gelöscht wird und was erhalten bleibt. Gibt bei Bestätigung `true`
/// zurück (der Aufruf von `anonymize` passiert im Aufrufer), bei
/// Abbrechen `false`/`null`.
class _AnonymizeDialog extends ConsumerStatefulWidget {
  const _AnonymizeDialog({required this.day});

  final BfDay day;

  @override
  ConsumerState<_AnonymizeDialog> createState() => _AnonymizeDialogState();
}

class _AnonymizeDialogState extends ConsumerState<_AnonymizeDialog> {
  AnonymizationSummary? _summary;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final summary = await ref
          .read(bfDayAdminRepositoryProvider)
          .anonymizationPreview(widget.day.id);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describeAnonymizationError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return AlertDialog(
      title: Text('BF-Tag anonymisieren · ${widget.day.name}'),
      content: SizedBox(
        width: 420,
        child: summary == null
            ? SizedBox(
                height: 80,
                child: Center(
                  child: _error != null
                      ? Text(_error!)
                      : const CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Folgendes wird endgültig gelöscht:'),
                  const SizedBox(height: 8),
                  Text('${summary.participations} Teilnahmen'),
                  Text('${summary.crewAssignments} Besatzungseinträge'),
                  Text(
                    '${summary.alarmRecipients} Empfänger und '
                    'Quittierungen',
                  ),
                  Text(
                    '${summary.personsDeleted} Personen anderer '
                    'Feuerwehren',
                  ),
                  Text(
                    'Personenbezug in ${summary.statusEvents} '
                    'Statusmeldungen wird entfernt',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Erhalten bleiben: Einsätze mit Meldebild und '
                    'Drehbuch, Alarmierungen, Fahrzeuge, Schichten.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Die Anonymisierung kann nicht rückgängig gemacht '
                    'werden.',
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('anonymize-dialog-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: summary == null
              ? null
              : () => Navigator.of(context).pop(true),
          child: const Text('Anonymisieren'),
        ),
      ],
    );
  }
}
