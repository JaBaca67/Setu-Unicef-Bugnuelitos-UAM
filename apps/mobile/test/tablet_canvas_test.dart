import 'package:cureando_mobile/shared/widgets/tablet_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Size? _seen;

Widget _probe() => Directionality(
  textDirection: TextDirection.ltr,
  child: TabletCanvas(
    child: Builder(
      builder: (BuildContext context) {
        _seen = MediaQuery.sizeOf(context);
        return const SizedBox.expand();
      },
    ),
  ),
);

void main() {
  testWidgets('en tableta la interfaz usa el ancho del teléfono escalado', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1600, 2560); // 800 × 1280 dp
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_probe());
    expect(_seen!.width, TabletCanvas.designWidth);
    expect(_seen!.height, closeTo(1280 / (800 / 430), .01));
    // El contenido ocupa toda la pantalla, sin bordes.
    expect(tester.getSize(find.byType(SizedBox).last), _seen);
    expect(tester.getRect(find.byType(FittedBox)).size, const Size(800, 1280));
  });

  testWidgets('en teléfono no cambia nada', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2340); // 360 × 780 dp
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_probe());
    expect(_seen, const Size(360, 780));
    expect(find.byType(FittedBox), findsNothing);
  });
}
