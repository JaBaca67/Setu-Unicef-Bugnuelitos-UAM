import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/home/activity_screens.dart';
import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/features/piece/student_piece.dart';
import 'package:cureando_mobile/features/school_access/student_session.dart';
import 'package:cureando_mobile/features/support/alert_screens.dart';
import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/theme/app_theme.dart';
import 'package:cureando_mobile/shared/widgets/setu_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _captureKey = ValueKey<String>('activities-qa');

void main() {
  setUpAll(() async {
    for (final weight in <String>['Regular', 'Medium', 'SemiBold', 'Bold']) {
      await (FontLoader(
        'Poppins',
      )..addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'Actividades muestra cinco tarjetas y abre las cinco rutas reales',
    (tester) async {
      _view(tester);
      final store = _Store();
      final session = StudentSession(
        openStore: () async => _Store(<String, Object?>{
          'version': 1,
          'school': localSchoolCatalog.first.toJson(),
        }),
      );
      await session.open();
      final progress = LearningProgress(
        openStore: () async => store,
        now: () => DateTime(2026, 11, 17),
      );
      addTearDown(progress.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _captureKey,
          child: CureandoApp(
            studentSession: session,
            learningProgress: progress,
            supportFlow: SupportFlow(openStore: () async => _Store()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SetuBottomNav),
          matching: find.text('Actividades'),
        ),
      );
      await tester.pumpAndSettle();
      const titles = <String>[
        'Rompecabezas del buen trato',
        'Semáforo de emociones',
        'Dados emocionales',
        'Pregunta libre',
        'Dibujo libre',
      ];
      for (final title in titles) {
        expect(find.bySemanticsLabel(title), findsOneWidget);
      }
      await _capture(tester, 'e06-actividades');
      for (int i = 0; i < titles.length; i++) {
        await _tap(tester, titles[i]);
        expect(find.byType(ActivityHeader), findsOneWidget);
        final element = tester.element(find.byType(ActivityHeader));
        expect(
          GoRouterState.of(element).uri.path,
          <String>[
            '/inicio/actividades/rompecabezas',
            '/inicio/actividades/semaforo',
            '/inicio/actividades/dados',
            '/inicio/actividades/pregunta',
            '/inicio/actividades/dibujo',
          ][i],
        );
        await _capture(
          tester,
          <String>[
            'e06e-rompecabezas',
            'e06a-semaforo',
            'e06b-dados',
            'e06c-pregunta',
            'e06d-dibujo',
          ][i],
        );
        await _tap(tester, 'Actividades');
        expect(find.byType(ActivityHeader), findsNothing);
      }
      // El banner de Inicio también llega al dado sin depender de la portada.
      await tester.tap(
        find.descendant(
          of: find.byType(SetuBottomNav),
          matching: find.text('Inicio'),
        ),
      );
      await tester.pumpAndSettle();
      final diceBanner = find.bySemanticsLabel('Dado de emociones');
      await tester.ensureVisible(diceBanner);
      await tester.pumpAndSettle();
      await tester.tap(diceBanner);
      await tester.pumpAndSettle();
      expect(find.byType(EmotionDiceScreen), findsOneWidget);
      await _tap(tester, 'Actividades');
      expect(progress.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Semáforo cambia la sugerencia y marca la selección', (
    tester,
  ) async {
    await _screen(tester, const TrafficLightScreen());
    await _tap(tester, 'Rojo');
    expect(
      find.text('Respirá hondo tres veces y buscá un lugar tranquilo.'),
      findsOneWidget,
    );
    await _tap(tester, 'Amarillo');
    expect(
      find.text('Probá ponerle un nombre a lo que sentís.'),
      findsOneWidget,
    );
    expect(
      find.text('Respirá hondo tres veces y buscá un lugar tranquilo.'),
      findsNothing,
    );
    await _capture(tester, 'e06a-semaforo-seleccion');
    await _tap(tester, 'Verde');
    expect(
      find.text('¡Qué bien! Fijate qué te ayudó a sentirte así.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dado anima, impide dobles lanzamientos y usa Random inyectado', (
    tester,
  ) async {
    final expected = diceEmotions[Random(12).nextInt(diceEmotions.length)];
    await _screen(tester, EmotionDiceScreen(random: Random(12)));
    await tester.ensureVisible(find.text('Lanzar el dado'));
    await tester.tap(find.text('Lanzar el dado'));
    await tester.pump();
    expect(find.text('Lanzando…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Te salió:'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Te salió: ${expected.name}'), findsOneWidget);
    expect(find.text(expected.prompt), findsOneWidget);
    await _capture(tester, 'e06b-dados-resultado');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pregunta cambia sin repetir y descarta respuesta al salir', (
    tester,
  ) async {
    await _screen(tester, const FreeQuestionScreen());
    expect(find.text(freeQuestions.first), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Respuesta ficticia temporal',
    );
    await _tap(tester, 'Otra pregunta');
    expect(find.text(freeQuestions[1]), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), 'Otra respuesta ficticia');
    await _tap(tester, 'Terminar');
    expect(find.text('Actividad terminada'), findsOneWidget);
    await _tap(tester, 'Reabrir');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dibujo empieza vacío, dibuja, deshace y confirma borrador', (
    tester,
  ) async {
    await _screen(tester, const FreeDrawingScreen());
    DrawingPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byKey(const ValueKey<String>('drawing-canvas')),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as DrawingPainter;
    final canvas = find.byKey(const ValueKey<String>('drawing-canvas'));
    expect(painter().strokes, isEmpty);
    final top = tester.getTopLeft(canvas);
    await tester.dragFrom(top + const Offset(50, 50), const Offset(100, 60));
    await tester.pumpAndSettle();
    expect(painter().strokes.length, 1);
    expect(painter().strokes.single.points.length, greaterThan(1));
    await _capture(tester, 'e06d-dibujo-trazo');
    await _tap(tester, 'Deshacer');
    expect(painter().strokes, isEmpty);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final beforeDrawing = scroll.position.pixels;
    await tester.dragFrom(
      tester.getTopLeft(canvas) + const Offset(70, 40),
      const Offset(0, 80),
    );
    expect(scroll.position.pixels, beforeDrawing);
    await tester.pumpAndSettle();
    await _tap(tester, 'Borrador');
    await _tap(tester, 'Cancelar');
    expect(painter().strokes.length, 1);
    await _tap(tester, 'Borrador');
    await _tap(tester, 'Borrar todo');
    expect(painter().strokes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Rompecabezas permite reintento, encaja y completa tres escenas',
    (tester) async {
      await _screen(tester, const KindnessPuzzleScreen());
      await _tap(tester, 'Seguir jugando');
      expect(find.textContaining('Probá otra pieza'), findsOneWidget);
      await _tap(tester, 'Invitarle a jugar');
      expect(find.textContaining('¡Encajó!'), findsOneWidget);
      expect(
        tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).state,
        PuzzleBoardState.connected,
      );
      await _capture(tester, 'e06e-rompecabezas-encajo');
      await _tap(tester, 'Siguiente escena');
      expect(find.text('2 de 3'), findsOneWidget);
      expect(
        tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).state,
        PuzzleBoardState.disconnected,
      );
      await _tap(tester, 'Preguntarle si quiere ayuda');
      await _tap(tester, 'Siguiente escena');
      await _tap(tester, 'Pedir ayuda a una persona adulta');
      await _tap(tester, 'Siguiente escena');
      expect(find.text('¡Completaste el rompecabezas!'), findsOneWidget);
      await _capture(tester, 'e06e-rompecabezas-completo');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Alerta paso 2 usa personajes originales y chip en una línea', (
    tester,
  ) async {
    final flow = SupportFlow(openStore: () async => _Store());
    final piece = ValueNotifier<StudentPiece>(StudentPiece.initial);
    addTearDown(flow.dispose);
    addTearDown(piece.dispose);
    await _screen(tester, AlertRoleScreen(flow: flow, piece: piece));
    for (final asset in <String>['personaje-08', 'personaje-14']) {
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/brand/png/$asset.png',
        ),
        findsOneWidget,
      );
    }
    final tag = tester.widget<Text>(find.text('Testigo solidario'));
    expect(tag.maxLines, 1);
    expect(tag.style!.fontSize, 13);
    expect(
      find.ancestor(
        of: find.text('Testigo solidario'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
    await _capture(tester, 'alerta-paso2');
    await _tap(tester, 'Lo vi o supe de alguien');
    expect(flow.participation, Participation.witness);
    expect(tester.takeException(), isNull);
  });

  for (final page in <Widget>[
    const TrafficLightScreen(),
    const EmotionDiceScreen(),
    const FreeQuestionScreen(),
    const FreeDrawingScreen(),
    const KindnessPuzzleScreen(),
  ]) {
    testWidgets(
      '${page.runtimeType} conserva layout a 360 con texto grande y barra Android',
      (tester) async {
        await _screen(tester, page, scale: 2);
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _view(WidgetTester tester, {double scale = 1}) {
  tester.view.physicalSize = const Size(360, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _screen(
  WidgetTester tester,
  Widget screen, {
  double scale = 1,
}) async {
  _view(tester, scale: scale);
  final router = GoRouter(
    initialLocation: '/actividad',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Column(
            children: <Widget>[
              const Text('Actividad terminada'),
              TextButton(
                onPressed: () => context.push<void>('/actividad'),
                child: const Text('Reabrir'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/inicio',
        builder: (context, _) => Scaffold(
          body: Column(
            children: <Widget>[
              const Text('Actividad terminada'),
              TextButton(
                onPressed: () => context.push<void>('/actividad'),
                child: const Text('Reabrir'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(path: '/actividad', builder: (_, _) => screen),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: CureandoTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _Store implements LocalStorePersistence {
  _Store([this.data]);
  Map<String, Object?>? data;
  @override
  Future<Map<String, Object?>?> load() async => data;
  @override
  Future<void> save(Map<String, Object?> value) async {
    data = value;
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SETU_CAPTURE_QA')) return;
  final capture = find.byKey(_captureKey);
  await tester.runAsync<void>(() async {
    await precacheImage(
      const AssetImage('assets/welcome/campaign-pattern.png'),
      tester.element(capture),
    );
    for (final element
        in find
            .descendant(of: capture, matching: find.byType(Image))
            .evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync<void>(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(capture)
        .toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory('build/qa').create(recursive: true);
    await File('build/qa/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}
