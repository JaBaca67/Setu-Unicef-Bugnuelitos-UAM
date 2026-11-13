import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/mesh/mesh_envelope.dart';
import 'package:cureando_mobile/shared/mesh/mesh_relay_service.dart';
import 'package:cureando_mobile/shared/mesh/mesh_transport.dart';
import 'package:cureando_mobile/shared/remote/case_capability.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements LocalStorePersistence {
  Map<String, Object?>? _data;

  @override
  Future<Map<String, Object?>?> load() async => _data;

  @override
  Future<void> save(Map<String, Object?> value) async {
    _data = Map<String, Object?>.from(value);
  }
}

class _InMemoryMeshBus {
  final Map<String, _FakeMeshTransport> nodes = <String, _FakeMeshTransport>{};

  void connect(String a, String b) {
    final _FakeMeshTransport nodeA = nodes[a]!;
    final _FakeMeshTransport nodeB = nodes[b]!;
    nodeA._peers.add(b);
    nodeB._peers.add(a);
    nodeA._controller.add(MeshPeerConnected(b));
    nodeB._controller.add(MeshPeerConnected(a));
  }

  void deliver(String from, String to, Uint8List bytes) {
    nodes[to]?._controller.add(
      MeshPayloadReceived(endpointId: from, bytes: bytes),
    );
  }
}

class _FakeMeshTransport implements MeshTransport {
  _FakeMeshTransport(this.nodeId, this.bus) {
    bus.nodes[nodeId] = this;
  }

  final String nodeId;
  final _InMemoryMeshBus bus;
  final StreamController<MeshTransportEvent> _controller =
      StreamController<MeshTransportEvent>.broadcast();
  final Set<String> _peers = <String>{};
  bool bluetoothOn = true;

  @override
  Stream<MeshTransportEvent> get events => _controller.stream;

  @override
  Future<bool> isBluetoothEnabled() async => bluetoothOn;

  @override
  Future<bool> requestEnableBluetooth() async {
    bluetoothOn = true;
    return true;
  }

  @override
  Future<bool> hasRequiredPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> startNode({String endpointName = 'setu-node'}) async {}

  @override
  Future<void> stopNode() async {
    _peers.clear();
  }

  @override
  Future<void> sendPayload(String endpointId, Uint8List bytes) async {
    bus.deliver(nodeId, endpointId, bytes);
  }

  @override
  Future<int> broadcastPayload(Uint8List bytes) async {
    for (final String peer in _peers) {
      bus.deliver(nodeId, peer, bytes);
    }
    return _peers.length;
  }

  Future<void> dispose() => _controller.close();
}

class _FakeBridgeRemoteGateway implements SetuRemoteGateway {
  final List<Map<String, Object?>> submitted = <Map<String, Object?>>[];

  @override
  Future<RemoteSchoolInfo> resolvePublicSchool(String publicCode) =>
      throw UnimplementedError();

  @override
  Future<RemoteAlertReceipt> submitStudentAlert({
    required String clientOperationId,
    required String publicSchoolCode,
    required String situationType,
    required String studentRole,
    required String capabilityVerifierHash,
    String origin = 'online',
    bool involvesStaff = false,
    DateTime? declaredAt,
    String? narrativeText,
    String locationText = '',
    String approxDateText = '',
  }) async {
    submitted.add(<String, Object?>{
      'clientOperationId': clientOperationId,
      'publicSchoolCode': publicSchoolCode,
      'situationType': situationType,
      'studentRole': studentRole,
      'origin': origin,
      'capabilityVerifierHash': capabilityVerifierHash,
    });
    return RemoteAlertReceipt(
      caseId: '22222222-2222-4222-8222-000000000099',
      referenceCode: 'SETU-MESH-0001',
      institutionId: '11111111-1111-4111-8111-000000000024',
      origin: origin,
      receivedCentrallyAt: DateTime.utc(2026, 11, 12, 21, 0),
    );
  }

