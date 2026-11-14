import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/models/cureando_models.dart';
import '../piece/student_piece.dart';
import 'support_flow.dart';

/// Alerta lista para entregar. El secreto de capacidad nunca viaja: solo su
/// verificador SHA-256.
@immutable
class AlertOutbox {
  const AlertOutbox({
    required this.operationId,
    required this.schoolCode,
    required this.situation,
    required this.participation,
    required this.details,
    required this.verifierHash,
    required this.declaredAt,
    required this.piece,
  });

  final String operationId;
  final String schoolCode;
  final Situation situation;
  final Participation participation;
  final String details;
  final String verifierHash;
  final DateTime declaredAt;
  final StudentPiece? piece;
}

@immutable
class ChatSnapshot {
  const ChatSnapshot({
    required this.available,
    required this.messages,
    this.caseClosed = false,
  });

  /// Verdadero cuando la Mesa de Escucha habilitó la conversación.
  final bool available;
  final bool caseClosed;
  final List<ChatMessage> messages;
}

/// Puerto del recorrido estudiantil hacia la plataforma. El estudiante no
/// tiene cuenta: cada llamada del chat se autoriza con el secreto del caso.
abstract interface class SupportBackend {
  /// Avisa cuando conviene volver a consultar el chat; null si no hay aviso.
  Listenable? get changes;

  /// Cada cuánto consultar el chat cuando no hay [changes].
  Duration? get pollInterval;

  /// Entrega la alerta y devuelve el identificador del caso. Repetir la
  /// llamada con el mismo `operationId` no crea otro caso.
  Future<String> submitAlert(AlertOutbox alert);

  Future<ChatSnapshot> chatSession({
    required String caseId,
    required String capabilityToken,
  });

  Future<void> sendMessage({
    required String caseId,
    required String capabilityToken,
    required String operationId,
    required String body,
  });

  void dispose();
}

class _SimulatedCase {
  bool available = false;
  Timer? timer;
  final List<ChatMessage> sent = <ChatMessage>[];
}

/// DEMOSTRACIÓN: acuse y aviso de disponibilidad simulados con
/// temporizadores, sin red. Nada sale del teléfono; solo datos ficticios.
class SimulatedSupportBackend extends ChangeNotifier implements SupportBackend {
  SimulatedSupportBackend({
    this.ackDelay = const Duration(seconds: 3),
    this.teamDelay = const Duration(seconds: 8),
  });

  static const String teamGreeting = 'Hola. Soy parte del equipo de escucha.';

  final Duration ackDelay;
  final Duration teamDelay;
  final Map<String, String> _caseByOperation = <String, String>{};
  final Map<String, _SimulatedCase> _cases = <String, _SimulatedCase>{};
  bool _disposed = false;

  /// Simula una caída de conexión en las pruebas.
  bool offline = false;

  void _online() {
    if (offline) throw const GatewayException('remote_error', 'offline');
  }

  _SimulatedCase _case(String caseId) => _cases.putIfAbsent(caseId, () {
    final _SimulatedCase created = _SimulatedCase();
    created.timer = Timer(teamDelay, () {
      created.available = true;
      if (!_disposed) notifyListeners();
    });
    return created;
  });

  @override
  Listenable? get changes => this;

  @override
  Duration? get pollInterval => null;

  @override
  Future<String> submitAlert(AlertOutbox alert) async {
    _online();
    await Future<void>.delayed(ackDelay);
    _online();
    final String caseId = _caseByOperation.putIfAbsent(
      alert.operationId,
      () => 'demo-${_caseByOperation.length + 1}',
    );
    if (!_disposed) _case(caseId);
    return caseId;
  }

  @override
  Future<ChatSnapshot> chatSession({
    required String caseId,
    required String capabilityToken,
  }) async {
    _online();
    final _SimulatedCase found = _case(caseId);
    return ChatSnapshot(
      available: found.available,
      messages: <ChatMessage>[
        if (found.available)
          const ChatMessage(teamGreeting, fromStudent: false),
        ...found.sent,
      ],
    );
  }

  @override
  Future<void> sendMessage({
    required String caseId,
    required String capabilityToken,
    required String operationId,
    required String body,
  }) async {
    _online();
    final _SimulatedCase found = _case(caseId);
    if (!found.available) {
      throw const GatewayException('chat_not_available', '');
    }
    found.sent.add(ChatMessage(body, fromStudent: true));
  }

  @override
  void dispose() {
    _disposed = true;
    for (final _SimulatedCase found in _cases.values) {
      found.timer?.cancel();
    }
    super.dispose();
  }
}
