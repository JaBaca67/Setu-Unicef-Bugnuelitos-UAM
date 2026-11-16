import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/local/encrypted_local_store.dart';
import '../../shared/models/cureando_models.dart';
import '../../shared/remote/case_capability_crypto.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'demo_staff_backend.dart';

/// Puerto de la interfaz de personal autorizado. Las pantallas solo conocen
/// este contrato: en pruebas se usa la implementación en memoria y en el
/// teléfono el adaptador que delega en `SetuRemoteGateway`.
///
/// La autorización real vive en el servidor (RLS y RPC). Este puerto no
/// concede permisos: solo transporta lo que el servidor ya autorizó.
abstract interface class StaffBackend {
  /// Verdadero cuando los datos son ficticios y no salen del teléfono.
  bool get isDemo;

  String? get currentUserId;

  String? get currentUserEmail;

  bool get isEmailConfirmed;

  Stream<void> authStateChanges();

  Future<StaffActivationPreview> previewActivation(
    String code, {
    String? email,
  });

  Future<void> signUp({required String email, required String password});

  Future<void> resendConfirmationEmail({required String email});

  Future<void> refreshAuthSession();

  Future<void> sendPasswordReset({required String email});

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<StaffActivationRedemption> redeemActivation(String code);

  Future<StaffActivationRedemption> redeemActivationWithProfile({
    required String code,
    required String firstName,
    required String lastName,
  });

  Future<List<StaffMembershipScope>> memberships();

  Future<StaffProfileView?> profile();

  Future<void> updateAvailabilityAndNotices({
    required bool isAvailable,
    required bool notifyNewAlerts,
    required bool notifyNewMessages,
  });

  Future<void> requestInviteReplacement({
    required String email,
    required String reasonCode,
    String? notes,
  });

  Future<List<StaffActivationInviteView>> invites({String? institutionId});

