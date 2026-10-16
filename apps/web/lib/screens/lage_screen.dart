import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/missed_alarms_section.dart';
import '../widgets/running_incidents_section.dart';
import '../widgets/scheduled_alarms_section.dart';
import '../widgets/vehicle_status_bar.dart';

/// Lage-Screen for `/admin`: Startseite der Leitstelle.
class LageScreen extends ConsumerWidget {
  const LageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lage')),
      body: const Column(
        children: [
          VehicleStatusBar(),
          MissedAlarmsSection(),
          ScheduledAlarmsSection(),
          Expanded(child: RunningIncidentsSection()),
        ],
      ),
    );
  }
}
