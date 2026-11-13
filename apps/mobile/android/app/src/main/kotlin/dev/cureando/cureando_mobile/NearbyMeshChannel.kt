package dev.cureando.cureando_mobile

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Canal nativo Kotlin para transporte mesh oportunista mediante
 * Google Nearby Connections (Strategy.P2P_CLUSTER).
 *
 * Solo transporta sobres cifrados opacos como bytes; no interpreta ni
 * almacena contenido clínico.
 */
class NearbyMeshChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "setu/mesh_nearby"
        const val EVENT_CHANNEL = "setu/mesh_nearby/events"
        private const val SERVICE_ID = "dev.cureando.setu.mesh.v1"
        private const val PERMISSION_REQUEST_CODE = 4207
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val connectionsClient: ConnectionsClient by lazy {
        Nearby.getConnectionsClient(activity)
    }

    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var localEndpointName: String = "setu-node"
    private val connectedEndpoints = mutableSetOf<String>()
    private val pendingEndpoints = mutableSetOf<String>()

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun emitEvent(payload: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(payload)
        }
    }

    private fun requiredPermissions(): Array<String> {
        val list = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            list.add(Manifest.permission.NEARBY_WIFI_DEVICES)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            list.add(Manifest.permission.BLUETOOTH_SCAN)
            list.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            list.add(Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            list.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        return list.toTypedArray()
    }

    private fun hasAllPermissions(): Boolean =
        requiredPermissions().all { permission ->
            ContextCompat.checkSelfPermission(activity, permission) ==
                PackageManager.PERMISSION_GRANTED
        }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasRequiredPermissions" -> result.success(hasAllPermissions())
            "requestPermissions" -> {
                if (hasAllPermissions()) {
                    result.success(true)
                    return
                }
                if (pendingPermissionResult != null) {
                    result.error("permission_in_progress", "Solicitud de permisos en curso", null)
                    return
                }
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    activity,
                    requiredPermissions(),
                    PERMISSION_REQUEST_CODE,
                )
            }
            "startNode" -> {
                if (!hasAllPermissions()) {
                    result.error("missing_permissions", "Faltan permisos Bluetooth/Wi-Fi cercano", null)
                    return
                }
                localEndpointName = (call.argument<String>("endpointName") ?: "setu-node")
                    .take(32)
                startCluster(result)
            }
            "stopNode" -> {
                stopCluster()
                result.success(null)
            }
            "sendPayload" -> {
                val endpointId = call.argument<String>("endpointId")
                val bytes = call.argument<ByteArray>("bytes")
                if (endpointId == null || bytes == null) {
                    result.error("invalid_argument", "Se requiere endpointId y bytes", null)
                    return
                }
                connectionsClient.sendPayload(endpointId, Payload.fromBytes(bytes))
                result.success(null)
            }
            "broadcastPayload" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("invalid_argument", "Se requiere bytes", null)
                    return
                }
                val targets = connectedEndpoints.toList()
                if (targets.isNotEmpty()) {
                    connectionsClient.sendPayload(targets, Payload.fromBytes(bytes))
                }
                result.success(targets.size)
            }
            else -> result.notImplemented()
        }
    }

    private fun startCluster(result: MethodChannel.Result) {
        val advertisingOptions = AdvertisingOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()
        val discoveryOptions = DiscoveryOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .build()

        connectionsClient.startAdvertising(
            localEndpointName,
            SERVICE_ID,
            connectionLifecycleCallback,
            advertisingOptions,
        ).addOnSuccessListener {
            connectionsClient.startDiscovery(
                SERVICE_ID,
                endpointDiscoveryCallback,
                discoveryOptions,
            ).addOnSuccessListener {
                emitEvent(mapOf("type" to "status", "state" to "started"))
                result.success(null)
            }.addOnFailureListener { e ->
                emitEvent(
                    mapOf(
                        "type" to "status",
                        "state" to "error",
                        "message" to (e.localizedMessage ?: "discovery_failed"),
                    ),
                )
                result.error("discovery_failed", e.localizedMessage, null)
            }
        }.addOnFailureListener { e ->
            emitEvent(
                mapOf(
                    "type" to "status",
                    "state" to "error",
                    "message" to (e.localizedMessage ?: "advertising_failed"),
                ),
            )
            result.error("advertising_failed", e.localizedMessage, null)
        }
    }

    private fun stopCluster() {
        connectionsClient.stopAdvertising()
        connectionsClient.stopDiscovery()
        connectionsClient.stopAllEndpoints()
        connectedEndpoints.clear()
        pendingEndpoints.clear()
        emitEvent(mapOf("type" to "status", "state" to "stopped"))
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            if (connectedEndpoints.contains(endpointId) || pendingEndpoints.contains(endpointId)) {
                return
            }
            pendingEndpoints.add(endpointId)
            connectionsClient.requestConnection(
                localEndpointName,
                endpointId,
                connectionLifecycleCallback,
            ).addOnFailureListener {
                pendingEndpoints.remove(endpointId)
            }
        }

        override fun onEndpointLost(endpointId: String) {
            pendingEndpoints.remove(endpointId)
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) {
            connectionsClient.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, resolution: ConnectionResolution) {
            pendingEndpoints.remove(endpointId)
            if (resolution.status.isSuccess) {
                connectedEndpoints.add(endpointId)
                emitEvent(
                    mapOf(
                        "type" to "peer_connected",
                        "endpointId" to endpointId,
                    ),
                )
            }
        }

        override fun onDisconnected(endpointId: String) {
            pendingEndpoints.remove(endpointId)
            connectedEndpoints.remove(endpointId)
            emitEvent(
                mapOf(
                    "type" to "peer_disconnected",
                    "endpointId" to endpointId,
                ),
            )
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val bytes = payload.asBytes() ?: return
                emitEvent(
                    mapOf(
                        "type" to "payload_received",
                        "endpointId" to endpointId,
                        "bytes" to bytes,
                    ),
                )
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            // Bytes payloads arrive atomically in onPayloadReceived.
        }
    }
}
