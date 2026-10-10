import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads/opens the system settings an alarm depends on (ADR 0021):
/// notification permission, Nicht-stören-Umgehung for the `alarm`
/// channel, battery-optimization exemption, and the device manufacturer
/// (for the Hersteller-Hinweis). Implementations: [MethodChannelDeviceSettings]
/// (Android/iOS) and [UnsupportedDeviceSettings] (desktop/tests).
abstract class DeviceSettings {
  Future<bool> notificationsEnabled();

  /// Android: channel `alarm`'s `canBypassDnd()`. iOS: Time Sensitive
  /// (`timeSensitiveSetting == .enabled`).
  Future<bool> bypassesDnd();

  /// Android: `PowerManager.isIgnoringBatteryOptimizations`. iOS: always
  /// true (no such concept).
  Future<bool> batteryOptimizationIgnored();

  /// Lowercased manufacturer name (`Build.MANUFACTURER.lowercase()` on
  /// Android, `'apple'` on iOS).
  Future<String> manufacturer();

  Future<void> openNotificationSettings();

  Future<void> openDndSettings();

  Future<void> requestIgnoreBatteryOptimization();
}

/// [DeviceSettings] backed by the `de.bftag/device_settings`
/// MethodChannel (Android `MainActivity.kt`, iOS `AppDelegate.swift`,
/// ADR 0021). A failed platform call (`PlatformException`/
/// `MissingPluginException`) is logged and mapped to a safe default:
/// `false` for status queries, a no-op for actions.
class MethodChannelDeviceSettings implements DeviceSettings {
  MethodChannelDeviceSettings({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('de.bftag/device_settings');

  final MethodChannel _channel;

  void _logError(String method, Object error, [StackTrace? stackTrace]) {
    developer.log(
      'DeviceSettings-Fehler ($method)',
      error: error,
      stackTrace: stackTrace,
      name: 'device_settings',
    );
  }

  Future<bool> _boolCall(String method) async {
    try {
      final result = await _channel.invokeMethod<bool>(method);
      return result ?? false;
    } catch (error, stackTrace) {
      _logError(method, error, stackTrace);
      return false;
    }
  }

  Future<void> _voidCall(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } catch (error, stackTrace) {
      _logError(method, error, stackTrace);
    }
  }

  @override
  Future<bool> notificationsEnabled() => _boolCall('notificationsEnabled');

  @override
  Future<bool> bypassesDnd() => _boolCall('bypassesDnd');

  @override
  Future<bool> batteryOptimizationIgnored() =>
      _boolCall('batteryOptimizationIgnored');

  @override
  Future<String> manufacturer() async {
    try {
      final result = await _channel.invokeMethod<String>('manufacturer');
      return result ?? 'unknown';
    } catch (error, stackTrace) {
      _logError('manufacturer', error, stackTrace);
      return 'unknown';
    }
  }

  @override
  Future<void> openNotificationSettings() =>
      _voidCall('openNotificationSettings');

  @override
  Future<void> openDndSettings() => _voidCall('openDndSettings');

  @override
  Future<void> requestIgnoreBatteryOptimization() =>
      _voidCall('requestIgnoreBatteryOptimization');
}

/// [DeviceSettings] for platforms without the native channel (desktop,
/// web, `flutter test`'s host platform): all statuses report as already
/// fine, the manufacturer is `'unknown'`, and the actions are no-ops.
class UnsupportedDeviceSettings implements DeviceSettings {
  const UnsupportedDeviceSettings();

  @override
  Future<bool> notificationsEnabled() async => true;

  @override
  Future<bool> bypassesDnd() async => true;

  @override
  Future<bool> batteryOptimizationIgnored() async => true;

  @override
  Future<String> manufacturer() async => 'unknown';

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> openDndSettings() async {}

  @override
  Future<void> requestIgnoreBatteryOptimization() async {}
}

/// Chooses the [DeviceSettings] implementation by platform: Android/iOS
/// use the native [MethodChannelDeviceSettings], everything else (and
/// the host platform `flutter test` runs on) gets
/// [UnsupportedDeviceSettings].
final deviceSettingsProvider = Provider<DeviceSettings>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return MethodChannelDeviceSettings();
  }
  return const UnsupportedDeviceSettings();
});
