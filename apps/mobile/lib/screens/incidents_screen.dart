import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/main_nav_bar.dart';

/// Einsatzliste screen for `/einsaetze`: shows the Einsätze of the
/// currently running BF-Tag via `GET /bf-days/current/incidents` (ADR
/// 0016) -- the server already filters by permission (Mannschaft sees
/// only `running`/`closed`, never Entwürfe or verworfene Einsätze).
///
/// Reloads on pull-to-refresh and whenever [pairedIncidentsProvider]
/// changes (a realtime `incident.updated` for the running list), since
/// that provider only tracks `running` Einsätze while this screen also
/// shows `closed` ones and needs the full list from the server.
///
/// Layout/states per `docs/design/screens/app-einsaetze.md` §3/§4
/// (ADR 0027): status chips use `primaryContainer`/`onPrimaryContainer`
/// (`running`) and `surfaceContainer`/`onSurfaceVariant` (`closed`,
/// i.e. the `surfaceVariant` design token -- see
/// `packages/core/lib/src/theme.dart`), never a hardcoded red/alarm.
class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

enum _LoadState { loading, noRunningBfDay, error, loaded }

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  List<Incident> _incidents = const [];
  _LoadState _loadState = _LoadState.loading;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final incidents =
          await ref.read(incidentRepositoryProvider).list('current');
      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _loadState = _LoadState.loaded;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadState = isNoRunningBfDayError(error)
            ? _LoadState.noRunningBfDay
            : _LoadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the realtime connection alive on this screen too, so
    // `session.revoked` is received (and logs the device out) regardless
    // of which tab is currently shown.
    ref.watch(pairedRealtimeClientProvider);
    ref.listen<AsyncValue<List<Incident>>>(pairedIncidentsProvider, (
      previous,
      next,
    ) {
      if (previous != null) {
        unawaited(_load());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsätze'),
        actions: [
          IconButton(
            key: const Key('settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: _load,
        child: _buildBody(context),
      ),
      bottomNavigationBar: const MainNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_loadState) {
      case _LoadState.loading:
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case _LoadState.noRunningBfDay:
        return _scrollableState(
          icon: Icons.event_busy_outlined,
          title: 'Kein laufender BF-Tag.',
        );
      case _LoadState.error:
        return _scrollableState(
          icon: Icons.warning_amber_outlined,
          iconColor: Theme.of(context).colorScheme.error,
          title: 'Einsätze konnten nicht geladen werden.',
          message: 'Nach unten ziehen zum erneut Laden.',
        );
      case _LoadState.loaded:
        if (_incidents.isEmpty) {
          return _scrollableState(
            icon: Icons.campaign_outlined,
            title: 'Noch keine Einsätze.',
          );
        }
        return ListView.separated(
          key: const Key('incidents-list'),
          itemCount: _incidents.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
          itemBuilder: (context, index) {
            final incident = _incidents[index];
            return ListTile(
              key: Key('incident-${incident.id}'),
              minVerticalPadding: 12,
              title: Text('#${incident.number} ${incident.keyword}'),
              subtitle: Text(incident.address),
              trailing: _StateChip(state: incident.state),
              onTap: () => context.push('/einsaetze/${incident.id}'),
            );
          },
        );
    }
  }

  /// Wraps the given state in a scrollable, centered container so
  /// [RefreshIndicator] keeps working even on an otherwise empty/error
  /// screen (Designsystem §5.10 Leer-/Fehlerzustand).
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

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final IncidentState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;
    switch (state) {
      case IncidentState.running:
        // `primaryContainer`/`onPrimaryContainer` -- NOT `alarm`/`onAlarm`
        // or a hardcoded red: a running Übungseinsatz is status info, not an
        // Alarmzustand of the app (Grundprinzip 1).
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        break;
      case IncidentState.closed:
      case IncidentState.draft:
      case IncidentState.discarded:
        // `surfaceContainer` is the Flutter mapping of the design-token
        // `surfaceVariant` (see packages/core/lib/src/theme.dart); the
        // deprecated `ColorScheme.surfaceVariant` getter is not wired to
        // this token and must stay unused.
        background = colorScheme.surfaceContainer;
        foreground = colorScheme.onSurfaceVariant;
        break;
    }
    return Chip(
      label: Text(state.label, style: TextStyle(color: foreground)),
      backgroundColor: background,
      side: BorderSide.none,
    );
  }
}
