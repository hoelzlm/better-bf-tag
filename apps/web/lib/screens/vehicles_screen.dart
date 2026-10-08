import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _typeSuggestions = [
  'HLF',
  'LF',
  'TLF',
  'DLK',
  'RW',
  'ELW',
  'MTW',
  'RTW',
  'KTW',
];

/// Fahrzeuge admin screen (`/admin/fahrzeuge`, Berechtigung Administrator):
/// Stammdaten (Funkrufname, Kurzname, Typ, aktiv) und Sortierung.
///
/// Loads `GET /vehicles` (all vehicles, incl. inactive) once on entry and
/// after every mutation -- there is no realtime subscription here.
class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  List<Vehicle>? _vehicles;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final vehicles =
          await ref.read(vehicleAdminRepositoryProvider).listAll();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Fahrzeuge konnten nicht geladen werden.';
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
    final result = await showDialog<_VehicleFormResult>(
      context: context,
      builder: (context) => const _VehicleFormDialog(),
    );
    if (result == null) return;
    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .create(
            callSign: result.callSign,
            shortName: result.shortName,
            type: result.type,
          );
      await _reload();
    } catch (_) {
      _showError('Fahrzeug konnte nicht angelegt werden.');
    }
  }

  Future<void> _openEditDialog(Vehicle vehicle) async {
    final result = await showDialog<_VehicleFormResult>(
      context: context,
      builder: (context) => _VehicleFormDialog(initial: vehicle),
    );
    if (result == null) return;
    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .update(
            vehicle.id,
            callSign: result.callSign,
            shortName: result.shortName,
            type: result.type,
          );
      await _reload();
    } catch (_) {
      _showError('Fahrzeug konnte nicht gespeichert werden.');
    }
  }

  Future<void> _toggleActive(Vehicle vehicle, bool active) async {
    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .update(vehicle.id, active: active);
      await _reload();
    } catch (_) {
      _showError('Status konnte nicht geändert werden.');
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final vehicles = _vehicles;
    if (vehicles == null) return;
    final updated = List<Vehicle>.of(vehicles);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    setState(() => _vehicles = updated);
    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .reorder(updated.map((v) => v.id).toList());
      await _reload();
    } catch (_) {
      _showError('Reihenfolge konnte nicht gespeichert werden.');
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles;
    return Scaffold(
      appBar: AppBar(title: const Text('Fahrzeuge')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-vehicle'),
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Fahrzeug anlegen'),
      ),
      body: vehicles == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : ReorderableListView.builder(
              key: const Key('vehicles-list'),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: vehicles.length,
              onReorderItem: _reorder,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return ListTile(
                  key: ValueKey(vehicle.id),
                  title: Text('${vehicle.callSign} (${vehicle.shortName})'),
                  subtitle: Text(vehicle.type),
                  onTap: () => _openEditDialog(vehicle),
                  trailing: Switch(
                    key: Key('active-switch-${vehicle.id}'),
                    value: vehicle.active,
                    onChanged: (value) => _toggleActive(vehicle, value),
                  ),
                );
              },
            ),
    );
  }
}

class _VehicleFormResult {
  const _VehicleFormResult({
    required this.callSign,
    required this.shortName,
    required this.type,
  });

  final String callSign;
  final String shortName;
  final String type;
}

class _VehicleFormDialog extends StatefulWidget {
  const _VehicleFormDialog({this.initial});

  final Vehicle? initial;

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  late final TextEditingController _callSignController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _callSignController = TextEditingController(
      text: widget.initial?.callSign ?? '',
    );
    _shortNameController = TextEditingController(
      text: widget.initial?.shortName ?? '',
    );
    _typeController = TextEditingController(text: widget.initial?.type ?? '');
  }

  @override
  void dispose() {
    _callSignController.dispose();
    _shortNameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _VehicleFormResult(
        callSign: _callSignController.text.trim(),
        shortName: _shortNameController.text.trim(),
        type: _typeController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Fahrzeug bearbeiten' : 'Fahrzeug anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('vehicle-form-call-sign'),
              controller: _callSignController,
              decoration: const InputDecoration(labelText: 'Funkrufname'),
            ),
            TextField(
              key: const Key('vehicle-form-short-name'),
              controller: _shortNameController,
              decoration: const InputDecoration(labelText: 'Kurzname'),
            ),
            TextField(
              key: const Key('vehicle-form-type'),
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Typ'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                for (final suggestion in _typeSuggestions)
                  ActionChip(
                    key: Key('type-suggestion-$suggestion'),
                    label: Text(suggestion),
                    onPressed: () =>
                        setState(() => _typeController.text = suggestion),
                  ),
              ],
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
          key: const Key('vehicle-form-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
