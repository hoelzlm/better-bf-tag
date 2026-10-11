import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Computes the "Navigation starten" target URI (ADR 0026, "App
/// (Alarm-Screen, Einsatzdetail)"): Android (and every other non-iOS
/// platform) gets a `geo:` URI that most maps apps understand, iOS gets
/// an Apple Maps deep link.
Uri navigationUri(double lat, double lng, TargetPlatform platform) {
  if (platform == TargetPlatform.iOS) {
    return Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
  }
  return Uri.parse('geo:$lat,$lng?q=$lat,$lng');
}

/// Launches an external maps app for `uri` (`LaunchMode.externalApplication`).
/// Returns `false` without throwing when no app can handle it or the
/// launch otherwise fails -- callers show a SnackBar in that case.
typedef UriLauncher = Future<bool> Function(Uri uri);

Future<bool> _defaultLaunch(Uri uri) async {
  try {
    return await url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

/// Injectable so widget tests can fake the launcher without touching the
/// platform (ADR 0026).
final uriLauncherProvider = Provider<UriLauncher>((ref) => _defaultLaunch);

/// Resolves [navigationUri] for the current platform and starts
/// navigation via [launcher] (defaults to `url_launcher`). Returns `false`
/// on failure instead of throwing.
Future<bool> startNavigation(
  double lat,
  double lng, {
  TargetPlatform? platform,
  UriLauncher launcher = _defaultLaunch,
}) async {
  final uri = navigationUri(lat, lng, platform ?? defaultTargetPlatform);
  try {
    return await launcher(uri);
  } catch (_) {
    return false;
  }
}
