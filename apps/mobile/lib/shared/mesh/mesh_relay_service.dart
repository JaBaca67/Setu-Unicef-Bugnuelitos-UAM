import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../local/encrypted_local_store.dart';
import '../remote/setu_remote_gateway.dart';
import '../remote/setu_remote_models.dart';
import 'mesh_envelope.dart';
import 'mesh_recipient_directory.dart';
import 'mesh_transport.dart';

enum MeshPacketState {
  queued,
  custodyConfirmed,
  serverCustody,
  centrallySynced,
}

@immutable
class MeshQueueItem {
  const MeshQueueItem({required this.envelope, required this.state});

  factory MeshQueueItem.fromJson(Map<String, Object?> json) => MeshQueueItem(
    envelope: MeshEnvelope.fromJson(
      Map<String, Object?>.from(json['envelope']! as Map<Object?, Object?>),
    ),
    state: MeshPacketState.values.byName(json['state']! as String),
  );

  final MeshEnvelope envelope;
  final MeshPacketState state;

  MeshQueueItem copyWith({MeshPacketState? state}) =>
      MeshQueueItem(envelope: envelope, state: state ?? this.state);

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
    this.resolveBridgeKeyPair,
    this.recipientDirectory,
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
  final Future<SimpleKeyPair?> Function()? resolveBridgeKeyPair;
  final MeshRecipientDirectory? recipientDirectory;

  LocalStorePersistence? _store;
  Future<void>? _opening;
  Future<bool>? _starting;
  bool _startingRequestsAccess = false;
  Future<void>? _preparingReceiver;
  String? _receiverScope;
  StreamSubscription<MeshTransportEvent>? _subscription;
  SimpleKeyPair? _resolvedBridgeKeyPair;
  bool _running = false;
  bool _disposed = false;
  bool _syncingBridge = false;
  bool _bridgeSyncRequested = false;
  Timer? _bridgeRetry;
  Future<void> _incomingWork = Future<void>.value();
  Future<void> _persistWork = Future<void>.value();
  int _syncedCount = 0;

  final Map<String, MeshQueueItem> _queue = <String, MeshQueueItem>{};
  final Set<String> _seenPacketIds = <String>{};
  final Set<String> _syncedOperationIds = <String>{};
  final Set<String> _connectedPeers = <String>{};
  final Map<String, String> _outgoingPackets = <String, String>{};
  final Map<String, String> _expectedDeliveryProofs = <String, String>{};
  final Map<String, String> _deliveryReceipts = <String, String>{};
  final Map<String, MeshMinimalAlertPayload> _schoolAlerts =
      <String, MeshMinimalAlertPayload>{};
  String? _schoolCode;
  SimpleKeyPair? _schoolKeyPair;
  int _schoolContextEpoch = 0;

  bool get isRunning => _running;
  int get connectedPeerCount => _connectedPeers.length;
  int get syncedCount => _syncedCount;
  List<MeshQueueItem> get items =>
      List<MeshQueueItem>.unmodifiable(_queue.values);
  List<MeshMinimalAlertPayload> get schoolAlerts =>
      List<MeshMinimalAlertPayload>.unmodifiable(_schoolAlerts.values);
  List<MeshMinimalAlertPayload> get directorAlerts => schoolAlerts;

  bool isOperationSynced(String clientOperationId) =>
      _syncedOperationIds.contains(clientOperationId);

