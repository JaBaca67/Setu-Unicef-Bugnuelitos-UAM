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

/// Nivel de despacho automático hacia psicólogos de Mesa de Escucha.
enum CaseDispatchTier {
  schoolPlant('school_plant', 'Equipo de planta del colegio'),
  externalPool('external_pool', 'Red externa disponible');

  const CaseDispatchTier(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static CaseDispatchTier fromWire(String value) {
    for (final CaseDispatchTier item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Nivel de despacho no reconocido: $value');
  }
}

/// Estado de atención de una alerta despachada a un psicólogo.
enum CaseDispatchStatus {
  pending('pending', 'Pendiente'),
  claimed('claimed', 'Atendida'),
  takenByOther('taken_by_other', 'Tomada por otro'),
  declined('declined', 'Declinada'),
  withdrawnCoverage('withdrawn_coverage', 'Cobertura pausada');

  const CaseDispatchStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static CaseDispatchStatus fromWire(String value) {
    for (final CaseDispatchStatus item in values) {
      if (item.wireValue == value) return item;
    }
    throw FormatException('Estado de despacho no reconocido: $value');
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
      shape:
          _readNullableString(json, 'shape') ??
          _readNullableString(json, 'variant'),
      color:
          _readNullableString(json, 'color') ??
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
    this.installationVerifierHash,
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

  /// SHA-256 del secreto de instalación. El servidor lo usa solo para el cupo
  /// de alertas activas por instalación; el secreto nunca sale del teléfono.
  final String? installationVerifierHash;
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
    final Map<String, Object?>? pieceMap = _readNullableMap(
      json,
      'student_piece',
    );
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
    this.caseClosed = false,
    this.conversationEnded = false,
    this.referenceCode,
    this.studentPiece,
  });

  final String caseId;
  final bool chatAvailableNotice;
  final bool caseClosed;

  /// Verdadero cuando la Mesa finalizó la conversación (o el caso cerró).
  final bool conversationEnded;
  final String? referenceCode;
  final StudentPieceSnapshot? studentPiece;
  final List<CaseChatMessageView> messages;

  factory StudentChatSessionView.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? pieceMap = _readNullableMap(
      json,
      'student_piece',
    );
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
      caseClosed: _readBool(json, 'case_closed'),
      conversationEnded:
          _readBool(json, 'conversation_ended') ||
          _readBool(json, 'case_closed'),
      referenceCode: _readNullableString(json, 'reference_code'),
      studentPiece: pieceMap == null
          ? null
          : StudentPieceSnapshot.fromJson(pieceMap),
      messages: List<CaseChatMessageView>.unmodifiable(parsedMessages),
    );
  }
}

