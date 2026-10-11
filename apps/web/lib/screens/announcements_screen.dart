import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/api_errors.dart';
import '../widgets/confirm_dialog.dart';

/// `text varchar(500)` (ADR 0024): client-side pre-check and counter, the
/// server enforces the limit authoritatively.
const _maxAnnouncementTextLength = 500;

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Durchsagen admin screen (`/admin/durchsagen`, Berechtigung Leitstelle
/// oder Administrator, ADR 0024): Formular zum Senden einer Durchsage an
/// alle oder eine Schicht des laufenden BF-Tags, Liste der Durchsagen des
/// Tags (`snapshot.announcements` + Events, neueste zuerst), Löschen mit
/// Rückfrage.
///
/// Shows a disabled form with a hint when no BF-Tag is running -- a
/// Durchsage only makes sense while one is (ADR 0024: `POST
/// /bf-days/{day}/announcements` 409s with `bf_day_not_running`
/// otherwise).
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _textController = TextEditingController();
  String? _selectedShiftId; // null == "Alle"
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send(String bfDayId) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(announcementRepositoryProvider)
          .create(bfDayId, text: text, shiftId: _selectedShiftId);
      if (!mounted) return;
      _textController.clear();
      setState(() {
        _sending = false;
        _selectedShiftId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showError(describeAnnouncementError(error));
    }
  }

  Future<void> _delete(Announcement announcement) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Durchsage löschen',
      message: 'Diese Durchsage wird für alle Empfänger entfernt.',
      confirmLabel: 'Löschen',
    );
    if (confirmed != true) return;
    try {
      await ref.read(announcementRepositoryProvider).delete(announcement.id);
    } catch (error) {
      _showError(describeAnnouncementError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bfDay = ref.watch(bfDayProvider).valueOrNull;
    final shifts = ref.watch(shiftsProvider).valueOrNull ?? const <Shift>[];
    final announcements =
        ref.watch(announcementsProvider).valueOrNull ??
        const <Announcement>[];
    final running = bfDay != null && bfDay.state == BfDayState.running;
    final text = _textController.text;

    String targetLabel(String? shiftId) {
      if (shiftId == null) return 'Alle';
      for (final shift in shifts) {
        if (shift.id == shiftId) return shift.name;
      }
      return shiftId;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Durchsagen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!running)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Kein laufender BF-Tag',
                  key: Key('announcements-no-running-day'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            TextField(
              key: const Key('announcement-text'),
              controller: _textController,
              enabled: running && !_sending,
              maxLines: 4,
              maxLength: _maxAnnouncementTextLength,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Text'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<String?>(
                  key: const Key('announcement-target'),
                  value: _selectedShiftId,
                  onChanged: running
                      ? (value) => setState(() => _selectedShiftId = value)
                      : null,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Alle'),
                    ),
                    for (final shift in shifts)
                      DropdownMenuItem<String?>(
                        value: shift.id,
                        child: Text(shift.name),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                FilledButton(
                  key: const Key('announcement-send'),
                  onPressed:
                      running && !_sending && text.trim().isNotEmpty
                      ? () => _send(bfDay.id)
                      : null,
                  child: const Text('Senden'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: announcements.isEmpty
                  ? const Center(child: Text('Keine Durchsagen.'))
                  : ListView.builder(
                      key: const Key('announcements-list'),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        final time = announcement.createdAt.toLocal();
                        final timeLabel =
                            '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
                        return ListTile(
                          key: Key('announcement-${announcement.id}'),
                          title: Text(announcement.text),
                          subtitle: Text(
                            '$timeLabel · '
                            '${targetLabel(announcement.shiftId)}',
                          ),
                          trailing: IconButton(
                            key: Key(
                              'delete-announcement-${announcement.id}',
                            ),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Löschen',
                            onPressed: () => _delete(announcement),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
