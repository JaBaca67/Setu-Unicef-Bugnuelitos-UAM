import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cureando_models.dart';
import 'setu_remote_models.dart';

/// Configuración pública de Supabase para la app cliente de SéTú.
///
/// Solo contiene URL del proyecto y llave pública (`publishable` / `anon`).
/// Nunca incluye llaves privilegiadas (`service_role`).
class SetuSupabaseConfig {
  const SetuSupabaseConfig({required this.url, required this.anonKey});

  static const String defaultUrl = 'https://rliiwzovgpnxhrkdkmus.supabase.co';
  static const String defaultPublishableKey =
      'sb_publishable_5n8GIQkTlLZnCMn3WKcP2A_plC5ja0u';

  final String url;
  final String anonKey;

  String get publishableKey => anonKey;

  factory SetuSupabaseConfig.fromEnvironment() {
    return const SetuSupabaseConfig(
      url: String.fromEnvironment(
        'SETU_SUPABASE_URL',
        defaultValue: defaultUrl,
      ),
      anonKey: String.fromEnvironment(
        'SETU_SUPABASE_ANON_KEY',
        defaultValue: defaultPublishableKey,
      ),
    );
  }
}

/// Contrato remoto unificado para estudiante, activación, MINED, Mesa y Dirección.
abstract interface class SetuRemoteGateway {
  // Estudiante (sin cuentas; token de capacidad por caso)
  Future<PublicSchoolResolution?> resolvePublicSchool(String publicCode);

  Future<StudentAlertReceipt> submitStudentAlert(
    StudentAlertSubmission submission,
  );

  Future<StudentChatSessionView> getStudentChatSession({
    required String caseId,
    required String capabilityToken,
  });

  Future<CaseChatMessageView> sendStudentChatMessage({
    required String caseId,
    required String capabilityToken,
    required String clientOperationId,
    required String body,
  });

  // Catálogo público D8
  Future<List<EditorialResourceRecord>> listPublishedEditorialResources();

  Future<List<HelpResourceRecord>> listPublishedHelpResources();

  // Autenticación y activación individual de personal autorizado
  String? get currentStaffUserId;

  String? get currentStaffEmail;

  bool get isCurrentStaffEmailConfirmed;

  Future<StaffActivationPreview> previewStaffActivationCode({
    required String activationCode,
    String? institutionalEmail,
  });

  Future<void> signUpStaffAccount({
    required String email,
    required String password,
    String? emailRedirectTo,
  });

  Future<void> resendStaffConfirmationEmail({
    required String email,
    String? emailRedirectTo,
  });

  Future<void> refreshStaffAuthSession();

  Future<void> sendStaffPasswordResetEmail({
    required String email,
    String? redirectTo,
  });

  Future<void> signInStaffWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOutStaff();

  Future<void> registerStaffPushToken({
    required String fcmToken,
    String platform = 'android',
  });

  Future<void> unregisterStaffPushToken({required String fcmToken});

  Future<void> registerStudentPushToken({
    required String caseId,
    required String capabilityToken,
    required String fcmToken,
    String platform = 'android',
  });

  Future<void> unregisterStudentPushToken({
    required String caseId,
    required String capabilityToken,
    required String fcmToken,
  });

  Future<StaffActivationRedemption> redeemStaffActivationCode(
    String activationCode,
  );

  Future<StaffActivationRedemption> redeemStaffActivationCodeWithProfile({
    required String activationCode,
    required String firstName,
    required String lastName,
  });

  Future<List<StaffMembershipScope>> getMyStaffMemberships();

  Future<StaffProfileView> getMyStaffProfile();

  Future<void> updateMyStaffAvailabilityAndNotices({
    required bool isAvailable,
    required bool notifyNewAlerts,
    required bool notifyNewMessages,
  });

  Future<void> requestStaffInviteReplacement({
    required String institutionalEmail,
    required String reasonCode,
    String? notes,
  });

  Future<List<StaffActivationInviteView>> listStaffActivationInvites({
    String? institutionId,
  });

  Future<Map<String, Object?>> requestStaffActivationInvite({
    required String institutionalEmail,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? fullName,
    String? requesterProgramLabel,
    String? supervisorUserId,
  });

