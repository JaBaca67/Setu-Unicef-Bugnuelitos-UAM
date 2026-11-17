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
    await _tap(tester, 'Iniciar sesión');
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
    expect(find.text('Cómo cuidamos tu información'), findsNothing);
    await _capture(tester, 'p01-bienvenida');
    await _tap(tester, 'Personal autorizado');

    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);
    expect(find.text('Volver a la bienvenida'), findsNothing);
    expect(find.text('Solicitar acceso'), findsNothing);
    expect(find.text('Ayuda'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Simplemente #SoloSéTú'), findsOneWidget);
    await _tap(tester, 'Personal autorizado');
    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);
    await _capture(tester, 'p02-ingreso');
    await _tap(tester, 'Iniciar sesión');
    expect(
      find.text('Escribí tu correo institucional y tu contraseña.'),
      findsOneWidget,
    );

    await _type(tester, 'Correo institucional', 'direccion.cca@example.org');
    await _type(tester, 'Contraseña', 'otra-clave');
    expect(_password(tester).obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(_password(tester).obscureText, isFalse);
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    await _tap(tester, 'Iniciar sesión');
    expect(
      find.text('El correo o la contraseña no coinciden.'),
      findsOneWidget,
    );

    await _type(tester, 'Contraseña', DemoStaffBackend.demoPassword);
    await _tap(tester, 'Iniciar sesión');
    expect(find.text('Dirección del centro'), findsOneWidget);
    expect(find.text('Colegio Centro América — Demo'), findsOneWidget);

    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    await _tap(tester, 'Cerrar sesión');
    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Simplemente #SoloSéTú'), findsOneWidget);
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

    await signIn(tester, 'escucha.demo@example.org');
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
    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(
      find.textContaining('cerrá sesión e ingresá de nuevo'),
      findsOneWidget,
    );
    await _tap(tester, 'Cerrar sesión');
    expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'el alta en 4 pasos pide datos y rol, confirma correo y activa con código en casillas',
    (WidgetTester tester) async {
      final DemoStaffBackend backend = await open(tester);
      await _tap(tester, 'Registrar cuenta');
      expect(find.text('¿Quién sos?'), findsOneWidget);

      await _tap(tester, 'Ayuda');
      expect(
        find.text(
          'Elegí qué pasó con tu acceso para resolverlo sin compartir códigos ni datos por canales grupales:',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('¿Quién sos?'), findsOneWidget);

      await _tap(tester, 'Continuar');
      expect(find.textContaining('Escribí tu nombre y apellidos'), findsOneWidget);
      await _type(tester, 'Nombre', 'Lucía');
      await _type(tester, 'Apellidos', 'Mendoza');
      await _tap(tester, 'Continuar');
      expect(find.text('Tu correo de acceso'), findsOneWidget);

      await _type(tester, 'Correo institucional', 'invitada.cca@example.org');
      await _type(tester, 'Contraseña nueva', 'corta');
      await _tap(tester, 'Crear mi cuenta');
      expect(find.textContaining('al menos 8 caracteres'), findsOneWidget);
      await _type(tester, 'Contraseña nueva', 'Clave-Ficticia-1');
      await _type(tester, 'Repetí la contraseña', 'Clave-Ficticia-2');
      await _tap(tester, 'Crear mi cuenta');
      expect(find.text('Las dos contraseñas no coinciden.'), findsOneWidget);
      await _type(tester, 'Repetí la contraseña', 'Clave-Ficticia-1');
      await _tap(tester, 'Crear mi cuenta');
      expect(find.text('Confirmá tu correo'), findsOneWidget);

      await _tap(tester, 'Reenviar enlace de confirmación');
      expect(find.textContaining('Reenviamos el enlace'), findsOneWidget);

      await _tap(tester, 'Ya confirmé mi correo');
      expect(
        find.textContaining('Todavía no vemos tu correo confirmado'),
        findsOneWidget,
      );

      // Cuenta confirmada pero aún sin membresía activa permanece bloqueada.
      backend.confirmEmail('invitada.cca@example.org');
      await _tap(tester, 'Ya confirmé mi correo');
      expect(find.text('Ingresá tu código'), findsOneWidget);
      final GoRouter router = GoRouter.of(
        tester.element(find.byType(StaffActivationScreen)),
      );
      router.go('/personal/direccion');
      await tester.pumpAndSettle();
      expect(find.text('Ingresá tu código'), findsOneWidget);

      await _tap(tester, 'Activar cuenta');
      expect(find.textContaining('Ingresá el código individual'), findsOneWidget);
      await _typeCode(tester, 'NO-EXISTE');
      await _tap(tester, 'Activar cuenta');
      expect(find.textContaining('No reconocemos ese código'), findsOneWidget);
      await _typeCode(tester, 'CCA-EXP-2026');
      await _tap(tester, 'Activar cuenta');
      expect(find.textContaining('ya venció'), findsOneWidget);
      await _typeCode(tester, 'CCA-REV-2026');
      await _tap(tester, 'Activar cuenta');
      expect(find.textContaining('fue revocado'), findsOneWidget);

      await _typeCode(tester, 'cca-dir-2026');
      await _tap(tester, 'Activar cuenta');
      expect(find.text('Dirección del centro'), findsOneWidget);
      expect(find.text('Colegio Centro América — Demo'), findsOneWidget);

      // El código es de un solo uso.
      final preview = await backend.previewActivation('CCADIR2026');
      expect(preview.error, 'activation_code_already_used');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('perfil, disponibilidad y ayuda con acceso funcionan en vivo', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await signIn(tester, 'escucha.demo@example.org');
    await _tap(tester, 'Colegio de prueba A');
    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('escucha.demo@example.org'), findsOneWidget);

    await _tap(tester, 'Disponible para nuevas alertas');
    expect(find.text('Disponibilidad y avisos'), findsOneWidget);
    expect(find.text('Pantalla bloqueada'), findsOneWidget);
    await _tap(tester, 'Recibir nuevas alertas');
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isFalse,
      reason: 'Switch should toggle off when tapped',
    );
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Pausada para nuevas alertas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iniciar sesión bloquea cuentas sin código canjeado y ofrece continuar registro',
    (WidgetTester tester) async {
      final DemoStaffBackend backend = await open(tester);
      await backend.signUp(
        email: 'invitada.cca@example.org',
        password: DemoStaffBackend.demoPassword,
      );
      backend.confirmEmail('invitada.cca@example.org');
      await backend.signOut();

      await signIn(tester, 'invitada.cca@example.org');
      expect(
        find.textContaining('todavía no completó su registro con el código'),
        findsOneWidget,
      );
      await _tap(tester, 'Continuar mi registro con código');
      expect(find.text('Ingresá tu código'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sin conexión informa el fallo y no entra', (
    WidgetTester tester,
  ) async {
    final DemoStaffBackend backend = await open(tester);
    backend.offline = true;
    await signIn(tester, 'mined.demo@example.org');
    expect(
      find.textContaining('Revisá tu conexión a internet'),
      findsOneWidget,
    );
    backend.offline = false;
    await _tap(tester, 'Iniciar sesión');
    expect(find.text('MINED central'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ingreso y activación caben en pantalla chica con texto grande', (
    WidgetTester tester,
  ) async {
    await open(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    await _tap(tester, 'Registrar cuenta');
    expect(find.text('¿Quién sos?'), findsOneWidget);
    await _tap(tester, 'Ayuda');
    expect(find.text('Reenviar enlace de confirmación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'solicitud extendida pre-login excluye MINED y se aprueba en el panel MINED',
    (WidgetTester tester) async {
      await open(tester);
      GoRouter.of(
        tester.element(find.byType(StaffLoginScreen)),
      ).push('/personal/solicitar');
      await tester.pumpAndSettle();
      expect(find.text('Solicitar acceso de personal'), findsOneWidget);
      expect(find.textContaining('Supervisor MINED'), findsNothing);

      await _type(tester, 'Nombre completo', 'Elena Torres Gómez');
      await _type(
        tester,
        'Correo institucional o de contacto',
        'elena.torres@example.org',
      );
      await _tap(tester, 'Enviar solicitud al MINED');
      expect(find.text('Solicitud enviada'), findsOneWidget);

      await _tap(tester, 'Volver al ingreso');
      await signIn(tester, 'mined.demo@example.org');
      await _tap(tester, 'Invitaciones de personal');
      expect(find.text('Por aprobar (1)'), findsOneWidget);
      await _tap(tester, 'Por aprobar (1)');
      expect(find.text('Elena Torres Gómez'), findsOneWidget);
      await _tap(tester, 'Aprobar y emitir');
      expect(find.text('Código de activación emitido'), findsOneWidget);
      await _tap(tester, 'Listo');
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'retorno automático tras confirmar correo avanza al paso 4 y cada paso '
    'tiene máximo 2 botones',
    (WidgetTester tester) async {
      final DemoStaffBackend backend = await open(tester);
      await _tap(tester, 'Registrar cuenta');

      int actionButtonCount() {
        final Finder scope = find.byType(StaffActivationScreen);
        return find
                .descendant(of: scope, matching: find.byType(FilledButton))
                .evaluate()
                .length +
            find
                .descendant(of: scope, matching: find.byType(OutlinedButton))
                .evaluate()
                .length +
            find
                .descendant(of: scope, matching: find.byType(TextButton))
                .evaluate()
                .length;
      }

      // Paso 1: máximo 2 botones.
      expect(actionButtonCount(), lessThanOrEqualTo(2));
      await _type(tester, 'Nombre', 'Lucía');
      await _type(tester, 'Apellidos', 'Mendoza');
      await _tap(tester, 'Continuar');

      // Paso 2: máximo 2 botones.
      expect(find.text('Tu correo de acceso'), findsOneWidget);
      expect(actionButtonCount(), lessThanOrEqualTo(2));

      await _type(tester, 'Correo institucional', 'invitada.cca@example.org');
      await _type(tester, 'Contraseña nueva', 'Clave-Ficticia-1');
      await _type(tester, 'Repetí la contraseña', 'Clave-Ficticia-1');
      await _tap(tester, 'Crear mi cuenta');
      expect(find.text('Confirmá tu correo'), findsOneWidget);

      // Paso 3: máximo 2 botones.
      expect(actionButtonCount(), lessThanOrEqualTo(2));

      // Simula retorno por deep link setu://login-callback mientras Auth emite
      // la confirmación asíncrona después de montar la pantalla.
      final GoRouter router = GoRouter.of(
        tester.element(find.byType(StaffActivationScreen)),
      );
      router.go('setu://login-callback?code=demo-pkce');
      await tester.pumpAndSettle();
      backend.simulateLoginCallback('invitada.cca@example.org');
      await tester.pumpAndSettle();

      expect(find.text('Ingresá tu código'), findsOneWidget);
      // Paso 4: máximo 2 botones.
      expect(actionButtonCount(), lessThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  final Finder field = find.descendant(
    of: find.byType(StaffActivationScreen),
    matching: find.byType(TextField),
  );
  await tester.enterText(field.first, code);
  await tester.pump();
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
