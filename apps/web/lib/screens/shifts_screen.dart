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

String _shortNameFor(List<Vehicle> vehicles, String vehicleId) {
  for (final vehicle in vehicles) {
    if (vehicle.id == vehicleId) return vehicle.shortName;
  }
  return vehicleId;
}

/// Picks the default BF-Tag for the Schichten screen (ADR 0013, "Web"):
/// the running one; else the planning one with the earliest `starts_at`;
/// else the one with the latest `starts_at`.
BfDay? pickDefaultBfDay(List<BfDay> days) {
  if (days.isEmpty) return null;
  for (final day in days) {
    if (day.state == BfDayState.running) return day;
  }
  final planning = days.where((d) => d.state == BfDayState.planning).toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  if (planning.isNotEmpty) return planning.first;
  final sorted = List<BfDay>.of(days)
    ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  return sorted.first;
}

List<Shift> _sortedShifts(List<Shift> shifts) {
  final sorted = List<Shift>.of(shifts)
    ..sort((a, b) {
      final byStart = a.startsAt.compareTo(b.startsAt);
      return byStart != 0 ? byStart : a.name.compareTo(b.name);
    });
  return sorted;
}

/// Drag payload for the Besatzungs-Board (ADR 0013): a participant dragged
/// either from the Teilnehmer-Liste ([fromVehicleId] null) or from an
/// existing crew chip on another vehicle (moving them).
class _CrewDragPayload {
  const _CrewDragPayload({required this.personId, this.fromVehicleId});

  final String personId;
  final String? fromVehicleId;
}

/// Schichten screen (`/admin/schichten`, Berechtigung Leitstelle oder
/// Administrator, ADR 0013): BF-Tag-Auswahl, Schichten als Tabs, und das
/// Besatzungs-Board mit Drag & Drop.
class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen> {
  List<BfDay>? _days;
  String? _selectedDayId;
  List<Shift>? _shifts;
  String? _selectedShiftId;
  List<Participant>? _participants;
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

