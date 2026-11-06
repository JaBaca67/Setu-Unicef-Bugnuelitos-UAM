import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cureando_mobile/app.dart';
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

  testWidgets(
    'SéTú muestra identidad y almacenamiento; responde a la interacción',
    (WidgetTester tester) async {
      const ValueKey<String> captureKey = ValueKey<String>('qa-capture');
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: CureandoApp(gateway: MockCureandoGateway()),
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
      await tester.pumpWidget(CureandoApp(gateway: MockCureandoGateway()));
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
    await tester.pumpWidget(CureandoApp(gateway: MockCureandoGateway()));
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

Future<void> _capture(WidgetTester tester, Key key, String name) async {
  if (!const bool.fromEnvironment('SETU_CAPTURE_QA')) return;
  await tester.runAsync<void>(() async {
    final RenderRepaintBoundary boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(key));
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
