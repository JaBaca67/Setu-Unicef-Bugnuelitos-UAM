import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/local/encrypted_local_store.dart';
import '../../shared/models/cureando_models.dart';
import '../../shared/mesh/mesh_bridge_keys.dart';
import '../../shared/mesh/mesh_envelope.dart';
import '../../shared/mesh/mesh_relay_service.dart';
import '../../shared/remote/case_capability_crypto.dart';
import '../../shared/theme/app_theme.dart';
import '../piece/student_piece.dart';
import '../school_access/school_location.dart';
import 'support_backend.dart';

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
/// La alerta se guarda cifrada en el teléfono antes de salir y solo pasa a
/// «recibida» cuando la plataforma confirma la entrega. El estudiante no
/// tiene cuenta: al enviar se genera un secreto por caso que queda en el
/// almacén cifrado y autoriza su chat; a la plataforma solo viaja el
/// verificador SHA-256. Sin [backend] se usa la demostración simulada con
/// temporizadores (`ackDelay`, `teamDelay`) y datos ficticios.
class SupportFlow extends ChangeNotifier {
  SupportFlow({
    Future<LocalStorePersistence> Function()? openStore,
    SupportBackend? backend,
    Duration ackDelay = const Duration(seconds: 3),
    Duration teamDelay = const Duration(seconds: 8),
    this.schoolCode = demoSchoolCode,
    this.retryDelay = const Duration(seconds: 20),
    CaseCapabilityCrypto? crypto,
    this.mesh,
    this.meshRecipientPublicKey,
    this.resolveMeshRecipientPublicKey,
    this.resolveMeshRecipients,
  }) : _openStore = openStore ?? _onDevice,
       _ownsBackend = backend == null,
       backend =
           backend ??
           SimulatedSupportBackend(ackDelay: ackDelay, teamDelay: teamDelay),
       _crypto = crypto ?? CaseCapabilityCrypto() {
    this.backend.changes?.addListener(_refreshChat);
    mesh?.addListener(_meshChanged);
  }

