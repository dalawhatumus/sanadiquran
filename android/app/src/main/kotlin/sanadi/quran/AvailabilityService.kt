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
 * While a teacher is "available to teach", keeps Sanadi running in the
 * background (with a small permanent notification) so a student's call can
 * still ring when the app is not on screen or the phone is locked. The
 * listening itself happens in the app; this service only keeps it alive.
 * Started and stopped from Dart through the "sanadi/availability" channel.
 */
class AvailabilityService : Service() {
    companion object {
        private const val CHANNEL = "availability"
        private const val ID = 7001
        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_CHANNEL_NAME = "channelName"

        fun start(context: Context, title: String, text: String, channelName: String): Boolean = try {
            val intent = Intent(context, AvailabilityService::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text)
                .putExtra(EXTRA_CHANNEL_NAME, channelName)
            context.startForegroundService(intent)
            true
        } catch (e: Exception) {
            // E.g. not allowed from the background on newer Android.
            Log.w("Sanadi", "Availability service not started", e)
            false
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, AvailabilityService::class.java))
            } catch (e: Exception) {
                Log.w("Sanadi", "Availability service not stopped", e)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Sanadi"
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""
        val channelName = intent?.getStringExtra(EXTRA_CHANNEL_NAME) ?: "Sanadi"
        val manager = getSystemService(NotificationManager::class.java)
        // Quiet: it only shows that Sanadi is ready to ring.
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, channelName, NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
            }
        )
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
        try {
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(ID, notification)
            }
        } catch (e: Exception) {
            Log.w("Sanadi", "Could not stay in the foreground", e)
            stopSelf()
        }
        // If Android stops it, don't restart without the app.
        return START_NOT_STICKY
    }
}
