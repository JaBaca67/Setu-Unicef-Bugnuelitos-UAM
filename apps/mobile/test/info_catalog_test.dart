import 'dart:convert';
import 'dart:io';

import 'package:cureando_mobile/features/home/external_links.dart';
import 'package:cureando_mobile/features/home/info_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> source =
      jsonDecode(
            File(
              '../../docs/contenido/catalogo_informacion.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final List<Map<String, dynamic>> resources =
      (source['resources'] as List<dynamic>).cast<Map<String, dynamic>>();

  test('catálogo conserva ids, fuentes y verificación de los 21 recursos', () {
    final List<Map<String, dynamic>> verified = resources
        .where((Map<String, dynamic> r) => r['verified'] == true)
        .toList();
    expect(infoCatalog, hasLength(21));
    expect(
      infoCatalog.map((InfoResource r) => r.id),
      verified.map((Map<String, dynamic> r) => r['id']),
    );
    for (final Map<String, dynamic> data in verified) {
      final InfoResource resource = infoResourceById(data['id'] as String)!;
      expect(resource.verified, isTrue);
      expect(resource.organization, data['organization']);
      expect(resource.notes, data['notes']);
      expect(resource.url, data['url']);
      expect(resource.minutes, data['minutes']);
      expect(resource.offline, !resource.isVideo);
      expect(
        resource.meta,
        resource.isVideo ? 'Video' : 'Guía · ${resource.minutes} min',
      );
      for (final String? asset in <String?>[
        resource.thumbAsset,
        resource.cardAsset,
        resource.bannerAsset,
      ]) {
        expect(asset, isNotNull);
        expect(File(asset!).existsSync(), isTrue);
      }
    }
    for (final Map<String, dynamic> data in resources.where(
      (Map<String, dynamic> r) => r['verified'] == false,
    )) {
      expect(infoResourceById(data['id'] as String), isNull);
    }
    expect(InfoTopic.values.map((InfoTopic t) => t.label), <String>[
      'Acoso escolar',
      'Ansiedad',
      'Depresión',
      'Ciberacoso',
      'Emociones',
      'Apoyo',
    ]);
    // El JSON es una entrada editorial de desarrollo; no se empaqueta en la app.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('catalogo_informacion.json')),
    );
  });

  test('lectura fácil: títulos, resúmenes y hasta tres ideas breves', () {
    for (final InfoResource resource in infoCatalog) {
      expect(
        resource.title.trim().split(RegExp(r'\s+')).length,
        lessThanOrEqualTo(6),
        reason: resource.id,
      );
      expect(resource.title, isNot(contains('UNICEF')));
      expect(resource.title, isNot(contains('MINED')));
      expect(
        resource.summary.length,
        lessThanOrEqualTo(70),
        reason: resource.id,
      );
      expect(
        resource.points.length,
        inInclusiveRange(1, 3),
        reason: resource.id,
      );
      for (final InfoPoint point in resource.points) {
        expect(point.body.length, lessThanOrEqualTo(90), reason: resource.id);
      }
    }
  });

  test(
    'cada tema tiene ilustraciones distintas en tarjetas, miniaturas y lector',
    () {
      for (final InfoTopic topic in InfoTopic.values) {
        final List<InfoResource> resources = infoCatalog
            .where((InfoResource r) => r.topic == topic)
            .toList();
        for (final String? Function(InfoResource) asset
            in <String? Function(InfoResource)>[
              (InfoResource r) => r.cardAsset,
              (InfoResource r) => r.thumbAsset,
              (InfoResource r) => r.bannerAsset,
            ]) {
          final List<String?> images = resources.map(asset).toList();
          expect(images.toSet(), hasLength(images.length), reason: topic.label);
          expect(images, isNot(contains(contains('fondo-homepage-banner'))));
          expect(images, isNot(contains(contains('home-header-girl'))));
        }
      }
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('    - assets/home/info/stickers/'),
      );
    },
  );

  test(
    'cuatro rutas completas conservan pregunta, A/B/C y feedback por opción',
    () {
      final List<Map<String, dynamic>> routes =
          (source['routes'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(infoRoutes, hasLength(4));
      expect(infoRoutes.map((InfoRoute r) => r.id), <String>[
        'acoso',
        'ansiedad',
        'depresion',
        'ciberacoso',
      ]);
      for (int i = 0; i < infoRoutes.length; i++) {
        final InfoRoute route = infoRoutes[i];
        expect(route.ready, isTrue);
        expect(route.steps, hasLength(3));
        expect(route.description, routes[i]['title']);
        final List<dynamic> steps = routes[i]['steps'] as List<dynamic>;
        for (int step = 0; step < 2; step++) {
          final InfoResource resource = infoResourceById(route.steps[step])!;
          expect(resource.verified, isTrue);
          expect(resource.topic, route.topic);
          expect(
            resource.id,
            (steps[step] as Map<String, dynamic>)['resourceId'],
          );
        }
        final Map<String, dynamic> data = steps[2] as Map<String, dynamic>;
        final InfoResource question = infoResourceById(route.steps.last)!;
        expect(question.isQuiz, isTrue);
        expect(question.caption, data['question']);
        expect(question.options, data['options']);
        expect(question.correct, data['correctIndex']);
        expect(question.optionFeedback, data['feedback']);
      }
    },
  );

  const MethodChannel channel = MethodChannel('dev.cureando.app/links');
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets('enlace externo invoca open con URL exacta', (
    WidgetTester tester,
  ) async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          received = call;
          return null;
        });
    final String url = infoCatalog.first.url;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => openExternalLink(context, url),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(received?.method, 'open');
    expect(received?.arguments, <String, String>{'url': url});
    expect(find.byType(SnackBar), findsNothing);
  });

  for (final bool missing in <bool>[false, true]) {
    testWidgets('fallo de enlace (canal ausente: $missing) muestra SnackBar', (
      WidgetTester tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (missing) throw MissingPluginException();
            throw PlatformException(code: 'no_browser');
          });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () =>
                    openExternalLink(context, infoCatalog.first.url),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo abrir el enlace. Probá de nuevo con internet.'),
        findsOneWidget,
      );
    });
  }
}
