import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const CureandoApp(
      showM1Verification: kDebugMode && bool.fromEnvironment('SETU_M1_QA'),
      allowDesignCapture:
          kDebugMode && bool.fromEnvironment('SETU_DESIGN_CAPTURE'),
    ),
  );
}
