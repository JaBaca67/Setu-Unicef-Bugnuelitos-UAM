package dev.cureando.cureando_mobile

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var nearbyMeshChannel: NearbyMeshChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Capturas permitidas en general; los chats activan FLAG_SECURE (ADR 0024).
        super.onCreate(savedInstanceState)
        SetuNotifications.ensureChannel(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "dev.cureando.app/screen_security").setMethodCallHandler { call, result ->
            runOnUiThread {
                when (call.method) {
                    "setSecureScreen" -> {
                        val enabled = call.arguments as? Boolean
                        if (enabled == null) {
                            result.error("invalid_argument", "Se requiere un booleano", null)
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
        SetuNotifications.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        // Abre el marcador con el número escrito (sin permiso de llamada): la
        // persona confirma la llamada. Solo dígitos, para contactos verificados.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "dev.cureando.app/dialer").setMethodCallHandler { call, result ->
            val number = call.argument<String>("number") ?: ""
            if (call.method != "dial") {
                result.notImplemented()
            } else if (!Regex("^\\+?[0-9]{3,15}$").matches(number)) {
                result.error("invalid_number", "Número no válido", null)
            } else {
                try {
                    startActivity(android.content.Intent(android.content.Intent.ACTION_DIAL,
                        android.net.Uri.parse("tel:$number")))
                    result.success(null)
                } catch (error: android.content.ActivityNotFoundException) {
                    result.error("no_dialer", "No hay marcador disponible", null)
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "dev.cureando.app/links").setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
            } else {
                val url = call.argument<String>("url") ?: ""
                val uri = android.net.Uri.parse(url)
                val host = uri.host?.lowercase(java.util.Locale.ROOT) ?: ""
                val allowed = host == "unicef.org" || host.endsWith(".unicef.org") ||
                    host in setOf("mined.gob.ni", "www.mined.gob.ni", "youtube.com", "www.youtube.com", "m.youtube.com",
                        "youtu.be", "facebook.com", "www.facebook.com")
                if (uri.scheme != "https" || !allowed || uri.userInfo != null ||
                    (uri.port != -1 && uri.port != 443) || url.any { it.isWhitespace() || it == '\\' }) {
                    result.error("invalid_url", "Enlace no permitido", null)
                } else {
                    try {
                        startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, uri))
                        result.success(null)
                    } catch (error: android.content.ActivityNotFoundException) {
                        result.error("no_browser", "No hay aplicación para abrir el enlace", null)
                    } catch (error: SecurityException) {
                        result.error("link_denied", "No se pudo abrir el enlace", null)
                    }
                }
            }
        }
        // Guarda en la galería el dibujo que el estudiante decide guardar.
        // MediaStore (Android 10+) no requiere permisos de almacenamiento.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "dev.cureando.app/gallery").setMethodCallHandler { call, result ->
            if (call.method != "savePng") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            val name = (call.argument<String>("name") ?: "setu-dibujo")
                .replace(Regex("[^A-Za-z0-9_-]"), "")
                .ifEmpty { "setu-dibujo" }
            if (bytes == null || bytes.isEmpty() || bytes.size > 20_000_000) {
                result.error("invalid_image", "Imagen no válida", null)
                return@setMethodCallHandler
            }
            if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.Q) {
                result.error("unsupported", "Requiere Android 10 o superior", null)
                return@setMethodCallHandler
            }
            try {
                val values = android.content.ContentValues().apply {
                    put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
                    put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,
                        android.os.Environment.DIRECTORY_PICTURES + "/SeTu")
                    put(android.provider.MediaStore.Images.Media.IS_PENDING, 1)
                }
                val resolver = contentResolver
                val uri = resolver.insert(
                    android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                    ?: throw java.io.IOException("insert_failed")
                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: throw java.io.IOException("stream_failed")
                values.clear()
                values.put(android.provider.MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                result.success(null)
            } catch (error: Exception) {
                result.error("save_failed", "No se pudo guardar la imagen", null)
            }
        }
        nearbyMeshChannel = NearbyMeshChannel(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (nearbyMeshChannel?.onRequestPermissionsResult(requestCode, grantResults) == true) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: android.content.Intent?,
    ) {
        if (nearbyMeshChannel?.onActivityResult(requestCode, resultCode) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
