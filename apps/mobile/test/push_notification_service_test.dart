import 'package:cureando_mobile/shared/remote/push_notification_service.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePushGateway implements SetuRemoteGateway {
  String? staffUserId;
  final List<String> registeredStaff = <String>[];
  final List<String> unregisteredStaff = <String>[];
  final List<String> registeredStudents = <String>[];

  @override
  String? get currentStaffUserId => staffUserId;

  @override
  Future<void> registerStaffPushToken({
    required String fcmToken,
    String platform = 'android',
  }) async {
    registeredStaff.add('$staffUserId:$fcmToken:$platform');
  }

  @override
  Future<void> unregisterStaffPushToken({required String fcmToken}) async {
    unregisteredStaff.add('$staffUserId:$fcmToken');
  }

  @override
  Future<void> registerStudentPushToken({
    required String caseId,
    required String capabilityToken,
    required String fcmToken,
    String platform = 'android',
  }) async {
    registeredStudents.add('$caseId:$capabilityToken:$fcmToken:$platform');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('syncStaff obtiene token, evita duplicados, renueva y da de baja', () async {
    final _FakePushGateway gateway = _FakePushGateway();
    String? activeToken = 'fcm_token_inicial_ficticio_1234567890';
    final PushNotificationService service = PushNotificationService.forTesting(
      gateway: gateway,
      fetchToken: () async => activeToken,
    );

    // Sin sesión activa no registra token.
    await service.syncStaff(hasActiveSession: false);
    expect(gateway.registeredStaff, isEmpty);

    // Con sesión activa registra una sola vez por par usuario+token.
    gateway.staffUserId = 'user-psicologo-1';
    await service.syncStaff(hasActiveSession: true);
    await service.syncStaff(hasActiveSession: true);
    expect(gateway.registeredStaff, <String>[
      'user-psicologo-1:fcm_token_inicial_ficticio_1234567890:android',
    ]);

    // Al rotar token limpia caché y vuelve a registrar.
    int tokenNotifications = 0;
    service.setListeners(onTokenChanged: () => tokenNotifications += 1);
    activeToken = 'fcm_token_rotado_ficticio_9876543210';
    service.handleTokenRefresh(activeToken);
    expect(tokenNotifications, 1);
    await service.syncStaff(hasActiveSession: true);
    expect(gateway.registeredStaff, hasLength(2));

    // Al cerrar sesión da de baja con el usuario todavía autenticado.
    await service.unregisterStaff();
    expect(gateway.unregisteredStaff, <String>[
      'user-psicologo-1:fcm_token_rotado_ficticio_9876543210',
    ]);
  });

  test('syncStudentCase reintenta si el token llega después y limpia al cerrar', () async {
    final _FakePushGateway gateway = _FakePushGateway();
    String? activeToken;
    final PushNotificationService service = PushNotificationService.forTesting(
      gateway: gateway,
      fetchToken: () async => activeToken,
    );

    // Primer intento cuando aún no hay token disponible: no cachea ni falla.
    await service.syncStudentCase(
      caseId: 'case-1',
      capabilityToken: 'cap-secret-1',
      active: true,
    );
    expect(gateway.registeredStudents, isEmpty);

    // Al reintentar cuando ya existe token FCM, sí sincroniza.
    activeToken = 'fcm_token_estudiante_ficticio_123456';
    await service.syncStudentCase(
      caseId: 'case-1',
      capabilityToken: 'cap-secret-1',
      active: true,
    );
    await service.syncStudentCase(
      caseId: 'case-1',
      capabilityToken: 'cap-secret-1',
      active: true,
    );
    expect(gateway.registeredStudents, <String>[
      'case-1:cap-secret-1:fcm_token_estudiante_ficticio_123456:android',
    ]);

    // Al desactivar y reactivar el mismo caso vuelve a sincronizar.
    await service.syncStudentCase(
      caseId: null,
      capabilityToken: null,
      active: false,
    );
    await service.syncStudentCase(
      caseId: 'case-1',
      capabilityToken: 'cap-secret-1',
      active: true,
    );
    expect(gateway.registeredStudents, hasLength(2));
  });
}