  Shift? get _selectedShift {
    final shifts = _shifts;
    if (shifts == null) return null;
    for (final shift in shifts) {
      if (shift.id == _selectedShiftId) return shift;
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
        _shifts = null;
        _participants = null;
        _selectedShiftId = null;
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
      final shifts = await ref.read(shiftRepositoryProvider).listShifts(dayId);
      final participants =
          await ref.read(bfDayAdminRepositoryProvider).listParticipants(dayId);
      if (!mounted) return;
      final sorted = _sortedShifts(shifts);
      final current = currentShift(sorted, DateTime.now());
      setState(() {
        _shifts = sorted;
        _participants = participants;
        _selectedShiftId =
            current?.id ?? (sorted.isNotEmpty ? sorted.first.id : null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Schichten konnten nicht geladen werden.');
    }
  }

  Future<void> _reloadSelectedDay() async {
    final dayId = _selectedDayId;
    if (dayId == null) return;
    try {
      final shifts = await ref.read(shiftRepositoryProvider).listShifts(dayId);
      if (!mounted) return;
      final sorted = _sortedShifts(shifts);
      setState(() {
        _shifts = sorted;
        if (_selectedShiftId == null ||
            !sorted.any((s) => s.id == _selectedShiftId)) {
          _selectedShiftId = sorted.isNotEmpty ? sorted.first.id : null;
        }
      });
    } catch (_) {
      // Best-effort live refresh: keep showing the stale state.
    }
  }

  void _selectDay(String dayId) {
    if (dayId == _selectedDayId) return;
    setState(() {
      _selectedDayId = dayId;
      _shifts = null;
      _participants = null;
      _selectedShiftId = null;
    });
    unawaited(_loadDay(dayId));
  }

  void _selectShift(String shiftId) {
    setState(() => _selectedShiftId = shiftId);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateShiftDialog() async {
    final day = _selectedDay;
    if (day == null) return;
    final result = await showDialog<_ShiftFormResult>(
      context: context,
      builder: (context) => _ShiftFormDialog(
        initialStart: day.startsAt,
        initialEnd: day.endsAt,
      ),
    );
    if (result == null) return;
    try {
      await ref.read(shiftRepositoryProvider).createShift(
            day.id,
            name: result.name,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
          );
      await _reloadSelectedDay();
    } catch (error) {
      _showError(
        describeApiError(error, 'Schicht konnte nicht angelegt werden.'),
      );
    }
  }

  Future<void> _openEditShiftDialog(Shift shift) async {
    final day = _selectedDay;
    if (day == null) return;
    final result = await showDialog<_ShiftFormResult>(
      context: context,
      builder: (context) => _ShiftFormDialog(
        name: shift.name,
        initialStart: shift.startsAt,
        initialEnd: shift.endsAt,
      ),
    );
    if (result == null) return;
    try {
      await ref.read(shiftRepositoryProvider).updateShift(
            day.id,
            shift.id,
            name: result.name,
            startsAt: result.startsAt,
            endsAt: result.endsAt,
          );
      await _reloadSelectedDay();
    } catch (error) {
      _showError(
        describeApiError(error, 'Schicht konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _deleteShift(Shift shift) async {
    final day = _selectedDay;
    if (day == null) return;
    final confirmed = await _confirm(
      context,
      title: 'Schicht löschen',
      message: '"${shift.name}" wirklich löschen?',
      confirmLabel: 'Löschen',
    );
    if (!confirmed) return;
    try {
      await ref.read(shiftRepositoryProvider).deleteShift(day.id, shift.id);
      await _reloadSelectedDay();
    } catch (error) {
      _showError(
        describeApiError(error, 'Schicht konnte nicht gelöscht werden.'),
      );
    }
  }

  Future<String?> _pickFunction(BuildContext context, {String? initial}) {
    return showDialog<String>(
      context: context,
      builder: (context) => _FunctionDialog(initial: initial),
    );
  }

  Future<void> _setCrew(String shiftId, List<CrewAssignmentInput> assignments) async {
    try {
      final updated =
          await ref.read(shiftRepositoryProvider).setCrew(shiftId, assignments);
      if (!mounted) return;
      setState(() {
        final shifts = _shifts;
        if (shifts != null) {
          _shifts = [
            for (final s in shifts) if (s.id == updated.id) updated else s,
          ];
        }
      });
    } catch (error) {
      _showError(
        describeApiError(error, 'Besatzung konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _onDrop(_CrewDragPayload payload, String targetVehicleId) async {
    final shift = _selectedShift;
    if (shift == null) return;
    final function = await _pickFunction(context);
    if (function == null || function.isEmpty) return;
    if (!mounted) return;
    final assignments = <CrewAssignmentInput>[
      for (final c in shift.crew)
        if (!(payload.fromVehicleId != null &&
            c.vehicleId == payload.fromVehicleId &&
            c.personId == payload.personId))
          CrewAssignmentInput(
            vehicleId: c.vehicleId,
            personId: c.personId,
            function: c.function,
          ),
      CrewAssignmentInput(
        vehicleId: targetVehicleId,
        personId: payload.personId,
        function: function,
      ),
    ];
    await _setCrew(shift.id, assignments);
  }

  Future<void> _removeAssignment(String vehicleId, String personId) async {
    final shift = _selectedShift;
    if (shift == null) return;
    final assignments = [
      for (final c in shift.crew)
        if (!(c.vehicleId == vehicleId && c.personId == personId))
          CrewAssignmentInput(
            vehicleId: c.vehicleId,
            personId: c.personId,
            function: c.function,
          ),
    ];
    await _setCrew(shift.id, assignments);
  }

  Future<void> _changeFunction(
    String vehicleId,
    String personId,
    String currentFunction,
  ) async {
    final shift = _selectedShift;
    if (shift == null) return;
    final newFunction = await _pickFunction(context, initial: currentFunction);
    if (newFunction == null || newFunction.isEmpty) return;
    if (!mounted) return;
    final assignments = [
      for (final c in shift.crew)
        CrewAssignmentInput(
          vehicleId: c.vehicleId,
          personId: c.personId,
          function: c.vehicleId == vehicleId && c.personId == personId
              ? newFunction
              : c.function,
        ),
    ];
    await _setCrew(shift.id, assignments);
  }

  Map<String, Set<String>> _vehiclesByPerson(Shift shift) {
    final map = <String, Set<String>>{};
    for (final c in shift.crew) {
      map.putIfAbsent(c.personId, () => <String>{}).add(c.vehicleId);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(shiftsProvider, (previous, next) {
      if (next.hasValue) {
        unawaited(_reloadSelectedDay());
      }
    });
    ref.listen(bfDayProvider, (previous, next) {
      unawaited(_reloadSelectedDay());
    });

    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final days = _days;
    final day = _selectedDay;
    final shifts = _shifts;
    final shift = _selectedShift;
    final participants = _participants ?? const <Participant>[];
    final dayEnded = day?.state == BfDayState.ended;
    final current = (day?.state == BfDayState.running && shifts != null)
        ? currentShift(shifts, DateTime.now())
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Schichten')),
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
                        Wrap(
                          key: const Key('shift-tabs'),
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in shifts ?? const <Shift>[])
                              ChoiceChip(
                                key: Key('shift-tab-${s.id}'),
                                label: Text(
                                  s.id == current?.id
                                      ? '${s.name} (aktuell)'
                                      : s.name,
                                ),
                                selected: s.id == _selectedShiftId,
                                onSelected: (_) => _selectShift(s.id),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FilledButton.icon(
                              key: const Key('create-shift'),
                              onPressed:
                                  dayEnded ? null : _openCreateShiftDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Schicht anlegen'),
                            ),
                            if (shift != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                key: const Key('edit-shift'),
                                onPressed: dayEnded
                                    ? null
                                    : () => _openEditShiftDialog(shift),
                                icon: const Icon(Icons.edit),
                                tooltip: dayEnded
                                    ? 'BF-Tag ist beendet'
                                    : 'Schicht bearbeiten',
                              ),
                              IconButton(
                                key: const Key('delete-shift'),
                                onPressed:
                                    dayEnded ? null : () => _deleteShift(shift),
                                icon: const Icon(Icons.delete),
                                tooltip: dayEnded
                                    ? 'BF-Tag ist beendet'
                                    : 'Schicht löschen',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_shifts == null)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (shift == null)
                          const Expanded(
                            child: Center(child: Text('Keine Schicht vorhanden.')),
                          )
                        else
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ParticipantsColumn(
                                  participants: participants,
                                  shift: shift,
                                  vehicles: vehicles,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Wrap(
                                      key: const Key('vehicle-cards'),
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        for (final v in vehicles)
                                          _VehicleCard(
                                            vehicle: v,
                                            crew: shift.crew
                                                .where((c) => c.vehicleId == v.id)
                                                .toList(),
                                            doubleBooked: _vehiclesByPerson(shift),
                                            vehicles: vehicles,
                                            onDrop: (payload) =>
                                                _onDrop(payload, v.id),
                                            onRemove: _removeAssignment,
                                            onChangeFunction: _changeFunction,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _ParticipantsColumn extends StatelessWidget {
  const _ParticipantsColumn({
    required this.participants,
    required this.shift,
    required this.vehicles,
  });

  final List<Participant> participants;
  final Shift shift;
  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    final unassigned = participants
        .where((p) => !shift.crew.any((c) => c.personId == p.personId))
        .toList();
    final assigned = participants
        .where((p) => shift.crew.any((c) => c.personId == p.personId))
        .toList();

    Widget chipFor(Participant p) {
      final assignedVehicleIds = shift.crew
          .where((c) => c.personId == p.personId)
          .map((c) => c.vehicleId)
          .toSet();
      final isDouble = assignedVehicleIds.length > 1;
      final chip = Chip(
        avatar: isDouble
            ? const Icon(Icons.warning, color: Colors.orange, size: 18)
            : null,
        label: Text(p.displayName),
        backgroundColor: assignedVehicleIds.isEmpty ? Colors.grey.shade300 : null,
      );
      final content = isDouble
          ? Tooltip(
              message:
                  'auch auf ${assignedVehicleIds.map((id) => _shortNameFor(vehicles, id)).join(', ')}',
              child: chip,
            )
          : chip;
      return Draggable<_CrewDragPayload>(
        key: Key('participant-draggable-${p.personId}'),
        data: _CrewDragPayload(personId: p.personId),
        feedback: Material(child: content),
        childWhenDragging: Opacity(opacity: 0.4, child: content),
        child: content,
      );
    }

    return SizedBox(
      width: 260,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nicht eingeteilt', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              key: const Key('unassigned-participants'),
              spacing: 6,
              runSpacing: 6,
              children: [for (final p in unassigned) chipFor(p)],
            ),
            const SizedBox(height: 16),
            const Text('Eingeteilt', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              key: const Key('assigned-participants'),
              spacing: 6,
              runSpacing: 6,
              children: [for (final p in assigned) chipFor(p)],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.crew,
    required this.doubleBooked,
    required this.vehicles,
    required this.onDrop,
    required this.onRemove,
    required this.onChangeFunction,
  });

  final Vehicle vehicle;
  final List<CrewAssignment> crew;
  final Map<String, Set<String>> doubleBooked;
  final List<Vehicle> vehicles;
  final void Function(_CrewDragPayload payload) onDrop;
  final void Function(String vehicleId, String personId) onRemove;
  final void Function(String vehicleId, String personId, String currentFunction)
      onChangeFunction;

  @override
  Widget build(BuildContext context) {
    final sortedCrew = List<CrewAssignment>.of(crew)
      ..sort((a, b) => compareCrewFunctions(a.function, b.function));

    return DragTarget<_CrewDragPayload>(
      key: Key('vehicle-dropzone-${vehicle.id}'),
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: Key('vehicle-card-${vehicle.id}'),
          width: 220,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.blue : Colors.grey,
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vehicle.shortName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (sortedCrew.isEmpty) const Text('—'),
              for (final a in sortedCrew)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _CrewEntry(
                    assignment: a,
                    allVehicleIds: doubleBooked[a.personId] ?? {a.vehicleId},
                    vehicles: vehicles,
                    onRemove: () => onRemove(a.vehicleId, a.personId),
                    onChangeFunction: () =>
                        onChangeFunction(a.vehicleId, a.personId, a.function),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CrewEntry extends StatelessWidget {
  const _CrewEntry({
    required this.assignment,
    required this.allVehicleIds,
    required this.vehicles,
    required this.onRemove,
    required this.onChangeFunction,
  });

  final CrewAssignment assignment;
  final Set<String> allVehicleIds;
  final List<Vehicle> vehicles;
  final VoidCallback onRemove;
  final VoidCallback onChangeFunction;

  @override
  Widget build(BuildContext context) {
    final isDouble = allVehicleIds.length > 1;
    final others = allVehicleIds
        .where((id) => id != assignment.vehicleId)
        .map((id) => _shortNameFor(vehicles, id))
        .toList();
    final chip = Chip(
      avatar: isDouble
          ? const Icon(Icons.warning, color: Colors.orange, size: 18)
          : null,
      label: Text(
        '${assignment.function} ${assignment.displayName}',
        overflow: TextOverflow.ellipsis,
      ),
    );
    final content = isDouble
        ? Tooltip(message: 'auch auf ${others.join(', ')}', child: chip)
        : chip;

    return Row(
      key: Key('crew-entry-${assignment.vehicleId}-${assignment.personId}'),
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Draggable<_CrewDragPayload>(
            data: _CrewDragPayload(
              personId: assignment.personId,
              fromVehicleId: assignment.vehicleId,
            ),
            feedback: Material(child: content),
            childWhenDragging: Opacity(opacity: 0.4, child: content),
            child: content,
          ),
        ),
        PopupMenuButton<String>(
          key: Key('crew-menu-${assignment.vehicleId}-${assignment.personId}'),
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (value) {
            if (value == 'change') onChangeFunction();
            if (value == 'remove') onRemove();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'change', child: Text('Funktion ändern')),
            PopupMenuItem(value: 'remove', child: Text('entfernen')),
          ],
        ),
      ],
    );
  }
}

class _ShiftFormResult {
  const _ShiftFormResult({
    required this.name,
    required this.startsAt,
    required this.endsAt,
  });

  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
}

class _ShiftFormDialog extends StatefulWidget {
  const _ShiftFormDialog({
    this.name,
    required this.initialStart,
    required this.initialEnd,
  });

  final String? name;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<_ShiftFormDialog> {
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
      _ShiftFormResult(
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
      title: Text(isEdit ? 'Schicht bearbeiten' : 'Schicht anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('shift-form-name'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('shift-form-start'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Start'),
              subtitle: Text(_formatDateTime(_startsAt)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickStart,
            ),
            ListTile(
              key: const Key('shift-form-end'),
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
          key: const Key('shift-form-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _FunctionDialog extends StatefulWidget {
  const _FunctionDialog({this.initial});

  final String? initial;

  @override
  State<_FunctionDialog> createState() => _FunctionDialogState();
}

class _FunctionDialogState extends State<_FunctionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final result = (value ?? _controller.text).trim();
    if (result.isEmpty) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Funktion wählen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in standardCrewFunctions)
                  ActionChip(
                    key: Key('function-btn-$f'),
                    label: Text(f),
                    onPressed: () => _submit(f),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('function-freetext'),
              controller: _controller,
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'Funktion (frei)'),
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
          key: const Key('function-submit'),
          onPressed: () => _submit(),
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }
}
