package dev.cureando.cureando_mobile

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "dev.cureando.app/screen_security").setMethodCallHandler { call, result ->
            runOnUiThread {
                when (call.method) {
                    "setSecureScreen" -> {
                        val enabled = call.arguments as? Boolean
                        if (enabled == null) {
                            result.error("invalid_argument", "Se requiere un booleano", null)
                        } else if (!enabled && !isDebuggable) {
                            result.error("debug_only", "Capturas disponibles en compilaciones de depuración", null)
                        } else {
                            if (enabled) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            result.success(null)
                        }
                    }
                    "isSecureScreenEnabled" -> result.success(
                        (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0)
                    else -> result.notImplemented()
                }
            }
        }
    }
}
