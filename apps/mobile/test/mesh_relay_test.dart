import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cureando_mobile/features/staff/demo_staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_inbox_screens.dart';
import 'package:cureando_mobile/features/support/support_backend.dart';
import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/mesh/mesh_bridge_keys.dart';
import 'package:cureando_mobile/shared/mesh/mesh_envelope.dart';
import 'package:cureando_mobile/shared/mesh/mesh_relay_service.dart';
import 'package:cureando_mobile/shared/mesh/mesh_recipient_directory.dart';
import 'package:cureando_mobile/shared/mesh/mesh_transport.dart';
import 'package:cureando_mobile/shared/remote/case_capability.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_gateway.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_models.dart';
import 'package:flutter/material.dart';
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
  bool permissionsGranted = true;
  final List<String> calls = <String>[];

  @override
  Stream<MeshTransportEvent> get events => _controller.stream;

  @override
  Future<bool> isBluetoothEnabled() async => bluetoothOn;

  @override
  Future<bool> requestEnableBluetooth() async {
    calls.add('requestEnableBluetooth');
    if (!permissionsGranted) {
      throw StateError('missing_bluetooth_connect');
    }
    bluetoothOn = true;
    return true;
  }

  @override
  Future<bool> hasRequiredPermissions() async => permissionsGranted;

  @override
  Future<bool> requestPermissions() async {
    calls.add('requestPermissions');
    permissionsGranted = true;
    return true;
  }

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
  Future<StudentAlertReceipt> submitStudentAlert(
    StudentAlertSubmission submission,
  ) async {
    submitted.add(<String, Object?>{
      'clientOperationId': submission.clientOperationId,
      'publicSchoolCode': submission.publicSchoolCode,
      'situationType': submission.situationType.wireValue,
      'studentRole': submission.studentRole.wireValue,
      'origin': submission.origin.wireValue,
      'involvesStaff': submission.involvesStaff,
      'capabilityVerifierHash': submission.capabilityVerifierHash,
    });
    return StudentAlertReceipt(
      caseId: '22222222-2222-4222-8222-000000000099',
      referenceCode: 'SETU-MESH-0001',
      institutionId: '11111111-1111-4111-8111-000000000024',
      origin: submission.origin,
      receivedCentrallyAt: DateTime.utc(2026, 11, 12, 21, 0),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryVault implements KeyVault {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String encodedKey) async {
    value = encodedKey;
  }
}

class _CustodyGateway extends _FakeBridgeRemoteGateway {
  _CustodyGateway(this.custody, {this.userId});
  final Map<String, Map<String, Object?>> custody;
  final String? userId;
  String? publicKey;
  String? recipientKeyId;
  bool online = true;
  @override
  String? get currentStaffUserId => userId;
  @override
  Future<void> registerMeshRecipient({
    String? publicSchoolCode,
    required String publicKeyBase64,
  }) async {
    publicKey = publicKeyBase64;
    recipientKeyId = (await Sha256().hash(
      base64Decode(publicKeyBase64),
    )).bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<List<String>> listMeshRecipientPublicKeys({
    required String publicSchoolCode,
    required bool involvesStaff,
  }) async {
    if (!online) throw StateError('offline');
    return <String>[?publicKey];
  }

  @override
  Future<void> relayMeshEnvelope(Map<String, Object?> envelope) async {
    if (!online) throw StateError('offline');
    custody[envelope['id']! as String] = envelope;
  }

  @override
  Future<List<Map<String, Object?>>> listMyMeshEnvelopes() async => custody
      .values
      .where(
        (Map<String, Object?> env) => env['recipient_key'] == recipientKeyId,
      )
      .toList();
  @override
  Future<void> completeMeshEnvelope(
    String packetId,
    String clientOperationId,
  ) async {
    custody.remove(packetId);
  }
}

void main() {
  test(
    'Puente sin clave sube solo ciphertext; el destinatario staff recupera y registra el caso',
    () async {
      final Map<String, Map<String, Object?>> custody =
          <String, Map<String, Object?>>{};
      final _CustodyGateway receiverRemote = _CustodyGateway(
        custody,
        userId: 'staff-ficticio',
      );
      final _MemoryVault vault = _MemoryVault();
      final _MemoryStore cache = _MemoryStore();
      final MeshRecipientDirectory directory = MeshRecipientDirectory(
        receiverRemote,
        vaultForUser: (_) => vault,
        openCache: () async => cache,
      );
      final SimpleKeyPair receiverKey = (await directory.registerReceiver(
        'AULA24',
      ))!;
      final List<List<int>> keys = await directory.recipients('AULA24', false);
      receiverRemote.online = false;
      expect(await directory.recipients('AULA24', false), keys);
      // Reabrir el receptor conserva su clave, sin incluirla en código o red.
      final MeshRecipientDirectory reopened = MeshRecipientDirectory(
        receiverRemote,
        vaultForUser: (_) => vault,
        openCache: () async => cache,
      );
      expect(
        (await (await reopened.registerReceiver(
          'AULA24',
        ))!.extractPublicKey()).bytes,
        (await receiverKey.extractPublicKey()).bytes,
      );

      final _InMemoryMeshBus bus = _InMemoryMeshBus();
      final _FakeMeshTransport emitterTransport = _FakeMeshTransport(
        'emisor',
        bus,
      );
      final _FakeMeshTransport bridgeTransport = _FakeMeshTransport(
        'puente',
        bus,
      );
      final _FakeMeshTransport receiverTransport = _FakeMeshTransport(
        'mesa',
        bus,
      );
      final _CustodyGateway bridgeRemote = _CustodyGateway(custody)
        ..online = false;
      final MeshRelayService emitter = MeshRelayService(
        transport: emitterTransport,
        openStore: () async => _MemoryStore(),
      );
      final MeshRelayService bridge = MeshRelayService(
        transport: bridgeTransport,
        openStore: () async => _MemoryStore(),
        remoteGateway: bridgeRemote,
      );
      final MeshRelayService receiver = MeshRelayService(
        transport: receiverTransport,
        openStore: () async => _MemoryStore(),
        remoteGateway: receiverRemote,
        recipientDirectory: directory,
      );
      addTearDown(() async {
        for (final MeshRelayService relay in <MeshRelayService>[
          emitter,
          bridge,
          receiver,
        ]) {
          await relay.stop();
          relay.dispose();
        }
        for (final _FakeMeshTransport transport in <_FakeMeshTransport>[
          emitterTransport,
          bridgeTransport,
          receiverTransport,
        ]) {
          await transport.dispose();
        }
      });
      await emitter.start();
      await bridge.start();
      bus.connect('emisor', 'puente');
      final CaseCapability capability = await CaseCapability.generate();
      final MeshMinimalAlertPayload alert = MeshMinimalAlertPayload(
        clientOperationId: 'op_custodia_ficticia_001',
        publicSchoolCode: 'AULA24',
        situationType: 'social_bullying',
        studentRole: 'victim',
        declaredAt: DateTime.utc(2026, 11, 16),
        capabilityVerifierHash: capability.verifierHash,
      );
      final MeshEnvelope envelope = await emitter.enqueueMinimalAlert(
        alert,
        recipientPublicKeyBytes: keys.single,
      );
      // Reintentar no crea otro paquete cifrado para el mismo destinatario.
      expect(
        (await emitter.enqueueMinimalAlert(
          alert,
          recipientPublicKeyBytes: keys.single,
        )).packetId,
        envelope.packetId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(custody, isEmpty);
      expect(bridgeRemote.submitted, isEmpty);
      bridgeRemote.online = true;
      expect(
        await bridge.syncPendingAsBridge(),
        0,
      ); // Custodia aún no es un caso.
      expect(bridge.items.single.state, MeshPacketState.serverCustody);
      expect(custody, hasLength(1));
      expect(jsonEncode(custody), isNot(contains('AULA24')));
      expect(jsonEncode(custody), isNot(contains(capability.verifierHash)));
      expect(bridgeRemote.submitted, isEmpty);
      receiverRemote.online = true;
      expect(await receiver.syncPendingAsBridge(), 1);
      expect(
        receiverRemote.submitted.single['clientOperationId'],
        alert.clientOperationId,
      );
      expect(receiverRemote.submitted.single['publicSchoolCode'], 'AULA24');
      expect(receiverRemote.submitted.single['origin'], 'mesh');
      expect(custody, isEmpty);
      expect(await receiver.syncPendingAsBridge(), 0);
      expect(receiverRemote.submitted, hasLength(1));
    },
  );

  test('Un acuse Nearby falsificado no equivale a recepción central', () async {
    final _InMemoryMeshBus bus = _InMemoryMeshBus();
    final _FakeMeshTransport transport = _FakeMeshTransport('emisor-ack', bus);
    final MeshRelayService relay = MeshRelayService(
      transport: transport,
      openStore: () async => _MemoryStore(),
    );
    await relay.start();
    final CaseCapability capability = await CaseCapability.generate();
    final MeshEnvelope envelope = await relay.enqueueMinimalAlert(
      MeshMinimalAlertPayload(
        clientOperationId: 'op_ack_ficticio_001',
        publicSchoolCode: 'AULA24',
        situationType: 'need_to_talk',
        studentRole: 'victim',
        capabilityVerifierHash: capability.verifierHash,
        declaredAt: DateTime.utc(2026, 11, 16),
      ),
      recipientPublicKeyBytes:
          (await (await X25519().newKeyPair()).extractPublicKey()).bytes,
    );
    bus.deliver(
      'vecino',
      'emisor-ack',
      MeshAckPacket(
        packetId: envelope.packetId,
        centrallySynced: true,
      ).toWireBytes(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(relay.items.single.state, MeshPacketState.custodyConfirmed);
    expect(relay.isOperationSynced('op_ack_ficticio_001'), isFalse);
    await relay.stop();
    relay.dispose();
    await transport.dispose();
  });

  test(
    'MeshEnvelope cifra E2EE y solo el destinatario puede abrirlo',
    () async {
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
      final MeshMinimalAlertPayload opened = await hopped.open(
        recipientKeyPair: bridgePair,
      );
      expect(opened.clientOperationId, 'op_mesh_12345678');
      expect(opened.publicSchoolCode, 'AULA24');
      expect(opened.situationType, 'physical_bullying');
    },
  );

  test(
    'Salto A -> B (retransmisor) -> C (puente) entrega alerta mesh sin leerla en B',
    () async {
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
    },
  );

  test(
    'SupportFlow solicita activar Bluetooth si falla envío sin internet',
    () async {
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

      final _FailingSupportBackend offlineBackend = _FailingSupportBackend();
      final SupportFlow flow = SupportFlow(
        openStore: () async => _MemoryStore(),
        backend: offlineBackend,
        mesh: relay,
        meshRecipientPublicKey: bridgePub.bytes,
      );

      flow.selectSituation(Situation.talk);
      flow.selectParticipation(Participation.own);
      final bool saved = await flow.send();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(saved, isTrue);
      expect(flow.delivery, AlertDelivery.pending);
      expect(flow.needsBluetoothForMesh, isTrue);
      expect(relay.items.length, 2);

      final bool enabled = await flow.ensureBluetoothForMesh();
      expect(enabled, isTrue);
      expect(flow.needsBluetoothForMesh, isFalse);
      expect(relay.isRunning, isTrue);

      await relay.stop();
      await transport.dispose();
    },
  );

  test(
    'MeshRelayService conserva la cola cifrada tras cerrar y reabrir',
    () async {
      final _MemoryStore sharedStore = _MemoryStore();
      final _InMemoryMeshBus bus = _InMemoryMeshBus();
      final _FakeMeshTransport transport1 = _FakeMeshTransport('node1', bus);
      final MeshRelayService relay1 = MeshRelayService(
        transport: transport1,
        openStore: () async => sharedStore,
      );
      final List<int> pubKey = await MeshBridgeKeys.resolvePublicKeyBytes();
      final CaseCapability cap = await CaseCapability.generate();
      final MeshEnvelope env = await relay1.enqueueMinimalAlert(
        MeshMinimalAlertPayload(
          clientOperationId: CaseCapability.newOperationId(prefix: 'persist'),
          publicSchoolCode: 'AULA24',
          situationType: 'need_to_talk',
          studentRole: 'victim',
          capabilityVerifierHash: cap.verifierHash,
          declaredAt: DateTime.utc(2026, 11, 13, 12),
        ),
        recipientPublicKeyBytes: pubKey,
      );
      expect(relay1.items.length, 1);
      relay1.dispose();
      await transport1.dispose();

      final _FakeMeshTransport transport2 = _FakeMeshTransport('node2', bus);
      final MeshRelayService relay2 = MeshRelayService(
        transport: transport2,
        openStore: () async => sharedStore,
      );
      await relay2.open();
      expect(relay2.items.length, 1);
      expect(relay2.items.first.envelope.packetId, env.packetId);
      expect(relay2.items.first.state, MeshPacketState.queued);

      relay2.dispose();
      await transport2.dispose();
    },
  );

  test(
    'SupportFlow resuelve clave del puente asíncronamente sin internet',
    () async {
      final _InMemoryMeshBus bus = _InMemoryMeshBus();
      final _FakeMeshTransport transport = _FakeMeshTransport('emitter', bus)
        ..bluetoothOn = false;
      final MeshRelayService relay = MeshRelayService(
        transport: transport,
        openStore: () async => _MemoryStore(),
      );
      final SupportFlow flow = SupportFlow(
        openStore: () async => _MemoryStore(),
        backend: _FailingSupportBackend(),
        mesh: relay,
        resolveMeshRecipientPublicKey: MeshBridgeKeys.resolvePublicKeyBytes,
      );

      flow.selectSituation(Situation.talk);
      flow.selectParticipation(Participation.own);
      final bool saved = await flow.send();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(saved, isTrue);
      expect(flow.needsBluetoothForMesh, isTrue);
      expect(relay.items.length, 2);

      final bool btOk = await flow.ensureBluetoothForMesh();
      expect(btOk, isTrue);
      expect(flow.needsBluetoothForMesh, isFalse);
      expect(relay.isRunning, isTrue);

      await relay.stop();
      await transport.dispose();
    },
  );

  test(
    'Dirección recibe alerta mínima por mesh sin internet y la omite si involucra personal',
    () async {
      final _InMemoryMeshBus bus = _InMemoryMeshBus();
      final _FakeMeshTransport tStudent = _FakeMeshTransport('student', bus);
      final _FakeMeshTransport tDirector = _FakeMeshTransport('director', bus);

      final MeshRelayService studentRelay = MeshRelayService(
        transport: tStudent,
        openStore: () async => _MemoryStore(),
      );
      final MeshRelayService directorRelay = MeshRelayService(
        transport: tDirector,
        openStore: () async => _MemoryStore(),
      );
      await directorRelay.setDirectorSchoolContext(
        schoolCode: 'AULA24',
        schoolKeyPair: await MeshSchoolKeys.demoSchoolKeyPair('AULA24'),
      );
      await studentRelay.start(endpointName: 'student');
      await directorRelay.start(endpointName: 'director');
      bus.connect('student', 'director');

      final SupportFlow flow = SupportFlow(
        openStore: () async => _MemoryStore(),
        backend: _FailingSupportBackend(),
        schoolCode: 'AULA24',
        mesh: studentRelay,
        resolveMeshRecipientPublicKey: MeshBridgeKeys.resolvePublicKeyBytes,
      );

      // Caso 1: no involucra personal -> Dirección recibe alerta mínima local.
      flow.selectSituation(Situation.verbal);
      flow.selectParticipation(Participation.own);
      flow.details = 'Relato privado que no debe llegar a Dirección';
      expect(await flow.send(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(directorRelay.directorAlerts, hasLength(1));
      expect(directorRelay.directorAlerts.single.publicSchoolCode, 'AULA24');
      expect(
        directorRelay.directorAlerts.single.situationType,
        'verbal_bullying',
      );

      // Caso 2: involucra personal -> no se genera sobre para Dirección.
      flow.selectSituation(Situation.physical);
      flow.selectParticipation(Participation.witness);
      flow.setInvolvesStaff(true);
      expect(await flow.send(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(directorRelay.directorAlerts, hasLength(1));

      await studentRelay.stop();
      await directorRelay.stop();
      await tStudent.dispose();
      await tDirector.dispose();
    },
  );

  test(
    'ensureReadyAndStart pide permisos antes de activar Bluetooth',
    () async {
      final _InMemoryMeshBus bus = _InMemoryMeshBus();
      final _FakeMeshTransport transport = _FakeMeshTransport('node', bus)
        ..bluetoothOn = false
        ..permissionsGranted = false;
      final MeshRelayService relay = MeshRelayService(
        transport: transport,
        openStore: () async => _MemoryStore(),
      );

      final bool started = await relay.ensureReadyAndStart(
        endpointName: 'mesa-AULA24',
      );
      expect(started, isTrue);
      expect(relay.isRunning, isTrue);
      expect(transport.calls.take(2).toList(), <String>[
        'requestPermissions',
        'requestEnableBluetooth',
      ]);

      await relay.stop();
      await transport.dispose();
    },
  );

  test(
    'Puente con resolveBridgeKeyPair sube alerta mesh (incluso involvesStaff) y la marca sincronizada',
    () async {
      final _InMemoryMeshBus bus = _InMemoryMeshBus();
      final _FakeMeshTransport tStudent = _FakeMeshTransport('student', bus);
      final _FakeMeshTransport tPsychologist = _FakeMeshTransport('psych', bus);
      final _FakeBridgeRemoteGateway remote = _FakeBridgeRemoteGateway();

      final MeshRelayService studentRelay = MeshRelayService(
        transport: tStudent,
        openStore: () async => _MemoryStore(),
      );
      final MeshRelayService psychRelay = MeshRelayService(
        transport: tPsychologist,
        openStore: () async => _MemoryStore(),
        remoteGateway: remote,
        resolveBridgeKeyPair: MeshBridgeKeys.resolveBridgeKeyPair,
      );
      await psychRelay.setSchoolContext(
        schoolCode: 'AULA24',
        schoolKeyPair: await MeshSchoolKeys.demoSchoolKeyPair('AULA24'),
      );
      await studentRelay.start(endpointName: 'student');
      await psychRelay.start(endpointName: 'mesa-AULA24');
      bus.connect('student', 'psych');

      final SupportFlow flow = SupportFlow(
        openStore: () async => _MemoryStore(),
        backend: _FailingSupportBackend(),
        schoolCode: 'AULA24',
        mesh: studentRelay,
        resolveMeshRecipientPublicKey: MeshBridgeKeys.resolvePublicKeyBytes,
      );

      flow.selectSituation(Situation.verbal);
      flow.selectParticipation(Participation.own);
      expect(await flow.send(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(remote.submitted, hasLength(1));
      expect(remote.submitted.single['origin'], 'mesh');
      expect(remote.submitted.single['publicSchoolCode'], 'AULA24');
      expect(psychRelay.syncedCount, 1);
      final String opId =
          remote.submitted.single['clientOperationId']! as String;
      expect(psychRelay.isOperationSynced(opId), isTrue);

      // Una vez sincronizada al servidor, no queda duplicada como local offline.
      expect(
        filterUnsyncedSchoolMeshAlerts(
          relay: psychRelay,
          schoolCode: 'AULA24',
          remoteCases: const <StaffCaseSummary>[],
        ),
        isEmpty,
      );

      await studentRelay.stop();
      await psychRelay.stop();
      await tStudent.dispose();
      await tPsychologist.dispose();
    },
  );

  testWidgets(
    'Mesa de Escucha recibe alerta mínima local por mesh sin internet y omite involvesStaff',
    (WidgetTester tester) async {
      final _InMemoryMeshBus bus = _InMemoryMeshBus();
      final _FakeMeshTransport tStudent = _FakeMeshTransport('student', bus);
      final _FakeMeshTransport tPsychologist = _FakeMeshTransport('psych', bus);

      final MeshRelayService studentRelay = MeshRelayService(
        transport: tStudent,
        openStore: () async => _MemoryStore(),
      );
      final MeshRelayService psychRelay = MeshRelayService(
        transport: tPsychologist,
        openStore: () async => _MemoryStore(),
      );

      final DemoStaffBackend backend = DemoStaffBackend();
      await backend.signIn(
        email: 'escucha.demo@example.org',
        password: DemoStaffBackend.demoPassword,
      );
      final StaffSession session = StaffSession(backend);
      await session.refresh();
      session.choose(
        session.memberships.firstWhere(
          (StaffMembershipScope s) => s.institutionPublicCode == 'AULA24',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DeskInboxScreen(session: session, meshRelay: psychRelay),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Red mesh activa · escuchando alertas sin internet'),
        findsOneWidget,
      );

      await studentRelay.start(endpointName: 'student');
      bus.connect('student', 'psych');

      final SupportFlow flow = SupportFlow(
        openStore: () async => _MemoryStore(),
        backend: _FailingSupportBackend(),
        schoolCode: 'AULA24',
        mesh: studentRelay,
        resolveMeshRecipientPublicKey: MeshBridgeKeys.resolvePublicKeyBytes,
      );

      // Alerta normal -> aparece en «Por tomar» como aviso local offline.
      flow.selectSituation(Situation.social);
      flow.selectParticipation(Participation.own);
      await tester.runAsync(() async {
        expect(await flow.send(), isTrue);
      });
      for (int i = 0; i < 100 && psychRelay.schoolAlerts.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(psychRelay.schoolAlerts, hasLength(1));
      await tester.tap(find.textContaining('Por tomar').first);
      await tester.pumpAndSettle();
      expect(find.text('Red mesh · Sin internet'), findsOneWidget);
      expect(find.text('Ver aviso local'), findsOneWidget);
      expect(find.textContaining('Acoso social'), findsOneWidget);

      // Alerta que involucra personal -> no se muestra localmente al psicólogo de planta.
      flow.selectSituation(Situation.physical);
      flow.selectParticipation(Participation.witness);
      flow.setInvolvesStaff(true);
      await tester.runAsync(() async {
        expect(await flow.send(), isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(find.text('Red mesh · Sin internet'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      flow.dispose();
      await tester.runAsync(() async {
        await studentRelay.stop();
        await psychRelay.stop();
        await tStudent.dispose();
        await tPsychologist.dispose();
      });
      session.dispose();
    },
  );
}

class _FailingSupportBackend implements SupportBackend {
  @override
  Listenable? get changes => null;

  @override
  Duration? get pollInterval => null;

  @override
  Future<String> submitAlert(AlertOutbox alert) => throw StateError('offline');

  @override
  Future<ChatSnapshot> chatSession({
    required String caseId,
    required String capabilityToken,
  }) => throw StateError('offline');

  @override
  Future<void> sendMessage({
    required String caseId,
    required String capabilityToken,
    required String operationId,
    required String body,
  }) => throw StateError('offline');

  @override
  void dispose() {}
}
