import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [TokenStore] backed by `flutter_secure_storage` (iOS Keychain / Android
/// Keystore), so the device's refresh token survives app restarts without
/// being readable by other apps.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _refreshTokenKey = 'bftag.device.refresh_token';
  static const _deviceIdKey = 'bftag.device.device_id';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredDeviceSession?> read() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final deviceId = await _storage.read(key: _deviceIdKey);
    if (refreshToken == null || deviceId == null) {
      return null;
    }
    return StoredDeviceSession(refreshToken: refreshToken, deviceId: deviceId);
  }

  @override
  Future<void> write(StoredDeviceSession session) async {
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(key: _deviceIdKey, value: session.deviceId);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _deviceIdKey);
  }
}
