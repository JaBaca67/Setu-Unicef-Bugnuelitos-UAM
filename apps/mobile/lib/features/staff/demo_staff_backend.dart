import 'dart:async';

import '../../shared/models/cureando_models.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'staff_backend.dart';

class _Invite {
  _Invite(
    this.id,
    this.email,
    this.role, {
    this.state = 'active',
    this.staffTier = 'school_plant',
    this.institutionId,
    this.scopeLabel,
    this.fullName,
    this.requesterProgramLabel,
    this.supervisorUserId,
    this.requestStatus = StaffInviteRequestStatus.approved,
    this.approvedBy,
    this.approvedAt,
    this.revokedAt,
    this.revokedReason,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) : expiresAt = expiresAt ?? DateTime(2026, 12, 31, 23, 59),
       createdAt = createdAt ?? DateTime(2026, 11, 13, 8, 0);

  final String id;
  final String email;
  final SetuStaffRole role;
  String state;
  String staffTier;
  String? institutionId;
  String? scopeLabel;
  String? fullName;
  String? requesterProgramLabel;
  String? supervisorUserId;
  StaffInviteRequestStatus requestStatus;
  String? requestedBy;
  String? approvedBy;
  DateTime? approvedAt;
  DateTime? revokedAt;
  String? revokedBy;
  String? revokedReason;
  DateTime? redeemedAt;
  String? replacedByInviteId;
  DateTime expiresAt;
  final DateTime createdAt;
  final List<StaffInviteEventView> events = <StaffInviteEventView>[];
}

class _SchoolCoverage {
  _SchoolCoverage({
    required this.institutionId,
    required this.publicCode,
    required this.name,
    this.minedExternalEnabled = true,
    this.mode = ExternalCoverageMode.enabled,
  });

  final String institutionId;
  final String publicCode;
  final String name;
  bool minedExternalEnabled;
  ExternalCoverageMode mode;
  DateTime? until;

  bool get activeNow {
    if (!minedExternalEnabled) return false;
    return switch (mode) {
      ExternalCoverageMode.disabled => false,
      ExternalCoverageMode.enabled => true,
      ExternalCoverageMode.temporaryUntil =>
        until != null && until!.isAfter(DateTime.now().toUtc()),
    };
  }
}

class _Account {
  _Account(
    this.password, {
    this.confirmed = false,
    this.firstName,
    this.lastName,
    this.staffTier = 'school_plant',
  });

  final String password;
  bool confirmed;
  String? firstName;
  String? lastName;
  String staffTier;
  String? supervisorUserId;
  bool isAvailable = true;
  bool notifyNewAlerts = true;
  bool notifyNewMessages = true;
  final Set<String> assignedInstitutionIds = <String>{};
  final List<StaffMembershipScope> memberships = <StaffMembershipScope>[];
}

class _DemoCase {
  _DemoCase({
    required this.id,
    required this.institutionId,
    required this.reference,
    required this.situation,
    required this.role,
    required this.declaredAt,
    required this.narrative,
    required this.piece,
    this.assignedTo,
    this.status = SetuCaseStatus.received,
    this.level,
    this.chat = false,
    this.origin = SetuAlertOrigin.online,
    this.involvesStaff = false,
    List<CaseChatMessageView>? messages,
    List<CaseActionSheetView>? sheets,
  }) : messages = messages ?? <CaseChatMessageView>[],
       sheets = sheets ?? <CaseActionSheetView>[];

  final String id;
  final String institutionId;
  final String reference;
  final SetuSituationType situation;
  final SetuStudentCaseRole role;
  final DateTime declaredAt;
  final String narrative;
  final StudentPieceSnapshot? piece;
  String? assignedTo;
  SetuCaseStatus status;
  int? level;
  bool chat;
  bool urgent = false;
  int version = 1;
  DateTime? closedAt;
  String? closedReason;
  final List<CaseChatMessageView> messages;
  final List<CaseInternalNoteView> notes = <CaseInternalNoteView>[];

  final SetuAlertOrigin origin;
  final bool involvesStaff;

  /// Fichas mínimas emitidas: nivel y orientación, sin relato ni mensajes.
  final List<CaseActionSheetView> sheets;
  final List<SchoolActionRecordView> actions = <SchoolActionRecordView>[];

  StaffCaseSummary get summary => StaffCaseSummary(
    id: id,
    institutionId: institutionId,
    referenceCode: reference,
    situationType: situation,
    studentRole: role,
    origin: origin,
    status: status,
    humanLevel: level,
    involvesStaff: involvesStaff,
    assignedCounselorId: assignedTo,
    chatAvailableNotice: chat,
    urgentReferralTriggered: urgent,
    concurrencyVersion: version,
    declaredAt: declaredAt,
    receivedCentrallyAt: declaredAt,
    closedAt: closedAt,
    closedReason: closedReason,
    studentPiece: piece,
  );
}

class _DemoDispatch {
  _DemoDispatch(
    this.caseId,
    this.counselor,
    this.tier, {
    this.status = CaseDispatchStatus.pending,
    DateTime? notifiedAt,
  }) : notifiedAt = notifiedAt ?? DateTime(2026, 11, 13, 9, 6);

  final String caseId;
  final String counselor;
  final CaseDispatchTier tier;
  CaseDispatchStatus status;
  final DateTime notifiedAt;
  DateTime? respondedAt;
  String? reason;
}

/// DEMOSTRACIÓN: personal autorizado en memoria, con datos ficticios que no
/// salen del teléfono. Imita las respuestas del servidor para las pruebas de
/// widgets; no es un mecanismo de autenticación.
class DemoStaffBackend implements StaffBackend {
  DemoStaffBackend({this.autoConfirmEmail = false}) {
    _seed(
      'mined.demo@example.org',
      <StaffMembershipScope>[_mined],
      firstName: 'Equipo',
      lastName: 'MINED',
      staffTier: 'mined_central',
    );
    _seed(
      'escucha.demo@example.org',
      <StaffMembershipScope>[
        _scope('m-desk-cca', SetuStaffRole.counselingDesk, cca),
        _scope('m-desk-a', SetuStaffRole.counselingDesk, schoolA),
      ],
      firstName: 'María',
      lastName: 'Pérez',
      staffTier: 'external_network',
      assignedSchools: <String>[cca.id, schoolA.id],
    );
    _seed(
      'direccion.cca@example.org',
      <StaffMembershipScope>[
        _scope('m-dir-cca', SetuStaffRole.schoolDirector, cca),
      ],
      firstName: 'Dirección',
      lastName: 'Centro América',
      staffTier: 'school_director',
    );
    _seed(
      externalCounselor,
      const <StaffMembershipScope>[
        StaffMembershipScope(
          membershipId: 'm-desk-ext',
          role: SetuStaffRole.counselingDesk,
          scopeLabel: 'Mesa de Escucha · Red externa · demostración',
        ),
      ],
      firstName: 'Carlos',
      lastName: 'Mendoza',
      staffTier: 'external_network',
      assignedSchools: <String>[cca.id],
    );
  }

  /// Cuenta ficticia de la red externa de Mesa de Escucha.
  static const String externalCounselor = 'red.externa@example.org';

  /// Contraseña ficticia de las cuentas de demostración en memoria.
  static const String demoPassword = 'Demo-SeTu-2026';

  static const ({String id, String code, String name}) cca = (
    id: 'demo-cca',
    code: 'AULA26',
    name: 'Colegio Centro América — Demo',
  );
  static const ({String id, String code, String name}) schoolA = (
    id: 'demo-a',
    code: 'AULA24',
    name: 'Colegio de prueba A',
  );

  static const StaffMembershipScope _mined = StaffMembershipScope(
    membershipId: 'm-mined',
    role: SetuStaffRole.minedSupervisor,
    scopeLabel: 'MINED central · demostración',
  );

  static StaffMembershipScope _scope(
    String id,
    SetuStaffRole role,
    ({String id, String code, String name}) school,
  ) => StaffMembershipScope(
    membershipId: id,
    role: role,
    institutionId: school.id,
    institutionPublicCode: school.code,
    institutionName: school.name,
    scopeLabel: '${role.label} · ${school.name}',
  );

  /// Si es verdadero, el registro deja el correo confirmado de inmediato.
  final bool autoConfirmEmail;

