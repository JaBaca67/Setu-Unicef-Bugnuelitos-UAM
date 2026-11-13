import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/remote/case_capability.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_gateway.dart';
import 'package:cureando_mobile/shared/remote/supabase_config.dart';
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

class _FakeRemoteGateway implements SetuRemoteGateway {
  bool shouldFail = false;
  String? lastSchoolCode;
  String? lastSituationType;
  String? lastStudentRole;
  String? lastVerifierHash;
  String? lastNarrativeText;
  String? lastClientOpId;
  bool chatAvailable = false;
  final List<RemoteChatMessage> messages = <RemoteChatMessage>[];

  @override
  Future<RemoteSchoolInfo> resolvePublicSchool(String publicCode) async =>
      RemoteSchoolInfo(
        id: '11111111-1111-4111-8111-000000000024',
        publicCode: publicCode,
        name: 'Colegio Público Demo',
        municipality: 'Managua',
        department: 'Managua',
        referenceLat: 12.098062,
        referenceLng: -86.2641465,
        radiusMeters: 150,
        configVersion: 1,
      );

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
    if (shouldFail) {
      throw StateError('offline');
    }
    lastClientOpId = clientOperationId;
    lastSchoolCode = publicSchoolCode;
    lastSituationType = situationType;
    lastStudentRole = studentRole;
    lastVerifierHash = capabilityVerifierHash;
    lastNarrativeText = narrativeText;
    return RemoteAlertReceipt(
      caseId: '22222222-2222-4222-8222-000000000001',
      referenceCode: 'SETU-AB12-CD34',
      institutionId: '11111111-1111-4111-8111-000000000024',
      origin: origin,
      receivedCentrallyAt: DateTime.utc(2026, 11, 12, 20, 0),
    );
  }

  @override
  Future<RemoteChatSession> getStudentChatSession({
    required String caseId,
    required String capabilityToken,
  }) async =>
      RemoteChatSession(
        caseId: caseId,
        chatAvailableNotice: chatAvailable,
        messages: List<RemoteChatMessage>.unmodifiable(messages),
      );

  @override
  Future<RemoteChatMessage> sendStudentChatMessage({
    required String caseId,
    required String capabilityToken,
    required String clientOperationId,
    required String body,
  }) async {
    final RemoteChatMessage msg = RemoteChatMessage(
      id: '33333333-3333-4333-8333-000000000001',
      senderRole: 'student',
      body: body,
      createdAt: DateTime.utc(2026, 11, 12, 20, 5),
    );
    messages.add(msg);
    return msg;
  }
}

void main() {
  test('SupabaseConfig solo está configurado con URL y anon key', () {
    const SupabaseConfig empty = SupabaseConfig(url: '', anonKey: '');
    const SupabaseConfig valid = SupabaseConfig(
      url: 'https://example.supabase.co',
      anonKey: 'anon-demo-key',
    );
    expect(empty.isConfigured, isFalse);
    expect(valid.isConfigured, isTrue);
  });

  test('CaseCapability genera token de 64 hex y hash SHA-256 distinto', () async {
    final CaseCapability cap = await CaseCapability.generate();
    final RegExp hex64 = RegExp(r'^[0-9a-f]{64}$');
    expect(hex64.hasMatch(cap.token), isTrue);
    expect(hex64.hasMatch(cap.verifierHash), isTrue);
    expect(cap.verifierHash, isNot(equals(cap.token)));
    expect(await CaseCapability.hashToken(cap.token), equals(cap.verifierHash));
  });

  test('SupportFlow envía alerta remota, persiste token y sincroniza chat', () async {
    final _MemoryStore store = _MemoryStore();
    final _FakeRemoteGateway remote = _FakeRemoteGateway();
    final SupportFlow flow = SupportFlow(
      openStore: () async => store,
      remote: remote,
      schoolCode: 'AULA24',
    );

    flow.selectSituation(Situation.verbal);
    flow.selectParticipation(Participation.own);
    flow.details = 'Me insultaron en el recreo';

    final bool saved = await flow.send();
    expect(saved, isTrue);
    expect(flow.delivery, AlertDelivery.received);
    expect(flow.caseId, '22222222-2222-4222-8222-000000000001');
    expect(flow.referenceCode, 'SETU-AB12-CD34');
    expect(remote.lastSchoolCode, 'AULA24');
    expect(remote.lastSituationType, 'verbal_bullying');
    expect(remote.lastStudentRole, 'victim');
    expect(remote.lastNarrativeText, 'Me insultaron en el recreo');
    expect(remote.lastVerifierHash, isNotNull);
    expect(remote.lastClientOpId, isNotNull);

    final Map<String, Object?>? persisted = await store.load();
    expect(persisted?['capabilityToken'], isA<String>());
    expect(persisted?['caseId'], '22222222-2222-4222-8222-000000000001');

    remote.chatAvailable = true;
    remote.messages.add(
      RemoteChatMessage(
        id: 'm1',
        senderRole: 'counseling_desk',
        body: 'Hola, te escuchamos.',
        createdAt: DateTime.utc(2026, 11, 12, 20, 2),
      ),
    );
    await flow.refreshRemoteChat();
    expect(flow.chatAvailable, isTrue);
    expect(flow.messages.length, 1);
    expect(flow.messages.first.fromStudent, isFalse);
  });

  test('SupportFlow conserva cola local pendiente si falla envío remoto', () async {
    final _MemoryStore store = _MemoryStore();
    final _FakeRemoteGateway remote = _FakeRemoteGateway()..shouldFail = true;
    final SupportFlow flow = SupportFlow(
      openStore: () async => store,
      remote: remote,
    );

    flow.selectSituation(Situation.talk);
    flow.selectParticipation(Participation.witness);
    final bool saved = await flow.send();

    expect(saved, isTrue);
    expect(flow.delivery, AlertDelivery.pending);
    expect(flow.caseId, isNull);
    final Map<String, Object?>? persisted = await store.load();
    expect(persisted?['received'], isFalse);
    expect(persisted?['capabilityToken'], isA<String>());
    expect(persisted?['clientOperationId'], isA<String>());
  });
}
