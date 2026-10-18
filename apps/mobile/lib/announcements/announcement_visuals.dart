import 'package:flutter/material.dart';

/// Shared visual identity for Durchsagen (app-durchsagen.md §3/§4, AC1+AC2):
/// the list cards on `/durchsagen` and the transient SnackBar
/// ([AnnouncementSnackbarListener]) both use the "campaign" icon on a
/// `primaryContainer` surface — deliberately NOT `alarm`/`onAlarm` or a
/// neutral grey, since a Durchsage is explicitly not an Alarm
/// (CONTEXT.md). Kept in one place so both call sites stay in sync.
const IconData announcementIcon = Icons.campaign;

/// The Durchsage surface colour (`primaryContainer`).
Color announcementSurfaceColor(BuildContext context) =>
    Theme.of(context).colorScheme.primaryContainer;

/// The Durchsage foreground colour (`onPrimaryContainer`) for icon/text on
/// [announcementSurfaceColor].
Color announcementOnSurfaceColor(BuildContext context) =>
    Theme.of(context).colorScheme.onPrimaryContainer;
