import '../models/cureando_models.dart';
import '../models/staff_models.dart';

abstract class CureandoGateway {
  Future<void> initialize();
  Future<InstitutionView> checkInstitutionInvite(String code);
  Future<AccountRegistration> registerStudent({
    required String alias,
    required String pin,
    required String inviteCode,
  });
  Future<StudentAccountView> signIn({
    required String alias,
    required String pin,
  });
  Future<void> resetPin({
    required String alias,
    required String backupCode,
    required String newPin,
  });
  Future<void> signOut();
  Future<StudentAccountView?> currentAccount();
  Future<ReportReceipt> submitReport(SubmitReportInput input);
  Future<List<StudentCaseSummary>> listMyReports();
  Future<StudentCaseDetailView> getReportDetail(String reportId);
  Future<void> sendStudentMessage(SendMessageInput input);
  Future<SupportRequestView> requestSupport({
    required String reportId,
    required SupportRequestType type,
    required String clientRequestId,
  });
  Future<CaseAccessCredential> createCaseAccess(String reportId);
  Future<StudentCaseDetailView> accessCase({
    required String referenceCode,
    required String pin,
  });
}

abstract class StaffCureandoGateway {
  Future<List<StudentCaseSummary>> listReports();
  Future<StaffCaseDetailView> getReportDetail(String reportId);
  Future<void> sendReply(SendMessageInput input);
  Future<void> addInternalNote(SendMessageInput input);
  Future<void> changeStatus({
    required String reportId,
    required ReportStatus status,
    required String reason,
    required String clientRequestId,
  });
}
