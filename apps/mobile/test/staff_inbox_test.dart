import 'dart:io';
import 'dart:ui' as ui;

import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/staff/demo_staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _captureKey = ValueKey<String>('staff-capture');
const String _desk = 'escucha.demo@setu.test';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final FontLoader poppins = FontLoader('Poppins');
    for (final String weight in <String>[
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      poppins.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await poppins.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<DemoStaffBackend> signIn(
    WidgetTester tester,
    String email, {
    Size size = const Size(392, 800),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final DemoStaffBackend backend = DemoStaffBackend();
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: CureandoApp(staffBackend: backend),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Personal autorizado');
    await _type(tester, 'Correo institucional', email);
    await _type(tester, 'Contraseña', DemoStaffBackend.demoPassword);
    await _tap(tester, 'Ingresar');
    return backend;
  }

  testWidgets('MINED ve datos mínimos y asigna el caso a Mesa de Escucha', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await signIn(
      tester,
      'mined.demo@setu.test',
    );
    expect(find.text('Alertas recibidas'), findsOneWidget);
    expect(find.text('DEMO-021'), findsOneWidget);
    expect(find.text('DEMO-014'), findsOneWidget);
    expect(find.text('Colegio Centro América — Demo'), findsOneWidget);
    expect(find.text('Sin asignar'), findsOneWidget);
    // El relato y la conversación nunca llegan a la supervisión.
    expect(find.textContaining('Relato ficticio'), findsNothing);
    expect(find.textContaining('Se burlan'), findsNothing);
    expect(find.textContaining('Me cuesta hablar'), findsNothing);
    expect(await backend.narrative('demo-case-021'), isNull);
    expect(await backend.messages('demo-case-009'), isEmpty);
    await _capture(tester, 'p05-mined');

    await _tap(tester, 'Asignar a Mesa de Escucha');
    expect(find.text('Asignar DEMO-021'), findsOneWidget);
    await _tap(tester, _desk);
    expect(find.text('Caso DEMO-021 asignado.'), findsOneWidget);
    expect(find.text('Sin asignar'), findsNothing);
    expect(find.text('Asignada'), findsNWidgets(3));

    backend.offline = true;
    await tester.ensureVisible(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Revisá tu conexión a internet'),
      findsOneWidget,
    );
    backend.offline = false;
    await _tap(tester, 'Reintentar');
    expect(find.text('DEMO-021'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mesa filtra sus casos y recibe el aviso de asignación', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await signIn(tester, _desk);
    await _tap(tester, 'Colegio de prueba A');
    expect(find.text('Mis casos'), findsOneWidget);
    expect(find.text('DEMO-014'), findsOneWidget);
    expect(find.text('Sin valorar'), findsOneWidget);
    expect(find.text('DEMO-009'), findsNothing);
    expect(find.text('Tenés una alerta asignada'), findsNothing);
    await _capture(tester, 'p06-mesa');

    await _tap(tester, 'En conversación');
    expect(find.text('DEMO-009'), findsOneWidget);
    expect(find.text('Nivel 2 · Convivencia'), findsOneWidget);
    expect(find.text('DEMO-014'), findsNothing);

    // Un caso de otro centro asignado a la misma persona dispara el aviso,
    // pero la bandeja de este centro no lo lista.
    backend.simulateAssignment('demo-case-021', _desk);
    await tester.pumpAndSettle();
    expect(find.text('Tenés una alerta asignada'), findsOneWidget);
    await _tap(tester, 'Tenés una alerta asignada');
    expect(find.text('Tenés una alerta asignada'), findsNothing);
    expect(find.text('Mis casos'), findsOneWidget);
    expect(find.text('DEMO-021'), findsNothing);

    await tester.tap(find.byTooltip('Mi sesión'));
    await tester.pumpAndSettle();
    await _tap(tester, 'Cambiar de centro');
    await _tap(tester, 'Colegio Centro América — Demo');
    expect(find.text('DEMO-021'), findsOneWidget);
    expect(find.text('Sin valorar'), findsOneWidget);
    await _tap(tester, 'En conversación');
    expect(find.text('No tenés conversaciones activas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las bandejas caben en pantalla chica con texto grande', (
    WidgetTester tester,
  ) async {
    await signIn(
      tester,
      'mined.demo@setu.test',
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(find.text('Alertas recibidas'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Mi sesión'));
    await tester.pumpAndSettle();
    await _tap(tester, 'Cerrar sesión');
    await _type(tester, 'Correo institucional', _desk);
    await _type(tester, 'Contraseña', DemoStaffBackend.demoPassword);
    await _tap(tester, 'Ingresar');
    await _tap(tester, 'Colegio de prueba A');
    expect(find.text('Mis casos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final Finder field = find.descendant(
    of: find.widgetWithText(StaffField, label),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final Finder any = find.text(label);
  if (any.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      any,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final Finder finder = any.first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SETU_CAPTURE_QA')) return;
  final Finder capture = find.byKey(_captureKey);
  await tester.runAsync<void>(() async {
    for (final Element element
        in find
            .descendant(of: capture, matching: find.byType(Image))
            .evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync<void>(() async {
    final RenderRepaintBoundary boundary = tester
        .renderObject<RenderRepaintBoundary>(capture);
    final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    final Directory directory = Directory('build/qa');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}
