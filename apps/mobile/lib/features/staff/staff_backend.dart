import 'package:flutter/foundation.dart';

import '../../shared/models/cureando_models.dart';
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
}

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
      _active = found.length == 1 ? found.single : null;
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
    notifyListeners();
  }

  Future<void> signOut() async {
    _memberships = const <StaffMembershipScope>[];
    _active = null;
    notifyListeners();
    try {
      await backend.signOut();
    } on Object {
      // La sesión local ya se cerró; el servidor vence la suya por su cuenta.
    }
  }
}
