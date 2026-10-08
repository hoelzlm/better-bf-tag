import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'monitor_fullscreen.dart';

/// Browser side effects triggered by the "Zum Aktivieren tippen" user
/// gesture (ADR 0012): wake lock and best-effort fullscreen. Behind an
/// interface so widget tests can inject a fake instead of touching real
/// browser APIs.
///
/// TODO(T08): unlock the alarm sound here too (same user-gesture
/// requirement), once Ticket 08 adds alarm playback.
abstract class MonitorPlatform {
  Future<void> enableWakeLock();

  Future<void> requestFullscreen();
}

class DefaultMonitorPlatform implements MonitorPlatform {
  @override
  Future<void> enableWakeLock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Ignore: wake lock is a nice-to-have, never fatal to the monitor.
    }
  }

  @override
  Future<void> requestFullscreen() async {
    try {
      await requestFullscreenPlatform();
    } catch (_) {
      // Ignore: fullscreen may be unsupported or rejected by the browser.
    }
  }
}

final monitorPlatformProvider = Provider<MonitorPlatform>(
  (ref) => DefaultMonitorPlatform(),
);
