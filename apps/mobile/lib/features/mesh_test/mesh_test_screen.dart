import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/mesh/mesh_envelope.dart';
import '../../shared/mesh/mesh_relay_service.dart';
import '../../shared/mesh/mesh_transport.dart';
import '../../shared/remote/case_capability.dart';
import '../../shared/remote/setu_remote_gateway.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_card.dart';
import '../school_access/school_location.dart';

enum MeshTestRole { emitter, relayer, bridge }

/// Pantalla de prueba física de red mesh entre 2 o más celulares Android
/// usando Nearby Connections (`Strategy.P2P_CLUSTER`) y sobres E2EE.
class MeshTestScreen extends StatefulWidget {
  const MeshTestScreen({
    super.key,
    this.remoteGateway,
    this.transport,
  });

  final SetuRemoteGateway? remoteGateway;
  final MeshTransport? transport;

  @override
  State<MeshTestScreen> createState() => _MeshTestScreenState();
}

class _MeshTestScreenState extends State<MeshTestScreen> {
  static final X25519 _x25519 = X25519();

  late final MeshTransport _transport =
      widget.transport ?? NearbyMeshTransport();
  MeshRelayService? _relay;
  StreamSubscription<MeshTransportEvent>? _eventSub;

  MeshTestRole _role = MeshTestRole.emitter;
  bool _bluetoothEnabled = false;
  bool _permissionsGranted = false;
  bool _nodeRunning = false;
  SimpleKeyPair? _demoBridgeKeyPair;
  List<int>? _demoBridgePublicKey;
  final TextEditingController _pubKeyController = TextEditingController();
  final List<String> _logs = <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_initStateAsync());
  }

  Future<void> _initStateAsync() async {
    // Par X25519 determinístico SOLO para prueba física rápida entre 2+ teléfonos.
    final SimpleKeyPair pair = await _x25519.newKeyPairFromSeed(
      utf8.encode('setu-demo-mesh-bridge-key-v1-32b').sublist(0, 32),
    );
    final SimplePublicKey pub = await pair.extractPublicKey();
    _demoBridgeKeyPair = pair;
    _demoBridgePublicKey = pub.bytes;
    _pubKeyController.text = base64Encode(pub.bytes);

    await _rebuildRelay();
    await _refreshRadioStatus();
  }

  Future<void> _rebuildRelay() async {
    final bool wasRunning = _nodeRunning;
    if (wasRunning) {
      await _relay?.stop();
    }
    await _eventSub?.cancel();
    _relay?.removeListener(_onRelayChanged);
    _relay?.dispose();

    final MeshRelayService service = MeshRelayService(
      transport: _transport,
      remoteGateway:
          _role == MeshTestRole.bridge ? widget.remoteGateway : null,
      bridgeKeyPair: _role == MeshTestRole.bridge ? _demoBridgeKeyPair : null,
    );
    service.addListener(_onRelayChanged);
    _eventSub = _transport.events.listen(_onTransportEvent);
    _relay = service;
    if (mounted) {
      setState(() {
        _nodeRunning = false;
      });
    }
  }

  void _onRelayChanged() {
    if (mounted) setState(() {});
  }

  void _onTransportEvent(MeshTransportEvent event) {
    final String line = switch (event) {
      MeshPeerConnected(:final String endpointId) =>
        'Vecino conectado: $endpointId',
      MeshPeerDisconnected(:final String endpointId) =>
        'Vecino desconectado: $endpointId',
      MeshPayloadReceived(:final String endpointId, :final Uint8List bytes) =>
        'Paquete recibido de $endpointId (${bytes.length} B)',
      MeshStatusChanged(:final String state, :final String? message) =>
        message == null ? 'Estado nodo: $state' : 'Estado: $state ($message)',
    };
    _addLog(line);
  }

  void _addLog(String msg) {
    if (!mounted) return;
    final DateTime now = DateTime.now();
    final String hh = now.hour.toString().padLeft(2, '0');
    final String mm = now.minute.toString().padLeft(2, '0');
    final String ss = now.second.toString().padLeft(2, '0');
    setState(() {
      _logs.insert(0, '[$hh:$mm:$ss] $msg');
      if (_logs.length > 40) _logs.removeLast();
    });
  }

  Future<void> _refreshRadioStatus() async {
    try {
      final bool bt = await _transport.isBluetoothEnabled();
      final bool perms = await _transport.hasRequiredPermissions();
      if (mounted) {
        setState(() {
          _bluetoothEnabled = bt;
          _permissionsGranted = perms;
        });
      }
    } on Object catch (e) {
      _addLog('No se pudo consultar Bluetooth/permisos: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final bool granted = await _transport.requestPermissions();
      if (mounted) {
        setState(() => _permissionsGranted = granted);
      }
      _addLog(granted ? 'Permisos concedidos' : 'Permisos denegados');
    } on Object catch (e) {
      _addLog('Error solicitando permisos: $e');
    }
  }

  Future<void> _enableBluetooth() async {
    try {
      if (!_permissionsGranted) {
        await _requestPermissions();
      }
      final bool enabled = await _transport.requestEnableBluetooth();
      if (mounted) {
        setState(() => _bluetoothEnabled = enabled);
      }
      _addLog(enabled ? 'Bluetooth activado' : 'Bluetooth sigue apagado');
    } on Object catch (e) {
      _addLog('Error activando Bluetooth: $e');
    }
  }

  Future<void> _toggleNode() async {
    final MeshRelayService? relay = _relay;
    if (relay == null) return;
    if (_nodeRunning) {
      await relay.stop();
      if (mounted) setState(() => _nodeRunning = false);
      _addLog('Nodo detenido');
      return;
    }
    await _refreshRadioStatus();
    if (!_bluetoothEnabled) {
      final bool enabled = await _transport.requestEnableBluetooth();
      if (!enabled) {
        _addLog('Activá Bluetooth para iniciar la prueba mesh');
        return;
      }
      if (mounted) setState(() => _bluetoothEnabled = true);
    }
    try {
      final String label = switch (_role) {
        MeshTestRole.emitter => 'setu-emisor',
        MeshTestRole.relayer => 'setu-retransmisor',
        MeshTestRole.bridge => 'setu-puente',
      };
      final bool ok = await relay.start(endpointName: label);
      if (mounted) setState(() => _nodeRunning = ok);
      _addLog(ok ? 'Nodo iniciado como $label' : 'Faltan permisos Nearby');
    } on Object catch (e) {
      _addLog('Error iniciando nodo: $e');
    }
  }

  Future<void> _sendTestAlert() async {
    final MeshRelayService? relay = _relay;
    if (relay == null) return;
    List<int>? recipientKey = _demoBridgePublicKey;
    final String rawB64 = _pubKeyController.text.trim();
    if (rawB64.isNotEmpty) {
      try {
        recipientKey = base64Decode(rawB64);
      } on Object {
        _addLog('Clave pública Base64 inválida');
        return;
      }
    }
    if (recipientKey == null || recipientKey.length != 32) {
      _addLog('Se requiere clave X25519 de 32 bytes');
      return;
    }
    final CaseCapability cap = await CaseCapability.generate();
    final String opId = CaseCapability.newOperationId(prefix: 'meshtest');
    final MeshEnvelope env = await relay.enqueueMinimalAlert(
      MeshMinimalAlertPayload(
        clientOperationId: opId,
        publicSchoolCode: demoSchoolCode,
        situationType: 'need_to_talk',
        studentRole: 'victim',
        capabilityVerifierHash: cap.verifierHash,
        declaredAt: DateTime.now().toUtc(),
      ),
      recipientPublicKeyBytes: recipientKey,
    );
    _addLog('Alerta cifrada encolada (packet=${env.packetId.substring(0, 8)}...)');
  }

  Future<void> _syncAsBridge() async {
    final MeshRelayService? relay = _relay;
    if (relay == null) return;
    final int count = await relay.syncPendingAsBridge();
    _addLog('Puente sincronizó $count sobre(s) a Supabase');
  }

  @override
  void dispose() {
    unawaited(_eventSub?.cancel());
    _relay?.removeListener(_onRelayChanged);
    _relay?.dispose();
    _pubKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MeshRelayService? relay = _relay;
    final List<MeshQueueItem> items = relay?.items ?? const <MeshQueueItem>[];
    final int peers = relay?.connectedPeerCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de red Mesh'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar estado radio',
            onPressed: _refreshRadioStatus,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SetuCard(
            color: const Color(0xFFEAF2FF),
            borderColor: CureandoTheme.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Estado de radios y permisos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bluetooth: ${_bluetoothEnabled ? "Activado" : "Apagado"} · '
                  'Permisos Nearby: ${_permissionsGranted ? "OK" : "Pendientes"} · '
                  'Vecinos: $peers',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (!_permissionsGranted)
                      OutlinedButton.icon(
                        onPressed: _requestPermissions,
                        icon: const Icon(Icons.security_rounded),
                        label: const Text('Dar permisos'),
                      ),
                    if (!_bluetoothEnabled)
                      FilledButton.icon(
                        onPressed: _enableBluetooth,
                        icon: const Icon(Icons.bluetooth_rounded),
                        label: const Text('Activar Bluetooth'),
                      ),
                    FilledButton.icon(
                      onPressed: _toggleNode,
                      icon: Icon(
                        _nodeRunning
                            ? Icons.stop_circle_outlined
                            : Icons.wifi_tethering_rounded,
                      ),
                      label: Text(_nodeRunning ? 'Detener nodo' : 'Iniciar nodo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SetuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Rol de este teléfono en la prueba',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SegmentedButton<MeshTestRole>(
                  segments: const <ButtonSegment<MeshTestRole>>[
                    ButtonSegment<MeshTestRole>(
                      value: MeshTestRole.emitter,
                      label: Text('Emisor'),
                    ),
                    ButtonSegment<MeshTestRole>(
                      value: MeshTestRole.relayer,
                      label: Text('Retransmisor'),
                    ),
                    ButtonSegment<MeshTestRole>(
                      value: MeshTestRole.bridge,
                      label: Text('Puente'),
                    ),
                  ],
                  selected: <MeshTestRole>{_role},
                  onSelectionChanged: (Set<MeshTestRole> selection) async {
                    setState(() => _role = selection.first);
                    await _rebuildRelay();
                  },
                ),
                const SizedBox(height: 12),
                if (_role == MeshTestRole.emitter) ...<Widget>[
                  TextField(
                    controller: _pubKeyController,
                    decoration: InputDecoration(
                      labelText: 'Clave pública X25519 del puente (demo)',
                      suffixIcon: IconButton(
                        tooltip: 'Copiar clave',
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _pubKeyController.text),
                          );
                          _addLog('Clave pública copiada');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _sendTestAlert,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Enviar alerta de prueba (AULA24)'),
                  ),
                ],
                if (_role == MeshTestRole.relayer)
                  const Text(
                    'Modo Retransmisor: recibe sobres cifrados opacos, los guarda en cola y los reenvía sin poder descifrar su contenido.',
                  ),
                if (_role == MeshTestRole.bridge) ...<Widget>[
                  Text(
                    widget.remoteGateway == null
                        ? 'Modo Puente (sin Supabase configurado): descifra sobres locales de prueba.'
                        : 'Modo Puente (con Supabase): descifra sobres y los sube con origin=mesh.',
                  ),
                  const SizedBox(height: 10),
                  if (widget.remoteGateway != null)
                    FilledButton.icon(
                      onPressed: _syncAsBridge,
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text('Sincronizar a Supabase'),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SetuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Sobres en cola (${items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text('Sin sobres en cola todavía.')
                else
                  for (final MeshQueueItem item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${item.envelope.packetId.substring(0, 8)}… · '
                        'TTL ${item.envelope.ttl} · ${item.state.name}',
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SetuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Registro de saltos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_logs.isEmpty)
                  const Text('Iniciá el nodo en 2 o más teléfonos para probar.')
                else
                  for (final String line in _logs)
                    Text(line, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
