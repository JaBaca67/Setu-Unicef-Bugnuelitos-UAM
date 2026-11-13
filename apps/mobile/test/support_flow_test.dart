import 'package:cureando_mobile/features/piece/student_piece.dart';
import 'package:cureando_mobile/features/support/support_backend.dart';
import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/models/cureando_models.dart';
import 'package:cureando_mobile/shared/remote/case_capability_crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements LocalStorePersistence {
  Map<String, Object?>? data;
  bool failing = false;

  @override
  Future<Map<String, Object?>?> load() async => data;

  @override
  Future<void> save(Map<String, Object?> value) async {
    if (failing) throw StateError('sin espacio');
    data = value;
  }
}

/// Plataforma ficticia que registra lo que recibe.
class _FakePlatform extends ChangeNotifier implements SupportBackend {
  bool offline = false;
  bool chatEnabled = false;
  final List<AlertOutbox> alerts = <AlertOutbox>[];
  final List<String> tokens = <String>[];
  final List<ChatMessage> messages = <ChatMessage>[];

  void enableChat() {
    chatEnabled = true;
    messages.add(const ChatMessage('Hola, te leo.', fromStudent: false));
    notifyListeners();
  }

  void _online() {
    if (offline) throw const GatewayException('remote_error', 'offline');
  }

  @override
  Listenable? get changes => this;

  @override
  Duration? get pollInterval => null;

  @override
  Future<String> submitAlert(AlertOutbox alert) async {
    _online();
    alerts.add(alert);
    return 'case-${alert.operationId}';
  }

  @override
  Future<ChatSnapshot> chatSession({
    required String caseId,
    required String capabilityToken,
  }) async {
    _online();
    tokens.add(capabilityToken);
    return ChatSnapshot(
      available: chatEnabled,
      messages: List<ChatMessage>.of(messages),
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
    messages.add(ChatMessage(body, fromStudent: true));
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  late _MemoryStore store;
  late _FakePlatform platform;
  late SupportFlow flow;

  SupportFlow build() => SupportFlow(
    openStore: () async => store,
    backend: platform,
    schoolCode: 'AULA26',
    retryDelay: const Duration(milliseconds: 10),
  );

  setUp(() {
    store = _MemoryStore();
    platform = _FakePlatform();
    flow = build();
  });

  Future<bool> send({String details = ''}) {
    flow
      ..selectSituation(Situation.verbal)
      ..selectParticipation(Participation.own)
      ..details = details;
    return flow.send(piece: StudentPiece.initial);
  }

  Map<String, Object?> saved() =>
      (store.data!['delivery']! as Map<Object?, Object?>)
          .cast<String, Object?>();

  test('envía la pieza y solo el verificador del secreto del caso', () async {
    expect(await send(details: ' Relato ficticio '), isTrue);
    await _settle();

    final AlertOutbox alert = platform.alerts.single;
    final String token = saved()['token']! as String;
    expect(token, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(
      alert.verifierHash,
      await CaseCapabilityCrypto().computeVerifierHash(token),
    );
    expect(alert.schoolCode, 'AULA26');
    expect(alert.details, 'Relato ficticio');
    expect(alert.situation, Situation.verbal);
    expect(alert.participation, Participation.own);
    expect(alert.piece?.toJson(), StudentPiece.initial.toJson());
    expect(flow.delivery, AlertDelivery.received);
    expect(store.data!['received'], isTrue);
    expect(saved()['caseId'], 'case-${alert.operationId}');
    flow.dispose();
  });

  test('si no puede guardar en el teléfono no envía nada', () async {
    store.failing = true;
    expect(await send(), isFalse);
    await _settle();
    expect(platform.alerts, isEmpty);
    expect(flow.delivery, AlertDelivery.none);
    flow.dispose();
  });

  test('sin conexión queda guardada y reintenta la misma operación', () async {
    platform.offline = true;
    expect(await send(), isTrue);
    await _settle();
    expect(flow.delivery, AlertDelivery.pending);
    expect(flow.deliveryFailed, isTrue);
    expect(store.data!['received'], isFalse);
    final String operation = saved()['operationId']! as String;
    flow.dispose();

    // Al reabrir la app se retoma la entrega con la misma operación.
    flow = build();
    await flow.open();
    await _settle();
    expect(flow.delivery, AlertDelivery.pending);
    platform.offline = false;
    await _settle();
    expect(flow.delivery, AlertDelivery.received);
    expect(flow.deliveryFailed, isFalse);
    expect(platform.alerts.single.operationId, operation);
    flow.dispose();
  });

  test(
    'el chat se abre con el aviso de la Mesa y usa mensajes reales',
    () async {
      await send();
      await _settle();
      expect(flow.chatAvailable, isFalse);
      expect(await flow.sendMessage('Hola'), isFalse);

      platform.enableChat();
      await _settle();
      expect(flow.chatAvailable, isTrue);
      expect(store.data!['chatAvailable'], isTrue);
      expect(flow.messages.single.text, 'Hola, te leo.');
      expect(flow.studentWrote, isFalse);
      expect(platform.tokens.toSet(), <String>{saved()['token']! as String});

      platform.offline = true;
      expect(await flow.sendMessage('Quiero contar algo'), isFalse);
      expect(flow.messages, hasLength(1));
      platform.offline = false;
      expect(await flow.sendMessage(' Quiero contar algo '), isTrue);
      expect(flow.messages.last.text, 'Quiero contar algo');
      expect(flow.studentWrote, isTrue);

      // Los mensajes no se guardan en el teléfono.
      expect(store.data.toString(), isNot(contains('Quiero contar algo')));
      flow.dispose();
    },
  );
}
