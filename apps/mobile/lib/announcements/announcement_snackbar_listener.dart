import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wraps the app's `GoRouter`-driven widget tree, next to
/// `AlarmNavigationListener`: watches [pairedAnnouncementCreatedProvider]
/// and shows a SnackBar "Durchsage: text" with an "Anzeigen" action
/// that navigates to `/durchsagen` (ADR 0024, "App im Vordergrund").
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
    messengerState.showSnackBar(
      SnackBar(
        content: Text('Durchsage: ${announcement.text}'),
        action: SnackBarAction(
          label: 'Anzeigen',
          onPressed: () => router.go('/durchsagen'),
        ),
      ),
    );
  }
}