  Future<void> requestInvite({
    required String email,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? fullName,
    String? requesterProgramLabel,
    String? supervisorUserId,
  });

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
  });

  Future<void> revokeInvite({required String inviteId, String? reason});

  Future<StaffInviteIssueResult> replaceInvite({
    required String inviteId,
    String? newEmail,
    int expiresInHours = 72,
    String? reason,
  });

  Future<void> submitAccessRequest({
    required String fullName,
    required String email,
    required SetuStaffRole role,
    String? institutionId,
    String staffTier = 'school_plant',
    String? requesterProgramLabel,
  });

  Future<BulkInviteResult> issueInvitesBulk({
    required List<BulkInviteRowDraft> rows,
    int expiresInHours = 72,
  });

  Future<InviteEmailDispatchResult> sendInviteEmails({
    required List<InviteEmailRecipient> recipients,
  });

  Future<CounselorDispatchCasesResult> counselorDispatches();

  Future<CaseDispatchRecoverResult> recoverDeclinedDispatch(String caseId);

  Future<SchoolCoverageAndAssignmentsView> schoolCoverageAndAssignments({
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

  Future<List<PracticanteSupervisorNoticeView>> supervisorNotices();

  /// Nombres de los centros activos, por identificador.
  Future<Map<String, String>> institutionNames();

  /// Casos que el servidor autoriza para la sesión. Nunca traen relato ni
  /// mensajes.
  Future<List<StaffCaseSummary>> cases({String? institutionId});

  // Supervisión MINED
  Future<List<AssignableCounselor>> counselors({String? institutionId});

  Future<void> assignCounselor({
    required String operationId,
    required String caseId,
    required String counselorUserId,
  });

  // Despacho a Mesa de Escucha: la alerta se ofrece a varias personas y la
  // atiende la primera que la toma.
  /// Toma una alerta despachada. Si otra persona la tomó antes, el resultado
  /// lo indica (`isAlreadyTaken`) sin lanzar error.
  Future<CaseClaimResult> claimCase({
    required String operationId,
    required String caseId,
  });

  /// Declina una alerta despachada; el servidor puede derivarla a la red
  /// externa.
  Future<CaseDeclineResult> declineDispatch({
    required String operationId,
    required String caseId,
    String? reason,
  });

  /// Historial de despachos: completo para MINED y solo los propios para
  /// Mesa de Escucha. Nunca trae relato ni mensajes.
  Future<List<CaseDispatchRecord>> dispatchHistory({
    String? institutionId,
    String? caseId,
  });

  /// Cambios en vivo de los despachos de la sesión actual.
  Stream<CaseDispatchRecord> incomingDispatches();

  // Mesa de Escucha: solo la persona asignada al caso.
  /// Avisos en vivo de casos recién asignados a la sesión actual.
  Stream<SetuAssignmentNotice> assignmentNotices();

  Future<CaseNarrativeView?> narrative(String caseId);

  Future<List<CaseChatMessageView>> messages(String caseId);

  /// Mensajes nuevos en vivo para la conversación abierta.
  Stream<CaseChatMessageView> watchMessages(String caseId);

  Future<List<CaseInternalNoteView>> notes(String caseId);

  Future<void> enableChat({
    required String operationId,
    required String caseId,
    String? openingMessage,
  });

  Future<void> sendMessage({
    required String operationId,
    required String caseId,
    required String body,
  });

  Future<void> saveNote({
    required String operationId,
    required String caseId,
    required String body,
  });

  Future<void> assess({
    required String operationId,
    required CaseAssessment assessment,
  });

  // Dirección del centro: avisos mínimos, fichas autorizadas y actuaciones.
  /// Fichas que el servidor autoriza para la sesión; nunca traen relato.
  Future<List<CaseActionSheetView>> sheets({String? caseId});

  Future<List<SchoolActionRecordView>> schoolActions(String caseId);

  Future<void> recordSchoolAction({
    required String operationId,
    required SchoolActionDraft action,
  });

  /// Falso mientras el registro de aviso docente no esté conectado.
  bool get supportsTeacherNotice;

  Future<void> recordTeacherNotice({
    required String operationId,
    required String institutionId,
    required SetuSituationType situationType,
    required bool involvesStaff,
  });
}

/// Actuación escolar por registrar. No lleva nombres ni relato.
@immutable
class SchoolActionDraft {
  const SchoolActionDraft({
    required this.caseId,
    required this.step,
    required this.notes,
    required this.expectedVersion,
    this.actionSheetId,
    this.isGroupAction = false,
    this.proposesClosure = false,
  });

  final String caseId;
  final String? actionSheetId;
  final SetuSchoolActionStep step;
  final bool isGroupAction;
  final String notes;
  final bool proposesClosure;

  /// Versión del caso que la persona estaba viendo; evita pisar cambios.
  final int expectedVersion;

  String get fingerprint =>
      '$caseId|$actionSheetId|${step.wireValue}|$isGroupAction|$notes|'
      '$proposesClosure|$expectedVersion';
}

/// Valoración humana de un caso. El nivel lo decide la persona profesional,
/// nunca la app.
@immutable
class CaseAssessment {
  const CaseAssessment({
    required this.caseId,
    required this.level,
    this.urgentReferral = false,
    this.issueSheet = false,
    this.guidanceNotes = '',
    this.omitSchool = false,
    this.closeCase = false,
    this.closedReason = '',
  });

  final String caseId;
  final int level;
  final bool urgentReferral;
  final bool issueSheet;
  final String guidanceNotes;
  final bool omitSchool;
  final bool closeCase;
  final String closedReason;

  /// Huella del contenido, para reutilizar la operación si se reintenta.
  String get fingerprint =>
      '$caseId|$level|$urgentReferral|$issueSheet|$guidanceNotes|$omitSchool|'
      '$closeCase|$closedReason';
}

/// Conserva el identificador de operación mientras se reintenta el mismo
/// contenido, para que un reintento no duplique la acción en el servidor.
class OperationIds {
  String? _key;
  String? _id;

  String idFor(String key) {
    if (_key != key || _id == null) {
      _key = key;
      _id = CaseCapabilityCrypto.generateClientOperationId(prefix: 'staff');
    }
    return _id!;
  }

  void done() => _key = _id = null;
}

/// Niveles de la valoración profesional, con texto además del número.
const Map<int, String> humanLevelLabels = <int, String>{
  1: 'Acompañamiento',
  2: 'Convivencia',
  3: 'Riesgo grave',
};

extension StaffRolePath on SetuStaffRole {
  /// Ruta de la superficie móvil de cada rol.
  String get path => switch (this) {
    SetuStaffRole.minedSupervisor => '/personal/mined',
    SetuStaffRole.counselingDesk => '/personal/mesa',
    SetuStaffRole.schoolDirector => '/personal/direccion',
  };
}

/// Nombre corto del nivel de despacho.
String dispatchTierLabel(CaseDispatchTier tier) => switch (tier) {
  CaseDispatchTier.schoolPlant => 'Equipo de planta',
  CaseDispatchTier.externalPool => 'Red externa',
};

extension StaffScopeText on StaffMembershipScope {
  /// Centro o ámbito que se muestra a la persona.
  String get place => institutionName ?? scopeLabel;
}

/// Texto para la persona a partir de un error del servidor. Nunca incluye
/// códigos, correos, contraseñas ni datos de casos.
String staffErrorMessage(Object error) {
  final String code = error is GatewayException
      ? '${error.code} ${error.message}'.toLowerCase()
      : error.toString().toLowerCase();
  bool has(String part) => code.contains(part);
  if (has('invalid_credentials') || has('invalid login')) {
    return 'El correo o la contraseña no coinciden.';
  }
  if (has('email_not_confirmed') || has('email_not_verified')) {
    return 'Todavía no vemos tu correo confirmado. Abrí el enlace que te '
        'enviamos e intentá de nuevo.';
  }
  if (has('weak_password')) {
    return 'Esa contraseña es fácil de adivinar. Probá con otra más larga.';
  }
  if (has('user_already_exists') || has('already registered')) {
    return 'Ese correo ya tiene una cuenta. Ingresá con tu contraseña.';
  }
  if (has('rate_limit')) {
    return 'Hubo demasiados intentos. Esperá unos minutos antes de probar '
        'otra vez.';
  }
  if (has('concurrency_conflict')) {
    return 'Otra persona actualizó este caso. Volvé a abrirlo antes de '
        'continuar.';
  }
  if (has('chat_not_available')) {
    return 'El chat de este caso todavía no está habilitado.';
  }
  if (has('requires_external_counselor')) {
    return 'Esta alerta involucra a personal del centro: la atiende la red '
        'externa de Mesa de Escucha.';
  }
  if (has('invalid_decline_reason')) {
    return 'El motivo es demasiado largo. Acortalo e intentá de nuevo.';
  }
  if (has('invite_email_mismatch')) {
    return 'Ese código pertenece a otro correo institucional.';
  }
  if (has('coverage_inactive') || has('coverage_locked_by_mined')) {
    return 'La cobertura de Red externa para ese centro está pausada o venció.';
  }
  if (has('supervisor_required') || has('invalid_supervisor_for_practicante')) {
    return 'Un practicante de 5.º año requiere un psicólogo de planta activo como tutor.';
  }
  if (has('forbidden_mined_self_request')) {
    return 'Las cuentas de supervisión MINED solo se asignan por invitación directa.';
  }
  if (has('duplicate_pending_staff_request')) {
    return 'Ya existe una solicitud pendiente o invitación vigente para ese correo.';
  }
  if (has('invalid_full_name')) {
    return 'Escribí tu nombre completo (mínimo 3 caracteres).';
  }
  if (has('institution_required_for_role')) {
    return 'Elegí el colegio al que pertenecés para ese rol.';
  }
  if (has('invalid_institutional_email') || has('fake_test_email_not_allowed')) {
    return 'Escribí un correo electrónico real válido.';
  }
  if (has('invalid_bulk_rows_count')) {
    return 'El archivo debe tener entre 1 y 200 filas para importar.';
  }
  if (has('first_and_last_name_required') || has('name_required')) {
    return 'Completá tu nombre y apellidos para activar la cuenta.';
  }
  if (has('case_not_found')) {
    return 'Ese caso no está disponible para tu cuenta.';
  }
  if (has('counselor_not_authorized')) {
    return 'Esa persona no está habilitada para atender casos de ese centro.';
  }
  if (has('family_contact_blocked')) {
    return 'Mientras la identidad del estudiante esté reservada, este paso '
        'solo puede registrarse como acción grupal.';
  }
  if (has('restricted_due_to_staff_conflict') ||
      has('action_sheet_not_authorized')) {
    return 'Este caso lo sigue la supervisión del MINED. La dirección no '
        'puede registrar actuaciones en él.';
  }
  if (has('teacher_notice_not_connected')) {
    return 'El registro de aviso docente todavía no está conectado al '
        'servidor.';
  }
  if (has('membership_revoked') || has('forbidden') || has('42501')) {
    return 'Tu cuenta no tiene permiso para esta acción.';
  }
  if (has('authentication_required')) {
    return 'Tu sesión terminó. Ingresá de nuevo.';
  }
  return 'No pudimos completar la acción. Revisá tu conexión a internet e '
      'intentá de nuevo.';
}

/// Texto para los resultados `ok = false` de la activación.
String activationErrorMessage(String? error, {int? remainingAttempts}) {
  final String attempts = remainingAttempts == null
      ? ''
      : remainingAttempts == 1
      ? ' Te queda 1 intento.'
      : ' Te quedan $remainingAttempts intentos.';
  return switch (error) {
    'activation_code_expired' =>
      'Ese código ya venció. Pedí uno nuevo a quien administra los accesos.',
    'activation_code_revoked' =>
      'Ese código fue revocado. Pedí uno nuevo a quien administra los accesos.',
    'activation_code_already_used' =>
      'Ese código ya se usó. Si ya activaste tu cuenta, ingresá con tu '
          'correo y contraseña.',
    'activation_rate_limited' =>
      'Hubo demasiados intentos. Esperá unos minutos antes de probar otra '
          'vez.',
    'activation_email_mismatch' =>
      'Ese código fue entregado para otro correo institucional.$attempts',
    _ => 'No reconocemos ese código. Revisalo e intentá de nuevo.$attempts',
  };
}

/// Sesión del personal autorizado: membresías activas y ámbito elegido.
///
/// Guarda cifrado en el teléfono únicamente la sesión activa y el ámbito
/// elegido (nunca contraseñas ni códigos privados) para no volver al ingreso
/// al reabrir la app.
class StaffSession extends ChangeNotifier {
  StaffSession(
    this.backend, {
    Future<LocalStorePersistence> Function()? openStore,
  }) : _openStore = openStore ?? _onDevice;

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_staff_session.enc',
        keyName: 'setu.staff.session.v1',
      );

  final StaffBackend backend;
  final Future<LocalStorePersistence> Function() _openStore;

  LocalStorePersistence? _store;
  Future<void>? _restoring;
  bool _opened = false;
  bool _touched = false;
  bool _disposed = false;
  String? _savedActiveMembershipId;

  List<StaffMembershipScope> _memberships = const <StaffMembershipScope>[];
  List<StaffMembershipScope> get memberships => _memberships;

  StaffMembershipScope? _active;
  StaffProfileView? _profile;

  String pendingFirstName = '';
  String pendingLastName = '';
  String pendingStaffTier = 'school_director';
  String? pendingInstitutionId;
  String pendingEmail = '';
  String pendingPassword = '';

  void clearPendingRegistration() {
    pendingFirstName = '';
    pendingLastName = '';
    pendingStaffTier = 'school_director';
    pendingInstitutionId = null;
    pendingEmail = '';
    pendingPassword = '';
  }

  /// Ámbito con el que la persona está trabajando; null si no hay sesión o
  /// falta elegir entre varios centros.
  StaffMembershipScope? get active => _active;

  StaffProfileView? get profile => _profile;

  bool get isAuthenticated => backend.currentUserId != null;

  bool get isEmailConfirmed => backend.isEmailConfirmed;

  String? get currentUserEmail => backend.currentUserEmail;

  bool get needsScopeChoice => _active == null && _memberships.length > 1;

  /// Ingresa y carga las membresías. Devuelve un texto de error o null.
  Future<String?> signIn(String email, String password) async {
    _touched = true;
    try {
      await backend.signIn(email: email.trim(), password: password);
      return await refresh();
    } on Object catch (error) {
      return staffErrorMessage(error);
    }
  }

  /// Al abrir la app: restaura la sesión y el centro guardados y, si hay
  /// usuario autenticado, verifica sus membresías sin pedir contraseña.
  Future<void> restore() =>
      _opened ? Future<void>.value() : _restoring ??= _load();

  Future<void> _load() async {
    try {
      final LocalStorePersistence store =
          await Future<LocalStorePersistence>.sync(_openStore);
      _store = store;
      final Map<String, Object?>? data = await store.load();
      if (!_touched && data != null && data['version'] == 1) {
        final String? savedUserId = data['userId'] as String?;
        final String? savedActiveId = data['activeMembershipId'] as String?;
        final List<StaffMembershipScope> savedMemberships = _parseMemberships(
          data['memberships'],
        );
        final StaffBackend currentBackend = backend;
        if (currentBackend.currentUserId == null &&
            savedUserId != null &&
            currentBackend is DemoStaffBackend) {
          currentBackend.restoreUser(savedUserId);
        }
        if (currentBackend.currentUserId != null &&
            savedUserId == currentBackend.currentUserId) {
          _savedActiveMembershipId = savedActiveId;
          if (savedMemberships.isNotEmpty) {
            _memberships = List<StaffMembershipScope>.unmodifiable(
              savedMemberships,
            );
            _active = _resolveActive(savedMemberships, savedActiveId);
            _watchAssignments();
            if (!_disposed) notifyListeners();
          }
        }
      }
    } on Object {
      // Sin almacén la sesión vive solo mientras la app está abierta.
    } finally {
      _opened = true;
      _restoring = null;
    }
    if (_disposed) return;
    if (_touched) {
      _save();
      return;
    }
    if (backend.currentUserId != null) {
      await refresh(preserveOnTransientError: _memberships.isNotEmpty);
    }
  }

  /// Vuelve a leer las membresías que el servidor reconoce para la sesión.
  Future<String?> refresh({bool preserveOnTransientError = false}) async {
    _touched = true;
    try {
      final List<StaffMembershipScope> found = await backend.memberships();
      final String? keep = _active?.membershipId ?? _savedActiveMembershipId;
      _memberships = found;
      _active = _resolveActive(found, keep);
      _savedActiveMembershipId = _active?.membershipId;
      if (found.isNotEmpty) {
        try {
          _profile = await backend.profile();
        } on Object {
          // Si el perfil opcional no responde en una llamada puntual, las
          // membresías válidas siguen activas.
        }
      } else {
        _profile = null;
      }
      _save();
      _watchAssignments();
      if (!_disposed) notifyListeners();
      if (found.isEmpty) {
        return 'Tu cuenta todavía no tiene un acceso activo. Si es tu primer '
            'ingreso, activá tu cuenta con el código que te entregaron.';
      }
      return null;
    } on Object catch (error) {
      if (preserveOnTransientError && _isAuthOrRevokedError(error)) {
        _memberships = const <StaffMembershipScope>[];
        _active = null;
        _savedActiveMembershipId = null;
        _save();
        _watchAssignments();
        if (!_disposed) notifyListeners();
      }
      return staffErrorMessage(error);
    }
  }

  void choose(StaffMembershipScope scope) {
    if (!_memberships.contains(scope)) return;
    _touched = true;
    _active = scope;
    _savedActiveMembershipId = scope.membershipId;
    _save();
    _watchAssignments();
    if (!_disposed) notifyListeners();
  }

  static List<StaffMembershipScope> _parseMemberships(Object? raw) {
    if (raw is! List<Object?>) return const <StaffMembershipScope>[];
    final List<StaffMembershipScope> parsed = <StaffMembershipScope>[];
    for (final Object? entry in raw) {
      if (entry is Map<Object?, Object?>) {
        try {
          parsed.add(
            StaffMembershipScope.fromJson(entry.cast<String, Object?>()),
          );
        } on Object {
          // Ignorar entradas dañadas al restaurar.
        }
      }
    }
    return parsed;
  }

  static StaffMembershipScope? _resolveActive(
    List<StaffMembershipScope> found,
    String? keep,
  ) => found.length == 1
      ? found.single
      : found
            .where((StaffMembershipScope scope) => scope.membershipId == keep)
            .firstOrNull;

  static bool _isAuthOrRevokedError(Object error) {
    final String code = error is GatewayException
        ? '${error.code} ${error.message}'.toLowerCase()
        : error.toString().toLowerCase();
    return code.contains('authentication_required') ||
        code.contains('membership_revoked') ||
        code.contains('forbidden') ||
        code.contains('42501') ||
        code.contains('jwt') ||
        code.contains('session_not_found');
  }

  Future<void> _save() async {
    try {
      await _store?.save(<String, Object?>{
        'version': 1,
        'userId': _memberships.isEmpty ? null : backend.currentUserId,
        'activeMembershipId': _active?.membershipId,
        'memberships': <Map<String, Object?>>[
          for (final StaffMembershipScope scope in _memberships) scope.toJson(),
        ],
      });
    } on Object {
      // Sin almacén disponible, la sesión sigue activa en memoria.
    }
  }

  StreamSubscription<SetuAssignmentNotice>? _notices;
  bool _assignmentPending = false;

  /// Verdadero cuando llegó una asignación que la persona todavía no abrió.
  /// El aviso no lleva datos del caso.
  bool get assignmentPending => _assignmentPending;

  void clearAssignment() {
    if (!_assignmentPending) return;
    _assignmentPending = false;
    notifyListeners();
  }

  void _watchAssignments() {
    _notices?.cancel();
    _notices = null;
    if (_active?.role != SetuStaffRole.counselingDesk) {
      _assignmentPending = false;
      return;
    }
    _notices = backend.assignmentNotices().listen((_) {
      _assignmentPending = true;
      notifyListeners();
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _disposed = true;
    _notices?.cancel();
    super.dispose();
  }

  Future<String?> refreshAuthAndMemberships() async {
    try {
      await backend.refreshAuthSession();
    } on Object catch (error) {
      return staffErrorMessage(error);
    }
    return refresh();
  }

  Future<void> reloadProfile() async {
    if (backend.currentUserId == null) return;
    try {
      _profile = await backend.profile();
      if (!_disposed) notifyListeners();
    } on Object {
      // Mantiene el perfil en caché si falla la recarga puntual.
    }
  }

  Future<void> signOut() async {
    _touched = true;
    _memberships = const <StaffMembershipScope>[];
    _active = null;
    _profile = null;
    _savedActiveMembershipId = null;
    try {
      await backend.signOut();
    } on Object {
      // La sesión local ya se cerró; el servidor vence la suya por su cuenta.
    }
    await _save();
    _watchAssignments();
    if (!_disposed) notifyListeners();
  }
}
