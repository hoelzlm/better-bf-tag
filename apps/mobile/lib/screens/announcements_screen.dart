import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../announcements/announcement_visuals.dart';
import '../widgets/main_nav_bar.dart';

/// Durchsagen screen for `/durchsagen` (ADR 0024): the last 20 visible
/// Durchsagen of the running BF-Tag from `snapshot.announcements` +
/// live `announcement.created`/`announcement.deleted` events, via
/// [pairedAnnouncementsProvider]. Already sorted newest-first by
/// `RealtimeClient`.
///
/// Layout/states per `docs/design/screens/app-durchsagen.md` §3/§4
/// (ADR 0027): each Durchsage is a `primaryContainer` card with the
/// "campaign" icon ([announcementSurfaceColor]/[announcementOnSurfaceColor],
/// shared with [AnnouncementSnackbarListener] via
/// `announcement_visuals.dart`), never `alarm`-colour or plain grey —
/// Durchsagen are explicitly not an Alarm (CONTEXT.md).
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements =
        ref.watch(pairedAnnouncementsProvider).valueOrNull ??
        const <Announcement>[];
    final theme = Theme.of(context);
    final radii = theme.extension<BftagRadii>()!;
    final spacing = theme.extension<BftagSpacing>()!;
    final surfaceColor = announcementSurfaceColor(context);
    final onSurfaceColor = announcementOnSurfaceColor(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Durchsagen')),
      body: announcements.isEmpty
          ? const BftagStateView.empty(
              icon: Icons.campaign_outlined,
              title: 'Keine Durchsagen',
            )
          : ListView.builder(
              key: const Key('announcements-list'),
              padding: EdgeInsets.all(spacing.md),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.sm),
                  child: Card(
                    key: Key('announcement-${announcement.id}'),
                    color: surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radii.large),
                    ),
                    child: ListTile(
                      minVerticalPadding: 12,
                      leading: Icon(announcementIcon, color: onSurfaceColor),
                      title: Text(
                        announcement.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: onSurfaceColor),
                      ),
                      subtitle: Text(
                        _formatTime(announcement.createdAt),
                        style: TextStyle(color: onSurfaceColor),
                      ),
                    ),
                  ),
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
