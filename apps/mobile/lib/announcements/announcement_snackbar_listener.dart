import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'announcement_visuals.dart';

/// Wraps the app's `GoRouter`-driven widget tree, next to
/// `AlarmNavigationListener`: watches [pairedAnnouncementCreatedProvider]
/// and shows a SnackBar "Durchsage: text" with an "Anzeigen" action
/// that navigates to `/durchsagen` (ADR 0024, "App im Vordergrund").
///
/// Visual-only per `docs/design/screens/app-durchsagen.md` §4/AC2: the
/// SnackBar shares the "campaign" icon + `primaryContainer` surface with
/// the Durchsagen-list cards (`announcement_visuals.dart`), auto-dismisses
/// after 8 s (Designsystem §5.7). The `messengerKey` mechanism and the
/// "Anzeigen" → `/durchsagen` navigation are unchanged.
///
/// Uses [messengerKey] rather than `ScaffoldMessenger.of(context)`
/// because this widget sits above `MaterialApp.router` in the tree and
/// has no `Scaffold` ancestor of its own.
class AnnouncementSnackbarListener extends ConsumerWidget {
  const AnnouncementSnackbarListener({
    super.key,
    required this.messengerKey,
    required this.router,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Announcement>>(pairedAnnouncementCreatedProvider, (
      previous,
      next,
    ) {
      next.whenData(_showSnackBar);
    });

    return child;
  }

  void _showSnackBar(Announcement announcement) {
    final messengerState = messengerKey.currentState;
    if (messengerState == null) return;
    // `messengerState.context` (not the outer `context` from `build`,
    // which sits above `MaterialApp.router` and has no `Theme` ancestor
    // of its own) so the SnackBar reads the app's theme.
    final theme = Theme.of(messengerState.context);
    final colorScheme = theme.colorScheme;
    final onSurfaceColor = colorScheme.onPrimaryContainer;
    messengerState.showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.primaryContainer,
        duration: const Duration(seconds: 8),
        content: Row(
          children: [
            Icon(announcementIcon, color: onSurfaceColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Durchsage: ${announcement.text}',
                style: TextStyle(color: onSurfaceColor),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Anzeigen',
          textColor: onSurfaceColor,
          onPressed: () => router.go('/durchsagen'),
        ),
      ),
    );
  }
}
