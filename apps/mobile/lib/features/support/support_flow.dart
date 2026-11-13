import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/local/encrypted_local_store.dart';
import '../../shared/mesh/mesh_envelope.dart';
import '../../shared/mesh/mesh_relay_service.dart';
import '../../shared/remote/case_capability.dart';
import '../../shared/remote/setu_remote_gateway.dart';
import '../../shared/theme/app_theme.dart';
import '../school_access/school_location.dart';

/// Situaciones que el estudiante puede elegir al enviar una alerta. El nivel
/// de alerta lo asigna después una persona profesional, nunca la app.
enum Situation {
  physical(
    'Acoso físico',
    Icons.back_hand_rounded,
    Color(0xFFF5B800),
    'physical_bullying',
  ),
  verbal(
    'Acoso verbal',
    Icons.sms_rounded,
    CureandoTheme.pink,
    'verbal_bullying',
  ),
  social(
    'Acoso social',
    Icons.group_rounded,
    CureandoTheme.green,
    'social_bullying',
  ),
  cyber(
    'Ciberacoso',
    Icons.laptop_mac_rounded,
    CureandoTheme.blue,
    'cyberbullying',
  ),
  sexual(
    'Violencia sexual',
    Icons.gpp_maybe_rounded,
    CureandoTheme.pink,
    'sexual_violence',
  ),
  talk(
    'Necesito hablar',
    Icons.favorite_rounded,
    CureandoTheme.blue,
    'need_to_talk',
  );

  const Situation(this.label, this.icon, this.color, this.rpcValue);
  final String label;
  final IconData icon;
  final Color color;
  final String rpcValue;
}

enum Participation {
  own('Me pasó a mí', 'victim'),
  witness('Lo vi o supe de alguien', 'solidarity_witness');

  const Participation(this.label, this.rpcValue);
  final String label;
  final String rpcValue;
}

/// Entrega de la alerta. «Recibida» es el acuse de la plataforma: no dice
/// nada sobre el avance del caso.
enum AlertDelivery { none, pending, received }

@immutable
class ChatMessage {
  const ChatMessage(this.text, {required this.fromStudent});
  final String text;
  final bool fromStudent;
}

/// Estado del recorrido «Pedir apoyo» (pantallas 1–8).
///
/// Cuando [remote] es nulo opera en modo demostración local con temporizadores
/// ([ackDelay], [teamDelay]). Cuando [remote] está configurado envía la alerta
/// y consulta el chat humano contra Supabase (ADR 0016), conservando respaldo
/// cifrado en el dispositivo (y envío por [mesh] si está disponible) si no hay
/// conexión. Solo deben usarse datos ficticios.
class SupportFlow extends ChangeNotifier {
  SupportFlow({
    Future<LocalStorePersistence> Function()? openStore,
    this.remote,
    this.mesh,
    this.meshRecipientPublicKey,
    this.schoolCode = demoSchoolCode,
    this.ackDelay = const Duration(seconds: 3),
    this.teamDelay = const Duration(seconds: 8),
  }) : _openStore = openStore ?? _onDevice;

