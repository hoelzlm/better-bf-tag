package de.bftag.bftag_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val deviceSettingsChannelName = "de.bftag/device_settings"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createAlarmNotificationChannel()
    }

    // Creates the `alarm` notification channel used for Alarmierung
    // pushes (ADR 0018): Importance HIGH, custom sound, distinctive
    // vibration pattern. Android forbids changing a channel's
    // sound/importance after creation, so a future change must use a
    // new channel id instead of mutating this one.
    private fun createAlarmNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val soundUri = Uri.parse("android.resource://$packageName/raw/alarm")
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
            .build()

        val channel = NotificationChannel(
            "alarm",
            "Alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alarmierung zum BF-Tag"
            setSound(soundUri, audioAttributes)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 800, 400, 800, 400, 800)
        }
        manager.createNotificationChannel(channel)
    }

    // Reads/opens the system settings an alarm depends on (ADR 0021):
    // notification permission, Nicht-stören-Umgehung for the `alarm`
    // channel, battery-optimization exemption, and the device
    // manufacturer. Mirrors `DeviceSettings` in
    // `apps/mobile/lib/onboarding/device_settings.dart`.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            deviceSettingsChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "notificationsEnabled" ->
                    result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
                "bypassesDnd" -> result.success(channelBypassesDnd())
                "batteryOptimizationIgnored" -> result.success(isIgnoringBatteryOptimizations())
                "manufacturer" -> result.success(Build.MANUFACTURER.lowercase())
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "openDndSettings" -> {
                    openDndSettings()
                    result.success(null)
                }
                "requestIgnoreBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun channelBypassesDnd(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = getSystemService(NotificationManager::class.java)
        val channel = manager.getNotificationChannel("alarm") ?: return false
        return channel.canBypassDnd()
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val manager = getSystemService(PowerManager::class.java)
        return manager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        startActivity(intent)
    }

    private fun openDndSettings() {
        val intent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            putExtra(Settings.EXTRA_CHANNEL_ID, "alarm")
        }
        startActivity(intent)
    }

    private fun requestIgnoreBatteryOptimization() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        } catch (error: Exception) {
            val fallback = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            startActivity(fallback)
        }
    }
}
