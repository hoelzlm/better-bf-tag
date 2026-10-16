import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';
import 'shifts_screen.dart' show pickDefaultBfDay;

String _twoDigits(int n) => n.toString().padLeft(2, '0');

String _formatTimeRange(DateTime startsAt, DateTime endsAt) {
  final start = startsAt.toLocal();
  final end = endsAt.toLocal();
  return '${_twoDigits(start.hour)}:${_twoDigits(start.minute)}–'
      '${_twoDigits(end.hour)}:${_twoDigits(end.minute)}';
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_twoDigits(local.day)}.${_twoDigits(local.month)}.${local.year} '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

IconData _iconFor(ProgramItemType type) {
  switch (type) {
    case ProgramItemType.meal:
      return Icons.restaurant;
    case ProgramItemType.training:
      return Icons.school;
    case ProgramItemType.maintenance:
      return Icons.build;
    case ProgramItemType.rest:
      return Icons.bedtime;
    case ProgramItemType.other:
      return Icons.event;
  }
}

List<ProgramItem> _sortedItems(List<ProgramItem> items) {
  final sorted = List<ProgramItem>.of(items)
    ..sort((a, b) {
      final byStart = a.startsAt.compareTo(b.startsAt);
      if (byStart != 0) return byStart;
      final byEnd = a.endsAt.compareTo(b.endsAt);
      if (byEnd != 0) return byEnd;
      return a.id.compareTo(b.id);
    });
  return sorted;
}

Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
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

/// Tagesablauf admin screen (`/admin/tagesablauf`, Berechtigung Leitstelle
/// oder Administrator, ADR 0025): BF-Tag-Auswahl wie die Schichten-Seite,
/// Liste der Programmpunkte nach Zeit, Anlegen/Bearbeiten/Löschen per
/// Dialog. BF-Tag `ended` -> nur lesend.
///
/// Concept: `docs/design/screens/web-tagesablauf.md`. "Programmpunkt
/// anlegen" ist `primary` (korrigiert die frühere `alarm`-Farbverletzung)
/// und wandert in den AppBar-Topbar neben die BF-Tag-Auswahl; Typ-Icon
/// sitzt in einer `primaryContainer`-Kachel statt nacktem Icon.
class ProgramScreen extends ConsumerStatefulWidget {
  const ProgramScreen({super.key});

