import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'features/staff/demo_staff_backend.dart';
import 'features/staff/remote_staff_backend.dart';
import 'features/staff/staff_backend.dart';
import 'features/school_access/student_session.dart';
import 'features/support/remote_support_backend.dart';
import 'features/support/support_flow.dart';
import 'shared/mesh/mesh_bridge_keys.dart';
import 'shared/mesh/mesh_relay_service.dart';
import 'shared/mesh/mesh_transport.dart';
import 'shared/remote/push_notification_service.dart';
import 'shared/remote/setu_remote_gateway.dart';
import 'shared/remote/setu_remote_models.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app se usa solo en vertical; el manifiesto de Android fija lo mismo.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(CureandoTheme.statusBarOverlayLight);
  // Si el cliente remoto no puede prepararse, la app abre con la demostración
  // en memoria, que se identifica en pantalla como datos ficticios.
  SetuRemoteGateway? remoteGateway;
  StaffBackend? staff;
  StudentSession? session;
  try {
    final SetuRemoteGateway gateway =
        await SupabaseSetuRemoteGateway.initialize();
    remoteGateway = gateway;
    await PushNotificationService.instance.initialize(gateway: gateway);
    staff = RemoteStaffBackend(gateway);
    // El código del colegio se valida en la plataforma; sin red, la sesión
    // usa su catálogo local de respaldo.
    session = StudentSession(
      resolver: (String code) async {
        final PublicSchoolResolution? found = await gateway.resolvePublicSchool(
          code,
        );
        return found == null
            ? null
            : ConfirmedSchool(
                id: found.id,
                publicCode: found.publicCode,
                name: found.name,
                municipality: found.municipality,
                department: found.department,
                referenceLat: found.referenceLat,
                referenceLng: found.referenceLng,
                radiusMeters: found.radiusMeters,
              );
      },
    );
  } on Object catch (error) {
    debugPrint(
      'SéTú: cliente remoto no disponible (${error.runtimeType}); usando modo demostración.',
    );
    remoteGateway = null;
    staff = null;
    session = null;
  }
  final MeshRelayService meshRelay = MeshRelayService(
    transport: NearbyMeshTransport(),
    remoteGateway: remoteGateway,
  );
  final StudentSession resolvedSession = session ?? StudentSession();
  final SupportFlow resolvedSupport = SupportFlow(
    backend: remoteGateway == null ? null : RemoteSupportBackend(remoteGateway),
    schoolCode: const String.fromEnvironment(
      'SETU_SCHOOL_CODE',
      defaultValue: 'AULA24',
    ),
    mesh: meshRelay,
    resolveMeshRecipientPublicKey: MeshBridgeKeys.resolvePublicKeyBytes,
  );
  final StaffSession resolvedStaffSession = StaffSession(
    staff ?? DemoStaffBackend(),
  );
  // Restauramos las sesiones guardadas antes de montar las rutas para abrir
  // directamente en la superficie activa sin pasar por la bienvenida o login.
  await Future.wait(<Future<void>>[
    resolvedSession.open(),
    resolvedSupport.open(),
    resolvedStaffSession.restore(),
    meshRelay.open(),
  ]);
  runApp(
    CureandoApp(
      remoteGateway: remoteGateway,
      meshRelay: meshRelay,
      staffBackend: staff,
      staffSession: resolvedStaffSession,
      supportFlow: resolvedSupport,
      studentSession: resolvedSession,
      showM1Verification: kDebugMode && bool.fromEnvironment('SETU_M1_QA'),
      allowDesignCapture:
          kDebugMode &&
          bool.fromEnvironment('SETU_DESIGN_CAPTURE', defaultValue: true),
      allowSchoolSimulation:
          kDebugMode &&
          bool.fromEnvironment('SETU_DEMO_SIMULATION', defaultValue: true),
    ),
  );
}
