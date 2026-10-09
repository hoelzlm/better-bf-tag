import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apns_push_service.dart';
import 'fcm_push_service.dart';

/// Platform push notifications (ADR 0018): token registration + deep-link
/// navigation on tap. Implementations: [FcmPushService] (Android, FCM),
/// [ApnsPushService] (iOS, direct APNs), [NoopPushService] (no
/// credentials configured / unsupported platform).
abstract class PushService {
  /// Requests notification permissions and performs any platform-specific
  /// setup. Safe to call more than once.
  Future<void> init();

  /// The current push token, if any.
  Future<String?> getToken();

  /// Emits a new token whenever the platform rotates it.
  Stream<String> get onTokenRefresh;

  /// The `alarm_id` the app was cold-started from (the user tapped a push
  /// notification while the app wasn't running), or `null`.
  Future<String?> initialAlarmId();

  /// Emits an `alarm_id` whenever the user taps a push notification while
  /// the app is running (foreground or background).
  Stream<String> get onAlarmOpened;
}

/// No-op [PushService] for platforms/builds without push credentials
/// (e.g. CI, desktop, or Android without the `FCM_*` dart-defines). The
/// app otherwise works normally -- only the push channel is inert.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> init() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<String?> initialAlarmId() async => null;

  @override
  Stream<String> get onAlarmOpened => const Stream<String>.empty();
}

const _fcmApiKey = String.fromEnvironment('FCM_API_KEY');
const _fcmAppId = String.fromEnvironment('FCM_APP_ID');
const _fcmSenderId = String.fromEnvironment('FCM_SENDER_ID');
const _fcmProjectId = String.fromEnvironment('FCM_PROJECT_ID');

/// Whether all four `FCM_*` dart-defines were provided at build time
/// (ADR 0018: CI builds without them, no `google-services.json` checked
/// in -- push is simply off in that case).
bool get fcmConfigured =>
    _fcmApiKey.isNotEmpty &&
    _fcmAppId.isNotEmpty &&
    _fcmSenderId.isNotEmpty &&
    _fcmProjectId.isNotEmpty;

/// Chooses the [PushService] implementation by platform (ADR 0018):
/// Android uses FCM only when [fcmConfigured], iOS always uses the native
/// APNs MethodChannel (no Firebase there), everything else (desktop/web,
/// and the host platform `flutter test` runs on) gets [NoopPushService].
final pushServiceProvider = Provider<PushService>((ref) {
  if (Platform.isAndroid) {
    return fcmConfigured ? FcmPushService() : const NoopPushService();
  }
  if (Platform.isIOS) {
    return ApnsPushService();
  }
  return const NoopPushService();
});
