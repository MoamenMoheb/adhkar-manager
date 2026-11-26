package com.moamenmoheb.adhkar_sanctuary

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray

data class UpcomingPrayerItem(
    val key: String,
    val title: String,
    val body: String,
    val timeMs: Long
)

object PrayerStickyHelper {
    const val NOTIF_ID = 8888
    const val CHANNEL_ID = "adhkar_sticky_salah_top_v3"
    private const val PREFS_NAME = "adhkar_sticky_prayer"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_SCHEDULE = "schedule_json"

    fun isEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ENABLED, false)
    }

    fun setEnabled(context: Context, enabled: Boolean) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    fun saveSchedule(context: Context, scheduleJson: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_SCHEDULE, scheduleJson).apply()
    }

    fun findNextPrayer(context: Context): UpcomingPrayerItem? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_SCHEDULE, null) ?: return null
        val now = System.currentTimeMillis()
        return try {
            val arr = JSONArray(raw)
            var best: UpcomingPrayerItem? = null
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val timeMs = obj.getLong("timeMs")
                if (timeMs > now) {
                    val candidate = UpcomingPrayerItem(
                        key = obj.optString("key", "fajr"),
                        title = obj.optString("title", "الصلاة القادمة"),
                        body = obj.optString("body", ""),
                        timeMs = timeMs
                    )
                    if (best == null || candidate.timeMs < best.timeMs) {
                        best = candidate
                    }
                }
            }
            best
        } catch (_: Exception) {
            null
        }
    }

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = nm.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "إشعار الصلاة القادمة المثبت",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "يبقي الصلاة القادمة والعد التنازلي مثبتة في أعلى شريط الإشعارات"
                    setSound(null, null)
                    enableVibration(false)
                    enableLights(false)
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(channel)
            }
        }
    }

    fun buildNotification(context: Context, item: UpcomingPrayerItem): Notification {
        ensureChannel(context)

        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("open_tab", "prayers")
            } ?: Intent(context, MainActivity::class.java)

        val contentPi = PendingIntent.getActivity(context, NOTIF_ID, launchIntent, piFlags)

        val dismissIntent = Intent(context, PrayerDismissReceiver::class.java)
        val deletePi = PendingIntent.getBroadcast(context, NOTIF_ID + 1, dismissIntent, piFlags)

        val iconRes = context.resources
            .getIdentifier("ic_launcher", "mipmap", context.packageName)
            .takeIf { it != 0 } ?: context.applicationInfo.icon

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        builder
            .setSmallIcon(iconRes)
            .setContentTitle(item.title)
            .setContentText(item.body)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSortKey("000000")
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setUsesChronometer(true)
            .setShowWhen(true)
            .setWhen(item.timeMs)
            .setContentIntent(contentPi)
            .setDeleteIntent(deletePi)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setChronometerCountDown(true)
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_MAX)
        }

        val notif = builder.build()
        notif.flags = notif.flags or
            Notification.FLAG_ONGOING_EVENT or
            Notification.FLAG_NO_CLEAR or
            Notification.FLAG_FOREGROUND_SERVICE
        return notif
    }

    fun startOrRefreshService(context: Context) {
        if (!isEnabled(context)) {
            stopService(context)
            return
        }
        val item = findNextPrayer(context) ?: return
        val serviceIntent = Intent(context, PrayerStickyService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {
            // Fallback for Android 12+ background FGS start restrictions: keep notification pinned
            postDirect(context, item)
        }
    }

    fun postDirect(context: Context, item: UpcomingPrayerItem? = null) {
        if (!isEnabled(context)) return
        val target = item ?: findNextPrayer(context) ?: return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(context, target))
    }

    fun stopService(context: Context) {
        setEnabled(context, false)
        try {
            context.stopService(Intent(context, PrayerStickyService::class.java))
        } catch (_: Exception) {
        }
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIF_ID)
    }
}
