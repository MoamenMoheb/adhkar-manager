package com.moamenmoheb.adhkar_sanctuary

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.GeomagneticField
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moamenmoheb.adhkar_sanctuary/sticky_prayer"
    private val compassChannelName = "com.moamenmoheb.adhkar_sanctuary/qibla_compass"
    private val locationChannelName = "com.moamenmoheb.adhkar_sanctuary/qibla_location"
    private val locationPermCode = 9012

    private var stickyChannel: MethodChannel? = null
    private var pendingLocationResult: MethodChannel.Result? = null

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
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, compassChannelName)
            .setStreamHandler(QiblaSensorStreamHandler(applicationContext))

        MethodChannel(messenger, locationChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
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
        if (intent.getStringExtra("open_tab") == "prayers") {
            stickyChannel?.invokeMethod("openedFromSticky", null)
        }
    }
}
