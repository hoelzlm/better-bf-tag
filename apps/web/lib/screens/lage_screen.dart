import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/funktisch.dart';
import '../widgets/missed_alarms_section.dart';
import '../widgets/running_incidents_section.dart';
import '../widgets/scheduled_alarms_section.dart';
import '../widgets/vehicle_status_bar.dart';

/// Lage-Screen for `/admin`: Startseite der Leitstelle.
///
/// Leitstelle/Admin: Funktisch (Status per Funk, ein Klick pro Meldung)
/// neben den laufenden Einsätzen. Ohne Leitstellen-Berechtigung: die reine
/// Statusleiste wie bisher.
class LageScreen extends ConsumerWidget {
  const LageScreen({super.key});

  /// Below this width the Funktisch sits above the incidents.
  static const double wideBreakpoint = 1200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canDispatch = permission?.canRunIncidents ?? false;

    const incidents = Column(
      children: [
        MissedAlarmsSection(),
        ScheduledAlarmsSection(),
        Expanded(child: RunningIncidentsSection()),
      ],
    );

    Widget body;
    if (!canDispatch) {
      body = const Column(
        children: [
          VehicleStatusBar(),
          Expanded(child: incidents),
        ],
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= wideBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 660, child: Funktisch()),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const Expanded(child: incidents),
              ],
            );
          }
          return Column(
            children: [
              SizedBox(
                height: (constraints.maxHeight * 0.45).clamp(220.0, 420.0),
                child: const Funktisch(),
              ),
              const Divider(height: 1),
              const Expanded(child: incidents),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lage')),
      body: body,
    );
  }
}