  Future<StaffInviteIssueResult> issueStaffActivationInvite({
    String? institutionalEmail,
    SetuStaffRole? role,
    String? institutionId,
    String? staffTier,
    String? scopeLabel,
    String? fullName,
    String? supervisorUserId,
    int expiresInHours = 72,
    String? pendingInviteId,
  });

  Future<void> revokeStaffActivationInvite({
    required String inviteId,
    String? reason,
  });

  Future<StaffInviteIssueResult> replaceStaffActivationInvite({
    required String inviteId,
    String? newInstitutionalEmail,
    int expiresInHours = 72,
    String? reason,
  });

  Future<CounselorDispatchCasesResult> listCounselorDispatchCases();

  Future<CaseDispatchRecoverResult> recoverDeclinedCaseDispatch(String caseId);

  Future<SchoolCoverageAndAssignmentsView> listSchoolCoverageAndAssignments({
    String? institutionId,
  });

  Future<void> setSchoolExternalCoverage({
    required String institutionId,
    ExternalCoverageMode? mode,
    DateTime? until,
    bool? minedExternalEnabled,
  });

  Future<void> assignExternalCounselorSchool({
    required String counselorUserId,
    required String institutionId,
    bool active = true,
  });

  Future<List<PracticanteSupervisorNoticeView>> listMySupervisorNotices();

  // Operación por rol institucional (protegida por RLS y RPC en Supabase)
  Future<List<StaffCaseSummary>> listCasesForScope({String? institutionId});

  Future<List<AssignableCounselor>> listAssignableCounselors({
    String? institutionId,
  });

  Future<Map<String, Object?>> assignCaseCounselor({
    required String clientOperationId,
    required String caseId,
    required String counselorUserId,
  });

  Future<Map<String, Object?>> minedUpdateCaseSupervision({
    required String clientOperationId,
    required String caseId,
    required SetuCaseStatus nextStatus,
    String? reason,
  });

  // Mesa de Escucha
  Future<CaseNarrativeView?> getCaseNarrative(String caseId);

  Future<List<CaseChatMessageView>> listCaseMessages(String caseId);

  Future<List<CaseInternalNoteView>> listCaseInternalNotes(String caseId);

  Future<Map<String, Object?>> enableCaseChat({
    required String clientOperationId,
    required String caseId,
    String? openingMessage,
  });

  Future<CaseChatMessageView> sendCounselorChatMessage({
    required String caseId,
    required String clientOperationId,
    required String body,
  });

  Future<CaseInternalNoteView> saveCaseInternalNote({
    required String caseId,
    required String clientOperationId,
    required String noteBody,
  });

  Future<Map<String, Object?>> assessCaseAndIssueSheet({
    required String clientOperationId,
    required String caseId,
    required int humanLevel,
    bool triggerUrgentReferral = false,
    bool issueSheet = false,
    String? guidanceNotes,
    bool omitSchoolDueToConflict = false,
    bool closeCase = false,
    String? closedReason,
  });

  // Dirección y actuaciones del centro
  /// Finaliza la conversación sin cerrar el expediente institucional.
  Future<Map<String, Object?>> endCaseConversation({
    required String clientOperationId,
    required String caseId,
  });

  /// Borrador de la «Nota para la ficha»; solo la persona asignada.
  Future<CaseSheetDraftView?> getCaseSheetDraft(String caseId);

  Future<CaseSheetDraftView> saveCaseSheetDraft({
    required String caseId,
    required String guidanceDraft,
  });

  Future<List<CaseActionSheetView>> listCaseActionSheets({String? caseId});

  Future<List<SchoolActionRecordView>> listSchoolActions(String caseId);

  Future<Map<String, Object?>> recordTeacherNotice({
    required String clientOperationId,
    required String institutionId,
    required SetuSituationType situationType,
    bool involvesStaff = false,
    DateTime? declaredAt,
  });

  Future<Map<String, Object?>> recordSchoolAction({
    required String clientOperationId,
    required String caseId,
    required String? actionSheetId,
    required SetuSchoolActionStep step,
    bool isGroupAction = false,
    String actionNotes = '',
    bool proposesClosure = false,
    int expectedConcurrencyVersion = 1,
  });

  /// Nombres de los centros activos por id (lectura pública por RLS).
  Future<Map<String, String>> listActiveInstitutionNames();

  // Aviso en vivo dentro de la app (Realtime)
  Stream<SetuAssignmentNotice> watchAssignedCaseNotices({
    required String counselorUserId,
  });

