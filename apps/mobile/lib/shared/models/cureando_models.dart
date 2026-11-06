import 'package:flutter/foundation.dart';

enum RelationType { affected, witness }

enum ReportStatus { received, inReview, accompanied, closed }

enum AuthorRole { student, staff }

enum OrientationRole { counseling, psychology, supervisor }

enum SituationType { teasing, exclusion, physical, cyberbullying, other }

enum PlaceType { classroom, playground, bathrooms, exit, online, other }

enum EarlyWarning { recent, recurring, needsSupportSoon }

enum SupportRequestType { followUp, discreetAppointment, externalSupport }

enum SimulatedNetwork { connected, offline, uncertain }

class GatewayException implements Exception {
  const GatewayException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'GatewayException($code): $message';
}

@immutable
class InstitutionView {
  const InstitutionView({
    required this.id,
    required this.name,
    this.active = true,
  });
  final String id;
  final String name;
  final bool active;
}

@immutable
class StudentAccountView {
  const StudentAccountView({
    required this.id,
    required this.alias,
    required this.institutionId,
  });
  final String id;
  final String alias;
  final String institutionId;
}

/// The raw recovery credential is returned only at account creation/reset.
/// Do not log, serialize to disk or add it to a student profile.
@immutable
class AccountRegistration {
  const AccountRegistration(this.account, this.backupCode);
  final StudentAccountView account;
  final String backupCode;
}

@immutable
class SubmitReportInput {
  SubmitReportInput({
    required this.clientRequestId,
    required this.relation,
    required this.body,
    this.recipient = OrientationRole.counseling,
    this.involvesStaff = false,
    List<SituationType> situations = const <SituationType>[],
    this.place,
    this.earlyWarning,
    this.locationText = '',
    this.approxDateText = '',
  }) : situations = List<SituationType>.unmodifiable(situations);
  final String clientRequestId;
  final RelationType relation;
  final String body;
  final OrientationRole recipient;
  final bool involvesStaff;
  final List<SituationType> situations;
  final PlaceType? place;
  final EarlyWarning? earlyWarning;
  final String locationText;
  final String approxDateText;

  Map<String, Object?> toJson() => <String, Object?>{
    'relation': relation.name,
    'body': body,
    'recipient': recipient.name,
    'involvesStaff': involvesStaff,
    'situations': situations.map((SituationType s) => s.name).toList(),
    'place': place?.name,
    'earlyWarning': earlyWarning?.name,
    'locationText': locationText,
    'approxDateText': approxDateText,
  };
}

@immutable
class ReportReceipt {
  const ReportReceipt({
    required this.reportId,
    required this.referenceCode,
    required this.createdAt,
  });
  final String reportId;
  final String referenceCode;
  final DateTime createdAt;
}

@immutable
class CaseAccessCredential {
  const CaseAccessCredential(this.referenceCode, this.pin);
  final String referenceCode;
  final String pin;
}

@immutable
class VisibleMessage {
  const VisibleMessage({
    required this.id,
    required this.role,
    required this.body,
    required this.createdAt,
  });
  final String id;
  final AuthorRole role;
  final String body;
  final DateTime createdAt;
  String get authorLabel =>
      role == AuthorRole.student ? 'Estudiante' : 'Equipo de orientación';
}

@immutable
class SupportRequestView {
  const SupportRequestView({
    required this.id,
    required this.type,
    required this.createdAt,
  });
  final String id;
  final SupportRequestType type;
  final DateTime createdAt;
}

@immutable
class StudentCaseSummary {
  const StudentCaseSummary({
    required this.reportId,
    required this.referenceCode,
    required this.status,
    required this.createdAt,
    required this.hasUnreadStaffReply,
  });
  final String reportId;
  final String referenceCode;
  final ReportStatus status;
  final DateTime createdAt;
  final bool hasUnreadStaffReply;
}

/// Deliberately has no internal notes, staff identity, PIN digest or account ID.
@immutable
class StudentCaseDetailView {
  StudentCaseDetailView({
    required this.summary,
    required this.body,
    required this.relation,
    required this.recipient,
    required this.involvesStaff,
    required List<VisibleMessage> messages,
    required List<SupportRequestView> requests,
    List<SituationType> situations = const <SituationType>[],
    this.place,
    this.earlyWarning,
    this.locationText = '',
    this.approxDateText = '',
    this.closedReason,
  }) : messages = List<VisibleMessage>.unmodifiable(messages),
       requests = List<SupportRequestView>.unmodifiable(requests),
       situations = List<SituationType>.unmodifiable(situations);
  final StudentCaseSummary summary;
  final String body;
  final RelationType relation;
  final OrientationRole recipient;
  final bool involvesStaff;
  final String? closedReason;
  final List<VisibleMessage> messages;
  final List<SupportRequestView> requests;
  final List<SituationType> situations;
  final PlaceType? place;
  final EarlyWarning? earlyWarning;
  final String locationText;
  final String approxDateText;
}

@immutable
class SendMessageInput {
  const SendMessageInput({
    required this.reportId,
    required this.clientRequestId,
    required this.body,
  });
  final String reportId;
  final String clientRequestId;
  final String body;
}
