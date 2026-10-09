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
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final connection = ref.watch(realtimeConnectionProvider).valueOrNull ??
        ConnectionStatus.connecting;
    final session = ref.watch(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canDispatch =
        permission == Permission.dispatch || permission == Permission.admin;
    final vehicles = vehiclesAsync.valueOrNull ?? const <Vehicle>[];

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
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                connection == ConnectionStatus.live ? 'live' : 'verbinde neu…',
                key: const Key('connection-indicator'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SizedBox(
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
        ),
      ],
    );
  }
}

Color _statusColor(FmsStatus status) {
  switch (status) {
    case FmsStatus.s1:
    case FmsStatus.s2:
      return Colors.green;
    case FmsStatus.s3:
      return Colors.orange;
    case FmsStatus.s4:
      return Colors.red;
    case FmsStatus.s5:
      return Colors.amber;
    case FmsStatus.s6:
      return Colors.grey;
    case FmsStatus.s7:
    case FmsStatus.s8:
      return Colors.blue;
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
    final color = _statusColor(vehicle.status);
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              vehicle.callSign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Text(
                '${vehicle.status.code}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      width: 110,
      child: interactive
          ? InkWell(
              onTap: () => _openStatusPicker(context, ref),
              child: tile,
            )
          : tile,
    );
  }
}
