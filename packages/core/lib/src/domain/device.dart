/// Plattform eines gekoppelten Geräts (Mobile-App).
enum DevicePlatform {
  android,
  ios;

  /// German display label.
  String get label {
    switch (this) {
      case DevicePlatform.android:
        return 'Android';
      case DevicePlatform.ios:
        return 'iOS';
    }
  }
}

/// Ein gekoppeltes Gerät einer Person (`GET /persons/{id}/devices`).
///
/// Siehe ADR 0010 ("Geräte-Sitzung (Mobile-App)").
class Device {
  const Device({
    required this.id,
    required this.platform,
    this.deviceName,
    required this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
    this.revokedAt,
  });

  final String id;
  final DevicePlatform platform;
  final String? deviceName;
  final String appVersion;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final DateTime? revokedAt;

  /// Whether this device has been locked (`Sperren`).
  bool get isRevoked => revokedAt != null;
}
