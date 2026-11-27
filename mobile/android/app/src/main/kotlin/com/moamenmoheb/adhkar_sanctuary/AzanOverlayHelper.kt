package com.moamenmoheb.adhkar_sanctuary

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import org.json.JSONArray

object AzanOverlayHelper {
    private const val PREFS_NAME = "adhkar_azan_overlay"
    private const val KEY_ENABLED = "overlay_enabled"
    private const val KEY_VIBRATE = "overlay_vibrate"
    private const val KEY_WALLPAPER = "wallpaper_key"
    private const val KEY_SOUND = "sound_key"
    private const val KEY_CITY = "city_name"
    private const val KEY_SCHEDULE = "overlay_schedule_json"
    private const val ALARM_REQUEST_CODE = 9201
    const val FULLSCREEN_NOTIF_ID = 8899
    const val FULLSCREEN_CHANNEL_ID = "adhkar_azan_overlay_fs_v1"

    fun canDrawOverlays(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)
    }

    fun isEnabled(context: Context): Boolean {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_ENABLED, false)
    }

    fun isVibrate(context: Context): Boolean {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_VIBRATE, false)
    }

    fun getWallpaperKey(context: Context): String {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_WALLPAPER, "wall_makkah") ?: "wall_makkah"
    }

    fun getSoundKey(context: Context): String {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_SOUND, "azan") ?: "azan"
    }

    fun getCityName(context: Context): String {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_CITY, "") ?: ""
    }

    fun saveConfigAndSchedule(
        context: Context,
        enabled: Boolean,
        vibrate: Boolean,
        wallpaperKey: String,
        soundKey: String,
        cityName: String,
        scheduleJson: String
    ) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putBoolean(KEY_VIBRATE, vibrate)
            .putString(KEY_WALLPAPER, wallpaperKey)
            .putString(KEY_SOUND, soundKey)
            .putString(KEY_CITY, cityName)
            .putString(KEY_SCHEDULE, scheduleJson)
            .apply()

        if (enabled) {
            scheduleNextAlarm(context)
        } else {
            cancelAlarm(context)
        }
    }

    fun cancelAlarm(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(buildAlarmPendingIntent(context, "", "", 0L))
    }

    private fun buildAlarmPendingIntent(
        context: Context,
        title: String,
        timeText: String,
        prayerTimeMs: Long
    ): PendingIntent {
        val intent = Intent(context, AzanOverlayAlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("timeText", timeText)
            putExtra("prayerTimeMs", prayerTimeMs)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, ALARM_REQUEST_CODE, intent, flags)
    }

    fun scheduleNextAlarm(context: Context) {
        if (!isEnabled(context)) {
            cancelAlarm(context)
            return
        }
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_SCHEDULE, null) ?: return
        val now = System.currentTimeMillis()

        var bestTitle: String? = null
        var bestTimeText = ""
        var bestMs = Long.MAX_VALUE

        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val timeMs = obj.getLong("timeMs")
                if (timeMs > now + 2000L && timeMs < bestMs) {
                    bestMs = timeMs
                    bestTitle = obj.optString("title", "حان الآن موعد الصلاة")
                    bestTimeText = obj.optString("body", "")
                }
            }
        } catch (_: Exception) {
            return
        }

        val targetTitle = bestTitle ?: return
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = buildAlarmPendingIntent(context, targetTitle, bestTimeText, bestMs)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, bestMs, pi)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, bestMs, pi)
                }
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, bestMs, pi)
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, bestMs, pi)
            }
        }
    }
}
