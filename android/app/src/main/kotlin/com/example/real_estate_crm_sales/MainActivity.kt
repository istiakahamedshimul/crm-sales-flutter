package com.example.real_estate_crm_sales

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            LEAD_CHANNEL_ID,
            "New lead assignments",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alerts when a new lead is assigned"
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

    companion object {
        private const val LEAD_CHANNEL_ID = "lead_assignments_v1"
    }
}
