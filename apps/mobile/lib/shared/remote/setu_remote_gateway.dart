import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class RemoteSchoolInfo {
  const RemoteSchoolInfo({
    required this.id,
    required this.publicCode,
    required this.name,
    required this.municipality,
    required this.department,
    required this.referenceLat,
    required this.referenceLng,
    required this.radiusMeters,
    required this.configVersion,
  });

  factory RemoteSchoolInfo.fromJson(Map<String, Object?> json) =>
      RemoteSchoolInfo(
        id: json['id']! as String,
        publicCode: json['public_code']! as String,
        name: json['name']! as String,
        municipality: json['municipality']! as String,
        department: json['department']! as String,
        referenceLat: (json['reference_lat']! as num).toDouble(),
        referenceLng: (json['reference_lng']! as num).toDouble(),
        radiusMeters: (json['radius_meters']! as num).toInt(),
        configVersion: (json['config_version']! as num).toInt(),
      );

  final String id;
  final String publicCode;
  final String name;
  final String municipality;
  final String department;
  final double referenceLat;
  final double referenceLng;
  final int radiusMeters;
  final int configVersion;
}

@immutable
class RemoteAlertReceipt {
  const RemoteAlertReceipt({
    required this.caseId,
    required this.referenceCode,
    required this.institutionId,
    required this.origin,
    required this.receivedCentrallyAt,
  });

  factory RemoteAlertReceipt.fromJson(Map<String, Object?> json) =>
      RemoteAlertReceipt(
        caseId: json['case_id']! as String,
        referenceCode: json['reference_code']! as String,
        institutionId: json['institution_id']! as String,
        origin: json['origin']! as String,
        receivedCentrallyAt: DateTime.parse(
          json['received_centrally_at']! as String,
        ),
      );

  final String caseId;
  final String referenceCode;
  final String institutionId;
  final String origin;
  final DateTime receivedCentrallyAt;
}

@immutable
class RemoteChatMessage {
  const RemoteChatMessage({
    required this.id,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  factory RemoteChatMessage.fromJson(Map<String, Object?> json) =>
      RemoteChatMessage(
        id: json['id']! as String,
        senderRole: json['sender_role']! as String,
        body: json['body']! as String,
        createdAt: DateTime.parse(json['created_at']! as String),
      );

  final String id;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  bool get fromStudent => senderRole == 'student';
}

@immutable
class RemoteChatSession {
  const RemoteChatSession({
    required this.caseId,
    required this.chatAvailableNotice,
    required this.messages,
  });

  factory RemoteChatSession.fromJson(Map<String, Object?> json) {
    final List<Object?> rawMessages =
        (json['messages'] as List<Object?>?) ?? const <Object?>[];
    return RemoteChatSession(
      caseId: json['case_id']! as String,
      chatAvailableNotice: json['chat_available_notice'] == true,
      messages: rawMessages
          .map(
            (Object? item) => RemoteChatMessage.fromJson(
              Map<String, Object?>.from(item! as Map<Object?, Object?>),
            ),
          )
          .toList(growable: false),
    );
  }

  final String caseId;
  final bool chatAvailableNotice;
  final List<RemoteChatMessage> messages;
}

/// Contrato de comunicación remota hacia los RPCs de Supabase (ADR 0016).
abstract class SetuRemoteGateway {
  Future<RemoteSchoolInfo> resolvePublicSchool(String publicCode);

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
  });

  Future<RemoteChatSession> getStudentChatSession({
    required String caseId,
    required String capabilityToken,
  });

  Future<RemoteChatMessage> sendStudentChatMessage({
    required String caseId,
    required String capabilityToken,
    required String clientOperationId,
    required String body,
  });
}

/// Implementación sobre [SupabaseClient] usando únicamente RPCs `SECURITY DEFINER`.
class SupabaseSetuRemoteGateway implements SetuRemoteGateway {
  SupabaseSetuRemoteGateway(this._client);

  final SupabaseClient _client;

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map<Object?, Object?>) {
      return Map<String, Object?>.from(value);
    }
    throw const FormatException('Respuesta RPC inesperada.');
  }

  @override
  Future<RemoteSchoolInfo> resolvePublicSchool(String publicCode) async {
    final Object? result = await _client.rpc<Object?>(
      'resolve_public_school',
      params: <String, Object?>{'p_public_code': publicCode},
    );
    return RemoteSchoolInfo.fromJson(_asMap(result));
  }

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
    final Object? result = await _client.rpc<Object?>(
      'submit_student_alert',
      params: <String, Object?>{
        'p_client_operation_id': clientOperationId,
        'p_public_school_code': publicSchoolCode,
        'p_situation_type': situationType,
        'p_student_role': studentRole,
        'p_origin': origin,
        'p_involves_staff': involvesStaff,
        'p_declared_at': (declaredAt ?? DateTime.now().toUtc())
            .toUtc()
            .toIso8601String(),
        'p_capability_verifier_hash': capabilityVerifierHash,
        'p_narrative_text': narrativeText,
        'p_location_text': locationText,
        'p_approx_date_text': approxDateText,
      },
    );
    return RemoteAlertReceipt.fromJson(_asMap(result));
  }

  @override
  Future<RemoteChatSession> getStudentChatSession({
    required String caseId,
    required String capabilityToken,
  }) async {
    final Object? result = await _client.rpc<Object?>(
      'get_student_chat_session',
      params: <String, Object?>{
        'p_case_id': caseId,
        'p_capability_token': capabilityToken,
      },
    );
    return RemoteChatSession.fromJson(_asMap(result));
  }

  @override
  Future<RemoteChatMessage> sendStudentChatMessage({
    required String caseId,
    required String capabilityToken,
    required String clientOperationId,
    required String body,
  }) async {
    final Object? result = await _client.rpc<Object?>(
      'send_student_chat_message',
      params: <String, Object?>{
        'p_case_id': caseId,
        'p_capability_token': capabilityToken,
        'p_client_operation_id': clientOperationId,
        'p_body': body,
      },
    );
    return RemoteChatMessage.fromJson(_asMap(result));
  }
}
