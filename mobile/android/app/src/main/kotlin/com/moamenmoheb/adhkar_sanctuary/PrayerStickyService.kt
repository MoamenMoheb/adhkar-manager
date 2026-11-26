package com.moamenmoheb.adhkar_sanctuary

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class PrayerStickyService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var refreshRunnable: Runnable? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!PrayerStickyHelper.isEnabled(this)) {
            stopCleanly()
            return START_NOT_STICKY
        }

        val item = PrayerStickyHelper.findNextPrayer(this)
        if (item == null) {
            stopCleanly()
            return START_NOT_STICKY
        }

        val notif = PrayerStickyHelper.buildNotification(this, item)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                PrayerStickyHelper.NOTIF_ID,
                notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(PrayerStickyHelper.NOTIF_ID, notif)
        }

        scheduleNextTransition(item.timeMs)
        return START_STICKY
    }

    private fun scheduleNextTransition(nextPrayerTimeMs: Long) {
        refreshRunnable?.let { handler.removeCallbacks(it) }
        val delayMs = (nextPrayerTimeMs - System.currentTimeMillis() + 1500L).coerceAtLeast(5000L)
        val runnable = Runnable {
            if (PrayerStickyHelper.isEnabled(this)) {
                PrayerStickyHelper.startOrRefreshService(this)
            }
        }
        refreshRunnable = runnable
        handler.postDelayed(runnable, delayMs)
    }

    private fun stopCleanly() {
        refreshRunnable?.let { handler.removeCallbacks(it) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (PrayerStickyHelper.isEnabled(this)) {
            PrayerStickyHelper.postDirect(this)
        }
    }

    override fun onDestroy() {
        refreshRunnable?.let { handler.removeCallbacks(it) }
        super.onDestroy()
    }
}
