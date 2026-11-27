package com.moamenmoheb.adhkar_sanctuary

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONArray

data class StickyPrayerDisplayState(
    val key: String,
    val title: String,
    val timeText: String,
    val prayerTimeMs: Long,
    val countdownTargetMs: Long,
    val isPostAzan: Boolean
)

object PrayerStickyHelper {
    const val NOTIF_ID = 8888
    const val CHANNEL_ID = "adhkar_sticky_salah_top_v3"
    private const val POST_AZAN_WINDOW_MS = 10 * 60 * 1000L
    private const val TRANSITION_REQUEST_CODE = 8891
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

    fun findActiveState(context: Context): StickyPrayerDisplayState? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_SCHEDULE, null) ?: return null
        val now = System.currentTimeMillis()
        return try {
            val arr = JSONArray(raw)
            var activePostAzan: StickyPrayerDisplayState? = null
            var nextUpcoming: StickyPrayerDisplayState? = null

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val key = obj.optString("key", "fajr")
                val title = obj.optString("title", "الصلاة القادمة")
                val body = obj.optString("body", "")
                val timeMs = obj.getLong("timeMs")

                if (key != "sunrise" && now >= timeMs && now < timeMs + POST_AZAN_WINDOW_MS) {
                    if (activePostAzan == null || timeMs > activePostAzan.prayerTimeMs) {
                        activePostAzan = StickyPrayerDisplayState(
                            key = key,
                            title = title,
                            timeText = body,
                            prayerTimeMs = timeMs,
                            countdownTargetMs = timeMs + POST_AZAN_WINDOW_MS,
                            isPostAzan = true
                        )
                    }
                } else if (timeMs > now) {
                    if (nextUpcoming == null || timeMs < nextUpcoming.prayerTimeMs) {
                        nextUpcoming = StickyPrayerDisplayState(
                            key = key,
                            title = title,
                            timeText = body,
                            prayerTimeMs = timeMs,
                            countdownTargetMs = timeMs,
                            isPostAzan = false
                        )
                    }
                }
            }
            activePostAzan ?: nextUpcoming
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

    fun buildNotification(context: Context, state: StickyPrayerDisplayState): Notification {
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

        val isNightMode = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES
        val titleColor = if (isNightMode) Color.parseColor("#E5E7EB") else Color.parseColor("#111827")
        val timeColor = if (isNightMode) Color.WHITE else Color.parseColor("#111827")
        val countdownColor = if (state.isPostAzan) {
            if (isNightMode) Color.parseColor("#F87171") else Color.parseColor("#DC2626")
        } else {
            if (isNightMode) Color.parseColor("#34D399") else Color.parseColor("#15803D")
        }

        val remoteViews = RemoteViews(context.packageName, R.layout.notif_sticky_prayer).apply {
            setImageViewResource(R.id.notif_logo, R.drawable.ic_notif_app_logo)
            setTextViewText(R.id.notif_title, state.title)
            setTextColor(R.id.notif_title, titleColor)
            setTextViewText(R.id.notif_time, state.timeText)
            setTextColor(R.id.notif_time, timeColor)

            val remainingMs = (state.countdownTargetMs - System.currentTimeMillis()).coerceAtLeast(0L)
            val chronometerBase = SystemClock.elapsedRealtime() + remainingMs
            val chronoFormat = if (state.isPostAzan) "%s" else "-%s"
            setChronometer(R.id.notif_chronometer, chronometerBase, chronoFormat, true)
            setTextColor(R.id.notif_chronometer, countdownColor)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                setChronometerCountDown(R.id.notif_chronometer, true)
            }
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        val largeBitmap = try {
            BitmapFactory.decodeResource(context.resources, R.drawable.ic_notif_app_logo)
        } catch (_: Exception) {
            null
        }

        builder
            .setSmallIcon(R.drawable.ic_notif_logo)
            .setContentTitle(state.title)
            .setContentText(state.timeText)
            .setLargeIcon(largeBitmap)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSortKey("000000")
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setContentIntent(contentPi)
            .setDeleteIntent(deletePi)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            builder.setColor(
                if (state.isPostAzan) Color.parseColor("#B91C1C") else Color.parseColor("#064E3B")
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder
                .setCustomContentView(remoteViews)
                .setCustomBigContentView(remoteViews)
                .setStyle(Notification.DecoratedCustomViewStyle())
        } else {
            @Suppress("DEPRECATION")
            builder
                .setContent(remoteViews)
                .setPriority(Notification.PRIORITY_MAX)
        }

        val notif = builder.build()
        notif.flags = notif.flags or
            Notification.FLAG_ONGOING_EVENT or
            Notification.FLAG_NO_CLEAR or
            Notification.FLAG_FOREGROUND_SERVICE
        return notif
    }

    private fun transitionPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerTransitionReceiver::class.java)
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(
            context,
            TRANSITION_REQUEST_CODE,
            intent,
            piFlags
        )
    }

    fun scheduleTransitionAlarm(context: Context, targetMs: Long) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = (targetMs + 1000L).coerceAtLeast(System.currentTimeMillis() + 5000L)
        val pi = transitionPendingIntent(context)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        }
    }

    fun cancelTransitionAlarm(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(transitionPendingIntent(context))
    }

    fun startOrRefreshService(context: Context) {
        if (!isEnabled(context)) {
            stopService(context)
            return
        }
        val state = findActiveState(context) ?: return
        scheduleTransitionAlarm(context, state.countdownTargetMs)
        val serviceIntent = Intent(context, PrayerStickyService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {
            // Fallback for Android 12+ background FGS start restrictions: keep notification pinned
            postDirect(context, state)
        }
    }

    fun postDirect(context: Context, state: StickyPrayerDisplayState? = null) {
        if (!isEnabled(context)) return
        val target = state ?: findActiveState(context) ?: return
        scheduleTransitionAlarm(context, target.countdownTargetMs)
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(context, target))
    }

    fun stopService(context: Context) {
        setEnabled(context, false)
        cancelTransitionAlarm(context)
        try {
            context.stopService(Intent(context, PrayerStickyService::class.java))
        } catch (_: Exception) {
        }
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIF_ID)
    }
}
