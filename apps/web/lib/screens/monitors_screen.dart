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
  final alarmColors = Theme.of(context).extension<BftagAlarmColors>();
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
          style: alarmColors == null
              ? null
              : ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(alarmColors.alarm),
                  foregroundColor: WidgetStatePropertyAll(alarmColors.onAlarm),
                ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Sort order for the Monitore-Liste (Konzept §3): gekoppelt zuerst, dann
/// nicht gekoppelt, dann gesperrt -- reine Darstellungsreihenfolge, keine
/// Zeile wird entfernt.
int _statusSortOrder(MonitorDisplayStatus status) => switch (status) {
      MonitorDisplayStatus.paired => 0,
      MonitorDisplayStatus.notPaired => 1,
      MonitorDisplayStatus.revoked => 2,
    };

List<Monitor> _sortedMonitors(List<Monitor> monitors) {
  final sorted = List<Monitor>.of(monitors);
  sorted.sort(
    (a, b) => _statusSortOrder(
      monitorStatusOf(a),
    ).compareTo(_statusSortOrder(monitorStatusOf(b))),
  );
  return sorted;
}

/// Monitore admin screen (`/admin/monitors`, Berechtigung Administrator):
/// Monitore anlegen/umbenennen, Kopplungscode erzeugen, sperren (Konzept
/// `docs/design/screens/web-monitore.md`).
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
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitore'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: spacing.lg),
            child: FilledButton.icon(
              key: const Key('create-monitor'),
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Monitor anlegen'),
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final monitors = _monitors;
    if (monitors == null) {
      final loadError = _loadError;
      if (loadError != null) {
        return BftagStateView.error(message: loadError, onRetry: _reload);
      }
      return const BftagStateView.loading();
    }
    if (monitors.isEmpty) {
      return BftagStateView.empty(
        icon: Icons.desktop_windows,
        title: 'Noch keine Monitore angelegt.',
        action: FilledButton.icon(
          key: const Key('monitors-empty-create'),
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Monitor anlegen'),
        ),
      );
    }

    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
    final sorted = _sortedMonitors(monitors);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radii.large),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.builder(
              key: const Key('monitors-list'),
              padding: EdgeInsets.zero,
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final monitor = sorted[index];
                return _MonitorRow(
                  key: ValueKey(monitor.id),
                  monitor: monitor,
                  isLast: index == sorted.length - 1,
                  onTap: () => _openRenameDialog(monitor),
                  onCreatePairingCode: () => _createPairingCode(monitor),
                  onRevoke: () => _revoke(monitor),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Status-Punkt vor dem Namen (Konzept §3): `primary` gefüllt = gekoppelt,
/// `outline`-Ring = nicht gekoppelt, `onSurfaceVariant` gestrichelt =
/// gesperrt. Farbe ist nie alleiniger Träger -- der Textstatus daneben
/// bleibt immer sichtbar.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final MonitorDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case MonitorDisplayStatus.paired:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        );
      case MonitorDisplayStatus.notPaired:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outline, width: 2),
          ),
        );
      case MonitorDisplayStatus.revoked:
        return CustomPaint(
          size: const Size(12, 12),
          painter: _DashedCirclePainter(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashCount = 8;
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (2 * 3.141592653589793 / dashCount) * i;
      final sweep = (2 * 3.141592653589793 / dashCount) * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MonitorRow extends StatelessWidget {
  const _MonitorRow({
    super.key,
    required this.monitor,
    required this.isLast,
    required this.onTap,
    required this.onCreatePairingCode,
    required this.onRevoke,
  });

  final Monitor monitor;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onCreatePairingCode;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final alarmColors = theme.extension<BftagAlarmColors>();
    final status = monitorStatusOf(monitor);
    final lastSeen = monitor.lastSeenAt;
    final lastSeenText = lastSeen != null
        ? 'zuletzt gesehen ${_formatDateTime(lastSeen.toLocal())}'
        : 'noch nie gesehen';
    return Column(
      children: [
        InkWell(
          key: Key('monitor-${monitor.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusDot(status: status),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        monitor.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    '${status.label} · $lastSeenText',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SizedBox(height: spacing.sm),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Tooltip(
                        message: 'Kopplungscode erzeugen',
                        child: FilledButton.tonalIcon(
                          key: Key('pairing-code-${monitor.id}'),
                          onPressed: onCreatePairingCode,
                          icon: const Icon(Icons.vpn_key),
                          label: const Text('Kopplungscode erzeugen'),
                        ),
                      ),
                      if (!monitor.isRevoked)
                        OutlinedButton(
                          key: Key('revoke-monitor-${monitor.id}'),
                          onPressed: onRevoke,
                          style: alarmColors == null
                              ? null
                              : OutlinedButton.styleFrom(
                                  foregroundColor: alarmColors.alarm,
                                  side: BorderSide(color: alarmColors.alarm),
                                ),
                          child: const Text('Sperren'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: theme.colorScheme.outline),
      ],
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
  String? _nameError;

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
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Name ist erforderlich.' : null;
    });
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
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
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
              ),
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
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();
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
            SizedBox(height: spacing.sm),
            Text('gültig bis ${_formatDateTime(item.expiresAt.toLocal())}'),
            SizedBox(height: spacing.lg),
            Text(
              'Am Fernseher $origin/monitor öffnen und den Code eingeben.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.lg),
            Container(
              padding: EdgeInsets.all(spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(radii.medium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      'Dieser Code wird nur einmal angezeigt. Ein neuer '
                      'Code beendet die aktuelle Sitzung dieses Monitors, '
                      'falls er bereits gekoppelt ist.',
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
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
