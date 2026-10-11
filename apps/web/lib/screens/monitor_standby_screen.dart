import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../monitor/announcement_banner.dart';
import '../monitor/monitor_clock.dart';
import '../monitor/monitor_session.dart';
import '../widgets/slide_rotator.dart';
import '../widgets/vehicle_status_bar.dart';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

bool _dateFormattingInitialized = false;

/// Standby screen (ADR 0012, "Monitor im Browser"; ADR 0014, "Monitor";
/// ADR 0024, "Durchsage"): large clock, German date, monitor name,
/// connection banner, the live Fahrzeugstatus-Leiste, and (when there are
/// active Folien) a rotating slide area -- scaled for viewing from across
/// a room on a TV.
///
/// [liveBanner] is owned by [MonitorScreen] (it must survive this widget
/// being replaced by the Einsatzansicht and back): when set, it is shown
/// full-width instead of the "Letzte Durchsage" panel.
class MonitorStandbyScreen extends ConsumerStatefulWidget {
  const MonitorStandbyScreen({super.key, this.liveBanner});

  final Announcement? liveBanner;

  @override
  ConsumerState<MonitorStandbyScreen> createState() =>
      _MonitorStandbyScreenState();
}

class _MonitorStandbyScreenState extends ConsumerState<MonitorStandbyScreen> {
  bool _ready = _dateFormattingInitialized;

  @override
  void initState() {
    super.initState();
    if (!_dateFormattingInitialized) {
      initializeDateFormatting('de').then((_) {
        _dateFormattingInitialized = true;
        if (mounted) {
          setState(() => _ready = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(monitorSessionControllerProvider);
    final name = session is MonitorPaired ? session.name : '';
    final connection = ref.watch(realtimeConnectionProvider).valueOrNull;
    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();
    final slides = ref.watch(slidesProvider).valueOrNull ?? const <Slide>[];

    final time =
        '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}';
    final seconds = _twoDigits(now.second);
    final date = _ready
        ? DateFormat('EEEE, d. MMMM y', 'de').format(now)
        : '';

    final clockAndStatus = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                time,
                key: const Key('monitor-clock-time'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 160,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                ':$seconds',
                key: const Key('monitor-clock-seconds'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          date,
          key: const Key('monitor-date'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 32),
        const VehicleStatusBar(),
        const _CrewPanel(),
        const _ProgramStandbyPanel(),
        if (widget.liveBanner == null) const _LastAnnouncementPanel(),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _ConnectionBanner(status: connection),
            if (widget.liveBanner != null)
              AnnouncementBanner(announcement: widget.liveBanner!),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: 24,
                    child: Text(
                      name,
                      key: const Key('monitor-name'),
                      style: const TextStyle(color: Colors.white54, fontSize: 20),
                    ),
                  ),
                  if (slides.isEmpty)
                    Center(child: clockAndStatus)
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 2, child: Center(child: clockAndStatus)),
                        Expanded(
                          flex: 3,
                          child: SlideRotator(slides: slides),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Besatzungsanzeige (ADR 0013): below the vehicle status bar, shows the
/// crew of the aktuelle Schicht per active Fahrzeug -- hidden when no
/// BF-Tag is running or no shift is currently active.
class _CrewPanel extends ConsumerWidget {
  const _CrewPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bfDay = ref.watch(bfDayProvider).valueOrNull;
    final shifts = ref.watch(shiftsProvider).valueOrNull ?? const <Shift>[];
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();

    if (bfDay == null || bfDay.state != BfDayState.running) {
      return const SizedBox.shrink();
    }
    final shift = currentShift(shifts, now);
    if (shift == null) {
      return const SizedBox.shrink();
    }

    final start = shift.startsAt.toLocal();
    final end = shift.endsAt.toLocal();
    final heading = '${shift.name} · ${_twoDigits(start.hour)}:'
        '${_twoDigits(start.minute)}–${_twoDigits(end.hour)}:'
        '${_twoDigits(end.minute)}';

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Text(
            heading,
            key: const Key('crew-panel-heading'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            key: const Key('crew-panel-vehicles'),
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final vehicle in vehicles)
                _CrewVehicleCard(
                  vehicle: vehicle,
                  crew: shift.crew
                      .where((c) => c.vehicleId == vehicle.id)
                      .toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrewVehicleCard extends StatelessWidget {
  const _CrewVehicleCard({required this.vehicle, required this.crew});

  final Vehicle vehicle;
  final List<CrewAssignment> crew;

  @override
  Widget build(BuildContext context) {
    final sortedCrew = List<CrewAssignment>.of(crew)
      ..sort((a, b) => compareCrewFunctions(a.function, b.function));
    return Container(
      key: Key('crew-vehicle-${vehicle.id}'),
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            vehicle.shortName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (sortedCrew.isEmpty)
            const Text(
              '—',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            )
          else
            for (final assignment in sortedCrew)
              Text(
                '${assignment.function} ${assignment.displayName}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
        ],
      ),
    );
  }
}

/// "Jetzt" / "Danach" (ADR 0025, "Clients"): the aktuelle und nächste
/// Programmpunkte of the running BF-Tag from [programItemsProvider],
/// recomputed from [monitorClockProvider] -- the block is absent when
/// there are no Programmpunkte at all, and a missing current/next line is
/// simply omitted (not replaced by a placeholder).
class _ProgramStandbyPanel extends ConsumerWidget {
  const _ProgramStandbyPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(programItemsProvider).valueOrNull ?? const <ProgramItem>[];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();
    final result = currentAndNext(items, now);
    if (result.current == null && result.next == null) {
      return const SizedBox.shrink();
    }

    String lineFor(ProgramItem item) {
      final start = item.startsAt.toLocal();
      final end = item.endsAt.toLocal();
      return '${_twoDigits(start.hour)}:${_twoDigits(start.minute)}–'
          '${_twoDigits(end.hour)}:${_twoDigits(end.minute)}  '
          '${item.title}';
    }

    final current = result.current;
    final next = result.next;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        key: const Key('program-standby-panel'),
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current != null) ...[
              const Text(
                'Jetzt',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              Text(
                lineFor(current),
                key: const Key('monitor-program-current'),
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ],
            if (current != null && next != null) const SizedBox(height: 12),
            if (next != null) ...[
              const Text(
                'Danach',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              Text(
                lineFor(next),
                key: const Key('monitor-program-next'),
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Letzte Durchsage" (ADR 0024, "Clients"): shown once the live banner
/// has expired (or none has been received yet this session), the newest
/// entry of [announcementsProvider] (time + text) -- nothing while there
/// are none.
class _LastAnnouncementPanel extends ConsumerWidget {
  const _LastAnnouncementPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements =
        ref.watch(announcementsProvider).valueOrNull ?? const <Announcement>[];
    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }
    final newest = announcements.first;
    final time = newest.createdAt.toLocal();
    final timeLabel = '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        key: const Key('last-announcement-panel'),
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Letzte Durchsage · $timeLabel',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              newest.text,
              key: const Key('last-announcement-text'),
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status});

  final ConnectionStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    // Neutral hint during the very first connect attempt; red banner for
    // every later non-live status (reconnecting/revoked).
    if (status == null || status == ConnectionStatus.connecting) {
      return _Banner(
        key: const Key('connection-banner-connecting'),
        color: Colors.grey.shade800,
        text: 'Verbinde …',
      );
    }
    if (status == ConnectionStatus.live) {
      return const SizedBox.shrink();
    }
    return _Banner(
      key: const Key('connection-banner-reconnecting'),
      color: Colors.red,
      text: 'Keine Verbindung – verbinde neu …',
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
