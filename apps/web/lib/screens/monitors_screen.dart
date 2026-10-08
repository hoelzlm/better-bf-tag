import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';
import '../admin/monitor_status.dart';

String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ja',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('confirm-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Monitore admin screen (`/admin/monitors`, Berechtigung Administrator):
/// Monitore anlegen/umbenennen, Kopplungscode erzeugen, sperren.
///
/// Loads `GET /monitors` once on entry and after every mutation -- there is
/// no realtime subscription here (same pattern as VehiclesScreen/
/// PersonsScreen).
class MonitorsScreen extends ConsumerStatefulWidget {
  const MonitorsScreen({super.key});

  @override
  ConsumerState<MonitorsScreen> createState() => _MonitorsScreenState();
}

class _MonitorsScreenState extends ConsumerState<MonitorsScreen> {
  List<Monitor>? _monitors;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final monitors =
          await ref.read(monitorAdminRepositoryProvider).listMonitors();
      if (!mounted) return;
      setState(() {
        _monitors = monitors;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Monitore konnten nicht geladen werden.';
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _MonitorFormDialog(),
    );
    if (name == null) return;
    try {
      await ref
          .read(monitorAdminRepositoryProvider)
          .createMonitor(name: name);
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Monitor konnte nicht angelegt werden.'),
      );
    }
  }

  Future<void> _openRenameDialog(Monitor monitor) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _MonitorFormDialog(initial: monitor),
    );
    if (name == null) return;
    try {
      await ref
          .read(monitorAdminRepositoryProvider)
          .updateMonitor(monitor.id, name: name);
      await _reload();
    } catch (error) {
      _showError(
        describeApiError(error, 'Monitor konnte nicht gespeichert werden.'),
      );
    }
  }

  Future<void> _revoke(Monitor monitor) async {
    final confirmed = await _confirm(
      context,
      title: 'Monitor sperren',
      message: 'Der Monitor zeigt danach nichts mehr an und muss neu '
          'gekoppelt werden.',
      confirmLabel: 'Sperren',
    );
    if (!confirmed) return;
    try {
      await ref.read(monitorAdminRepositoryProvider).revokeMonitor(
            monitor.id,
          );
      await _reload();
    } catch (error) {
      _showError(describeApiError(error, 'Monitor konnte nicht gesperrt werden.'));
    }
  }

  Future<void> _createPairingCode(Monitor monitor) async {
    try {
      final item = await ref
          .read(monitorAdminRepositoryProvider)
          .createPairingCode(monitor.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _MonitorPairingCodeDialog(item: item),
      );
    } catch (error) {
      _showError(
        describeApiError(error, 'Kopplungscode konnte nicht erzeugt werden.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitors = _monitors;
    return Scaffold(
      appBar: AppBar(title: const Text('Monitore')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-monitor'),
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Monitor anlegen'),
      ),
      body: monitors == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : ListView.builder(
              key: const Key('monitors-list'),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: monitors.length,
              itemBuilder: (context, index) {
                final monitor = monitors[index];
                final status = monitorStatusOf(monitor);
                final lastSeen = monitor.lastSeenAt;
                return ListTile(
                  key: Key('monitor-${monitor.id}'),
                  title: Text(monitor.name),
                  subtitle: Text(
                    '${status.label} · zuletzt gesehen '
                    '${lastSeen != null ? _formatDateTime(lastSeen.toLocal()) : '–'}',
                  ),
                  onTap: () => _openRenameDialog(monitor),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        key: Key('pairing-code-${monitor.id}'),
                        icon: const Icon(Icons.vpn_key),
                        tooltip: 'Kopplungscode erzeugen',
                        onPressed: () => _createPairingCode(monitor),
                      ),
                      if (!monitor.isRevoked)
                        TextButton(
                          key: Key('revoke-monitor-${monitor.id}'),
                          onPressed: () => _revoke(monitor),
                          child: const Text('Sperren'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _MonitorFormDialog extends StatefulWidget {
  const _MonitorFormDialog({this.initial});

  final Monitor? initial;

  @override
  State<_MonitorFormDialog> createState() => _MonitorFormDialogState();
}

class _MonitorFormDialogState extends State<_MonitorFormDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Monitor umbenennen' : 'Monitor anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('monitor-form-name'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const Key('monitor-form-submit'),
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

/// `Uri.base.origin`, but [Uri.origin] throws for schemes other than
/// http/https (e.g. `file://` in `flutter test`'s VM environment) -- fall
/// back to a manual origin string there instead of crashing the dialog.
String _origin() {
  final uri = Uri.base;
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return uri.origin;
  }
  return '${uri.scheme}://${uri.host}';
}

class _MonitorPairingCodeDialog extends StatelessWidget {
  const _MonitorPairingCodeDialog({required this.item});

  final MonitorPairingCode item;

  @override
  Widget build(BuildContext context) {
    final origin = _origin();
    return AlertDialog(
      title: const Text('Kopplungscode'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.code,
              key: const Key('pairing-code-text'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('gültig bis ${_formatDateTime(item.expiresAt.toLocal())}'),
            const SizedBox(height: 16),
            Text(
              'Am Fernseher $origin/monitor öffnen und den Code eingeben.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Dieser Code wird nur einmal angezeigt. Ein neuer Code '
              'beendet die aktuelle Sitzung dieses Monitors, falls er '
              'bereits gekoppelt ist.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}
