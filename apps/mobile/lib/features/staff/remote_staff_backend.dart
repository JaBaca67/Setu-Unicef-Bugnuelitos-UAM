import '../../shared/remote/setu_remote_gateway.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'staff_backend.dart';

/// Adaptador del puerto de personal hacia Supabase. No agrega reglas: cada
/// llamada la autoriza el servidor.
class RemoteStaffBackend implements StaffBackend {
  RemoteStaffBackend(this._gateway);

  static const String _authRedirectUrl = 'setu://login-callback';

  final SetuRemoteGateway _gateway;

  @override
  bool get isDemo => false;

  @override
  String? get currentUserId => _gateway.currentStaffUserId;

  @override
  String? get currentUserEmail => _gateway.currentStaffEmail;

  @override
  bool get isEmailConfirmed => _gateway.isCurrentStaffEmailConfirmed;

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
      _gateway.signUpStaffAccount(
        email: email,
        password: password,
        emailRedirectTo: _authRedirectUrl,
      );

  @override
  Future<void> resendConfirmationEmail({required String email}) =>
      _gateway.resendStaffConfirmationEmail(
        email: email,
        emailRedirectTo: _authRedirectUrl,
      );

  @override
  Future<void> refreshAuthSession() => _gateway.refreshStaffAuthSession();

  @override
  Future<void> sendPasswordReset({required String email}) =>
      _gateway.sendStaffPasswordResetEmail(email: email);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _gateway.signInStaffWithPassword(email: email, password: password);

  @override
  Future<void> signOut() => _gateway.signOutStaff();

  @override
  Future<StaffActivationRedemption> redeemActivation(String code) =>
      _gateway.redeemStaffActivationCode(code);

  @override
  Future<StaffActivationRedemption> redeemActivationWithProfile({
    required String code,
    required String firstName,
    required String lastName,
  }) => _gateway.redeemStaffActivationCodeWithProfile(
    activationCode: code,
    firstName: firstName,
    lastName: lastName,
  );

  @override
  Future<List<StaffMembershipScope>> memberships() =>
      _gateway.getMyStaffMemberships();

  @override
  Future<StaffProfileView?> profile() => _gateway.getMyStaffProfile();

  @override
  Future<void> updateAvailabilityAndNotices({
    required bool isAvailable,
    required bool notifyNewAlerts,
    required bool notifyNewMessages,
  }) => _gateway.updateMyStaffAvailabilityAndNotices(
    isAvailable: isAvailable,
    notifyNewAlerts: notifyNewAlerts,
    notifyNewMessages: notifyNewMessages,
  );

  @override
  Future<void> requestInviteReplacement({
    required String email,
    required String reasonCode,
    String? notes,
  }) => _gateway.requestStaffInviteReplacement(
    institutionalEmail: email,
    reasonCode: reasonCode,
    notes: notes,
  );

  @override
  Future<List<StaffActivationInviteView>> invites({String? institutionId}) =>
      _gateway.listStaffActivationInvites(institutionId: institutionId);

  @override
  Future<void> requestInvite({
    required String email,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? fullName,
    String? requesterProgramLabel,
    String? supervisorUserId,
  }) => _gateway.requestStaffActivationInvite(
    institutionalEmail: email,
    role: role,
    institutionId: institutionId,
    staffTier: staffTier,
    fullName: fullName,
    requesterProgramLabel: requesterProgramLabel,
    supervisorUserId: supervisorUserId,
  );

  @override
  Future<StaffInviteIssueResult> issueInvite({
    String? email,
    SetuStaffRole? role,
    String? institutionId,
    String? staffTier,
    String? scopeLabel,
    String? fullName,
    String? supervisorUserId,
    int expiresInHours = 72,
    String? pendingInviteId,
  }) => _gateway.issueStaffActivationInvite(
    institutionalEmail: email,
    role: role,
    institutionId: institutionId,
    staffTier: staffTier,
    scopeLabel: scopeLabel,
    fullName: fullName,
    supervisorUserId: supervisorUserId,
    expiresInHours: expiresInHours,
    pendingInviteId: pendingInviteId,
  );

  @override
  Future<void> revokeInvite({required String inviteId, String? reason}) =>
      _gateway.revokeStaffActivationInvite(inviteId: inviteId, reason: reason);

  @override
  Future<StaffInviteIssueResult> replaceInvite({
    required String inviteId,
    String? newEmail,
    int expiresInHours = 72,
    String? reason,
  }) => _gateway.replaceStaffActivationInvite(
    inviteId: inviteId,
    newInstitutionalEmail: newEmail,
    expiresInHours: expiresInHours,
    reason: reason,
  );

  @override
  Future<void> submitAccessRequest({
    required String fullName,
    required String email,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? requesterProgramLabel,
  }) => _gateway.submitStaffAccessRequest(
    fullName: fullName,
    institutionalEmail: email,
    role: role,
    institutionId: institutionId,
    staffTier: staffTier,
    requesterProgramLabel: requesterProgramLabel,
  );

  @override
  Future<BulkInviteResult> issueInvitesBulk({
    required List<BulkInviteRowDraft> rows,
    int expiresInHours = 72,
  }) => _gateway.issueStaffInvitesBulk(
    rows: rows,
    expiresInHours: expiresInHours,
  );

  @override
  Future<InviteEmailDispatchResult> sendInviteEmails({
    required List<InviteEmailRecipient> recipients,
  }) => _gateway.sendStaffInviteEmails(recipients: recipients);

  @override
  Future<CounselorDispatchCasesResult> counselorDispatches() =>
      _gateway.listCounselorDispatchCases();

  @override
  Future<CaseDispatchRecoverResult> recoverDeclinedDispatch(String caseId) =>
      _gateway.recoverDeclinedCaseDispatch(caseId);

  @override
  Future<SchoolCoverageAndAssignmentsView> schoolCoverageAndAssignments({
    String? institutionId,
  }) => _gateway.listSchoolCoverageAndAssignments(institutionId: institutionId);

  @override
  Future<void> setSchoolExternalCoverage({
    required String institutionId,
    ExternalCoverageMode? mode,
    DateTime? until,
    bool? minedExternalEnabled,
  }) => _gateway.setSchoolExternalCoverage(
    institutionId: institutionId,
    mode: mode,
    until: until,
    minedExternalEnabled: minedExternalEnabled,
  );

  @override
  Future<void> assignExternalCounselorSchool({
    required String counselorUserId,
    required String institutionId,
    bool active = true,
  }) => _gateway.assignExternalCounselorSchool(
    counselorUserId: counselorUserId,
    institutionId: institutionId,
    active: active,
  );

  @override
  Future<List<PracticanteSupervisorNoticeView>> supervisorNotices() =>
      _gateway.listMySupervisorNotices();

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
