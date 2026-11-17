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
const String _desk = 'escucha.demo@example.org';

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
    await _tap(tester, 'Iniciar sesión');
    await _tap(tester, 'Colegio de prueba A');
    return backend;
  }

  Future<StaffCaseSummary> summary(DemoStaffBackend backend, String id) async =>
      (await backend.cases()).firstWhere(
        (StaffCaseSummary item) => item.id == id,
      );

  testWidgets('Alerta muestra pieza con relato y el chat alterna con Ficha', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDesk(tester);
    await _tap(tester, 'DEMO-014');
    expect(find.text('Alerta DEMO-014'), findsOneWidget);
    expect(find.text('Sin valorar'), findsOneWidget);
    expect(find.text('Comentario de la alerta'), findsOneWidget);
    expect(find.text('Chispa Cósmica'), findsOneWidget);
    expect(find.text('Se burlan de mí durante el recreo.'), findsOneWidget);
    expect(find.text('Datos de la alerta'), findsOneWidget);
    expect(find.text('Acoso verbal'), findsOneWidget);
    expect(find.text('Me pasó a mí'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Pieza del estudiante')),
      findsOneWidget,
    );
    await _capture(tester, 'p07-caso');

    // El botón principal habilita el chat sin exigir valoración previa.
    await _tap(tester, 'Atender por chat');
    expect(find.text('Chispa Cósmica'), findsOneWidget);
    expect(find.text('DEMO-014 · Sin valorar'), findsOneWidget);
    expect(find.text('Ficha'), findsOneWidget);
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
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Hola, te leo.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );

    // Conmuta a «Ficha» dentro del chat sin perder el borrador de chat.
    await tester.enterText(find.byType(TextField), 'Borrador chat vivo');
    await _tap(tester, 'Ficha');
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Notas privadas de escucha'), findsOneWidget);
    expect(find.text('Todavía no hay notas en este caso.'), findsOneWidget);

    await _tap(tester, 'Guardar nota');
    expect(find.text('Escribí la nota antes de guardarla.'), findsOneWidget);
    await _type(tester, 'Nueva nota privada', 'Nota ficticia privada');
    await _tap(tester, 'Guardar nota');
    expect(find.text('Nota ficticia privada'), findsOneWidget);
    await _capture(tester, 'p09-nota');

    // Regresar a «Chat» conserva el texto escrito en el compositor.
    await _tap(tester, 'Chat');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Borrador chat vivo',
    );
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
    expect(find.text('Atender por chat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ficha guarda borrador, exige revisión, envía reporte y cierra chat', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDesk(tester);
    await _tap(tester, 'DEMO-014');
    // Acceso secundario a Ficha sin habilitar chat todavía.
    await _tap(tester, 'Abrir ficha sin chat');
    expect(find.text('Chat'), findsOneWidget);
    await _tap(tester, '3 · Riesgo grave');
    await _tap(tester, 'Registrar derivación urgente');
    await _type(
      tester,
      'Comentarios para la ficha',
      'Borrador inicial del centro.',
    );
    await _tap(tester, 'Guardar borrador');
    expect(find.text('Borrador guardado.'), findsOneWidget);
    expect(
      (await backend.sheetDraft('demo-case-014'))?.guidanceDraft,
      'Borrador inicial del centro.',
    );

    // Al salir y volver a entrar a la ficha, el borrador guardado se restaura.
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await _tap(tester, 'Abrir ficha sin chat');
    expect(
      find.text('Borrador inicial del centro.'),
      findsOneWidget,
    );

    await _tap(tester, '3 · Riesgo grave');
    await _tap(tester, 'Registrar derivación urgente');
    await _type(
      tester,
      'Comentarios para la ficha',
      'Orientación ficticia para el centro.',
    );
    await _tap(tester, 'Enviar reporte y cerrar chat');

    expect(find.text('Revisar ficha antes de enviar'), findsOneWidget);
    expect(find.text('Nivel 3 · Riesgo grave'), findsOneWidget);
    expect(find.text('Se registra ahora.'), findsOneWidget);
    expect(
      find.text('La dirección del centro y la supervisión del MINED.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no incluye el relato, los mensajes ni las notas'),
      findsOneWidget,
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

    await _tap(tester, 'Enviar reporte y cerrar chat');
    final Finder confirmReport = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(
        FilledButton,
        'Enviar reporte y cerrar chat',
      ),
    );
    await tester.ensureVisible(confirmReport);
    await tester.pumpAndSettle();
    await tester.tap(confirmReport);
    await tester.pumpAndSettle();
    expect(find.text('Reporte enviado y chat cerrado.'), findsOneWidget);
    final StaffCaseSummary saved = await summary(backend, 'demo-case-014');
    expect(saved.humanLevel, 3);
    expect(saved.urgentReferralTriggered, isTrue);
    expect(saved.status, SetuCaseStatus.sheetSent);
    expect(saved.isConversationEnded, isTrue);

    // Al volver al chat queda en solo lectura.
    await _tap(tester, 'Chat');
    expect(find.text('Chat finalizado. Solo lectura.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el nivel 1 cierra caso y chat, y retoma chats activos', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDesk(tester);
    await _tap(tester, 'DEMO-014');
    await _tap(tester, 'Abrir ficha sin chat');
    await _tap(tester, '1 · Acompañamiento');
    expect(find.text('Enviar reporte y cerrar chat'), findsNothing);
    await _tap(tester, 'Cerrar caso y chat');
    expect(find.text('Escribí el motivo del cierre.'), findsOneWidget);
    await _type(tester, 'Motivo del cierre', 'Acompañamiento concluido.');
    await _tap(tester, 'Cerrar caso y chat');
    expect(find.text('Confirmar cierre'), findsWidgets);
    final Finder confirmClose = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(FilledButton, 'Confirmar cierre'),
    );
    await tester.ensureVisible(confirmClose);
    await tester.pumpAndSettle();
    await tester.tap(confirmClose);
    await tester.pumpAndSettle();
    expect(find.text('Caso cerrado y chat finalizado.'), findsOneWidget);
    final StaffCaseSummary closedCase = await summary(backend, 'demo-case-014');
    expect(closedCase.status, SetuCaseStatus.closed);
    expect(closedCase.isConversationEnded, isTrue);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(
      find.text('Este caso está cerrado. Motivo: Acompañamiento concluido.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    await _tap(tester, 'En conversación');
    await _tap(tester, 'DEMO-009');
    expect(find.textContaining('no escribió detalles'), findsOneWidget);
    await _tap(tester, 'Atender por chat');
    expect(find.text('12 nov'), findsOneWidget);
    expect(find.text('Me cuesta hablar de esto.'), findsOneWidget);
    expect(find.text('Podés contarme a tu ritmo.'), findsOneWidget);
    await _capture(tester, 'p08-conversacion');
    expect(tester.takeException(), isNull);
  });

  testWidgets('caso, chat y ficha caben en pantalla chica con texto grande', (
    WidgetTester tester,
  ) async {
    await openDesk(tester, size: const Size(320, 568), textScale: 2);
    await _tap(tester, 'DEMO-014');
    expect(find.text('Alerta DEMO-014'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'Atender por chat');
    expect(find.text('Chispa Cósmica'), findsOneWidget);
    await _tap(tester, 'Ficha');
    await _tap(tester, '2 · Convivencia');
    expect(find.text('Comentarios para la ficha'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('quien no tiene el caso asignado no lee ni actúa sobre él', () async {
    final DemoStaffBackend backend = DemoStaffBackend();
    await backend.signIn(
      email: 'mined.demo@example.org',
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
      () => backend.sheetDraft('demo-case-014'),
      () => backend.saveSheetDraft(
        caseId: 'demo-case-014',
        guidanceDraft: 'x',
      ),
      () => backend.endConversation(
        operationId: 'op-12345678',
        caseId: 'demo-case-014',
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
