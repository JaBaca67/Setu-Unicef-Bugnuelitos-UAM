/// Modelos inmutables y enumeraciones alineadas al esquema SQL de SéTú en Supabase.
library;

/// Roles institucionales separados en `staff_memberships` y `staff_activation_invites`.
enum SetuStaffRole {
  minedSupervisor('mined_supervisor', 'MINED central'),
  counselingDesk('counseling_desk', 'Mesa de Escucha'),
  schoolDirector('school_director', 'Dirección del centro');

  const SetuStaffRole(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static SetuStaffRole fromWire(String value) {
    for (final SetuStaffRole role in values) {
      if (role.wireValue == value) return role;
    }
    throw FormatException('Rol institucional no reconocido: $value');
  }
}

/// Tipos de situación definidos en `public.case_situation_type`.
enum SetuSituationType {
  physicalBullying('physical_bullying', 'Agresión física'),
  verbalBullying('verbal_bullying', 'Burlas o insultos'),
  socialBullying('social_bullying', 'Exclusión o rumores'),
  cyberbullying('cyberbullying', 'Acoso en línea'),
  sexualViolence('sexual_violence', 'Violencia o abuso sexual'),
  needToTalk('need_to_talk', 'Necesito hablar');

  const SetuSituationType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static SetuSituationType fromWire(String value) {
    for (final SetuSituationType item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Tipo de situación no reconocido: $value');
  }
}

/// Rol declarado por quien envía la alerta en `public.student_case_role`.
enum SetuStudentCaseRole {
  victim('victim', 'Me está pasando a mí'),
  solidarityWitness('solidarity_witness', 'Lo vi o apoyo a alguien');

