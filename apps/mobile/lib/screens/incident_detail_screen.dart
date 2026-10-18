import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../map/incident_location_card.dart';
import '../map/station_provider.dart';

/// Einsatzdetail screen for `/einsaetze/:id`: Meldebild (Stichwort,
/// Adresse, Lagebeschreibung) and, only when the server included the
/// `script` field (ADR 0016 -- Einsatzvorbereitung/Leitstelle/
/// Administrator), a separate, visually distinct Drehbuch section. The
/// app never decides visibility itself, only by the field's presence.
///
/// Layout/states per `docs/design/screens/app-einsatzdetail.md` §3/§4
/// (ADR 0027): Adresse/Lagebeschreibung get `labelMedium` labels, the
/// Drehbuch-Card uses `primaryContainer`/`onPrimaryContainer` (never
/// a hardcoded amber).
class IncidentDetailScreen extends ConsumerStatefulWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  ConsumerState<IncidentDetailScreen> createState() =>
      _IncidentDetailScreenState();
}

enum _LoadState { loading, error, loaded }

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  Incident? _incident;
  _LoadState _loadState = _LoadState.loading;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final incident =
          await ref.read(incidentRepositoryProvider).get(widget.incidentId);
      if (!mounted) return;
      setState(() {
        _incident = incident;
        _loadState = _LoadState.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadState = _LoadState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = _incident;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          incident == null ? 'Einsatz' : '#${incident.number} ${incident.keyword}',
        ),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: _load,
        child: _buildBody(context, incident),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Incident? incident) {
    switch (_loadState) {
      case _LoadState.loading:
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case _LoadState.error:
        return _scrollableState(
          icon: Icons.warning_amber_outlined,
          iconColor: Theme.of(context).colorScheme.error,
          title: 'Einsatz konnte nicht geladen werden.',
          message: 'Nach unten ziehen zum erneut Laden.',
        );
      case _LoadState.loaded:
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident!.keyword,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _FieldLabel(icon: Icons.place_outlined, label: 'Adresse'),
              const SizedBox(height: 4),
              Text(incident.address, style: textTheme.bodyLarge),
              if (incident.report.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FieldLabel(label: 'Lagebeschreibung'),
                const SizedBox(height: 4),
                Text(incident.report, style: textTheme.bodyLarge),
              ],
              if (incident.location != null) ...[
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: IncidentLocationCard(
                      incident: incident.location!,
                      station: ref.watch(pairedStationProvider).valueOrNull,
                    ),
                  ),
                ),
              ],
              if (incident.script != null) ...[
                const SizedBox(height: 24),
                Container(
                  key: const Key('script-section'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    border: Border.all(color: colorScheme.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Drehbuch – nur für dich sichtbar',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        incident.script!,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _scrollableState({
    required IconData icon,
    required String title,
    Color? iconColor,
    String? message,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: iconColor ?? theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// `labelMedium` field label, optionally preceded by an icon (Adresse
/// gets the `place_outlined` icon per the concept wireframe,
/// Lagebeschreibung does not).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (icon == null) {
      return Text(label, style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}