  @override
  Future<RemoteChatSession> getStudentChatSession({
    required String caseId,
    required String capabilityToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<RemoteChatMessage> sendStudentChatMessage({
    required String caseId,
    required String capabilityToken,
    required String clientOperationId,
    required String body,
  }) =>
      throw UnimplementedError();
}

void main() {
  test('MeshEnvelope cifra E2EE y solo el destinatario puede abrirlo', () async {
    final X25519 x25519 = X25519();
    final SimpleKeyPair bridgePair = await x25519.newKeyPair();
    final SimplePublicKey bridgePub = await bridgePair.extractPublicKey();
    final SimpleKeyPair relayerPair = await x25519.newKeyPair();

    final CaseCapability cap = await CaseCapability.generate();
    final MeshMinimalAlertPayload payload = MeshMinimalAlertPayload(
      clientOperationId: 'op_mesh_12345678',
      publicSchoolCode: 'AULA24',
      situationType: 'physical_bullying',
      studentRole: 'victim',
      capabilityVerifierHash: cap.verifierHash,
      declaredAt: DateTime.utc(2026, 11, 12, 21, 0),
    );

    final MeshEnvelope envelope = await MeshEnvelope.seal(
      payload,
      recipientPublicKeyBytes: bridgePub.bytes,
      ttl: 4,
    );
    final MeshEnvelope hopped = envelope.nextHop();
    expect(hopped.ttl, 3);
    expect(hopped.ciphertextB64, envelope.ciphertextB64);

    // Retransmisor sin la clave privada del puente falla al abrir.
    await expectLater(
      hopped.open(recipientKeyPair: relayerPair),
      throwsA(isA<Object>()),
    );

    // El puente sí puede descifrar la alerta mínima.
    final MeshMinimalAlertPayload opened =
        await hopped.open(recipientKeyPair: bridgePair);
    expect(opened.clientOperationId, 'op_mesh_12345678');
    expect(opened.publicSchoolCode, 'AULA24');
    expect(opened.situationType, 'physical_bullying');
  });

  test('Salto A -> B (retransmisor) -> C (puente) entrega alerta mesh sin leerla en B', () async {
    final X25519 x25519 = X25519();
    final SimpleKeyPair bridgePair = await x25519.newKeyPair();
    final SimplePublicKey bridgePub = await bridgePair.extractPublicKey();

    final _InMemoryMeshBus bus = _InMemoryMeshBus();
    final _FakeMeshTransport tA = _FakeMeshTransport('A', bus);
    final _FakeMeshTransport tB = _FakeMeshTransport('B', bus);
    final _FakeMeshTransport tC = _FakeMeshTransport('C', bus);

    final _FakeBridgeRemoteGateway bridgeRemote = _FakeBridgeRemoteGateway();

    final MeshRelayService nodeA = MeshRelayService(
      transport: tA,
      openStore: () async => _MemoryStore(),
    );
    final MeshRelayService nodeB = MeshRelayService(
      transport: tB,
      openStore: () async => _MemoryStore(),
    );
    final MeshRelayService nodeC = MeshRelayService(
      transport: tC,
      openStore: () async => _MemoryStore(),
      remoteGateway: bridgeRemote,
      bridgeKeyPair: bridgePair,
    );

    await nodeA.start(endpointName: 'A');
    await nodeB.start(endpointName: 'B');
    await nodeC.start(endpointName: 'C');

    // A solo conecta con B; B conecta con C (A y C no tienen enlace directo).
    bus.connect('A', 'B');
    bus.connect('B', 'C');

    final CaseCapability cap = await CaseCapability.generate();
    await nodeA.enqueueMinimalAlert(
      MeshMinimalAlertPayload(
        clientOperationId: 'op_hop_test_0001',
        publicSchoolCode: 'AULA24',
        situationType: 'cyberbullying',
        studentRole: 'solidarity_witness',
        capabilityVerifierHash: cap.verifierHash,
        declaredAt: DateTime.utc(2026, 11, 12, 21, 5),
      ),
      recipientPublicKeyBytes: bridgePub.bytes,
    );

    // Esperar que el bus entregue los eventos asíncronos entre A -> B -> C.
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(nodeA.items.length, 1);
    expect(nodeA.items.first.state, MeshPacketState.custodyConfirmed);

    expect(nodeB.items.length, 1);
    expect(nodeB.items.first.envelope.ttl, 4);

    expect(nodeC.items.length, 1);
    expect(nodeC.items.first.state, MeshPacketState.centrallySynced);
    expect(bridgeRemote.submitted.length, 1);
    expect(bridgeRemote.submitted.first['origin'], 'mesh');
    expect(bridgeRemote.submitted.first['publicSchoolCode'], 'AULA24');
    expect(bridgeRemote.submitted.first['situationType'], 'cyberbullying');

    await nodeA.stop();
    await nodeB.stop();
    await nodeC.stop();
    await tA.dispose();
    await tB.dispose();
    await tC.dispose();
  });

  test('SupportFlow solicita activar Bluetooth si falla envío sin internet', () async {
    final X25519 x25519 = X25519();
    final SimpleKeyPair bridgePair = await x25519.newKeyPair();
    final SimplePublicKey bridgePub = await bridgePair.extractPublicKey();

    final _InMemoryMeshBus bus = _InMemoryMeshBus();
    final _FakeMeshTransport transport = _FakeMeshTransport('E', bus)
      ..bluetoothOn = false;
    final MeshRelayService relay = MeshRelayService(
      transport: transport,
      openStore: () async => _MemoryStore(),
    );

    final _FailingRemoteGateway offlineRemote = _FailingRemoteGateway();
    final SupportFlow flow = SupportFlow(
      openStore: () async => _MemoryStore(),
      remote: offlineRemote,
      mesh: relay,
      meshRecipientPublicKey: bridgePub.bytes,
    );

    flow.selectSituation(Situation.talk);
    flow.selectParticipation(Participation.own);
    final bool saved = await flow.send();

    expect(saved, isTrue);
    expect(flow.delivery, AlertDelivery.pending);
    expect(flow.needsBluetoothForMesh, isTrue);
    expect(relay.items.length, 1);

    final bool enabled = await flow.ensureBluetoothForMesh();
    expect(enabled, isTrue);
    expect(flow.needsBluetoothForMesh, isFalse);
    expect(relay.isRunning, isTrue);

    await relay.stop();
    await transport.dispose();
  });
}

class _FailingRemoteGateway implements SetuRemoteGateway {
  @override
  Future<RemoteSchoolInfo> resolvePublicSchool(String publicCode) =>
      throw StateError('offline');

  @override
  Future<RemoteAlertReceipt> submitStudentAlert({
    required String clientOperationId,
    required String publicSchoolCode,
    required String situationType,
    required String studentRole,
    required String capabilityVerifierHash,
    String origin = 'online',
    bool involvesStaff = false,
    DateTime? declaredAt,
    String? narrativeText,
    String locationText = '',
    String approxDateText = '',
  }) =>
      throw StateError('offline');

  @override
  Future<RemoteChatSession> getStudentChatSession({
    required String caseId,
    required String capabilityToken,
  }) =>
      throw StateError('offline');

  @override
  Future<RemoteChatMessage> sendStudentChatMessage({
    required String caseId,
    required String capabilityToken,
    required String clientOperationId,
    required String body,
  }) =>
      throw StateError('offline');
}
