
package com.suwaya.app

import android.media.AudioManager
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
                    window.addFlags(
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    )
                    result.success(null)
                }

                "hideFromLockScreen" -> {
                    window.clearFlags(
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    )
                    result.success(null)
                }

                "setAlarmVolumeControl" -> {
                    val enabled =
                        call.argument<Boolean>("enabled") ?: false

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
