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
const String _director = 'direccion.cca@setu.test';

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

  Future<DemoStaffBackend> openDirector(
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
    await _type(tester, 'Correo institucional', _director);
    await _type(tester, 'Contraseña', DemoStaffBackend.demoPassword);
    await _tap(tester, 'Ingresar');
    return backend;
  }

  testWidgets('Dirección ve la ficha mínima y registra los pasos del centro', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDirector(tester);
    expect(find.text('Avisos y fichas'), findsOneWidget);
    expect(find.text('DEMO-030'), findsOneWidget);
    expect(find.text('Ficha recibida'), findsOneWidget);
    expect(find.text('DEMO-021'), findsOneWidget);
    expect(find.text('Aviso recibido'), findsOneWidget);
    // Los casos de otro centro no aparecen.
    expect(find.text('DEMO-014'), findsNothing);
    await _capture(tester, 'p11-direccion');

    await _tap(tester, 'DEMO-030');
    expect(find.text('Aviso DEMO-030'), findsOneWidget);
    expect(find.text('Ficha de Mesa de Escucha'), findsOneWidget);
    expect(find.text('Nivel 2 · Convivencia'), findsOneWidget);
    expect(find.textContaining('reforzar los acuerdos'), findsOneWidget);
    expect(find.text('Ciberacoso · Me pasó a mí'), findsOneWidget);
    // Ni el relato ni la conversación llegan a la dirección.
    expect(find.textContaining('Relato ficticio'), findsNothing);
    expect(await backend.narrative('demo-case-030'), isNull);
    expect(await backend.messages('demo-case-030'), isEmpty);
    expect(await backend.notes('demo-case-030'), isEmpty);
    expect(find.text('Pendiente'), findsNWidgets(5));

    await _tap(tester, 'Registrar');
    expect(find.text('Qué hizo el centro'), findsOneWidget);
    await _tap(tester, 'Guardar registro');
    expect(
      find.text('Escribí qué hizo el centro en este paso.'),
      findsOneWidget,
    );
    await _type(tester, 'Qué hizo el centro', 'Registro ficticio del paso 1.');
    await _tap(tester, 'Guardar registro');
    expect(find.text('Registro ficticio del paso 1.'), findsOneWidget);
    expect(find.text('Registrado'), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(4));
    expect(find.text('En actuación del centro'), findsOneWidget);
    await _capture(tester, 'p12-actuaciones');

    // Paso 3: con la identidad reservada solo se registra como acción grupal.
    await _tap(tester, '3 · Informar a familia o grupo según ficha');
    final Finder third = find.descendant(
      of: find
          .ancestor(
            of: find.text('3 · Informar a familia o grupo según ficha'),
            matching: find.byType(Container),
          )
          .first,
      matching: find.text('Registrar'),
    );
    await tester.ensureVisible(third);
    await tester.tap(third);
    await tester.pumpAndSettle();
    expect(find.textContaining('acción con el grupo'), findsOneWidget);
    await _type(tester, 'Qué hizo el centro', 'Charla ficticia con el grupo.');
    await _tap(tester, 'Documentar y enviar al MINED');
    await _tap(tester, 'Guardar registro');
    expect(
      find.textContaining('Acción grupal · Cierre propuesto al MINED'),
      findsOneWidget,
    );
    final List<SchoolActionRecordView> saved = await backend.schoolActions(
      'demo-case-030',
    );
    expect(saved, hasLength(2));
    expect(saved.last.isGroupAction, isTrue);
    expect(saved.last.proposesClosure, isTrue);
    expect(saved.last.actionSheetId, 'demo-sheet-030');
    // Proponer el cierre no cierra el caso.
    final StaffCaseSummary item = (await backend.cases()).firstWhere(
      (StaffCaseSummary found) => found.id == 'demo-case-030',
    );
    expect(item.status, SetuCaseStatus.schoolActing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el aviso docente se registra sin relato ni nombres', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await openDirector(tester);
    await _tap(tester, 'Registrar aviso docente');
    expect(find.text('Aviso docente'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await _tap(tester, 'Registrar aviso');
    expect(find.text('Elegí el tipo de situación.'), findsOneWidget);
    await _tap(tester, 'Acoso verbal');
    await _tap(tester, 'Registrar aviso');
    expect(find.text('Acoso verbal · Aviso docente'), findsOneWidget);

    // Si involucra a personal del centro, deja de verse en esta bandeja.
    await _tap(tester, 'Registrar aviso docente');
    await _tap(tester, 'Acoso social');
    await _tap(tester, 'Involucra a personal del centro');
    await _tap(tester, 'Registrar aviso');
    expect(find.text('Acoso social · Aviso docente'), findsNothing);
    expect(await backend.cases(), hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('la vista de Dirección cabe en pantalla chica con texto grande', (
    WidgetTester tester,
  ) async {
    await openDirector(tester, size: const Size(320, 568), textScale: 2);
    expect(find.text('Avisos y fichas'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'DEMO-030');
    expect(find.text('Actuaciones del centro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('las actuaciones respetan rol, conflicto y concurrencia', () async {
    final DemoStaffBackend backend = DemoStaffBackend();
    const SchoolActionDraft draft = SchoolActionDraft(
      caseId: 'demo-case-030',
      step: SetuSchoolActionStep.identify,
      notes: 'Registro ficticio.',
      expectedVersion: 1,
    );
    Future<void> record(String operation, SchoolActionDraft action) =>
        backend.recordSchoolAction(operationId: operation, action: action);

    await backend.signIn(
      email: 'mined.demo@setu.test',
      password: DemoStaffBackend.demoPassword,
    );
    await expectLater(
      record('op-mined-0001', draft),
      throwsA(isA<GatewayException>()),
    );

    await backend.signIn(
      email: _director,
      password: DemoStaffBackend.demoPassword,
    );
    // Un caso de otro centro no admite registros de esta dirección.
    await expectLater(
      record(
        'op-otro-00001',
        const SchoolActionDraft(
          caseId: 'demo-case-014',
          step: SetuSchoolActionStep.identify,
          notes: 'Registro ficticio.',
          expectedVersion: 1,
        ),
      ),
      throwsA(isA<GatewayException>()),
    );
    // El contacto con una familia en particular está bloqueado.
    await expectLater(
      record(
        'op-familia-01',
        const SchoolActionDraft(
          caseId: 'demo-case-030',
          step: SetuSchoolActionStep.notifyFamilyOrGroup,
          notes: 'Registro ficticio.',
          expectedVersion: 1,
        ),
      ),
      throwsA(
        isA<GatewayException>().having(
          (GatewayException e) => e.message,
          'message',
          contains('family_contact_blocked'),
        ),
      ),
    );

    await record('op-paso-0001', draft);
    // Repetir la misma operación no duplica el registro.
    await record('op-paso-0001', draft);
    expect(await backend.schoolActions('demo-case-030'), hasLength(1));
    // Una versión vieja del caso se rechaza.
    await expectLater(
      record('op-paso-0002', draft),
      throwsA(
        isA<GatewayException>().having(
          (GatewayException e) => e.message,
          'message',
          'concurrency_conflict',
        ),
      ),
    );
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
