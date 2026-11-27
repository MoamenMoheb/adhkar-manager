package com.moamenmoheb.adhkar_sanctuary

import android.app.Activity
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.TextView

class AzanOverlayActivity : Activity() {
    companion object {
        fun buildLaunchIntent(
            context: Context,
            prayerName: String,
            prayerTime: String,
            cityName: String,
            wallpaperKey: String,
            soundKey: String,
            vibrate: Boolean,
            isPreview: Boolean
        ): Intent {
            return Intent(context, AzanOverlayActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtra("prayerName", prayerName)
                putExtra("prayerTime", prayerTime)
                putExtra("cityName", cityName)
                putExtra("wallpaperKey", wallpaperKey)
                putExtra("soundKey", soundKey)
                putExtra("vibrate", vibrate)
                putExtra("isPreview", isPreview)
            }
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var isMuted = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_azan_overlay)
        bindAndPlay(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        if (intent != null) {
            setIntent(intent)
            stopAudioAndVibration()
            bindAndPlay(intent)
        }
    }

    private fun bindAndPlay(intent: Intent) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(AzanOverlayHelper.FULLSCREEN_NOTIF_ID)

        val prayerName = intent.getStringExtra("prayerName") ?: "صلاة الفجر"
        val prayerTime = intent.getStringExtra("prayerTime") ?: ""
        val cityName = intent.getStringExtra("cityName") ?: ""
        val wallpaperKey = intent.getStringExtra("wallpaperKey") ?: "wall_makkah"
        val soundKey = intent.getStringExtra("soundKey") ?: "azan"
        val vibrate = intent.getBooleanExtra("vibrate", false)
        val isPreview = intent.getBooleanExtra("isPreview", false)

        val wallView = findViewById<ImageView>(R.id.azan_wall_image)
        val wallRes = resources.getIdentifier(wallpaperKey, "drawable", packageName)
            .takeIf { it != 0 } ?: R.drawable.wall_makkah
        wallView.setImageResource(wallRes)

        findViewById<TextView>(R.id.azan_badge_text).text =
            if (isPreview) "معاينة شاشة الأذان" else "حان الآن موعد الأذان"
        findViewById<TextView>(R.id.azan_prayer_name).text = prayerName

        val timeView = findViewById<TextView>(R.id.azan_prayer_time)
        timeView.text = prayerTime
        timeView.visibility = if (prayerTime.isNotBlank()) View.VISIBLE else View.GONE

        val cityView = findViewById<TextView>(R.id.azan_city_label)
        cityView.text = cityName
        cityView.visibility = if (cityName.isNotBlank()) View.VISIBLE else View.GONE

        val btnSilent = findViewById<ImageButton>(R.id.azan_btn_silent)
        val lblSilent = findViewById<TextView>(R.id.azan_lbl_silent)
        isMuted = soundKey == "silent"
        btnSilent.alpha = if (isMuted) 0.55f else 1.0f
        lblSilent.text = if (isMuted) "صامت" else "كتم الصوت"

        btnSilent.setOnClickListener {
            stopAudioAndVibration()
            isMuted = true
            btnSilent.alpha = 0.55f
            lblSilent.text = "تم الكتم"
        }

        findViewById<ImageButton>(R.id.azan_btn_qibla).setOnClickListener {
            stopAudioAndVibration()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                if (km.isKeyguardLocked) {
                    km.requestDismissKeyguard(this, null)
                }
            }
            val qiblaIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                putExtra("open_tab", "qibla")
            }
            startActivity(qiblaIntent)
            finish()
        }

        findViewById<ImageButton>(R.id.azan_btn_cancel).setOnClickListener {
            stopAudioAndVibration()
            finish()
        }

        if (soundKey != "silent") {
            startAzanSound(soundKey)
        }
        if (vibrate && !isMuted) {
            startGentleVibration()
        }
    }

    private fun startAzanSound(soundKey: String) {
        try {
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )

            if (soundKey == "default") {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                if (uri == null) {
                    player.release()
                    return
                }
                player.setDataSource(this, uri)
            } else {
                val resId = resources.getIdentifier(soundKey, "raw", packageName)
                    .takeIf { it != 0 } ?: R.raw.azan
                val afd = resources.openRawResourceFd(resId)
                player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
            }

            player.setOnCompletionListener { mp ->
                mp.release()
                if (mediaPlayer === mp) mediaPlayer = null
                stopVibration()
            }
            player.prepare()
            player.start()
            mediaPlayer = player
        } catch (_: Exception) {
        }
    }

    private fun startGentleVibration() {
        try {
            val vib = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            vibrator = vib
            val pattern = longArrayOf(0L, 500L, 1200L)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vib.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vib.vibrate(pattern, 0)
            }
        } catch (_: Exception) {
        }
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
        } catch (_: Exception) {
        }
        vibrator = null
    }

    private fun stopAudioAndVibration() {
        stopVibration()
        try {
            mediaPlayer?.let { mp ->
                if (mp.isPlaying) mp.stop()
                mp.release()
            }
        } catch (_: Exception) {
        }
        mediaPlayer = null
    }

    override fun onDestroy() {
        stopAudioAndVibration()
        super.onDestroy()
    }
}
