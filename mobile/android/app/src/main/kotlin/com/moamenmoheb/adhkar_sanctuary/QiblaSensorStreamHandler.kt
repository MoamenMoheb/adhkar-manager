package com.moamenmoheb.adhkar_sanctuary

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

class QiblaSensorStreamHandler(context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var eventSink: EventChannel.EventSink? = null

    private val rotationSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val accelSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    private val accelReading = FloatArray(3)
    private val magReading = FloatArray(3)
    private var hasAccel = false
    private var hasMag = false

    private val rotationMatrix = FloatArray(9)
    private val orientation = FloatArray(3)

    private var hasFiltered = false
    private var filteredSin = 0.0
    private var filteredCos = 0.0
    private var currentAccuracy = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
    private var lastEmitMs = 0L

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        hasFiltered = false
        hasAccel = false
        hasMag = false
        lastEmitMs = 0L

        if (rotationSensor != null) {
            sensorManager.registerListener(this, rotationSensor, SensorManager.SENSOR_DELAY_GAME)
            if (magSensor != null) {
                sensorManager.registerListener(this, magSensor, SensorManager.SENSOR_DELAY_UI)
            }
        } else if (accelSensor != null && magSensor != null) {
            sensorManager.registerListener(this, accelSensor, SensorManager.SENSOR_DELAY_GAME)
            sensorManager.registerListener(this, magSensor, SensorManager.SENSOR_DELAY_GAME)
        } else {
            events?.success(
                mapOf(
                    "hasSensor" to false,
                    "heading" to 0.0,
                    "accuracy" to -1
                )
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        eventSink = null
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD || sensor?.type == Sensor.TYPE_ROTATION_VECTOR) {
            currentAccuracy = accuracy
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        val sink = eventSink ?: return
        var updatedAzimuth: Double? = null

        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                SensorManager.getOrientation(rotationMatrix, orientation)
                updatedAzimuth = Math.toDegrees(orientation[0].toDouble())
            }
            Sensor.TYPE_ACCELEROMETER -> {
                System.arraycopy(event.values, 0, accelReading, 0, 3)
                hasAccel = true
                if (rotationSensor == null && hasMag) {
                    if (SensorManager.getRotationMatrix(rotationMatrix, null, accelReading, magReading)) {
                        SensorManager.getOrientation(rotationMatrix, orientation)
                        updatedAzimuth = Math.toDegrees(orientation[0].toDouble())
                    }
                }
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                System.arraycopy(event.values, 0, magReading, 0, 3)
                hasMag = true
                if (rotationSensor == null && hasAccel) {
                    if (SensorManager.getRotationMatrix(rotationMatrix, null, accelReading, magReading)) {
                        SensorManager.getOrientation(rotationMatrix, orientation)
                        updatedAzimuth = Math.toDegrees(orientation[0].toDouble())
                    }
                }
            }
        }

        val rawDeg = updatedAzimuth ?: return
        val rad = Math.toRadians(rawDeg)
        val s = sin(rad)
        val c = cos(rad)

        if (!hasFiltered) {
            filteredSin = s
            filteredCos = c
            hasFiltered = true
        } else {
            val alpha = 0.18
            filteredSin += alpha * (s - filteredSin)
            filteredCos += alpha * (c - filteredCos)
        }

        val now = System.currentTimeMillis()
        if (now - lastEmitMs < 33L) return
        lastEmitMs = now

        var smoothedDeg = Math.toDegrees(atan2(filteredSin, filteredCos))
        if (smoothedDeg < 0.0) smoothedDeg += 360.0

        sink.success(
            mapOf(
                "hasSensor" to true,
                "heading" to smoothedDeg,
                "accuracy" to currentAccuracy
            )
        )
    }
}
