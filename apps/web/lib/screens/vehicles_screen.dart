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
      final vehicles = await ref.read(vehicleAdminRepositoryProvider).listAll();
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fahrzeuge'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: spacing.lg),
            child: FilledButton.icon(
              key: const Key('create-vehicle'),
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Fahrzeug anlegen'),
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final vehicles = _vehicles;
    if (vehicles == null) {
      final loadError = _loadError;
      if (loadError != null) {
        return BftagStateView.error(message: loadError, onRetry: _reload);
      }
      return const BftagStateView.loading();
    }
    if (vehicles.isEmpty) {
      return BftagStateView.empty(
        icon: Icons.local_shipping_outlined,
        title: 'Noch keine Fahrzeuge angelegt.',
        action: FilledButton.icon(
          key: const Key('vehicles-empty-create'),
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Fahrzeug anlegen'),
        ),
      );
    }

    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radii.large),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.lg,
                    vertical: spacing.sm,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Funkrufname',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Kurzname',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Typ', style: theme.textTheme.titleMedium),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Aktiv',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    key: const Key('vehicles-list'),
                    padding: EdgeInsets.zero,
                    itemCount: vehicles.length,
                    onReorderItem: _reorder,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return _VehicleRow(
                        key: ValueKey(vehicle.id),
                        vehicle: vehicle,
                        index: index,
                        isLast: index == vehicles.length - 1,
                        onTap: () => _openEditDialog(vehicle),
                        onToggleActive: (value) =>
                            _toggleActive(vehicle, value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({
    super.key,
    required this.vehicle,
    required this.index,
    required this.isLast,
    required this.onTap,
    required this.onToggleActive,
  });

  final Vehicle vehicle;
  final int index;
  final bool isLast;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final isActive = vehicle.active;
    final content = Opacity(
      opacity: isActive ? 1 : 0.6,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.lg,
                vertical: spacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Semantics(
                      container: true,
                      label: 'Ziehen zum Sortieren: ${vehicle.callSign}',
                      child: ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_indicator,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(vehicle.callSign)),
                        if (!isActive) ...[
                          SizedBox(width: spacing.sm),
                          Text(
                            'inaktiv',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text(vehicle.shortName)),
                  Expanded(flex: 2, child: Text(vehicle.type)),
                  SizedBox(
                    width: 80,
                    child: Switch(
                      key: Key('active-switch-${vehicle.id}'),
                      value: vehicle.active,
                      onChanged: onToggleActive,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isLast) Divider(height: 1, color: theme.colorScheme.outline),
        ],
      ),
    );
    return content;
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
  String? _callSignError;
  String? _shortNameError;
  String? _typeError;

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
    final callSign = _callSignController.text.trim();
    final shortName = _shortNameController.text.trim();
    final type = _typeController.text.trim();
    setState(() {
      _callSignError = callSign.isEmpty ? 'Pflichtfeld' : null;
      _shortNameError = shortName.isEmpty ? 'Pflichtfeld' : null;
      _typeError = type.isEmpty ? 'Pflichtfeld' : null;
    });
    if (callSign.isEmpty || shortName.isEmpty || type.isEmpty) return;
    Navigator.of(context).pop(
      _VehicleFormResult(callSign: callSign, shortName: shortName, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Fahrzeug bearbeiten' : 'Fahrzeug anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('vehicle-form-call-sign'),
              controller: _callSignController,
              decoration: InputDecoration(
                labelText: 'Funkrufname',
                errorText: _callSignError,
              ),
            ),
            TextField(
              key: const Key('vehicle-form-short-name'),
              controller: _shortNameController,
              decoration: InputDecoration(
                labelText: 'Kurzname',
                errorText: _shortNameError,
              ),
            ),
            TextField(
              key: const Key('vehicle-form-type'),
              controller: _typeController,
              decoration: InputDecoration(
                labelText: 'Typ',
                errorText: _typeError,
              ),
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Vorschläge',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
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
