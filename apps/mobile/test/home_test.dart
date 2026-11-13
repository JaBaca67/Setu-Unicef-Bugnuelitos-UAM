import 'dart:io';
import 'dart:ui' as ui;

import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/features/home/student_activities.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/features/school_access/school_location.dart';
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
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          if (call.method == 'setSecureScreen') return null;
          if (call.method == 'isSecureScreenEnabled') return true;
          throw PlatformException(code: 'unknown');
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets('el inicio E03 muestra sus bloques y navega entre pestañas', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(392, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const ValueKey<String> captureKey = ValueKey<String>('home-capture');
    await tester.pumpWidget(RepaintBoundary(key: captureKey, child: _app()));
    await tester.pumpAndSettle();
    await _goHome(tester);

    expect(find.text('¡Hola!'), findsOneWidget);
    expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
    expect(find.text('Pedir apoyo'), findsOneWidget);
    expect(find.text('Racha de 0 días'), findsOneWidget);
    expect(find.text('0 XP'), findsOneWidget);
    expect(find.text('Explorá a tu ritmo'), findsOneWidget);
    expect(find.text('Ver todo'), findsNWidgets(2));
    expect(find.text('Entendé tus emociones'), findsOneWidget);
    expect(find.text('Convivencia escolar'), findsOneWidget);
    expect(find.text('Pregunta del día'), findsOneWidget);
    expect(find.text('Dado de emociones'), findsOneWidget);
    expect(find.text('Mi seguimiento'), findsNothing);
    expect(find.text('Seguimiento'), findsNothing);
    await _capture(tester, captureKey, 'e03-home');

    await _tapNav(tester, 'Información');
    expect(find.text('Catálogo de muestra'), findsOneWidget);
    expect(find.text('Acoso escolar'), findsOneWidget);
    await _tapNav(tester, 'Actividades');
    expect(find.text('Actividades de muestra'), findsOneWidget);
    expect(find.text('Pregunta del día'), findsOneWidget);
    await _tapNav(tester, 'Ayuda');
    expect(
      find.textContaining('recursos de ayuda verificados'),
      findsOneWidget,
    );
    await _tapNav(tester, 'Inicio');
    expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendario y racha reflejan pregunta y lecturas al reabrir', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    final MemoryProgressStore store = MemoryProgressStore();
    DateTime now = DateTime(2026, 11, 12, 14);
    const ValueKey<String> captureKey = ValueKey<String>('streak-capture');
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: _app(store: store, now: () => now),
      ),
    );
    await tester.pumpAndSettle();
    await _goHome(tester);

    await _tapLabel(tester, 'Racha de 0 días');
    expect(find.text('Mi racha'), findsOneWidget);
    expect(find.text('Noviembre 2026'), findsOneWidget);
    await _capture(tester, captureKey, 'e03-streak');
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Octubre 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Noviembre 2026'), findsOneWidget);
    await _tapLabel(tester, 'Ir a Actividades');
    expect(find.text('Actividades de muestra'), findsOneWidget);
    await _tapLabel(
      tester,
      'Todas las emociones son válidas; lo importante es cómo las expresamos.',
    );
    await _tapNav(tester, 'Inicio');
    expect(find.text('Racha de 1 día'), findsOneWidget);
    expect(find.text('10 XP'), findsOneWidget);

    await _tapLabel(tester, 'Entendé tus emociones');
    expect(find.text('Marcar como leída'), findsOneWidget);
    await _tapLabel(tester, 'Marcar como leída');
    expect(find.text('Lectura registrada'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('15 XP'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    now = DateTime(2026, 11, 13, 9);
    await tester.pumpWidget(_app(store: store, now: () => now));
    await tester.pumpAndSettle();
    await _goHome(tester);
    expect(find.text('Racha de 1 día'), findsOneWidget);
    expect(find.text('15 XP'), findsOneWidget);
    await _tapLabel(tester, 'Entendé tus emociones');
    await _tapLabel(tester, 'Marcar como leída');
    expect(find.text('Marcaste un día de aprendizaje.'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Racha de 2 días'), findsOneWidget);
    expect(find.text('15 XP'), findsOneWidget);
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await _tapLabel(tester, 'Racha de 2 días');
      expect(
        find.bySemanticsLabel(
          'viernes 13 de noviembre, hoy, actividad completada',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pedir apoyo abre la muestra con aviso y chat identificado', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _goHome(tester);
    await _tapLabel(tester, 'Pedir apoyo');
    expect(find.text('Cuéntanos lo que quieras compartir'), findsOneWidget);
    expect(find.text('Vista de muestra'), findsOneWidget);
    expect(
      find.textContaining('una persona autorizada esté disponible'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no incluye detalles de lo que contaste'),
      findsOneWidget,
    );
    await _tapLabel(tester, 'Ver cómo será el chat');
    expect(
      find.textContaining('nadie está conectado en esta demostración'),
      findsOneWidget,
    );
    expect(find.textContaining('No es un chat automático'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las tarjetas de Información abren el recurso de muestra', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _goHome(tester);
    await _tapLabel(tester, 'Entendé tus emociones');
    expect(find.text('Tema: Emociones'), findsOneWidget);
    expect(find.textContaining('Contenido propio de muestra'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Convivencia escolar');
    expect(find.textContaining('todavía no está empaquetado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la pregunta del día retroalimenta y el dado muestra emociones', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _goHome(tester);
    await _tapNav(tester, 'Actividades');
    await _tapLabel(
      tester,
      'Hay emociones malas que es mejor esconder siempre.',
    );
    expect(find.textContaining('probá de nuevo'), findsOneWidget);
    await _tapLabel(
      tester,
      'Todas las emociones son válidas; lo importante es cómo las expresamos.',
    );
    expect(find.text('¡Así es! Sumaste 10 XP.'), findsOneWidget);
    await _tapLabel(tester, 'Lanzar el dado');
    expect(find.text('Lanzar de nuevo'), findsOneWidget);
    final int emotionsShown = diceEmotions
        .where(
          (DiceEmotion emotion) =>
              find.text(emotion.name).evaluate().isNotEmpty,
        )
        .length;
    expect(emotionsShown, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el avatar se personaliza con opciones gráficas, sin foto', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _goHome(tester);
    await tester.tap(find.byTooltip('Personalizar tu avatar'));
    await tester.pumpAndSettle();
    expect(find.text('Tu avatar virtual'), findsOneWidget);
    expect(find.textContaining('No usamos fotos'), findsOneWidget);
    await _tapLabel(tester, 'Espiral');
    await _tapLabel(tester, 'Verde');
    await _tapLabel(tester, 'Guardar avatar');
    expect(find.text('Tu avatar virtual'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Espiral de color verde')),
      findsOneWidget,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla chica con texto al 200 % conserva cada acción', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _goHome(tester);
    await _tapLabel(tester, 'Racha de 0 días');
    expect(find.text('Mi racha'), findsOneWidget);
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Octubre 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Pedir apoyo');
    expect(find.text('Cuéntanos lo que quieras compartir'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await _tapNav(tester, 'Actividades');
    expect(find.text('Actividades de muestra'), findsOneWidget);
    await _tapNav(tester, 'Ayuda');
    await _tapLabel(tester, 'Pedir apoyo');
    expect(find.text('Cuéntanos lo que quieras compartir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movimiento reducido entra al inicio sin transición', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _goHome(tester);
    final ModalRoute<Object?>? route = ModalRoute.of(
      tester.element(find.text('¿Qué querés hacer hoy?')),
    );
    expect(route?.transitionDuration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}

CureandoApp _app({MemoryProgressStore? store, DateTime Function()? now}) =>
    CureandoApp(
      checkSchoolProximity: () async => SchoolProximity.nearby,
      learningProgress: LearningProgress(
        openStore: () async => store ?? MemoryProgressStore(),
        now: now ?? () => DateTime(2026, 11, 12),
      ),
    );

class MemoryProgressStore implements LocalStorePersistence {
  Map<String, Object?>? _data;

  @override
  Future<Map<String, Object?>?> load() async => _data;

  @override
  Future<void> save(Map<String, Object?> value) async => _data = value;
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(392, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _goHome(WidgetTester tester) async {
  await _tapLabel(tester, 'Usar código del colegio');
  await _tapLabel(tester, 'Escribir código');
  await tester.enterText(find.byType(TextField), demoSchoolCode);
  await _tapLabel(tester, 'Entrar');
  await _tapLabel(tester, 'Comprobar cercanía');
  await _tapLabel(tester, 'Continuar');
}

Future<void> _tapNav(WidgetTester tester, String label) async {
  final Finder finder = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
    await precacheImage(
      const AssetImage('assets/welcome/campaign-pattern.png'),
      tester.element(capture),
    );
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