  bool isOperationDelivered(String operationId) => _outgoingPackets.entries.any(
    (MapEntry<String, String> entry) =>
        entry.key.startsWith('$operationId:') &&
        _expectedDeliveryProofs[entry.value] != null &&
        _expectedDeliveryProofs[entry.value] == _deliveryReceipts[entry.value],
  );

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
        // Las proyecciones se reconstruyen con la clave de la sesión activa.
        final List<Object?> rawSyncedOps =
            (data['syncedOps'] as List<Object?>?) ?? const <Object?>[];
        for (final Object? op in rawSyncedOps) {
          if (op is String && op.isNotEmpty) {
            _syncedOperationIds.add(op);
          }
        }
        final Object? outgoing = data['outgoingPackets'];
        if (outgoing is Map<Object?, Object?>) {
          _outgoingPackets.addAll(outgoing.cast<String, String>());
        }
        for (final (String, Map<String, String>) field
            in <(String, Map<String, String>)>[
              ('expectedDeliveryProofs', _expectedDeliveryProofs),
              ('deliveryReceipts', _deliveryReceipts),
            ]) {
          final Object? raw = data[field.$1];
          if (raw is Map<Object?, Object?>) {
            field.$2.addAll(raw.cast<String, String>());
          }
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

  /// Solicita permisos Nearby, pide activar Bluetooth si hace falta e inicia el nodo.
  Future<bool> ensureReadyAndStart({
    String endpointName = 'setu-node',
    bool requestAccess = true,
  }) async {
    final Future<bool>? active = _starting;
    if (active != null) {
      final bool canRequestAfter = requestAccess && !_startingRequestsAccess;
      final bool ready = await active;
      if (ready || !canRequestAfter) return ready;
      return ensureReadyAndStart(requestAccess: true);
    }
    _startingRequestsAccess = requestAccess;
    return _starting = _ensureReady(requestAccess).whenComplete(() {
      _starting = null;
    });
  }

  Future<bool> _ensureReady(bool requestAccess) async {
    await open();
    bool hasPerms = await transport.hasRequiredPermissions();
    if (!hasPerms && requestAccess) {
      hasPerms = await transport.requestPermissions();
    }
    if (!hasPerms) {
      _running = false;
      _connectedPeers.clear();
      return false;
    }
    bool btOn = await transport.isBluetoothEnabled();
    if (!btOn && requestAccess) {
      btOn = await transport.requestEnableBluetooth();
    }
    if (!btOn) {
      _running = false;
      _connectedPeers.clear();
      return false;
    }
    if (!_running) {
      return _startNode();
    }
    return true;
  }

  Future<bool> start({String endpointName = 'setu-node'}) =>
      ensureReadyAndStart();

  Future<bool> _startNode() async {
    if (_running) return true;
    _subscription ??= transport.events.listen((MeshTransportEvent event) {
      _incomingWork = _incomingWork.then((_) => _handleEvent(event)).catchError(
        (Object _) {
          /* Paquete o almacenamiento inválido: no confirmar custodia. */
        },
      );
    });
    // Nunca anunciar usuario, rol, colegio ni nombre real del teléfono.
    await transport.startNode(endpointName: 'setu-node');
    _running = true;
    _bridgeRetry ??= Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(retryPending());
    });
    unawaited(syncPendingAsBridge());
    _notify();
    return true;
  }

  /// Reintenta radios, transferencias y HTTPS sin repetir solicitudes del sistema.
  Future<void> retryPending() async {
    if (_disposed) return;
    try {
      final bool ready = await ensureReadyAndStart(requestAccess: false);
      if (ready) {
        for (final String peer in _connectedPeers.toList()) {
          await _flushQueuedToPeer(peer);
        }
      }
    } on Object {
      _running = false;
    }
    await syncPendingAsBridge();
  }

  Future<void> stop() async {
    _bridgeRetry?.cancel();
    _bridgeRetry = null;
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
    final String outgoingKey =
        '${payload.clientOperationId}:${base64Encode(recipientPublicKeyBytes)}';
    final String? existingId = _outgoingPackets[outgoingKey];
    if (existingId != null && _queue.containsKey(existingId)) {
      await _persist();
      final MeshQueueItem existing = _queue[existingId]!;
      if (_connectedPeers.isNotEmpty &&
          existing.state != MeshPacketState.centrallySynced) {
        try {
          await transport.broadcastPayload(existing.envelope.toWireBytes());
        } on Object {
          // El siguiente ciclo vuelve a intentar con la misma copia persistida.
        }
      }
      return existing.envelope;
    }
    final String receiptToken = MeshEnvelope.newReceiptToken();
    final MeshEnvelope envelope = await MeshEnvelope.seal(
      payload,
      recipientPublicKeyBytes: recipientPublicKeyBytes,
      receiptToken: receiptToken,
    );
    _expectedDeliveryProofs[envelope.packetId] =
        await MeshEnvelope.deliveryProof(envelope.packetId, receiptToken);
    _seenPacketIds.add(envelope.packetId);
    _outgoingPackets[outgoingKey] = envelope.packetId;
    _queue[envelope.packetId] = MeshQueueItem(
      envelope: envelope,
      state: MeshPacketState.queued,
    );
    await _persist();
    if (_connectedPeers.isNotEmpty) {
      try {
        await transport.broadcastPayload(envelope.toWireBytes());
      } on Object {
        // No impedir el arranque automático por un vecino desconectado.
      }
    }
    _notify();
    return envelope;
  }

  Future<SimpleKeyPair?> _getBridgeKeyPair() async {
    if (recipientDirectory != null) return recipientDirectory!.localKeyPair();
    if (bridgeKeyPair != null) return bridgeKeyPair;
    if (_resolvedBridgeKeyPair != null) return _resolvedBridgeKeyPair;
    final Future<SimpleKeyPair?> Function()? resolver = resolveBridgeKeyPair;
    if (resolver == null) return null;
    _resolvedBridgeKeyPair = await resolver();
    return _resolvedBridgeKeyPair;
  }

  /// Intenta subir sobres pendientes si este teléfono actúa como puente autorizado.
  Future<int> syncPendingAsBridge() async {
    if (_syncingBridge) {
      _bridgeSyncRequested = true;
      return 0;
    }
    final SetuRemoteGateway? gateway = remoteGateway;
    if (gateway == null) return 0;
    _syncingBridge = true;
    int uploaded = 0;
    try {
      await open();
      // El arranque de la app también sincroniza como puente. Esperar la
      // preparación evita registrar una clave global mientras se carga la
      // clave escolar de la sesión que acaba de iniciar.
      await _preparingReceiver;
      if (_receiverScope != null && recipientDirectory != null) {
        await recipientDirectory!.registerReceiver(_schoolCode);
      }
      final SimpleKeyPair? keyPair = await _getBridgeKeyPair();
      if (recipientDirectory != null && keyPair != null) {
        try {
          final List<Map<String, Object?>> received = await gateway
              .listMyMeshEnvelopes()
              .timeout(const Duration(seconds: 8));
          for (final Map<String, Object?> json in received) {
            final MeshEnvelope envelope = MeshEnvelope.fromJson(json);
            _queue.putIfAbsent(
              envelope.packetId,
              () => MeshQueueItem(
                envelope: envelope,
                state: MeshPacketState.serverCustody,
              ),
            );
          }
          if (received.isNotEmpty) await _persist();
        } on Object {
          // La cola local sigue disponible si no se puede consultar custodia.
        }
      }
      final List<MeshQueueItem> pending = _queue.values
          .where(
            (MeshQueueItem item) =>
                item.state != MeshPacketState.centrallySynced,
          )
          .toList(growable: false);

      for (final MeshQueueItem item in pending) {
        MeshMinimalAlertPayload? payload;
        try {
          if (keyPair != null) {
            payload = await item.envelope.open(recipientKeyPair: keyPair);
          }
        } on Object {
          // Este teléfono solo retransmite los sobres de otro destinatario.
        }
        if (payload == null) {
          if (item.state != MeshPacketState.serverCustody &&
              item.envelope.recipientKeyId != null) {
            try {
              await gateway
                  .relayMeshEnvelope(item.envelope.toJson())
                  .timeout(const Duration(seconds: 8));
              _queue[item.envelope.packetId] = item.copyWith(
                state: MeshPacketState.serverCustody,
              );
              await _persist();
            } on Object {
              /* Sin red: conservar para el siguiente intento. */
            }
          }
          continue;
        }
        // También los sobres recuperados de custodia producen una proyección
        // local antes de depender de otra llamada HTTPS.
        if (await _tryOpenForSchool(item.envelope)) {
          await _persist();
          _notify();
        }
        await _confirmRecipientDelivery(item.envelope, payload);
        try {
          await gateway
              .submitStudentAlert(
                StudentAlertSubmission(
                  clientOperationId: payload.clientOperationId,
                  publicSchoolCode: payload.publicSchoolCode,
                  situationType: SetuSituationType.fromWire(
                    payload.situationType,
                  ),
                  studentRole: SetuStudentCaseRole.fromWire(
                    payload.studentRole,
                  ),
                  origin: SetuAlertOrigin.mesh,
                  involvesStaff: payload.involvesStaff,
                  declaredAt: payload.declaredAt,
                  capabilityVerifierHash: payload.capabilityVerifierHash,
                ),
              )
              .timeout(const Duration(seconds: 8));
          if (recipientDirectory != null) {
            // Puede no existir custodia remota si llegó directamente por Nearby.
            await gateway
                .completeMeshEnvelope(
                  item.envelope.packetId,
                  payload.clientOperationId,
                )
                .timeout(const Duration(seconds: 8));
          }
          _queue[item.envelope.packetId] = item.copyWith(
            state: MeshPacketState.centrallySynced,
          );
          _syncedOperationIds.add(payload.clientOperationId);
          _schoolAlerts.remove(payload.clientOperationId);
          _syncedCount++;
          uploaded++;
        } on Object {
          // Conserva el sobre para reintento posterior o si no pertenece a esta clave.
        }
      }

      if (uploaded > 0) {
        await _persist();
        _notify();
      }
    } on Object {
      // Clave o almacén no disponibles: conservar los sobres para reintentar.
    } finally {
      _syncingBridge = false;
      if (_bridgeSyncRequested && !_disposed) {
        _bridgeSyncRequested = false;
        unawaited(syncPendingAsBridge());
      }
    }
    return uploaded;
  }

  Future<void> prepareSchoolReceiver(String? schoolCode) async {
    final String scope =
        '${remoteGateway?.currentStaffUserId}:${schoolCode?.trim().toUpperCase()}';
    if (_receiverScope == scope && _preparingReceiver != null) {
      return _preparingReceiver;
    }
    final Future<void> preparing = _prepareSchoolReceiver(schoolCode);
    _receiverScope = scope;
    _preparingReceiver = preparing;
    return preparing;
  }

  Future<void> _prepareSchoolReceiver(String? schoolCode) async {
    _bridgeRetry ??= Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(retryPending());
    });
    clearSchoolContext();
    final int epoch = _schoolContextEpoch;
    final SimpleKeyPair? pair = await recipientDirectory?.registerReceiver(
      schoolCode,
    );
    if (epoch != _schoolContextEpoch || _disposed) return;
    if (pair != null && schoolCode != null && schoolCode.trim().isNotEmpty) {
      await setSchoolContext(schoolCode: schoolCode, schoolKeyPair: pair);
    }
    await ensureReadyAndStart();
    unawaited(syncPendingAsBridge());
  }

  Future<void> setSchoolContext({
    required String schoolCode,
    required SimpleKeyPair schoolKeyPair,
  }) async {
    final int epoch = _schoolContextEpoch;
    await open();
    if (epoch != _schoolContextEpoch || _disposed) return;
    _schoolCode = schoolCode.trim().toUpperCase();
    _schoolKeyPair = schoolKeyPair;
    bool changed = false;
    for (final MeshQueueItem item in _queue.values.toList()) {
      if (await _tryOpenForSchool(item.envelope)) {
        changed = true;
      }
    }
    if (changed) {
      await _persist();
      _notify();
    }
    for (final MeshQueueItem item in _queue.values.toList()) {
      try {
        final MeshMinimalAlertPayload payload = await item.envelope.open(
          recipientKeyPair: schoolKeyPair,
        );
        if (epoch != _schoolContextEpoch || _disposed) return;
        await _confirmRecipientDelivery(item.envelope, payload);
      } on Object {
        // Sobres de otro destinatario permanecen opacos.
      }
    }
  }

  void clearSchoolContext() {
    _schoolContextEpoch++;
    _schoolCode = null;
    _schoolKeyPair = null;
    _schoolAlerts.clear();
    _receiverScope = null;
    _preparingReceiver = null;
  }

  Future<void> setDirectorSchoolContext({
    required String schoolCode,
    required SimpleKeyPair schoolKeyPair,
  }) => setSchoolContext(schoolCode: schoolCode, schoolKeyPair: schoolKeyPair);

  void clearDirectorSchoolContext() => clearSchoolContext();

  Future<bool> _tryOpenForSchool(MeshEnvelope envelope) async {
    final int epoch = _schoolContextEpoch;
    final SimpleKeyPair? keyPair = _schoolKeyPair;
    final String? schoolCode = _schoolCode;
    if (keyPair == null || schoolCode == null) return false;
    try {
      final MeshMinimalAlertPayload payload = await envelope.open(
        recipientKeyPair: keyPair,
      );
      if (epoch != _schoolContextEpoch || _disposed) return false;
      if (payload.involvesStaff) return false;
      if (payload.publicSchoolCode.trim().toUpperCase() != schoolCode) {
        return false;
      }
      if (_schoolAlerts.containsKey(payload.clientOperationId)) return false;
      _schoolAlerts[payload.clientOperationId] = payload;
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _confirmRecipientDelivery(
    MeshEnvelope envelope,
    MeshMinimalAlertPayload payload,
  ) async {
    final String? token = payload.receiptToken;
    if (token == null || token.length != 64) return;
    final String proof = await MeshEnvelope.deliveryProof(
      envelope.packetId,
      token,
    );
    if (_deliveryReceipts[envelope.packetId] == proof) return;
    _deliveryReceipts[envelope.packetId] = proof;
    // Persistir la alerta cifrada antes de confirmar recepción al emisor.
    await _persist();
    for (final String peer in _connectedPeers.toList()) {
      await _sendDeliveryReceipt(peer, envelope.packetId, proof);
    }
    _notify();
  }

  Future<void> _sendDeliveryReceipt(
    String peer,
    String packetId,
    String proof,
  ) async {
    try {
      await transport.sendPayload(
        peer,
        Uint8List.fromList(
          utf8.encode(
            jsonEncode(<String, Object?>{
              'kind': 'recipient_receipt',
              'id': packetId,
              'proof': proof,
            }),
          ),
        ),
      );
    } on Object {
      // Se reenvía al volver a conectar o en el próximo ciclo.
    }
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
      case MeshPayloadReceived(
        :final String endpointId,
        :final Uint8List bytes,
      ):
        await _handleIncomingBytes(endpointId, bytes);
      case MeshStatusChanged():
        if (event.state == 'stopped' || event.state == 'error') {
          _running = false;
          _connectedPeers.clear();
        }
        _notify();
    }
  }

  Future<void> _flushQueuedToPeer(String endpointId) async {
    await _persist();
    for (final MapEntry<String, String> receipt
        in _deliveryReceipts.entries.toList()) {
      await _sendDeliveryReceipt(endpointId, receipt.key, receipt.value);
    }
    for (final MeshQueueItem item in _queue.values.toList()) {
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

  Future<void> _handleIncomingBytes(
    String fromEndpointId,
    Uint8List bytes,
  ) async {
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

    if (kind == 'recipient_receipt') {
      final Object? id = map['id'];
      final Object? proof = map['proof'];
      if (id is! String ||
          proof is! String ||
          proof.length != 44 ||
          !_queue.containsKey(id) ||
          _deliveryReceipts[id] == proof) {
        return;
      }
      final String? expected = _expectedDeliveryProofs[id];
      if (expected != null && proof != expected) return;
      _deliveryReceipts[id] = proof;
      await _persist();
      for (final String peer in _connectedPeers.toList()) {
        if (peer != fromEndpointId) {
          await _sendDeliveryReceipt(peer, id, proof);
        }
      }
      _notify();
      return;
    }

    if (kind == 'ack') {
      final MeshAckPacket ack = MeshAckPacket.fromJson(map);
      final MeshQueueItem? existing = _queue[ack.packetId];
      if (existing != null) {
        // Un vecino no autenticado solo prueba custodia; el recibo central
        // procede exclusivamente de una respuesta HTTPS de la RPC.
        const MeshPacketState nextState = MeshPacketState.custodyConfirmed;
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
      await _persist();
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

    if (await _tryOpenForSchool(envelope)) {
      await _persist();
    }
    final SimpleKeyPair? receiverKey =
        _schoolKeyPair ?? await _getBridgeKeyPair();
    if (receiverKey != null) {
      try {
        final MeshMinimalAlertPayload payload = await envelope.open(
          recipientKeyPair: receiverKey,
        );
        await _confirmRecipientDelivery(envelope, payload);
      } on Object {
        // Un puente sin clave no puede generar una prueba de entrega.
      }
    }

    await _sendAck(fromEndpointId, envelope.packetId, synced: false);

    if (relayEnvelope.ttl > 0) {
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
    if (remoteGateway != null) unawaited(syncPendingAsBridge());
  }

  Future<void> _sendAck(
    String endpointId,
    String packetId, {
    required bool synced,
  }) async {
    try {
      await transport.sendPayload(
        endpointId,
        MeshAckPacket(
          packetId: packetId,
          centrallySynced: synced,
        ).toWireBytes(),
      );
    } on Object {
      // Silencioso si el vecino ya se desconectó.
    }
  }

  Future<void> _persist() async {
    final Future<void> write = _persistWork.then((_) async {
      final LocalStorePersistence? store = _store;
      if (store == null) throw StateError('mesh_storage_unavailable');
      await store.save(<String, Object?>{
        'version': 1,
        'items': _queue.values
            .map((MeshQueueItem item) => item.toJson())
            .toList(growable: false),
        'seen': _seenPacketIds.toList(growable: false),
        'directorAlerts': _schoolAlerts.values
            .map((MeshMinimalAlertPayload item) => item.toJson())
            .toList(growable: false),
        'syncedOps': _syncedOperationIds.toList(growable: false),
        'outgoingPackets': Map<String, String>.from(_outgoingPackets),
        'expectedDeliveryProofs': Map<String, String>.from(
          _expectedDeliveryProofs,
        ),
        'deliveryReceipts': Map<String, String>.from(_deliveryReceipts),
      });
    });
    _persistWork = write.catchError((Object _) {});
    await write;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _bridgeRetry?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(transport.stopNode().catchError((Object _) {}));
    super.dispose();
  }
}
