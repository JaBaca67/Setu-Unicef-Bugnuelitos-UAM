import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/staff/remote_staff_backend.dart';
import 'features/staff/staff_backend.dart';
import 'features/school_access/student_session.dart';
import 'features/support/remote_support_backend.dart';
import 'features/support/support_flow.dart';
import 'shared/remote/setu_remote_gateway.dart';
import 'shared/remote/setu_remote_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Si el cliente remoto no puede prepararse, la app abre con la demostración
  // en memoria, que se identifica en pantalla como datos ficticios.
  StaffBackend? staff;
  SupportFlow? support;
  StudentSession? session;
  try {
    final SetuRemoteGateway gateway =
        await SupabaseSetuRemoteGateway.initialize();
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
              );
      },
    );
    support = SupportFlow(
      backend: RemoteSupportBackend(gateway),
      // Código inicial; la app lo reemplaza por el del colegio confirmado.
      schoolCode: const String.fromEnvironment(
        'SETU_SCHOOL_CODE',
        defaultValue: 'AULA24',
      ),
    );
  } on Object {
    staff = null;
    support = null;
    session = null;
  }
  runApp(
    CureandoApp(
      staffBackend: staff,
      supportFlow: support,
      studentSession: session,
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
