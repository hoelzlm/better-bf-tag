// Reusable Einsatzansicht building blocks (`docs/design/screens/
// monitor-einsatz.md` §3/§6 AC4/AC5): the vehicle chip and the
// Quittierungs-Fortschritt computation/chip. Shared between
// `MonitorIncidentScreen` (ux-07 C) and the loud Alarmzustand screen
// (`monitor-alarm.md`, ux-07 D) so both learn the same visual language
// once.
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';

/// "N alarmiert": number of alarmed persons. BF-Tag ohne Handys: nobody
/// acknowledges on a phone, so an "X/Y quittiert" count would sit at 0
/// forever. Name and Key kept so the monitor layout stays unchanged.
String ackProgressLabel(List<AlarmRecipient> recipients) {
  final count = recipients
      .map((recipient) => recipient.personId)
      .toSet()
      .length;
  return '$count alarmiert';
}

/// Quittierungs-Fortschritt chip (concept §3 Review-Runde 1 Punkt 8,
/// §6 AC4): `Key('monitor-incident-ack-progress')`, `primaryContainer`
/// background, `monitorLabel` text -- deliberately separate from
/// `monitor-incident-alarm-label` (which keeps showing the
/// Alarmierungsstufe), so live `alarm.acknowledged` updates never touch
/// the alarm-sequence chip's content.
class AckProgressChip extends StatelessWidget {
  const AckProgressChip({super.key, required this.recipients});

  final List<AlarmRecipient> recipients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final style = (monitorStyles?.label ?? const TextStyle(fontSize: 22))
        .copyWith(color: theme.colorScheme.onPrimaryContainer);
    return Container(
      key: const Key('monitor-incident-ack-progress'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(radii.full),
      ),
      child: Text(ackProgressLabel(recipients), style: style),
    );
  }
}

/// Fahrzeugkarte für die alarmierten Fahrzeuge (concept §3 "Fahrzeugkarten",
/// §6 AC5): `Key('incident-vehicle-<id>')`, Kurzname + Rufname
/// ([Vehicle.callSign]) + [FmsBadge] (number + text, never color-only).
class IncidentVehicleChip extends StatelessWidget {
  const IncidentVehicleChip({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final nameStyle = (monitorStyles?.headline ?? const TextStyle(fontSize: 40))
        .copyWith(color: theme.colorScheme.onSurface);
    final callSignStyle =
        (monitorStyles?.label ?? const TextStyle(fontSize: 22)).copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
    return Container(
      key: Key('incident-vehicle-${vehicle.id}'),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radii.medium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vehicle.shortName, style: nameStyle),
          Text(vehicle.callSign, style: callSignStyle),
          SizedBox(height: spacing.xs),
          FmsBadge(status: vehicle.status, large: true),
        ],
      ),
    );
  }
}