  final Map<String, _Account> _accounts = <String, _Account>{};
  final Map<String, _SchoolCoverage> _coverages = <String, _SchoolCoverage>{
    cca.id: _SchoolCoverage(
      institutionId: cca.id,
      publicCode: cca.code,
      name: cca.name,
      minedExternalEnabled: true,
      mode: ExternalCoverageMode.enabled,
    ),
    schoolA.id: _SchoolCoverage(
      institutionId: schoolA.id,
      publicCode: schoolA.code,
      name: schoolA.name,
      minedExternalEnabled: true,
      mode: ExternalCoverageMode.enabled,
    ),
  };
  final List<PracticanteSupervisorNoticeView> _supervisorNotices =
      <PracticanteSupervisorNoticeView>[];
  final Map<String, _Invite> _invites = <String, _Invite>{
    'CCADIR2026': _Invite(
      'inv-dir-1',
      'invitada.cca@example.org',
      SetuStaffRole.schoolDirector,
      staffTier: 'school_director',
      institutionId: cca.id,
      scopeLabel: 'Dirección del centro · Colegio Centro América — Demo',
      approvedBy: 'mined.demo@example.org',
      approvedAt: DateTime(2026, 11, 13, 8, 5),
    ),
    'CCAMESA2026': _Invite(
      'inv-mesa-1',
      'practicante.cca@example.org',
      SetuStaffRole.counselingDesk,
      staffTier: 'practicante_5to',
      institutionId: cca.id,
      supervisorUserId: 'escucha.demo@example.org',
      scopeLabel: 'Mesa de Escucha · Colegio Centro América — Demo',
      approvedBy: 'mined.demo@example.org',
      approvedAt: DateTime(2026, 11, 13, 8, 5),
    ),
    'CCAEXP2026': _Invite(
      'inv-exp-1',
      'expirada.cca@example.org',
      SetuStaffRole.counselingDesk,
      state: 'expired',
      institutionId: cca.id,
      scopeLabel: 'Mesa de Escucha · Colegio Centro América — Demo',
    ),
    'CCAREV2026': _Invite(
      'inv-rev-1',
      'revocada.cca@example.org',
      SetuStaffRole.counselingDesk,
      state: 'revoked',
      institutionId: cca.id,
      scopeLabel: 'Mesa de Escucha · Colegio Centro América — Demo',
      revokedReason: 'Código anulado en demostración',
      revokedAt: DateTime(2026, 11, 13, 8, 10),
    ),
  };
  String? _user;

  static const String _desk = 'escucha.demo@example.org';

  final StreamController<SetuAssignmentNotice> _notices =
      StreamController<SetuAssignmentNotice>.broadcast();
  final StreamController<CaseChatMessageView> _liveMessages =
      StreamController<CaseChatMessageView>.broadcast();
  int _sequence = 0;

  final List<_DemoCase> _cases = <_DemoCase>[
    _DemoCase(
      id: 'demo-case-014',
      institutionId: schoolA.id,
      reference: 'DEMO-014',
      situation: SetuSituationType.verbalBullying,
      role: SetuStudentCaseRole.victim,
      declaredAt: DateTime(2026, 11, 13, 10, 24),
      narrative: 'Se burlan de mí durante el recreo.',
      piece: const StudentPieceSnapshot(
        shape: 'puzzle',
        color: 'green',
        accessories: <String>[],
      ),
      assignedTo: _desk,
      status: SetuCaseStatus.inListening,
    ),
    _DemoCase(
      id: 'demo-case-009',
      institutionId: schoolA.id,
      reference: 'DEMO-009',
      situation: SetuSituationType.socialBullying,
      role: SetuStudentCaseRole.solidarityWitness,
      declaredAt: DateTime(2026, 11, 12, 15, 40),
      narrative: '',
      piece: const StudentPieceSnapshot(
        shape: 'flower',
        color: 'yellow',
        accessories: <String>['bowTie'],
      ),
      assignedTo: _desk,
      status: SetuCaseStatus.inListening,
      level: 2,
      chat: true,
      messages: <CaseChatMessageView>[
        CaseChatMessageView(
          id: 'demo-msg-1',
          caseId: 'demo-case-009',
          senderRole: SetuMessageSender.student,
          body: 'Me cuesta hablar de esto.',
          createdAt: DateTime(2026, 11, 12, 15, 52),
        ),
        CaseChatMessageView(
          id: 'demo-msg-2',
          caseId: 'demo-case-009',
          senderRole: SetuMessageSender.counselingDesk,
          body: 'Podés contarme a tu ritmo.',
          createdAt: DateTime(2026, 11, 12, 15, 53),
        ),
      ],
    ),
    _DemoCase(
      id: 'demo-case-030',
      institutionId: cca.id,
      reference: 'DEMO-030',
      situation: SetuSituationType.cyberbullying,
      role: SetuStudentCaseRole.victim,
      declaredAt: DateTime(2026, 11, 11, 8, 30),
      narrative: 'Relato ficticio reservado a Mesa de Escucha.',
      piece: null,
      assignedTo: _desk,
      status: SetuCaseStatus.sheetSent,
      level: 2,
      sheets: <CaseActionSheetView>[
        CaseActionSheetView(
          id: 'demo-sheet-030',
          caseId: 'demo-case-030',
          institutionId: cca.id,
          version: 1,
          issuedBy: _desk,
          humanLevel: 2,
          summaryType: SetuSituationType.cyberbullying,
          summaryRole: SetuStudentCaseRole.victim,
          omitSchoolDueToConflict: false,
          guidanceNotes:
              'Orientación ficticia: reforzar los acuerdos de convivencia '
              'del grupo sin señalar a nadie.',
          issuedAt: DateTime(2026, 11, 12, 9, 15),
        ),
      ],
    ),
    _DemoCase(
      id: 'demo-case-021',
      institutionId: cca.id,
      reference: 'DEMO-021',
      situation: SetuSituationType.needToTalk,
      role: SetuStudentCaseRole.victim,
      declaredAt: DateTime(2026, 11, 13, 9, 5),
      narrative: 'Relato ficticio de demostración.',
      piece: const StudentPieceSnapshot(
        shape: 'star',
        color: 'blue',
        accessories: <String>['glasses'],
      ),
    ),
  ];

  /// Despachos ficticios: la alerta sin asignar se ofrece al equipo de
  /// planta; las ya asignadas figuran como atendidas.
  final List<_DemoDispatch> _dispatches = <_DemoDispatch>[
    _DemoDispatch('demo-case-021', _desk, CaseDispatchTier.schoolPlant),
    for (final String id in <String>[
      'demo-case-014',
      'demo-case-009',
      'demo-case-030',
    ])
      _DemoDispatch(
        id,
        _desk,
        CaseDispatchTier.schoolPlant,
        status: CaseDispatchStatus.claimed,
      )..respondedAt = DateTime(2026, 11, 13, 9, 30),
  ];
  final StreamController<CaseDispatchRecord> _dispatchEvents =
      StreamController<CaseDispatchRecord>.broadcast();

  CaseDispatchRecord _record(_DemoDispatch item) {
    final _DemoCase found = _cases.firstWhere(
      (_DemoCase entry) => entry.id == item.caseId,
    );
    return CaseDispatchRecord(
      id: 'demo-dispatch-${item.caseId}-${item.counselor}',
      caseId: item.caseId,
      institutionId: found.institutionId,
      counselorUserId: item.counselor,
      dispatchTier: item.tier,
      dispatchStatus: item.status,
      notifiedAt: item.notifiedAt,
      referenceCode: found.reference,
      institutionName: found.institutionId == cca.id ? cca.name : schoolA.name,
      situationType: found.situation,
      caseStatus: found.status,
      assignedCounselorId: found.assignedTo,
      counselorEmail: item.counselor,
      respondedAt: item.respondedAt,
      declineReason: item.reason,
    );
  }

  /// Deja el despacho coherente con quién atiende el caso y avisa en vivo a
  /// las demás personas a las que se les había ofrecido.
  void _settleDispatches(_DemoCase found, String winner, {bool notify = true}) {
    final DateTime now = DateTime.now();
    bool winnerListed = false;
    for (final _DemoDispatch item in _dispatches) {
      if (item.caseId != found.id) continue;
      if (item.counselor == winner) {
        winnerListed = true;
        item
          ..status = CaseDispatchStatus.claimed
          ..respondedAt = now;
      } else if (item.status == CaseDispatchStatus.pending ||
          item.status == CaseDispatchStatus.claimed) {
        item
          ..status = CaseDispatchStatus.takenByOther
          ..respondedAt = now;
        if (notify) _dispatchEvents.add(_record(item));
      }
    }
    if (!winnerListed) {
      _dispatches.add(
        _DemoDispatch(
          found.id,
          winner,
          CaseDispatchTier.schoolPlant,
          status: CaseDispatchStatus.claimed,
          notifiedAt: now,
        )..respondedAt = now,
      );
    }
  }

