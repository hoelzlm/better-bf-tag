import 'package:bftag_core/bftag_core.dart';

/// Anzeigestatus eines Monitors im Admin-Bereich (ADR 0012: "gesperrt"
/// gewinnt immer, auch wenn der Monitor zuvor gekoppelt war).
enum MonitorDisplayStatus {
  notPaired,
  paired,
  revoked;

  /// German display label.
  String get label {
    switch (this) {
      case MonitorDisplayStatus.notPaired:
        return 'nicht gekoppelt';
      case MonitorDisplayStatus.paired:
        return 'gekoppelt';
      case MonitorDisplayStatus.revoked:
        return 'gesperrt';
    }
  }
}

/// Derives the display status from [monitor]'s `paired`/`revoked_at`
/// fields. "gesperrt" wins over "gekoppelt"/"nicht gekoppelt".
MonitorDisplayStatus monitorStatusOf(Monitor monitor) {
  if (monitor.isRevoked) {
    return MonitorDisplayStatus.revoked;
  }
  return monitor.paired ? MonitorDisplayStatus.paired : MonitorDisplayStatus.notPaired;
}
