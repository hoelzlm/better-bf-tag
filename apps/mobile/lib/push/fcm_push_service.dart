import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_service.dart';

/// Android push via Firebase Cloud Messaging (ADR 0018). Initializes
/// Firebase purely from `--dart-define`s (`FCM_API_KEY`, `FCM_APP_ID`,
/// `FCM_SENDER_ID`, `FCM_PROJECT_ID`) -- no `google-services.json` and no
/// `com.google.gms.google-services` Gradle plugin, so the app and CI
/// build without any Firebase secrets checked in. Foreground messages
/// are intentionally ignored: the app is already showing the WS-driven
/// Alarm-Vollbild in that case (ADR 0017).
class FcmPushService implements PushService {
  FirebaseApp? _app;

  Future<FirebaseMessaging> _ensureInitialized() async {
    _app ??= await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: String.fromEnvironment('FCM_API_KEY'),
        appId: String.fromEnvironment('FCM_APP_ID'),
        messagingSenderId: String.fromEnvironment('FCM_SENDER_ID'),
        projectId: String.fromEnvironment('FCM_PROJECT_ID'),
      ),
    );
    return FirebaseMessaging.instance;
  }

  @override
  Future<void> init() async {
    final messaging = await _ensureInitialized();
    // Covers Android 13+'s runtime POST_NOTIFICATIONS permission.
    await messaging.requestPermission();
  }

  @override
  Future<String?> getToken() async {
    final messaging = await _ensureInitialized();
    return messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Future<String?> initialAlarmId() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message?.data['alarm_id'] as String?;
  }

  @override
  Stream<String> get onAlarmOpened => FirebaseMessaging.onMessageOpenedApp
      .map((message) => message.data['alarm_id'] as String?)
      .where((alarmId) => alarmId != null)
      .cast<String>();
}
