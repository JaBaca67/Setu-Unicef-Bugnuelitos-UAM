import 'dart:io';
import 'dart:ui' as ui;

import 'package:cureando_mobile/features/home/information_tab.dart';
import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/features/home/student_home_screen.dart';
import 'package:cureando_mobile/features/home/student_resources.dart';
import 'package:cureando_mobile/features/piece/student_piece.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/theme/app_theme.dart';
import 'package:cureando_mobile/shared/widgets/campaign_screen.dart';
import 'package:cureando_mobile/shared/widgets/flow_scaffold.dart';
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
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final double width in <double>[360, 412]) {
    for (final double height in <double>[560, 850]) {
      for (final double inset in <double>[0, 24, 48]) {
        testWidgets(
          'pestañas visibles al final: $width × $height, inset $inset',
          (WidgetTester tester) async {
            _view(tester, width, height, inset);
            final LearningProgress progress = _progress();
            final ValueNotifier<StudentPiece> piece =
                ValueNotifier<StudentPiece>(StudentPiece.initial);
            addTearDown(progress.dispose);
            addTearDown(piece.dispose);
            await tester.pumpWidget(
              _app(StudentHomeScreen(progress: progress, piece: piece)),
            );
            await tester.pumpAndSettle();
            final Map<HomeSection, Finder> endings = <HomeSection, Finder>{
              HomeSection.inicio: find.bySemanticsLabel('Dado de emociones'),
              HomeSection.informacion: find.text(
                'Qué pasa al enviar una alerta en SéTú',
              ),
              HomeSection.actividades: find.textContaining(
                'El equipo diseñó otros materiales',
              ),
              HomeSection.ayuda: find.text('¿Qué puedo hacer sin internet?'),
            };
            for (final MapEntry<HomeSection, Finder> entry in endings.entries) {
              await tester.tap(
                find.descendant(
                  of: find.byType(SetuBottomNav),
                  matching: find.text(entry.key.label),
                ),
              );
              await tester.pumpAndSettle();
              final ScrollableState scroll = tester.state<ScrollableState>(
                find
                    .descendant(
                      of: find.byType(CustomScrollView),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              scroll.position.jumpTo(scroll.position.maxScrollExtent);
              await tester.pumpAndSettle();
              final Rect last = tester.getRect(entry.value);
              final Rect nav = tester.getRect(find.byType(SetuBottomNav));
              expect(last.top, greaterThanOrEqualTo(0));
              expect(
                last.bottom,
                lessThanOrEqualTo(nav.top - 16),
                reason: entry.key.label,
              );
              expect(entry.value.hitTestable(), findsOneWidget);
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }

    testWidgets('E10 y E11 sin desbordes y CTA sobre Android a $width', (
      WidgetTester tester,
    ) async {
      _view(tester, width, 640, 48);
      final LearningProgress progress = _progress();
      addTearDown(progress.dispose);
      await progress.open();
      const Key capture = ValueKey<String>('info-layout');
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: capture,
            child: CampaignScreen(
              header: const InformationHeader(),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: InformationTab(progress: progress),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UnicefLogo), findsOneWidget);
      final TextField search = tester.widget<TextField>(find.byType(TextField));
      expect(search.decoration!.fillColor, Colors.white);
      expect(
        (search.decoration!.enabledBorder! as OutlineInputBorder).borderSide,
        const BorderSide(color: CureandoTheme.blue, width: 2),
      );
      for (final ChoiceChip chip in tester.widgetList<ChoiceChip>(
        find.byType(ChoiceChip),
      )) {
        expect(chip.backgroundColor, chip.selectedColor);
        expect(chip.labelStyle!.fontWeight, FontWeight.w700);
      }
      await _capture(tester, capture, 'e10-$width');
      await tester.ensureVisible(find.text('Pasó en el chat del grupo'));
      await tester.pumpAndSettle();
      await _capture(tester, capture, 'e10-ciberacoso-$width');
      final ScrollableState libraryScroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      libraryScroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Acoso escolar'));
      await tester.pumpAndSettle();
      final ChoiceChip selected = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Acoso escolar'),
      );
      expect(selected.selected, isTrue);
      expect(selected.selectedColor, CureandoTheme.yellow);
      expect(selected.labelStyle!.color, CureandoTheme.pink);
      expect(selected.showCheckmark, isTrue);
      for (final InfoResource r in infoCatalog) {
        await tester.pumpWidget(
          _app(
            RepaintBoundary(
              key: capture,
              child: ResourcePreviewScreen(
                key: ValueKey<String>(r.id),
                resourceId: r.id,
                progress: progress,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Finder button = find.widgetWithText(
          OutlinedButton,
          'Pedir apoyo',
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(tester.getRect(button).bottom, lessThanOrEqualTo(640 - 48 - 16));
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull, reason: r.id);
        await _capture(tester, capture, 'e11-${r.id}-$width');
        if (r.points.isNotEmpty) {
          final Finder lastParagraph = find.text(r.points.last.body);
          await tester.ensureVisible(lastParagraph);
          await tester.pumpAndSettle();
          expect(lastParagraph.hitTestable(), findsOneWidget);
        }
      }
    });
  }

  for (final bool campaign in <bool>[true, false]) {
    for (final bool withNav in <bool>[true, false]) {
      testWidgets(
        'scaffold campaña=$campaign barra=$withNav respeta viewPadding con padding consumido',
        (WidgetTester tester) async {
          _view(tester, 360, 640, 48);
          final Widget body = Column(
            children: <Widget>[
              const SizedBox(height: 1000),
              FilledButton(
                onPressed: () {},
                child: const Text('Última acción'),
              ),
            ],
          );
          final Widget? nav = withNav
              ? SetuBottomNav(selected: HomeSection.inicio, onSelected: (_) {})
              : null;
          await tester.pumpWidget(
            _app(
              MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 640),
                  viewPadding: EdgeInsets.only(bottom: 48),
                ),
                child: campaign
                    ? CampaignScreen(
                        header: const SizedBox(height: 80),
                        body: body,
                        bottomNavigationBar: nav,
                      )
                    : FlowScaffold(
                        header: const SizedBox(height: 80),
                        body: body,
                        bottomNavigationBar: nav,
                      ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final ScrollableState scroll = tester.state<ScrollableState>(
            find.byType(Scrollable).first,
          );
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
          await tester.pumpAndSettle();
          final Finder action = find.widgetWithText(
            FilledButton,
            'Última acción',
          );
          final double boundary = withNav
              ? tester.getRect(find.byType(SetuBottomNav)).top
              : 640 - 48;
          expect(
            tester.getRect(action).bottom,
            lessThanOrEqualTo(boundary - 16),
          );
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'FlowScaffold conserva CTA y final con texto grande y poca altura',
    (WidgetTester tester) async {
      _view(tester, 360, 480, 48);
      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 480),
              padding: EdgeInsets.only(bottom: 48),
              viewPadding: EdgeInsets.only(bottom: 48),
              textScaler: TextScaler.linear(2),
            ),
            child: FlowScaffold(
              header: const SizedBox(height: 70),
              body: const Column(
                children: <Widget>[
                  SizedBox(height: 600),
                  Text('Final del formulario'),
                ],
              ),
              bottom: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < 4; i++)
                    FilledButton(onPressed: () {}, child: Text('Acción $i')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder lastButton = find.widgetWithText(FilledButton, 'Acción 3');
      await tester.ensureVisible(lastButton);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(lastButton).bottom,
        lessThanOrEqualTo(480 - 48 - 16),
      );
      expect(lastButton.hitTestable(), findsOneWidget);
      final Finder scroll = find.byType(SingleChildScrollView).first;
      await tester.drag(scroll, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.text('Final del formulario').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.text('Final del formulario')).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byType(SingleChildScrollView).last).top,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app(Widget child) =>
    MaterialApp(theme: CureandoTheme.light, home: child);

LearningProgress _progress() => LearningProgress(
  openStore: () async => _MemoryStore(),
  now: () => DateTime(2026, 11, 16),
);

class _MemoryStore implements LocalStorePersistence {
  @override
  Future<Map<String, Object?>?> load() async => null;
  @override
  Future<void> save(Map<String, Object?> value) async {}
}

void _view(WidgetTester tester, double width, double height, double inset) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.padding = FakeViewPadding(bottom: inset);
  tester.view.viewPadding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.reset);
}

Future<void> _capture(WidgetTester tester, Key key, String name) async {
  if (!const bool.fromEnvironment('SETU_CAPTURE_QA')) return;
  final Finder target = find.byKey(key);
  await tester.runAsync<void>(() async {
    for (final Element e
        in find
            .descendant(of: target, matching: find.byType(Image))
            .evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
    await precacheImage(
      const AssetImage('assets/welcome/campaign-pattern.png'),
      tester.element(target),
    );
    for (final String asset in <String>[
      'e10a_featured_broma.png',
      'e10a_banner_chat.png',
      'e10c_route_map.png',
    ]) {
      await precacheImage(
        AssetImage('assets/home/info/$asset'),
        tester.element(target),
      );
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync<void>(() async {
    final ui.Image frame = await tester
        .renderObject<RenderRepaintBoundary>(target)
        .toImage();
    final ByteData? bytes = await frame.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.dispose();
    await Directory('build/qa').create(recursive: true);
    await File('build/qa/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}
