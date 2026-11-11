package com.sribeesonline.sribees_new_orders

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Someone accepted an order (backend sends `{type: order_accepted, tag}` as a
 * silent data push): drop that order's notification from this phone, even
 * when the app is closed. Every ring of an order is posted by FCM under the
 * same tag (`new_order:<id>`, id 0), so one cancel clears it.
 *
 * Runs beside the firebase_messaging plugin's own receiver: both are in the
 * ordered RECEIVE broadcast, this one only reads it.
 */
class AlertClearReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        if (extras.getString("type") != "order_accepted") return
        val tag = extras.getString("tag") ?: return
        if (!tag.startsWith("new_order:")) return
        context.getSystemService(NotificationManager::class.java)?.cancel(tag, 0)
    }
}
