import '../../shared/models/cureando_models.dart';
import '../../shared/remote/setu_remote_gateway.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'staff_backend.dart';

/// Adaptador del puerto de personal hacia Supabase. No agrega reglas: cada
/// llamada la autoriza el servidor.
class RemoteStaffBackend implements StaffBackend {
  RemoteStaffBackend(this._gateway, {this.loadInstitutionNames, this.rpc});

  final SetuRemoteGateway _gateway;

  /// Lectura pública de los centros activos; null si no está disponible.
  final Future<Map<String, String>> Function()? loadInstitutionNames;

  /// Llamada directa a una función del servidor. Se usa solo donde el
  /// contrato del cliente remoto todavía no coincide con la función SQL.
  final Future<Object?> Function(String name, Map<String, Object?> params)? rpc;

  @override
  bool get isDemo => false;

  @override
  String? get currentUserId => _gateway.currentStaffUserId;

  @override
  Future<StaffActivationPreview> previewActivation(
    String code, {
    String? email,
  }) => _gateway.previewStaffActivationCode(
    activationCode: code,
    institutionalEmail: email,
  );

  @override
  Future<void> signUp({required String email, required String password}) =>
      _gateway.signUpStaffAccount(email: email, password: password);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _gateway.signInStaffWithPassword(email: email, password: password);

  @override
  Future<void> signOut() => _gateway.signOutStaff();

  @override
  Future<StaffActivationRedemption> redeemActivation(String code) =>
      _gateway.redeemStaffActivationCode(code);

  @override
  Future<List<StaffMembershipScope>> memberships() =>
      _gateway.getMyStaffMemberships();

  @override
  Future<Map<String, String>> institutionNames() async =>
      await loadInstitutionNames?.call() ?? const <String, String>{};

  @override
  Future<List<StaffCaseSummary>> cases({String? institutionId}) =>
      _gateway.listCasesForScope(institutionId: institutionId);

  @override
  Future<List<AssignableCounselor>> counselors({String? institutionId}) =>
      _gateway.listAssignableCounselors(institutionId: institutionId);

  @override
  Future<void> assignCounselor({
    required String operationId,
    required String caseId,
    required String counselorUserId,
  }) => _gateway.assignCaseCounselor(
    clientOperationId: operationId,
    caseId: caseId,
    counselorUserId: counselorUserId,
  );

  @override
  Stream<SetuAssignmentNotice> assignmentNotices() {
    final String? user = _gateway.currentStaffUserId;
    return user == null
        ? const Stream<SetuAssignmentNotice>.empty()
        : _gateway.watchAssignedCaseNotices(counselorUserId: user);
  }

  @override
  Future<CaseNarrativeView?> narrative(String caseId) =>
      _gateway.getCaseNarrative(caseId);

  @override
  Future<List<CaseChatMessageView>> messages(String caseId) =>
      _gateway.listCaseMessages(caseId);

  @override
  Future<List<CaseInternalNoteView>> notes(String caseId) =>
      _gateway.listCaseInternalNotes(caseId);

  @override
  Future<void> enableChat({
    required String operationId,
    required String caseId,
  }) => _gateway.enableCaseChat(clientOperationId: operationId, caseId: caseId);

  @override
  Future<void> sendMessage({
    required String operationId,
    required String caseId,
    required String body,
  }) => _gateway.sendCounselorChatMessage(
    caseId: caseId,
    clientOperationId: operationId,
    body: body,
  );

  @override
  Future<void> saveNote({
    required String operationId,
    required String caseId,
    required String body,
  }) => _gateway.saveCaseInternalNote(
    caseId: caseId,
    clientOperationId: operationId,
    noteBody: body,
  );

  @override
  Future<void> assess({
    required String operationId,
    required CaseAssessment assessment,
  }) => _gateway.assessCaseAndIssueSheet(
    clientOperationId: operationId,
    caseId: assessment.caseId,
    humanLevel: assessment.level,
    triggerUrgentReferral: assessment.urgentReferral,
    issueSheet: assessment.issueSheet,
    guidanceNotes: assessment.guidanceNotes.isEmpty
        ? null
        : assessment.guidanceNotes,
    omitSchoolDueToConflict: assessment.omitSchool,
    closeCase: assessment.closeCase,
    closedReason: assessment.closedReason.isEmpty
        ? null
        : assessment.closedReason,
  );

  @override
  Future<List<CaseActionSheetView>> sheets({String? caseId}) =>
      _gateway.listCaseActionSheets(caseId: caseId);

  @override
  Future<List<SchoolActionRecordView>> schoolActions(String caseId) =>
      _gateway.listSchoolActions(caseId);

  @override
  Future<void> recordSchoolAction({
    required String operationId,
    required SchoolActionDraft action,
  }) async {
    final Future<Object?> Function(String, Map<String, Object?>)? call = rpc;
    if (call == null) {
      throw const GatewayException('remote_error', 'rpc_unavailable');
    }
    // PENDIENTE: `SetuRemoteGateway.recordSchoolAction` envía parámetros que
    // la función SQL `record_school_action` no tiene. Hasta que se alinee,
    // se llama a la función con su firma real.
    try {
      await call('record_school_action', <String, Object?>{
        'p_client_operation_id': operationId,
        'p_case_id': action.caseId,
        'p_action_sheet_id': action.actionSheetId,
        'p_step': action.step.wireValue,
        'p_is_group_action': action.isGroupAction,
        'p_action_notes': action.notes,
        'p_proposes_closure': action.proposesClosure,
        'p_expected_concurrency_version': action.expectedVersion,
      });
    } on GatewayException {
      rethrow;
    } on Object catch (error) {
      throw GatewayException('remote_error', error.toString());
    }
  }

  // PENDIENTE: un aviso docente no tiene participación del estudiante y el
  // listado de casos del cliente remoto todavía no acepta ese valor vacío.
  // Registrarlo hoy dejaría las bandejas sin poder cargar.
  @override
  bool get supportsTeacherNotice => false;

  @override
  Future<void> recordTeacherNotice({
    required String operationId,
    required String institutionId,
    required SetuSituationType situationType,
    required bool involvesStaff,
  }) => throw const GatewayException(
    'remote_error',
    'teacher_notice_not_connected',
  );
}