  /// Simula que otra persona de Mesa de Escucha tomó la alerta primero.
  /// Solo para pruebas y demostración.
  /// Con [notify] en falso no llega el aviso en vivo, como cuando dos
  /// personas tocan «Tomar alerta» casi al mismo tiempo.
  void simulateOtherClaim(String caseId, {bool notify = true}) {
    final _DemoCase found = _cases.firstWhere(
      (_DemoCase item) => item.id == caseId,
    );
    found
      ..assignedTo = 'otra.persona@example.org'
      ..status = SetuCaseStatus.inListening
      ..version += 1;
    _settleDispatches(found, 'otra.persona@example.org', notify: notify);
  }

  @override
  Future<CaseClaimResult> claimCase({
    required String operationId,
    required String caseId,
  }) async {
    _scopes();
    final _DemoDispatch? mine = _dispatches
        .where(
          (_DemoDispatch item) =>
              item.caseId == caseId && item.counselor == _user,
        )
        .firstOrNull;
    final _DemoCase? found = _cases
        .where((_DemoCase item) => item.id == caseId)
        .firstOrNull;
    if (mine == null || found == null) {
      throw const GatewayException('P0002', 'case_not_found');
    }
    if (!_has(SetuStaffRole.counselingDesk, found.institutionId)) {
      throw const GatewayException(
        '42501',
        'forbidden_counseling_desk_required',
      );
    }
    final String? holder = found.assignedTo;
    if (holder != null && holder != _user) {
      mine
        ..status = CaseDispatchStatus.takenByOther
        ..respondedAt ??= DateTime.now();
      return CaseClaimResult(
        ok: false,
        claimed: false,
        alreadyAssignedToYou: false,
        error: 'case_already_taken',
        caseId: caseId,
        assignedCounselorId: holder,
      );
    }
    final bool already = holder == _user;
    if (!already) {
      found
        ..assignedTo = _user
        ..version += 1;
      if (found.status == SetuCaseStatus.received) {
        found.status = SetuCaseStatus.inListening;
      }
      _settleDispatches(found, _user!);
    }
    return CaseClaimResult(
      ok: true,
      claimed: !already,
      alreadyAssignedToYou: already,
      caseId: caseId,
      assignedCounselorId: _user!,
      status: found.status,
      humanLevel: found.level,
      concurrencyVersion: found.version,
    );
  }

  @override
  Future<CaseDeclineResult> declineDispatch({
    required String operationId,
    required String caseId,
    String? reason,
  }) async {
    _scopes();
    final _DemoDispatch mine = _dispatches.firstWhere(
      (_DemoDispatch item) =>
          item.caseId == caseId &&
          item.counselor == _user &&
          item.status == CaseDispatchStatus.pending,
      orElse: () => throw const GatewayException('P0002', 'case_not_found'),
    );
    final String clean = (reason ?? '').trim();
    if (clean.length > 500) {
      throw const GatewayException('22023', 'invalid_decline_reason');
    }
    mine
      ..status = CaseDispatchStatus.declined
      ..respondedAt = DateTime.now()
      ..reason = clean.isEmpty ? null : clean;
    // Si nadie más del equipo de planta la tiene pendiente, pasa a la red
    // externa.
    final bool othersPending = _dispatches.any(
      (_DemoDispatch item) =>
          item.caseId == caseId && item.status == CaseDispatchStatus.pending,
    );
    final bool alreadyExternal = _dispatches.any(
      (_DemoDispatch item) =>
          item.caseId == caseId && item.tier == CaseDispatchTier.externalPool,
    );
    final bool fallback = !othersPending && !alreadyExternal;
    if (fallback) {
      final _DemoDispatch external = _DemoDispatch(
        caseId,
        externalCounselor,
        CaseDispatchTier.externalPool,
        notifiedAt: DateTime.now(),
      );
      _dispatches.add(external);
      _dispatchEvents.add(_record(external));
    }
    return CaseDeclineResult(
      ok: true,
      caseId: caseId,
      dispatchStatus: CaseDispatchStatus.declined,
      fallbackTier: fallback ? CaseDispatchTier.externalPool : null,
      fallbackDispatchedCount: fallback ? 1 : null,
    );
  }

  @override
  Future<List<CaseDispatchRecord>> dispatchHistory({
    String? institutionId,
    String? caseId,
  }) async {
    final List<StaffMembershipScope> scopes = _scopes();
    final bool mined = scopes.any(
      (StaffMembershipScope scope) =>
          scope.role == SetuStaffRole.minedSupervisor,
    );
    final bool desk = scopes.any(
      (StaffMembershipScope scope) =>
          scope.role == SetuStaffRole.counselingDesk,
    );
    if (!mined && !desk) {
      throw const GatewayException('42501', 'forbidden_staff_role_required');
    }
    final List<CaseDispatchRecord> records = <CaseDispatchRecord>[
      for (final _DemoDispatch item in _dispatches)
        if (mined || item.counselor == _user) _record(item),
    ];
    return <CaseDispatchRecord>[
      for (final CaseDispatchRecord record in records)
        if ((caseId == null || record.caseId == caseId) &&
            (institutionId == null || record.institutionId == institutionId))
          record,
    ]..sort(
      (CaseDispatchRecord a, CaseDispatchRecord b) =>
          b.notifiedAt.compareTo(a.notifiedAt),
    );
  }

  @override
  Stream<CaseDispatchRecord> incomingDispatches() {
    final String? user = _user;
    return _dispatchEvents.stream.where(
      (CaseDispatchRecord record) => record.counselorUserId == user,
    );
  }

  /// Simula una caída de conexión en las pruebas.
  bool offline = false;

  void _seed(
    String email,
    List<StaffMembershipScope> memberships, {
    String? firstName,
    String? lastName,
    String staffTier = 'school_plant',
    List<String> assignedSchools = const <String>[],
  }) {
    final _Account account = _Account(
      demoPassword,
      confirmed: true,
      firstName: firstName,
      lastName: lastName,
      staffTier: staffTier,
    )..memberships.addAll(memberships);
    account.assignedInstitutionIds.addAll(assignedSchools);
    _accounts[email] = account;
  }

  /// Simula que la persona abrió el enlace de confirmación de su correo.
  void confirmEmail(String email) => _accounts[_clean(email)]?.confirmed = true;

  static String _clean(String email) => email.trim().toLowerCase();

  static String _normalize(String code) =>
      code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  void _online() {
    if (offline) throw const GatewayException('remote_error', 'offline');
  }

  @override
  bool get isDemo => true;

  @override
  String? get currentUserId => _user;

  @override
  String? get currentUserEmail => _user;

  @override
  bool get isEmailConfirmed =>
      _user != null && (_accounts[_user]?.confirmed ?? false);

  @override
  Future<StaffActivationPreview> previewActivation(
    String code, {
    String? email,
  }) async {
    _online();
    final _Account? account = _accounts[_user];
    if (account == null) {
      throw const GatewayException('42501', 'authentication_required');
    }
    if (!account.confirmed) {
      throw const GatewayException('42501', 'email_not_verified');
    }
    final _Invite? invite = _invites[_normalize(code)];
    if (invite == null) {
      return const StaffActivationPreview(
        ok: false,
        error: 'invalid_activation_code',
      );
    }
    if (invite.requestStatus != StaffInviteRequestStatus.approved) {
      return const StaffActivationPreview(
        ok: false,
        error: 'activation_code_not_approved',
      );
    }
    if (invite.state != 'active') {
      return StaffActivationPreview(
        ok: false,
        error: switch (invite.state) {
          'expired' => 'activation_code_expired',
          'revoked' => 'activation_code_revoked',
          _ => 'activation_code_already_used',
        },
      );
    }
    if (invite.email != _user) {
      return const StaffActivationPreview(
        ok: false,
        error: 'activation_email_mismatch',
        remainingAttempts: 4,
      );
    }
    final ({String id, String code, String name})? school =
        invite.institutionId == cca.id
            ? cca
            : invite.institutionId == schoolA.id
            ? schoolA
            : null;
    return StaffActivationPreview(
      ok: true,
      inviteId: invite.id,
      role: invite.role,
      staffTier: invite.staffTier,
      supervisorUserId: invite.supervisorUserId,
      institutionId: school?.id,
      institutionPublicCode: school?.code,
      institutionName: school?.name,
      scopeLabel: invite.scopeLabel ?? '${invite.role.label} · ${school?.name ?? 'Red externa'}',
      expiresAt: invite.expiresAt,
    );
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    _online();
    final String key = _clean(email);
    if (_accounts.containsKey(key)) {
      throw const GatewayException('user_already_exists', '');
    }
    _accounts[key] = _Account(password, confirmed: autoConfirmEmail);
    if (autoConfirmEmail) _user = key;
  }

