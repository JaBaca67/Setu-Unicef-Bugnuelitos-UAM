import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import 'school_access_screen.dart' show SchoolCrest;
import 'school_location.dart';
import 'student_session.dart';

/// Cartel con el QR público de un colegio. El QR solo lleva el código
/// público del centro (`setu://colegio/CODIGO`): no identifica a nadie.
class SchoolQrPosterScreen extends StatelessWidget {
  const SchoolQrPosterScreen({super.key, required this.school});

  final ConfirmedSchool school;

  @override
  Widget build(BuildContext context) {
    final String code = school.publicCode;
    final bool valid = extractSchoolCode(code) != null;
    return FlowScaffold(
      header: const FlowHeader(
        title: 'Cartel QR',
        subtitle: 'Para mostrar o colocar en el colegio.',
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CureandoTheme.blue, width: 2),
        ),
        child: Column(
          children: <Widget>[
            SchoolCrest(school: school, size: 72),
            const SizedBox(height: 10),
            Semantics(
              header: true,
              child: Text(
                school.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (school.municipality.isNotEmpty)
              Text(
                school.place,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: CureandoTheme.secondaryInk,
                ),
              ),
            const SizedBox(height: 18),
            if (valid) ...<Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: QrImageView(
                  data: schoolQrLink(code),
                  size: 240,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  semanticsLabel: 'Código QR del colegio, código $code',
                ),
              ),
              const SizedBox(height: 12),
              const Text('Código del colegio', style: TextStyle(fontSize: 15)),
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 30,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.blue,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Abrí SéTú, tocá «Ingreso estudiantil» y escaneá este código '
                'para entrar al espacio de tu colegio. No te pedimos nombre '
                'ni carné.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
            ] else
              const Text(
                'Este centro todavía no tiene un código público disponible '
                'para generar su cartel.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
          ],
        ),
      ),
    );
  }
}
