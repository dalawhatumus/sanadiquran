package sanadi.quran

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "sanadi/screen").setMethodCallHandler { call, result ->
            when (call.method) {
                // Keeps the screen on during a lesson call, so it doesn't go
                // dark while the student recites.
                "keepOn" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                // Shows Sanadi over the lock screen (and wakes the screen)
                // only while a call is ringing or in progress; switched off
                // again straight after, so the app is never open on a locked
                // phone otherwise.
                "overLockScreen" -> {
                    val on = call.arguments == true
                    if (Build.VERSION.SDK_INT >= 27) {
                        setShowWhenLocked(on)
                        setTurnScreenOn(on)
                    } else {
                        @Suppress("DEPRECATION")
                        val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                        if (on) window.addFlags(flags) else window.clearFlags(flags)
                    }
                    result.success(null)
                }
                // Back on the home screen while available: keep running in
                // the background (like Home) instead of closing.
                "moveToBack" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                // Opens the phone's "Add a Google account" screen, for
                // someone with no Google account on the phone yet.
                "addGoogleAccount" -> {
                    val intent = Intent(Settings.ACTION_ADD_ACCOUNT)
                        .putExtra(Settings.EXTRA_ACCOUNT_TYPES, arrayOf("com.google"))
                    result.success(
                        try {
                            startActivity(intent)
                            true
                        } catch (e: Exception) {
                            false
                        }
                    )
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "sanadi/call").setMethodCallHandler { call, result ->
            when (call.method) {
                // A lesson call connected / ended: keeps the microphone
                // working with the screen off (see CallService).
                "start" -> {
                    val args = call.arguments as? Map<*, *>
                    result.success(
                        CallService.start(
                            this,
                            args?.get("title") as? String ?: "Sanadi",
                            args?.get("text") as? String ?: "",
                            args?.get("channelName") as? String ?: "Sanadi",
                        )
                    )
                }
                "stop" -> {
                    CallService.stop(this)
                    result.success(null)
                }
                "ring" -> {
                    Ringer.start(this)
                    result.success(null)
                }
                "stopRing" -> {
                    Ringer.stop()
                    result.success(null)
                }
                // Android 14+ lets people (and Google Play) switch off
                // full-screen call alerts for an app.
                "canFullScreen" -> {
                    result.success(
                        if (Build.VERSION.SDK_INT >= 34) {
                            getSystemService(NotificationManager::class.java).canUseFullScreenIntent()
                        } else {
                            true
                        }
                    )
                }
                "openFullScreenSettings" -> {
                    val intent = if (Build.VERSION.SDK_INT >= 34) {
                        Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, Uri.parse("package:$packageName"))
                    } else {
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    }
                    try {
                        startActivity(intent)
                    } catch (e: Exception) {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
                            )
                        } catch (_: Exception) {
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "sanadi/availability").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val args = call.arguments as? Map<*, *>
                    result.success(
                        AvailabilityService.start(
                            this,
                            args?.get("title") as? String ?: "Sanadi",
                            args?.get("text") as? String ?: "",
                            args?.get("channelName") as? String ?: "Sanadi",
                        )
                    )
                }
                "stop" -> {
                    AvailabilityService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        // Closed for good (e.g. swiped away): nothing is listening any more,
        // so don't keep showing "available", and no call goes on.
        if (isFinishing) {
            AvailabilityService.stop(this)
            CallService.stop(this)
            Ringer.stop()
        }
        super.onDestroy()
    }
}