  @override
  Future<void> resendConfirmationEmail({required String email}) async {
    _online();
  }

  @override
  Future<void> refreshAuthSession() async {
    _online();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    _online();
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _online();
    final _Account? account = _accounts[_clean(email)];
    if (account == null || account.password != password) {
      throw const GatewayException('invalid_credentials', '');
    }
    if (!account.confirmed) {
      throw const GatewayException('email_not_confirmed', '');
    }
    _user = _clean(email);
  }

  @override
  Future<void> signOut() async => _user = null;

  /// Restaura la sesión en memoria de una cuenta de demostración ya validada
  /// previamente en el dispositivo.
  void restoreUser(String? email) {
    if (email == null) return;
    final String key = _clean(email);
    final _Account? account = _accounts[key];
    if (account != null && account.confirmed) {
      _user = key;
    }
  }

  @override
  Future<StaffActivationRedemption> redeemActivation(String code) =>
      redeemActivationWithProfile(
        code: code,
        firstName: 'Personal',
        lastName: 'Demo',
      );

  @override
  Future<StaffActivationRedemption> redeemActivationWithProfile({
    required String code,
    required String firstName,
    required String lastName,
  }) async {
    _online();
    final _Account? account = _accounts[_user];
    if (account == null) {
      throw const GatewayException('42501', 'authentication_required');
    }
    if (!account.confirmed) {
      throw const GatewayException('42501', 'email_not_verified');
    }
    final String cleanFirst = firstName.trim();
    final String cleanLast = lastName.trim();
    if (cleanFirst.isEmpty || cleanLast.isEmpty) {
      throw const GatewayException('22023', 'first_and_last_name_required');
    }
    final _Invite? invite = _invites[_normalize(code)];
    if (invite == null ||
        invite.state != 'active' ||
        invite.requestStatus != StaffInviteRequestStatus.approved) {
      return StaffActivationRedemption(
        ok: false,
        error: invite == null
            ? 'invalid_activation_code'
            : invite.state == 'revoked'
            ? 'activation_code_revoked'
            : invite.state == 'expired'
            ? 'activation_code_expired'
            : 'activation_code_already_used',
      );
    }
    if (invite.email != _user) {
      return const StaffActivationRedemption(
        ok: false,
        error: 'activation_email_mismatch',
      );
    }
    invite
      ..state = 'used'
      ..redeemedAt = DateTime.now().toUtc()
      ..events.add(
        StaffInviteEventView(
          id: 'evt-${++_sequence}',
          eventType: 'redeemed',
          actorUserId: _user,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    account
      ..firstName = cleanFirst
      ..lastName = cleanLast
      ..staffTier = invite.staffTier
      ..supervisorUserId = invite.supervisorUserId;
    final ({String id, String code, String name})? school =
        invite.institutionId == schoolA.id
            ? schoolA
            : invite.institutionId == cca.id
            ? cca
            : null;
    final StaffMembershipScope scope = school != null
        ? _scope('m-${_normalize(code)}', invite.role, school)
        : StaffMembershipScope(
            membershipId: 'm-${_normalize(code)}',
            role: invite.role,
            scopeLabel: invite.scopeLabel ?? invite.role.label,
          );
    account.memberships.add(scope);
    return StaffActivationRedemption(
      ok: true,
      membershipId: scope.membershipId,
      role: scope.role,
      staffTier: invite.staffTier,
      supervisorUserId: invite.supervisorUserId,
      institutionId: scope.institutionId,
      scopeLabel: scope.scopeLabel,
      firstName: cleanFirst,
      lastName: cleanLast,
    );
  }

  @override
  Future<StaffProfileView?> profile() async {
    _online();
    final String? uid = _user;
    final _Account? account = uid == null ? null : _accounts[uid];
    if (account == null || uid == null) {
      throw const GatewayException('42501', 'authentication_required');
    }
    final _Account? sup = account.supervisorUserId == null
        ? null
        : _accounts[account.supervisorUserId];
    final String? supName = sup == null
        ? null
        : '${sup.firstName ?? ''} ${sup.lastName ?? ''}'.trim();
    final List<StaffSchoolScopeItem> assigned = <StaffSchoolScopeItem>[
      for (final _SchoolCoverage cov in _coverages.values)
        if (account.assignedInstitutionIds.contains(cov.institutionId))
          StaffSchoolScopeItem(
            institutionId: cov.institutionId,
            publicCode: cov.publicCode,
            name: cov.name,
            coverageActiveNow: cov.activeNow,
            externalSupportMode: cov.mode,
            externalSupportUntil: cov.until,
          ),
    ];
    final List<StaffSchoolScopeItem> available = <StaffSchoolScopeItem>[
      for (final _SchoolCoverage cov in _coverages.values)
        if (!account.assignedInstitutionIds.contains(cov.institutionId))
          StaffSchoolScopeItem(
            institutionId: cov.institutionId,
            publicCode: cov.publicCode,
            name: cov.name,
            coverageActiveNow: cov.activeNow,
            externalSupportMode: cov.mode,
            externalSupportUntil: cov.until,
          ),
    ];
    return StaffProfileView(
      userId: uid,
      email: uid,
      emailConfirmed: account.confirmed,
      firstName: account.firstName,
      lastName: account.lastName,
      staffTier: account.staffTier,
      supervisorUserId: account.supervisorUserId,
      supervisorName: supName?.isEmpty ?? true ? null : supName,
      isAvailable: account.isAvailable,
      notifyNewAlerts: account.notifyNewAlerts,
      notifyNewMessages: account.notifyNewMessages,
      memberships: List<StaffMembershipScope>.unmodifiable(account.memberships),
      assignedSchools: assigned,
      availableSchools: available,
    );
  }

  @override
  Future<void> updateAvailabilityAndNotices({
    required bool isAvailable,
    required bool notifyNewAlerts,
    required bool notifyNewMessages,
  }) async {
    _online();
    final _Account? account = _accounts[_user];
    if (account == null) {
      throw const GatewayException('42501', 'authentication_required');
    }
    account
      ..isAvailable = isAvailable
      ..notifyNewAlerts = notifyNewAlerts
      ..notifyNewMessages = notifyNewMessages;
  }

  @override
  Future<void> requestInviteReplacement({
    required String email,
    required String reasonCode,
    String? notes,
  }) async {
    _online();
  }

  @override
  Future<List<StaffActivationInviteView>> invites({
    String? institutionId,
  }) async {
    final List<StaffMembershipScope> scopes = _scopes();
    final bool mined = scopes.any(
      (StaffMembershipScope s) => s.role == SetuStaffRole.minedSupervisor,
    );
    final Set<String?> directed = <String?>{
      for (final StaffMembershipScope s in scopes)
        if (s.role == SetuStaffRole.schoolDirector) s.institutionId,
    };
    if (!mined && directed.isEmpty) {
      throw const GatewayException('42501', 'forbidden_invite_viewer_required');
    }
    return <StaffActivationInviteView>[
      for (final _Invite item in _invites.values)
        if ((mined || (item.institutionId != null && directed.contains(item.institutionId))) &&
            (institutionId == null || item.institutionId == institutionId))
          StaffActivationInviteView(
            inviteId: item.id,
            institutionalEmail: item.email,
            fullName: item.fullName,
            role: item.role,
            staffTier: item.staffTier,
            institutionId: item.institutionId,
            institutionName: item.institutionId == cca.id
                ? cca.name
                : item.institutionId == schoolA.id
                ? schoolA.name
                : null,
            scopeLabel: item.scopeLabel ?? item.role.label,
            requestStatus: item.requestStatus,
            requesterProgramLabel: item.requesterProgramLabel,
            supervisorUserId: item.supervisorUserId,
            requestedBy: item.requestedBy,
            approvedBy: item.approvedBy,
            approvedAt: item.approvedAt,
            expiresAt: item.expiresAt,
            revokedAt: item.revokedAt,
            revokedBy: item.revokedBy,
            revokedReason: item.revokedReason,
            redeemedAt: item.redeemedAt,
            replacedByInviteId: item.replacedByInviteId,
            createdAt: item.createdAt,
            events: List<StaffInviteEventView>.unmodifiable(item.events),
          ),
    ];
  }

  @override
  Future<void> requestInvite({
    required String email,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? fullName,
    String? requesterProgramLabel,
    String? supervisorUserId,
  }) async {
    _online();
    final bool director = institutionId != null &&
        _has(SetuStaffRole.schoolDirector, institutionId);
    final bool mined = _has(SetuStaffRole.minedSupervisor);
    if (!director && !mined) {
      throw const GatewayException('42501', 'forbidden_invite_requester');
    }
    if (director && !mined && staffTier != 'school_plant') {
      throw const GatewayException('42501', 'forbidden_invite_tier');
    }
    final String code = 'REQ${++_sequence}2026';
    _invites[code] = _Invite(
      'inv-req-$_sequence',
      _clean(email),
      role,
      staffTier: staffTier,
      institutionId: institutionId,
      fullName: fullName,
      requesterProgramLabel: requesterProgramLabel,
      supervisorUserId: supervisorUserId,
      requestStatus: StaffInviteRequestStatus.pendingApproval,
      scopeLabel: '${role.label} · ${institutionId == schoolA.id ? schoolA.name : cca.name}',
    )
      ..requestedBy = _user
      ..events.add(
        StaffInviteEventView(
          id: 'evt-${++_sequence}',
          eventType: 'requested',
          actorUserId: _user,
          createdAt: DateTime.now().toUtc(),
        ),
      );
  }

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
  }) async {
    _online();
    if (!_has(SetuStaffRole.minedSupervisor)) {
      throw const GatewayException('42501', 'forbidden_mined_required');
    }
    final DateTime now = DateTime.now().toUtc();
    if (pendingInviteId != null) {
      final _Invite pending = _invites.values.firstWhere(
        (_Invite i) => i.id == pendingInviteId,
      );
      pending
        ..requestStatus = StaffInviteRequestStatus.approved
        ..supervisorUserId = supervisorUserId ?? pending.supervisorUserId
        ..approvedBy = _user
        ..approvedAt = now
        ..expiresAt = now.add(Duration(hours: expiresInHours));
      final String code = _invites.entries
          .firstWhere((MapEntry<String, _Invite> e) => e.value.id == pending.id)
          .key;
      return StaffInviteIssueResult(
        ok: true,
        inviteId: pending.id,
        activationCode: code,
        institutionalEmail: pending.email,
        role: pending.role,
        staffTier: pending.staffTier,
        institutionId: pending.institutionId,
        scopeLabel: pending.scopeLabel ?? pending.role.label,
        expiresAt: pending.expiresAt,
      );
    }
    final String code = 'SETU${++_sequence}26';
    final SetuStaffRole resolvedRole = role ?? SetuStaffRole.counselingDesk;
    final String resolvedTier = staffTier ?? 'school_plant';
    final _Invite invite = _Invite(
      'inv-$_sequence',
      _clean(email ?? ''),
      resolvedRole,
      staffTier: resolvedTier,
      institutionId: institutionId,
      fullName: fullName,
      supervisorUserId: supervisorUserId,
      scopeLabel: scopeLabel ?? resolvedRole.label,
      approvedBy: _user,
      approvedAt: now,
      expiresAt: now.add(Duration(hours: expiresInHours)),
    );
    invite.events.add(
      StaffInviteEventView(
        id: 'evt-${++_sequence}',
        eventType: 'issued',
        actorUserId: _user,
        createdAt: now,
      ),
    );
    _invites[code] = invite;
    return StaffInviteIssueResult(
      ok: true,
      inviteId: invite.id,
      activationCode: code,
      institutionalEmail: invite.email,
      role: invite.role,
      staffTier: invite.staffTier,
      institutionId: invite.institutionId,
      scopeLabel: invite.scopeLabel ?? '',
      expiresAt: invite.expiresAt,
    );
  }

