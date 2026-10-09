import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Einsatzdetail screen for `/einsaetze/:id`: Meldebild (Stichwort,
/// Adresse, Lagebeschreibung) and, only when the server included the
/// `script` field (ADR 0016 -- Einsatzvorbereitung/Leitstelle/
/// Administrator), a separate, visually distinct Drehbuch section. The
/// app never decides visibility itself, only by the field's presence.
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
        onRefresh: _load,
        child: _buildBody(incident),
      ),
    );
  }

  Widget _buildBody(Incident? incident) {
    switch (_loadState) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.error:
        return _scrollableMessage('Einsatz konnte nicht geladen werden.');
      case _LoadState.loaded:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident!.keyword,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(incident.address),
              if (incident.report.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(incident.report),
              ],
              if (incident.script != null) ...[
                const SizedBox(height: 24),
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
                              'Drehbuch – GEHEIM',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(incident.script!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

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
