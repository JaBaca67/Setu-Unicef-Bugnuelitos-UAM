import 'package:cureando_mobile/features/home/information_tab.dart';
import 'package:cureando_mobile/features/home/info_catalog.dart';
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
import 'package:cureando_mobile/shared/widgets/unicef_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      // La navegación real de estos banners se verifica en activities_test.
      expect(label.hitTestable(), findsOneWidget);
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
      final Finder clipped = find.widgetWithText(ChoiceChip, 'Ansiedad');
      AnimatedOpacity chipOpacity(Finder chip) =>
          tester.widget<AnimatedOpacity>(
            find.ancestor(of: chip, matching: find.byType(AnimatedOpacity)),
          );
      final Rect viewport = tester.getRect(carousel);
      expect(tester.getRect(clipped).right, greaterThan(viewport.right));
      expect(chipOpacity(clipped).opacity, 0);
      expect(chipOpacity(clipped).alwaysIncludeSemantics, isTrue);
      expect(
        tester
            .renderObject<RenderAnimatedOpacity>(
              find.ancestor(
                of: clipped,
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity
            .value,
        0,
      );
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(clipped),
          matchesSemantics(
            label: 'Ansiedad',
            isHidden: true,
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
      await tester.drag(carousel, const Offset(-260, 0));
      await tester.pumpAndSettle();
      expect(chipOpacity(clipped).opacity, 1);
      expect(tester.getRect(clipped).right, lessThanOrEqualTo(viewport.right));
      expect(
        tester.widget<SetuBottomNav>(find.byType(SetuBottomNav)).selected,
        HomeSection.informacion,
      );
      final Finder support = find.widgetWithText(ChoiceChip, 'Apoyo');
      await tester.ensureVisible(support);
      await tester.pumpAndSettle();
      expect(support.hitTestable(), findsOneWidget);
      await tester.tap(support);
      await tester.pumpAndSettle();
      expect(find.text('4 disponibles'), findsOneWidget);
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

  for (final double width in <double>[360, 412]) {
    for (final double scale in <double>[1, 2]) {
      testWidgets('chips completos a $width px y texto $scale', (
        WidgetTester tester,
      ) async {
        _view(tester, scale: scale);
        tester.view.physicalSize = Size(width, 850);
        final LearningProgress progress = _progress();
        addTearDown(progress.dispose);
        await tester.pumpWidget(
          _app(
            CampaignScreen(
              header: const InformationHeader(),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: InformationTab(progress: progress),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Finder carousel = find.byKey(
          const ValueKey<String>('information-categories'),
        );
        int checkChips() {
          final Rect viewport = tester.getRect(carousel);
          int visible = 0;
          for (final Element element in find.byType(ChoiceChip).evaluate()) {
            final Finder chip = find.byWidget(element.widget);
            final Rect rect = tester.getRect(chip);
            final Finder opacity = find.ancestor(
              of: chip,
              matching: find.byType(AnimatedOpacity),
            );
            final bool full =
                rect.left >= viewport.left - .5 &&
                rect.right <= viewport.right + .5;
            expect(
              tester.widget<AnimatedOpacity>(opacity).opacity,
              full ? 1 : 0,
            );
            if (full) visible++;
          }
          return visible;
        }

        expect(
          checkChips(),
          scale == 1 ? greaterThanOrEqualTo(4) : isPositive,
          reason: find
              .byType(ChoiceChip)
              .evaluate()
              .map(
                (Element e) =>
                    '${(e.widget as ChoiceChip).label}: ${tester.getRect(find.byWidget(e.widget))}',
              )
              .join(', '),
        );
        if (scale == 1) {
          for (final String label in <String>[
            'Todos',
            'Acoso escolar',
            'Emociones',
            'Ciberacoso',
          ]) {
            final Rect chip = tester.getRect(
              find.widgetWithText(ChoiceChip, label),
            );
            expect(
              chip.left,
              greaterThanOrEqualTo(tester.getRect(carousel).left - .5),
            );
            expect(
              chip.right,
              lessThanOrEqualTo(tester.getRect(carousel).right + .5),
            );
          }
        }
        // Desplazamiento pequeño: el primer chip queda parcialmente fuera y se oculta.
        await tester.drag(carousel, const Offset(-15, 0), touchSlopX: 0);
        await tester.pumpAndSettle();
        checkChips();
        await tester.drag(carousel, const Offset(-240, 0));
        await tester.pumpAndSettle();
        checkChips();
        await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Todos'));
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(ChoiceChip, 'Todos').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('portada E10-A abre catálogo E10-B y actualiza XP leídos', (
    WidgetTester tester,
  ) async {
    _view(tester);
    tester.view.physicalSize = const Size(360, 850);
    final LearningProgress progress = _progress();
    addTearDown(progress.dispose);
    await progress.open();
    await tester.pumpWidget(
      _app(
        CampaignScreen(
          header: const InformationHeader(),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: InformationTab(progress: progress),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ver todo ›'), findsNothing);
    expect(find.text('Ver catálogo ›'), findsNWidgets(6));
    final Finder block = find.byKey(
      const ValueKey<String>('topic-preview-acoso'),
    );
    final Finder cards = find.descendant(
      of: block,
      matching: find.byType(InfoResourceCard),
    );
    expect(cards, findsNWidgets(2));
    expect(
      tester
          .widgetList<InfoResourceCard>(cards)
          .every((InfoResourceCard c) => c.cover),
      isTrue,
    );
    expect(tester.getRect(cards.first).top, tester.getRect(cards.last).top);
    expect(
      tester.getRect(cards.first).right,
      lessThan(tester.getRect(cards.last).left),
    );
    for (final InfoTopic topic in InfoTopic.values) {
      final List<InfoResource> preview = infoCatalog
          .where(
            (InfoResource r) =>
                r.topic == topic && !r.isQuiz && r != infoCatalog.first,
          )
          .take(3)
          .toList();
      final Finder category = find.byKey(
        ValueKey<String>('topic-preview-${topic.name}'),
      );
      expect(
        find.descendant(of: category, matching: find.byType(InfoResourceCard)),
        findsNWidgets(2),
      );
      if (preview.length == 3) {
        expect(
          find.descendant(
            of: category,
            matching: find.byKey(ValueKey<String>('banner-${preview.last.id}')),
          ),
          findsOneWidget,
        );
      }
    }
    await tester.ensureVisible(find.text('Ver catálogo ›').first);
    await tester.tap(find.text('Ver catálogo ›').first);
    await tester.pumpAndSettle();
    final List<InfoResource> resources = infoCatalog
        .where((InfoResource r) => r.topic == InfoTopic.acoso && !r.isQuiz)
        .toList();
    expect(find.text('${resources.length} disponibles'), findsOneWidget);
    expect(find.byType(InfoResourceCard), findsNWidgets(resources.length));
    for (final InfoResourceCard card in tester.widgetList<InfoResourceCard>(
      find.byType(InfoResourceCard),
    )) {
      expect(card.cover, isFalse);
      final Finder target = find.byWidget(card);
      expect(
        find.descendant(
          of: target,
          matching: find.text(card.resource.availability),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: target, matching: find.text('+5 XP')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: target, matching: find.text(card.resource.summary)),
        findsOneWidget,
      );
    }
    await progress.completeResource(resources.first.id);
    await tester.pumpAndSettle();
    expect(find.text('+5 XP'), findsNWidgets(resources.length - 1));
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Leer ›'), findsOneWidget);
    expect(find.text('Ver catálogo ›'), findsNWidgets(6));
    await tester.enterText(find.byType(TextField), 'video');
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<InfoResourceCard>(find.byType(InfoResourceCard))
          .every((InfoResourceCard card) => !card.cover),
      isTrue,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Ver catálogo ›'), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Elegí tu ruta: cuatro temas, estados, piezas y medalla', (
    WidgetTester tester,
  ) async {
    _view(tester);
    final LearningProgress progress = _progress();
    addTearDown(progress.dispose);
    await progress.open();
    for (final String id in infoRoutes.first.steps.take(2)) {
      await progress.completeResource(id);
    }
    await progress.completeRoute(infoRoutes.first.id);
    await progress.completeResource(infoRoutes[1].steps.first);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SingleChildScrollView(
            child: InformationTab(progress: progress),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rutas'));
    await tester.pumpAndSettle();
    expect(find.text('+20 XP ganados'), findsOneWidget);
    expect(find.byIcon(Icons.extension_rounded), findsAtLeastNWidgets(3));
    await tester.tap(find.text('Cambiar tema'));
    await tester.pumpAndSettle();
    expect(find.text('Elegí tu ruta'), findsOneWidget);
    expect(find.text('¡Completada!'), findsOneWidget);
    expect(find.text('En curso'), findsOneWidget);
    expect(find.text('Nueva'), findsNWidgets(2));
    Finder choice(String id) =>
        find.byKey(ValueKey<String>('route-choice-$id'));
    expect(
      tester.getTopLeft(choice('acoso')).dy,
      tester.getTopLeft(choice('ansiedad')).dy,
    );
    expect(
      tester.getTopLeft(choice('depresion')).dy,
      tester.getTopLeft(choice('ciberacoso')).dy,
    );
    for (int i = 0; i < infoRoutes.length; i++) {
      final InfoRoute route = infoRoutes[i];
      final Finder card = choice(route.id);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: card, matching: find.text(route.topic.label)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: _asset('assets/home/activities/rompecabezas_pareja.png'),
        ),
        findsOneWidget,
      );
      final Semantics semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: card,
              matching: find.byWidgetPredicate(
                (Widget w) => w is Semantics && w.properties.label != null,
              ),
            )
            .first,
      );
      expect(
        semantics.properties.label,
        contains('${<int>[3, 1, 0, 0][i]} de 3 pasos'),
      );
      expect(semantics.properties.selected, i == 0);
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.workspace_premium_rounded),
        ),
        i == 0 ? findsOneWidget : findsNothing,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.extension_rounded),
        ),
        findsNWidgets(<int>[3, 1, 0, 0][i]),
      );
    }
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
    'Mi racha comparte fondo y logos de Inicio sobre figuras transparentes',
    (WidgetTester tester) async {
      _view(tester);
      final LearningProgress progress = _progress();
      addTearDown(progress.dispose);
      await tester.pumpWidget(_app(StreakScreen(progress: progress)));
      await tester.pumpAndSettle();
      expect(_asset('assets/home/banner-racha.png'), findsNothing);
      final Finder figures = _asset('assets/home/banner-racha-figures.png');
      expect(figures, findsOneWidget);
      final Rect artwork = tester.getRect(figures);
      expect(artwork.width / artwork.height, closeTo(600 / 268, .01));
      final CampaignSymbol symbol = tester.widget<CampaignSymbol>(
        find.byType(CampaignSymbol),
      );
      expect(symbol.size, 28);
      expect(symbol.showUnicef, isTrue);
      expect(
        tester.getTopLeft(find.byType(CampaignSymbol)),
        const Offset(18, 8),
      );
      expect(find.byType(UnicefLogo), findsOneWidget);
      final Finder background = find
          .descendant(
            of: find.byType(CampaignBackground),
            matching: find.byType(DecoratedBox),
          )
          .first;
      final BoxDecoration decoration =
          tester.widget<DecoratedBox>(background).decoration as BoxDecoration;
      expect(decoration.color, CureandoTheme.blue);
      expect(
        (decoration.image!.image as AssetImage).assetName,
        'assets/welcome/campaign-pattern.png',
      );
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