  @override
  Future<void> revokeInvite({required String inviteId, String? reason}) async {
    _online();
    if (!_has(SetuStaffRole.minedSupervisor)) {
      throw const GatewayException('42501', 'forbidden_mined_required');
    }
    final _Invite found = _invites.values.firstWhere(
      (_Invite i) => i.id == inviteId,
    );
    found
      ..state = 'revoked'
      ..revokedAt = DateTime.now().toUtc()
      ..revokedBy = _user
      ..revokedReason = reason
      ..requestStatus =
          found.requestStatus == StaffInviteRequestStatus.pendingApproval
          ? StaffInviteRequestStatus.rejected
          : found.requestStatus;
  }

  @override
  Future<void> submitAccessRequest({
    required String fullName,
    required String email,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? requesterProgramLabel,
  }) async {
    _online();
    final String cleanFullName = fullName.trim();
    if (cleanFullName.length < 3) {
      throw const GatewayException('22023', 'invalid_full_name');
    }
    final String cleanEmail = _clean(email);
    if (!cleanEmail.contains('@')) {
      throw const GatewayException('22023', 'invalid_institutional_email');
    }
    if (role == SetuStaffRole.minedSupervisor || staffTier == 'mined_central') {
      throw const GatewayException('42501', 'forbidden_mined_self_request');
    }
    if ((role == SetuStaffRole.schoolDirector || staffTier == 'school_plant') &&
        (institutionId == null || institutionId.isEmpty)) {
      throw const GatewayException('22023', 'institution_required_for_role');
    }
    final bool duplicate = _invites.values.any(
      (_Invite item) =>
          item.email == cleanEmail &&
          item.revokedAt == null &&
          item.redeemedAt == null &&
          item.replacedByInviteId == null &&
          (item.requestStatus == StaffInviteRequestStatus.pendingApproval ||
              item.expiresAt.isAfter(DateTime.now().toUtc())),
    );
    if (duplicate) {
      throw const GatewayException('23505', 'duplicate_pending_staff_request');
    }
    final String resolvedTier = role == SetuStaffRole.schoolDirector
        ? 'school_director'
        : staffTier;
    final String code = 'REQ${++_sequence}2026';
    final String schoolLabel = institutionId == schoolA.id
        ? schoolA.name
        : institutionId == cca.id
        ? cca.name
        : resolvedTier == 'practicante_5to'
        ? 'Practicante 5.º año · Mesa de escucha'
        : 'Red externa nacional';
    _invites[code] = _Invite(
      'inv-req-$_sequence',
      cleanEmail,
      role,
      staffTier: resolvedTier,
      institutionId: institutionId,
      fullName: cleanFullName,
      requesterProgramLabel: requesterProgramLabel?.trim().isEmpty == true
          ? null
          : requesterProgramLabel?.trim(),
      requestStatus: StaffInviteRequestStatus.pendingApproval,
      scopeLabel: schoolLabel,
    )
      ..events.add(
        StaffInviteEventView(
          id: 'evt-${++_sequence}',
          eventType: 'requested',
          details: 'Solicitud enviada para aprobación del MINED',
          createdAt: DateTime.now().toUtc(),
        ),
      );
  }

  @override
  Future<BulkInviteResult> issueInvitesBulk({
    required List<BulkInviteRowDraft> rows,
    int expiresInHours = 72,
  }) async {
    _online();
    if (!_has(SetuStaffRole.minedSupervisor)) {
      throw const GatewayException('42501', 'forbidden_mined_required');
    }
    if (rows.isEmpty || rows.length > 200) {
      throw const GatewayException('22023', 'invalid_bulk_rows_count');
    }
    final List<BulkInviteRowResult> results = <BulkInviteRowResult>[];
    int issued = 0;
    int errors = 0;
    for (int i = 0; i < rows.length; i++) {
      final BulkInviteRowDraft row = rows[i];
      try {
        final String cleanEmail = _clean(row.institutionalEmail);
        if (!cleanEmail.contains('@')) {
          throw const GatewayException('22023', 'invalid_institutional_email');
        }
        final String rawRole = row.role.trim().toLowerCase();
        final SetuStaffRole role =
            rawRole == 'school_director' || rawRole == 'director'
            ? SetuStaffRole.schoolDirector
            : rawRole == 'mined_supervisor' || rawRole == 'mined'
            ? SetuStaffRole.minedSupervisor
            : SetuStaffRole.counselingDesk;
        final String tier = role == SetuStaffRole.schoolDirector
            ? 'school_director'
            : role == SetuStaffRole.minedSupervisor
            ? 'mined_central'
            : (row.staffTier.trim().isEmpty ? 'school_plant' : row.staffTier);
        String? instId;
        String scope = role == SetuStaffRole.minedSupervisor
            ? 'MINED central'
            : 'Red externa nacional';
        final String ref = (row.schoolRef ?? '').trim().toLowerCase();
        if (ref.isNotEmpty) {
          if (ref == cca.id || ref == 'aula26' || ref.contains('centro am')) {
            instId = cca.id;
            scope = cca.name;
          } else if (ref == schoolA.id || ref == 'aula24' || ref.contains('demo')) {
            instId = schoolA.id;
            scope = schoolA.name;
          } else {
            throw const GatewayException('P0002', 'institution_not_found');
          }
        }
        if ((role == SetuStaffRole.schoolDirector || tier == 'school_plant') &&
            instId == null) {
          throw const GatewayException('22023', 'institution_required_for_role');
        }
        final StaffInviteIssueResult out = await issueInvite(
          email: cleanEmail,
          role: role,
          institutionId: instId,
          staffTier: tier,
          scopeLabel: scope,
          fullName: row.fullName,
          expiresInHours: expiresInHours,
        );
        issued++;
        results.add(
          BulkInviteRowResult(
            index: i + 1,
            ok: true,
            institutionalEmail: out.institutionalEmail,
            fullName: row.fullName,
            inviteId: out.inviteId,
            activationCode: out.activationCode,
            scopeLabel: out.scopeLabel,
            role: out.role,
            staffTier: out.staffTier,
            expiresAt: out.expiresAt,
          ),
        );
      } on Object catch (failure) {
        errors++;
        results.add(
          BulkInviteRowResult(
            index: i + 1,
            ok: false,
            institutionalEmail: row.institutionalEmail,
            fullName: row.fullName,
            error: staffErrorMessage(failure),
          ),
        );
      }
    }
    return BulkInviteResult(
      ok: true,
      issuedCount: issued,
      errorCount: errors,
      results: List<BulkInviteRowResult>.unmodifiable(results),
    );
  }

