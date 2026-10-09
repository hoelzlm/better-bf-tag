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
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      bottomNavigationBar: const MainNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    switch (_loadState) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.noRunningBfDay:
        return _scrollableMessage('Kein laufender BF-Tag.');
      case _LoadState.error:
        return _scrollableMessage('Einsätze konnten nicht geladen werden.');
      case _LoadState.loaded:
        if (_incidents.isEmpty) {
          return _scrollableMessage('Noch keine Einsätze.');
        }
        return ListView.builder(
          key: const Key('incidents-list'),
          itemCount: _incidents.length,
          itemBuilder: (context, index) {
            final incident = _incidents[index];
            return ListTile(
              key: Key('incident-${incident.id}'),
              title: Text('#${incident.number} ${incident.keyword}'),
              subtitle: Text(incident.address),
              trailing: _StateChip(state: incident.state),
              onTap: () => context.push('/einsaetze/${incident.id}'),
            );
          },
        );
    }
  }

  /// Wraps [message] in a scrollable, centered container so
  /// [RefreshIndicator] keeps working even on an otherwise empty screen.
  Widget _scrollableMessage(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: Text(message)),
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
    final Color color;
    switch (state) {
      case IncidentState.running:
        color = Colors.red.shade600;
        break;
      case IncidentState.closed:
        color = Colors.grey.shade500;
        break;
      case IncidentState.draft:
      case IncidentState.discarded:
        color = Colors.grey.shade300;
        break;
    }
    return Chip(
      label: Text(
        state.label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}
