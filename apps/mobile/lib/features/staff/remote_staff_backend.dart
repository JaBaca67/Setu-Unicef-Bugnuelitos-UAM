import '../../shared/remote/setu_remote_gateway.dart';
import '../../shared/remote/setu_remote_models.dart';
import 'staff_backend.dart';

/// Adaptador del puerto de personal hacia Supabase. No agrega reglas: cada
/// llamada la autoriza el servidor.
class RemoteStaffBackend implements StaffBackend {
  RemoteStaffBackend(this._gateway);

  final SetuRemoteGateway _gateway;

  @override
  bool get isDemo => false;

  @override
  String? get currentUserId => _gateway.currentStaffUserId;

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
      _gateway.signUpStaffAccount(email: email, password: password);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _gateway.signInStaffWithPassword(email: email, password: password);

  @override
  Future<void> signOut() => _gateway.signOutStaff();

  @override
  Future<StaffActivationRedemption> redeemActivation(String code) =>
      _gateway.redeemStaffActivationCode(code);

  @override
  Future<List<StaffMembershipScope>> memberships() =>
      _gateway.getMyStaffMemberships();
}