  @override
  Future<InviteEmailDispatchResult> sendInviteEmails({
    required List<InviteEmailRecipient> recipients,
  }) async {
    _online();
    return InviteEmailDispatchResult(
      ok: true,
      configured: true,
      sentCount: recipients.length,
      failedCount: 0,
    );
  }

  @override
  Future<StaffInviteIssueResult> replaceInvite({
    required String inviteId,
    String? newEmail,
    int expiresInHours = 72,
    String? reason,
  }) async {
    _online();
    if (!_has(SetuStaffRole.minedSupervisor)) {
      throw const GatewayException('42501', 'forbidden_mined_required');
    }
    final _Invite old = _invites.values.firstWhere(
      (_Invite i) => i.id == inviteId,
    );
    final StaffInviteIssueResult fresh = await issueInvite(
      email: newEmail ?? old.email,
      role: old.role,
      institutionId: old.institutionId,
      staffTier: old.staffTier,
      scopeLabel: old.scopeLabel,
      fullName: old.fullName,
      supervisorUserId: old.supervisorUserId,
      expiresInHours: expiresInHours,
    );
    old
      ..state = 'revoked'
      ..revokedAt = DateTime.now().toUtc()
      ..revokedBy = _user
      ..revokedReason = reason ?? 'Reposición'
      ..replacedByInviteId = fresh.inviteId;
    return fresh;
  }

  @override
  Future<CounselorDispatchCasesResult> counselorDispatches() async {
    _scopes();
    final List<CaseDispatchRecord> pending = <CaseDispatchRecord>[];
    final List<DeclinedDispatchRecord> declined = <DeclinedDispatchRecord>[];
    for (final _DemoDispatch item in _dispatches) {
      if (item.counselor != _user) continue;
      final _DemoCase found = _cases.firstWhere(
        (_DemoCase c) => c.id == item.caseId,
      );
      if (item.status == CaseDispatchStatus.pending &&
          found.assignedTo == null &&
          found.status != SetuCaseStatus.closed) {
        pending.add(_record(item));
      } else if (item.status == CaseDispatchStatus.declined) {
        final bool covOk = item.tier == CaseDispatchTier.schoolPlant ||
            (_coverages[found.institutionId]?.activeNow ?? false);
        final DeclinedDispatchAvailability avail = found.assignedTo != null
            ? DeclinedDispatchAvailability.alreadyInCare
            : found.status == SetuCaseStatus.closed
            ? DeclinedDispatchAvailability.closed
            : !covOk
            ? DeclinedDispatchAvailability.coverageInactive
            : DeclinedDispatchAvailability.available;
        declined.add(
          DeclinedDispatchRecord(
            id: 'demo-dispatch-${item.caseId}-${item.counselor}',
            caseId: item.caseId,
            institutionId: found.institutionId,
            counselorUserId: item.counselor,
            dispatchTier: item.tier,
            dispatchStatus: item.status,
            notifiedAt: item.notifiedAt,
            canRecover: avail == DeclinedDispatchAvailability.available,
            availabilityState: avail,
            referenceCode: found.reference,
            institutionName: found.institutionId == cca.id
                ? cca.name
                : schoolA.name,
            situationType: found.situation,
            caseStatus: found.status,
            assignedCounselorId: found.assignedTo,
            respondedAt: item.respondedAt,
            declineReason: item.reason,
            declaredAt: found.declaredAt,
            involvesStaff: found.involvesStaff,
          ),
        );
      }
    }
    return CounselorDispatchCasesResult(
      pendingDispatches: pending,
      declinedDispatches: declined,
    );
  }

  @override
  Future<CaseDispatchRecoverResult> recoverDeclinedDispatch(
    String caseId,
  ) async {
    _scopes();
    final _DemoDispatch mine = _dispatches.firstWhere(
      (_DemoDispatch d) =>
          d.caseId == caseId &&
          d.counselor == _user &&
          d.status == CaseDispatchStatus.declined,
      orElse: () => throw const GatewayException('P0002', 'case_not_found'),
    );
    final _DemoCase found = _cases.firstWhere((_DemoCase c) => c.id == caseId);
    if (found.assignedTo != null) {
      return CaseDispatchRecoverResult(
        ok: false,
        caseId: caseId,
        error: 'already_in_care',
        availabilityState: DeclinedDispatchAvailability.alreadyInCare,
      );
    }
    mine
      ..status = CaseDispatchStatus.pending
      ..respondedAt = null;
    return CaseDispatchRecoverResult(
      ok: true,
      caseId: caseId,
      dispatchStatus: CaseDispatchStatus.pending,
      availabilityState: DeclinedDispatchAvailability.available,
    );
  }

  @override
  Future<SchoolCoverageAndAssignmentsView> schoolCoverageAndAssignments({
    String? institutionId,
  }) async {
    final List<StaffMembershipScope> scopes = _scopes();
    final bool mined = scopes.any(
      (StaffMembershipScope s) => s.role == SetuStaffRole.minedSupervisor,
    );
    final Set<String?> directed = <String?>{
      for (final StaffMembershipScope s in scopes)
        if (s.role == SetuStaffRole.schoolDirector) s.institutionId,
    };
    if (!mined && directed.isEmpty) {
      throw const GatewayException('42501', 'forbidden_coverage_viewer_required');
    }
    final List<SchoolCoverageStatusView> schools = <SchoolCoverageStatusView>[
      for (final _SchoolCoverage cov in _coverages.values)
        if ((mined || directed.contains(cov.institutionId)) &&
            (institutionId == null || cov.institutionId == institutionId))
          SchoolCoverageStatusView(
            institutionId: cov.institutionId,
            publicCode: cov.publicCode,
            name: cov.name,
            minedExternalEnabled: cov.minedExternalEnabled,
            externalSupportMode: cov.mode,
            externalSupportUntil: cov.until,
            coverageActiveNow: cov.activeNow,
            hasPlantCounselor: true,
            assignedExternalCount: _accounts.values
                .where((_Account a) =>
                    a.staffTier == 'external_network' &&
                    a.assignedInstitutionIds.contains(cov.institutionId))
                .length,
          ),
    ];
    final List<ExternalCounselorAssignmentView> extList = mined
        ? <ExternalCounselorAssignmentView>[
            for (final MapEntry<String, _Account> entry in _accounts.entries)
              if (entry.value.staffTier == 'external_network')
                ExternalCounselorAssignmentView(
                  userId: entry.key,
                  email: entry.key,
                  firstName: entry.value.firstName,
                  lastName: entry.value.lastName,
                  staffTier: entry.value.staffTier,
                  isAvailable: entry.value.isAvailable,
                  assignedInstitutionIds: List<String>.unmodifiable(
                    entry.value.assignedInstitutionIds,
                  ),
                ),
          ]
        : const <ExternalCounselorAssignmentView>[];
    return SchoolCoverageAndAssignmentsView(
      schools: schools,
      externalCounselors: extList,
    );
  }

