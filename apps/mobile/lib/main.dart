import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'shared/remote/setu_remote_gateway.dart';
import 'shared/remote/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool hasRemote = await initializeSupabaseIfConfigured();
  runApp(
    CureandoApp(
      remoteGateway: hasRemote
          ? SupabaseSetuRemoteGateway(Supabase.instance.client)
          : null,
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
