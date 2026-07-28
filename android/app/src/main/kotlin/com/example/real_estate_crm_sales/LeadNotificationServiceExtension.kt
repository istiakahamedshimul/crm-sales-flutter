package com.example.real_estate_crm_sales

import android.app.Notification
import androidx.annotation.Keep
import com.onesignal.notifications.INotificationReceivedEvent
import com.onesignal.notifications.INotificationServiceExtension

@Keep
class LeadNotificationServiceExtension : INotificationServiceExtension {
    override fun onNotificationReceived(event: INotificationReceivedEvent) {
        val data = event.notification.additionalData ?: return
        if (data.optString("screen") != "assigned_leads") return

        event.notification.setExtender { builder ->
            builder
                .setOngoing(true)
                .setAutoCancel(false)
                .setChannelId(MainActivity.LEAD_CHANNEL_ID)
            builder.notification.flags =
                builder.notification.flags or
                    Notification.FLAG_INSISTENT or
                    Notification.FLAG_NO_CLEAR
            builder
        }
        event.context
            .getSharedPreferences(PREFERENCES, 0)
            .edit()
            .putInt(NOTIFICATION_ID, event.notification.androidNotificationId)
            .apply()
    }

    companion object {
        const val PREFERENCES = "lead_alarm"
        const val NOTIFICATION_ID = "notification_id"
    }
}
