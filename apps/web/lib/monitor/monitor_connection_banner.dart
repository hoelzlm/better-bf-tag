import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';

/// Shared connection banner for the monitor's standby and Einsatzansicht
/// screens (`docs/design/screens/monitor-standby.md` §3/§6 AC4,
/// `monitor-einsatz.md` AC7): a neutral `surfaceContainer`/`surfaceVariant`
/// banner, never the alarm/red color -- a dropped realtime connection is
/// not an Alarm (Grundprinzip 1). Hidden entirely once the connection is
/// live.
///
/// [status] takes the same input as `realtimeConnectionProvider`
/// (`null` while the very first snapshot hasn't resolved yet).
class MonitorConnectionBanner extends StatelessWidget {
  const MonitorConnectionBanner({super.key, required this.status});

  final ConnectionStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null || status == ConnectionStatus.connecting) {
      return const _Banner(
        key: Key('connection-banner-connecting'),
        icon: Icons.wifi_tethering,
        text: 'Verbinde …',
      );
    }
    if (status == ConnectionStatus.live) {
      return const SizedBox.shrink();
    }
    return const _Banner(
      key: Key('connection-banner-reconnecting'),
      icon: Icons.wifi_off,
      text: 'Keine Verbindung – verbinde neu …',
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final textStyle = (monitorStyles?.label ?? const TextStyle(fontSize: 22))
        .copyWith(color: colorScheme.onSurface);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      // `surfaceContainer` maps to the `surfaceVariant` token (theme.dart)
      // -- deliberately NOT `BftagAlarmColors.alarm`/`Colors.red`.
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colorScheme.onSurface, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(text, style: textStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
