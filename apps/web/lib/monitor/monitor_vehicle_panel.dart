import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';

/// How many Fahrzeug-Zeilen fit on one "Seite" before the panel starts
/// paging (`docs/design/screens/monitor-standby.md` §4 "viele Fahrzeuge").
const monitorVehiclePanelPageSize = 7;

/// How often the panel advances to the next page when there are more
/// vehicles than fit on one page (§4: "Wechsel alle 10 s").
const monitorVehiclePanelPageDuration = Duration(seconds: 10);

/// Monitor-eigenes Fahrzeugstatus+Besatzung-Panel
/// (`docs/design/screens/monitor-standby.md` §3 "Fahrzeugstatus+Besatzung
/// vereinigt", §7): replaces `VehicleStatusBar` on the monitor -- a
/// vertical, non-scrolling list (one row per Fahrzeug, Fahrzeugkurzname +
/// Besatzung + FMS-Pille), paging instead of scrolling once there are
/// more than [monitorVehiclePanelPageSize] vehicles (§4 AC1/AC2).
///
/// Pure presentational widget, no Riverpod/provider dependency (ADR 0027,
/// like `FmsBadge`) -- the caller resolves `vehiclesProvider`/
/// `shiftsProvider`/`bfDayProvider` and passes the result in.
class MonitorVehiclePanel extends StatefulWidget {
  const MonitorVehiclePanel({
    super.key,
    required this.vehicles,
    required this.crewByVehicleId,
    this.shiftLabel,
    this.pageDuration = monitorVehiclePanelPageDuration,
  });

  /// Fahrzeuge to show, already sorted the way the caller wants them
  /// paged (page `n` is `vehicles[n*7 .. n*7+7)`).
  final List<Vehicle> vehicles;

  /// Besatzung per Fahrzeug-id; a missing or empty entry renders "—"
  /// (§4 "Kein BF-Tag läuft"/"keine aktive Schicht").
  final Map<String, List<CrewAssignment>> crewByVehicleId;

  /// Appended to the heading as " · $shiftLabel" when a shift is active
  /// (§3 "Panel-Überschrift"), e.g. "Schicht 2 · 08:00–12:00". `null`
  /// when no BF-Tag runs or no shift is currently active.
  final String? shiftLabel;

  /// Overridable for widget tests (default 10 s per §4).
  final Duration pageDuration;

  @override
  State<MonitorVehiclePanel> createState() => _MonitorVehiclePanelState();
}

class _MonitorVehiclePanelState extends State<MonitorVehiclePanel> {
  Timer? _timer;
  int _page = 0;

  int get _pageCount =>
      (widget.vehicles.length / monitorVehiclePanelPageSize).ceil();

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void didUpdateWidget(covariant MonitorVehiclePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageCount = _pageCount;
    if (pageCount == 0) {
      _page = 0;
    } else if (_page >= pageCount) {
      _page = _page % pageCount;
    }
    if (pageCount <= 1) {
      _timer?.cancel();
      _timer = null;
    } else if (_timer == null) {
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = null;
    if (_pageCount <= 1) {
      return;
    }
    _timer = Timer(widget.pageDuration, _advance);
  }

  void _advance() {
    if (!mounted) {
      return;
    }
    final pageCount = _pageCount;
    if (pageCount <= 1) {
      return;
    }
    setState(() {
      _page = (_page + 1) % pageCount;
    });
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    final heading = widget.shiftLabel == null
        ? 'Fahrzeugstatus & Besatzung'
        : 'Fahrzeugstatus & Besatzung · ${widget.shiftLabel}';

    final pageCount = _pageCount;
    final page = pageCount == 0 ? 0 : (_page % pageCount);
    final start = page * monitorVehiclePanelPageSize;
    final end = (start + monitorVehiclePanelPageSize).clamp(
      0,
      widget.vehicles.length,
    );
    final pageVehicles = start >= widget.vehicles.length
        ? const <Vehicle>[]
        : widget.vehicles.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          heading,
          key: const Key('crew-panel-heading'),
          style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
              .copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: spacing.lg),
        Column(
          key: const Key('crew-panel-vehicles'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final vehicle in pageVehicles) ...[
              _VehicleRow(
                vehicle: vehicle,
                crew: widget.crewByVehicleId[vehicle.id] ?? const [],
              ),
              SizedBox(height: spacing.lg),
            ],
          ],
        ),
        if (pageCount > 1)
          Padding(
            padding: EdgeInsets.only(top: spacing.sm),
            child: Row(
              key: const Key('vehicle-status-page-indicator'),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < pageCount; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.xs),
                    child: Icon(
                      Icons.circle,
                      key: Key('vehicle-status-page-$i'),
                      size: 10,
                      color: i == page
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle, required this.crew});

  final Vehicle vehicle;
  final List<CrewAssignment> crew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    final sortedCrew = List<CrewAssignment>.of(crew)
      ..sort((a, b) => compareCrewFunctions(a.function, b.function));
    // §4 "Lange Besatzungsliste": Namen durch `·` getrennt, eine Zeile,
    // Ellipsis danach -- niemals eine zweite Zeile.
    final crewText = sortedCrew.isEmpty
        ? '—'
        : sortedCrew.map((c) => '${c.function} ${c.displayName}').join(' · ');

    return Container(
      key: Key('crew-vehicle-${vehicle.id}'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.md,
      ),
      decoration: BoxDecoration(
        // `surfaceContainer` maps to the `surfaceVariant` token
        // (theme.dart), matching the concept's "`surfaceVariant`-Karte".
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radii.medium),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(
              vehicle.shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (monitorStyles?.headline ?? const TextStyle(fontSize: 40))
                  .copyWith(color: colorScheme.onSurface),
            ),
          ),
          SizedBox(width: spacing.lg),
          Expanded(
            child: Text(
              crewText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          SizedBox(width: spacing.lg),
          FmsBadge(status: vehicle.status, large: true),
        ],
      ),
    );
  }
}
