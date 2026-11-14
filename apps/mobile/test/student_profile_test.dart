import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/features/piece/student_piece.dart';
import 'package:cureando_mobile/features/school_access/school_location.dart';
import 'package:cureando_mobile/features/school_access/student_session.dart';
import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/widgets/setu_bottom_nav.dart';
import 'package:flutter/material.dart';
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
);

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
    'el nivel, la mejor racha y el apodo se calculan sin datos reales',
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

      expect(StudentPiece.cleanNickname('   '), StudentPiece.defaultNickname);
      expect(
        StudentPiece.cleanNickname('x' * 40).length,
        StudentPiece.maxNickname,
      );
      expect(
        StudentPiece.initial.copyWith(nickname: 'Luna').toJson()['displayName'],
        'Luna',
      );
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
    'el colegio confirmado persiste, llega a la alerta y se puede salir',
    (WidgetTester tester) async {
      _useTallView(tester);
      final _MemoryStore sessionStore = _MemoryStore();
      final _MemoryStore progressStore = _MemoryStore();
      final _MemoryStore alertStore = _MemoryStore();
      SupportFlow support() => SupportFlow(openStore: () async => alertStore);

      await tester.pumpWidget(
        _app(
          sessionStore: sessionStore,
          progressStore: progressStore,
          support: support(),
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

      // La alerta se registra en el colegio activo, no en uno fijo.
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
        'Pulgin Valiente',
      );
      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();

      // Al reabrir la app entra directo al inicio, sin pedir el código.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _app(
          sessionStore: sessionStore,
          progressStore: progressStore,
          support: support(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('¿Qué querés hacer hoy?'), findsOneWidget);
      expect(find.text('Ingreso estudiantil'), findsNothing);

      // El perfil muestra apodo, colegio con escudo, nivel y estadísticas.
      await tester.tap(find.byTooltip('Abrir mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Pulgin Valiente'), findsOneWidget);
      expect(find.text('Colegio Centro América · Managua'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Escudo del Colegio Centro América'),
        findsOneWidget,
      );
      expect(find.text('Nivel 1 · Curioso'), findsOneWidget);
      expect(find.text('0 / 50 XP'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      for (final String stat in <String>[
        'Racha actual',
        'Mejor racha',
        'XP total',
        'Actividades y lecturas',
      ]) {
        expect(find.text(stat), findsOneWidget);
      }

      // Salir pide confirmación y conserva la pieza guardada.
      await _tapLabel(tester, 'Cambiar o salir del colegio');
      expect(find.text('¿Salir de este colegio?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(sessionStore.data?['school'], isNotNull);
      await _tapLabel(tester, 'Cambiar o salir del colegio');
      await tester.tap(find.text('Salir del colegio'));
      await tester.pumpAndSettle();
      expect(find.text('Ingreso estudiantil'), findsOneWidget);
      expect(sessionStore.data?['school'], isNull);
      expect(sessionStore.data?['piece'], isNotNull);
      await _tapLabel(tester, 'Ingreso estudiantil');
      expect(find.text('Confirmá tu colegio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
