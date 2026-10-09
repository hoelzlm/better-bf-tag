import Flutter
import UIKit
import UserNotifications

/// ADR 0018, "App" / iOS: direct APNs (no Firebase) via the
/// `de.bftag/push` MethodChannel, bridged from Dart's `ApnsPushService`.
/// Implements `UNUserNotificationCenterDelegate` so foreground
/// notifications never show a native banner (the WS already drives the
/// Alarm-Vollbild, ADR 0017) and so a tap -- cold start or
/// backgrounded -- is reported to Dart as `alarm_id`. A `test_alarm`
/// (ADR 0021) is the one exception: it has no `alarm_id` (tapping it
/// opens no Alarm-Screen) and -- because the app is in the foreground
/// when triggering it -- it must show a banner with sound and be
/// reported to Dart via the `de.bftag/push` channel's `testAlarmReceived`
/// call so `ApnsPushService.onTestAlarmReceived` can fire.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UNUserNotificationCenterDelegate {
  private var pushChannel: FlutterMethodChannel?
  private var deviceSettingsChannel: FlutterMethodChannel?
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

    let settingsChannel = FlutterMethodChannel(
      name: "de.bftag/device_settings",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    settingsChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "notificationsEnabled":
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          result(settings.authorizationStatus == .authorized)
        }
      case "bypassesDnd":
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          result(settings.timeSensitiveSetting == .enabled)
        }
      case "batteryOptimizationIgnored":
        result(true)
      case "manufacturer":
        result("apple")
      case "openNotificationSettings", "openDndSettings":
        DispatchQueue.main.async {
          if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }
        result(nil)
      case "requestIgnoreBatteryOptimization":
        // No such concept on iOS.
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    deviceSettingsChannel = settingsChannel
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    pendingToken = token
    pushChannel?.invokeMethod("onToken", arguments: token)
  }

  // No banner in foreground for a real Alarmierung: the WS already
  // shows the Alarm-Vollbild (ADR 0017). A `test_alarm` (ADR 0021) is
  // the exception -- the person just triggered it from the foreground
  // app, so it must show as a banner with sound, and is additionally
  // reported to Dart so `ApnsPushService.onTestAlarmReceived` fires.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    if (userInfo["type"] as? String) == "test_alarm" {
      pushChannel?.invokeMethod("testAlarmReceived", arguments: nil)
      completionHandler([.banner, .sound, .list])
      return
    }
    completionHandler([])
  }

  // Tapping a notification while the app is running (foreground or
  // background) -- report to Dart immediately. A cold-start tap is
  // handled in `application(_:didFinishLaunchingWithOptions:)` instead.
  // A `test_alarm` notification has no `alarm_id` (ADR 0021), so
  // `alarmId(from:)` returns `nil` here and nothing is reported --
  // tapping it must not open an Alarm-Screen.
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
