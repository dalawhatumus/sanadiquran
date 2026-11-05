package sanadi.quran

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * During a lesson call only: a foreground service of the "microphone" type,
 * so the other person still hears this phone when the screen goes off or
 * Sanadi goes to the background (Android cuts the microphone off for apps
 * in the background otherwise). Started from the call screen, while Sanadi
 * is on screen, and stopped as soon as the call ends. Shows a "Lesson call
 * in progress" notification that leads back to the call.
 */
class CallService : Service() {
    companion object {
        private const val CHANNEL = "call_in_progress"
        private const val ID = 7002

        fun start(context: Context, title: String, text: String, channelName: String): Boolean = try {
            val intent = Intent(context, CallService::class.java)
                .putExtra("title", title)
                .putExtra("text", text)
                .putExtra("channelName", channelName)
            context.startForegroundService(intent)
            true
        } catch (e: Exception) {
            Log.w("Sanadi", "Call service not started", e)
            false
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, CallService::class.java))
            } catch (e: Exception) {
                Log.w("Sanadi", "Call service not stopped", e)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra("title") ?: "Sanadi"
        val text = intent?.getStringExtra("text") ?: ""
        val channelName = intent?.getStringExtra("channelName") ?: "Sanadi"
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, channelName, NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
            }
        )
        val open = PendingIntent.getActivity(
            this,
            1,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_sanadi)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_CALL)
            .build()
        try {
            if (Build.VERSION.SDK_INT >= 30) {
                startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
            } else {
                startForeground(ID, notification)
            }
        } catch (e: Exception) {
            // E.g. the microphone permission was taken away mid-call.
            Log.w("Sanadi", "Call service could not stay in the foreground", e)
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Sanadi swiped away mid-call: the call is over.
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }
}
