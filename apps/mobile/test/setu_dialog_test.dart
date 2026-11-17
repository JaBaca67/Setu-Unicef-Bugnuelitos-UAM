import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cureando_mobile/shared/theme/app_theme.dart';
import 'package:cureando_mobile/shared/widgets/setu_dialog.dart';

void main() {
  testWidgets('dialog keeps results and actions reachable with large text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: CureandoTheme.light,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async {
                result = await showSetuDialog<bool>(
                  context: context,
                  builder: (BuildContext dialog) => SetuDialog(
                    title: const Text('¿Borrar todo el dibujo?'),
                    content: Text(
                      List<String>.filled(15, 'Tu dibujo.').join(' '),
                    ),
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(dialog, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        key: const Key('confirm'),
                        onPressed: () => Navigator.pop(dialog, true),
                        child: const Text('Borrar todo'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet preserves its result and accessible button label', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: CureandoTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async {
                result = await showSetuBottomSheet<String>(
                  context: context,
                  builder: (BuildContext sheet) => SafeArea(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheet, 'done'),
                      child: const Text('Listo', semanticsLabel: 'Cerrar hoja'),
                    ),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Cerrar hoja'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(result, 'done');
    semantics.dispose();
  });
}
