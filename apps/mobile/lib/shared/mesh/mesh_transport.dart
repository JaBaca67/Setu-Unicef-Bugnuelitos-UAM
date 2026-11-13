import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
sealed class MeshTransportEvent {
  const MeshTransportEvent();
}

class MeshPeerConnected extends MeshTransportEvent {
  const MeshPeerConnected(this.endpointId);
  final String endpointId;
}

class MeshPeerDisconnected extends MeshTransportEvent {
  const MeshPeerDisconnected(this.endpointId);
  final String endpointId;
}

class MeshPayloadReceived extends MeshTransportEvent {
  const MeshPayloadReceived({
    required this.endpointId,
    required this.bytes,
  });

  final String endpointId;
  final Uint8List bytes;
}

class MeshStatusChanged extends MeshTransportEvent {
  const MeshStatusChanged(this.state, {this.message});
  final String state;
  final String? message;
}

/// Contrato de transporte de proximidad (Bluetooth/Wi-Fi P2P) para SéTú.
abstract class MeshTransport {
  Stream<MeshTransportEvent> get events;
  Future<bool> hasRequiredPermissions();
  Future<bool> requestPermissions();
  Future<void> startNode({String endpointName = 'setu-node'});
  Future<void> stopNode();
  Future<void> sendPayload(String endpointId, Uint8List bytes);
  Future<int> broadcastPayload(Uint8List bytes);
}

/// Implementación sobre Google Nearby Connections (`Strategy.P2P_CLUSTER`) vía Kotlin.
class NearbyMeshTransport implements MeshTransport {
  static const MethodChannel _method = MethodChannel('setu/mesh_nearby');
  static const EventChannel _event = EventChannel('setu/mesh_nearby/events');

  Stream<MeshTransportEvent>? _events;

  @override
  Stream<MeshTransportEvent> get events =>
      _events ??= _event.receiveBroadcastStream().map(_parseEvent).where(
            (MeshTransportEvent? e) => e != null,
          ).cast<MeshTransportEvent>();

  static MeshTransportEvent? _parseEvent(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final String? type = raw['type'] as String?;
    return switch (type) {
      'peer_connected' => MeshPeerConnected(raw['endpointId']! as String),
      'peer_disconnected' => MeshPeerDisconnected(raw['endpointId']! as String),
      'payload_received' => MeshPayloadReceived(
          endpointId: raw['endpointId']! as String,
          bytes: raw['bytes']! as Uint8List,
        ),
      'status' => MeshStatusChanged(
          raw['state']! as String,
          message: raw['message'] as String?,
        ),
      _ => null,
    };
  }

  @override
  Future<bool> hasRequiredPermissions() async =>
      await _method.invokeMethod<bool>('hasRequiredPermissions') ?? false;

  @override
  Future<bool> requestPermissions() async =>
      await _method.invokeMethod<bool>('requestPermissions') ?? false;

  @override
  Future<void> startNode({String endpointName = 'setu-node'}) =>
      _method.invokeMethod<void>(
        'startNode',
        <String, Object?>{'endpointName': endpointName},
      );

  @override
  Future<void> stopNode() => _method.invokeMethod<void>('stopNode');

  @override
  Future<void> sendPayload(String endpointId, Uint8List bytes) =>
      _method.invokeMethod<void>(
        'sendPayload',
        <String, Object?>{'endpointId': endpointId, 'bytes': bytes},
      );

  @override
  Future<int> broadcastPayload(Uint8List bytes) async =>
      await _method.invokeMethod<int>(
        'broadcastPayload',
        <String, Object?>{'bytes': bytes},
      ) ??
      0;
}