  // Despacho multi-psicólogo (Opción A: toma sin colisiones, declinación e historial MINED)
  Future<CaseClaimResult> claimCaseCounselor({
    required String clientOperationId,
    required String caseId,
  });

  Future<CaseDeclineResult> declineCaseDispatch({
    required String clientOperationId,
    required String caseId,
    String? reason,
  });

  Future<List<CaseDispatchRecord>> listCaseDispatchHistory({
    String? institutionId,
    String? caseId,
  });

  Stream<CaseDispatchRecord> watchIncomingDispatches({
    required String counselorUserId,
  });

  /// Escucha mensajes entrantes en vivo en `public.case_messages` para un caso.
  Stream<CaseChatMessageView> watchCaseMessages(String caseId);
}

/// Implementación oficial contra Supabase (`supabase_flutter`).
class SupabaseSetuRemoteGateway implements SetuRemoteGateway {
  SupabaseSetuRemoteGateway(this._client);

  final SupabaseClient _client;

  static Future<SupabaseSetuRemoteGateway> initialize({
    SetuSupabaseConfig? config,
  }) async {
    final SetuSupabaseConfig resolved =
        config ?? SetuSupabaseConfig.fromEnvironment();
    final Supabase instance = await Supabase.initialize(
      url: resolved.url,
      publishableKey: resolved.publishableKey,
    );
    return SupabaseSetuRemoteGateway(instance.client);
  }

  @override
  String? get currentStaffUserId => _client.auth.currentUser?.id;

  @override
  String? get currentStaffEmail => _client.auth.currentUser?.email;

  @override
  bool get isCurrentStaffEmailConfirmed {
    final String? confirmedAt = _client.auth.currentUser?.emailConfirmedAt;
    return confirmedAt != null && confirmedAt.isNotEmpty;
  }

