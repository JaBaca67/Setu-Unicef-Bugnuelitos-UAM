import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'features/staff/remote_staff_backend.dart';
import 'features/staff/staff_backend.dart';
import 'features/support/remote_support_backend.dart';
import 'features/support/support_flow.dart';
import 'shared/remote/setu_remote_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Si el cliente remoto no puede prepararse, la app abre con la demostración
  // en memoria, que se identifica en pantalla como datos ficticios.
  StaffBackend? staff;
  SupportFlow? support;
  try {
    final SetuRemoteGateway gateway =
        await SupabaseSetuRemoteGateway.initialize();
    staff = RemoteStaffBackend(
      gateway,
      // Los centros activos son de lectura pública (RLS).
      loadInstitutionNames: () async => <String, String>{
        for (final Map<String, dynamic> row
            in await Supabase.instance.client
                .from('institutions')
                .select('id,name'))
          '${row['id']}': '${row['name']}',
      },
    );
    support = SupportFlow(
      backend: RemoteSupportBackend(gateway),
      // El acceso escolar de la demostración valida un único código local.
      schoolCode: const String.fromEnvironment(
        'SETU_SCHOOL_CODE',
        defaultValue: 'AULA24',
      ),
    );
  } on Object {
    staff = null;
    support = null;
  }
  runApp(
    CureandoApp(
      staffBackend: staff,
      supportFlow: support,
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
