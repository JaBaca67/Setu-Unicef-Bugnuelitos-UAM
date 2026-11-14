import 'dart:io';
import 'dart:ui' as ui;

import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/staff/demo_staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_access_screens.dart';
import 'package:cureando_mobile/features/staff/staff_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const ValueKey<String> _captureKey = ValueKey<String>('staff-capture');

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

  Future<DemoStaffBackend> open(
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
    return backend;
  }

  Future<void> signIn(WidgetTester tester, String email) async {
    await _type(tester, 'Correo institucional', email);
    await _type(tester, 'Contraseña', DemoStaffBackend.demoPassword);
    await _tap(tester, 'Ingresar');
  }

  testWidgets('la bienvenida lleva al ingreso de personal y valida la cuenta', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(392, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: CureandoApp(staffBackend: DemoStaffBackend()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Explorar Información'), findsNothing);
    expect(find.text('Ayuda'), findsOneWidget);
    expect(find.text('Cómo cuidamos tu información'), findsOneWidget);
    await _capture(tester, 'p01-bienvenida');
    await _tap(tester, 'Personal autorizado');

    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);
    await _capture(tester, 'p02-ingreso');
    await _tap(tester, 'Ingresar');
    expect(
      find.text('Escribí tu correo institucional y tu contraseña.'),
      findsOneWidget,
    );

    await _type(tester, 'Correo institucional', 'direccion.cca@setu.test');
    await _type(tester, 'Contraseña', 'otra-clave');
    expect(_password(tester).obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(_password(tester).obscureText, isFalse);
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    await _tap(tester, 'Ingresar');
    expect(
      find.text('El correo o la contraseña no coinciden.'),
      findsOneWidget,
    );

    await _type(tester, 'Contraseña', DemoStaffBackend.demoPassword);
    await _tap(tester, 'Ingresar');
    expect(find.text('Dirección del centro'), findsOneWidget);
    expect(find.text('Colegio Centro América — Demo'), findsOneWidget);

    await tester.tap(find.byTooltip('Mi sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Cambiar de centro'), findsNothing);
    await _tap(tester, 'Cerrar sesión');
    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);

    await _tap(tester, 'Volver a la bienvenida');
    expect(find.text('Tu salud mental'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con varios centros pide elegir ámbito y respeta el rol', (
    WidgetTester tester,
  ) async {
    await open(tester);
    final GoRouter router = GoRouter.of(
      tester.element(find.byType(StaffLoginScreen)),
    );
    router.go('/personal/mined');
    await tester.pumpAndSettle();
    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);

    await signIn(tester, 'escucha.demo@setu.test');
    expect(find.text('¿Dónde vas a trabajar?'), findsOneWidget);
    expect(find.text('Colegio Centro América — Demo'), findsOneWidget);
    await _capture(tester, 'p04-ambito');
    await _tap(tester, 'Colegio de prueba A');
    expect(find.text('Mesa de Escucha'), findsOneWidget);
    expect(find.text('Mis casos'), findsOneWidget);

    router.go('/personal/direccion');
    await tester.pumpAndSettle();
    expect(find.text('Mesa de Escucha'), findsOneWidget);

    // Elegido el centro, no se cambia sin cerrar sesión.
    router.go('/personal/ambito');
    await tester.pumpAndSettle();
    expect(find.text('Mis casos'), findsOneWidget);
    await tester.tap(find.byTooltip('Mi sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Cambiar de centro'), findsNothing);
    await _tap(tester, 'Cerrar sesión');
    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el primer ingreso valida el código, el correo y el canje', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await open(tester);
    await _tap(tester, 'Activar mi cuenta');
    expect(find.text('Confirmá tu acceso'), findsOneWidget);
    await _tap(tester, 'Necesito ayuda con mi acceso');
    expect(find.text('Ayuda con tu acceso'), findsOneWidget);
    await _tap(tester, 'Cerrar');

    await _tap(tester, 'Validar código');
    expect(find.text('Escribí el código de activación.'), findsOneWidget);
    await _type(tester, 'Código de activación', 'NO-EXISTE');
    await _tap(tester, 'Validar código');
    expect(find.textContaining('No reconocemos ese código'), findsOneWidget);
    await _type(tester, 'Código de activación', 'CCA-EXP-2026');
    await _tap(tester, 'Validar código');
    expect(find.textContaining('ya venció'), findsOneWidget);
    await _type(tester, 'Código de activación', 'CCA-REV-2026');
    await _tap(tester, 'Validar código');
    expect(find.textContaining('fue anulado'), findsOneWidget);

    await _type(tester, 'Código de activación', 'cca-dir-2026');
    await _tap(tester, 'Validar código');
    expect(find.text('Colegio asignado'), findsOneWidget);
    expect(find.text('Colegio Centro América — Demo'), findsOneWidget);
    expect(find.text('Dirección del centro'), findsOneWidget);
    await _capture(tester, 'p03-activacion');
    await _tap(tester, 'Confirmar acceso');

    expect(find.text('Creá tu contraseña'), findsOneWidget);
    await _type(tester, 'Correo institucional', 'otra@setu.test');
    await _type(tester, 'Contraseña nueva', 'corta');
    await _tap(tester, 'Crear mi cuenta');
    expect(find.textContaining('al menos 8 caracteres'), findsOneWidget);
    await _type(tester, 'Contraseña nueva', 'Clave-Ficticia-1');
    await _type(tester, 'Repetí la contraseña', 'Clave-Ficticia-2');
    await _tap(tester, 'Crear mi cuenta');
    expect(find.text('Las dos contraseñas no coinciden.'), findsOneWidget);
    await _type(tester, 'Repetí la contraseña', 'Clave-Ficticia-1');
    await _tap(tester, 'Crear mi cuenta');
    expect(find.textContaining('otro correo institucional'), findsOneWidget);

    await _type(tester, 'Correo institucional', 'invitada.cca@setu.test');
    await _tap(tester, 'Crear mi cuenta');
    expect(find.text('Revisá tu correo institucional'), findsOneWidget);
    await _tap(tester, 'Ya confirmé mi correo');
    expect(
      find.textContaining('Todavía no vemos tu correo confirmado'),
      findsOneWidget,
    );

    backend.confirmEmail('invitada.cca@setu.test');
    await _tap(tester, 'Ya confirmé mi correo');
    expect(find.text('Dirección del centro'), findsOneWidget);
    expect(find.text('Colegio Centro América — Demo'), findsOneWidget);

    // El código es de un solo uso.
    final preview = await backend.previewActivation('CCA-DIR-2026');
    expect(preview.error, 'activation_code_already_used');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin conexión informa el fallo y no entra', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await open(tester);
    backend.offline = true;
    await signIn(tester, 'mined.demo@setu.test');
    expect(
      find.textContaining('Revisá tu conexión a internet'),
      findsOneWidget,
    );
    backend.offline = false;
    await _tap(tester, 'Ingresar');
    expect(find.text('MINED central'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ingreso y activación caben en pantalla chica con texto grande', (
    WidgetTester tester,
  ) async {
    await open(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'Activar mi cuenta');
    await _type(tester, 'Código de activación', 'CCA-MESA-2026');
    await _tap(tester, 'Validar código');
    expect(find.text('Colegio asignado'), findsOneWidget);
    await _tap(tester, 'Confirmar acceso');
    expect(find.text('Creá tu contraseña'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

TextField _password(WidgetTester tester) => tester.widget<TextField>(
  find.descendant(
    of: find.widgetWithText(StaffField, 'Contraseña'),
    matching: find.byType(TextField),
  ),
);

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
  final Finder finder = any.last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SETU_CAPTURE_QA')) return;
  final Finder capture = find.byKey(_captureKey);
  final Finder images = find.descendant(
    of: capture,
    matching: find.byType(Image),
  );
  await tester.runAsync<void>(() async {
    for (final Element element in images.evaluate()) {
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
