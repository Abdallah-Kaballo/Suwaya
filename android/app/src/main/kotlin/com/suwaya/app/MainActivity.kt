package com.suwaya.app

import android.app.KeyguardManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.suwaya.app/lockscreen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "showOnLockScreen" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                        setShowWhenLocked(true)
                        setTurnScreenOn(true)
                        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                        keyguardManager?.requestDismissKeyguard(this, null)
                    } else {
                        @Suppress("DEPRECATION")
                        window.addFlags(
                            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                        )
                    }
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                }

                "hideFromLockScreen" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                        setShowWhenLocked(false)
                        setTurnScreenOn(false)
                    } else {
                        @Suppress("DEPRECATION")
                        window.clearFlags(
                            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                        )
                    }
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                }

                "setAlarmVolumeControl" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    volumeControlStream = if (enabled) {
                        AudioManager.STREAM_ALARM
                    } else {
                        AudioManager.USE_DEFAULT_STREAM_TYPE
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}