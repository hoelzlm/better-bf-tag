import 'dart:async';

import 'package:flutter/services.dart';

import 'push_service.dart';

/// iOS push via direct APNs (ADR 0018, no Firebase). Talks to the native
/// side through the `de.bftag/push` MethodChannel implemented in
/// `AppDelegate.swift`: `requestPermissionAndRegister` requests
/// notification permission and calls `registerForRemoteNotifications`;
/// `getToken`/`getInitialAlarmId` are synchronous-from-Dart's-perspective
/// queries; native code invokes back via `onToken`/`onAlarmOpened`.
class ApnsPushService implements PushService {
  static const _channel = MethodChannel('de.bftag/push');

  final _tokenRefreshController = StreamController<String>.broadcast();
  final _alarmOpenedController = StreamController<String>.broadcast();
  bool _handlerInstalled = false;

  void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onToken':
          _tokenRefreshController.add(call.arguments as String);
        case 'onAlarmOpened':
          _alarmOpenedController.add(call.arguments as String);
      }
      return null;
    });
  }

  @override
  Future<void> init() async {
    _ensureHandler();
    await _channel.invokeMethod<void>('requestPermissionAndRegister');
  }

  @override
  Future<String?> getToken() {
    _ensureHandler();
    return _channel.invokeMethod<String>('getToken');
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<String?> initialAlarmId() {
    _ensureHandler();
    return _channel.invokeMethod<String>('getInitialAlarmId');
  }

  @override
  Stream<String> get onAlarmOpened => _alarmOpenedController.stream;
}
