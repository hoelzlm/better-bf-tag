import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../map_tile_provider.dart';
import '../station_provider.dart';
import '../widgets/alarm_dialog.dart';
import '../widgets/running_incidents_section.dart'
    show scheduledAlarmsWarningFragment;
import 'shifts_screen.dart' show pickDefaultBfDay;

String _stateChipLabel(IncidentState state) => state.label;

/// Einsätze screen (`/admin/einsaetze`, Berechtigung Einsatzvorbereitung,
/// Leitstelle oder Administrator, ADR 0016): BF-Tag-Auswahl, Filter nach
/// Zustand (Entwurf/laufend/abgeschlossen -- verworfen ausgeblendet),
/// Liste, Editor mit Meldebild und geheimem Drehbuch.
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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDays());
  }

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

  Future<void> _openCreateDialog() async {
    final day = _selectedDay;
    if (day == null) return;
    final result = await showDialog<_IncidentFormResult>(
      context: context,
      builder: (context) => const _IncidentFormDialog(),
    );
    if (result == null) return;
    try {
      await ref
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
      await _reload();
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
    final triggered = await showDialog<bool>(
      context: context,
      builder: (context) => AlarmDialog(
        incidentId: incident.id,
        title: title,
        alreadyAlarmedVehicleIds: alreadyAlarmed,
        hasFirstAlarm: hasFirstAlarmFor(incident.id, alarms, scheduledAlarms),
      ),
    );
    if (triggered == true) {
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
    final session = ref.watch(sessionControllerProvider);
    // Keeps alarmsProvider/scheduledAlarmsProvider subscribed and fresh so
    // the on-demand ref.read() calls in _openAlarmDialog/_discard (ADR
    // 0022) see up-to-date data even if this screen is opened directly
    // (not via the Lage-Screen, which already watches both).
    ref.watch(alarmsProvider);
    ref.watch(scheduledAlarmsProvider);
    final permission = switch (session) {
      SessionSignedIn(person: final person) => person.permission,
      _ => null,
    };
    final canAlarm =
        permission == Permission.dispatch || permission == Permission.admin;
    final days = _days;
    final day = _selectedDay;
    final dayEnded = day?.state == BfDayState.ended;
    final incidents = _filteredIncidents;

    return Scaffold(
      appBar: AppBar(title: const Text('Einsätze')),
      floatingActionButton: day == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('create-incident'),
              onPressed: dayEnded ? null : _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Einsatz anlegen'),
            ),
      body: days == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : days.isEmpty
          ? const Center(child: Text('Keine BF-Tage angelegt.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
                  if (day != null) ...[
                    SegmentedButton<IncidentState>(
                      key: const Key('incident-filter'),
                      segments: const [
                        ButtonSegment(
                          value: IncidentState.draft,
                          label: Text('Entwurf'),
                        ),
                        ButtonSegment(
                          value: IncidentState.running,
                          label: Text('laufend'),
                        ),
                        ButtonSegment(
                          value: IncidentState.closed,
                          label: Text('abgeschlossen'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (selection) {
                        setState(() => _filter = selection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_incidents == null)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (incidents.isEmpty)
                      const Expanded(
                        child: Center(child: Text('Keine Einsätze vorhanden.')),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          key: const Key('incidents-list'),
                          itemCount: incidents.length,
                          itemBuilder: (context, index) {
                            final incident = incidents[index];
                            return ListTile(
                              key: Key('incident-${incident.id}'),
                              title: Text(
                                '#${incident.number} ${incident.keyword} – ${incident.address}',
                              ),
                              onTap: () => _openEditDialog(incident),
                              trailing: Wrap(
                                spacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Chip(
                                    key: Key('incident-state-${incident.id}'),
                                    label: Text(
                                      _stateChipLabel(incident.state),
                                    ),
                                  ),
                                  if (incident.state == IncidentState.draft &&
                                      canAlarm)
                                    IconButton(
                                      key: Key('alarm-incident-${incident.id}'),
                                      icon: const Icon(Icons.campaign),
                                      tooltip: 'Alarmieren',
                                      onPressed: () =>
                                          _openAlarmDialog(incident),
                                    ),
                                  if (incident.state == IncidentState.running &&
                                      canAlarm)
                                    IconButton(
                                      key: Key(
                                        'nachalarmieren-incident-${incident.id}',
                                      ),
                                      icon: const Icon(Icons.campaign),
                                      tooltip: 'Nachalarmieren',
                                      onPressed: () =>
                                          _openAlarmDialog(incident),
                                    ),
                                  if (incident.state == IncidentState.draft)
                                    IconButton(
                                      key: Key(
                                        'discard-incident-${incident.id}',
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Verwerfen',
                                      onPressed: () => _discard(incident),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ],
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
/// (Stichwort, Adresse, Lagebeschreibung) and -- in a visually distinct,
/// warning-coloured container with lock icon -- the geheime Drehbuch.
/// Read-only once the Einsatz is `closed`.
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
  late final TextEditingController _locationSearchController;

  /// Current Einsatzort pin (ADR 0026), `null` when none is set.
  LatLng? _pin;

  /// Whether [widget.incident] already had a pin -- distinguishes "no
  /// change" from "pin explicitly removed" for [IncidentRepository.update]
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
    _locationSearchController = TextEditingController();
    _pin = incident?.location;
    _hadLocation = _pin != null;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _addressController.dispose();
    _reportController.dispose();
    _scriptController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }

  /// Searches [_locationSearchController]'s text, falling back to the
  /// Adresse field when the search field is empty (ADR 0026, Web-
  /// Einsatzformular: "Die Adresse im Textfeld wird durch die Suche nicht
  /// überschrieben" -- the search only reads the address, never writes it).
  Future<void> _search() async {
    final query = _locationSearchController.text.trim().isEmpty
        ? _addressController.text.trim()
        : _locationSearchController.text.trim();
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
      _suggestions = null;
    });
  }

  void _removePin() {
    setState(() => _pin = null);
  }

  void _submit() {
    final pin = _pin;
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
              const Text(
                'Meldebild',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('incident-form-keyword'),
                controller: _keywordController,
                readOnly: readOnly,
                decoration: const InputDecoration(labelText: 'Stichwort'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('incident-form-address'),
                controller: _addressController,
                readOnly: readOnly,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('incident-form-report'),
                controller: _reportController,
                readOnly: readOnly,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Lagebeschreibung',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Einsatzort (Karte)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (!readOnly) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('incident-form-location-search'),
                        controller: _locationSearchController,
                        decoration: const InputDecoration(
                          labelText: 'Adresssuche',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('incident-form-location-search-button'),
                      onPressed: _searching ? null : _search,
                      child: const Text('Suchen'),
                    ),
                  ],
                ),
                if (suggestions != null) ...[
                  const SizedBox(height: 4),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('incident-form-remove-pin'),
                  onPressed: _removePin,
                  child: const Text('Pin entfernen'),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                key: const Key('script-section'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.amber.shade800, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Drehbuch – GEHEIM, nie für die Mannschaft sichtbar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
            onPressed: _submit,
            child: const Text('Speichern'),
          ),
      ],
    );
  }
}