  @override
  Future<void> setSchoolExternalCoverage({
    required String institutionId,
    ExternalCoverageMode? mode,
    DateTime? until,
    bool? minedExternalEnabled,
  }) async {
    _online();
    final bool mined = _has(SetuStaffRole.minedSupervisor);
    final bool director = _has(SetuStaffRole.schoolDirector, institutionId);
    if (!mined && !director) {
      throw const GatewayException('42501', 'forbidden_coverage_manager');
    }
    final _SchoolCoverage cov = _coverages[institutionId]!;
    if (mined && minedExternalEnabled != null) {
      cov.minedExternalEnabled = minedExternalEnabled;
    }
    if (!cov.minedExternalEnabled &&
        !mined &&
        mode != null &&
        mode != ExternalCoverageMode.disabled) {
      throw const GatewayException('42501', 'coverage_locked_by_mined');
    }
    if (mode != null) {
      cov
        ..mode = mode
        ..until = mode == ExternalCoverageMode.temporaryUntil ? until : null;
    }
  }

  @override
  Future<void> assignExternalCounselorSchool({
    required String counselorUserId,
    required String institutionId,
    bool active = true,
  }) async {
    _online();
    if (!_has(SetuStaffRole.minedSupervisor)) {
      throw const GatewayException('42501', 'forbidden_mined_required');
    }
    final _Account? counselor = _accounts[counselorUserId];
    if (counselor == null) return;
    if (active) {
      counselor.assignedInstitutionIds.add(institutionId);
    } else {
      counselor.assignedInstitutionIds.remove(institutionId);
    }
  }

  @override
  Future<List<PracticanteSupervisorNoticeView>> supervisorNotices() async {
    _scopes();
    return List<PracticanteSupervisorNoticeView>.unmodifiable(_supervisorNotices);
  }

  @override
  Future<List<StaffMembershipScope>> memberships() async {
    _online();
    final _Account? account = _accounts[_user];
    if (account == null) {
      throw const GatewayException('42501', 'authentication_required');
    }
    return List<StaffMembershipScope>.unmodifiable(account.memberships);
  }

  // --- Casos: imita las reglas de acceso del servidor -----------------------

  List<StaffMembershipScope> _scopes() {
    _online();
    final _Account? account = _accounts[_user];
    if (account == null) {
      throw const GatewayException('42501', 'authentication_required');
    }
    return account.memberships;
  }

  bool _has(SetuStaffRole role, [String? institutionId]) => _scopes().any(
    (StaffMembershipScope scope) =>
        scope.role == role &&
        (institutionId == null ||
            scope.institutionId == null ||
            scope.institutionId == institutionId),
  );

  /// Caso asignado a la sesión; error de permiso si no lo está.
  _DemoCase _assigned(String caseId) {
    _scopes();
    return _cases.firstWhere(
      (_DemoCase found) => found.id == caseId && found.assignedTo == _user,
      orElse: () => throw const GatewayException(
        '42501',
        'forbidden_assigned_counselor_required',
      ),
    );
  }

  _DemoCase? _assignedOrNull(String caseId) {
    _scopes();
    return _cases
        .where(
          (_DemoCase found) => found.id == caseId && found.assignedTo == _user,
        )
        .firstOrNull;
  }

  @override
  Future<Map<String, String>> institutionNames() async {
    _online();
    return <String, String>{cca.id: cca.name, schoolA.id: schoolA.name};
  }

  @override
  Future<List<StaffCaseSummary>> cases({String? institutionId}) async {
    final List<StaffMembershipScope> scopes = _scopes();
    final bool mined = scopes.any(
      (StaffMembershipScope scope) =>
          scope.role == SetuStaffRole.minedSupervisor,
    );
    final Set<String?> directed = <String?>{
      for (final StaffMembershipScope scope in scopes)
        if (scope.role == SetuStaffRole.schoolDirector) scope.institutionId,
    };
    final List<_DemoCase> visible =
        _cases
            .where(
              (_DemoCase found) =>
                  (mined ||
                      found.assignedTo == _user ||
                      (directed.contains(found.institutionId) &&
                          !found.involvesStaff)) &&
                  (institutionId == null ||
                      found.institutionId == institutionId),
            )
            .toList()
          ..sort(
            (_DemoCase a, _DemoCase b) => b.declaredAt.compareTo(a.declaredAt),
          );
    return <StaffCaseSummary>[
      for (final _DemoCase found in visible) found.summary,
    ];
  }

  @override
  Future<List<AssignableCounselor>> counselors({String? institutionId}) async {
    if (!_has(SetuStaffRole.minedSupervisor)) {
      throw const GatewayException(
        '42501',
        'forbidden_mined_supervisor_required',
      );
    }
    return <AssignableCounselor>[
      for (final MapEntry<String, _Account> entry in _accounts.entries)
        for (final StaffMembershipScope scope in entry.value.memberships)
          if (scope.role == SetuStaffRole.counselingDesk &&
              (institutionId == null || scope.institutionId == institutionId))
            AssignableCounselor(
              userId: entry.key,
              email: entry.key,
              institutionId: scope.institutionId,
            ),
    ];
  }

  @override
  Future<void> assignCounselor({
    required String operationId,
    required String caseId,
    required String counselorUserId,
  }) async {
    if (!_has(SetuStaffRole.minedSupervisor)) {
      throw const GatewayException(
        '42501',
        'forbidden_mined_supervisor_required',
      );
    }
    final _DemoCase found = _cases.firstWhere(
      (_DemoCase item) => item.id == caseId,
      orElse: () => throw const GatewayException('P0002', 'case_not_found'),
    );
    final bool authorized =
        _accounts[counselorUserId]?.memberships.any(
          (StaffMembershipScope scope) =>
              scope.role == SetuStaffRole.counselingDesk &&
              scope.institutionId == found.institutionId,
        ) ??
        false;
    if (!authorized) {
      throw const GatewayException(
        '42501',
        'counselor_not_authorized_for_institution',
      );
    }
    _applyAssignment(found, counselorUserId);
  }

  /// Simula que MINED asignó un caso mientras otra persona tiene la sesión
  /// abierta. Solo para pruebas y demostración.
  void simulateAssignment(String caseId, String counselorUserId) =>
      _applyAssignment(
        _cases.firstWhere((_DemoCase item) => item.id == caseId),
        counselorUserId,
      );

  void _applyAssignment(_DemoCase found, String counselorUserId) {
    final bool changed = found.assignedTo != counselorUserId;
    found
      ..assignedTo = counselorUserId
      ..version += 1;
    if (found.status == SetuCaseStatus.received) {
      found.status = SetuCaseStatus.inListening;
    }
    _settleDispatches(found, counselorUserId);
    if (changed) {
      _notices.add(
        SetuAssignmentNotice(
          caseId: found.id,
          referenceCode: found.reference,
          institutionId: found.institutionId,
          assignedCounselorId: counselorUserId,
        ),
      );
    }
  }

  @override
  Stream<SetuAssignmentNotice> assignmentNotices() {
    final String? user = _user;
    return _notices.stream.where(
      (SetuAssignmentNotice notice) => notice.assignedCounselorId == user,
    );
  }

  @override
  Future<CaseNarrativeView?> narrative(String caseId) async {
    final _DemoCase? found = _assignedOrNull(caseId);
    if (found == null || found.narrative.isEmpty) return null;
    return CaseNarrativeView(
      caseId: found.id,
      narrativeText: found.narrative,
      locationText: '',
      approxDateText: '',
      createdAt: found.declaredAt,
    );
  }

  @override
  Future<List<CaseChatMessageView>> messages(String caseId) async =>
      List<CaseChatMessageView>.of(
        _assignedOrNull(caseId)?.messages ?? const <CaseChatMessageView>[],
      );

  @override
  Stream<CaseChatMessageView> watchMessages(String caseId) => _liveMessages
      .stream
      .where((CaseChatMessageView message) => message.caseId == caseId);

  @override
  Future<List<CaseInternalNoteView>> notes(String caseId) async =>
      List<CaseInternalNoteView>.of(
        _assignedOrNull(caseId)?.notes.reversed ??
            const <CaseInternalNoteView>[],
      );

  @override
  Future<void> enableChat({
    required String operationId,
    required String caseId,
    String? openingMessage,
  }) async {
    final _DemoCase found = _assigned(caseId);
    if (found.status == SetuCaseStatus.closed) {
      throw const GatewayException('P0001', 'chat_not_available');
    }
    found
      ..chat = true
      ..version += 1;
    final String? clean = openingMessage?.trim();
    if (clean != null && clean.isNotEmpty) {
      final CaseChatMessageView message = CaseChatMessageView(
        id: 'demo-msg-${++_sequence}-$operationId-greeting',
        caseId: caseId,
        senderRole: SetuMessageSender.counselingDesk,
        body: clean,
        createdAt: DateTime.now(),
      );
      found.messages.add(message);
      _liveMessages.add(message);
    }
  }

