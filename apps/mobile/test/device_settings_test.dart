import 'package:bftag_mobile/onboarding/device_settings.dart';
import 'package:bftag_mobile/onboarding/manufacturer_hints.dart';
import 'package:bftag_mobile/push/apns_push_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelDeviceSettings', () {
    const channel = MethodChannel('de.bftag/device_settings');
    final device = MethodChannelDeviceSettings(channel: channel);
    final calls = <MethodCall>[];

    void setHandler(Future<Object?> Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });
    }

    tearDown(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('notificationsEnabled calls the matching channel method', () async {
      setHandler((call) async => true);
      expect(await device.notificationsEnabled(), isTrue);
      expect(calls.single.method, 'notificationsEnabled');
    });

    test('bypassesDnd calls the matching channel method', () async {
      setHandler((call) async => false);
      expect(await device.bypassesDnd(), isFalse);
      expect(calls.single.method, 'bypassesDnd');
    });

    test(
      'batteryOptimizationIgnored calls the matching channel method',
      () async {
        setHandler((call) async => true);
        expect(await device.batteryOptimizationIgnored(), isTrue);
        expect(calls.single.method, 'batteryOptimizationIgnored');
      },
    );

    test('manufacturer calls the matching channel method', () async {
      setHandler((call) async => 'samsung');
      expect(await device.manufacturer(), 'samsung');
      expect(calls.single.method, 'manufacturer');
    });

    test(
      'manufacturer falls back to unknown when the result is null',
      () async {
        setHandler((call) async => null);
        expect(await device.manufacturer(), 'unknown');
      },
    );

    test('openNotificationSettings calls the matching channel method', () async {
      setHandler((call) async => null);
      await device.openNotificationSettings();
      expect(calls.single.method, 'openNotificationSettings');
    });

    test('openDndSettings calls the matching channel method', () async {
      setHandler((call) async => null);
      await device.openDndSettings();
      expect(calls.single.method, 'openDndSettings');
    });

    test(
      'requestIgnoreBatteryOptimization calls the matching channel method',
      () async {
        setHandler((call) async => null);
        await device.requestIgnoreBatteryOptimization();
        expect(calls.single.method, 'requestIgnoreBatteryOptimization');
      },
    );

    test('a PlatformException on a status query maps to false', () async {
      setHandler((call) async => throw PlatformException(code: 'error'));
      expect(await device.notificationsEnabled(), isFalse);
      expect(await device.bypassesDnd(), isFalse);
      expect(await device.batteryOptimizationIgnored(), isFalse);
    });

    test('a PlatformException on manufacturer maps to unknown', () async {
      setHandler((call) async => throw PlatformException(code: 'error'));
      expect(await device.manufacturer(), 'unknown');
    });

    test('a PlatformException on an action is swallowed', () async {
      setHandler((call) async => throw PlatformException(code: 'error'));
      await device.openNotificationSettings();
      await device.openDndSettings();
      await device.requestIgnoreBatteryOptimization();
    });
  });

  group('UnsupportedDeviceSettings', () {
    const device = UnsupportedDeviceSettings();

    test('status queries report as already fine', () async {
      expect(await device.notificationsEnabled(), isTrue);
      expect(await device.bypassesDnd(), isTrue);
      expect(await device.batteryOptimizationIgnored(), isTrue);
      expect(await device.manufacturer(), 'unknown');
    });

    test('actions are no-ops', () async {
      await device.openNotificationSettings();
      await device.openDndSettings();
      await device.requestIgnoreBatteryOptimization();
    });
  });

  group('batteryHintFor', () {
    test('samsung, xiaomi and the default hint are distinct', () {
      final samsung = batteryHintFor('samsung');
      final xiaomi = batteryHintFor('Redmi Note 12');
      final unknown = batteryHintFor('some-other-oem');

      expect(samsung, contains('dontkillmyapp.com'));
      expect(xiaomi, contains('dontkillmyapp.com'));
      expect(unknown, contains('dontkillmyapp.com'));

      expect(samsung, isNot(equals(xiaomi)));
      expect(samsung, isNot(equals(unknown)));
      expect(xiaomi, isNot(equals(unknown)));
    });
  });

  group('ApnsPushService.onTestAlarmReceived', () {
    test('a testAlarmReceived channel call emits an event', () async {
      const channel = MethodChannel('de.bftag/push');
      final service = ApnsPushService();

      final events = <void>[];
      final subscription = service.onTestAlarmReceived.listen(events.add);

      // Simulate the native side invoking the method call handler that
      // `onTestAlarmReceived` installed on the shared push channel.
      final data = channel.codec.encodeMethodCall(
        const MethodCall('testAlarmReceived'),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(channel.name, data, (_) {});
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      await subscription.cancel();
    });
  });
}