  static const String teamGreeting = SimulatedSupportBackend.teamGreeting;
  static const int maxDetails = 1000;

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_support_alert.enc',
        keyName: 'setu.support.master.v1',
      );

  final Future<LocalStorePersistence> Function() _openStore;
  final SupportBackend backend;
  final bool _ownsBackend;
  final CaseCapabilityCrypto _crypto;
  final MeshRelayService? mesh;
  final List<int>? meshRecipientPublicKey;
  final Future<List<int>?> Function()? resolveMeshRecipientPublicKey;
  final Future<List<List<int>>> Function(String schoolCode, bool involvesStaff)?
  resolveMeshRecipients;
  bool _needsBluetoothForMesh = false;
  bool get needsBluetoothForMesh => _needsBluetoothForMesh;
  bool _meshPending = false;
  bool get meshPending => _meshPending && _delivery == AlertDelivery.pending;
  bool get minimalAlertDelivered {
    final String? operation = _case?['operationId'] as String?;
    return operation != null &&
        (mesh?.isOperationDelivered(operation) ?? false);
  }

  void _meshChanged() => _notify();
  bool _meshPermissionAttempted = false;

  /// Código público del colegio confirmado en el acceso escolar. La app lo
  /// actualiza cuando el estudiante confirma o cambia de colegio; cada
  /// alerta guarda el código vigente al momento de enviarla.
  String schoolCode;

  /// Espera antes de reintentar una entrega que falló.
  final Duration retryDelay;

  LocalStorePersistence? _store;
  Future<void>? _opening;
  Timer? _retry;
  Timer? _poll;
  bool _delivering = false;
  bool _disposed = false;
  Map<String, Object?>? _alert;

  /// Datos de entrega: operación idempotente, secreto del caso, verificador
  /// y, tras el acuse, identificador del caso.
  Map<String, Object?>? _case;
  List<ChatMessage> _messages = const <ChatMessage>[];

  Situation? situation;
  Participation? participation;
  String details = '';
  bool involvesStaff = false;

  AlertDelivery _delivery = AlertDelivery.none;
  AlertDelivery get delivery => _delivery;

  bool _deliveryFailed = false;

  /// Verdadero si el último intento de entrega falló y la alerta sigue
  /// guardada en el teléfono.
  bool get deliveryFailed =>
      _deliveryFailed && _delivery == AlertDelivery.pending;

  bool _chatAvailable = false;
  bool get chatAvailable => _chatAvailable;

  bool _caseClosed = false;
  bool get caseClosed => _caseClosed;

  List<ChatMessage> get messages => _messages;

  // Avisos para el estudiante: el chat se activó o llegaron mensajes del
  // equipo de escucha desde la última vez que abrió «Pedir apoyo».
  bool _chatSeen = false;
  int _staffSeen = 0;

  int get _staffCount =>
      _messages.where((ChatMessage message) => !message.fromStudent).length;

  /// Cantidad de avisos sin revisar que muestra el botón «Pedir apoyo».
  int get unreadSupport {
    if (_delivery != AlertDelivery.received || _caseClosed) return 0;
    final int newMessages = _staffCount - _staffSeen;
    return (_chatAvailable && !_chatSeen ? 1 : 0) +
        (newMessages > 0 ? newMessages : 0);
  }

  /// El estudiante entró a «Pedir apoyo» o al chat: el contador vuelve a 0.
  void markSupportSeen() {
    if (unreadSupport == 0) return;
    _chatSeen = _chatAvailable;
    _staffSeen = _staffCount;
    _persist();
    _notify();
  }

  bool get studentWrote =>
      _messages.any((ChatMessage message) => message.fromStudent);

  String? get _caseId => _case?['caseId'] as String?;

  /// Identificador y token del caso activo recibido, usados para registrar push.
  String? get activeCaseId =>
      _delivery == AlertDelivery.received && !_caseClosed ? _caseId : null;

  String? get activeCapabilityToken {
    if (_delivery != AlertDelivery.received || _caseClosed) return null;
    return _case?['token'] as String?;
  }

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
        final Map<Object?, Object?>? saved =
            data['delivery'] as Map<Object?, Object?>?;
        _case = saved == null ? null : Map<String, Object?>.from(saved);
        _chatAvailable = data['chatAvailable'] == true;
        _chatSeen = data['chatSeen'] == true;
        _staffSeen = (data['staffSeen'] as num?)?.toInt() ?? 0;
        _caseClosed = data['caseClosed'] == true;
        if (_alert != null) {
          _case ??= await _newCase(null);
          // Sin identificador de caso no hay acuse que mostrar.
          _delivery = data['received'] == true && _caseId != null
              ? AlertDelivery.received
              : AlertDelivery.pending;
        }
      }
      _store = store;
      _resume();
    } on Object {
      // Sin almacén no se puede guardar: [send] lo informa sin falso éxito.
    } finally {
      _opening = null;
      _notify();
    }
  }

  Future<Map<String, Object?>> _newCase(StudentPiece? piece) async {
    final CaseCapabilityPair pair = await _crypto.generateCapabilityPair();
    return <String, Object?>{
      'operationId': CaseCapabilityCrypto.generateClientOperationId(
        prefix: 'alert',
      ),
      'token': pair.capabilityToken,
      'verifierHash': pair.capabilityVerifierHash,
      'declaredAt': DateTime.now().toUtc().toIso8601String(),
      'schoolCode': schoolCode,
      'piece': piece?.toJson(),
      'caseId': null,
    };
  }

  void selectSituation(Situation value) {
    situation = value;
    _notify();
  }

  void selectParticipation(Participation value) {
    participation = value;
    _notify();
  }

  void setInvolvesStaff(bool value) {
    if (involvesStaff == value) return;
    involvesStaff = value;
    _notify();
  }

  /// Guarda la alerta en el teléfono y empieza la entrega. Devuelve false si
  /// no pudo guardarse; en ese caso no se envía nada.
  Future<bool> send({StudentPiece? piece}) async {
    final Situation? type = situation;
    final Participation? role = participation;
    if (type == null || role == null) return false;
    await open();
    final LocalStorePersistence? store = _store;
    if (store == null) return false;
    final Map<String, Object?> alert = <String, Object?>{
      'situation': type.name,
      'participation': role.name,
      'details': details.trim(),
      'involvesStaff': involvesStaff,
    };
    final Map<String, Object?> delivery;
    // Un caso nuevo empieza sin avisos revisados.
    _chatSeen = false;
    _staffSeen = 0;
    try {
      delivery = await _newCase(piece);
      await store.save(
        _snapshot(alert, delivery, received: false, chatAvailable: false),
      );
    } on Object {
      return false;
    }
    _alert = alert;
    _case = delivery;
    _delivery = AlertDelivery.pending;
    _deliveryFailed = false;
    _meshPending = false;
    _meshPermissionAttempted = false;
    _chatAvailable = false;
    _chatSeen = false;
    _staffSeen = 0;
    _caseClosed = false;
    _messages = const <ChatMessage>[];
    situation = null;
    participation = null;
    details = '';
    involvesStaff = false;
    _resume();
    _notify();
    return true;
  }

  Map<String, Object?> _snapshot(
    Map<String, Object?>? alert,
    Map<String, Object?>? delivery, {
    required bool received,
    required bool chatAvailable,
  }) => <String, Object?>{
    'version': 1,
    'alert': alert,
    'delivery': delivery,
    'received': received,
    'chatAvailable': chatAvailable,
    'caseClosed': caseClosed,
    'chatSeen': _chatSeen,
    'staffSeen': _staffSeen,
  };

  void _resume() {
    _retry?.cancel();
    _poll?.cancel();
    if (_disposed) return;
    if (_delivery == AlertDelivery.pending) {
      _deliver();
    } else if (_delivery == AlertDelivery.received) {
      final Duration? every = backend.pollInterval;
      if (every != null) {
        _poll = Timer.periodic(every, (_) => _refreshChat());
      }
      _refreshChat();
    }
  }

  /// Vuelve a intentar la entrega de una alerta guardada.
  void retryDelivery() {
    if (_delivery == AlertDelivery.pending) _resume();
  }

  Future<void> _deliver() async {
    final Map<String, Object?>? alert = _alert;
    final Map<String, Object?>? delivery = _case;
    if (_delivering || alert == null || delivery == null) return;
    _delivering = true;
    AlertOutbox? outbox;
    try {
      final Object? piece = delivery['piece'];
      outbox = AlertOutbox(
        operationId: delivery['operationId']! as String,
        schoolCode: delivery['schoolCode'] as String? ?? schoolCode,
        situation: Situation.values.byName(alert['situation']! as String),
        participation: Participation.values.byName(
          alert['participation']! as String,
        ),
        details: alert['details'] as String? ?? '',
        involvesStaff: alert['involvesStaff'] == true,
        verifierHash: delivery['verifierHash']! as String,
        declaredAt: DateTime.parse(delivery['declaredAt']! as String),
        // La pieza viaja tal como se guardó al enviar la alerta.
        piece: piece is Map<Object?, Object?>
            ? piece.cast<String, Object?>()
            : null,
      );
      final String caseId = await backend
          .submitAlert(outbox)
          .timeout(const Duration(seconds: 8));
      // Si mientras tanto se envió otra alerta, este acuse ya no aplica.
      if (identical(_case, delivery)) {
        delivery['caseId'] = caseId;
        _delivery = AlertDelivery.received;
        _deliveryFailed = false;
        _needsBluetoothForMesh = false;
        _persist();
      }
    } on Object catch (error) {
      if (identical(_case, delivery)) _deliveryFailed = true;
      // Un rechazo de autorización/validación no habilita otra vía de alta.
      if (!_disposed &&
          identical(_case, delivery) &&
          outbox != null &&
          (error is TimeoutException ||
              error is GatewayException &&
                  error.code == 'network_unavailable')) {
        await _enqueueMeshFallback(outbox);
      }
    } finally {
      _delivering = false;
    }
    if (_disposed) return;
    if (_delivery == AlertDelivery.pending && identical(_case, delivery)) {
      _retry?.cancel();
      _retry = Timer(retryDelay, _deliver);
    } else {
      _resume();
    }
    _notify();
  }

  Future<bool> ensureBluetoothForMesh() async {
    final MeshRelayService? relay = mesh;
    if (relay == null) return false;
    try {
      final bool started = await relay.ensureReadyAndStart();
      _needsBluetoothForMesh = !started;
      _notify();
      return started;
    } on Object {
      _needsBluetoothForMesh = true;
      _notify();
      return false;
    }
  }

  Future<void> _enqueueMeshFallback(AlertOutbox outbox) async {
    final MeshRelayService? relay = mesh;
    if (relay == null) return;
    try {
      final List<List<int>> keys;
      final resolver = resolveMeshRecipients;
      if (resolver != null) {
        keys = await resolver(outbox.schoolCode, outbox.involvesStaff);
      } else {
        final List<int>? recipientKey =
            meshRecipientPublicKey ??
            await resolveMeshRecipientPublicKey?.call();
        keys = <List<int>>[?recipientKey];
      }
      if (keys.isEmpty) return;
      final MeshMinimalAlertPayload payload = MeshMinimalAlertPayload(
        clientOperationId: outbox.operationId,
        publicSchoolCode: outbox.schoolCode,
        situationType: outbox.situation.rpcValue,
        studentRole: outbox.participation.rpcValue,
        involvesStaff: outbox.involvesStaff,
        capabilityVerifierHash: outbox.verifierHash,
        declaredAt: outbox.declaredAt,
        // ADR 0028: relato y pieza viajan cifrados para el personal autorizado.
        narrativeText: resolver == null
            ? null
            : MeshMinimalAlertPayload.fitNarrative(outbox.details),
        studentPiece: resolver == null ? null : outbox.piece,
      );
      for (final List<int> key in keys) {
        await relay.enqueueMinimalAlert(payload, recipientPublicKeyBytes: key);
      }
      // Proyección local solo para simulaciones en memoria, sin directorio remoto.
      if (resolver == null &&
          !outbox.involvesStaff &&
          outbox.schoolCode.trim().isNotEmpty) {
        final List<int> schoolKey =
            await MeshSchoolKeys.resolveSchoolPublicKeyBytes(outbox.schoolCode);
        await relay.enqueueMinimalAlert(
          payload.withoutPrivateFields(),
          recipientPublicKeyBytes: schoolKey,
        );
      }
      _meshPending = true;
      _notify();
      // Una única solicitud del sistema por envío. Reintentar no insiste si
      // se denegó; al reanudar se vuelve a comprobar sin abrir diálogos.
      final bool requestAccess = !_meshPermissionAttempted;
      _meshPermissionAttempted = true;
      _needsBluetoothForMesh = !await relay.ensureReadyAndStart(
        requestAccess: requestAccess,
      );
    } on Object {
      // Permanece en la cola local cifrada.
    }
  }

  /// Consulta de inmediato el estado y los mensajes nuevos del chat.
  Future<void> refreshChat() => _refreshChat();

  Future<void> _refreshChat() async {
    final Map<String, Object?>? delivery = _case;
    final String? caseId = _caseId;
    if (_disposed ||
        delivery == null ||
        caseId == null ||
        _delivery != AlertDelivery.received) {
      return;
    }
    try {
      final ChatSnapshot snapshot = await backend.chatSession(
        caseId: caseId,
        capabilityToken: delivery['token']! as String,
      );
      if (_disposed || !identical(_case, delivery)) return;
      _messages = List<ChatMessage>.unmodifiable(snapshot.messages);
      if (_chatAvailable != snapshot.available ||
          _caseClosed != snapshot.caseClosed) {
        _chatAvailable = snapshot.available;
        _caseClosed = snapshot.caseClosed;
        _persist();
      }
      _notify();
    } on Object {
      // Sin conexión se conserva lo último confirmado por la plataforma.
    }
  }

  void _persist() {
    _store
        ?.save(
          _snapshot(
            _alert,
            _case,
            received: _delivery == AlertDelivery.received,
            chatAvailable: _chatAvailable,
          ),
        )
        .catchError((Object _) {});
  }

  /// Envía un mensaje al equipo de escucha. Devuelve false si no salió; el
  /// borrador debe conservarse.
  Future<bool> sendMessage(String text) async {
    final String clean = text.trim();
    final Map<String, Object?>? delivery = _case;
    final String? caseId = _caseId;
    if (clean.isEmpty ||
        !_chatAvailable ||
        delivery == null ||
        caseId == null) {
      return false;
    }
    try {
      await backend.sendMessage(
        caseId: caseId,
        capabilityToken: delivery['token']! as String,
        operationId: CaseCapabilityCrypto.generateClientOperationId(
          prefix: 'msg',
        ),
        body: clean,
      );
    } on Object {
      return false;
    }
    await _refreshChat();
    return true;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _poll?.cancel();
    backend.changes?.removeListener(_refreshChat);
    mesh?.removeListener(_meshChanged);
    if (_ownsBackend) backend.dispose();
    super.dispose();
  }
}
