import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fahrzeugstatus-Leiste: one tile per active Fahrzeug, live from
/// [vehiclesProvider] (no reload). Shows a small connection indicator from
/// [realtimeConnectionProvider].
///
/// For permission `dispatch`/`admin`, tapping a tile opens a status picker
/// that calls `PUT /vehicles/{id}/status`; other permissions get read-only
/// tiles. The displayed status is never mutated optimistically -- it only
/// changes once the realtime `vehicle.status_changed` event arrives.
class VehicleStatusBar extends ConsumerWidget {
  const VehicleStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final connection =
        ref.watch(realtimeConnectionProvider).valueOrNull ??
        ConnectionStatus.connecting;
    final session = ref.watch(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canDispatch = permission?.canRunIncidents ?? false;
    final vehicles = vehiclesAsync.valueOrNull ?? const <Vehicle>[];

    Widget body;
    if (vehiclesAsync.hasError && vehicles.isEmpty) {
      body = SizedBox(
        height: 140,
        child: BftagStateView.error(
          message: 'Fahrzeuge konnten nicht geladen werden.',
          onRetry: () => ref.invalidate(vehiclesProvider),
        ),
      );
    } else if (vehiclesAsync.isLoading && vehicles.isEmpty) {
      body = const SizedBox(height: 140, child: BftagStateView.loading());
    } else {
      body = SizedBox(
        height: 140,
        child: ListView(
          key: const Key('vehicle-status-bar'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final vehicle in vehicles)
              _VehicleTile(vehicle: vehicle, interactive: canDispatch),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
        body,
      ],
    );
  }
}

class _VehicleTile extends ConsumerWidget {
  const _VehicleTile({required this.vehicle, required this.interactive});

  final Vehicle vehicle;
  final bool interactive;

  Future<void> _openStatusPicker(BuildContext context, WidgetRef ref) async {
    final chosen = await showDialog<FmsStatus>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Status für ${vehicle.callSign}'),
        children: [
          for (final status in offeredStatuses(vehicle.type))
            SimpleDialogOption(
              key: Key('status-option-${status.code}'),
              onPressed: () => Navigator.of(dialogContext).pop(status),
              child: Text('${status.code} – ${status.label}'),
            ),
        ],
      ),
    );
    if (chosen == null) {
      return;
    }
    try {
      await ref
          .read(vehicleAdminRepositoryProvider)
          .setStatus(vehicle.id, chosen.code);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status konnte nicht gesetzt werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tile = Card(
      key: Key('vehicle-tile-${vehicle.id}'),
      margin: const EdgeInsets.all(2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vehicle.shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            Tooltip(
              message: vehicle.callSign,
              child: Text(
                vehicle.callSign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: FmsBadge(status: vehicle.status),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: 180,
      child: interactive
          ? InkWell(onTap: () => _openStatusPicker(context, ref), child: tile)
          : tile,
    );
  }
}
