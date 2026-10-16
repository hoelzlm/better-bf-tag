// ConnectionBanner: Offline-/Verbindungsbanner (Designsystem §5.10). Pure
// presentational widget, no Riverpod/provider dependency (ADR 0027,
// "Gemeinsame Widgets") — the input is a plain `bool`, the surface-specific
// provider wiring happens at the call site.
import 'package:flutter/material.dart';

/// Slim full-width banner shown while the realtime connection is down.
/// Renders nothing when [connected] is true. Never red — a reconnect is
/// not an alarm (Designsystem §5.10, Grundprinzip 1).
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.connected,
    this.text = 'Verbindung verloren — verbinde erneut …',
  });

  /// Whether the realtime connection is currently up.
  final bool connected;

  /// The message shown while disconnected.
  final String text;

  @override
  Widget build(BuildContext context) {
    if (connected) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
