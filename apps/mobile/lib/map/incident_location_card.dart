import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'navigation.dart';

/// Shows the small [IncidentMap] (height ~180) plus a "Navigation
/// starten" button for an Einsatz with coordinates (ADR 0026, "App
/// (Alarm-Screen, Einsatzdetail)"). Callers only build this when
/// [incident] is non-null; the Wache pin ([station]) is optional.
class IncidentLocationCard extends ConsumerWidget {
  const IncidentLocationCard({
    super.key,
    required this.incident,
    this.station,
    this.tileProvider,
  });

  /// Einsatzort -- required, since the card has nothing to show without it.
  final LatLng incident;

  /// Wache, or `null` when none is configured.
  final LatLng? station;

  /// Injectable so widget tests run without network access (ADR 0026).
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: IncidentMap(
            incident: incident,
            station: station,
            interactive: false,
            tileProvider: tileProvider,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('start-navigation'),
          onPressed: () => unawaited(_startNavigation(context, ref)),
          child: const Text('Navigation starten'),
        ),
      ],
    );
  }

  Future<void> _startNavigation(BuildContext context, WidgetRef ref) async {
    final launcher = ref.read(uriLauncherProvider);
    final platform = Theme.of(context).platform;
    final ok = await startNavigation(
      incident.latitude,
      incident.longitude,
      platform: platform,
      launcher: launcher,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation konnte nicht gestartet werden'),
        ),
      );
    }
  }
}