/// Resultado de `preview_staff_activation_code` luego de confirmar el correo.
class StaffActivationPreview {
  const StaffActivationPreview({
    required this.ok,
    this.error,
    this.inviteId,
    this.role,
    this.staffTier,
    this.supervisorUserId,
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
  final String? staffTier;
  final String? supervisorUserId;
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
      staffTier: _readNullableString(json, 'staff_tier'),
      supervisorUserId: _readNullableString(json, 'supervisor_user_id'),
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

/// Resultado transaccional de `redeem_staff_activation_code_with_profile`.
class StaffActivationRedemption {
  const StaffActivationRedemption({
    required this.ok,
    this.error,
    this.membershipId,
    this.role,
    this.staffTier,
    this.supervisorUserId,
    this.institutionId,
    this.scopeLabel,
    this.firstName,
    this.lastName,
    this.remainingAttempts,
    this.lockedUntil,
  });

  final bool ok;
  final String? error;
  final String? membershipId;
  final SetuStaffRole? role;
  final String? staffTier;
  final String? supervisorUserId;
  final String? institutionId;
  final String? scopeLabel;
  final String? firstName;
  final String? lastName;
  final int? remainingAttempts;
  final DateTime? lockedUntil;

  factory StaffActivationRedemption.fromJson(Map<String, Object?> json) {
    final String? roleStr = _readNullableString(json, 'role');
    return StaffActivationRedemption(
      ok: _readBool(json, 'ok'),
      error: _readNullableString(json, 'error'),
      membershipId: _readNullableString(json, 'membership_id'),
      role: roleStr == null ? null : SetuStaffRole.fromWire(roleStr),
      staffTier: _readNullableString(json, 'staff_tier'),
      supervisorUserId: _readNullableString(json, 'supervisor_user_id'),
      institutionId: _readNullableString(json, 'institution_id'),
      scopeLabel: _readNullableString(json, 'scope_label'),
      firstName: _readNullableString(json, 'first_name'),
      lastName: _readNullableString(json, 'last_name'),
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
    this.staffTier,
    this.institutionId,
    this.institutionPublicCode,
    this.institutionName,
  });

  final String membershipId;
  final SetuStaffRole role;
  final String? staffTier;
  final String? institutionId;
  final String? institutionPublicCode;
  final String? institutionName;
  final String scopeLabel;

  factory StaffMembershipScope.fromJson(Map<String, Object?> json) {
    return StaffMembershipScope(
      membershipId: _readString(json, 'membership_id'),
      role: SetuStaffRole.fromWire(_readString(json, 'role')),
      staffTier: _readNullableString(json, 'staff_tier'),
      institutionId: _readNullableString(json, 'institution_id'),
      institutionPublicCode: _readNullableString(
        json,
        'institution_public_code',
      ),
      institutionName: _readNullableString(json, 'institution_name'),
      scopeLabel: _readString(json, 'scope_label'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'membership_id': membershipId,
    'role': role.wireValue,
    if (staffTier != null) 'staff_tier': staffTier,
    'institution_id': institutionId,
    'institution_public_code': institutionPublicCode,
    'institution_name': institutionName,
    'scope_label': scopeLabel,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMembershipScope &&
          other.membershipId == membershipId &&
          other.role == role &&
          other.staffTier == staffTier &&
          other.institutionId == institutionId &&
          other.institutionPublicCode == institutionPublicCode &&
          other.institutionName == institutionName &&
          other.scopeLabel == scopeLabel;

  @override
  int get hashCode => Object.hash(
    membershipId,
    role,
    staffTier,
    institutionId,
    institutionPublicCode,
    institutionName,
    scopeLabel,
  );
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
    this.conversationEndedAt,
    this.studentPiece,
    this.clientOperationId,
  });

  final String id;
  final String? clientOperationId;
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

  /// Momento en que la Mesa finalizó la conversación. No cierra el expediente.
  final DateTime? conversationEndedAt;
  final StudentPieceSnapshot? studentPiece;

  /// Conversación finalizada o caso cerrado: el chat queda solo de consulta.
  bool get isConversationEnded =>
      conversationEndedAt != null || status == SetuCaseStatus.closed;

  /// Los casos recién asignados llegan «Sin valorar» (`human_level IS NULL`).
  bool get isUnassessed => humanLevel == null;

  /// Permite agrupar «En conversación» cuando el profesional habilitó el chat.
  bool get isInConversation => chatAvailableNotice;

  factory StaffCaseSummary.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? pieceMap = _readNullableMap(
      json,
      'student_piece',
    );
    final String? roleStr = _readNullableString(json, 'student_role');
    return StaffCaseSummary(
      id: _readString(json, 'id'),
      clientOperationId: _readNullableString(json, 'client_operation_id'),
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
      conversationEndedAt: _readNullableDateTime(json, 'conversation_ended_at'),
      studentPiece: pieceMap == null
          ? null
          : StudentPieceSnapshot.fromJson(pieceMap),
    );
  }
}

/// Borrador de la «Nota para la ficha», reservado a la persona asignada.
class CaseSheetDraftView {
  const CaseSheetDraftView({
    required this.caseId,
    required this.guidanceDraft,
    this.updatedAt,
  });

  final String caseId;
  final String guidanceDraft;
  final DateTime? updatedAt;

  factory CaseSheetDraftView.fromJson(Map<String, Object?> json) {
    return CaseSheetDraftView(
      caseId: _readString(json, 'case_id'),
      guidanceDraft: _readNullableString(json, 'guidance_draft') ?? '',
      updatedAt: _readNullableDateTime(json, 'updated_at'),
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
      summaryType: SetuSituationType.fromWire(
        _readString(json, 'summary_type'),
      ),
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

/// Resultado de intentar tomar un caso disponible en Mesa de Escucha.
class CaseClaimResult {
  const CaseClaimResult({
    required this.ok,
    required this.claimed,
    required this.alreadyAssignedToYou,
    required this.caseId,
    required this.assignedCounselorId,
    this.error,
    this.status,
    this.humanLevel,
    this.concurrencyVersion,
  });

  final bool ok;
  final bool claimed;
  final bool alreadyAssignedToYou;
  final String? error;
  final String caseId;
  final String assignedCounselorId;
  final SetuCaseStatus? status;
  final int? humanLevel;
  final int? concurrencyVersion;

  bool get isAlreadyTaken => !claimed && error == 'case_already_taken';

  factory CaseClaimResult.fromJson(Map<String, Object?> json) {
    final String? rawStatus = _readNullableString(json, 'status');
    return CaseClaimResult(
      ok: _readBool(json, 'ok'),
      claimed: _readBool(json, 'claimed'),
      alreadyAssignedToYou: _readBool(json, 'already_assigned_to_you'),
      error: _readNullableString(json, 'error'),
      caseId: _readString(json, 'case_id'),
      assignedCounselorId: _readString(json, 'assigned_counselor_id'),
      status: rawStatus == null || rawStatus.isEmpty
          ? null
          : SetuCaseStatus.fromWire(rawStatus),
      humanLevel: _readNullableInt(json, 'human_level'),
      concurrencyVersion: _readNullableInt(json, 'concurrency_version'),
    );
  }
}

/// Resultado de declinar una alerta despachada y posible derivación al pool externo.
class CaseDeclineResult {
  const CaseDeclineResult({
    required this.ok,
    required this.caseId,
    required this.dispatchStatus,
    this.fallbackTier,
    this.fallbackDispatchedCount,
  });

  final bool ok;
  final String caseId;
  final CaseDispatchStatus dispatchStatus;
  final CaseDispatchTier? fallbackTier;
  final int? fallbackDispatchedCount;

  factory CaseDeclineResult.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? fallback = _readNullableMap(json, 'fallback');
    final String? rawFallbackTier = fallback == null
        ? null
        : _readNullableString(fallback, 'dispatch_tier');
    return CaseDeclineResult(
      ok: _readBool(json, 'ok'),
      caseId: _readString(json, 'case_id'),
      dispatchStatus: CaseDispatchStatus.fromWire(
        _readString(json, 'dispatch_status'),
      ),
      fallbackTier: rawFallbackTier == null || rawFallbackTier.isEmpty
          ? null
          : CaseDispatchTier.fromWire(rawFallbackTier),
      fallbackDispatchedCount: fallback == null
          ? null
          : _readNullableInt(fallback, 'dispatched_count'),
    );
  }
}

/// Registro del historial de despacho multi-psicólogo o evento en vivo en `case_counselor_dispatches`.
class CaseDispatchRecord {
  const CaseDispatchRecord({
    required this.id,
    required this.caseId,
    required this.institutionId,
    required this.counselorUserId,
    required this.dispatchTier,
    required this.dispatchStatus,
    required this.notifiedAt,
    this.referenceCode,
    this.institutionName,
    this.situationType,
    this.caseStatus,
    this.assignedCounselorId,
    this.counselorEmail,
    this.respondedAt,
    this.declineReason,
  });

  final String id;
  final String caseId;
  final String institutionId;
  final String counselorUserId;
  final CaseDispatchTier dispatchTier;
  final CaseDispatchStatus dispatchStatus;
  final DateTime notifiedAt;
  final String? referenceCode;
  final String? institutionName;
  final SetuSituationType? situationType;
  final SetuCaseStatus? caseStatus;
  final String? assignedCounselorId;
  final String? counselorEmail;
  final DateTime? respondedAt;
  final String? declineReason;

  factory CaseDispatchRecord.fromJson(Map<String, Object?> json) {
    final String? rawSituation = _readNullableString(json, 'situation_type');
    final String? rawCaseStatus = _readNullableString(json, 'case_status');
    return CaseDispatchRecord(
      id: _readString(json, 'id'),
      caseId: _readString(json, 'case_id'),
      institutionId: _readString(json, 'institution_id'),
      counselorUserId: _readString(json, 'counselor_user_id'),
      dispatchTier: CaseDispatchTier.fromWire(
        _readString(json, 'dispatch_tier'),
      ),
      dispatchStatus: CaseDispatchStatus.fromWire(
        _readString(json, 'dispatch_status'),
      ),
      notifiedAt: _readDateTime(json, 'notified_at'),
      referenceCode: _readNullableString(json, 'reference_code'),
      institutionName: _readNullableString(json, 'institution_name'),
      situationType: rawSituation == null || rawSituation.isEmpty
          ? null
          : SetuSituationType.fromWire(rawSituation),
      caseStatus: rawCaseStatus == null || rawCaseStatus.isEmpty
          ? null
          : SetuCaseStatus.fromWire(rawCaseStatus),
      assignedCounselorId: _readNullableString(json, 'assigned_counselor_id'),
      counselorEmail: _readNullableString(json, 'counselor_email'),
      respondedAt: _readNullableDateTime(json, 'responded_at'),
      declineReason: _readNullableString(json, 'decline_reason'),
    );
  }
}

/// Tipo o equipo del personal autorizado (`staff_tier`).
enum StaffTierKind {
  schoolPlant('school_plant', 'Planta del colegio'),
  externalNetwork('external_network', 'Red externa'),
  practicante5to('practicante_5to', 'Practicante 5.º año'),
  minedCentral('mined_central', 'MINED central'),
  schoolDirector('school_director', 'Dirección del centro');

  const StaffTierKind(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static StaffTierKind? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final StaffTierKind item in values) {
      if (item.wireValue == value) return item;
    }
    return null;
  }
}

/// Estado de la solicitud/emisión de invitación de personal.
enum StaffInviteRequestStatus {
  pendingApproval('pending_approval', 'Solicitud pendiente'),
  approved('approved', 'Aprobada'),
  rejected('rejected', 'Rechazada');

  const StaffInviteRequestStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static StaffInviteRequestStatus fromWire(String value) {
    for (final StaffInviteRequestStatus item in values) {
      if (item.wireValue == value) return item;
    }
    return StaffInviteRequestStatus.approved;
  }
}

/// Estado de cobertura de Red externa en un centro educativo.
enum ExternalCoverageMode {
  disabled('disabled', 'Apoyo externo desactivado'),
  enabled('enabled', 'Apoyo externo habilitado'),
  temporaryUntil('temporary_until', 'Apoyo temporal');

  const ExternalCoverageMode(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static ExternalCoverageMode fromWire(String value) {
    for (final ExternalCoverageMode item in values) {
      if (item.wireValue == value) return item;
    }
    return ExternalCoverageMode.disabled;
  }
}

/// Disponibilidad actual de una alerta declinada para recuperación en bandeja.
enum DeclinedDispatchAvailability {
  available('available', 'Disponible'),
  alreadyInCare('already_in_care', 'Ya está en atención'),
  coverageInactive('coverage_inactive', 'Cobertura externa inactiva'),
  closed('closed', 'Cerrado');

  const DeclinedDispatchAvailability(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static DeclinedDispatchAvailability fromWire(String value) {
    for (final DeclinedDispatchAvailability item in values) {
      if (item.wireValue == value) return item;
    }
    return DeclinedDispatchAvailability.available;
  }
}

/// Colegio visible en el perfil de personal (asignado o disponible en el catálogo).
class StaffSchoolScopeItem {
  const StaffSchoolScopeItem({
    required this.institutionId,
    required this.publicCode,
    required this.name,
    required this.coverageActiveNow,
    required this.externalSupportMode,
    this.externalSupportUntil,
  });

  final String institutionId;
  final String publicCode;
  final String name;
  final bool coverageActiveNow;
  final ExternalCoverageMode externalSupportMode;
  final DateTime? externalSupportUntil;

  factory StaffSchoolScopeItem.fromJson(Map<String, Object?> json) {
    return StaffSchoolScopeItem(
      institutionId: _readString(json, 'institution_id'),
      publicCode: _readNullableString(json, 'public_code') ?? '',
      name: _readString(json, 'name'),
      coverageActiveNow: _readBool(json, 'coverage_active_now'),
      externalSupportMode: ExternalCoverageMode.fromWire(
        _readNullableString(json, 'external_support_mode') ?? 'disabled',
      ),
      externalSupportUntil: _readNullableDateTime(
        json,
        'external_support_until',
      ),
    );
  }
}

/// Perfil completo de la cuenta de personal autorizado (`get_my_staff_profile`).
class StaffProfileView {
  const StaffProfileView({
    required this.userId,
    required this.email,
    required this.emailConfirmed,
    required this.isAvailable,
    required this.notifyNewAlerts,
    required this.notifyNewMessages,
    required this.memberships,
    required this.assignedSchools,
    required this.availableSchools,
    this.firstName,
    this.lastName,
    this.staffTier,
    this.supervisorUserId,
    this.supervisorName,
  });

  final String userId;
  final String email;
  final bool emailConfirmed;
  final String? firstName;
  final String? lastName;
  final String? staffTier;
  final String? supervisorUserId;
  final String? supervisorName;
  final bool isAvailable;
  final bool notifyNewAlerts;
  final bool notifyNewMessages;
  final List<StaffMembershipScope> memberships;
  final List<StaffSchoolScopeItem> assignedSchools;
  final List<StaffSchoolScopeItem> availableSchools;

  String get fullName {
    final String joined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (joined.isNotEmpty) return joined;
    return email;
  }

  String get initials {
    final List<String> parts = fullName
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return 'ST';
  }

  String get staffTierLabel =>
      StaffTierKind.fromWire(staffTier)?.label ?? 'Personal autorizado';

  factory StaffProfileView.fromJson(Map<String, Object?> json) {
    return StaffProfileView(
      userId: _readString(json, 'user_id'),
      email: _readNullableString(json, 'email') ?? '',
      emailConfirmed: _readBool(json, 'email_confirmed'),
      firstName: _readNullableString(json, 'first_name'),
      lastName: _readNullableString(json, 'last_name'),
      staffTier: _readNullableString(json, 'staff_tier'),
      supervisorUserId: _readNullableString(json, 'supervisor_user_id'),
      supervisorName: _readNullableString(json, 'supervisor_name'),
      isAvailable: _readBool(json, 'is_available', fallback: true),
      notifyNewAlerts: _readBool(json, 'notify_new_alerts', fallback: true),
      notifyNewMessages: _readBool(json, 'notify_new_messages', fallback: true),
      memberships:
          List<StaffMembershipScope>.unmodifiable(<StaffMembershipScope>[
            for (final Object? entry in _readList(json, 'memberships'))
              if (entry is Map<dynamic, dynamic>)
                StaffMembershipScope.fromJson(_castMap(entry)),
          ]),
      assignedSchools:
          List<StaffSchoolScopeItem>.unmodifiable(<StaffSchoolScopeItem>[
            for (final Object? entry in _readList(json, 'assigned_schools'))
              if (entry is Map<dynamic, dynamic>)
                StaffSchoolScopeItem.fromJson(_castMap(entry)),
          ]),
      availableSchools:
          List<StaffSchoolScopeItem>.unmodifiable(<StaffSchoolScopeItem>[
            for (final Object? entry in _readList(json, 'available_schools'))
              if (entry is Map<dynamic, dynamic>)
                StaffSchoolScopeItem.fromJson(_castMap(entry)),
          ]),
    );
  }
}

/// Evento de auditoría de una invitación de personal (sin exponer el código).
class StaffInviteEventView {
  const StaffInviteEventView({
    required this.id,
    required this.eventType,
    required this.createdAt,
    this.actorUserId,
    this.details,
  });

  final String id;
  final String eventType;
  final String? actorUserId;
  final String? details;
  final DateTime createdAt;

  String get eventLabel => switch (eventType) {
    'requested' => 'Solicitud registrada',
    'issued' => 'Invitación emitida',
    'revoked' => 'Invitación revocada',
    'replaced' => 'Invitación repuesta',
    'redeemed' => 'Código canjeado',
    'replacement_requested' => 'Reposición solicitada',
    _ => eventType,
  };

  factory StaffInviteEventView.fromJson(Map<String, Object?> json) {
    return StaffInviteEventView(
      id: _readString(json, 'id'),
      eventType: _readString(json, 'event_type'),
      actorUserId: _readNullableString(json, 'actor_user_id'),
      details: _readNullableString(json, 'details'),
      createdAt: _readDateTime(json, 'created_at'),
    );
  }
}

/// Registro visible de solicitud o invitación emitida (`list_staff_activation_invites`).
class StaffActivationInviteView {
  const StaffActivationInviteView({
    required this.inviteId,
    required this.institutionalEmail,
    required this.role,
    required this.staffTier,
    required this.scopeLabel,
    required this.requestStatus,
    required this.createdAt,
    required this.events,
    this.fullName,
    this.institutionId,
    this.institutionName,
    this.requesterProgramLabel,
    this.supervisorUserId,
    this.supervisorName,
    this.requestedBy,
    this.approvedBy,
    this.approvedAt,
    this.expiresAt,
    this.revokedAt,
    this.revokedBy,
    this.revokedReason,
    this.redeemedAt,
    this.replacedByInviteId,
  });

  final String inviteId;
  final String institutionalEmail;
  final String? fullName;
  final SetuStaffRole role;
  final String staffTier;
  final String? institutionId;
  final String? institutionName;
  final String scopeLabel;
  final StaffInviteRequestStatus requestStatus;
  final String? requesterProgramLabel;
  final String? supervisorUserId;
  final String? supervisorName;
  final String? requestedBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? revokedBy;
  final String? revokedReason;
  final DateTime? redeemedAt;
  final String? replacedByInviteId;
  final DateTime createdAt;
  final List<StaffInviteEventView> events;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc());

  bool get isActiveForRedemption =>
      requestStatus == StaffInviteRequestStatus.approved &&
      redeemedAt == null &&
      revokedAt == null &&
      !isExpired;

  String get displayStatus {
    if (redeemedAt != null) return 'Canjeada';
    if (replacedByInviteId != null) return 'Reemplazada';
    if (revokedAt != null) return 'Revocada';
    if (requestStatus == StaffInviteRequestStatus.pendingApproval) {
      return 'Por aprobar';
    }
    if (requestStatus == StaffInviteRequestStatus.rejected) {
      return 'Rechazada';
    }
    if (isExpired) return 'Vencida';
    return 'Emitida y vigente';
  }

  factory StaffActivationInviteView.fromJson(Map<String, Object?> json) {
    return StaffActivationInviteView(
      inviteId: _readString(json, 'invite_id'),
      institutionalEmail: _readString(json, 'institutional_email'),
      fullName: _readNullableString(json, 'full_name'),
      role: SetuStaffRole.fromWire(_readString(json, 'role')),
      staffTier: _readNullableString(json, 'staff_tier') ?? 'school_plant',
      institutionId: _readNullableString(json, 'institution_id'),
      institutionName: _readNullableString(json, 'institution_name'),
      scopeLabel: _readNullableString(json, 'scope_label') ?? '',
      requestStatus: StaffInviteRequestStatus.fromWire(
        _readNullableString(json, 'request_status') ?? 'approved',
      ),
      requesterProgramLabel: _readNullableString(
        json,
        'requester_program_label',
      ),
      supervisorUserId: _readNullableString(json, 'supervisor_user_id'),
      supervisorName: _readNullableString(json, 'supervisor_name'),
      requestedBy: _readNullableString(json, 'requested_by'),
      approvedBy: _readNullableString(json, 'approved_by'),
      approvedAt: _readNullableDateTime(json, 'approved_at'),
      expiresAt: _readNullableDateTime(json, 'expires_at'),
      revokedAt: _readNullableDateTime(json, 'revoked_at'),
      revokedBy: _readNullableString(json, 'revoked_by'),
      revokedReason: _readNullableString(json, 'revoked_reason'),
      redeemedAt: _readNullableDateTime(json, 'redeemed_at'),
      replacedByInviteId: _readNullableString(json, 'replaced_by_invite_id'),
      createdAt: _readDateTime(json, 'created_at'),
      events: List<StaffInviteEventView>.unmodifiable(<StaffInviteEventView>[
        for (final Object? entry in _readList(json, 'events'))
          if (entry is Map<dynamic, dynamic>)
            StaffInviteEventView.fromJson(_castMap(entry)),
      ]),
    );
  }
}

/// Respuesta única al emitir o reponer una invitación con su código efímero.
class StaffInviteIssueResult {
  const StaffInviteIssueResult({
    required this.ok,
    required this.inviteId,
    required this.activationCode,
    required this.institutionalEmail,
    required this.role,
    required this.staffTier,
    required this.scopeLabel,
    this.institutionId,
    this.expiresAt,
  });

  final bool ok;
  final String inviteId;
  final String activationCode;
  final String institutionalEmail;
  final SetuStaffRole role;
  final String staffTier;
  final String? institutionId;
  final String scopeLabel;
  final DateTime? expiresAt;

  factory StaffInviteIssueResult.fromJson(Map<String, Object?> json) {
    return StaffInviteIssueResult(
      ok: _readBool(json, 'ok', fallback: true),
      inviteId: _readString(json, 'invite_id'),
      activationCode: _readString(json, 'activation_code'),
      institutionalEmail: _readString(json, 'institutional_email'),
      role: SetuStaffRole.fromWire(_readString(json, 'role')),
      staffTier: _readNullableString(json, 'staff_tier') ?? 'school_plant',
      institutionId: _readNullableString(json, 'institution_id'),
      scopeLabel: _readNullableString(json, 'scope_label') ?? '',
      expiresAt: _readNullableDateTime(json, 'expires_at'),
    );
  }
}

/// Fila de entrada para emisión masiva de invitaciones desde CSV.
class BulkInviteRowDraft {
  const BulkInviteRowDraft({
    required this.institutionalEmail,
    required this.role,
    required this.staffTier,
    this.fullName,
    this.schoolRef,
    this.supervisorEmail,
  });

  final String institutionalEmail;
  final String role;
  final String staffTier;
  final String? fullName;
  final String? schoolRef;
  final String? supervisorEmail;

  Map<String, Object?> toJson() => <String, Object?>{
    'institutional_email': institutionalEmail,
    'role': role,
    'staff_tier': staffTier,
    if (fullName != null && fullName!.trim().isNotEmpty)
      'full_name': fullName!.trim(),
    if (schoolRef != null && schoolRef!.trim().isNotEmpty)
      'school_ref': schoolRef!.trim(),
    if (supervisorEmail != null && supervisorEmail!.trim().isNotEmpty)
      'supervisor_email': supervisorEmail!.trim(),
  };
}

/// Resultado por fila de `issue_staff_invites_bulk`.
class BulkInviteRowResult {
  const BulkInviteRowResult({
    required this.index,
    required this.ok,
    required this.institutionalEmail,
    this.fullName,
    this.inviteId,
    this.activationCode,
    this.scopeLabel,
    this.role,
    this.staffTier,
    this.expiresAt,
    this.error,
  });

  final int index;
  final bool ok;
  final String institutionalEmail;
  final String? fullName;
  final String? inviteId;
  final String? activationCode;
  final String? scopeLabel;
  final SetuStaffRole? role;
  final String? staffTier;
  final DateTime? expiresAt;
  final String? error;

  factory BulkInviteRowResult.fromJson(Map<String, Object?> json) {
    final String? rawRole = _readNullableString(json, 'role');
    return BulkInviteRowResult(
      index: _readInt(json, 'index', fallback: 0),
      ok: _readBool(json, 'ok'),
      institutionalEmail: _readString(json, 'institutional_email'),
      fullName: _readNullableString(json, 'full_name'),
      inviteId: _readNullableString(json, 'invite_id'),
      activationCode: _readNullableString(json, 'activation_code'),
      scopeLabel: _readNullableString(json, 'scope_label'),
      role: rawRole == null || rawRole.isEmpty
          ? null
          : SetuStaffRole.fromWire(rawRole),
      staffTier: _readNullableString(json, 'staff_tier'),
      expiresAt: _readNullableDateTime(json, 'expires_at'),
      error: _readNullableString(json, 'error'),
    );
  }
}

/// Respuesta consolidada de `issue_staff_invites_bulk`.
class BulkInviteResult {
  const BulkInviteResult({
    required this.ok,
    required this.issuedCount,
    required this.errorCount,
    required this.results,
  });

  final bool ok;
  final int issuedCount;
  final int errorCount;
  final List<BulkInviteRowResult> results;

  factory BulkInviteResult.fromJson(Map<String, Object?> json) {
    return BulkInviteResult(
      ok: _readBool(json, 'ok', fallback: true),
      issuedCount: _readInt(json, 'issued_count', fallback: 0),
      errorCount: _readInt(json, 'error_count', fallback: 0),
      results: List<BulkInviteRowResult>.unmodifiable(<BulkInviteRowResult>[
        for (final Object? entry in _readList(json, 'results'))
          if (entry is Map<dynamic, dynamic>)
            BulkInviteRowResult.fromJson(_castMap(entry)),
      ]),
    );
  }
}

/// Destinatario para envío automático de código vía Edge Function `invite-email`.
class InviteEmailRecipient {
  const InviteEmailRecipient({
    required this.institutionalEmail,
    required this.activationCode,
    this.inviteId,
    this.fullName,
    this.roleLabel,
    this.scopeLabel,
    this.expiresAt,
  });

  final String? inviteId;
  final String institutionalEmail;
  final String? fullName;
  final String? roleLabel;
  final String? scopeLabel;
  final String activationCode;
  final DateTime? expiresAt;

  Map<String, Object?> toJson() => <String, Object?>{
    if (inviteId != null) 'invite_id': inviteId,
    'institutional_email': institutionalEmail,
    if (fullName != null && fullName!.trim().isNotEmpty) 'full_name': fullName,
    if (roleLabel != null && roleLabel!.trim().isNotEmpty)
      'role_label': roleLabel,
    if (scopeLabel != null && scopeLabel!.trim().isNotEmpty)
      'scope_label': scopeLabel,
    'activation_code': activationCode,
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
  };
}

/// Respuesta del envío de correos de invitación (`invite-email`).
class InviteEmailDispatchResult {
  const InviteEmailDispatchResult({
    required this.ok,
    required this.configured,
    required this.sentCount,
    required this.failedCount,
    this.reason,
  });

  final bool ok;
  final bool configured;
  final int sentCount;
  final int failedCount;
  final String? reason;

  factory InviteEmailDispatchResult.fromJson(Map<String, Object?> json) {
    return InviteEmailDispatchResult(
      ok: _readBool(json, 'ok'),
      configured: _readBool(json, 'configured'),
      sentCount: _readInt(json, 'sent_count', fallback: 0),
      failedCount: _readInt(json, 'failed_count', fallback: 0),
      reason: _readNullableString(json, 'reason'),
    );
  }
}

/// Elemento de «Declinadas recientes» en Mesa de Escucha.
class DeclinedDispatchRecord {
  const DeclinedDispatchRecord({
    required this.id,
    required this.caseId,
    required this.institutionId,
    required this.counselorUserId,
    required this.dispatchTier,
    required this.dispatchStatus,
    required this.notifiedAt,
    required this.canRecover,
    required this.availabilityState,
    this.referenceCode,
    this.institutionName,
    this.situationType,
    this.caseStatus,
    this.assignedCounselorId,
    this.respondedAt,
    this.declineReason,
    this.declaredAt,
    this.involvesStaff = false,
  });

  final String id;
  final String caseId;
  final String institutionId;
  final String counselorUserId;
  final CaseDispatchTier dispatchTier;
  final CaseDispatchStatus dispatchStatus;
  final DateTime notifiedAt;
  final bool canRecover;
  final DeclinedDispatchAvailability availabilityState;
  final String? referenceCode;
  final String? institutionName;
  final SetuSituationType? situationType;
  final SetuCaseStatus? caseStatus;
  final String? assignedCounselorId;
  final DateTime? respondedAt;
  final String? declineReason;
  final DateTime? declaredAt;
  final bool involvesStaff;

  factory DeclinedDispatchRecord.fromJson(Map<String, Object?> json) {
    final String? rawSituation = _readNullableString(json, 'situation_type');
    final String? rawCaseStatus = _readNullableString(json, 'case_status');
    return DeclinedDispatchRecord(
      id: _readString(json, 'id'),
      caseId: _readString(json, 'case_id'),
      institutionId: _readString(json, 'institution_id'),
      counselorUserId: _readString(json, 'counselor_user_id'),
      dispatchTier: CaseDispatchTier.fromWire(
        _readString(json, 'dispatch_tier'),
      ),
      dispatchStatus: CaseDispatchStatus.fromWire(
        _readString(json, 'dispatch_status'),
      ),
      notifiedAt: _readDateTime(json, 'notified_at'),
      canRecover: _readBool(json, 'can_recover'),
      availabilityState: DeclinedDispatchAvailability.fromWire(
        _readNullableString(json, 'availability_state') ?? 'available',
      ),
      referenceCode: _readNullableString(json, 'reference_code'),
      institutionName: _readNullableString(json, 'institution_name'),
      situationType: rawSituation == null || rawSituation.isEmpty
          ? null
          : SetuSituationType.fromWire(rawSituation),
      caseStatus: rawCaseStatus == null || rawCaseStatus.isEmpty
          ? null
          : SetuCaseStatus.fromWire(rawCaseStatus),
      assignedCounselorId: _readNullableString(json, 'assigned_counselor_id'),
      respondedAt: _readNullableDateTime(json, 'responded_at'),
      declineReason: _readNullableString(json, 'decline_reason'),
      declaredAt: _readNullableDateTime(json, 'declared_at'),
      involvesStaff: _readBool(json, 'involves_staff'),
    );
  }
}

/// Resultado de `list_counselor_dispatch_cases`: ofertas pendientes y declinadas recientes.
class CounselorDispatchCasesResult {
  const CounselorDispatchCasesResult({
    required this.pendingDispatches,
    required this.declinedDispatches,
  });

  final List<CaseDispatchRecord> pendingDispatches;
  final List<DeclinedDispatchRecord> declinedDispatches;

  factory CounselorDispatchCasesResult.fromJson(Map<String, Object?> json) {
    return CounselorDispatchCasesResult(
      pendingDispatches:
          List<CaseDispatchRecord>.unmodifiable(<CaseDispatchRecord>[
            for (final Object? entry in _readList(json, 'pending_dispatches'))
              if (entry is Map<dynamic, dynamic>)
                CaseDispatchRecord.fromJson(_castMap(entry)),
          ]),
      declinedDispatches:
          List<DeclinedDispatchRecord>.unmodifiable(<DeclinedDispatchRecord>[
            for (final Object? entry in _readList(json, 'declined_dispatches'))
              if (entry is Map<dynamic, dynamic>)
                DeclinedDispatchRecord.fromJson(_castMap(entry)),
          ]),
    );
  }
}

/// Resultado de `recover_declined_case_dispatch`.
class CaseDispatchRecoverResult {
  const CaseDispatchRecoverResult({
    required this.ok,
    required this.caseId,
    this.dispatchStatus,
    this.error,
    this.availabilityState,
  });

  final bool ok;
  final String caseId;
  final CaseDispatchStatus? dispatchStatus;
  final String? error;
  final DeclinedDispatchAvailability? availabilityState;

  factory CaseDispatchRecoverResult.fromJson(Map<String, Object?> json) {
    final String? rawStatus = _readNullableString(json, 'dispatch_status');
    final String? rawAvailability = _readNullableString(
      json,
      'availability_state',
    );
    return CaseDispatchRecoverResult(
      ok: _readBool(json, 'ok'),
      caseId: _readNullableString(json, 'case_id') ?? '',
      dispatchStatus: rawStatus == null || rawStatus.isEmpty
          ? null
          : CaseDispatchStatus.fromWire(rawStatus),
      error: _readNullableString(json, 'error'),
      availabilityState: rawAvailability == null || rawAvailability.isEmpty
          ? null
          : DeclinedDispatchAvailability.fromWire(rawAvailability),
    );
  }
}

/// Estado de cobertura externa de un centro educativo.
class SchoolCoverageStatusView {
  const SchoolCoverageStatusView({
    required this.institutionId,
    required this.publicCode,
    required this.name,
    required this.minedExternalEnabled,
    required this.externalSupportMode,
    required this.coverageActiveNow,
    required this.hasPlantCounselor,
    required this.assignedExternalCount,
    this.externalSupportUntil,
  });

  final String institutionId;
  final String publicCode;
  final String name;
  final bool minedExternalEnabled;
  final ExternalCoverageMode externalSupportMode;
  final DateTime? externalSupportUntil;
  final bool coverageActiveNow;
  final bool hasPlantCounselor;
  final int assignedExternalCount;

  factory SchoolCoverageStatusView.fromJson(Map<String, Object?> json) {
    return SchoolCoverageStatusView(
      institutionId: _readString(json, 'institution_id'),
      publicCode: _readNullableString(json, 'public_code') ?? '',
      name: _readString(json, 'name'),
      minedExternalEnabled: _readBool(json, 'mined_external_enabled'),
      externalSupportMode: ExternalCoverageMode.fromWire(
        _readNullableString(json, 'external_support_mode') ?? 'disabled',
      ),
      externalSupportUntil: _readNullableDateTime(
        json,
        'external_support_until',
      ),
      coverageActiveNow: _readBool(json, 'coverage_active_now'),
      hasPlantCounselor: _readBool(json, 'has_plant_counselor'),
      assignedExternalCount: _readInt(
        json,
        'assigned_external_count',
        fallback: 0,
      ),
    );
  }
}

/// Psicólogo de Red externa con sus centros asignados.
class ExternalCounselorAssignmentView {
  const ExternalCounselorAssignmentView({
    required this.userId,
    required this.email,
    required this.staffTier,
    required this.isAvailable,
    required this.assignedInstitutionIds,
    this.firstName,
    this.lastName,
  });

  final String userId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String staffTier;
  final bool isAvailable;
  final List<String> assignedInstitutionIds;

  String get displayName {
    final String joined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return joined.isEmpty ? email : joined;
  }

  factory ExternalCounselorAssignmentView.fromJson(Map<String, Object?> json) {
    return ExternalCounselorAssignmentView(
      userId: _readString(json, 'user_id'),
      email: _readNullableString(json, 'email') ?? '',
      firstName: _readNullableString(json, 'first_name'),
      lastName: _readNullableString(json, 'last_name'),
      staffTier: _readNullableString(json, 'staff_tier') ?? 'external_network',
      isAvailable: _readBool(json, 'is_available', fallback: true),
      assignedInstitutionIds: List<String>.unmodifiable(<String>[
        for (final Object? entry in _readList(json, 'assigned_institution_ids'))
          if (entry != null) entry.toString(),
      ]),
    );
  }
}

/// Vista conjunta de colegios y asignaciones externas (`list_school_coverage_and_assignments`).
class SchoolCoverageAndAssignmentsView {
  const SchoolCoverageAndAssignmentsView({
    required this.schools,
    required this.externalCounselors,
  });

  final List<SchoolCoverageStatusView> schools;
  final List<ExternalCounselorAssignmentView> externalCounselors;

  factory SchoolCoverageAndAssignmentsView.fromJson(Map<String, Object?> json) {
    return SchoolCoverageAndAssignmentsView(
      schools: List<SchoolCoverageStatusView>.unmodifiable(
        <SchoolCoverageStatusView>[
          for (final Object? entry in _readList(json, 'schools'))
            if (entry is Map<dynamic, dynamic>)
              SchoolCoverageStatusView.fromJson(_castMap(entry)),
        ],
      ),
      externalCounselors: List<ExternalCounselorAssignmentView>.unmodifiable(
        <ExternalCounselorAssignmentView>[
          for (final Object? entry in _readList(json, 'external_counselors'))
            if (entry is Map<dynamic, dynamic>)
              ExternalCounselorAssignmentView.fromJson(_castMap(entry)),
        ],
      ),
    );
  }
}

/// Aviso no bloqueante al psicólogo tutor por actuación de practicante de 5.º año.
class PracticanteSupervisorNoticeView {
  const PracticanteSupervisorNoticeView({
    required this.eventId,
    required this.caseId,
    required this.referenceCode,
    required this.institutionName,
    required this.situationType,
    required this.humanLevel,
    required this.createdAt,
    this.practicanteName,
    this.reason,
  });

  final String eventId;
  final String caseId;
  final String referenceCode;
  final String institutionName;
  final SetuSituationType situationType;
  final int humanLevel;
  final String? practicanteName;
  final String? reason;
  final DateTime createdAt;

  factory PracticanteSupervisorNoticeView.fromJson(Map<String, Object?> json) {
    return PracticanteSupervisorNoticeView(
      eventId: _readString(json, 'event_id'),
      caseId: _readString(json, 'case_id'),
      referenceCode: _readNullableString(json, 'reference_code') ?? '',
      institutionName: _readNullableString(json, 'institution_name') ?? '',
      situationType: SetuSituationType.fromWire(
        _readString(json, 'situation_type'),
      ),
      humanLevel: _readInt(json, 'human_level', fallback: 1),
      practicanteName: _readNullableString(json, 'practicante_name'),
      reason: _readNullableString(json, 'reason'),
      createdAt: _readDateTime(json, 'created_at'),
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

bool _readBool(Map<String, Object?> json, String key, {bool fallback = false}) {
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
