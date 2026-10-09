import 'dart:async';
import 'dart:developer' as developer;

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'push_service.dart';

/// Registers the device's push token with the backend (ADR 0018) and
/// navigates to `/alarm/:alarmId` when the user taps a push
/// notification.
///
/// Wraps the app's widget tree alongside `AlarmNavigationListener`:
/// - once the paired session becomes [Paired] (app start and every
///   re-pair), calls [PushService.init] and registers the current token
///   via [pushTokenRepositoryProvider];
/// - re-registers on every [PushService.onTokenRefresh] event;
/// - checks [PushService.initialAlarmId] once per pairing (cold start
///   from a tap) and navigates on every [PushService.onAlarmOpened]
///   event (tap while running), but only while [Paired] -- an unpaired
///   device ignores a stale deep link.
///
/// Errors from the push service or the repository are logged and never
/// crash the app or block the rest of the UI.
class PushRegistrar extends ConsumerStatefulWidget {
  const PushRegistrar({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<PushRegistrar> createState() => _PushRegistrarState();
}

class _PushRegistrarState extends ConsumerState<PushRegistrar> {
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<String>? _alarmOpenedSub;
  bool _wired = false;
  bool _initializedForCurrentPairing = false;

  void _logError(Object error, [StackTrace? stackTrace]) {
    developer.log(
      'Push-Fehler',
      error: error,
      stackTrace: stackTrace,
      name: 'push',
    );
  }

  Future<void> _registerToken(String token) async {
    try {
      await ref.read(pushTokenRepositoryProvider).updatePushToken(token);
    } catch (error, stackTrace) {
      _logError(error, stackTrace);
    }
  }

  Future<void> _initAndRegister() async {
    final service = ref.read(pushServiceProvider);
    try {
      await service.init();
      final token = await service.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (error, stackTrace) {
      _logError(error, stackTrace);
    }
  }

  Future<void> _checkInitialAlarm() async {
    final service = ref.read(pushServiceProvider);
    try {
      final alarmId = await service.initialAlarmId();
      if (alarmId != null) {
        _navigate(alarmId);
      }
    } catch (error, stackTrace) {
      _logError(error, stackTrace);
    }
  }

  void _navigate(String alarmId) {
    if (!mounted) return;
    final session = ref.read(pairedSessionControllerProvider);
    if (session is! Paired) return;
    widget.router.go('/alarm/$alarmId');
  }

  void _wireStreamsOnce() {
    if (_wired) return;
    _wired = true;
    final service = ref.read(pushServiceProvider);
    _tokenRefreshSub = service.onTokenRefresh.listen(
      (token) => unawaited(_registerToken(token)),
      onError: _logError,
    );
    _alarmOpenedSub = service.onAlarmOpened.listen(
      _navigate,
      onError: _logError,
    );
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    _alarmOpenedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _wireStreamsOnce();

    final session = ref.watch(pairedSessionControllerProvider);
    final isPaired = session is Paired;
    if (!isPaired) {
      _initializedForCurrentPairing = false;
    } else if (!_initializedForCurrentPairing) {
      _initializedForCurrentPairing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_initAndRegister());
        unawaited(_checkInitialAlarm());
      });
    }

    return widget.child;
  }
}
