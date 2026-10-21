import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../map_tile_provider.dart';
import '../station_provider.dart';
import '../widgets/alarm_dialog.dart';
import '../widgets/running_incidents_section.dart'
    show formatElapsedSince, scheduledAlarmsWarningFragment;
import 'shifts_screen.dart' show pickDefaultBfDay;

String _stateChipLabel(IncidentState state) => state.label;

/// Earliest `triggeredAt` of [incident]'s alarms, formatted via
/// [formatElapsedSince] (concept §3.1/§3.4c, AC21) -- `null` when
/// [incident] is not `running` or has no triggered alarm yet (a purely
/// planned/missed Alarmierung does not count).
String? _elapsedLabelFor(Incident incident, List<Alarm> alarms, DateTime now) {
  if (incident.state != IncidentState.running) return null;
  DateTime? first;
  for (final alarm in alarms) {
    if (alarm.incidentId != incident.id) continue;
    final triggeredAt = alarm.triggeredAt;
    if (triggeredAt == null) continue;
    if (first == null || triggeredAt.isBefore(first)) first = triggeredAt;
  }
  if (first == null) return null;
  return formatElapsedSince(first, now);
}

/// Einsätze screen (`/admin/einsaetze`, Berechtigung Einsatzvorbereitung,
/// Leitstelle oder Administrator, ADR 0016): BF-Tag-Auswahl, Filter nach
/// Zustand (Entwurf/laufend/abgeschlossen -- verworfen ausgeblendet),
/// Liste, Editor mit Meldebild und geheimem Drehbuch.
///
/// Implements the kritischer Pfad (concept `docs/design/screens/
/// web-einsaetze.md` §3.4): after a successful `create()` the filter
/// switches to "Entwurf", the new card scrolls into view and is briefly
/// highlighted, and keyboard focus moves to its "Alarmieren" button; after
/// a successful Sofort-Erstalarm the filter switches to "laufend".
class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  List<BfDay>? _days;
  String? _selectedDayId;
  List<Incident>? _incidents;
  IncidentState _filter = IncidentState.draft;

  bool get _isRadio => switch (ref.read(sessionControllerProvider)) {
    SessionSignedIn(person: final person) =>
      person.permission == Permission.radio,
    _ => false,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Funktisch hat keinen Entwurf-Filter: Start auf "laufend".
    final session = ref.read(sessionControllerProvider);
    if (session is SessionSignedIn &&
        session.person.permission == Permission.radio &&
        _filter == IncidentState.draft) {
      _filter = IncidentState.running;
    }
  }

  String? _loadError;

  /// Id of the card currently showing the brief post-create highlight
  /// (§3.4a), or `null` when none is highlighted.
  String? _highlightedIncidentId;
  Timer? _highlightTimer;

  /// Keyboard focus for each card's Alarmieren/Nachalarmieren button,
  /// created on demand and reused across rebuilds so §3.4a/§5 can move
  /// focus to a specific card after it is (re)created.
  final Map<String, FocusNode> _alarmFocusNodes = {};

  /// Anchors used to resolve a card's `BuildContext` for
  /// `Scrollable.ensureVisible` (§3.4a) -- keyed by incident id, created
  /// on demand.
  final Map<String, GlobalKey> _cardAnchorKeys = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadDays());
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    for (final node in _alarmFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _focusNodeFor(String incidentId) =>
      _alarmFocusNodes[incidentId] ??= FocusNode();

  GlobalKey _anchorKeyFor(String incidentId) =>
      _cardAnchorKeys[incidentId] ??= GlobalKey();

  BfDay? get _selectedDay {
    final days = _days;
    if (days == null) return null;
    for (final day in days) {
      if (day.id == _selectedDayId) return day;
    }
    return null;
  }

  List<Incident> get _filteredIncidents {
    final incidents = _incidents ?? const <Incident>[];
    return incidents.where((i) => i.state == _filter).toList();
  }

  Future<void> _loadDays() async {
    try {
      final days = await ref.read(bfDayAdminRepositoryProvider).list();
      if (!mounted) return;
      final defaultDay = pickDefaultBfDay(days);
      setState(() {
        _days = days;
        _loadError = null;
        _selectedDayId = defaultDay?.id;
        _incidents = null;
      });
      if (defaultDay != null) {
        await _loadDay(defaultDay.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'BF-Tage konnten nicht geladen werden.');
    }
  }

  Future<void> _loadDay(String dayId) async {
    try {
      final incidents = await ref.read(incidentRepositoryProvider).list(dayId);
      if (!mounted) return;
      setState(() => _incidents = incidents);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Einsätze konnten nicht geladen werden.');
    }
  }

  Future<void> _reload() async {
    final dayId = _selectedDayId;
    if (dayId == null) return;
    await _loadDay(dayId);
  }

  void _selectDay(String dayId) {
    if (dayId == _selectedDayId) return;
    setState(() {
      _selectedDayId = dayId;
      _incidents = null;
    });
    unawaited(_loadDay(dayId));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// §3.4a: after a successful `create()`, switches the filter to
  /// "Entwurf" and briefly highlights the new card, independent of
  /// whether the user can see/reach its Alarmieren button.
  void _scheduleHighlightClear() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _highlightedIncidentId = null);
    });
  }

  /// §3.4a/§5: scrolls the new card into view and, when the current
  /// Berechtigung can see an Alarmieren button, moves keyboard focus onto
  /// it -- the AC16 counterpart to §3.4b's focus on the first vehicle
  /// checkbox inside [AlarmDialog].
  void _focusNewIncidentCard(String incidentId) {
    final session = ref.read(sessionControllerProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canAlarm = permission?.canRunIncidents ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final anchorContext = _anchorKeyFor(incidentId).currentContext;
      if (anchorContext != null) {
        await Scrollable.ensureVisible(
          anchorContext,
          duration: const Duration(milliseconds: 200),
          alignment: 0.5,
        );
      }
      if (!mounted || !canAlarm) return;
      _focusNodeFor(incidentId).requestFocus();
    });
  }

  Future<void> _openCreateDialog() async {
    final day = _selectedDay;
    if (day == null) return;
    final result = await showDialog<_IncidentFormResult>(
      context: context,
      builder: (context) => const _IncidentFormDialog(),
    );
    if (result == null) return;
    try {
      final created = await ref
          .read(incidentRepositoryProvider)
          .create(
            day.id,
            keyword: result.keyword,
            address: result.address,
            report: result.report,
            script: result.script,
            latitude: result.latitude,
            longitude: result.longitude,
          );
      setState(() {
        _filter = IncidentState.draft;
        _highlightedIncidentId = created.id;
      });
      await _reload();
      _scheduleHighlightClear();
      _focusNewIncidentCard(created.id);
    } catch (error) {
      _showError(
        describeIncidentError(
          error,
          fallback: 'Einsatz konnte nicht angelegt werden.',
        ),
      );
    }
  }

  Future<void> _openEditDialog(Incident incident) async {
    final result = await showDialog<_IncidentFormResult>(
      context: context,
      builder: (context) => _IncidentFormDialog(incident: incident),
    );
    if (result == null) return;
    try {
      await ref
          .read(incidentRepositoryProvider)
          .update(
            incident.id,
            keyword: result.keyword,
            address: result.address,
            report: result.report,
            script: result.script,
            latitude: result.latitude,
            longitude: result.longitude,
            clearLocation: result.clearLocation,
          );
      await _reload();
    } catch (error) {
      _showError(
        describeIncidentError(
          error,
          fallback: 'Einsatz konnte nicht gespeichert werden.',
        ),
      );
    }
  }

  Future<void> _openAlarmDialog(Incident incident) async {
    final isNachalarmierung = incident.state == IncidentState.running;
    final alarms = ref.read(alarmsProvider).valueOrNull ?? const <Alarm>[];
    final scheduledAlarms =
        ref.read(scheduledAlarmsProvider).valueOrNull ??
        const <ScheduledAlarm>[];
    final alreadyAlarmed = isNachalarmierung
        ? {
            for (final alarm in alarms)
              if (alarm.incidentId == incident.id) ...alarm.vehicleIds,
          }
        : const <String>{};
    final title = isNachalarmierung
        ? 'Nachalarmierung für Einsatz #${incident.number}'
        : 'Einsatz #${incident.number} "${incident.keyword}" alarmieren';
    // §3.4c/AC19: only a successful Sofort-Erstalarm (not a
    // Nachalarmierung, not a Planung) switches the filter to "laufend" --
    // tracked via this flag instead of the dialog's `pop(true)` result,
    // which is also `true` for the idempotent "bereits alarmiert" case
    // and for a successful Planung.
    var triggeredNow = false;
    final triggered = await showDialog<bool>(
      context: context,
      builder: (context) => AlarmDialog(
        incidentId: incident.id,
        allowPlanning: !_isRadio,
        title: title,
        alreadyAlarmedVehicleIds: alreadyAlarmed,
        hasFirstAlarm: hasFirstAlarmFor(incident.id, alarms, scheduledAlarms),
        onTriggered: isNachalarmierung ? null : () => triggeredNow = true,
      ),
    );
    if (triggered == true) {
      if (triggeredNow) {
        setState(() => _filter = IncidentState.running);
      }
      await _reload();
    }
  }

  Future<void> _discard(Incident incident) async {
    final scheduledAlarms =
        (ref.read(scheduledAlarmsProvider).valueOrNull ??
                const <ScheduledAlarm>[])
            .where((sa) => sa.incident.id == incident.id)
            .toList();
    final warning = scheduledAlarmsWarningFragment(scheduledAlarms);
    final alarmColors = Theme.of(context).extension<BftagAlarmColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einsatz verwerfen'),
        content: Text(
          warning == null
              ? 'Einsatz #${incident.number} "${incident.keyword}" wirklich verwerfen?'
              : 'Einsatz #${incident.number} "${incident.keyword}" wirklich '
                    'verwerfen? $warning werden ebenfalls verworfen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('confirm-dialog-confirm'),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(alarmColors.alarm),
              foregroundColor: WidgetStatePropertyAll(alarmColors.onAlarm),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(incidentRepositoryProvider).discard(incident.id);
      await _reload();
    } catch (error) {
      _showError(
        describeIncidentError(
          error,
          fallback: 'Einsatz konnte nicht verworfen werden.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final session = ref.watch(sessionControllerProvider);
    // Keeps alarmsProvider/scheduledAlarmsProvider/vehiclesProvider
    // subscribed and fresh so the on-demand ref.read() calls in
    // _openAlarmDialog/_discard (ADR 0022) see up-to-date data even if this
    // screen is opened directly (not via the Lage-Screen, which already
    // watches alarms/scheduledAlarms) -- and, critically, so AlarmDialog's
    // own `ref.watch(vehiclesProvider)` sees the already-resolved AsyncData
    // instead of racing a late subscription against realtime_client.dart's
    // single-shot broadcast StreamController (which does not replay past
    // events to new listeners).
    final alarms = ref.watch(alarmsProvider).valueOrNull ?? const <Alarm>[];
    ref.watch(scheduledAlarmsProvider);
    ref.watch(vehiclesProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canAlarm = permission?.canRunIncidents ?? false;
    // Funktisch: nur laufende + abgeschlossene Einsätze, nichts anlegen
    // oder bearbeiten (Entwürfe liefert das Backend gar nicht erst).
    final isRadio = permission == Permission.radio;
    final days = _days;
    final day = _selectedDay;
    final dayEnded = day?.state == BfDayState.ended;
    final incidents = _filteredIncidents;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsätze'),
        actions: [
          if (days != null && days.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: spacing.lg),
              child: Row(
                children: [
                  Text('BF-Tag:', style: theme.textTheme.bodyMedium),
                  SizedBox(width: spacing.sm),
                  DropdownButton<String>(
                    key: const Key('bf-day-dropdown'),
                    value: _selectedDayId,
                    items: [
                      for (final d in days)
                        DropdownMenuItem(value: d.id, child: Text(d.name)),
                    ],
                    onChanged: (value) {
                      if (value != null) _selectDay(value);
                    },
                  ),
                ],
              ),
            ),
          if (!isRadio)
            Padding(
              padding: EdgeInsets.only(right: spacing.lg),
              child: FilledButton.icon(
                key: const Key('create-incident'),
                onPressed: (day == null || dayEnded) ? null : _openCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Einsatz anlegen'),
              ),
            ),
        ],
      ),
      body: days == null
          ? Center(
              child: _loadError != null
                  ? BftagStateView.error(
                      message: _loadError!,
                      onRetry: _loadDays,
                    )
                  : const CircularProgressIndicator(),
            )
          : days.isEmpty
          ? const BftagStateView.empty(
              title: 'Keine BF-Tage angelegt.',
              icon: Icons.event_busy_outlined,
            )
          : Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<IncidentState>(
                    key: const Key('incident-filter'),
                    segments: [
                      if (!isRadio)
                        const ButtonSegment(
                          value: IncidentState.draft,
                          label: Text('Entwurf'),
                        ),
                      const ButtonSegment(
                        value: IncidentState.running,
                        label: Text('laufend'),
                      ),
                      const ButtonSegment(
                        value: IncidentState.closed,
                        label: Text('abgeschlossen'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) {
                      setState(() => _filter = selection.first);
                    },
                  ),
                  SizedBox(height: spacing.lg),
                  if (_incidents == null)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (incidents.isEmpty)
                    Expanded(
                      child: BftagStateView.empty(
                        icon: Icons.local_fire_department,
                        title: 'Keine Einsätze im Zustand ${_filter.label}.',
                        action: _filter == IncidentState.draft && !isRadio
                            ? FilledButton.icon(
                                key: const Key('incidents-empty-create'),
                                onPressed: dayEnded ? null : _openCreateDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Einsatz anlegen'),
                              )
                            : null,
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        key: const Key('incidents-list'),
                        children: [
                          for (final incident in incidents)
                            Padding(
                              padding: EdgeInsets.only(bottom: spacing.md),
                              child: KeyedSubtree(
                                key: _anchorKeyFor(incident.id),
                                child: _IncidentCard(
                                  key: Key('incident-${incident.id}'),
                                  incident: incident,
                                  highlighted:
                                      incident.id == _highlightedIncidentId,
                                  elapsedLabel: _elapsedLabelFor(
                                    incident,
                                    alarms,
                                    now,
                                  ),
                                  canAlarm: canAlarm,
                                  alarmFocusNode: canAlarm
                                      ? _focusNodeFor(incident.id)
                                      : null,
                                  onTap: isRadio
                                      ? null
                                      : () => _openEditDialog(incident),
                                  onDiscard: () => _discard(incident),
                                  onAlarm: () => _openAlarmDialog(incident),
                                ),
                              ),
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

/// A single Einsatz card (concept §3.1): title row with the "#Nummer"
/// badge, Stichwort and the always-visible Zustands-Label
/// (`incident-state-${id}`), the Adresse beneath it, and a narrow,
/// vertically centered action column with "seit X min" (laufend only),
/// "Verwerfen" (Entwurf only) and "Alarmieren"/"Nachalarmieren".
class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    super.key,
    required this.incident,
    required this.highlighted,
    required this.elapsedLabel,
    required this.canAlarm,
    required this.alarmFocusNode,
    required this.onTap,
    required this.onDiscard,
    required this.onAlarm,
  });

  final Incident incident;
  final bool highlighted;
  final String? elapsedLabel;
  final bool canAlarm;
  final FocusNode? alarmFocusNode;
  final VoidCallback? onTap;
  final VoidCallback onDiscard;
  final VoidCallback onAlarm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final alarmColors = theme.extension<BftagAlarmColors>()!;
    final statusColors = theme.extension<BftagStatusColors>()!;
    final isDraft = incident.state == IncidentState.draft;
    final isRunning = incident.state == IncidentState.running;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radii.large),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radii.large),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(radii.large),
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(radii.full),
                              ),
                              child: Text(
                                '#${incident.number}',
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Expanded(
                              child: Text(
                                incident.keyword,
                                style: theme.textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            Chip(
                              key: Key('incident-state-${incident.id}'),
                              label: Text(_stateChipLabel(incident.state)),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.xs),
                        Text(
                          incident.address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                // Fits "Nachalarmieren" + icon on one line.
                width: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isRunning && elapsedLabel != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColors.fms2,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: spacing.xs),
                          Text(
                            'seit $elapsedLabel',
                            key: Key('incident-elapsed-${incident.id}'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.xs),
                    ],
                    if (isDraft)
                      Tooltip(
                        message: 'Verwerfen',
                        child: TextButton(
                          key: Key('discard-incident-${incident.id}'),
                          onPressed: onDiscard,
                          child: const Text('Verwerfen'),
                        ),
                      ),
                    if (canAlarm && (isDraft || isRunning))
                      Padding(
                        padding: EdgeInsets.only(top: isDraft ? spacing.xs : 0),
                        child: Tooltip(
                          message: isDraft ? 'Alarmieren' : 'Nachalarmieren',
                          child: FilledButton.icon(
                            key: Key(
                              isDraft
                                  ? 'alarm-incident-${incident.id}'
                                  : 'nachalarmieren-incident-${incident.id}',
                            ),
                            focusNode: alarmFocusNode,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                alarmColors.alarm,
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                alarmColors.onAlarm,
                              ),
                            ),
                            icon: const Icon(Icons.notification_important),
                            label: Text(
                              isDraft ? 'Alarmieren' : 'Nachalarmieren',
                              maxLines: 1,
                              softWrap: false,
                            ),
                            onPressed: onAlarm,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentFormResult {
  const _IncidentFormResult({
    required this.keyword,
    required this.address,
    required this.report,
    required this.script,
    this.latitude,
    this.longitude,
    this.clearLocation = false,
  });

  final String keyword;
  final String address;
  final String report;
  final String script;

  /// Einsatzort (ADR 0026), or both `null` for no pin.
  final double? latitude;
  final double? longitude;

  /// `true` when an existing pin was explicitly removed (`latitude`/
  /// `longitude` are then `null`, see [IncidentRepository.update]).
  final bool clearLocation;
}

/// Editor dialog with two clearly separated sections (ADR 0016): Meldebild
/// (Stichwort, Adresse, Lagebeschreibung) and -- in a visually distinct
/// "Vertraulich" container (concept §3.2: `surfaceContainer` + 1 px
/// `outline`-Rahmen + Schloss-Icon, NOT the `warning`/`alarm` tokens,
/// since confidentiality is not an error/alarm state) -- the geheime
/// Drehbuch. Read-only once the Einsatz is `closed`.
class _IncidentFormDialog extends ConsumerStatefulWidget {
  const _IncidentFormDialog({this.incident});

  final Incident? incident;

  @override
  ConsumerState<_IncidentFormDialog> createState() =>
      _IncidentFormDialogState();
}

class _IncidentFormDialogState extends ConsumerState<_IncidentFormDialog> {
  late final TextEditingController _keywordController;
  late final TextEditingController _addressController;
  late final TextEditingController _reportController;
  late final TextEditingController _scriptController;

  /// Current Einsatzort pin (ADR 0026), `null` when none is set.
  LatLng? _pin;

  /// Whether [widget.incident] already had a pin -- distinguishes \"no
  /// change\" from \"pin explicitly removed\" for [IncidentRepository.update]
  /// (see [_IncidentFormResult.clearLocation]).
  bool _hadLocation = false;

  /// Results of the last Adresssuche, or `null` before any search has run.
  List<GeocodeSuggestion>? _suggestions;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final incident = widget.incident;
    _keywordController = TextEditingController(text: incident?.keyword ?? '');
    _addressController = TextEditingController(text: incident?.address ?? '');
    _reportController = TextEditingController(text: incident?.report ?? '');
    _scriptController = TextEditingController(text: incident?.script ?? '');
    _pin = incident?.location;
    _hadLocation = _pin != null;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _addressController.dispose();
    _reportController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  /// Searches the Adresse field (one field for text and map, BF-Tag). The
  /// address text is never overwritten by the search.
  Future<void> _search() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = const []);
      return;
    }
    setState(() => _searching = true);
    final results = await ref.read(geocodeRepositoryProvider).search(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _searching = false;
    });
  }

  void _selectSuggestion(GeocodeSuggestion suggestion) {
    setState(() {
      _pin = LatLng(suggestion.latitude, suggestion.longitude);
      _pinRemovedByUser = false;
      _suggestions = null;
    });
  }

  /// Set once the user explicitly removes the pin, so saving does not
  /// immediately geocode it back.
  bool _pinRemovedByUser = false;

  void _removePin() {
    setState(() {
      _pin = null;
      _pinRemovedByUser = true;
    });
  }

  bool _saving = false;

  /// Saves the form. With an Adresse but no pin, the address is geocoded
  /// first and the best match becomes the pin, so the Monitor shows the
  /// Einsatzort without a separate search step. No match (or no network)
  /// saves without coordinates, as before.
  Future<void> _submit() async {
    if (_saving) return;
    var pin = _pin;
    final address = _addressController.text.trim();
    if (pin == null && address.isNotEmpty && !_pinRemovedByUser) {
      setState(() => _saving = true);
      try {
        final results = await ref
            .read(geocodeRepositoryProvider)
            .search(address);
        if (results.isNotEmpty) {
          pin = LatLng(results.first.latitude, results.first.longitude);
        }
      } catch (_) {
        // Geocoding is best effort; saving must never fail because of it.
      }
      if (!mounted) return;
      setState(() => _saving = false);
    }
    Navigator.of(context).pop(
      _IncidentFormResult(
        keyword: _keywordController.text.trim(),
        address: _addressController.text.trim(),
        report: _reportController.text.trim(),
        script: _scriptController.text.trim(),
        latitude: pin?.latitude,
        longitude: pin?.longitude,
        clearLocation: pin == null && _hadLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final incident = widget.incident;
    final isEdit = incident != null;
    final readOnly = incident?.state == IncidentState.closed;
    final station = ref.watch(stationProvider).valueOrNull;
    final tileProvider = ref.watch(mapTileProviderProvider);
    final suggestions = _suggestions;

    return AlertDialog(
      title: Text(isEdit ? 'Einsatz bearbeiten' : 'Einsatz anlegen'),
      content: SizedBox(
        // Fixed width: AlertDialog otherwise measures its content's
        // intrinsic width, which IncidentMap's LayoutBuilder-based
        // FlutterMap does not support.
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meldebild', style: theme.textTheme.titleMedium),
              SizedBox(height: spacing.sm),
              TextField(
                key: const Key('incident-form-keyword'),
                controller: _keywordController,
                readOnly: readOnly,
                decoration: const InputDecoration(labelText: 'Stichwort'),
              ),
              SizedBox(height: spacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('incident-form-address'),
                      controller: _addressController,
                      readOnly: readOnly,
                      textInputAction: TextInputAction.search,
                      onSubmitted: readOnly ? null : (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        helperText: 'Beim Speichern wird der Ort automatisch auf der Karte gesetzt.',
                      ),
                    ),
                  ),
                  if (!readOnly) ...[
                    SizedBox(width: spacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        key: const Key('incident-form-location-search-button'),
                        onPressed: _searching ? null : _search,
                        icon: const Icon(Icons.search),
                        label: const Text('Auf Karte suchen'),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: spacing.md),
              TextField(
                key: const Key('incident-form-report'),
                controller: _reportController,
                readOnly: readOnly,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Lagebeschreibung',
                ),
              ),
              SizedBox(height: spacing.lg),
              Text('Einsatzort (Karte)', style: theme.textTheme.titleMedium),
              SizedBox(height: spacing.sm),
              if (!readOnly) ...[
                if (suggestions != null) ...[
                  SizedBox(height: spacing.xs),
                  if (suggestions.isEmpty)
                    const Text('Keine Vorschläge')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final suggestion in suggestions)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(suggestion.label),
                            onTap: () => _selectSuggestion(suggestion),
                          ),
                      ],
                    ),
                ],
                SizedBox(height: spacing.sm),
              ],
              SizedBox(
                height: 300,
                child: IncidentMap(
                  incident: _pin,
                  station: station,
                  interactive: !readOnly,
                  onTap: readOnly
                      ? null
                      : (point) => setState(() => _pin = point),
                  tileProvider: tileProvider,
                ),
              ),
              if (!readOnly && _pin != null) ...[
                SizedBox(height: spacing.sm),
                TextButton(
                  key: const Key('incident-form-remove-pin'),
                  onPressed: _removePin,
                  child: const Text('Pin entfernen'),
                ),
              ],
              SizedBox(height: spacing.lg),
              Container(
                key: const Key('script-section'),
                padding: EdgeInsets.all(spacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(radii.medium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            'Drehbuch – GEHEIM, nie für die Mannschaft sichtbar',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.sm),
                    TextField(
                      key: const Key('incident-form-script'),
                      controller: _scriptController,
                      readOnly: readOnly,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Drehbuch'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        if (!readOnly)
          FilledButton(
            key: const Key('incident-form-submit'),
            onPressed: _saving ? null : _submit,
            child: const Text('Speichern'),
          ),
      ],
    );
  }
}
