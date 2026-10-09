import Flutter
import UIKit
import UserNotifications

/// ADR 0018, "App" / iOS: direct APNs (no Firebase) via the
/// `de.bftag/push` MethodChannel, bridged from Dart's `ApnsPushService`.
/// Implements `UNUserNotificationCenterDelegate` so foreground
/// notifications never show a native banner (the WS already drives the
/// Alarm-Vollbild, ADR 0017) and so a tap -- cold start or
/// backgrounded -- is reported to Dart as `alarm_id`.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UNUserNotificationCenterDelegate {
  private var pushChannel: FlutterMethodChannel?
  private var pendingToken: String?
  private var pendingAlarmId: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
      let alarmId = alarmId(from: remoteNotification)
    {
      // Cold start from tapping a push notification, before the
      // implicit Flutter engine (and so `pushChannel`) exists yet --
      // buffer it for the `getInitialAlarmId` MethodChannel call.
      pendingAlarmId = alarmId
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "de.bftag/push",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "requestPermissionAndRegister":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }
        }
        result(nil)
      case "getToken":
        result(self.pendingToken)
      case "getInitialAlarmId":
        result(self.pendingAlarmId)
        self.pendingAlarmId = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    pushChannel = channel
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    pendingToken = token
    pushChannel?.invokeMethod("onToken", arguments: token)
  }

  // No banner in foreground: the WS already shows the Alarm-Vollbild
  // (ADR 0017), so a push notification only matters while backgrounded.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([])
  }

  // Tapping a notification while the app is running (foreground or
  // background) -- report to Dart immediately. A cold-start tap is
  // handled in `application(_:didFinishLaunchingWithOptions:)` instead.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let alarmId = alarmId(from: response.notification.request.content.userInfo) {
      if let channel = pushChannel {
        channel.invokeMethod("onAlarmOpened", arguments: alarmId)
      } else {
        pendingAlarmId = alarmId
      }
    }
    completionHandler()
  }

  private func alarmId(from userInfo: [AnyHashable: Any]) -> String? {
    userInfo["alarm_id"] as? String
  }
}