  @override
  Future<PublicSchoolResolution?> resolvePublicSchool(String publicCode) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'resolve_public_school',
        params: <String, Object?>{'p_public_code': publicCode},
      );
      if (response == null) return null;
      return PublicSchoolResolution.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StudentAlertReceipt> submitStudentAlert(
    StudentAlertSubmission submission,
  ) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'submit_student_alert',
        params: <String, Object?>{
          'p_client_operation_id': submission.clientOperationId,
          'p_public_school_code': submission.publicSchoolCode,
          'p_situation_type': submission.situationType.wireValue,
          'p_student_role': submission.studentRole.wireValue,
          'p_origin': submission.origin.wireValue,
          'p_involves_staff': submission.involvesStaff,
          'p_declared_at': submission.declaredAt.toUtc().toIso8601String(),
          'p_capability_verifier_hash': submission.capabilityVerifierHash,
          'p_narrative_text': submission.narrativeText,
          'p_location_text': submission.locationText,
          'p_approx_date_text': submission.approxDateText,
          'p_student_piece': submission.studentPiece?.toJson(),
          // Sin hash se usa la variante anterior de la función, sin cupo.
          if (submission.installationVerifierHash != null)
            'p_installation_verifier_hash': submission.installationVerifierHash,
        },
      );
      return StudentAlertReceipt.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StudentChatSessionView> getStudentChatSession({
    required String caseId,
    required String capabilityToken,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'get_student_chat_session',
        params: <String, Object?>{
          'p_case_id': caseId,
          'p_capability_token': capabilityToken,
        },
      );
      return StudentChatSessionView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseChatMessageView> sendStudentChatMessage({
    required String caseId,
    required String capabilityToken,
    required String clientOperationId,
    required String body,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'send_student_chat_message',
        params: <String, Object?>{
          'p_case_id': caseId,
          'p_capability_token': capabilityToken,
          'p_client_operation_id': clientOperationId,
          'p_body': body,
        },
      );
      return CaseChatMessageView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<EditorialResourceRecord>>
  listPublishedEditorialResources() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('editorial_resources')
          .select(
            'id,version,topic,format,title,summary,body_paragraphs,school_stage,'
            'duration_label,source_name,reviewer_name,verified_at,rights_notice,'
            'accessible_alternative,offline_packable',
          )
          .eq('published', true)
          .order('verified_at', ascending: false);
      return List<EditorialResourceRecord>.unmodifiable(
        rows.map(
          (Map<String, dynamic> row) =>
              EditorialResourceRecord.fromJson(_normalizeDynamicMap(row)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<HelpResourceRecord>> listPublishedHelpResources() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('help_resources')
          .select(
            'id,name,phone_or_channel,territory,hours_label,source_name,'
            'editorial_responsible,verified_at,is_verified_for_pilot,display_order',
          )
          .eq('published', true)
          .order('display_order', ascending: true);
      return List<HelpResourceRecord>.unmodifiable(
        rows.map(
          (Map<String, dynamic> row) =>
              HelpResourceRecord.fromJson(_normalizeDynamicMap(row)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffActivationPreview> previewStaffActivationCode({
    required String activationCode,
    String? institutionalEmail,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'preview_staff_activation_code',
        params: <String, Object?>{
          'p_activation_code': activationCode,
          'p_institutional_email': institutionalEmail,
        },
      );
      return StaffActivationPreview.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> signUpStaffAccount({
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async {
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: emailRedirectTo,
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> resendStaffConfirmationEmail({
    required String email,
    String? emailRedirectTo,
  }) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: emailRedirectTo,
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> refreshStaffAuthSession() async {
    try {
      await _client.auth.refreshSession();
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> sendStaffPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> signInStaffWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> signOutStaff() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> registerStaffPushToken({
    required String fcmToken,
    String platform = 'android',
  }) async {
    try {
      await _client.rpc<Object?>(
        'register_staff_push_token',
        params: <String, Object?>{
          'p_fcm_token': fcmToken,
          'p_platform': platform,
        },
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> unregisterStaffPushToken({required String fcmToken}) async {
    try {
      await _client.rpc<Object?>(
        'unregister_staff_push_token',
        params: <String, Object?>{'p_fcm_token': fcmToken},
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> registerStudentPushToken({
    required String caseId,
    required String capabilityToken,
    required String fcmToken,
    String platform = 'android',
  }) async {
    try {
      await _client.rpc<Object?>(
        'register_student_push_token',
        params: <String, Object?>{
          'p_case_id': caseId,
          'p_capability_token': capabilityToken,
          'p_fcm_token': fcmToken,
          'p_platform': platform,
        },
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> unregisterStudentPushToken({
    required String caseId,
    required String capabilityToken,
    required String fcmToken,
  }) async {
    try {
      await _client.rpc<Object?>(
        'unregister_student_push_token',
        params: <String, Object?>{
          'p_case_id': caseId,
          'p_capability_token': capabilityToken,
          'p_fcm_token': fcmToken,
        },
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffActivationRedemption> redeemStaffActivationCode(
    String activationCode,
  ) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'redeem_staff_activation_code',
        params: <String, Object?>{'p_activation_code': activationCode},
      );
      return StaffActivationRedemption.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffActivationRedemption> redeemStaffActivationCodeWithProfile({
    required String activationCode,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'redeem_staff_activation_code_with_profile',
        params: <String, Object?>{
          'p_activation_code': activationCode,
          'p_first_name': firstName.trim(),
          'p_last_name': lastName.trim(),
        },
      );
      return StaffActivationRedemption.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffProfileView> getMyStaffProfile() async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'get_my_staff_profile',
      );
      return StaffProfileView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> updateMyStaffAvailabilityAndNotices({
    required bool isAvailable,
    required bool notifyNewAlerts,
    required bool notifyNewMessages,
  }) async {
    try {
      await _client.rpc<Object?>(
        'update_my_staff_availability_and_notices',
        params: <String, Object?>{
          'p_is_available': isAvailable,
          'p_notify_new_alerts': notifyNewAlerts,
          'p_notify_new_messages': notifyNewMessages,
        },
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> requestStaffInviteReplacement({
    required String institutionalEmail,
    required String reasonCode,
    String? notes,
  }) async {
    try {
      await _client.rpc<Object?>(
        'request_staff_invite_replacement',
        params: <String, Object?>{
          'p_institutional_email': institutionalEmail.trim(),
          'p_reason_code': reasonCode,
          'p_notes': notes,
        },
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<StaffActivationInviteView>> listStaffActivationInvites({
    String? institutionId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'list_staff_activation_invites',
        params: <String, Object?>{'p_institution_id': institutionId},
      );
      final List<Object?> rows = _requireList(response);
      return List<StaffActivationInviteView>.unmodifiable(
        rows.map(
          (Object? item) =>
              StaffActivationInviteView.fromJson(_requireMap(item)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> requestStaffActivationInvite({
    required String institutionalEmail,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? fullName,
    String? requesterProgramLabel,
    String? supervisorUserId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'request_staff_activation_invite',
        params: <String, Object?>{
          'p_institutional_email': institutionalEmail.trim(),
          'p_role': role.wireValue,
          'p_institution_id': institutionId,
          'p_staff_tier': staffTier,
          'p_full_name': fullName,
          'p_requester_program_label': requesterProgramLabel,
          'p_supervisor_user_id': supervisorUserId,
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffInviteIssueResult> issueStaffActivationInvite({
    String? institutionalEmail,
    SetuStaffRole? role,
    String? institutionId,
    String? staffTier,
    String? scopeLabel,
    String? fullName,
    String? supervisorUserId,
    int expiresInHours = 72,
    String? pendingInviteId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'issue_staff_activation_invite',
        params: <String, Object?>{
          'p_institutional_email': institutionalEmail?.trim(),
          'p_role': role?.wireValue,
          'p_institution_id': institutionId,
          'p_staff_tier': staffTier,
          'p_scope_label': scopeLabel,
          'p_full_name': fullName,
          'p_supervisor_user_id': supervisorUserId,
          'p_expires_in_hours': expiresInHours,
          'p_pending_invite_id': pendingInviteId,
        },
      );
      return StaffInviteIssueResult.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> revokeStaffActivationInvite({
    required String inviteId,
    String? reason,
  }) async {
    try {
      await _client.rpc<Object?>(
        'revoke_staff_activation_invite',
        params: <String, Object?>{'p_invite_id': inviteId, 'p_reason': reason},
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<StaffInviteIssueResult> replaceStaffActivationInvite({
    required String inviteId,
    String? newInstitutionalEmail,
    int expiresInHours = 72,
    String? reason,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'replace_staff_activation_invite',
        params: <String, Object?>{
          'p_invite_id': inviteId,
          'p_new_institutional_email': newInstitutionalEmail?.trim(),
          'p_expires_in_hours': expiresInHours,
          'p_reason': reason,
        },
      );
      return StaffInviteIssueResult.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CounselorDispatchCasesResult> listCounselorDispatchCases() async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'list_counselor_dispatch_cases',
      );
      return CounselorDispatchCasesResult.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseDispatchRecoverResult> recoverDeclinedCaseDispatch(
    String caseId,
  ) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'recover_declined_case_dispatch',
        params: <String, Object?>{'p_case_id': caseId},
      );
      return CaseDispatchRecoverResult.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<SchoolCoverageAndAssignmentsView> listSchoolCoverageAndAssignments({
    String? institutionId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'list_school_coverage_and_assignments',
        params: <String, Object?>{'p_institution_id': institutionId},
      );
      return SchoolCoverageAndAssignmentsView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> setSchoolExternalCoverage({
    required String institutionId,
    ExternalCoverageMode? mode,
    DateTime? until,
    bool? minedExternalEnabled,
  }) async {
    try {
      await _client.rpc<Object?>(
        'set_school_external_coverage',
        params: <String, Object?>{
          'p_institution_id': institutionId,
          'p_mode': mode?.wireValue,
          'p_until': until?.toUtc().toIso8601String(),
          'p_mined_external_enabled': minedExternalEnabled,
        },
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> assignExternalCounselorSchool({
    required String counselorUserId,
    required String institutionId,
    bool active = true,
  }) async {
    try {
      await _client.rpc<Object?>(
        'assign_external_counselor_school',
        params: <String, Object?>{
          'p_counselor_user_id': counselorUserId,
          'p_institution_id': institutionId,
          'p_active': active,
        },
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<PracticanteSupervisorNoticeView>>
  listMySupervisorNotices() async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'list_my_supervisor_notices',
      );
      final List<Object?> rows = _requireList(response);
      return List<PracticanteSupervisorNoticeView>.unmodifiable(
        rows.map(
          (Object? item) =>
              PracticanteSupervisorNoticeView.fromJson(_requireMap(item)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<StaffMembershipScope>> getMyStaffMemberships() async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'get_my_staff_memberships',
      );
      final List<Object?> items = _requireList(response);
      return List<StaffMembershipScope>.unmodifiable(
        items.map(
          (Object? item) => StaffMembershipScope.fromJson(_requireMap(item)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<StaffCaseSummary>> listCasesForScope({
    String? institutionId,
  }) async {
    try {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _client
          .from('cases')
          .select(
            'id,institution_id,reference_code,situation_type,student_role,origin,'
            'status,human_level,involves_staff,assigned_counselor_id,'
            'chat_available_notice,urgent_referral_triggered,concurrency_version,'
            'declared_at,received_centrally_at,closed_at,closed_reason,'
            'conversation_ended_at,student_piece',
          );
      if (institutionId != null) {
        query = query.eq('institution_id', institutionId);
      }
      final List<Map<String, dynamic>> rows = await query.order(
        'received_centrally_at',
        ascending: false,
      );
      return List<StaffCaseSummary>.unmodifiable(
        rows.map(
          (Map<String, dynamic> row) =>
              StaffCaseSummary.fromJson(_normalizeDynamicMap(row)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<AssignableCounselor>> listAssignableCounselors({
    String? institutionId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'list_assignable_counselors',
        params: <String, Object?>{'p_institution_id': institutionId},
      );
      final List<Object?> items = _requireList(response);
      return List<AssignableCounselor>.unmodifiable(
        items.map(
          (Object? item) => AssignableCounselor.fromJson(_requireMap(item)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> assignCaseCounselor({
    required String clientOperationId,
    required String caseId,
    required String counselorUserId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'assign_case_counselor',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
          'p_counselor_user_id': counselorUserId,
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> minedUpdateCaseSupervision({
    required String clientOperationId,
    required String caseId,
    required SetuCaseStatus nextStatus,
    String? reason,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'mined_update_case_supervision',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
          'p_next_status': nextStatus.wireValue,
          'p_reason': reason,
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseNarrativeView?> getCaseNarrative(String caseId) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from('case_narratives')
          .select(
            'case_id,narrative_text,location_text,approx_date_text,created_at',
          )
          .eq('case_id', caseId)
          .maybeSingle();
      if (row == null) return null;
      return CaseNarrativeView.fromJson(_normalizeDynamicMap(row));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<CaseChatMessageView>> listCaseMessages(String caseId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('case_messages')
          .select('id,case_id,sender_role,body,created_at')
          .eq('case_id', caseId)
          .order('created_at', ascending: true);
      return List<CaseChatMessageView>.unmodifiable(
        rows.map(
          (Map<String, dynamic> row) =>
              CaseChatMessageView.fromJson(_normalizeDynamicMap(row)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<CaseInternalNoteView>> listCaseInternalNotes(
    String caseId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('case_internal_notes')
          .select(
            'id,case_id,author_user_id,note_body,client_operation_id,created_at',
          )
          .eq('case_id', caseId)
          .order('created_at', ascending: false);
      return List<CaseInternalNoteView>.unmodifiable(
        rows.map(
          (Map<String, dynamic> row) =>
              CaseInternalNoteView.fromJson(_normalizeDynamicMap(row)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> enableCaseChat({
    required String clientOperationId,
    required String caseId,
    String? openingMessage,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'enable_case_chat',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
          'p_opening_message': openingMessage,
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseChatMessageView> sendCounselorChatMessage({
    required String caseId,
    required String clientOperationId,
    required String body,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'send_counselor_chat_message',
        params: <String, Object?>{
          'p_case_id': caseId,
          'p_client_operation_id': clientOperationId,
          'p_body': body,
        },
      );
      return CaseChatMessageView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseInternalNoteView> saveCaseInternalNote({
    required String caseId,
    required String clientOperationId,
    required String noteBody,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'save_case_internal_note',
        params: <String, Object?>{
          'p_case_id': caseId,
          'p_client_operation_id': clientOperationId,
          'p_note_body': noteBody,
        },
      );
      return CaseInternalNoteView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> assessCaseAndIssueSheet({
    required String clientOperationId,
    required String caseId,
    required int humanLevel,
    bool triggerUrgentReferral = false,
    bool issueSheet = false,
    String? guidanceNotes,
    bool omitSchoolDueToConflict = false,
    bool closeCase = false,
    String? closedReason,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'assess_case_and_issue_sheet',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
          'p_human_level': humanLevel,
          'p_trigger_urgent_referral': triggerUrgentReferral,
          'p_issue_sheet': issueSheet,
          'p_guidance_notes': guidanceNotes,
          'p_omit_school_due_to_conflict': omitSchoolDueToConflict,
          'p_close_case': closeCase,
          'p_closed_reason': closedReason,
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> endCaseConversation({
    required String clientOperationId,
    required String caseId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'end_case_conversation',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseSheetDraftView?> getCaseSheetDraft(String caseId) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'get_case_sheet_draft',
        params: <String, Object?>{'p_case_id': caseId},
      );
      if (response == null) return null;
      return CaseSheetDraftView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseSheetDraftView> saveCaseSheetDraft({
    required String caseId,
    required String guidanceDraft,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'save_case_sheet_draft',
        params: <String, Object?>{
          'p_case_id': caseId,
          'p_guidance_draft': guidanceDraft,
        },
      );
      return CaseSheetDraftView.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<CaseActionSheetView>> listCaseActionSheets({
    String? caseId,
  }) async {
    try {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _client
          .from('case_action_sheets')
          .select(
            'id,case_id,institution_id,version,issued_by,human_level,'
            'summary_type,summary_role,omit_school_due_to_conflict,guidance_notes,issued_at',
          );
      if (caseId != null) {
        query = query.eq('case_id', caseId);
      }
      final List<Map<String, dynamic>> rows = await query.order(
        'issued_at',
        ascending: false,
      );
      return List<CaseActionSheetView>.unmodifiable(
        rows.map(
          (Map<String, dynamic> row) =>
              CaseActionSheetView.fromJson(_normalizeDynamicMap(row)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<SchoolActionRecordView>> listSchoolActions(String caseId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('school_actions')
          .select(
            'id,case_id,institution_id,action_sheet_id,step,is_group_action,'
            'action_notes,proposes_closure,recorded_by,client_operation_id,created_at',
          )
          .eq('case_id', caseId)
          .order('created_at', ascending: true);
      return List<SchoolActionRecordView>.unmodifiable(
        rows.map(
          (Map<String, dynamic> row) =>
              SchoolActionRecordView.fromJson(_normalizeDynamicMap(row)),
        ),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> recordTeacherNotice({
    required String clientOperationId,
    required String institutionId,
    required SetuSituationType situationType,
    bool involvesStaff = false,
    DateTime? declaredAt,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'record_teacher_notice',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_institution_id': institutionId,
          'p_situation_type': situationType.wireValue,
          'p_involves_staff': involvesStaff,
          // Sin fecha, el servidor aplica su `DEFAULT now()`.
          'p_declared_at': ?declaredAt?.toUtc().toIso8601String(),
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, Object?>> recordSchoolAction({
    required String clientOperationId,
    required String caseId,
    required String? actionSheetId,
    required SetuSchoolActionStep step,
    bool isGroupAction = false,
    String actionNotes = '',
    bool proposesClosure = false,
    int expectedConcurrencyVersion = 1,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'record_school_action',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
          'p_action_sheet_id': actionSheetId,
          'p_step': step.wireValue,
          'p_is_group_action': isGroupAction,
          'p_action_notes': actionNotes,
          'p_proposes_closure': proposesClosure,
          'p_expected_concurrency_version': expectedConcurrencyVersion,
        },
      );
      return _requireMap(response);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<Map<String, String>> listActiveInstitutionNames() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('institutions')
          .select('id,name')
          .eq('active', true);
      return Map<String, String>.unmodifiable(<String, String>{
        for (final Map<String, dynamic> row in rows)
          '${row['id']}': '${row['name']}',
      });
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Stream<SetuAssignmentNotice> watchAssignedCaseNotices({
    required String counselorUserId,
  }) {
    late final StreamController<SetuAssignmentNotice> controller;
    RealtimeChannel? channel;

    controller = StreamController<SetuAssignmentNotice>(
      onListen: () {
        channel = _client
            .channel('counselor-assigned-$counselorUserId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'cases',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'assigned_counselor_id',
                value: counselorUserId,
              ),
              callback: (PostgresChangePayload payload) {
                if (payload.newRecord.isEmpty) return;
                final Map<String, Object?> row = _normalizeDynamicMap(
                  payload.newRecord,
                );
                final Object? oldCounselor = payload.oldRecord.isEmpty
                    ? null
                    : payload.oldRecord['assigned_counselor_id'];
                if (row['assigned_counselor_id'] == counselorUserId &&
                    oldCounselor != counselorUserId &&
                    !controller.isClosed) {
                  controller.add(SetuAssignmentNotice.fromCaseRow(row));
                }
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final RealtimeChannel? active = channel;
        if (active != null) {
          await _client.removeChannel(active);
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<CaseClaimResult> claimCaseCounselor({
    required String clientOperationId,
    required String caseId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'claim_case_counselor',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
        },
      );
      return CaseClaimResult.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<CaseDeclineResult> declineCaseDispatch({
    required String clientOperationId,
    required String caseId,
    String? reason,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'decline_case_dispatch',
        params: <String, Object?>{
          'p_client_operation_id': clientOperationId,
          'p_case_id': caseId,
          'p_reason': reason,
        },
      );
      return CaseDeclineResult.fromJson(_requireMap(response));
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<List<CaseDispatchRecord>> listCaseDispatchHistory({
    String? institutionId,
    String? caseId,
  }) async {
    try {
      final Object? response = await _client.rpc<Object?>(
        'list_case_dispatch_history',
        params: <String, Object?>{
          'p_institution_id': institutionId,
          'p_case_id': caseId,
        },
      );
      final List<Object?> rows = _requireList(response);
      return List<CaseDispatchRecord>.unmodifiable(<CaseDispatchRecord>[
        for (final Object? entry in rows)
          if (entry is Map<dynamic, dynamic>)
            CaseDispatchRecord.fromJson(_normalizeDynamicMap(entry)),
      ]);
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Stream<CaseDispatchRecord> watchIncomingDispatches({
    required String counselorUserId,
  }) {
    late final StreamController<CaseDispatchRecord> controller;
    RealtimeChannel? channel;

    controller = StreamController<CaseDispatchRecord>(
      onListen: () {
        channel = _client
            .channel('counselor-dispatches-$counselorUserId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'case_counselor_dispatches',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'counselor_user_id',
                value: counselorUserId,
              ),
              callback: (PostgresChangePayload payload) {
                if (payload.newRecord.isEmpty) return;
                final Map<String, Object?> row = _normalizeDynamicMap(
                  payload.newRecord,
                );
                if (row['counselor_user_id'] == counselorUserId &&
                    !controller.isClosed) {
                  controller.add(CaseDispatchRecord.fromJson(row));
                }
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final RealtimeChannel? active = channel;
        if (active != null) {
          await _client.removeChannel(active);
        }
      },
    );

    return controller.stream;
  }

  @override
  Stream<CaseChatMessageView> watchCaseMessages(String caseId) {
    late final StreamController<CaseChatMessageView> controller;
    RealtimeChannel? channel;

    controller = StreamController<CaseChatMessageView>(
      onListen: () {
        channel = _client
            .channel('case-messages-$caseId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'case_messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'case_id',
                value: caseId,
              ),
              callback: (PostgresChangePayload payload) {
                if (payload.newRecord.isEmpty || controller.isClosed) return;
                final Map<String, Object?> row = _normalizeDynamicMap(
                  payload.newRecord,
                );
                try {
                  controller.add(CaseChatMessageView.fromJson(row));
                } on FormatException {
                  // Ignora registros incompletos del canal en vivo.
                }
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final RealtimeChannel? active = channel;
        if (active != null) {
          await _client.removeChannel(active);
        }
      },
    );

    return controller.stream;
  }

  Map<String, Object?> _requireMap(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    if (raw is Map<dynamic, dynamic>) return _normalizeDynamicMap(raw);
    throw const FormatException('Se esperaba un objeto JSON desde Supabase.');
  }

  List<Object?> _requireList(Object? raw) {
    if (raw is List<Object?>) return raw;
    if (raw is List<dynamic>) return List<Object?>.from(raw);
    throw const FormatException('Se esperaba una lista JSON desde Supabase.');
  }

  Map<String, Object?> _normalizeDynamicMap(Map<dynamic, dynamic> source) {
    final Map<String, Object?> result = <String, Object?>{};
    source.forEach((Object? key, Object? value) {
      if (key != null) {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  GatewayException _mapError(Object error) {
    if (error is GatewayException) return error;
    if (error is PostgrestException) {
      return GatewayException(error.code ?? 'postgrest_error', error.message);
    }
    if (error is AuthException) {
      return GatewayException(error.code ?? 'auth_error', error.message);
    }
    return GatewayException('remote_error', error.toString());
  }
}
