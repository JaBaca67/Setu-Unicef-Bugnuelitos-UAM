import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/features/piece/piece_editor_screen.dart';
import 'package:cureando_mobile/features/piece/student_piece.dart';
import 'package:cureando_mobile/features/piece/student_profile_screen.dart';
import 'package:cureando_mobile/features/school_access/school_location.dart';
import 'package:cureando_mobile/features/school_access/student_session.dart';
import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/theme/app_theme.dart';
import 'package:cureando_mobile/shared/widgets/setu_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements LocalStorePersistence {
  Map<String, Object?>? data;

  @override
  Future<Map<String, Object?>?> load() async => data;

  @override
  Future<void> save(Map<String, Object?> value) async => data = value;
}

CureandoApp _app({
  required _MemoryStore sessionStore,
  _MemoryStore? progressStore,
  SupportFlow? support,
  SchoolResolver? resolver,
  math.Random? pieceRandom,
}) => CureandoApp(
  checkSchoolProximity: () async => SchoolProximity.nearby,
  studentSession: StudentSession(
    openStore: () async => sessionStore,
    resolver: resolver,
  ),
  supportFlow: support ?? SupportFlow(openStore: () async => _MemoryStore()),
  learningProgress: LearningProgress(
    openStore: () async => progressStore ?? _MemoryStore(),
    now: () => DateTime(2026, 11, 13),
  ),
  pieceRandom: pieceRandom,
);

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

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(392, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

Future<void> _enterSchool(WidgetTester tester, String code) async {
  await _tapLabel(tester, 'Ingreso estudiantil');
  await _tapLabel(tester, 'Escribir código');
  await tester.enterText(find.byType(TextField), code);
  await _tapLabel(tester, 'Entrar');
  await _tapLabel(tester, 'Comprobar cercanía');
  await _tapLabel(tester, 'Continuar');
}

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

  group('SetuBottomNav', () {
    Future<List<HomeSection>> pumpNav(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      final List<HomeSection> opened = <HomeSection>[];
      HomeSection selected = HomeSection.inicio;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Scaffold(
                bottomNavigationBar: SetuBottomNav(
                  selected: selected,
                  onSelected: (HomeSection section) => setState(() {
                    opened.add(section);
                    selected = section;
                  }),
                ),
              ),
            ),
          ),
        ),
      );
      return opened;
    }

    testWidgets('tocar una pestaña la abre y la marca como seleccionada', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final List<HomeSection> opened = await pumpNav(tester);
      await tester.tap(find.text('Ayuda'));
      await tester.pumpAndSettle();
      expect(opened, <HomeSection>[HomeSection.ayuda]);
      final SetuNavIcon active = tester.widget<SetuNavIcon>(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is SetuNavIcon && widget.section == HomeSection.ayuda,
        ),
      );
      final SetuNavIcon inactive = tester.widget<SetuNavIcon>(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is SetuNavIcon && widget.section == HomeSection.inicio,
        ),
      );
      expect(active.color, CureandoTheme.blue);
      expect(active.color.a, greaterThan(inactive.color.a));
      final Text activeLabel = tester.widget<Text>(find.text('Ayuda'));
      final Text inactiveLabel = tester.widget<Text>(find.text('Inicio'));
      expect(activeLabel.style!.color, active.color);
      expect(
        activeLabel.style!.fontWeight!.value,
        greaterThan(inactiveLabel.style!.fontWeight!.value),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      final Finder capsule = find.descendant(
        of: find.byKey(const ValueKey<String>('nav-indicator')),
        matching: find.byType(DecoratedBox),
      );
      final BoxDecoration decoration =
          tester.widget<DecoratedBox>(capsule).decoration as BoxDecoration;
      expect(decoration.gradient!.colors.first.a, lessThan(.5));
      expect(decoration.gradient!.colors.last.a, lessThan(.04));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ayuda')),
        isSemantics(
          label: 'Ayuda',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('cada ícono y su etiqueta quedan centrados en su cuarto', (
      WidgetTester tester,
    ) async {
      await pumpNav(tester);
      final Rect bar = tester.getRect(find.byType(GestureDetector).first);
      final double slot = bar.width / HomeSection.values.length;
      for (final HomeSection section in HomeSection.values) {
        final double center = bar.left + slot * (section.index + .5);
        final Rect icon = tester.getRect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is SetuNavIcon && widget.section == section,
          ),
        );
        final Rect label = tester.getRect(find.text(section.label));
        expect(icon.center.dx, closeTo(center, .5));
        expect(label.center.dx, closeTo(center, .5));
        // El bloque ícono + etiqueta queda centrado en el alto de la barra.
        expect((icon.top + label.bottom) / 2, closeTo(bar.center.dy, .5));
      }
    });

    testWidgets('deslizar el dedo mueve la cápsula y abre al soltar', (
      WidgetTester tester,
    ) async {
      final List<HomeSection> opened = await pumpNav(
        tester,
        reduceMotion: true,
      );
      final Finder capsule = find.byType(AnimatedAlign);
      final double start = tester.getCenter(find.text('Inicio')).dx;
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Inicio')),
      );
      await gesture.moveTo(tester.getCenter(find.text('Información')));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('Actividades')));
      await tester.pump();
      // La cápsula sigue al dedo antes de soltar y todavía no se abre nada.
      expect(
        tester.widget<AnimatedAlign>(capsule).alignment,
        isNot(const Alignment(-1, 0)),
      );
      expect(opened, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(opened, <HomeSection>[HomeSection.actividades]);
      expect(
        tester.widget<AnimatedAlign>(capsule).alignment,
        Alignment(-1 + 2 * 2 / 3, 0),
      );
      expect(tester.getCenter(find.text('Actividades')).dx, greaterThan(start));
    });
  });

  test(
    'el nivel, el catálogo de nombres y la migración funcionan sin datos reales',
    () async {
      DateTime now = DateTime(2026, 11, 10);
      final LearningProgress progress = LearningProgress(
        openStore: () async => _MemoryStore(),
        now: () => now,
      );
      addTearDown(progress.dispose);
      await progress.open();
      expect(progress.level, 1);
      expect(progress.levelTitle, 'Curioso');
      for (int day = 10; day <= 12; day++) {
        now = DateTime(2026, 11, day);
        await progress.completeQuestion(progress.today);
        await progress.completeResource('lectura-$day');
      }
      now = DateTime(2026, 11, 20);
      await progress.completeQuestion(progress.today);
      await progress.completeResource('lectura-20');
      // 4 preguntas (40) + 4 lecturas (20) = 60 XP.
      expect(progress.xp, 60);
      expect(progress.level, 2);
      expect(progress.levelTitle, 'Explorador');
      expect(progress.levelXp, 10);
      expect(progress.streak, 1);
      expect(progress.bestStreak, 3);
      expect(progress.completedCount, 8);

      // Concordancia de género y catálogo cerrado sin duplicados.
      expect(
        const PieceName(
          PieceNameNoun.chispa,
          PieceNameTrait.cosmico,
        ).displayName,
        'Chispa Cósmica',
      );
      expect(
        const PieceName(
          PieceNameNoun.cometa,
          PieceNameTrait.cosmico,
        ).displayName,
        'Cometa Cósmico',
      );
      final List<String> names = PieceName.all
          .map((PieceName n) => n.displayName)
          .toList();
      expect(names.length, 144);
      expect(names.toSet().length, 144);
      expect(PieceName.match('  pulgin   VALIENTE '), PieceName.initial);
      expect(PieceName.match('Nombre Libre Demo'), isNull);

      const StudentPiece unnamed = StudentPiece(
        shape: PieceShape.star,
        color: PieceColor.pink,
        name: null,
      );
      expect(unnamed.displayName, isNull);
      expect(unnamed.toJson().containsKey('displayName'), isFalse);

      // Migración de perfil anterior: conserva apariencia y borra el apodo libre.
      final _MemoryStore legacyStore = _MemoryStore();
      legacyStore.data = <String, Object?>{
        'version': 1,
        'school': localSchoolCatalog.first.toJson(),
        'piece': <String, Object?>{
          'displayName': 'Apodo Libre Anterior',
          'shape': 'flower',
          'color': 'blue',
          'accessories': <String>['bowTie'],
        },
      };
      final StudentSession session = StudentSession(
        openStore: () async => legacyStore,
      );
      addTearDown(session.dispose);
      await session.open();
      expect(session.piece.value.shape, PieceShape.flower);
      expect(session.piece.value.color, PieceColor.blue);
      expect(session.piece.value.accessories, <PieceAccessory>{
        PieceAccessory.bowTie,
      });
      expect(session.piece.value.name, isNull);
      final Map<String, Object?> savedPiece =
          (legacyStore.data!['piece']! as Map<Object?, Object?>)
              .cast<String, Object?>();
      expect(savedPiece.containsKey('displayName'), isFalse);
      expect(savedPiece['shape'], 'flower');
    },
  );

  test(
    'el código se valida en la plataforma y sin red usa el catálogo',
    () async {
      final List<String> asked = <String>[];
      bool offline = false;
      final StudentSession session = StudentSession(
        openStore: () async => _MemoryStore(),
        resolver: (String code) async {
          asked.add(code);
          if (offline) throw StateError('sin red');
          return code == 'NUEVO1'
              ? const ConfirmedSchool(
                  id: 'remoto',
                  publicCode: 'NUEVO1',
                  name: 'Colegio Centro América — Demo',
                  municipality: 'Managua',
                  department: 'Managua',
                )
              : null;
        },
      );
      addTearDown(session.dispose);
      final ConfirmedSchool? remote = await session.resolve(' nuev-o1 '.trim());
      expect(asked, <String>['NUEVO1']);
      expect(remote?.displayName, 'Colegio Centro América');
      expect(remote?.crestAsset, isNotNull);
      // La plataforma respondió que no existe: no se usa el catálogo local.
      expect(await session.resolve('AULA24'), isNull);
      offline = true;
      final ConfirmedSchool? local = await session.resolve('aula24');
      expect(local?.publicCode, 'AULA24');
      expect(local?.crestAsset, isNull);
      expect(await session.resolve('AULA00'), isNull);
    },
  );

  testWidgets(
    'primer ingreso, persistencia al reabrir, alertas y salir del colegio',
    (WidgetTester tester) async {
      _useTallView(tester);
      const ValueKey<String> captureKey = ValueKey<String>('profile-capture');
      final _MemoryStore sessionStore = _MemoryStore();
      final _MemoryStore progressStore = _MemoryStore();
      final _MemoryStore alertStore = _MemoryStore();
      SupportFlow support() => SupportFlow(openStore: () async => alertStore);
      final SupportFlow firstSupport = support();
      final SupportFlow secondSupport = support();

      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: _app(
            sessionStore: sessionStore,
            progressStore: progressStore,
            support: firstSupport,
            pieceRandom: math.Random(7),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ingreso estudiantil'), findsOneWidget);
      expect(find.text('Personal autorizado'), findsOneWidget);
      await _enterSchool(tester, 'AULA26');
      expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
      expect(
        (sessionStore.data?['school'] as Map<String, Object?>?)?['publicCode'],
        'AULA26',
      );

      // Primer ingreso a «Mi perfil»: datos reales en cero, accesorios y colegio al final.
      await tester.tap(find.byTooltip('Abrir mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Pulgin Valiente'), findsOneWidget);
      expect(find.text('Gorra amarilla'), findsOneWidget);
      expect(find.text('Lentes azules'), findsOneWidget);
      expect(find.text('Corbatín rosado'), findsNothing);
      expect(find.text('Racha de 0 días'), findsOneWidget);
      expect(find.text('0 XP'), findsOneWidget);
      expect(find.text('Nivel 1 · Curioso'), findsOneWidget);
      expect(
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value,
        0,
      );
      await _capture(tester, captureKey, 'mi-perfil-inicial');

      // Tocar un accesorio equipado abre el editor directo en «Accesorios».
      await _tapLabel(tester, 'Gorra amarilla');
      expect(find.text('Mi pieza'), findsOneWidget);
      expect(find.text('Corbatín'), findsOneWidget);

      // Cambiar a «Nombre», probar «Al azar» y elegir «Chispa Cósmica».
      await _tapLabel(tester, 'Nombre');
      await _capture(tester, captureKey, 'mi-pieza-nombre');
      await _tapLabel(tester, 'Al azar');
      expect(find.text('Pulgin Valiente'), findsNothing);
      await _tapLabel(tester, 'Guardar mi pieza');
      expect(find.text('Pieza guardada en este teléfono.'), findsOneWidget);
      final String chosenName =
          ((sessionStore.data?['piece']! as Map<Object?, Object?>)['displayName'])!
              as String;
      expect(find.text(chosenName), findsOneWidget);

      // Volver a Inicio y enviar una alerta con el nombre de juego elegido.
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      await _tapLabel(tester, 'Pedir apoyo');
      await _tapLabel(tester, 'Enviar una alerta');
      await _tapLabel(tester, 'Necesito hablar');
      await _tapLabel(tester, 'Continuar');
      await _tapLabel(tester, 'Me pasó a mí');
      await _tapLabel(tester, 'Continuar');
      await _tapLabel(tester, 'Revisar alerta');
      await _tapLabel(tester, 'Enviar alerta');
      final Map<Object?, Object?> delivery =
          alertStore.data!['delivery']! as Map<Object?, Object?>;
      expect(delivery['schoolCode'], 'AULA26');
      expect(
        (delivery['piece']! as Map<Object?, Object?>)['displayName'],
        chosenName,
      );
      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();

      // Al reabrir la app entra directo al inicio y conserva pieza y nombre.
      await tester.pumpWidget(const SizedBox.shrink());
      firstSupport.dispose();
      await tester.pumpWidget(
        _app(
          sessionStore: sessionStore,
          progressStore: progressStore,
          support: secondSupport,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
      expect(find.text('Ingreso estudiantil'), findsNothing);

      await tester.tap(find.byTooltip('Abrir mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text(chosenName), findsOneWidget);

      // «Mi colegio y ajustes» despliega el colegio, confirmación y conserva todo al salir.
      await _tapLabel(tester, 'Mi colegio y ajustes');
      expect(find.text('Colegio Centro América · Managua'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Escudo del Colegio Centro América'),
        findsOneWidget,
      );
      await _tapLabel(tester, 'Salir del colegio');
      expect(find.text('¿Salir de este colegio?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(sessionStore.data?['school'], isNotNull);
      await _tapLabel(tester, 'Salir del colegio');
      await tester.tap(find.text('Salir del colegio').last);
      await tester.pumpAndSettle();
      expect(find.text('Ingreso estudiantil'), findsOneWidget);
      expect(sessionStore.data?['school'], isNull);
      expect(
        (sessionStore.data?['piece']! as Map<Object?, Object?>)['displayName'],
        chosenName,
      );
      await _tapLabel(tester, 'Ingreso estudiantil');
      expect(find.text('Confirmá tu colegio'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      secondSupport.dispose();
    },
  );

  testWidgets(
    'perfil anterior sin nombre válido, calendario de racha y barra con umbrales reales',
    (WidgetTester tester) async {
      _useTallView(tester);
      const ValueKey<String> captureKey = ValueKey<String>('legacy-capture');
      final _MemoryStore sessionStore = _MemoryStore();
      sessionStore.data = <String, Object?>{
        'version': 1,
        'school': localSchoolCatalog.first.toJson(),
        'piece': <String, Object?>{
          'displayName': 'Juanito Demo',
          'shape': 'star',
          'color': 'pink',
          'accessories': <String>[],
        },
      };
      final _MemoryStore progressStore = _MemoryStore();
      progressStore.data = <String, Object?>{
        'version': 1,
        'activeDays': <String>['2026-11-11', '2026-11-12', '2026-11-13'],
        'questionDays': <String>['2026-11-11', '2026-11-12', '2026-11-13'],
        'resources': <String>['res-1', 'res-2', 'res-3', 'res-4', 'res-5', 'res-6', 'res-7', 'res-8'],
      };
      final _MemoryStore alertStore = _MemoryStore();
      final SupportFlow support = SupportFlow(openStore: () async => alertStore);

      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: _app(
            sessionStore: sessionStore,
            progressStore: progressStore,
            support: support,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Abrir mi perfil'));
      await tester.pumpAndSettle();
      // Conserva apariencia sin accesorios, progreso real (3 días, 70 XP -> Nivel 2) y pide nombre.
      expect(find.text('Elegí un nombre de juego'), findsOneWidget);
      expect(find.text('Tu pieza no lleva accesorios.'), findsOneWidget);
      expect(find.text('Probar accesorios'), findsOneWidget);
      expect(find.text('Racha de 3 días'), findsOneWidget);
      expect(find.text('70 XP'), findsOneWidget);
      expect(find.text('Nivel 2 · Explorador'), findsOneWidget);
      expect(
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value,
        closeTo(0.4, 0.001),
      );
      await _capture(tester, captureKey, 'mi-perfil-sin-nombre-ni-accesorios');

      // «Ver mi racha» abre el calendario actual y puede enviar a Actividades.
      await _tapLabel(tester, 'Ver mi racha');
      expect(find.text('Mi racha'), findsOneWidget);
      expect(find.text('Noviembre 2026'), findsOneWidget);
      expect(find.text('70 XP'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      // «Elegí un nombre de juego» abre el editor en la pestaña «Nombre».
      await _tapLabel(tester, 'Elegí un nombre de juego');
      expect(
        find.textContaining('Usá un nombre de juego para tu pieza.'),
        findsOneWidget,
      );
      // Seleccionar solo una palabra deshabilita guardar hasta elegir la segunda.
      final Finder nounDropdown = find.byType(
        DropdownButtonFormField<PieceNameNoun>,
      );
      await tester.ensureVisible(nounDropdown);
      await tester.pumpAndSettle();
      await tester.tap(nounDropdown);
      await tester.pumpAndSettle();
      await _tapLabel(tester, 'Chispa');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Guardar mi pieza'),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.text('Elegí también el apodo para poder guardar.'),
        findsOneWidget,
      );
      // Volver atrás sin guardar conserva el estado anterior sin nombre válido.
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Elegí un nombre de juego'), findsOneWidget);

      // Nueva alerta mientras no elige nombre válido omite `displayName`.
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      await _tapLabel(tester, 'Pedir apoyo');
      await _tapLabel(tester, 'Enviar una alerta');
      await _tapLabel(tester, 'Necesito hablar');
      await _tapLabel(tester, 'Continuar');
      await _tapLabel(tester, 'Me pasó a mí');
      await _tapLabel(tester, 'Continuar');
      await _tapLabel(tester, 'Revisar alerta');
      await _tapLabel(tester, 'Enviar alerta');
      final Map<Object?, Object?> deliveryPiece =
          (alertStore.data!['delivery']! as Map<Object?, Object?>)['piece']!
              as Map<Object?, Object?>;
      expect(deliveryPiece.containsKey('displayName'), isFalse);
      expect(deliveryPiece['shape'], 'star');
      expect(deliveryPiece['color'], 'pink');
      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      support.dispose();
    },
  );

  testWidgets(
    'accesibilidad: nombre largo, texto al 200 % y reacción con movimiento reducido',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final _MemoryStore sessionStore = _MemoryStore();
      sessionStore.data = <String, Object?>{
        'version': 1,
        'school': localSchoolCatalog.first.toJson(),
        'piece': <String, Object?>{
          'displayName': 'Guardabarranco Solidario',
          'shape': 'puzzle',
          'color': 'green',
          'accessories': <String>[],
        },
      };
      const ValueKey<String> captureKey = ValueKey<String>('a11y-capture');
      final StudentSession session = StudentSession(
        openStore: () async => sessionStore,
      );
      await session.open();
      final LearningProgress progress = LearningProgress(
        openStore: () async => _MemoryStore(),
        now: () => DateTime(2026, 11, 13),
      );
      await progress.open();
      addTearDown(session.dispose);
      addTearDown(progress.dispose);

      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: CureandoTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true,
                textScaler: TextScaler.linear(2.0),
              ),
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => StudentProfileScreenWrapper(
                    session: session,
                    progress: progress,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Guardabarranco Solidario'), findsOneWidget);
      expect(find.text('Tu pieza no lleva accesorios.'), findsOneWidget);
      await _capture(tester, captureKey, 'mi-perfil-largo-200');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'probar accesorio muestra reacción en texto y respeta movimiento reducido',
    (WidgetTester tester) async {
      _useTallView(tester);
      final ValueNotifier<StudentPiece> piece = ValueNotifier<StudentPiece>(
        const StudentPiece(shape: PieceShape.puzzle, color: PieceColor.green),
      );
      addTearDown(piece.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: PieceEditorScreen(
              piece: piece,
              initialTab: PieceEditorTab.accessories,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Corbatín'));
      await tester.pump();
      expect(find.text('Tu pieza se puso el corbatín.'), findsOneWidget);
      await tester.tap(find.byTooltip('Corbatín'));
      await tester.pump();
      expect(find.text('Tu pieza se quitó el corbatín.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class StudentProfileScreenWrapper extends StatelessWidget {
  const StudentProfileScreenWrapper({
    super.key,
    required this.session,
    required this.progress,
  });

  final StudentSession session;
  final LearningProgress progress;

  @override
  Widget build(BuildContext context) =>
      StudentProfileScreen(session: session, progress: progress);
}
