package com.suwaya.app

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.suwaya.app/lockscreen"
    private var methodChannel: MethodChannel? = null
    private var isAlarmCurrentlyRinging = false

    private fun applyLockScreenFlags(enable: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(enable)
            setTurnScreenOn(enable)
        } else {
            @Suppress("DEPRECATION")
            if (enable) {
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                )
            } else {
                window.clearFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                )
            }
        }
        if (enable) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDeviceLocked" -> {
                        val keyguardManager =
                            getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                        val powerManager =
                            getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isKeyguardLocked = keyguardManager?.isKeyguardLocked ?: false
                        val isInteractive = powerManager?.isInteractive ?: true
                        result.success(isKeyguardLocked || !isInteractive)
                    }

                    "setAlarmRingingState" -> {
                        val ringing = call.argument<Boolean>("ringing") ?: false
                        isAlarmCurrentlyRinging = ringing
                        applyLockScreenFlags(ringing)
                        result.success(null)
                    }

                    "showOnLockScreen" -> {
                        isAlarmCurrentlyRinging = true
                        applyLockScreenFlags(true)
                        result.success(null)
                    }

                    "hideFromLockScreen" -> {
                        isAlarmCurrentlyRinging = false
                        applyLockScreenFlags(false)
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

                    "shareApp" -> {
                        val text = call.argument<String>("text")
                            ?: "https://play.google.com/store/apps/details?id=com.suwaya.app"
                        val title = call.argument<String>("title") ?: "Suwaya"
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_SUBJECT, title)
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        val shareIntent = Intent.createChooser(sendIntent, title)
                        startActivity(shareIntent)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isAlarmCurrentlyRinging &&
            (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP)
        ) {
            methodChannel?.invokeMethod("onHardwareVolumeAction", null)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}