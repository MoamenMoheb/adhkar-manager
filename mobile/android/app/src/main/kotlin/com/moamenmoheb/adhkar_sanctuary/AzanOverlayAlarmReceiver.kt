package com.moamenmoheb.adhkar_sanctuary

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build

class AzanOverlayAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        // Re-arm the subsequent prayer immediately
        AzanOverlayHelper.scheduleNextAlarm(context)

        if (!AzanOverlayHelper.isEnabled(context)) return

        val title = intent?.getStringExtra("title")?.takeIf { it.isNotBlank() } ?: "حان الآن موعد الصلاة"
        val timeText = intent?.getStringExtra("timeText") ?: ""
        val cityName = AzanOverlayHelper.getCityName(context)
        val wallpaperKey = AzanOverlayHelper.getWallpaperKey(context)
        val soundKey = AzanOverlayHelper.getSoundKey(context)
        val vibrate = AzanOverlayHelper.isVibrate(context)

        val overlayIntent = AzanOverlayActivity.buildLaunchIntent(
            context = context,
            prayerName = title,
            prayerTime = timeText,
            cityName = cityName,
            wallpaperKey = wallpaperKey,
            soundKey = soundKey,
            vibrate = vibrate,
            isPreview = false
        )

        if (AzanOverlayHelper.canDrawOverlays(context)) {
            try {
                context.startActivity(overlayIntent)
            } catch (_: Exception) {
            }
        }

        // Also post a silent full-screen intent notification for lockscreen wakeup compatibility
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existing = nm.getNotificationChannel(AzanOverlayHelper.FULLSCREEN_CHANNEL_ID)
            if (existing == null) {
                val ch = NotificationChannel(
                    AzanOverlayHelper.FULLSCREEN_CHANNEL_ID,
                    "شاشة الأذان الكاملة",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "تفتح شاشة الأذان الإسلامية فوق التطبيقات عند دخول وقت الصلاة"
                    setSound(null, null)
                    enableVibration(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(ch)
            }
        }

        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val fsPi = PendingIntent.getActivity(
            context,
            AzanOverlayHelper.FULLSCREEN_NOTIF_ID,
            overlayIntent,
            piFlags
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, AzanOverlayHelper.FULLSCREEN_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        builder
            .setSmallIcon(R.drawable.ic_notif_logo)
            .setContentTitle(title)
            .setContentText(if (timeText.isNotEmpty()) "$timeText • اضغط لفتح شاشة الأذان" else "اضغط لفتح شاشة الأذان")
            .setColor(Color.parseColor("#064E3B"))
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(fsPi)
            .setFullScreenIntent(fsPi, true)

        nm.notify(AzanOverlayHelper.FULLSCREEN_NOTIF_ID, builder.build())
    }
}
