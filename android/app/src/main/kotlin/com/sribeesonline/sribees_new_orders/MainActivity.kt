package com.sribeesonline.sribees_new_orders

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNewOrdersChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Flutter plays the same ringtone for an order that arrives while the
        // app is open (FCM does not draw those) and for "test the sound".
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sribees/alerts")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playNewOrderSound" -> {
                        try {
                            RingtoneManager.getRingtone(applicationContext, soundUri())?.play()
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun soundUri(): Uri = Uri.parse(
        ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + packageName + "/" + R.raw.new_order
    )

    /**
     * The channel every new-order push lands in. The backend names it in each
     * FCM message (staff_order_alert_service.py: channel "new_orders", sound
     * "new_order"), and the manifest makes it the default too.
     *
     * In the background the system -- not Flutter -- draws the notification,
     * and on Android 8+ the channel, not the message, decides the sound. So
     * the ringtone is set here. Creating an existing channel is a no-op, and
     * the user's own settings for it always win.
     */
    private fun createNewOrdersChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.new_orders_channel_id),
            getString(R.string.new_orders_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.new_orders_channel_description)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 400, 200, 400)
            setSound(
                soundUri(),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }
}
