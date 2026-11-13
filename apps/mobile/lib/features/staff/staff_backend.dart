import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/models/cureando_models.dart';
import '../../shared/remote/case_capability_crypto.dart';
import '../../shared/remote/setu_remote_models.dart';

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

  Future<StaffActivationPreview> previewActivation(
    String code, {
    String? email,
  });

  Future<void> signUp({required String email, required String password});

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<StaffActivationRedemption> redeemActivation(String code);

  Future<List<StaffMembershipScope>> memberships();

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

  // Mesa de Escucha: solo la persona asignada al caso.
  /// Avisos en vivo de casos recién asignados a la sesión actual.
  Stream<SetuAssignmentNotice> assignmentNotices();

  Future<CaseNarrativeView?> narrative(String caseId);

  Future<List<CaseChatMessageView>> messages(String caseId);

  Future<List<CaseInternalNoteView>> notes(String caseId);

  Future<void> enableChat({
    required String operationId,
    required String caseId,
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
      'Ese código fue anulado. Pedí uno nuevo a quien administra los accesos.',
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
class StaffSession extends ChangeNotifier {
  StaffSession(this.backend);

  final StaffBackend backend;

  List<StaffMembershipScope> _memberships = const <StaffMembershipScope>[];
  List<StaffMembershipScope> get memberships => _memberships;

  StaffMembershipScope? _active;

  /// Ámbito con el que la persona está trabajando; null si no hay sesión o
  /// falta elegir entre varios centros.
  StaffMembershipScope? get active => _active;

  bool get needsScopeChoice => _active == null && _memberships.length > 1;

  /// Ingresa y carga las membresías. Devuelve un texto de error o null.
  Future<String?> signIn(String email, String password) async {
    try {
      await backend.signIn(email: email.trim(), password: password);
      return await refresh();
    } on Object catch (error) {
      return staffErrorMessage(error);
    }
  }

  /// Vuelve a leer las membresías que el servidor reconoce para la sesión.
  Future<String?> refresh() async {
    try {
      final List<StaffMembershipScope> found = await backend.memberships();
      _memberships = found;
      final String? keep = _active?.membershipId;
      _active = found.length == 1
          ? found.single
          : found
                .where(
                  (StaffMembershipScope scope) => scope.membershipId == keep,
                )
                .firstOrNull;
      _watchAssignments();
      notifyListeners();
      if (found.isEmpty) {
        return 'Tu cuenta todavía no tiene un acceso activo. Si es tu primer '
            'ingreso, activá tu cuenta con el código que te entregaron.';
      }
      return null;
    } on Object catch (error) {
      return staffErrorMessage(error);
    }
  }

  void choose(StaffMembershipScope scope) {
    if (!_memberships.contains(scope)) return;
    _active = scope;
    _watchAssignments();
    notifyListeners();
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
    _notices?.cancel();
    super.dispose();
  }

  Future<void> signOut() async {
    _memberships = const <StaffMembershipScope>[];
    _active = null;
    _watchAssignments();
    notifyListeners();
    try {
      await backend.signOut();
    } on Object {
      // La sesión local ya se cerró; el servidor vence la suya por su cuenta.
    }
  }
}
