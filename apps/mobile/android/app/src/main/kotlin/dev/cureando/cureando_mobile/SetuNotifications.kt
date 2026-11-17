package dev.cureando.cureando_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Avisos nativos de SéTú. El canal es de importancia alta para que Android
 * muestre el aviso flotante (heads-up) como una app de mensajería. Los textos
 * son neutros: nunca incluyen relatos ni datos del caso.
 */
object SetuNotifications {
    const val CHANNEL_ID = "setu_avisos"
    private const val METHOD_CHANNEL = "dev.cureando.app/notifications"
    private var nextId = 1000

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Avisos de SéTú",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Nuevas alertas y mensajes de seguimiento."
            enableVibration(true)
            enableLights(true)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        manager.createNotificationChannel(channel)
    }

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    val title = call.argument<String>("title") ?: "SéTú"
                    val body = call.argument<String>("body") ?: ""
                    show(context, title, body)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun show(context: Context, title: String, body: String) {
        ensureChannel(context)
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val launch = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            context,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
                .setDefaults(Notification.DEFAULT_ALL)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_setu)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setCategory(Notification.CATEGORY_MESSAGE)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()
        manager.notify(nextId++, notification)
    }
}
