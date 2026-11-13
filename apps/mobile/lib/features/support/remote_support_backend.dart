import 'package:flutter/foundation.dart';

import '../../shared/remote/setu_remote_gateway.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'support_backend.dart';
import 'support_flow.dart';

/// Adaptador del recorrido estudiantil hacia Supabase.
class RemoteSupportBackend implements SupportBackend {
  RemoteSupportBackend(this._gateway);

  final SetuRemoteGateway _gateway;

  @override
  Listenable? get changes => null;

  @override
  Duration? get pollInterval => const Duration(seconds: 6);

  @override
  Future<String> submitAlert(AlertOutbox alert) async {
    final StudentAlertReceipt receipt = await _gateway.submitStudentAlert(
      StudentAlertSubmission(
        clientOperationId: alert.operationId,
        publicSchoolCode: alert.schoolCode,
        situationType: switch (alert.situation) {
          Situation.physical => SetuSituationType.physicalBullying,
          Situation.verbal => SetuSituationType.verbalBullying,
          Situation.social => SetuSituationType.socialBullying,
          Situation.cyber => SetuSituationType.cyberbullying,
          Situation.sexual => SetuSituationType.sexualViolence,
          Situation.talk => SetuSituationType.needToTalk,
        },
        studentRole: switch (alert.participation) {
          Participation.own => SetuStudentCaseRole.victim,
          Participation.witness => SetuStudentCaseRole.solidarityWitness,
        },
        origin: SetuAlertOrigin.online,
        involvesStaff: false,
        declaredAt: alert.declaredAt,
        capabilityVerifierHash: alert.verifierHash,
        narrativeText: alert.details.isEmpty ? null : alert.details,
        studentPiece: alert.piece == null
            ? null
            : StudentPieceSnapshot.fromJson(alert.piece!.toJson()),
      ),
    );
    return receipt.caseId;
  }

  @override
  Future<ChatSnapshot> chatSession({
    required String caseId,
    required String capabilityToken,
  }) async {
    final StudentChatSessionView session = await _gateway.getStudentChatSession(
      caseId: caseId,
      capabilityToken: capabilityToken,
    );
    return ChatSnapshot(
      available: session.chatAvailableNotice,
      messages: <ChatMessage>[
        for (final CaseChatMessageView message in session.messages)
          ChatMessage(
            message.body,
            fromStudent: message.senderRole == SetuMessageSender.student,
          ),
      ],
    );
  }

  @override
  Future<void> sendMessage({
    required String caseId,
    required String capabilityToken,
    required String operationId,
    required String body,
  }) => _gateway.sendStudentChatMessage(
    caseId: caseId,
    capabilityToken: capabilityToken,
    clientOperationId: operationId,
    body: body,
  );

  @override
  void dispose() {}
}
