import 'dart:convert';

import 'package:bftag_core/bftag_core.dart';
import 'package:web/web.dart' as web;

/// Browser [TokenStore] for the web monitor (ADR 0012, "Monitor im
/// Browser"): persists the refresh token + monitor id in `localStorage`
/// under [_storageKey], so the monitor's session survives page reloads
/// independently of the admin web session (which uses an HttpOnly cookie,
/// never `localStorage`).
const String _storageKey = 'bftag.monitor.session';

class LocalStorageTokenStore implements TokenStore {
  @override
  Future<StoredDeviceSession?> read() async {
    final raw = web.window.localStorage.getItem(_storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final refreshToken = json['refresh_token'] as String?;
      final deviceId = json['monitor_id'] as String?;
      if (refreshToken == null || deviceId == null) return null;
      return StoredDeviceSession(refreshToken: refreshToken, deviceId: deviceId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(StoredDeviceSession session) async {
    web.window.localStorage.setItem(
      _storageKey,
      jsonEncode({
        'refresh_token': session.refreshToken,
        'monitor_id': session.deviceId,
      }),
    );
  }

  @override
  Future<void> clear() async {
    web.window.localStorage.removeItem(_storageKey);
  }
}
