import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const CureandoApp(showM1Verification: bool.fromEnvironment('SETU_M1_QA')),
  );
}
