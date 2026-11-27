package com.moamenmoheb.adhkar_sanctuary

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PrayerTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (!PrayerStickyHelper.isEnabled(context)) {
            PrayerStickyHelper.stopService(context)
            return
        }
        PrayerStickyHelper.postDirect(context)
        PrayerStickyHelper.startOrRefreshService(context)
    }
}
