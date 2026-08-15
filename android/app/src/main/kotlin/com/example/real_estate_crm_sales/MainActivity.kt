package com.example.real_estate_crm_sales

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        stopLeadAlarm()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            LEAD_CHANNEL_ID,
            "CRM warning alerts",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Audible alerts for lead assignments and overdue follow-ups"
            enableVibration(true)
            setSound(
                Uri.parse("android.resource://$packageName/raw/lead_notification"),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
        }

        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    override fun onResume() {
        super.onResume()
        stopLeadAlarm()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        stopLeadAlarm()
    }

    private fun stopLeadAlarm() {
        val preferences = getSharedPreferences(
            LeadNotificationServiceExtension.PREFERENCES,
            MODE_PRIVATE
        )
        val notificationId = preferences.getInt(
            LeadNotificationServiceExtension.NOTIFICATION_ID,
            -1
        )
        if (notificationId != -1) {
            getSystemService(NotificationManager::class.java)
                .cancel(notificationId)
            preferences.edit()
                .remove(LeadNotificationServiceExtension.NOTIFICATION_ID)
                .apply()
        }
    }

    companion object {
        // Versioned because Android notification-channel sounds are immutable after creation.
        const val LEAD_CHANNEL_ID = "crm_warning_alerts_v1"
    }
}
