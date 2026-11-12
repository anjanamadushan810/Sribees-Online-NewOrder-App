package com.sribeesonline.sribees_new_orders

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
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
                    "alertHealth" -> result.success(alertHealth())
                    "openNotificationSettings" -> result.success(openNotificationSettings())
                    "openChannelSettings" -> result.success(openChannelSettings())
                    "openBatterySettings" -> result.success(openAppDetails())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Whether this phone can ring for a new order (P9). "Allowed" alone is not
     * enough: the New orders channel can be switched off or made silent on its
     * own, and a battery-restricted app may never get the push.
     */
    private fun alertHealth(): Map<String, Any?> {
        val nm = getSystemService(NotificationManager::class.java)
        val notificationsOn = nm?.areNotificationsEnabled() ?: true
        var channel = "on"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm != null) {
            val c = nm.getNotificationChannel(getString(R.string.new_orders_channel_id))
            if (c != null) {
                channel = when {
                    c.importance == NotificationManager.IMPORTANCE_NONE -> "off"
                    c.importance < NotificationManager.IMPORTANCE_DEFAULT || c.sound == null -> "silent"
                    else -> "on"
                }
            }
        }
        val restricted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getSystemService(ActivityManager::class.java)?.isBackgroundRestricted ?: false
        } else {
            false
        }
        val model = "${Build.MANUFACTURER} ${Build.MODEL}".trim().take(64)
        return mapOf(
            "notifications" to notificationsOn,
            "channel" to channel,
            "backgroundRestricted" to restricted,
            "model" to model,
        )
    }

    private fun start(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }

    /** This app's own notification page; the app details page on old phones. */
    private fun openNotificationSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val i = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            if (start(i)) return true
        }
        return openAppDetails()
    }

    /** The New orders channel's own page (sound, pop-up, on/off). */
    private fun openChannelSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val i = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                .putExtra(Settings.EXTRA_CHANNEL_ID, getString(R.string.new_orders_channel_id))
            if (start(i)) return true
        }
        return openNotificationSettings()
    }

    /**
     * App details: where "Battery" -> Unrestricted lives on every make. No
     * REQUEST_IGNORE_BATTERY_OPTIMIZATIONS: Play restricts it, and the default
     * "optimised" still gets high-priority pushes -- "restricted" is the problem.
     */
    private fun openAppDetails(): Boolean = start(
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
    )

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