  static const String teamGreeting = 'Hola. Soy parte del equipo de escucha.';
  static const int maxDetails = 1000;

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_support_alert.enc',
        keyName: 'setu.support.master.v1',
      );

  final Future<LocalStorePersistence> Function() _openStore;
  final SetuRemoteGateway? remote;
  final MeshRelayService? mesh;
  final List<int>? meshRecipientPublicKey;
  final String schoolCode;
  final Duration ackDelay;
  final Duration teamDelay;
  LocalStorePersistence? _store;
  Future<void>? _opening;
  Timer? _timer;
  bool _disposed = false;
  Map<String, Object?>? _alert;
  final List<ChatMessage> _sent = <ChatMessage>[];
  List<ChatMessage>? _remoteMessages;

  String? _caseId;
  String? get caseId => _caseId;

  String? _referenceCode;
  String? get referenceCode => _referenceCode;

  String? _capabilityToken;
  String? _clientOperationId;

  Situation? situation;
  Participation? participation;
  String details = '';

  AlertDelivery _delivery = AlertDelivery.none;
  AlertDelivery get delivery => _delivery;

  bool _chatAvailable = false;
  bool get chatAvailable => _chatAvailable;

  bool _needsBluetoothForMesh = false;
  bool get needsBluetoothForMesh => _needsBluetoothForMesh;

  List<ChatMessage> get messages {
    final List<ChatMessage>? synced = _remoteMessages;
    if (synced != null) {
      return List<ChatMessage>.unmodifiable(synced);
    }
    return <ChatMessage>[
      if (_chatAvailable) const ChatMessage(teamGreeting, fromStudent: false),
      ..._sent,
    ];
  }

  bool get studentWrote => messages.any((ChatMessage m) => m.fromStudent);

  Future<void> open() =>
      _store != null ? Future<void>.value() : _opening ??= _load();

  Future<void> _load() async {
    try {
      final LocalStorePersistence store =
          await Future<LocalStorePersistence>.sync(_openStore);
      final Map<String, Object?>? data = await store.load();
      if (data != null && data['version'] == 1) {
        _alert = (data['alert'] as Map<Object?, Object?>?)
            ?.cast<String, Object?>();
        _chatAvailable = data['chatAvailable'] == true;
        _caseId = data['caseId'] as String?;
        _referenceCode = data['referenceCode'] as String?;
        _capabilityToken = data['capabilityToken'] as String?;
        _clientOperationId = data['clientOperationId'] as String?;
        if (_alert != null) {
          _delivery = data['received'] == true
              ? AlertDelivery.received
              : AlertDelivery.pending;
        }
      }
      _store = store;
      if (remote == null) {
        _schedule();
      } else if (_caseId != null && _capabilityToken != null) {
        unawaited(refreshRemoteChat());
      }
    } on Object {
      // Sin almacén no se puede guardar: [send] lo informa sin falso éxito.
    } finally {
      _opening = null;
      _notify();
    }
  }

  void selectSituation(Situation value) {
    situation = value;
    _notify();
  }

  void selectParticipation(Participation value) {
    participation = value;
    _notify();
  }

  /// Guarda la alerta en el teléfono y, si [remote] está configurado, la envía
  /// de forma idempotente al backend. Devuelve false si no pudo guardarse.
  Future<bool> send() async {
    final Situation? type = situation;
    final Participation? role = participation;
    if (type == null || role == null) return false;
    await open();
    final LocalStorePersistence? store = _store;
    if (store == null) return false;
    final String cleanDetails = details.trim();
    final Map<String, Object?> alert = <String, Object?>{
      'situation': type.name,
      'participation': role.name,
      'details': cleanDetails,
    };

    String? opId;
    CaseCapability? capability;
    if (remote != null) {
      opId = CaseCapability.newOperationId(prefix: 'alert');
      capability = await CaseCapability.generate();
    }

    try {
      await store.save(
        _snapshot(
          alert,
          received: false,
          chatAvailable: false,
          caseId: null,
          referenceCode: null,
          capabilityToken: capability?.token,
          clientOperationId: opId,
        ),
      );
    } on Object {
      return false;
    }

    _alert = alert;
    _delivery = AlertDelivery.pending;
    _chatAvailable = false;
    _caseId = null;
    _referenceCode = null;
    _capabilityToken = capability?.token;
    _clientOperationId = opId;
    _sent.clear();
    _remoteMessages = null;
    situation = null;
    participation = null;
    details = '';

    if (remote == null) {
      _schedule();
      _notify();
      return true;
    }

    try {
      final RemoteAlertReceipt receipt = await remote!.submitStudentAlert(
        clientOperationId: opId!,
        publicSchoolCode: schoolCode,
        situationType: type.rpcValue,
        studentRole: role.rpcValue,
        capabilityVerifierHash: capability!.verifierHash,
        narrativeText: cleanDetails.isEmpty ? null : cleanDetails,
      );
      _caseId = receipt.caseId;
      _referenceCode = receipt.referenceCode;
      _delivery = AlertDelivery.received;
      await store.save(
        _snapshot(
          alert,
          received: true,
          chatAvailable: false,
          caseId: receipt.caseId,
          referenceCode: receipt.referenceCode,
          capabilityToken: capability.token,
          clientOperationId: opId,
        ),
      );
    } on Object {
      // Sin conexión o ante fallo temporal, la alerta queda en cola local
      // cifrada con su token y clientOperationId; si mesh está activo, se
      // sella la alerta mínima para reenvío oportunista sin relato.
      final MeshRelayService? relay = mesh;
      final List<int>? recipientKey = meshRecipientPublicKey;
      if (relay != null && recipientKey != null) {
        try {
          await relay.enqueueMinimalAlert(
            MeshMinimalAlertPayload(
              clientOperationId: opId!,
              publicSchoolCode: schoolCode,
              situationType: type.rpcValue,
              studentRole: role.rpcValue,
              capabilityVerifierHash: capability!.verifierHash,
              declaredAt: DateTime.now().toUtc(),
            ),
            recipientPublicKeyBytes: recipientKey,
          );
          final bool btOn = await relay.transport.isBluetoothEnabled();
          _needsBluetoothForMesh = !btOn;
          if (btOn && !relay.isRunning) {
            await relay.start();
          }
        } on Object {
          // Permanece en la cola local cifrada.
        }
      }
    }

    _notify();
    return true;
  }

  /// Solicita permisos y activación de Bluetooth cuando no hay internet y
  /// existe una alerta pendiente por enviar vía red mesh.
  Future<bool> ensureBluetoothForMesh() async {
    final MeshRelayService? relay = mesh;
    if (relay == null) return false;
    try {
      final bool granted = await relay.transport.requestPermissions();
      if (!granted) return false;
      final bool enabled = await relay.transport.requestEnableBluetooth();
      if (!enabled) {
        _needsBluetoothForMesh = true;
        _notify();
        return false;
      }
      _needsBluetoothForMesh = false;
      if (!relay.isRunning) {
        await relay.start();
      }
      _notify();
      return true;
    } on Object {
      return false;
    }
  }

  /// Sincroniza el estado de disponibilidad del chat y los mensajes desde Supabase.
  Future<void> refreshRemoteChat() async {
    final SetuRemoteGateway? gateway = remote;
    final String? id = _caseId;
    final String? token = _capabilityToken;
    if (gateway == null || id == null || token == null) return;
    try {
      final RemoteChatSession session = await gateway.getStudentChatSession(
        caseId: id,
        capabilityToken: token,
      );
      _chatAvailable = session.chatAvailableNotice;
      _remoteMessages = session.messages
          .map(
            (RemoteChatMessage m) =>
                ChatMessage(m.body, fromStudent: m.fromStudent),
          )
          .toList(growable: false);
      _persist();
      _notify();
    } on Object {
      // Mantiene el último estado conocido sin exponer errores técnicos al alumno.
    }
  }

  Map<String, Object?> _snapshot(
    Map<String, Object?>? alert, {
    required bool received,
    bool? chatAvailable,
    String? caseId,
    String? referenceCode,
    String? capabilityToken,
    String? clientOperationId,
  }) => <String, Object?>{
    'version': 1,
    'alert': alert,
    'received': received,
    'chatAvailable': chatAvailable ?? _chatAvailable,
    if ((caseId ?? _caseId) != null) 'caseId': caseId ?? _caseId,
    if ((referenceCode ?? _referenceCode) != null)
      'referenceCode': referenceCode ?? _referenceCode,
    if ((capabilityToken ?? _capabilityToken) != null)
      'capabilityToken': capabilityToken ?? _capabilityToken,
    if ((clientOperationId ?? _clientOperationId) != null)
      'clientOperationId': clientOperationId ?? _clientOperationId,
  };

  void _schedule() {
    _timer?.cancel();
    if (_disposed || remote != null) return;
    if (_delivery == AlertDelivery.pending) {
      _timer = Timer(ackDelay, () {
        _delivery = AlertDelivery.received;
        _persist();
        _schedule();
        _notify();
      });
    } else if (_delivery == AlertDelivery.received && !_chatAvailable) {
      _timer = Timer(teamDelay, () {
        _chatAvailable = true;
        _persist();
        _notify();
      });
    }
  }

  void _persist() {
    _store
        ?.save(_snapshot(_alert, received: _delivery == AlertDelivery.received))
        .catchError((Object _) {});
  }

  void sendMessage(String text) {
    final String clean = text.trim();
    if (clean.isEmpty || !_chatAvailable) return;
    final SetuRemoteGateway? gateway = remote;
    final String? id = _caseId;
    final String? token = _capabilityToken;
    if (gateway != null && id != null && token != null) {
      final List<ChatMessage> updated = List<ChatMessage>.from(messages)
        ..add(ChatMessage(clean, fromStudent: true));
      _remoteMessages = updated;
      _notify();
      unawaited(
        gateway
            .sendStudentChatMessage(
              caseId: id,
              capabilityToken: token,
              clientOperationId: CaseCapability.newOperationId(prefix: 'msg'),
              body: clean,
            )
            .then((_) => refreshRemoteChat())
            .catchError((Object _) {}),
      );
      return;
    }
    _sent.add(ChatMessage(clean, fromStudent: true));
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
