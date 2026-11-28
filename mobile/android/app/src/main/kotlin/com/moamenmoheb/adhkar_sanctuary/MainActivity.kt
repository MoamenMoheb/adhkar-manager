package com.moamenmoheb.adhkar_sanctuary

import android.Manifest
import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.GeomagneticField
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moamenmoheb.adhkar_sanctuary/sticky_prayer"
    private val compassChannelName = "com.moamenmoheb.adhkar_sanctuary/qibla_compass"
    private val locationChannelName = "com.moamenmoheb.adhkar_sanctuary/qibla_location"
    private val azanOverlayChannelName = "com.moamenmoheb.adhkar_sanctuary/azan_overlay"
    private val azanPlayerChannelName = "com.moamenmoheb.adhkar_sanctuary/azan_player"
    private val appPermissionsChannelName = "com.moamenmoheb.adhkar_sanctuary/app_permissions"
    private val locationPermCode = 9012
    private val notifPermCode = 9013

    private var stickyChannel: MethodChannel? = null
    private var azanPlayerChannel: MethodChannel? = null
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingLaunchTab: String? = null
    private var previewPlayer: MediaPlayer? = null
    private var previewPlayingKey: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingLaunchTab = intent?.getStringExtra("open_tab")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val ch = MethodChannel(messenger, channelName)
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
                "consumePendingLaunchTab" -> {
                    val tab = pendingLaunchTab
                    pendingLaunchTab = null
                    result.success(tab)
                }
                "getSupportedAbis" -> {
                    result.success(Build.SUPPORTED_ABIS.toList())
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, azanOverlayChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "canDrawOverlays" -> result.success(AzanOverlayHelper.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.fromParts("package", packageName, null)
                            )
                            startActivity(intent)
                        } catch (_: Exception) {
                        }
                    }
                    result.success(true)
                }
                "saveAndSchedule" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val vibrate = call.argument<Boolean>("vibrate") ?: false
                    val wallpaperKey = call.argument<String>("wallpaperKey") ?: "wall_makkah"
                    val soundKey = call.argument<String>("soundKey") ?: "azan"
                    val cityName = call.argument<String>("cityName") ?: ""
                    val scheduleJson = call.argument<String>("scheduleJson") ?: "[]"
                    AzanOverlayHelper.saveConfigAndSchedule(
                        this,
                        enabled,
                        vibrate,
                        wallpaperKey,
                        soundKey,
                        cityName,
                        scheduleJson
                    )
                    result.success(true)
                }
                "previewOverlay" -> {
                    stopPreviewAudio()
                    val prayerName = call.argument<String>("prayerName") ?: "صلاة الفجر"
                    val prayerTime = call.argument<String>("prayerTime") ?: ""
                    val cityName = call.argument<String>("cityName") ?: ""
                    val wallpaperKey = call.argument<String>("wallpaperKey") ?: "wall_makkah"
                    val soundKey = call.argument<String>("soundKey") ?: "azan"
                    val vibrate = call.argument<Boolean>("vibrate") ?: false
                    startActivity(
                        AzanOverlayActivity.buildLaunchIntent(
                            context = this,
                            prayerName = prayerName,
                            prayerTime = prayerTime,
                            cityName = cityName,
                            wallpaperKey = wallpaperKey,
                            soundKey = soundKey,
                            vibrate = vibrate,
                            isPreview = true
                        )
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        val playerCh = MethodChannel(messenger, azanPlayerChannelName)
        azanPlayerChannel = playerCh
        playerCh.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val key = call.argument<String>("soundKey") ?: "azan"
                    if (previewPlayer != null && previewPlayingKey == key) {
                        stopPreviewAudio()
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    stopPreviewAudio()
                    if (key == "silent") {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val mp = MediaPlayer()
                        mp.setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_MEDIA)
                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                .build()
                        )
                        if (key == "default") {
                            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                            if (uri == null) {
                                mp.release()
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            mp.setDataSource(this, uri)
                        } else {
                            val resId = resources.getIdentifier(key, "raw", packageName)
                                .takeIf { it != 0 } ?: R.raw.azan
                            val afd = resources.openRawResourceFd(resId)
                            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                            afd.close()
                        }
                        mp.setOnCompletionListener { finished ->
                            finished.release()
                            if (previewPlayer === finished) {
                                previewPlayer = null
                                previewPlayingKey = null
                            }
                            azanPlayerChannel?.invokeMethod("onCompleted", null)
                        }
                        mp.prepare()
                        mp.start()
                        previewPlayer = mp
                        previewPlayingKey = key
                        result.success(true)
                    } catch (_: Exception) {
                        stopPreviewAudio()
                        result.success(false)
                    }
                }
                "stop" -> {
                    stopPreviewAudio()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, compassChannelName)
            .setStreamHandler(QiblaSensorStreamHandler(applicationContext))

        MethodChannel(messenger, locationChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasLocationPermission" -> result.success(hasLocationPermission())
                "openAppSettings" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null)
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "getDeclination" -> {
                    val lat = (call.argument<Number>("lat") ?: 0.0).toFloat()
                    val lng = (call.argument<Number>("lng") ?: 0.0).toFloat()
                    val field = GeomagneticField(lat, lng, 0f, System.currentTimeMillis())
                    result.success(field.declination.toDouble())
                }
                "getCurrentLocation" -> handleGetCurrentLocation(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, appPermissionsChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPermissionsStatus" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val notifPostOk = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    val notifOk = notifPostOk && nm.areNotificationsEnabled()
                    val locOk = hasLocationPermission()
                    val overlayOk = AzanOverlayHelper.canDrawOverlays(this)
                    val exactOk = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        (getSystemService(Context.ALARM_SERVICE) as AlarmManager).canScheduleExactAlarms()
                    } else {
                        true
                    }
                    result.success(
                        mapOf(
                            "notifications" to notifOk,
                            "location" to locOk,
                            "overlay" to overlayOk,
                            "exactAlarms" to exactOk
                        )
                    )
                }
                "requestNotifications" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                    ) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), notifPermCode)
                        result.success(true)
                    } else {
                        openNotificationSettingsIntent()
                        result.success(true)
                    }
                }
                "openNotificationSettings" -> {
                    openNotificationSettingsIntent()
                    result.success(true)
                }
                "requestLocation" -> {
                    if (!hasLocationPermission() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        requestPermissions(
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            locationPermCode
                        )
                        result.success(true)
                    } else {
                        openAppDetailsIntent()
                        result.success(true)
                    }
                }
                "openAppDetails" -> {
                    openAppDetailsIntent()
                    result.success(true)
                }
                "openOverlaySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.fromParts("package", packageName, null)
                                )
                            )
                        } catch (_: Exception) {
                            openAppDetailsIntent()
                        }
                    }
                    result.success(true)
                }
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            startActivity(
                                Intent(
                                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                    Uri.fromParts("package", packageName, null)
                                )
                            )
                        } catch (_: Exception) {
                            openAppDetailsIntent()
                        }
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openNotificationSettingsIntent() {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
            } else {
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", packageName, null)
                )
            }
            startActivity(intent)
        } catch (_: Exception) {
            openAppDetailsIntent()
        }
    }

    private fun openAppDetailsIntent() {
        try {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", packageName, null)
                )
            )
        } catch (_: Exception) {
        }
    }

    private fun stopPreviewAudio() {
        try {
            previewPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (_: Exception) {
        }
        previewPlayer = null
        previewPlayingKey = null
    }

    private fun hasLocationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun handleGetCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                pendingLocationResult?.error("CANCELLED", "New location request started", null)
                pendingLocationResult = result
                requestPermissions(
                    arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    ),
                    locationPermCode
                )
            } else {
                result.success(null)
            }
            return
        }
        resolveDeviceLocation(result)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == locationPermCode) {
            val pending = pendingLocationResult
            pendingLocationResult = null
            if (pending != null) {
                if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                    resolveDeviceLocation(pending)
                } else {
                    pending.success(null)
                }
            }
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    @SuppressLint("MissingPermission")
    private fun resolveDeviceLocation(result: MethodChannel.Result) {
        val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER
        )
        var bestLast: Location? = null
        for (p in providers) {
            try {
                if (!lm.isProviderEnabled(p)) continue
                val loc = lm.getLastKnownLocation(p) ?: continue
                if (bestLast == null || loc.time > bestLast.time) {
                    bestLast = loc
                }
            } catch (_: Exception) {
            }
        }

        val freshCutoffMs = System.currentTimeMillis() - 5 * 60 * 1000L
        if (bestLast != null && bestLast.time >= freshCutoffMs) {
            result.success(mapOf("lat" to bestLast.latitude, "lng" to bestLast.longitude))
            return
        }

        val activeProvider = when {
            runCatching { lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) }.getOrDefault(false) ->
                LocationManager.NETWORK_PROVIDER
            runCatching { lm.isProviderEnabled(LocationManager.GPS_PROVIDER) }.getOrDefault(false) ->
                LocationManager.GPS_PROVIDER
            else -> null
        }

        if (activeProvider == null) {
            result.success(bestLast?.let { mapOf("lat" to it.latitude, "lng" to it.longitude) })
            return
        }

        val handler = Handler(Looper.getMainLooper())
        var resolved = false
        lateinit var listener: LocationListener

        val timeoutRunnable = Runnable {
            if (!resolved) {
                resolved = true
                try {
                    lm.removeUpdates(listener)
                } catch (_: Exception) {
                }
                result.success(bestLast?.let { mapOf("lat" to it.latitude, "lng" to it.longitude) })
            }
        }

        listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                if (!resolved) {
                    resolved = true
                    handler.removeCallbacks(timeoutRunnable)
                    try {
                        lm.removeUpdates(this)
                    } catch (_: Exception) {
                    }
                    result.success(mapOf("lat" to location.latitude, "lng" to location.longitude))
                }
            }

            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
            override fun onProviderEnabled(provider: String) {}
            override fun onProviderDisabled(provider: String) {}
        }

        try {
            lm.requestLocationUpdates(activeProvider, 0L, 0f, listener, Looper.getMainLooper())
            handler.postDelayed(timeoutRunnable, 6000L)
        } catch (_: Exception) {
            result.success(bestLast?.let { mapOf("lat" to it.latitude, "lng" to it.longitude) })
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val tab = intent.getStringExtra("open_tab")
        if (tab == "prayers") {
            stickyChannel?.invokeMethod("openedFromSticky", null)
        } else if (!tab.isNullOrBlank()) {
            pendingLaunchTab = tab
            stickyChannel?.invokeMethod("openTab", tab)
        }
    }

    override fun onDestroy() {
        stopPreviewAudio()
        super.onDestroy()
    }
}
