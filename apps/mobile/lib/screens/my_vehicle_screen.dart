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
/// [pairedRealtimeClientProvider].
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
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: assignments.isEmpty
          ? const Center(
              child: Text('Du bist aktuell keinem Fahrzeug zugeteilt.'),
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
    final vehicle = assignment.vehicle;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vehicle.callSign, style: Theme.of(context).textTheme.titleLarge),
          Text('${vehicle.shortName} – ${vehicle.type}'),
          const SizedBox(height: 8),
          Text('Deine Funktion: ${assignment.function}'),
          Text(
            'Status: ${vehicle.status.code} – ${vehicle.status.label}',
          ),
          const SizedBox(height: 16),
          FmsPanel(vehicle: vehicle),
          const SizedBox(height: 16),
          Text('Besatzung', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
