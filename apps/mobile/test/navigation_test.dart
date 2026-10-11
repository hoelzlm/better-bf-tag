import 'package:bftag_mobile/map/navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('navigationUri (ADR 0026)', () {
    test('android uses a geo: URI', () {
      final uri = navigationUri(48.1, 11.5, TargetPlatform.android);
      expect(uri.toString(), 'geo:48.1,11.5?q=48.1,11.5');
    });

    test('iOS uses an Apple Maps link', () {
      final uri = navigationUri(48.1, 11.5, TargetPlatform.iOS);
      expect(uri.toString(), 'https://maps.apple.com/?daddr=48.1,11.5');
    });

    test('defaults to geo: for other platforms', () {
      final uri = navigationUri(48.1, 11.5, TargetPlatform.linux);
      expect(uri.toString(), 'geo:48.1,11.5?q=48.1,11.5');
    });
  });

  group('startNavigation', () {
    test('calls the launcher with the platform-specific URI and returns '
        'its result', () async {
      Uri? launched;
      final ok = await startNavigation(
        48.1,
        11.5,
        platform: TargetPlatform.android,
        launcher: (uri) async {
          launched = uri;
          return true;
        },
      );

      expect(launched.toString(), 'geo:48.1,11.5?q=48.1,11.5');
      expect(ok, true);
    });

    test('returns false without throwing when the launcher fails', () async {
      final ok = await startNavigation(
        48.1,
        11.5,
        platform: TargetPlatform.android,
        launcher: (uri) async => false,
      );

      expect(ok, false);
    });

    test('returns false without throwing when the launcher throws', () async {
      final ok = await startNavigation(
        48.1,
        11.5,
        platform: TargetPlatform.android,
        launcher: (uri) async => throw Exception('boom'),
      );

      expect(ok, false);
    });
  });
}
