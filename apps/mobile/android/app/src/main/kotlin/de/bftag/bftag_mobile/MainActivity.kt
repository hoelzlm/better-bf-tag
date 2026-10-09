package de.bftag.bftag_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
}
