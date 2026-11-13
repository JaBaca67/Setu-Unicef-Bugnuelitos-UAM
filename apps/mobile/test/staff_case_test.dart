import 'dart:io';
import 'dart:ui' as ui;

import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/staff/demo_staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_widgets.dart';
import 'package:cureando_mobile/shared/models/cureando_models.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_models.dart';
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

  /// Entra como Mesa de Escucha en Colegio de prueba A.
  Future<DemoStaffBackend> openDesk(
    WidgetTester tester, {
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
    await _type(tester, 'Correo institucional', _desk);
    await _type(tester, 'Contraseña', DemoStaffBackend.demoPassword);
    await _tap(tester, 'Ingresar');
    await _tap(tester, 'Colegio de prueba A');
    return backend;
  }

  Future<StaffCaseSummary> summary(DemoStaffBackend backend, String id) async =>
      (await backend.cases()).firstWhere(
        (StaffCaseSummary item) => item.id == id,
      );

  testWidgets('Mesa conversa antes de valorar y la nota interna queda aparte', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDesk(tester);
    await _tap(tester, 'DEMO-014');
    expect(find.text('Alerta DEMO-014'), findsOneWidget);
    expect(find.text('Relato compartido'), findsOneWidget);
    expect(find.text('“Se burlan de mí durante el recreo.”'), findsOneWidget);
    expect(find.text('Acoso verbal · Me pasó a mí'), findsOneWidget);
    expect(find.text('Sin valorar'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Pieza del estudiante')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Guardar valoración'),
          )
          .onPressed,
      isNull,
    );
    await _capture(tester, 'p07-caso');

    // El chat se habilita sin haber valorado.
    await _tap(tester, 'Habilitar chat');
    expect(find.text('Conversación'), findsOneWidget);
    expect(find.textContaining('Todavía no hay mensajes'), findsOneWidget);
    expect((await summary(backend, 'demo-case-014')).humanLevel, isNull);

    backend.offline = true;
    await tester.enterText(find.byType(TextField), 'Hola, te leo.');
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Tu texto sigue en el borrador'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Hola, te leo.',
    );
    backend.offline = false;
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, te leo.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );

    await _tap(tester, 'Nota interna');
    expect(find.text('Notas internas'), findsOneWidget);
    expect(find.text('Todavía no hay notas en este caso.'), findsOneWidget);
    await _tap(tester, 'Guardar nota');
    expect(find.text('Escribí la nota antes de guardarla.'), findsOneWidget);
    await _type(tester, 'Nota nueva', 'Nota ficticia privada');
    await _tap(tester, 'Guardar nota');
    expect(find.text('Nota ficticia privada'), findsOneWidget);
    await _capture(tester, 'p09-nota');
    await _tap(tester, 'Cerrar');

    // La nota no aparece en la conversación ni viaja como mensaje.
    expect(find.text('Nota ficticia privada'), findsNothing);
    final List<CaseChatMessageView> messages = await backend.messages(
      'demo-case-014',
    );
    expect(messages.map((CaseChatMessageView m) => m.body), <String>[
      'Hola, te leo.',
    ]);
    expect(
      (await backend.notes('demo-case-014')).single.noteBody,
      'Nota ficticia privada',
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir conversación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la valoración exige revisar la ficha mínima antes de enviarla', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDesk(tester);
    await _tap(tester, 'DEMO-014');
    await _tap(tester, '3 · Riesgo grave');
    await _tap(tester, 'Registrar derivación urgente');
    await _tap(tester, 'Enviar ficha mínima');
    await _tap(tester, 'Guardar valoración');
    expect(find.text('Escribí la orientación para el centro.'), findsOneWidget);
    await _type(
      tester,
      'Orientación para el centro',
      'Orientación ficticia para el centro.',
    );
    await _tap(tester, 'Guardar valoración');

    expect(find.text('Revisá antes de guardar'), findsOneWidget);
    expect(find.text('Nivel 3 · Riesgo grave'), findsOneWidget);
    expect(find.text('Se registra ahora.'), findsOneWidget);
    expect(
      find.text('La dirección del centro y la supervisión del MINED.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no incluye el relato, los mensajes ni las notas'),
      findsWidgets,
    );
    // El relato nunca forma parte de la ficha que se revisa.
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.textContaining('Se burlan'),
      ),
      findsNothing,
    );
    await _capture(tester, 'p10-ficha');
    await _tap(tester, 'Volver a editar');
    expect((await summary(backend, 'demo-case-014')).humanLevel, isNull);

    await _tap(tester, 'Guardar valoración');
    await _tap(tester, 'Confirmar y guardar');
    expect(find.text('Valoración guardada.'), findsOneWidget);
    expect(find.text('Derivación urgente registrada.'), findsOneWidget);
    final StaffCaseSummary saved = await summary(backend, 'demo-case-014');
    expect(saved.humanLevel, 3);
    expect(saved.urgentReferralTriggered, isTrue);
    expect(saved.status, SetuCaseStatus.sheetSent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el nivel 1 permite cerrar con motivo y retoma chats activos', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDesk(tester);
    await _tap(tester, 'DEMO-014');
    await _tap(tester, '1 · Acompañamiento');
    expect(find.text('Enviar ficha mínima'), findsNothing);
    await _tap(tester, 'Cerrar el caso en Mesa de Escucha');
    await _tap(tester, 'Guardar valoración');
    expect(find.text('Escribí el motivo del cierre.'), findsOneWidget);
    await _type(tester, 'Motivo del cierre', 'Acompañamiento concluido.');
    await _tap(tester, 'Guardar valoración');
    await _tap(tester, 'Confirmar y guardar');
    expect(
      find.text('Este caso está cerrado. Motivo: Acompañamiento concluido.'),
      findsOneWidget,
    );
    expect(find.text('Habilitar chat'), findsNothing);
    expect(
      (await summary(backend, 'demo-case-014')).status,
      SetuCaseStatus.closed,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO-014'), findsNothing);
    await _tap(tester, 'En conversación');
    await _tap(tester, 'DEMO-009');
    expect(find.textContaining('no escribió detalles'), findsOneWidget);
    await _tap(tester, 'Abrir conversación');
    expect(find.text('Me cuesta hablar de esto.'), findsOneWidget);
    expect(find.text('Podés contarme a tu ritmo.'), findsOneWidget);
    await _capture(tester, 'p08-conversacion');
    expect(tester.takeException(), isNull);
  });

  testWidgets('caso y conversación caben en pantalla chica con texto grande', (
    WidgetTester tester,
  ) async {
    await openDesk(tester, size: const Size(320, 568), textScale: 2);
    await _tap(tester, 'DEMO-014');
    await _tap(tester, '2 · Convivencia');
    await _tap(tester, 'Enviar ficha mínima');
    expect(find.text('Orientación para el centro'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'Habilitar chat');
    expect(find.text('Conversación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('quien no tiene el caso asignado no lee ni actúa sobre él', () async {
    final DemoStaffBackend backend = DemoStaffBackend();
    await backend.signIn(
      email: 'mined.demo@setu.test',
      password: DemoStaffBackend.demoPassword,
    );
    expect(await backend.narrative('demo-case-014'), isNull);
    expect(await backend.messages('demo-case-009'), isEmpty);
    expect(await backend.notes('demo-case-014'), isEmpty);
    for (final Future<void> Function() action in <Future<void> Function()>[
      () => backend.enableChat(
        operationId: 'op-12345678',
        caseId: 'demo-case-014',
      ),
      () => backend.saveNote(
        operationId: 'op-12345678',
        caseId: 'demo-case-014',
        body: 'x',
      ),
      () => backend.assess(
        operationId: 'op-12345678',
        assessment: const CaseAssessment(caseId: 'demo-case-014', level: 2),
      ),
    ]) {
      await expectLater(action(), throwsA(isA<GatewayException>()));
    }
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