  @override
  ConsumerState<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends ConsumerState<ProgramScreen> {
  List<BfDay>? _days;
  String? _selectedDayId;
  List<ProgramItem>? _items;
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

  Future<void> _loadDays() async {
    try {
      final days = await ref.read(bfDayAdminRepositoryProvider).list();
      if (!mounted) return;
      final defaultDay = pickDefaultBfDay(days);
      setState(() {
        _days = days;
        _loadError = null;
        _selectedDayId = defaultDay?.id;
        _items = null;
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
      final items = await ref.read(programItemRepositoryProvider).list(dayId);
      if (!mounted) return;
      setState(() => _items = _sortedItems(items));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _loadError = 'Programmpunkte konnten nicht geladen werden.',
      );
    }
  }

  void _selectDay(String dayId) {
    if (dayId == _selectedDayId) return;
    setState(() {
      _selectedDayId = dayId;
      _items = null;
    });
    unawaited(_loadDay(dayId));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateDialog() async {
    final day = _selectedDay;
    if (day == null) return;
    final result = await showDialog<_ProgramItemFormResult>(
      context: context,
      builder: (context) => _ProgramItemFormDialog(
        initialStart: day.startsAt,
        initialEnd: day.endsAt,
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(programItemRepositoryProvider)
          .create(
            day.id,
            title: result.title,
            type: result.type,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
          );
      await _loadDay(day.id);
    } catch (error) {
      _showError(describeProgramItemError(error));
    }
  }

  Future<void> _openEditDialog(ProgramItem item) async {
    final day = _selectedDay;
    if (day == null) return;
    final result = await showDialog<_ProgramItemFormResult>(
      context: context,
      builder: (context) => _ProgramItemFormDialog(
        title: item.title,
        type: item.type,
        initialStart: item.startsAt,
        initialEnd: item.endsAt,
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(programItemRepositoryProvider)
          .update(
            item.id,
            title: result.title,
            type: result.type,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
          );
      await _loadDay(day.id);
    } catch (error) {
      _showError(describeProgramItemError(error));
    }
  }

  Future<void> _deleteItem(ProgramItem item) async {
    final day = _selectedDay;
    if (day == null) return;
    final confirmed = await _confirm(
      context,
      title: 'Programmpunkt löschen',
      message: '"${item.title}" wirklich löschen?',
      confirmLabel: 'Löschen',
    );
    if (!confirmed) return;
    try {
      await ref.read(programItemRepositoryProvider).delete(item.id);
      await _loadDay(day.id);
    } catch (error) {
      _showError(describeProgramItemError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final days = _days;
    final day = _selectedDay;
    final items = _items ?? const <ProgramItem>[];
    final dayEnded = day?.state == BfDayState.ended;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagesablauf'),
        actions: [
          if (days != null && days.isNotEmpty) ...[
            if (dayEnded) ...[
              Icon(
                Icons.lock_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: spacing.xs),
              Padding(
                padding: EdgeInsets.only(right: spacing.md),
                child: Text(
                  'Dieser BF-Tag ist beendet — nur lesend',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            Text(
              'BF-Tag:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: spacing.sm),
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
            SizedBox(width: spacing.md),
            if (day != null)
              Padding(
                padding: EdgeInsets.only(right: spacing.lg),
                child: FilledButton.icon(
                  key: const Key('program-add'),
                  onPressed: dayEnded ? null : _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Programmpunkt anlegen'),
                ),
              ),
          ],
        ],
      ),
      body: days == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          : days.isEmpty
          ? const BftagStateView.empty(
              title: 'Keine BF-Tage angelegt.',
              icon: Icons.event_busy_outlined,
            )
          : day == null
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: _items == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : items.isEmpty
                  ? BftagStateView.empty(
                      title: 'Keine Programmpunkte vorhanden.',
                      icon: Icons.event_note,
                      action: dayEnded
                          ? null
                          : FilledButton.icon(
                              key: const Key('program-empty-create'),
                              onPressed: _openCreateDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Programmpunkt anlegen'),
                            ),
                    )
                  : ListView.separated(
                      key: const Key('program-list'),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: theme.colorScheme.outline),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _ProgramRow(
                          item: item,
                          readOnly: dayEnded,
                          onEdit: () => _openEditDialog(item),
                          onDelete: () => _deleteItem(item),
                        );
                      },
                    ),
            ),
    );
  }
}

/// Programmpunkt-Zeile (web-tagesablauf.md §3): feste Zeitspalte links,
/// Typ-Icon in einer farbigen `primaryContainer`-Kachel statt nacktem
/// Icon, Bearbeiten-/Löschen-Icons mit 8 dp Abstand und ≥ 40 dp
/// Klickfläche.
class _ProgramRow extends StatelessWidget {
  const _ProgramRow({
    required this.item,
    required this.readOnly,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgramItem item;
  final bool readOnly;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    return Padding(
      key: Key('program-item-${item.id}'),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              _formatTimeRange(item.startsAt, item.endsAt),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Container(
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(radii.small),
            ),
            child: Icon(_iconFor(item.type), color: theme.colorScheme.primary),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleMedium),
                Text(
                  item.type.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!readOnly) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                key: Key('program-edit-${item.id}'),
                icon: const Icon(Icons.edit),
                tooltip: 'Bearbeiten',
                onPressed: onEdit,
              ),
            ),
            SizedBox(width: spacing.sm),
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                key: Key('program-delete-${item.id}'),
                icon: const Icon(Icons.delete),
                tooltip: 'Löschen',
                onPressed: onDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgramItemFormResult {
  const _ProgramItemFormResult({
    required this.title,
    required this.type,
    required this.startsAt,
    required this.endsAt,
  });

  final String title;
  final ProgramItemType type;
  final DateTime startsAt;
  final DateTime endsAt;
}

class _ProgramItemFormDialog extends StatefulWidget {
  const _ProgramItemFormDialog({
    this.title,
    this.type,
    required this.initialStart,
    required this.initialEnd,
  });

  final String? title;
  final ProgramItemType? type;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_ProgramItemFormDialog> createState() => _ProgramItemFormDialogState();
}

class _ProgramItemFormDialogState extends State<_ProgramItemFormDialog> {
  late final TextEditingController _titleController;
  late ProgramItemType _type;
  late DateTime _startsAt;
  late DateTime _endsAt;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title ?? '');
    _type = widget.type ?? ProgramItemType.other;
    _startsAt = widget.initialStart;
    _endsAt = widget.initialEnd;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    final title = _titleController.text.trim();
    if (title.isEmpty || title.length > 80) return;
    if (!_endsAt.isAfter(_startsAt)) {
      setState(() => _rangeError = 'Ende muss nach Start liegen.');
      return;
    }
    Navigator.of(context).pop(
      _ProgramItemFormResult(
        title: title,
        type: _type,
        startsAt: _startsAt,
        endsAt: _endsAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.title != null;
    return AlertDialog(
      title: Text(
        isEdit ? 'Programmpunkt bearbeiten' : 'Programmpunkt anlegen',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('program-form-title'),
              controller: _titleController,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 12),
            DropdownButton<ProgramItemType>(
              key: const Key('program-form-type'),
              value: _type,
              items: [
                for (final type in ProgramItemType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('program-form-start'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Start'),
              subtitle: Text(_formatDateTime(_startsAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickStart,
            ),
            ListTile(
              key: const Key('program-form-end'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Ende'),
              subtitle: Text(_formatDateTime(_endsAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickEnd,
            ),
            if (_rangeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _rangeError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
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
          key: const Key('program-form-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
