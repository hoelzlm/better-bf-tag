// Funktisch: Statuseingabe der Leitstelle für den BF-Tag ohne Handys.
//
// Die Besatzungen melden ihren Status per Funk; die Leitstelle setzt ihn hier
// mit einem Klick (statt Kachel -> Dialog). Pro Fahrzeug eine Zeile mit den
// FMS-Tasten (1–6, RTW/KTW 1–8), dem aktuellen Status und seit wann.
//
// Tastatur: Zeile fokussieren (Klick auf den Namen oder Tab), Ziffer drücken
// setzt den Status; Pfeil hoch/runter wechselt das Fahrzeug.
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Funktisch extends ConsumerStatefulWidget {
  const Funktisch({super.key});

  @override
  ConsumerState<Funktisch> createState() => _FunktischState();
}

class _FunktischState extends ConsumerState<Funktisch> {
  final Map<String, FocusNode> _focusNodes = {};

  /// Vehicle ids with a status request in flight (buttons disabled).
  final Set<String> _pending = {};

  FocusNode _nodeFor(String vehicleId) =>
      _focusNodes.putIfAbsent(vehicleId, () => FocusNode());

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _setStatus(Vehicle vehicle, FmsStatus status) async {
    if (_pending.contains(vehicle.id)) return;
    setState(() => _pending.add(vehicle.id));
    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .setStatus(vehicle.id, status.code);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status ${status.code} für ${vehicle.shortName} konnte nicht '
              'gesetzt werden.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(vehicle.id));
    }
  }

  KeyEventResult _onKey(KeyEvent event, List<Vehicle> vehicles, int index) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown && index < vehicles.length - 1) {
      _nodeFor(vehicles[index + 1].id).requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp && index > 0) {
      _nodeFor(vehicles[index - 1].id).requestFocus();
      return KeyEventResult.handled;
    }
    final digit = _digitFor(key);
    if (digit == null) return KeyEventResult.ignored;
    final vehicle = vehicles[index];
    for (final status in offeredStatuses(vehicle.type)) {
      if (status.code == digit) {
        _setStatus(vehicle, status);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? const <Vehicle>[];
    final connection =
        ref.watch(realtimeConnectionProvider).valueOrNull ??
        ConnectionStatus.connecting;

    Widget body;
    if (vehiclesAsync.hasError && vehicles.isEmpty) {
      body = BftagStateView.error(
        message: 'Fahrzeuge konnten nicht geladen werden.',
        onRetry: () => ref.invalidate(vehiclesProvider),
      );
    } else if (vehiclesAsync.isLoading && vehicles.isEmpty) {
      body = const BftagStateView.loading();
    } else if (vehicles.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Keine aktiven Fahrzeuge.'),
      );
    } else {
      body = ListView.separated(
        key: const Key('funktisch-list'),
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        itemCount: vehicles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          return Focus(
            focusNode: _nodeFor(vehicle.id),
            onKeyEvent: (_, event) => _onKey(event, vehicles, index),
            child: Builder(
              builder: (context) => _FunktischRow(
                vehicle: vehicle,
                focused: Focus.of(context).hasFocus,
                pending: _pending.contains(vehicle.id),
                onFocus: () => _nodeFor(vehicle.id).requestFocus(),
                onStatus: (status) {
                  _nodeFor(vehicle.id).requestFocus();
                  _setStatus(vehicle, status);
                },
              ),
            ),
          );
        },
      );
    }

    return Column(
      key: const Key('funktisch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Text('Funktisch', style: theme.textTheme.titleMedium),
              const SizedBox(width: 12),
              Icon(
                connection == ConnectionStatus.live
                    ? Icons.circle
                    : Icons.sync_problem,
                size: 10,
                color: connection == ConnectionStatus.live
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                connection == ConnectionStatus.live ? 'live' : 'verbinde neu…',
                key: const Key('connection-indicator'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text(
            'Status per Funk → Taste klicken. Tastatur: Fahrzeug anklicken, '
            'Ziffer drücken, ↑/↓ wechselt das Fahrzeug.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

final _digits = <LogicalKeyboardKey, int>{
  LogicalKeyboardKey.digit1: 1,
  LogicalKeyboardKey.digit2: 2,
  LogicalKeyboardKey.digit3: 3,
  LogicalKeyboardKey.digit4: 4,
  LogicalKeyboardKey.digit5: 5,
  LogicalKeyboardKey.digit6: 6,
  LogicalKeyboardKey.digit7: 7,
  LogicalKeyboardKey.digit8: 8,
  LogicalKeyboardKey.numpad1: 1,
  LogicalKeyboardKey.numpad2: 2,
  LogicalKeyboardKey.numpad3: 3,
  LogicalKeyboardKey.numpad4: 4,
  LogicalKeyboardKey.numpad5: 5,
  LogicalKeyboardKey.numpad6: 6,
  LogicalKeyboardKey.numpad7: 7,
  LogicalKeyboardKey.numpad8: 8,
};

int? _digitFor(LogicalKeyboardKey key) => _digits[key];

class _FunktischRow extends StatelessWidget {
  const _FunktischRow({
    required this.vehicle,
    required this.focused,
    required this.pending,
    required this.onFocus,
    required this.onStatus,
  });

  final Vehicle vehicle;
  final bool focused;
  final bool pending;
  final VoidCallback onFocus;
  final ValueChanged<FmsStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<BftagStatusColors>()!;
    final changedAt = vehicle.statusChangedAt?.toLocal();
    final since = changedAt == null
        ? ''
        : ' · ${changedAt.hour.toString().padLeft(2, '0')}:'
              '${changedAt.minute.toString().padLeft(2, '0')}';

    return Material(
      key: Key('funktisch-row-${vehicle.id}'),
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: focused ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: Key('funktisch-select-${vehicle.id}'),
                onTap: onFocus,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicle.shortName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        vehicle.callSign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${vehicle.status.code} ${vehicle.status.label}$since',
                        key: Key('funktisch-current-${vehicle.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final status in offeredStatuses(vehicle.type))
                  _StatusKey(
                    key: Key('funktisch-${vehicle.id}-${status.code}'),
                    vehicleName: vehicle.shortName,
                    status: status,
                    current: status == vehicle.status,
                    color: statusColors.colorFor(status),
                    onColor: statusColors.onColorFor(status),
                    onPressed: pending ? null : () => onStatus(status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusKey extends StatelessWidget {
  const _StatusKey({
    super.key,
    required this.vehicleName,
    required this.status,
    required this.current,
    required this.color,
    required this.onColor,
    required this.onPressed,
  });

  final String vehicleName;
  final FmsStatus status;
  final bool current;
  final Color color;
  final Color onColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = current
        ? color
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = current ? onColor : theme.colorScheme.onSurface;
    return Tooltip(
      message: '${status.code} – ${status.label}',
      child: Semantics(
        selected: current,
        label: '$vehicleName Status ${status.code} ${status.label}',
        child: SizedBox(
          width: 44,
          height: 44,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: background,
              foregroundColor: foreground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: current
                    ? BorderSide(color: theme.colorScheme.onSurface, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Text(
              '${status.code}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
