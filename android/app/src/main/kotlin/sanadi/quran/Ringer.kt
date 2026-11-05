package sanadi.quran

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * The phone's own ringtone, on repeat, and a ring-like vibration while a call
 * rings. Follows the phone's settings: silent mode rings silently, vibrate
 * mode only vibrates.
 */
object Ringer {
    private var ringtone: Ringtone? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())

    // Before Android 9 a ringtone can't loop by itself: play it again when
    // it finishes.
    private val replay = object : Runnable {
        override fun run() {
            val r = ringtone ?: return
            if (!r.isPlaying) r.play()
            handler.postDelayed(this, 1000)
        }
    }

    fun start(context: Context) {
        stop()
        val app = context.applicationContext
        val audio = app.getSystemService(AudioManager::class.java)
        val mode = audio?.ringerMode ?: AudioManager.RINGER_MODE_NORMAL
        try {
            if (mode == AudioManager.RINGER_MODE_NORMAL) {
                val uri = RingtoneManager.getActualDefaultRingtoneUri(app, RingtoneManager.TYPE_RINGTONE)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                val r = RingtoneManager.getRingtone(app, uri)
                if (r != null) {
                    r.audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    if (Build.VERSION.SDK_INT >= 28) r.isLooping = true
                    r.play()
                    ringtone = r
                    if (Build.VERSION.SDK_INT < 28) handler.postDelayed(replay, 1000)
                }
            }
        } catch (e: Exception) {
            Log.w("Sanadi", "Ringtone not played", e)
        }
        try {
            if (mode != AudioManager.RINGER_MODE_SILENT) {
                val v = if (Build.VERSION.SDK_INT >= 31) {
                    app.getSystemService(VibratorManager::class.java)?.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    app.getSystemService(Vibrator::class.java)
                }
                if (v != null && v.hasVibrator()) {
                    // Ring, ring, pause, repeated.
                    val pattern = longArrayOf(0, 800, 400, 800, 1400)
                    if (Build.VERSION.SDK_INT >= 33) {
                        v.vibrate(
                            VibrationEffect.createWaveform(pattern, 0),
                            android.os.VibrationAttributes.createForUsage(android.os.VibrationAttributes.USAGE_RINGTONE),
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        v.vibrate(
                            VibrationEffect.createWaveform(pattern, 0),
                            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE).build(),
                        )
                    }
                    vibrator = v
                }
            }
        } catch (e: Exception) {
            Log.w("Sanadi", "Vibration not started", e)
        }
    }

    fun stop() {
        handler.removeCallbacks(replay)
        try {
            ringtone?.stop()
        } catch (_: Exception) {
        }
        ringtone = null
        try {
            vibrator?.cancel()
        } catch (_: Exception) {
        }
        vibrator = null
    }
}
