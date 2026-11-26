package com.moamenmoheb.adhkar_sanctuary

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PrayerDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (!PrayerStickyHelper.isEnabled(context)) return
        // Immediately restore the sticky notification if the user swipes it away on Android 14+
        PrayerStickyHelper.postDirect(context)
        PrayerStickyHelper.startOrRefreshService(context)
    }
}
