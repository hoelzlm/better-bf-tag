import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/fms_panel.dart';
import '../widgets/main_nav_bar.dart';

/// Screen "Mein Fahrzeug" for `/`: shows the Fahrzeug(e) the paired Person
/// is currently Besatzung of (ADR 0015), with the FMS-Bedienteil to set
/// the Fahrzeugstatus. Starts the realtime connection (so
/// `session.revoked` is received) as a side effect of watching
/// [pairedRealtimeClientProvider]. Header hierarchy and empty state per
/// `docs/design/screens/app-mein-fahrzeug.md` §3/§4 (ADR 0027).
class MyVehicleScreen extends ConsumerStatefulWidget {
  const MyVehicleScreen({super.key});

  @override
  ConsumerState<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends ConsumerState<MyVehicleScreen> {
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    ref.watch(pairedRealtimeClientProvider);

    final assignments = ref.watch(myCrewAssignmentsProvider);

    MyCrewAssignment? selected;
    if (assignments.isNotEmpty) {
      selected = assignments.firstWhere(
        (a) => a.vehicle.id == _selectedVehicleId,
        orElse: () => assignments.first,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Fahrzeug'),
        actions: [
          IconButton(
            key: const Key('settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: assignments.isEmpty
          ? const BftagStateView.empty(
              title: 'Du bist aktuell keinem Fahrzeug zugeteilt.',
              icon: Icons.local_shipping_outlined,
            )
          : Column(
              children: [
                if (assignments.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SegmentedButton<String>(
                      key: const Key('vehicle-switcher'),
                      segments: [
                        for (final a in assignments)
                          ButtonSegment(
                            value: a.vehicle.id,
                            label: Text(a.vehicle.shortName),
                          ),
                      ],
                      selected: {selected!.vehicle.id},
                      onSelectionChanged: (set) {
                        setState(() => _selectedVehicleId = set.first);
                      },
                    ),
                  ),
                Expanded(
                  child: _VehicleContent(assignment: selected!),
                ),
              ],
            ),
      bottomNavigationBar: const MainNavBar(currentIndex: 0),
    );
  }
}

class _VehicleContent extends StatelessWidget {
  const _VehicleContent({required this.assignment});

  final MyCrewAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>()!;
    final vehicle = assignment.vehicle;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vehicle.callSign, style: theme.textTheme.headlineSmall),
          Text(
            '${vehicle.shortName} – ${vehicle.type}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.sm),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyLarge,
              children: [
                TextSpan(text: 'Funktion: ${assignment.function} · '),
                const TextSpan(
                  text: 'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '${vehicle.status.code} – ${vehicle.status.label}',
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.lg),
          FmsPanel(vehicle: vehicle),
          SizedBox(height: spacing.lg),
          Text('Besatzung', style: theme.textTheme.titleMedium),
          SizedBox(height: spacing.sm),
          for (final crewMember in assignment.crew)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${crewMember.function} ${crewMember.displayName}'),
            ),
        ],
      ),
    );
  }
}
