import '../../shared/remote/setu_remote_gateway.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'staff_backend.dart';

/// Adaptador del puerto de personal hacia Supabase. No agrega reglas: cada
/// llamada la autoriza el servidor.
class RemoteStaffBackend implements StaffBackend {
  RemoteStaffBackend(this._gateway);

  final SetuRemoteGateway _gateway;

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
  Future<Map<String, String>> institutionNames() =>
      _gateway.listActiveInstitutionNames();

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
  Future<CaseClaimResult> claimCase({
    required String operationId,
    required String caseId,
  }) => _gateway.claimCaseCounselor(
    clientOperationId: operationId,
    caseId: caseId,
  );

  @override
  Future<CaseDeclineResult> declineDispatch({
    required String operationId,
    required String caseId,
    String? reason,
  }) => _gateway.declineCaseDispatch(
    clientOperationId: operationId,
    caseId: caseId,
    reason: reason,
  );

  @override
  Future<List<CaseDispatchRecord>> dispatchHistory({
    String? institutionId,
    String? caseId,
  }) => _gateway.listCaseDispatchHistory(
    institutionId: institutionId,
    caseId: caseId,
  );

  @override
  Stream<CaseDispatchRecord> incomingDispatches() {
    final String? user = _gateway.currentStaffUserId;
    return user == null
        ? const Stream<CaseDispatchRecord>.empty()
        : _gateway.watchIncomingDispatches(counselorUserId: user);
  }

  @override
  Future<CaseNarrativeView?> narrative(String caseId) =>
      _gateway.getCaseNarrative(caseId);

  @override
  Future<List<CaseChatMessageView>> messages(String caseId) =>
      _gateway.listCaseMessages(caseId);

  @override
  Stream<CaseChatMessageView> watchMessages(String caseId) =>
      _gateway.watchCaseMessages(caseId);

  @override
  Future<List<CaseInternalNoteView>> notes(String caseId) =>
      _gateway.listCaseInternalNotes(caseId);

  @override
  Future<void> enableChat({
    required String operationId,
    required String caseId,
    String? openingMessage,
  }) => _gateway.enableCaseChat(
    clientOperationId: operationId,
    caseId: caseId,
    openingMessage:
        openingMessage ??
        'Hola, soy parte del equipo de escucha. Cuando quieras, podés '
            'contarme lo que pasó.',
  );

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
  }) => _gateway.recordSchoolAction(
    clientOperationId: operationId,
    caseId: action.caseId,
    actionSheetId: action.actionSheetId,
    step: action.step,
    isGroupAction: action.isGroupAction,
    actionNotes: action.notes,
    proposesClosure: action.proposesClosure,
    expectedConcurrencyVersion: action.expectedVersion,
  );

  @override
  bool get supportsTeacherNotice => true;

  @override
  Future<void> recordTeacherNotice({
    required String operationId,
    required String institutionId,
    required SetuSituationType situationType,
    required bool involvesStaff,
  }) => _gateway.recordTeacherNotice(
    clientOperationId: operationId,
    institutionId: institutionId,
    situationType: situationType,
    involvesStaff: involvesStaff,
  );
}
