import 'dart:async';

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

  // Excludes Durchsage pushes (ADR 0024) explicitly, on top of the
  // implicit exclusion from the `alarm_id`/`where` filter below -- a
  // Durchsage payload never carries `alarm_id`, but this keeps the
  // split between the two push kinds obvious at the call site.
  @override
  Stream<String> get onAlarmOpened => FirebaseMessaging.onMessageOpenedApp
      .where((message) => message.data['type'] != 'announcement.created')
      .map((message) => message.data['alarm_id'] as String?)
      .where((alarmId) => alarmId != null)
      .cast<String>();

  // Only a `test_alarm` (ADR 0021) is relevant in the foreground: a real
  // Alarmierung is already shown via the WS-driven Alarm-Vollbild (ADR
  // 0017), so other foreground messages are intentionally ignored.
  @override
  Stream<void> get onTestAlarmReceived => FirebaseMessaging.onMessage
      .where((message) => message.data['type'] == 'test_alarm')
      .map((_) {});

  // Covers both cases in one stream (ADR 0024, "Clients"): a tap while
  // the app is already running (`onMessageOpenedApp`) and a cold start
  // from the tap (`getInitialMessage`, checked once when this getter is
  // first read). `onAlarmOpened` above excludes `type ==
  // 'announcement.created'`, so the two streams never both fire for the
  // same push.
  @override
  Stream<void> get onAnnouncementOpened {
    final controller = StreamController<void>.broadcast();
    unawaited(
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message?.data['type'] == 'announcement.created') {
          controller.add(null);
        }
      }),
    );
    final subscription = FirebaseMessaging.onMessageOpenedApp
        .where((message) => message.data['type'] == 'announcement.created')
        .listen((_) => controller.add(null));
    controller.onCancel = subscription.cancel;
    return controller.stream;
  }
}