  const SetuStudentCaseRole(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static SetuStudentCaseRole fromWire(String value) {
    for (final SetuStudentCaseRole item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Rol en el caso no reconocido: $value');
  }
}

/// Canal de ingreso en `public.alert_origin`.
enum SetuAlertOrigin {
  online('online'),
  mesh('mesh'),
  teacherNotice('teacher_notice');

  const SetuAlertOrigin(this.wireValue);

  final String wireValue;

  static SetuAlertOrigin fromWire(String value) {
    for (final SetuAlertOrigin item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Origen de alerta no reconocido: $value');
  }
}

/// Estados del ciclo de caso en `public.case_status`.
enum SetuCaseStatus {
  received('received', 'Recibida'),
  inListening('in_listening', 'En escucha'),
  sheetSent('sheet_sent', 'Ficha emitida'),
  schoolActing('school_acting', 'En actuación escolar'),
  escalated('escalated', 'Escalada'),
  closed('closed', 'Cerrada');

  const SetuCaseStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static SetuCaseStatus fromWire(String value) {
    for (final SetuCaseStatus item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Estado de caso no reconocido: $value');
  }
}

/// Pasos del protocolo institucional en `public.school_action_step`.
enum SetuSchoolActionStep {
  identify('identify', 'Identificar'),
  notifyDirection('notify_direction', 'Notificar a Dirección'),
  notifyFamilyOrGroup(
    'notify_family_or_group',
    'Informar a familia o grupo según ficha',
  ),
  accompany('accompany', 'Acompañar'),
  followUp('follow_up', 'Dar seguimiento');

  const SetuSchoolActionStep(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static SetuSchoolActionStep fromWire(String value) {
    for (final SetuSchoolActionStep item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Paso institucional no reconocido: $value');
  }
}

/// Formatos editoriales del espacio Información en `public.editorial_resource_format`.
enum SetuEditorialFormat {
  article('article'),
  video('video'),
  testimony('testimony'),
  guide('guide');

  const SetuEditorialFormat(this.wireValue);

  final String wireValue;

  static SetuEditorialFormat fromWire(String value) {
    for (final SetuEditorialFormat item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Formato editorial no reconocido: $value');
  }
}

/// Emisores permitidos en `public.case_message_sender`.
enum SetuMessageSender {
  student('student'),
  counselingDesk('counseling_desk');

  const SetuMessageSender(this.wireValue);

  final String wireValue;

  static SetuMessageSender fromWire(String value) {
    for (final SetuMessageSender item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Emisor de mensaje no reconocido: $value');
  }
}

/// Instantánea serializable de la pieza simbólica elegida por el estudiante (ADR 0015).
class StudentPieceSnapshot {
  const StudentPieceSnapshot({
    this.shape,
    this.color,
    this.accessories = const <String>[],
    this.displayName,
    this.rawJson = const <String, Object?>{},
  });

  final String? shape;
  final String? color;
  final List<String> accessories;
  final String? displayName;
  final Map<String, Object?> rawJson;

  factory StudentPieceSnapshot.fromJson(Map<String, Object?> json) {
    final List<String> parsedAccessories = <String>[];
    final Object? rawAcc = json['accessories'];
    if (rawAcc is List<Object?>) {
      for (final Object? entry in rawAcc) {
        if (entry != null) {
          parsedAccessories.add(entry.toString());
        }
      }
    } else if (json['accessoryKey'] is String) {
      parsedAccessories.add(json['accessoryKey'] as String);
    }

    return StudentPieceSnapshot(
      shape: _readNullableString(json, 'shape') ??
          _readNullableString(json, 'variant'),
      color: _readNullableString(json, 'color') ??
          _readNullableString(json, 'paletteKey'),
      accessories: List<String>.unmodifiable(parsedAccessories),
      displayName: _readNullableString(json, 'displayName'),
      rawJson: Map<String, Object?>.unmodifiable(json),
    );
  }

  Map<String, Object?> toJson() {
    if (rawJson.isNotEmpty) {
      return Map<String, Object?>.from(rawJson);
    }
    return <String, Object?>{
      if (shape != null) 'shape': shape,
      if (color != null) 'color': color,
      'accessories': accessories,
      if (displayName != null) 'displayName': displayName,
    };
  }
}

/// Resultado de `resolve_public_school` (sin exponer verificadores privados).
class PublicSchoolResolution {
  const PublicSchoolResolution({
    required this.id,
    required this.publicCode,
    required this.name,
    required this.municipality,
    required this.department,
    required this.radiusMeters,
    required this.configVersion,
    this.referenceLat,
    this.referenceLng,
  });

  final String id;
  final String publicCode;
  final String name;
  final String municipality;
  final String department;
  final double? referenceLat;
  final double? referenceLng;
  final int radiusMeters;
  final int configVersion;

  factory PublicSchoolResolution.fromJson(Map<String, Object?> json) {
    return PublicSchoolResolution(
      id: _readString(json, 'id'),
      publicCode: _readString(json, 'public_code'),
      name: _readString(json, 'name'),
      municipality: _readString(json, 'municipality'),
      department: _readString(json, 'department'),
      referenceLat: _readNullableDouble(json, 'reference_lat'),
      referenceLng: _readNullableDouble(json, 'reference_lng'),
      radiusMeters: _readInt(json, 'radius_meters', fallback: 150),
      configVersion: _readInt(json, 'config_version', fallback: 1),
    );
  }
}

/// Payload para enviar una alerta real con operación idempotente y pieza opcional.
class StudentAlertSubmission {
  const StudentAlertSubmission({
    required this.clientOperationId,
    required this.publicSchoolCode,
    required this.situationType,
    required this.studentRole,
    required this.origin,
    required this.involvesStaff,
    required this.declaredAt,
    required this.capabilityVerifierHash,
    this.narrativeText,
    this.locationText = '',
    this.approxDateText = '',
    this.studentPiece,
  });

  final String clientOperationId;
  final String publicSchoolCode;
  final SetuSituationType situationType;
  final SetuStudentCaseRole studentRole;
  final SetuAlertOrigin origin;
  final bool involvesStaff;
  final DateTime declaredAt;
  final String capabilityVerifierHash;
  final String? narrativeText;
  final String locationText;
  final String approxDateText;
  final StudentPieceSnapshot? studentPiece;
}

/// Acuse devuelto por `submit_student_alert` al confirmar recepción central.
class StudentAlertReceipt {
  const StudentAlertReceipt({
    required this.caseId,
    required this.referenceCode,
    required this.institutionId,
    required this.origin,
    required this.receivedCentrallyAt,
    this.studentPiece,
  });

  final String caseId;
  final String referenceCode;
  final String institutionId;
  final SetuAlertOrigin origin;
  final DateTime receivedCentrallyAt;
  final StudentPieceSnapshot? studentPiece;

  factory StudentAlertReceipt.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? pieceMap = _readNullableMap(json, 'student_piece');
    return StudentAlertReceipt(
      caseId: _readString(json, 'case_id'),
      referenceCode: _readString(json, 'reference_code'),
      institutionId: _readString(json, 'institution_id'),
      origin: SetuAlertOrigin.fromWire(_readString(json, 'origin')),
      receivedCentrallyAt: _readDateTime(json, 'received_centrally_at'),
      studentPiece: pieceMap == null
          ? null
          : StudentPieceSnapshot.fromJson(pieceMap),
    );
  }
}

/// Mensaje persistido en `case_messages` (usado en chat humano estudiante <-> Mesa).
class CaseChatMessageView {
  const CaseChatMessageView({
    required this.id,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    this.caseId,
  });

  final String id;
  final SetuMessageSender senderRole;
  final String body;
  final DateTime createdAt;
  final String? caseId;

  factory CaseChatMessageView.fromJson(Map<String, Object?> json) {
    return CaseChatMessageView(
      id: _readString(json, 'id'),
      caseId: _readNullableString(json, 'case_id'),
      senderRole: SetuMessageSender.fromWire(_readString(json, 'sender_role')),
      body: _readString(json, 'body'),
      createdAt: _readDateTime(json, 'created_at'),
    );
  }
}

/// Estado privado recuperado por el estudiante con su token de capacidad (E08).
class StudentChatSessionView {
  const StudentChatSessionView({
    required this.caseId,
    required this.chatAvailableNotice,
    required this.messages,
    this.studentPiece,
  });

  final String caseId;
  final bool chatAvailableNotice;
  final StudentPieceSnapshot? studentPiece;
  final List<CaseChatMessageView> messages;

  factory StudentChatSessionView.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? pieceMap = _readNullableMap(json, 'student_piece');
    final List<Object?> rawMessages = _readList(json, 'messages');
    final List<CaseChatMessageView> parsedMessages = <CaseChatMessageView>[];
    for (final Object? entry in rawMessages) {
      if (entry is Map<String, Object?>) {
        parsedMessages.add(CaseChatMessageView.fromJson(entry));
      } else if (entry is Map<dynamic, dynamic>) {
        parsedMessages.add(CaseChatMessageView.fromJson(_castMap(entry)));
      }
    }
    return StudentChatSessionView(
      caseId: _readString(json, 'case_id'),
      chatAvailableNotice: _readBool(json, 'chat_available_notice'),
      studentPiece: pieceMap == null
          ? null
          : StudentPieceSnapshot.fromJson(pieceMap),
      messages: List<CaseChatMessageView>.unmodifiable(parsedMessages),
    );
  }
}

/// Resultado de `preview_staff_activation_code` antes de crear cuenta o confirmar acceso.
class StaffActivationPreview {
  const StaffActivationPreview({
    required this.ok,
    this.error,
    this.inviteId,
    this.role,
    this.institutionId,
    this.institutionPublicCode,
    this.institutionName,
    this.scopeLabel,
    this.expiresAt,
    this.remainingAttempts,
    this.lockedUntil,
  });

  final bool ok;
  final String? error;
  final String? inviteId;
  final SetuStaffRole? role;
  final String? institutionId;
  final String? institutionPublicCode;
  final String? institutionName;
  final String? scopeLabel;
  final DateTime? expiresAt;
  final int? remainingAttempts;
  final DateTime? lockedUntil;

  factory StaffActivationPreview.fromJson(Map<String, Object?> json) {
    final String? roleStr = _readNullableString(json, 'role');
    return StaffActivationPreview(
      ok: _readBool(json, 'ok'),
      error: _readNullableString(json, 'error'),
      inviteId: _readNullableString(json, 'invite_id'),
      role: roleStr == null ? null : SetuStaffRole.fromWire(roleStr),
      institutionId: _readNullableString(json, 'institution_id'),
      institutionPublicCode: _readNullableString(
        json,
        'institution_public_code',
      ),
      institutionName: _readNullableString(json, 'institution_name'),
      scopeLabel: _readNullableString(json, 'scope_label'),
      expiresAt: _readNullableDateTime(json, 'expires_at'),
      remainingAttempts: _readNullableInt(json, 'remaining_attempts'),
      lockedUntil: _readNullableDateTime(json, 'locked_until'),
    );
  }
}

/// Resultado transaccional de `redeem_staff_activation_code`.
class StaffActivationRedemption {
  const StaffActivationRedemption({
    required this.ok,
    this.error,
    this.membershipId,
    this.role,
    this.institutionId,
    this.scopeLabel,
    this.remainingAttempts,
    this.lockedUntil,
  });

  final bool ok;
  final String? error;
  final String? membershipId;
  final SetuStaffRole? role;
  final String? institutionId;
  final String? scopeLabel;
  final int? remainingAttempts;
  final DateTime? lockedUntil;

  factory StaffActivationRedemption.fromJson(Map<String, Object?> json) {
    final String? roleStr = _readNullableString(json, 'role');
    return StaffActivationRedemption(
      ok: _readBool(json, 'ok'),
      error: _readNullableString(json, 'error'),
      membershipId: _readNullableString(json, 'membership_id'),
      role: roleStr == null ? null : SetuStaffRole.fromWire(roleStr),
      institutionId: _readNullableString(json, 'institution_id'),
      scopeLabel: _readNullableString(json, 'scope_label'),
      remainingAttempts: _readNullableInt(json, 'remaining_attempts'),
      lockedUntil: _readNullableDateTime(json, 'locked_until'),
    );
  }
}

/// Membresía activa autorizada por el servidor (`get_my_staff_memberships`).
class StaffMembershipScope {
  const StaffMembershipScope({
    required this.membershipId,
    required this.role,
    required this.scopeLabel,
    this.institutionId,
    this.institutionPublicCode,
    this.institutionName,
  });

  final String membershipId;
  final SetuStaffRole role;
  final String? institutionId;
  final String? institutionPublicCode;
  final String? institutionName;
  final String scopeLabel;

  factory StaffMembershipScope.fromJson(Map<String, Object?> json) {
    return StaffMembershipScope(
      membershipId: _readString(json, 'membership_id'),
      role: SetuStaffRole.fromWire(_readString(json, 'role')),
      institutionId: _readNullableString(json, 'institution_id'),
      institutionPublicCode: _readNullableString(
        json,
        'institution_public_code',
      ),
      institutionName: _readNullableString(json, 'institution_name'),
      scopeLabel: _readString(json, 'scope_label'),
    );
  }
}

/// Psicólogo o integrante habilitado de Mesa de Escucha para asignación por MINED.
class AssignableCounselor {
  const AssignableCounselor({
    required this.userId,
    required this.email,
    this.institutionId,
  });

  final String userId;
  final String email;
  final String? institutionId;

  factory AssignableCounselor.fromJson(Map<String, Object?> json) {
    return AssignableCounselor(
      userId: _readString(json, 'user_id'),
      email: _readString(json, 'email'),
      institutionId: _readNullableString(json, 'institution_id'),
    );
  }
}

/// Vista operativa de un caso en bandejas de MINED, Mesa de Escucha o Dirección.
class StaffCaseSummary {
  const StaffCaseSummary({
    required this.id,
    required this.institutionId,
    required this.referenceCode,
    required this.situationType,
    required this.studentRole,
    required this.origin,
    required this.status,
    required this.involvesStaff,
    required this.chatAvailableNotice,
    required this.urgentReferralTriggered,
    required this.concurrencyVersion,
    required this.declaredAt,
    required this.receivedCentrallyAt,
    this.humanLevel,
    this.assignedCounselorId,
    this.closedAt,
    this.closedReason,
    this.studentPiece,
  });

  final String id;
  final String institutionId;
  final String referenceCode;
  final SetuSituationType situationType;

  /// Nulo en los avisos docentes (`origin = teacher_notice`).
  final SetuStudentCaseRole? studentRole;
  final SetuAlertOrigin origin;
  final SetuCaseStatus status;
  final int? humanLevel;
  final bool involvesStaff;
  final String? assignedCounselorId;
  final bool chatAvailableNotice;
  final bool urgentReferralTriggered;
  final int concurrencyVersion;
  final DateTime declaredAt;
  final DateTime receivedCentrallyAt;
  final DateTime? closedAt;
  final String? closedReason;
  final StudentPieceSnapshot? studentPiece;

  /// Los casos recién asignados llegan «Sin valorar» (`human_level IS NULL`).
  bool get isUnassessed => humanLevel == null;

  /// Permite agrupar «En conversación» cuando el profesional habilitó el chat.
  bool get isInConversation => chatAvailableNotice;

  factory StaffCaseSummary.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? pieceMap = _readNullableMap(json, 'student_piece');
    final String? roleStr = _readNullableString(json, 'student_role');
    return StaffCaseSummary(
      id: _readString(json, 'id'),
      institutionId: _readString(json, 'institution_id'),
      referenceCode: _readString(json, 'reference_code'),
      situationType: SetuSituationType.fromWire(
        _readString(json, 'situation_type'),
      ),
      studentRole: roleStr == null
          ? null
          : SetuStudentCaseRole.fromWire(roleStr),
      origin: SetuAlertOrigin.fromWire(_readString(json, 'origin')),
      status: SetuCaseStatus.fromWire(_readString(json, 'status')),
      humanLevel: _readNullableInt(json, 'human_level'),
      involvesStaff: _readBool(json, 'involves_staff'),
      assignedCounselorId: _readNullableString(json, 'assigned_counselor_id'),
      chatAvailableNotice: _readBool(json, 'chat_available_notice'),
      urgentReferralTriggered: _readBool(json, 'urgent_referral_triggered'),
      concurrencyVersion: _readInt(json, 'concurrency_version', fallback: 1),
      declaredAt: _readDateTime(json, 'declared_at'),
      receivedCentrallyAt: _readDateTime(json, 'received_centrally_at'),
      closedAt: _readNullableDateTime(json, 'closed_at'),
      closedReason: _readNullableString(json, 'closed_reason'),
      studentPiece: pieceMap == null
          ? null
          : StudentPieceSnapshot.fromJson(pieceMap),
    );
  }
}

/// Relato opcional D3 (visible por RLS únicamente para la Mesa asignada).
class CaseNarrativeView {
  const CaseNarrativeView({
    required this.caseId,
    required this.narrativeText,
    required this.locationText,
    required this.approxDateText,
    required this.createdAt,
  });

  final String caseId;
  final String narrativeText;
  final String locationText;
  final String approxDateText;
  final DateTime createdAt;

  factory CaseNarrativeView.fromJson(Map<String, Object?> json) {
    return CaseNarrativeView(
      caseId: _readString(json, 'case_id'),
      narrativeText: _readString(json, 'narrative_text'),
      locationText: _readString(json, 'location_text'),
      approxDateText: _readString(json, 'approx_date_text'),
      createdAt: _readDateTime(json, 'created_at'),
    );
  }
}

/// Nota clínica interna D3 (aislada de mensajes, MINED, Dirección y estudiante).
class CaseInternalNoteView {
  const CaseInternalNoteView({
    required this.id,
    required this.caseId,
    required this.noteBody,
    required this.createdAt,
    this.authorUserId,
    this.clientOperationId,
  });

  final String id;
  final String caseId;
  final String? authorUserId;
  final String noteBody;
  final String? clientOperationId;
  final DateTime createdAt;

  factory CaseInternalNoteView.fromJson(Map<String, Object?> json) {
    return CaseInternalNoteView(
      id: _readString(json, 'id'),
      caseId: _readString(json, 'case_id'),
      authorUserId: _readNullableString(json, 'author_user_id'),
      noteBody: _readString(json, 'note_body'),
      clientOperationId: _readNullableString(json, 'client_operation_id'),
      createdAt: _readDateTime(json, 'created_at'),
    );
  }
}

/// Ficha mínima D4 sin relato ni notas internas, para Dirección y MINED.
class CaseActionSheetView {
  const CaseActionSheetView({
    required this.id,
    required this.caseId,
    required this.institutionId,
    required this.version,
    required this.issuedBy,
    required this.humanLevel,
    required this.summaryType,
    required this.summaryRole,
    required this.omitSchoolDueToConflict,
    required this.guidanceNotes,
    required this.issuedAt,
  });

  final String id;
  final String caseId;
  final String institutionId;
  final int version;
  final String issuedBy;
  final int humanLevel;
  final SetuSituationType summaryType;

  /// Nulo cuando la ficha nace de un aviso docente (`summary_role` nulo).
  final SetuStudentCaseRole? summaryRole;
  final bool omitSchoolDueToConflict;
  final String guidanceNotes;
  final DateTime issuedAt;

  factory CaseActionSheetView.fromJson(Map<String, Object?> json) {
    final String? roleStr = _readNullableString(json, 'summary_role');
    return CaseActionSheetView(
      id: _readString(json, 'id'),
      caseId: _readString(json, 'case_id'),
      institutionId: _readString(json, 'institution_id'),
      version: _readInt(json, 'version', fallback: 1),
      issuedBy: _readString(json, 'issued_by'),
      humanLevel: _readInt(json, 'human_level', fallback: 2),
      summaryType: SetuSituationType.fromWire(_readString(json, 'summary_type')),
      summaryRole: roleStr == null
          ? null
          : SetuStudentCaseRole.fromWire(roleStr),
      omitSchoolDueToConflict: _readBool(json, 'omit_school_due_to_conflict'),
      guidanceNotes: _readString(json, 'guidance_notes'),
      issuedAt: _readDateTime(json, 'issued_at'),
    );
  }
}

/// Registro de actuación institucional D4 ejecutado por Dirección.
class SchoolActionRecordView {
  const SchoolActionRecordView({
    required this.id,
    required this.caseId,
    required this.institutionId,
    required this.step,
    required this.isGroupAction,
    required this.actionNotes,
    required this.proposesClosure,
    required this.recordedBy,
    required this.clientOperationId,
    required this.createdAt,
    this.actionSheetId,
  });

  final String id;
  final String caseId;
  final String institutionId;
  final String? actionSheetId;
  final SetuSchoolActionStep step;
  final bool isGroupAction;
  final String actionNotes;
  final bool proposesClosure;
  final String recordedBy;
  final String clientOperationId;
  final DateTime createdAt;

  factory SchoolActionRecordView.fromJson(Map<String, Object?> json) {
    return SchoolActionRecordView(
      id: _readString(json, 'id'),
      caseId: _readString(json, 'case_id'),
      institutionId: _readString(json, 'institution_id'),
      actionSheetId: _readNullableString(json, 'action_sheet_id'),
      step: SetuSchoolActionStep.fromWire(_readString(json, 'step')),
      isGroupAction: _readBool(json, 'is_group_action'),
      actionNotes: _readString(json, 'action_notes'),
      proposesClosure: _readBool(json, 'proposes_closure'),
      recordedBy: _readString(json, 'recorded_by'),
      clientOperationId: _readString(json, 'client_operation_id'),
      createdAt: _readDateTime(json, 'created_at'),
    );
  }
}

/// Recurso del espacio Información D8 (ADR 0009), desacoplado de casos.
class EditorialResourceRecord {
  const EditorialResourceRecord({
    required this.id,
    required this.version,
    required this.topic,
    required this.format,
    required this.title,
    required this.summary,
    required this.bodyParagraphs,
    required this.schoolStage,
    required this.durationLabel,
    required this.sourceName,
    required this.reviewerName,
    required this.verifiedAt,
    required this.rightsNotice,
    required this.offlinePackable,
    this.accessibleAlternative,
  });

  final String id;
  final int version;
  final String topic;
  final SetuEditorialFormat format;
  final String title;
  final String summary;
  final List<String> bodyParagraphs;
  final String schoolStage;
  final String durationLabel;
  final String sourceName;
  final String reviewerName;
  final DateTime verifiedAt;
  final String rightsNotice;
  final String? accessibleAlternative;
  final bool offlinePackable;

  factory EditorialResourceRecord.fromJson(Map<String, Object?> json) {
    final List<Object?> rawParagraphs = _readList(json, 'body_paragraphs');
    final List<String> paragraphs = <String>[
      for (final Object? entry in rawParagraphs)
        if (entry != null) entry.toString(),
    ];
    return EditorialResourceRecord(
      id: _readString(json, 'id'),
      version: _readInt(json, 'version', fallback: 1),
      topic: _readString(json, 'topic'),
      format: SetuEditorialFormat.fromWire(_readString(json, 'format')),
      title: _readString(json, 'title'),
      summary: _readString(json, 'summary'),
      bodyParagraphs: List<String>.unmodifiable(paragraphs),
      schoolStage: _readString(json, 'school_stage'),
      durationLabel: _readString(json, 'duration_label'),
      sourceName: _readString(json, 'source_name'),
      reviewerName: _readString(json, 'reviewer_name'),
      verifiedAt: _readDateTime(json, 'verified_at'),
      rightsNotice: _readString(json, 'rights_notice'),
      accessibleAlternative: _readNullableString(
        json,
        'accessible_alternative',
      ),
      offlinePackable: _readBool(json, 'offline_packable', fallback: true),
    );
  }
}

/// Recurso de ayuda D8 con trazabilidad editorial obligatoria.
class HelpResourceRecord {
  const HelpResourceRecord({
    required this.id,
    required this.name,
    required this.phoneOrChannel,
    required this.territory,
    required this.hoursLabel,
    required this.sourceName,
    required this.editorialResponsible,
    required this.verifiedAt,
    required this.isVerifiedForPilot,
    required this.displayOrder,
  });

  final String id;
  final String name;
  final String phoneOrChannel;
  final String territory;
  final String hoursLabel;
  final String sourceName;
  final String editorialResponsible;
  final DateTime verifiedAt;
  final bool isVerifiedForPilot;
  final int displayOrder;

  factory HelpResourceRecord.fromJson(Map<String, Object?> json) {
    return HelpResourceRecord(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      phoneOrChannel: _readString(json, 'phone_or_channel'),
      territory: _readString(json, 'territory'),
      hoursLabel: _readString(json, 'hours_label'),
      sourceName: _readString(json, 'source_name'),
      editorialResponsible: _readString(json, 'editorial_responsible'),
      verifiedAt: _readDateTime(json, 'verified_at'),
      isVerifiedForPilot: _readBool(json, 'is_verified_for_pilot'),
      displayOrder: _readInt(json, 'display_order', fallback: 100),
    );
  }
}

/// Aviso en vivo dentro de la app cuando un caso se asigna al profesional.
class SetuAssignmentNotice {
  const SetuAssignmentNotice({
    required this.caseId,
    required this.referenceCode,
    required this.institutionId,
    required this.assignedCounselorId,
    this.headline = defaultHeadline,
  });

  static const String defaultHeadline = 'Tenés una alerta asignada';

  final String caseId;
  final String referenceCode;
  final String institutionId;
  final String assignedCounselorId;
  final String headline;

  factory SetuAssignmentNotice.fromCaseRow(Map<String, Object?> row) {
    return SetuAssignmentNotice(
      caseId: _readString(row, 'id'),
      referenceCode: _readString(row, 'reference_code'),
      institutionId: _readString(row, 'institution_id'),
      assignedCounselorId: _readString(row, 'assigned_counselor_id'),
    );
  }
}

Map<String, Object?> _castMap(Map<dynamic, dynamic> raw) {
  final Map<String, Object?> result = <String, Object?>{};
  raw.forEach((Object? key, Object? value) {
    if (key != null) {
      result[key.toString()] = value;
    }
  });
  return result;
}

String _readString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String) return value;
  if (value == null) {
    throw FormatException('Falta campo requerido "$key" en respuesta.');
  }
  return value.toString();
}

String? _readNullableString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool _readBool(
  Map<String, Object?> json,
  String key, {
  bool fallback = false,
}) {
  final Object? value = json[key];
  if (value is bool) return value;
  return fallback;
}

int _readInt(Map<String, Object?> json, String key, {required int fallback}) {
  final Object? value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _readNullableInt(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _readNullableDouble(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime _readDateTime(Map<String, Object?> json, String key) {
  final String raw = _readString(json, key);
  return DateTime.parse(raw).toUtc();
}

DateTime? _readNullableDateTime(Map<String, Object?> json, String key) {
  final String? raw = _readNullableString(json, key);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

Map<String, Object?>? _readNullableMap(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is Map<String, Object?>) return value;
  if (value is Map<dynamic, dynamic>) return _castMap(value);
  return null;
}

List<Object?> _readList(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is List<Object?>) return value;
  return const <Object?>[];
}
