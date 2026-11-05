import 'package:cureando_mobile/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('M0 muestra el aviso de demo y responde al toque', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CureandoApp());
    await tester.pumpAndSettle();

    expect(find.text('Prototipo con datos ficticios'), findsOneWidget);
    expect(find.textContaining('No envía reportes reales.'), findsOneWidget);
    await tester.tap(find.text('Comprobar funcionamiento'));
    await tester.pump();
    expect(
      find.text('¡Listo! La interfaz responde correctamente.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('M0 admite pantalla pequeña y texto ampliado', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const CureandoApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comprobar funcionamiento'));
    await tester.tap(find.text('Comprobar funcionamiento'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.text('¡Listo! La interfaz responde correctamente.'),
      findsOneWidget,
    );
  });
}