  @override
  Future<void> sendMessage({
    required String operationId,
    required String caseId,
    required String body,
  }) async {
    final _DemoCase found = _assigned(caseId);
    if (!found.chat || found.status == SetuCaseStatus.closed) {
      throw const GatewayException('P0001', 'chat_not_available');
    }
    final CaseChatMessageView message = CaseChatMessageView(
      id: 'demo-msg-${++_sequence}-$operationId',
      caseId: caseId,
      senderRole: SetuMessageSender.counselingDesk,
      body: body.trim(),
      createdAt: DateTime.now(),
    );
    found.messages.add(message);
    _liveMessages.add(message);
  }

  @override
  Future<void> saveNote({
    required String operationId,
    required String caseId,
    required String body,
  }) async {
    _assigned(caseId).notes.add(
      CaseInternalNoteView(
        id: 'demo-note-${++_sequence}',
        caseId: caseId,
        authorUserId: _user,
        noteBody: body.trim(),
        clientOperationId: operationId,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> assess({
    required String operationId,
    required CaseAssessment assessment,
  }) async {
    final _DemoCase found = _assigned(assessment.caseId);
    final int level = assessment.level;
    if (level < 1 || level > 3) {
      throw const GatewayException('22023', 'invalid_human_level');
    }
    if (level == 1 && assessment.issueSheet) {
      throw const GatewayException(
        '22023',
        'level_1_cannot_issue_school_sheet',
      );
    }
    if (assessment.issueSheet && assessment.guidanceNotes.trim().isEmpty) {
      throw const GatewayException('22023', 'invalid_guidance_notes');
    }
    if (assessment.closeCase &&
        (level != 1 || assessment.closedReason.trim().isEmpty)) {
      throw const GatewayException('22023', 'closed_reason_required');
    }
    found
      ..level = level
      ..urgent = found.urgent || (level == 3 && assessment.urgentReferral)
      ..version += 1;
    if (assessment.closeCase) {
      found
        ..status = SetuCaseStatus.closed
        ..closedAt = DateTime.now()
        ..closedReason = assessment.closedReason.trim();
    } else if (assessment.issueSheet) {
      found.status = SetuCaseStatus.sheetSent;
      found.sheets.add(
        CaseActionSheetView(
          id: 'demo-sheet-${++_sequence}',
          caseId: found.id,
          institutionId: found.institutionId,
          version: found.sheets.length + 1,
          issuedBy: _user!,
          humanLevel: level,
          summaryType: found.situation,
          summaryRole: found.role,
          omitSchoolDueToConflict: assessment.omitSchool,
          guidanceNotes: assessment.guidanceNotes.trim(),
          issuedAt: DateTime.now(),
        ),
      );
    } else if (found.status == SetuCaseStatus.received) {
      found.status = SetuCaseStatus.inListening;
    }
    final _Account? actor = _accounts[_user];
    if (actor != null && actor.staffTier == 'practicante_5to') {
      _supervisorNotices.add(
        PracticanteSupervisorNoticeView(
          eventId: 'notice-${++_sequence}',
          caseId: found.id,
          referenceCode: found.reference,
          institutionName: found.institutionId == cca.id
              ? cca.name
              : schoolA.name,
          situationType: found.situation,
          humanLevel: level,
          practicanteName: '${actor.firstName ?? ''} ${actor.lastName ?? ''}'
              .trim(),
          reason: assessment.guidanceNotes.trim(),
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  // --- Dirección del centro ------------------------------------------------

  /// Caso del centro que dirige la sesión; error de permiso si no lo es.
  _DemoCase _directed(String caseId) {
    final _DemoCase found = _cases.firstWhere(
      (_DemoCase item) => item.id == caseId,
      orElse: () => throw const GatewayException('P0002', 'case_not_found'),
    );
    if (!_has(SetuStaffRole.schoolDirector, found.institutionId) ||
        !_scopes().any(
          (StaffMembershipScope scope) =>
              scope.role == SetuStaffRole.schoolDirector &&
              scope.institutionId == found.institutionId,
        )) {
      throw const GatewayException(
        '42501',
        'forbidden_school_director_required',
      );
    }
    if (found.involvesStaff) {
      throw const GatewayException('42501', 'restricted_due_to_staff_conflict');
    }
    return found;
  }

  @override
  Future<List<CaseActionSheetView>> sheets({String? caseId}) async {
    final List<StaffMembershipScope> scopes = _scopes();
    final bool mined = scopes.any(
      (StaffMembershipScope scope) =>
          scope.role == SetuStaffRole.minedSupervisor,
    );
    final Set<String?> directed = <String?>{
      for (final StaffMembershipScope scope in scopes)
        if (scope.role == SetuStaffRole.schoolDirector) scope.institutionId,
    };
    return <CaseActionSheetView>[
      for (final _DemoCase found in _cases)
        if (caseId == null || found.id == caseId)
          for (final CaseActionSheetView sheet in found.sheets.reversed)
            if (mined ||
                found.assignedTo == _user ||
                (directed.contains(found.institutionId) &&
                    !found.involvesStaff &&
                    !sheet.omitSchoolDueToConflict))
              sheet,
    ];
  }

  @override
  Future<List<SchoolActionRecordView>> schoolActions(String caseId) async {
    final List<StaffMembershipScope> scopes = _scopes();
    final _DemoCase? found = _cases
        .where((_DemoCase item) => item.id == caseId)
        .firstOrNull;
    if (found == null) return const <SchoolActionRecordView>[];
    final bool allowed = scopes.any(
      (StaffMembershipScope scope) =>
          scope.role == SetuStaffRole.minedSupervisor ||
          (scope.role == SetuStaffRole.schoolDirector &&
              scope.institutionId == found.institutionId &&
              !found.involvesStaff),
    );
    return allowed
        ? List<SchoolActionRecordView>.of(found.actions)
        : const <SchoolActionRecordView>[];
  }

  @override
  Future<void> recordSchoolAction({
    required String operationId,
    required SchoolActionDraft action,
  }) async {
    final _DemoCase found = _directed(action.caseId);
    final String notes = action.notes.trim();
    if (notes.isEmpty || notes.length > 1500) {
      throw const GatewayException('22023', 'invalid_action_notes');
    }
    if (found.actions.any(
      (SchoolActionRecordView saved) => saved.clientOperationId == operationId,
    )) {
      return;
    }
    if (found.version != action.expectedVersion) {
      throw const GatewayException('40001', 'concurrency_conflict');
    }
    final String? sheetId = action.actionSheetId;
    if (sheetId != null &&
        !found.sheets.any(
          (CaseActionSheetView sheet) =>
              sheet.id == sheetId && !sheet.omitSchoolDueToConflict,
        )) {
      throw const GatewayException('42501', 'action_sheet_not_authorized');
    }
    // En la demostración la identidad del estudiante siempre está reservada.
    if (action.step == SetuSchoolActionStep.notifyFamilyOrGroup &&
        !action.isGroupAction) {
      throw const GatewayException(
        '42501',
        'family_contact_blocked_while_identity_reserved',
      );
    }
    found.actions.add(
      SchoolActionRecordView(
        id: 'demo-action-${++_sequence}',
        caseId: found.id,
        institutionId: found.institutionId,
        actionSheetId: sheetId,
        step: action.step,
        isGroupAction: action.isGroupAction,
        actionNotes: notes,
        proposesClosure: action.proposesClosure,
        recordedBy: _user!,
        clientOperationId: operationId,
        createdAt: DateTime.now(),
      ),
    );
    found.version += 1;
    if (found.status == SetuCaseStatus.sheetSent) {
      found.status = SetuCaseStatus.schoolActing;
    }
  }

  @override
  bool get supportsTeacherNotice => true;

  @override
  Future<void> recordTeacherNotice({
    required String operationId,
    required String institutionId,
    required SetuSituationType situationType,
    required bool involvesStaff,
  }) async {
    final bool director = _scopes().any(
      (StaffMembershipScope scope) =>
          scope.role == SetuStaffRole.schoolDirector &&
          scope.institutionId == institutionId,
    );
    if (!director) {
      throw const GatewayException(
        '42501',
        'forbidden_school_director_required',
      );
    }
    if (_cases.any((_DemoCase item) => item.id == 'demo-$operationId')) return;
    _cases.add(
      _DemoCase(
        id: 'demo-$operationId',
        institutionId: institutionId,
        reference: 'DEMO-${100 + ++_sequence}',
        situation: situationType,
        // El aviso docente no tiene participación del estudiante; las
        // pantallas muestran «Aviso docente» en su lugar.
        role: SetuStudentCaseRole.solidarityWitness,
        declaredAt: DateTime.now(),
        narrative: '',
        piece: null,
        origin: SetuAlertOrigin.teacherNotice,
        involvesStaff: involvesStaff,
      ),
    );
  }
}
