import '../../shared/models/cureando_models.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'staff_backend.dart';

class _Invite {
  _Invite(this.email, this.role, {this.state = 'active'});
  final String email;
  final SetuStaffRole role;
  String state;
}

class _Account {
  _Account(this.password, {this.confirmed = false});
  final String password;
  bool confirmed;
  final List<StaffMembershipScope> memberships = <StaffMembershipScope>[];
}

/// DEMOSTRACIÓN: personal autorizado en memoria, con datos ficticios que no
/// salen del teléfono. Imita las respuestas del servidor para las pruebas de
/// widgets; no es un mecanismo de autenticación.
class DemoStaffBackend implements StaffBackend {
  DemoStaffBackend({this.autoConfirmEmail = false}) {
    _seed('mined.demo@setu.test', <StaffMembershipScope>[_mined]);
    _seed('escucha.demo@setu.test', <StaffMembershipScope>[
      _scope('m-desk-cca', SetuStaffRole.counselingDesk, cca),
      _scope('m-desk-a', SetuStaffRole.counselingDesk, schoolA),
    ]);
    _seed('direccion.cca@setu.test', <StaffMembershipScope>[
      _scope('m-dir-cca', SetuStaffRole.schoolDirector, cca),
    ]);
  }

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
  final Map<String, _Invite> _invites = <String, _Invite>{
    'CCADIR2026': _Invite(
      'invitada.cca@setu.test',
      SetuStaffRole.schoolDirector,
    ),
    'CCAMESA2026': _Invite(
      'practicante.cca@setu.test',
      SetuStaffRole.counselingDesk,
    ),
    'CCAEXP2026': _Invite(
      'expirada.cca@setu.test',
      SetuStaffRole.counselingDesk,
      state: 'expired',
    ),
    'CCAREV2026': _Invite(
      'revocada.cca@setu.test',
      SetuStaffRole.counselingDesk,
      state: 'revoked',
    ),
  };
  String? _user;

  /// Simula una caída de conexión en las pruebas.
  bool offline = false;

  void _seed(String email, List<StaffMembershipScope> memberships) {
    _accounts[email] = _Account(demoPassword, confirmed: true)
      ..memberships.addAll(memberships);
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
  Future<StaffActivationPreview> previewActivation(
    String code, {
    String? email,
  }) async {
    _online();
    final _Invite? invite = _invites[_normalize(code)];
    if (invite == null) {
      return const StaffActivationPreview(
        ok: false,
        error: 'invalid_activation_code',
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
    if (email != null && _clean(email) != invite.email) {
      return const StaffActivationPreview(
        ok: false,
        error: 'activation_email_mismatch',
        remainingAttempts: 4,
      );
    }
    return StaffActivationPreview(
      ok: true,
      role: invite.role,
      institutionId: cca.id,
      institutionPublicCode: cca.code,
      institutionName: cca.name,
      scopeLabel: '${invite.role.label} · ${cca.name}',
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

  @override
  Future<StaffActivationRedemption> redeemActivation(String code) async {
    _online();
    final _Account? account = _accounts[_user];
    if (account == null) {
      throw const GatewayException('42501', 'authentication_required');
    }
    final _Invite? invite = _invites[_normalize(code)];
    if (invite == null || invite.state != 'active') {
      return StaffActivationRedemption(
        ok: false,
        error: invite == null
            ? 'invalid_activation_code'
            : 'activation_code_already_used',
      );
    }
    if (invite.email != _user) {
      return const StaffActivationRedemption(
        ok: false,
        error: 'activation_email_mismatch',
      );
    }
    invite.state = 'used';
    final StaffMembershipScope scope = _scope(
      'm-${_normalize(code)}',
      invite.role,
      cca,
    );
    account.memberships.add(scope);
    return StaffActivationRedemption(
      ok: true,
      membershipId: scope.membershipId,
      role: scope.role,
      institutionId: scope.institutionId,
      scopeLabel: scope.scopeLabel,
    );
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
}
