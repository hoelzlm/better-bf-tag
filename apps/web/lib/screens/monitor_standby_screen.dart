import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../monitor/announcement_banner.dart';
import '../monitor/monitor_clock.dart';
import '../monitor/monitor_connection_banner.dart';
import '../monitor/monitor_session.dart';
import '../monitor/monitor_vehicle_panel.dart';
import '../widgets/slide_rotator.dart';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

bool _dateFormattingInitialized = false;

/// Minimum Folienfläche, concept §3/§6 AC10.
const _minSlideSize = Size(900, 440);

/// Fixed height of the "mit Folien" compact Tagesablauf-Block, concept §3.
const _compactProgramHeight = 260.0;

/// Standby screen (ADR 0012, "Monitor im Browser"; ADR 0014, "Monitor";
/// ADR 0024, "Durchsage"): fixed grid (concept
/// `docs/design/screens/monitor-standby.md` §3) -- Kopfzeile (clock, date,
/// name), the Fahrzeugstatus+Besatzung panel ([MonitorVehiclePanel]), the
/// Tagesablauf column (plain or split with a Folienfläche), and a
/// three-priority Fußzeile (live Durchsage > "Letzte Durchsage" > empty).
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    final session = ref.watch(monitorSessionControllerProvider);
    final name = session is MonitorPaired ? session.name : '';
    final connection = ref.watch(realtimeConnectionProvider).valueOrNull;
    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();
    final slides = ref.watch(slidesProvider).valueOrNull ?? const <Slide>[];
    final vehicles =
        ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final bfDay = ref.watch(bfDayProvider).valueOrNull;
    final shifts = ref.watch(shiftsProvider).valueOrNull ?? const <Shift>[];
    final programItems =
        ref.watch(programItemsProvider).valueOrNull ?? const <ProgramItem>[];
    final announcements =
        ref.watch(announcementsProvider).valueOrNull ?? const <Announcement>[];

    final time = '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}';
    final seconds = _twoDigits(now.second);
    final date = _ready ? DateFormat('EEEE, d. MMMM y', 'de').format(now) : '';

    // §3 "Panel-Überschrift": the Schicht-Zusatz only appears while a
    // BF-Tag läuft AND a shift is currently active -- the vehicle list
    // itself stays visible regardless (Fahrzeuge existieren unabhängig).
    Shift? shift;
    if (bfDay != null && bfDay.state == BfDayState.running) {
      shift = currentShift(shifts, now);
    }
    String? shiftLabel;
    final activeShift = shift;
    if (activeShift != null) {
      final start = activeShift.startsAt.toLocal();
      final end = activeShift.endsAt.toLocal();
      shiftLabel =
          '${activeShift.name} · '
          '${_twoDigits(start.hour)}:${_twoDigits(start.minute)}–'
          '${_twoDigits(end.hour)}:${_twoDigits(end.minute)}';
    }
    final crewByVehicleId = <String, List<CrewAssignment>>{};
    if (activeShift != null) {
      for (final assignment in activeShift.crew) {
        crewByVehicleId
            .putIfAbsent(assignment.vehicleId, () => <CrewAssignment>[])
            .add(assignment);
      }
    }

    final hasSlides = slides.isNotEmpty;
    final programPanel = _ProgramStandbyPanel(
      items: programItems,
      now: now,
      compact: hasSlides,
    );

    Widget rightColumn;
    if (hasSlides) {
      rightColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: _compactProgramHeight, child: programPanel),
          SizedBox(height: spacing.lg),
          Expanded(
            child: ConstrainedBox(
              key: const Key('monitor-slide-area'),
              constraints: BoxConstraints(
                minWidth: _minSlideSize.width,
                minHeight: _minSlideSize.height,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    theme.extension<BftagRadii>()?.medium ?? 12,
                  ),
                ),
                child: SlideRotator(slides: slides),
              ),
            ),
          ),
        ],
      );
    } else {
      rightColumn = SingleChildScrollView(child: programPanel);
    }

    Widget footer;
    final liveBanner = widget.liveBanner;
    if (liveBanner != null) {
      footer = AnnouncementBanner(announcement: liveBanner);
    } else if (announcements.isNotEmpty) {
      footer = _LastAnnouncementPanel(announcement: announcements.first);
    } else {
      footer = _EmptyFooter();
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            MonitorConnectionBanner(status: connection),
            Padding(
              padding: EdgeInsets.all(spacing.xl),
              child: _MonitorHeader(
                time: time,
                seconds: seconds,
                date: date,
                name: name,
                live: connection == ConnectionStatus.live,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: MonitorVehiclePanel(
                          vehicles: vehicles,
                          crewByVehicleId: crewByVehicleId,
                          shiftLabel: shiftLabel,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.xxl),
                    Expanded(child: rightColumn),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Kopfzeile (concept §3): Uhrzeit links, Datum darunter, rechts der
/// Verbindungspunkt + Monitorname -- always visible (the clock is never
/// empty), independent of which panels below have content.
class _MonitorHeader extends StatelessWidget {
  const _MonitorHeader({
    required this.time,
    required this.seconds,
    required this.date,
    required this.name,
    required this.live,
  });

  final String time;
  final String seconds;
  final String date;
  final String name;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final statusColors = theme.extension<BftagStatusColors>();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    key: const Key('monitor-clock-time'),
                    style:
                        (monitorStyles?.display ??
                                const TextStyle(fontSize: 64))
                            .copyWith(color: colorScheme.onSurface),
                  ),
                  Text(
                    ':$seconds',
                    key: const Key('monitor-clock-seconds'),
                    style:
                        (monitorStyles?.headline ??
                                const TextStyle(fontSize: 40))
                            .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              SizedBox(height: spacing.sm),
              Text(
                date,
                key: const Key('monitor-date'),
                style: (monitorStyles?.label ?? const TextStyle(fontSize: 22))
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              live ? Icons.circle : Icons.sync_problem,
              size: 14,
              color: live
                  ? (statusColors?.fms2 ?? colorScheme.primary)
                  : colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: spacing.sm),
            Text(
              name,
              key: const Key('monitor-name'),
              style: (monitorStyles?.label ?? const TextStyle(fontSize: 22))
                  .copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Jetzt" / "Danach" + bis zu 4 weitere künftige Programmpunkte (ADR
/// 0025, "Clients"; concept §3/§4): niemals vergangene Punkte (§6 AC9).
/// [compact] (Folien vorhanden) shows only "Jetzt"/"Danach", no further
/// Punkte (§3 "Mit Folien"). The panel itself is always present (§4
/// "Leer/Erststart": festes Grid, nie ein leerer Bildschirm) -- an empty
/// state replaces the content when there is nothing to show.
class _ProgramStandbyPanel extends StatelessWidget {
  const _ProgramStandbyPanel({
    required this.items,
    required this.now,
    required this.compact,
  });

  final List<ProgramItem> items;
  final DateTime now;
  final bool compact;

  String _lineFor(ProgramItem item) {
    final start = item.startsAt.toLocal();
    final end = item.endsAt.toLocal();
    return '${_twoDigits(start.hour)}:${_twoDigits(start.minute)}–'
        '${_twoDigits(end.hour)}:${_twoDigits(end.minute)}  '
        '${item.title}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    final sorted = List<ProgramItem>.of(items)
      ..sort((a, b) {
        final byStart = a.startsAt.compareTo(b.startsAt);
        if (byStart != 0) return byStart;
        final byEnd = a.endsAt.compareTo(b.endsAt);
        if (byEnd != 0) return byEnd;
        return a.id.compareTo(b.id);
      });

    final result = currentAndNext(sorted, now);
    final current = result.current;
    final next = result.next;

    final utcNow = now.toUtc();
    // §6 AC9: never a Programmpunkt whose `endsAt` is already past and
    // that isn't the current one -- `startsAt.isAfter(utcNow)` already
    // guarantees `endsAt` is in the future too (`startsAt < endsAt`).
    final upcoming = compact
        ? const <ProgramItem>[]
        : sorted
              .where(
                (item) => item.startsAt.isAfter(utcNow) && item.id != next?.id,
              )
              .take(4)
              .toList();

    Widget content;
    if (current == null && next == null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_note, size: 48, color: colorScheme.onSurfaceVariant),
          SizedBox(height: spacing.sm),
          Text(
            'Kein Tagesablauf für heute.',
            style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null) ...[
            Text(
              'Jetzt',
              style: (monitorStyles?.label ?? const TextStyle(fontSize: 22))
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: spacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(radii.small),
              ),
              child: Text(
                _lineFor(current),
                key: const Key('monitor-program-current'),
                style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
                    .copyWith(color: colorScheme.onSurface),
              ),
            ),
          ],
          if (current != null && next != null) SizedBox(height: spacing.md),
          if (next != null) ...[
            Text(
              'Danach',
              style: (monitorStyles?.label ?? const TextStyle(fontSize: 22))
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: spacing.xs),
            Text(
              _lineFor(next),
              key: const Key('monitor-program-next'),
              style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
          for (final item in upcoming) ...[
            SizedBox(height: spacing.sm),
            Text(
              _lineFor(item),
              style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      );
    }

    return Container(
      key: const Key('program-standby-panel'),
      width: double.infinity,
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radii.medium),
      ),
      child: content,
    );
  }
}

/// "Letzte Durchsage" (ADR 0024, "Clients"): shown once the live banner
/// has expired (or none has been received yet this session), the newest
/// entry of [announcementsProvider] (time + text) -- Fußzeile-Priorität 2.
class _LastAnnouncementPanel extends StatelessWidget {
  const _LastAnnouncementPanel({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    final time = announcement.createdAt.toLocal();
    final timeLabel = '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

    return Container(
      key: const Key('last-announcement-panel'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xxl,
        vertical: spacing.md,
      ),
      color: colorScheme.surfaceContainer,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Letzte Durchsage · $timeLabel',
            style: (monitorStyles?.label ?? const TextStyle(fontSize: 22))
                .copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(width: spacing.lg),
          Expanded(
            child: Text(
              announcement.text,
              key: const Key('last-announcement-text'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
                  .copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fußzeile-Priorität 3 (concept §3): leer, dezent, ohne Text -- shown
/// when neither a live nor a "letzte" Durchsage exists.
class _EmptyFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 32,
      color: colorScheme.surfaceContainer,
    );
  }
}
