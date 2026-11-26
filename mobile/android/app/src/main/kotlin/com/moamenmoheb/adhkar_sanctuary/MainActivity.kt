package com.moamenmoheb.adhkar_sanctuary

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moamenmoheb.adhkar_sanctuary/sticky_prayer"
    private var stickyChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        stickyChannel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "startOrUpdate" -> {
                    val scheduleJson = call.argument<String>("scheduleJson") ?: "[]"
                    PrayerStickyHelper.setEnabled(this, true)
                    PrayerStickyHelper.saveSchedule(this, scheduleJson)
                    PrayerStickyHelper.startOrRefreshService(this)
                    result.success(true)
                }
                "stop" -> {
                    PrayerStickyHelper.stopService(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getStringExtra("open_tab") == "prayers") {
            stickyChannel?.invokeMethod("openedFromSticky", null)
        }
    }
}
