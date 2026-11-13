import 'dart:io';
import 'dart:ui' as ui;
import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/school_access/school_location.dart';
import 'package:cureando_mobile/shared/mock/mock_cureando_gateway.dart';
import 'package:cureando_mobile/shared/platform/screen_security_controller.dart';
import 'package:cureando_mobile/shared/theme/app_theme.dart';
import 'package:cureando_mobile/shared/widgets/setu_brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
  const MethodChannel channel = MethodChannel(
    'dev.cureando.app/screen_security',
  );
  late bool secure;
  setUp(() {
    secure = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          if (call.method == 'setSecureScreen') {
            secure = call.arguments! as bool;
            return null;
          }
          if (call.method == 'isSecureScreenEnabled') return secure;
          throw PlatformException(code: 'unknown');
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets('abre la bienvenida y permite visitar y cerrar cada muestra', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(392, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const ValueKey<String> captureKey = ValueKey<String>('welcome-capture');
    await tester.pumpWidget(
      const RepaintBoundary(key: captureKey, child: CureandoApp()),
    );
    await tester.pumpAndSettle();
    final Finder title = find.text('Tu salud mental');
    expect(title, findsOneWidget);
    await _capture(tester, captureKey, 'e01-welcome');

    const Map<String, String> destinations = <String, String>{'Ayuda': 'Ayuda'};
    for (final MapEntry<String, String> destination in destinations.entries) {
      final Finder action = find.text(destination.key);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, destination.value), findsOneWidget);
      expect(find.text('Vista de demostración'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
    }

    await _tapLabel(tester, 'Cómo cuidamos tu información');
    expect(find.textContaining('equipo de escucha asignado'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'las casillas aceptan pegar el código y permiten comprobar cercanía',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CureandoApp(checkSchoolProximity: () async => SchoolProximity.nearby),
      );
      await tester.pumpAndSettle();
      await _tapLabel(tester, 'Usar código del colegio');
      expect(find.text('Confirmá tu colegio'), findsOneWidget);
      final ModalRoute<Object?>? route = ModalRoute.of(
        tester.element(find.text('Confirmá tu colegio')),
      );
      expect(route?.transitionDuration, const Duration(milliseconds: 260));
      await _tapLabel(tester, 'Escribir código');
      await tester.enterText(find.byType(TextField), 'aula-24');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'aula24',
      );
      await _tapLabel(tester, 'Entrar');
      expect(find.text('Colegio Centro América'), findsOneWidget);
      expect(find.text('Simular cercanía para la demo'), findsNothing);
      await _tapLabel(tester, 'Comprobar cercanía');
      expect(find.text('Colegio confirmado'), findsOneWidget);
      expect(find.text(SchoolProximity.nearby.message), findsOneWidget);
      await _tapLabel(tester, 'Continuar');
      expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
      expect(find.text('Pedir apoyo'), findsOneWidget);
      expect(secure, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el código manual permite corregir, reintentar y volver', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      CureandoApp(checkSchoolProximity: () async => SchoolProximity.outside),
    );
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Usar código del colegio');
    await _tapLabel(tester, 'Escribir código');
    await _tapLabel(tester, 'Entrar');
    expect(
      find.text('Ingresá los seis caracteres del código.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'AULA00');
    await _tapLabel(tester, 'Entrar');
    expect(find.textContaining('Ese código no corresponde'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' aula-24 ');
    await _tapLabel(tester, 'Entrar');
    await _tapLabel(tester, 'Comprobar cercanía');
    expect(find.text('Fuera de la zona de prueba'), findsOneWidget);
    await _tapLabel(tester, 'Explorar Información');
    expect(find.widgetWithText(AppBar, 'Información'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Reintentar');
    expect(find.text('Comprobar cercanía'), findsOneWidget);
    await _tapLabel(tester, 'Ahora no');
    expect(find.text('Escribir código'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la presentación simula cercanía sin llamar a ubicación', (
    WidgetTester tester,
  ) async {
    int requests = 0;
    await tester.pumpWidget(
      CureandoApp(
        allowSchoolSimulation: true,
        checkSchoolProximity: () async {
          requests++;
          return SchoolProximity.unavailable;
        },
      ),
    );
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Usar código del colegio');
    await _tapLabel(tester, 'Escribir código');
    await tester.enterText(find.byType(TextField), demoSchoolCode);
    await _tapLabel(tester, 'Entrar');
    await _tapLabel(tester, 'Simular cercanía para la demo');
    expect(find.text('Cercanía simulada'), findsOneWidget);
    expect(find.text('Colegio confirmado'), findsNothing);
    expect(requests, 0);
    await _tapLabel(tester, 'Continuar');
    expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
  });

  test(
    'la zona se confirma solo cuando el margen de precisión queda adentro',
    () {
      expect(normalizeSchoolCode(' aula-24 '), demoSchoolCode);
      expect(
        normalizeSchoolCode('https://example.org/AULA24'),
        isNot(demoSchoolCode),
      );
      expect(
        classifySchoolDistance(distanceMeters: 140, accuracyMeters: 10),
        SchoolProximity.nearby,
      );
      expect(
        classifySchoolDistance(distanceMeters: 145, accuracyMeters: 10),
        SchoolProximity.imprecise,
      );
      expect(
        classifySchoolDistance(distanceMeters: 165, accuracyMeters: 10),
        SchoolProximity.outside,
      );
      expect(
        classifySchoolDistance(distanceMeters: 5, accuracyMeters: 200),
        SchoolProximity.imprecise,
      );
    },
  );

  testWidgets('respeta movimiento reducido y habilita capturas en modo local', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const CureandoApp(allowDesignCapture: true));
    await tester.pumpAndSettle();
    expect(secure, isFalse);
    await _tapLabel(tester, 'Usar código del colegio');
    final ModalRoute<Object?>? route = ModalRoute.of(
      tester.element(find.text('Confirmá tu colegio')),
    );
    expect(route?.transitionDuration, Duration.zero);
    expect(route?.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('la bienvenida permite abrir privacidad con texto al 200 %', (
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
    await _tapLabel(tester, 'Cómo cuidamos tu información');
    expect(find.textContaining('equipo de escucha asignado'), findsOneWidget);
    final Finder close = find.text('Cerrar');
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.textContaining('equipo de escucha asignado'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'SéTú muestra identidad y almacenamiento; responde a la interacción',
    (WidgetTester tester) async {
      const ValueKey<String> captureKey = ValueKey<String>('qa-capture');
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: CureandoApp(
            gateway: MockCureandoGateway(),
            showM1Verification: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, captureKey, 'm1-home');
      expect(find.byType(SetuBrandMark), findsOneWidget);
      expect(find.text('Almacenamiento local cifrado listo.'), findsOneWidget);
      await tester.ensureVisible(find.text('Comprobar funcionamiento'));
      await tester.tap(find.text('Comprobar funcionamiento'));
      await tester.pumpAndSettle();
      await _capture(tester, captureKey, 'm1-controls');
      expect(
        find.text('¡Listo! La interfaz responde correctamente.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'protección requiere confirmación; cancelar conserva FLAG_SECURE',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CureandoApp(gateway: MockCureandoGateway(), showM1Verification: true),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Permitir capturas y proyección'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(secure, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permitir'));
      await tester.pumpAndSettle();
      expect(secure, isFalse);
      expect(
        find.textContaining('Capturas y proyección permitidas'),
        findsOneWidget,
      );
    },
  );

  testWidgets('texto de Android al 200% más Grande respeta pantalla pequeña', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      CureandoApp(gateway: MockCureandoGateway(), showM1Verification: true),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Grande +20%'));
    await tester.tap(find.text('Grande +20%'));
    await tester.pumpAndSettle();
    final BuildContext context = tester.element(find.text('Tu voz importa.'));
    expect(MediaQuery.textScalerOf(context).scale(16), closeTo(38.4, .01));
    await tester.ensureVisible(find.text('Comprobar funcionamiento'));
    await tester.tap(find.text('Comprobar funcionamiento'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text('¡Listo! La interfaz responde correctamente.'),
      findsOneWidget,
    );
  });

  test('tokens y combinaciones de texto conservan contraste mínimo', () {
    double ratio(Color a, Color b) {
      final double x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    expect(ratio(CureandoTheme.blue, Colors.white), greaterThanOrEqualTo(4.5));
    for (final Color c in <Color>[
      CureandoTheme.pink,
      CureandoTheme.yellow,
      CureandoTheme.green,
    ]) {
      expect(ratio(c, CureandoTheme.ink), greaterThanOrEqualTo(4.5));
    }
  });

  test('fallo de canal no comunica un cambio exitoso', () async {
    final ScreenSecurityController controller = ScreenSecurityController();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (MethodCall call) async => throw PlatformException(code: 'denied'),
        );
    await controller.setSecureScreen(false);
    expect(controller.enabled, isTrue);
    expect(controller.error, isNotNull);
    expect(controller.busy, isFalse);
    controller.dispose();
  });
}

Future<void> _tapLabel(WidgetTester tester, String label) async {
  final Finder finder = find.text(label);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, Key key, String name) async {
  if (!const bool.fromEnvironment('SETU_CAPTURE_QA')) return;
  final Finder capture = find.byKey(key);
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
