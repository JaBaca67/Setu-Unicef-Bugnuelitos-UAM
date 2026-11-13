import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../local/encrypted_local_store.dart';
import '../remote/setu_remote_gateway.dart';
import 'mesh_envelope.dart';
import 'mesh_transport.dart';

enum MeshPacketState { queued, custodyConfirmed, centrallySynced }

@immutable
class MeshQueueItem {
  const MeshQueueItem({
    required this.envelope,
    required this.state,
  });

  factory MeshQueueItem.fromJson(Map<String, Object?> json) => MeshQueueItem(
        envelope: MeshEnvelope.fromJson(
          Map<String, Object?>.from(json['envelope']! as Map<Object?, Object?>),
        ),
        state: MeshPacketState.values.byName(json['state']! as String),
      );

  final MeshEnvelope envelope;
  final MeshPacketState state;

  MeshQueueItem copyWith({MeshPacketState? state}) => MeshQueueItem(
        envelope: envelope,
        state: state ?? this.state,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'envelope': envelope.toJson(),
        'state': state.name,
      };
}

/// Servicio de cola cifrada, reenvío multisalto, acuses y subida puente (ADR 0005 / 0008).
class MeshRelayService extends ChangeNotifier {
  MeshRelayService({
    required this.transport,
    Future<LocalStorePersistence> Function()? openStore,
    this.remoteGateway,
    this.bridgeKeyPair,
  }) : _openStore = openStore ?? _onDevice;

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_mesh_queue.enc',
        keyName: 'setu.mesh.master.v1',
      );

  final MeshTransport transport;
  final Future<LocalStorePersistence> Function() _openStore;
  final SetuRemoteGateway? remoteGateway;
  final SimpleKeyPair? bridgeKeyPair;

  LocalStorePersistence? _store;
  Future<void>? _opening;
  StreamSubscription<MeshTransportEvent>? _subscription;
  bool _running = false;
  bool _disposed = false;

  final Map<String, MeshQueueItem> _queue = <String, MeshQueueItem>{};
  final Set<String> _seenPacketIds = <String>{};
  final Set<String> _connectedPeers = <String>{};

  bool get isRunning => _running;
  int get connectedPeerCount => _connectedPeers.length;
  List<MeshQueueItem> get items =>
      List<MeshQueueItem>.unmodifiable(_queue.values);

  Future<void> open() =>
      _store != null ? Future<void>.value() : _opening ??= _load();

  Future<void> _load() async {
    try {
      final LocalStorePersistence store =
          await Future<LocalStorePersistence>.sync(_openStore);
      final Map<String, Object?>? data = await store.load();
      if (data != null && data['version'] == 1) {
        final List<Object?> rawItems =
            (data['items'] as List<Object?>?) ?? const <Object?>[];
        for (final Object? entry in rawItems) {
          final MeshQueueItem item = MeshQueueItem.fromJson(
            Map<String, Object?>.from(entry! as Map<Object?, Object?>),
          );
          _queue[item.envelope.packetId] = item;
          _seenPacketIds.add(item.envelope.packetId);
        }
        final List<Object?> rawSeen =
            (data['seen'] as List<Object?>?) ?? const <Object?>[];
        for (final Object? id in rawSeen) {
          if (id is String) _seenPacketIds.add(id);
        }
      }
      _store = store;
    } on Object {
      // Mantiene operación en memoria si el almacén no está disponible.
    } finally {
      _opening = null;
      _notify();
    }
  }

  Future<bool> start({String endpointName = 'setu-node'}) async {
    await open();
    final bool granted = await transport.requestPermissions();
    if (!granted) return false;
    _subscription ??= transport.events.listen(_handleEvent);
    await transport.startNode(endpointName: endpointName);
    _running = true;
    _notify();
    return true;
  }

  Future<void> stop() async {
    await transport.stopNode();
    await _subscription?.cancel();
    _subscription = null;
    _connectedPeers.clear();
    _running = false;
    _notify();
  }

  /// Sella la alerta mínima en un sobre E2EE, la guarda y la difunde si hay vecinos.
  Future<MeshEnvelope> enqueueMinimalAlert(
    MeshMinimalAlertPayload payload, {
    required List<int> recipientPublicKeyBytes,
  }) async {
    await open();
    final MeshEnvelope envelope = await MeshEnvelope.seal(
      payload,
      recipientPublicKeyBytes: recipientPublicKeyBytes,
    );
    _seenPacketIds.add(envelope.packetId);
    _queue[envelope.packetId] = MeshQueueItem(
      envelope: envelope,
      state: MeshPacketState.queued,
    );
    await _persist();
    if (_connectedPeers.isNotEmpty) {
      await transport.broadcastPayload(envelope.toWireBytes());
    }
    _notify();
    return envelope;
  }

  /// Intenta subir sobres pendientes si este teléfono actúa como puente autorizado.
  Future<int> syncPendingAsBridge() async {
    final SetuRemoteGateway? gateway = remoteGateway;
    final SimpleKeyPair? keyPair = bridgeKeyPair;
    if (gateway == null || keyPair == null) return 0;

    int uploaded = 0;
    final List<MeshQueueItem> pending = _queue.values
        .where(
          (MeshQueueItem item) => item.state != MeshPacketState.centrallySynced,
        )
        .toList(growable: false);

    for (final MeshQueueItem item in pending) {
      try {
        final MeshMinimalAlertPayload payload = await item.envelope.open(
          recipientKeyPair: keyPair,
        );
        await gateway.submitStudentAlert(
          clientOperationId: payload.clientOperationId,
          publicSchoolCode: payload.publicSchoolCode,
          situationType: payload.situationType,
          studentRole: payload.studentRole,
          origin: 'mesh',
          involvesStaff: payload.involvesStaff,
          declaredAt: payload.declaredAt,
          capabilityVerifierHash: payload.capabilityVerifierHash,
        );
        _queue[item.envelope.packetId] = item.copyWith(
          state: MeshPacketState.centrallySynced,
        );
        uploaded++;
      } on Object {
        // Conserva el sobre para reintento posterior o si no pertenece a esta clave.
      }
    }

    if (uploaded > 0) {
      await _persist();
      _notify();
    }
    return uploaded;
  }

  Future<void> _handleEvent(MeshTransportEvent event) async {
    switch (event) {
      case MeshPeerConnected(:final String endpointId):
        _connectedPeers.add(endpointId);
        await _flushQueuedToPeer(endpointId);
        _notify();
      case MeshPeerDisconnected(:final String endpointId):
        _connectedPeers.remove(endpointId);
        _notify();
      case MeshPayloadReceived(:final String endpointId, :final Uint8List bytes):
        await _handleIncomingBytes(endpointId, bytes);
      case MeshStatusChanged():
        _notify();
    }
  }

  Future<void> _flushQueuedToPeer(String endpointId) async {
    for (final MeshQueueItem item in _queue.values) {
      if (item.state != MeshPacketState.centrallySynced &&
          item.envelope.ttl > 0) {
        try {
          await transport.sendPayload(endpointId, item.envelope.toWireBytes());
        } on Object {
          // Si el vecino se desconectó, permanece en cola.
        }
      }
    }
  }

  Future<void> _handleIncomingBytes(String fromEndpointId, Uint8List bytes) async {
    if (bytes.length > MeshEnvelope.maxWireBytes) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on Object {
      return;
    }
    if (decoded is! Map<Object?, Object?>) return;
    final Map<String, Object?> map = Map<String, Object?>.from(decoded);
    final String? kind = map['kind'] as String?;

    if (kind == 'ack') {
      final MeshAckPacket ack = MeshAckPacket.fromJson(map);
      final MeshQueueItem? existing = _queue[ack.packetId];
      if (existing != null) {
        final MeshPacketState nextState = ack.centrallySynced
            ? MeshPacketState.centrallySynced
            : MeshPacketState.custodyConfirmed;
        if (existing.state.index < nextState.index) {
          _queue[ack.packetId] = existing.copyWith(state: nextState);
          await _persist();
          _notify();
        }
      }
      return;
    }

    if (kind != 'envelope') return;
    final MeshEnvelope envelope;
    try {
      envelope = MeshEnvelope.fromJson(map);
    } on Object {
      return;
    }

    if (_seenPacketIds.contains(envelope.packetId)) {
      // Ya recibido antes: reenvía acuse sin duplicar.
      await _sendAck(fromEndpointId, envelope.packetId, synced: false);
      return;
    }

    _seenPacketIds.add(envelope.packetId);
    final MeshEnvelope relayEnvelope = envelope.nextHop();
    _queue[envelope.packetId] = MeshQueueItem(
      envelope: relayEnvelope,
      state: MeshPacketState.custodyConfirmed,
    );
    // Persiste antes de confirmar custodia al vecino.
    await _persist();

    bool syncedNow = false;
    if (bridgeKeyPair != null && remoteGateway != null) {
      syncedNow = (await syncPendingAsBridge()) > 0;
    }

    await _sendAck(fromEndpointId, envelope.packetId, synced: syncedNow);

    if (!syncedNow && relayEnvelope.ttl > 0) {
      final Uint8List forwardBytes = relayEnvelope.toWireBytes();
      for (final String peerId in _connectedPeers) {
        if (peerId != fromEndpointId) {
          try {
            await transport.sendPayload(peerId, forwardBytes);
          } on Object {
            // Reenvío oportunista: si falla un vecino, sigue en cola.
          }
        }
      }
    }

    _notify();
  }

  Future<void> _sendAck(
    String endpointId,
    String packetId, {
    required bool synced,
  }) async {
    try {
      await transport.sendPayload(
        endpointId,
        MeshAckPacket(packetId: packetId, centrallySynced: synced)
            .toWireBytes(),
      );
    } on Object {
      // Silencioso si el vecino ya se desconectó.
    }
  }

  Future<void> _persist() async {
    await _store?.save(<String, Object?>{
      'version': 1,
      'items': _queue.values
          .map((MeshQueueItem item) => item.toJson())
          .toList(growable: false),
      'seen': _seenPacketIds.toList(growable: false),
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
