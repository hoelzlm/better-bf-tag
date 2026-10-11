import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/main_nav_bar.dart';

/// Durchsagen screen for `/durchsagen` (ADR 0024): the last 20 visible
/// Durchsagen of the running BF-Tag from `snapshot.announcements` +
/// live `announcement.created`/`announcement.deleted` events, via
/// [pairedAnnouncementsProvider]. Already sorted newest-first by
/// `RealtimeClient`.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements =
        ref.watch(pairedAnnouncementsProvider).valueOrNull ??
        const <Announcement>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Durchsagen')),
      body: announcements.isEmpty
          ? const Center(child: Text('Keine Durchsagen'))
          : ListView.builder(
              key: const Key('announcements-list'),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return ListTile(
                  key: Key('announcement-${announcement.id}'),
                  title: Text(announcement.text),
                  subtitle: Text(_formatTime(announcement.createdAt)),
                );
              },
            ),
      bottomNavigationBar: const MainNavBar(currentIndex: 2),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
