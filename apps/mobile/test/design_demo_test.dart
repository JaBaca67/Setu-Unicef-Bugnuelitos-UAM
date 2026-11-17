import 'package:cureando_mobile/features/home/information_tab.dart';
import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/features/home/streak_screen.dart';
import 'package:cureando_mobile/features/home/student_home_screen.dart';
import 'package:cureando_mobile/features/piece/piece_editor_screen.dart';
import 'package:cureando_mobile/features/piece/student_piece.dart';
import 'package:cureando_mobile/features/piece/student_profile_screen.dart';
import 'package:cureando_mobile/features/school_access/student_session.dart';
import 'package:cureando_mobile/features/staff/demo_staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_backend.dart';
import 'package:cureando_mobile/features/staff/staff_profile_screens.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/theme/app_theme.dart';
import 'package:cureando_mobile/shared/widgets/campaign_screen.dart';
import 'package:cureando_mobile/shared/widgets/setu_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final FontLoader font = FontLoader('Poppins');
    for (final String weight in <String>[
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
  });

  testWidgets(
    'Inicio muestra dos banners sin texto duplicado y con etiquetas',
    (WidgetTester tester) async {
      _view(tester);
      final LearningProgress progress = _progress();
      final ValueNotifier<StudentPiece> piece = ValueNotifier<StudentPiece>(
        StudentPiece.initial,
      );
      addTearDown(progress.dispose);
      addTearDown(piece.dispose);
      await tester.pumpWidget(
        _app(StudentHomeScreen(progress: progress, piece: piece)),
      );
      await tester.pumpAndSettle();
      final Finder question = _asset('assets/home/banner-pregunta-del-dia.png');
      final Finder dice = _asset('assets/home/banner-dado-emociones.png');
      expect(question, findsOneWidget);
      expect(dice, findsOneWidget);
      expect(tester.getRect(question).top, tester.getRect(dice).top);
      expect(
        tester.getRect(question).right,
        lessThan(tester.getRect(dice).left),
      );
      expect(find.text('Pregunta del día'), findsNothing);
      expect(find.text('Dado de emociones'), findsNothing);
      final Finder label = find.bySemanticsLabel('Dado de emociones');
      await tester.ensureVisible(label);
      await tester.pumpAndSettle();
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(find.text('Actividades de muestra'), findsOneWidget);
      expect(find.text('Dado de emociones'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Información tiene búsqueda compacta y carrusel independiente del PageView',
    (WidgetTester tester) async {
      _view(tester);
      final LearningProgress progress = _progress();
      final ValueNotifier<StudentPiece> piece = ValueNotifier<StudentPiece>(
        StudentPiece.initial,
      );
      addTearDown(progress.dispose);
      addTearDown(piece.dispose);
      await tester.pumpWidget(
        _app(
          StudentHomeScreen(
            progress: progress,
            piece: piece,
            sectionRequest: HomeSectionRequest(HomeSection.informacion),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder search = find.byType(TextField);
      expect(tester.getSize(search).height, inInclusiveRange(44, 48));
      expect(tester.widget<TextField>(search).decoration!.suffixIcon, isNull);
      expect(find.textContaining('Catálogo de muestra'), findsNothing);
      final Finder carousel = find.byKey(
        const ValueKey<String>('information-categories'),
      );
      expect(
        tester.widget<SingleChildScrollView>(carousel).scrollDirection,
        Axis.horizontal,
      );
      final List<double> tops = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .map((ChoiceChip chip) => tester.getTopLeft(find.byWidget(chip)).dy)
          .toList();
      expect(tops.every((double top) => top == tops.first), isTrue);
      await tester.drag(carousel, const Offset(-260, 0));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SetuBottomNav>(find.byType(SetuBottomNav)).selected,
        HomeSection.informacion,
      );
      final Finder support = find.widgetWithText(ChoiceChip, 'Apoyo');
      expect(support.hitTestable(), findsOneWidget);
      await tester.tap(support);
      await tester.pumpAndSettle();
      expect(find.text('2 disponibles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Información deja el título directo sobre el banner completo', (
    WidgetTester tester,
  ) async {
    _view(tester);
    await tester.pumpWidget(
      _app(
        const CampaignScreen(
          header: InformationHeader(),
          body: SizedBox(height: 600),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Finder title = find.text('Información');
    expect(
      find.ancestor(of: title, matching: find.byType(DecoratedBox)),
      findsOneWidget,
    ); // Solo el fondo de campaña.
    expect(tester.widget<Text>(title).style!.shadows, isNotEmpty);
    final Image figure = tester.widget<Image>(
      _asset('assets/home/info/e10a_header_figures.png'),
    );
    expect(figure.fit, BoxFit.contain);
    expect(
      tester.getSize(find.byType(InformationHeader)).height,
      greaterThanOrEqualTo(360 * 308 / 780),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'la cápsula sigue posiciones fraccionarias durante un swipe sin soltar',
    (WidgetTester tester) async {
      _view(tester);
      final LearningProgress progress = _progress();
      final ValueNotifier<StudentPiece> piece = ValueNotifier<StudentPiece>(
        StudentPiece.initial,
      );
      addTearDown(progress.dispose);
      addTearDown(piece.dispose);
      await tester.pumpWidget(
        _app(StudentHomeScreen(progress: progress, piece: piece)),
      );
      await tester.pumpAndSettle();
      final PageController controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      final TestGesture gesture = await tester.startGesture(
        const Offset(290, 260),
      );
      await gesture.moveBy(const Offset(-24, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      final double firstPage = controller.page!;
      expect(firstPage, greaterThan(0));
      expect(firstPage, lessThan(1));
      AnimatedAlign indicator() => tester.widget<AnimatedAlign>(
        find.byKey(const ValueKey<String>('nav-indicator')),
      );
      expect(
        (indicator().alignment as Alignment).x,
        closeTo(-1 + firstPage * 2 / 3, .001),
      );
      expect(indicator().duration, Duration.zero);
      await gesture.moveBy(const Offset(-110, 0));
      await tester.pump();
      expect(controller.page!, greaterThan(firstPage));
      expect(
        (indicator().alignment as Alignment).x,
        closeTo(-1 + controller.page! * 2 / 3, .001),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<SetuBottomNav>(find.byType(SetuBottomNav)).selected,
        HomeSection.informacion,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Mi racha usa su banner sin subheadline y conserva calendario y CTA',
    (WidgetTester tester) async {
      _view(tester);
      final LearningProgress progress = _progress();
      addTearDown(progress.dispose);
      await tester.pumpWidget(_app(StreakScreen(progress: progress)));
      await tester.pumpAndSettle();
      expect(_asset('assets/home/banner-racha.png'), findsOneWidget);
      expect(find.text('Mi racha'), findsOneWidget);
      expect(find.text('Cada día que participás suma.'), findsNothing);
      expect(find.text('Racha actual'), findsOneWidget);
      expect(find.text('XP acumulados'), findsOneWidget);
      expect(find.text('Noviembre 2026'), findsOneWidget);
      await tester.ensureVisible(find.text('Ir a Actividades'));
      await tester.pumpAndSettle();
      expect(find.text('Ir a Actividades').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final double scale in <double>[1, 2]) {
    testWidgets(
      'perfil y editor completos sobre Android de 48 px, escala $scale',
      (WidgetTester tester) async {
        _view(tester, scale: scale);
        final StudentSession session = StudentSession(
          openStore: () async => _Store(),
        );
        final LearningProgress progress = _progress();
        addTearDown(session.dispose);
        addTearDown(progress.dispose);
        await session.open();
        await session.resolve('AULA26');
        session.confirmCandidate();
        await tester.pumpWidget(
          _app(StudentProfileScreen(session: session, progress: progress)),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Mi colegio y ajustes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mi colegio y ajustes'));
        await tester.pumpAndSettle();
        _scrollToEnd(tester);
        await tester.pumpAndSettle();
        final Finder leave = find.widgetWithText(
          OutlinedButton,
          'Salir del colegio',
        );
        final double navTop = tester.getTopLeft(find.byType(SetuBottomNav)).dy;
        expect(tester.getBottomLeft(leave).dy, lessThanOrEqualTo(navTop - 16));
        expect(leave.hitTestable(), findsOneWidget);
        await tester.tap(leave);
        await tester.pumpAndSettle();
        expect(find.text('¿Salir de este colegio?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        for (final PieceEditorTab tab in <PieceEditorTab>[
          PieceEditorTab.shape,
          PieceEditorTab.name,
        ]) {
          await tester.pumpWidget(
            _app(
              PieceEditorScreen(
                key: ValueKey<PieceEditorTab>(tab),
                piece: session.piece,
                initialTab: tab,
              ),
            ),
          );
          await tester.pumpAndSettle();
          _scrollToEnd(tester);
          await tester.pumpAndSettle();
          final Finder save = find.widgetWithText(
            FilledButton,
            'Guardar mi pieza',
          );
          expect(
            tester.getBottomLeft(save).dy,
            lessThanOrEqualTo(560 - 48 - 16),
          );
          expect(save.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Cerrar sesión del personal se puede alcanzar sobre Android, escala $scale',
      (WidgetTester tester) async {
        _view(tester, scale: scale);
        final StaffSession session = StaffSession(
          DemoStaffBackend(),
          openStore: () async => _Store(),
        );
        addTearDown(session.dispose);
        await session.signIn(
          'direccion.cca@example.org',
          DemoStaffBackend.demoPassword,
        );
        await tester.pumpWidget(_app(StaffProfileScreen(session: session)));
        await tester.pumpAndSettle();
        _scrollToEnd(tester);
        await tester.pumpAndSettle();
        final Finder logout = find.widgetWithText(
          OutlinedButton,
          'Cerrar sesión',
        );
        expect(
          tester.getBottomLeft(logout).dy,
          lessThanOrEqualTo(560 - 48 - 16),
        );
        expect(logout.hitTestable(), findsOneWidget);
        await tester.tap(logout);
        await tester.pumpAndSettle();
        expect(session.isAuthenticated, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _view(WidgetTester tester, {double scale = 1}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 560);
  tester.view.padding = const FakeViewPadding(bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(bottom: 48);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void _scrollToEnd(WidgetTester tester) {
  final ScrollableState scroll = tester.state<ScrollableState>(
    find.byType(Scrollable).first,
  );
  scroll.position.jumpTo(scroll.position.maxScrollExtent);
}

Finder _asset(String path) => find.byWidgetPredicate(
  (Widget w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == path,
);
Widget _app(Widget screen) =>
    MaterialApp(theme: CureandoTheme.light, home: screen);
LearningProgress _progress() => LearningProgress(
  openStore: () async => _Store(),
  now: () => DateTime(2026, 11, 16),
);

class _Store implements LocalStorePersistence {
  @override
  Future<Map<String, Object?>?> load() async => null;
  @override
  Future<void> save(Map<String, Object?> value) async {}
}
