import 'package:cureando_mobile/app.dart';
import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/features/school_access/school_location.dart';
import 'package:cureando_mobile/features/school_access/student_session.dart';
import 'package:cureando_mobile/features/staff/demo_staff_backend.dart';
import 'package:cureando_mobile/features/support/support_flow.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

const String _desk = 'escucha.demo@setu.test';
const String _home = '¿Qué querés hacer hoy?';

class _MemoryStore implements LocalStorePersistence {
  Map<String, Object?>? data;

  @override
  Future<Map<String, Object?>?> load() async => data;

  @override
  Future<void> save(Map<String, Object?> value) async => data = value;
}

CureandoApp _app({
  _MemoryStore? sessionStore,
  DemoStaffBackend? staff,
  bool simulation = false,
}) => CureandoApp(
  checkSchoolProximity: () async => SchoolProximity.nearby,
  allowSchoolSimulation: simulation,
  staffBackend: staff,
  studentSession: StudentSession(
    openStore: () async => sessionStore ?? _MemoryStore(),
  ),
  supportFlow: SupportFlow(openStore: () async => _MemoryStore()),
  learningProgress: LearningProgress(
    openStore: () async => _MemoryStore(),
    now: () => DateTime(2026, 11, 13),
  ),
);

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(392, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, String label) async {
  final Finder finder = find.text(label);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> _go(WidgetTester tester, String location) async {
  _router(tester).go(location);
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, String email) async {
  await _tap(tester, 'Personal autorizado');
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(
    find.byType(TextField).at(1),
    DemoStaffBackend.demoPassword,
  );
  await _tap(tester, 'Ingresar');
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Mi sesión'));
  await tester.pumpAndSettle();
  await _tap(tester, 'Cerrar sesión');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el QR acepta código directo y enlaces, y rechaza lo demás', () {
    expect(extractSchoolCode('AULA26'), 'AULA26');
    expect(extractSchoolCode(' aula-26 '), 'AULA26');
    expect(extractSchoolCode('setu://colegio/AULA26'), 'AULA26');
    expect(extractSchoolCode('setu://colegio/aula26?origen=cartel'), 'AULA26');
    expect(
      extractSchoolCode('https://setu.example/entrar?code=AULA26'),
      'AULA26',
    );
    expect(extractSchoolCode('?code=aula26'), 'AULA26');
    expect(extractSchoolCode(schoolQrLink('AULA26')), 'AULA26');
    expect(extractSchoolCode('https://example.org/AULA24'), isNull);
    expect(extractSchoolCode('setu://otro/AULA26'), isNull);
    expect(extractSchoolCode('setu://colegio/AULA'), isNull);
    expect(extractSchoolCode('hola'), isNull);
  });

  testWidgets(
    'con colegio confirmado no se vuelve a la bienvenida ni se cambia de rol',
    (WidgetTester tester) async {
      _useTallView(tester);
      final _MemoryStore store = _MemoryStore();
      await tester.pumpWidget(_app(sessionStore: store));
      await tester.pumpAndSettle();
      // El enlace del cartel entra sin código manual ni paso de cercanía.
      await _go(tester, '/colegio/enlace/AULA26');
      expect(find.text(_home), findsOneWidget);
      expect(find.text('Entraste a Colegio Centro América.'), findsOneWidget);
      expect(find.text('Comprobar cercanía'), findsNothing);

      for (final String blocked in <String>[
        '/',
        '/colegio',
        '/colegio/codigo',
        '/colegio/enlace/AULA24',
        '/personal',
        '/personal/mined',
      ]) {
        await _go(tester, blocked);
        expect(find.text(_home), findsOneWidget, reason: blocked);
      }
      expect(
        (store.data?['school'] as Map<String, Object?>?)?['publicCode'],
        'AULA26',
      );

      // Al reabrir sigue en su colegio y sigue bloqueado.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(sessionStore: store));
      await tester.pumpAndSettle();
      expect(find.text(_home), findsOneWidget);
      await _go(tester, '/');
      expect(find.text('Ingreso estudiantil'), findsNothing);

      // Solo «Salir del colegio» libera la sesión.
      await tester.tap(find.byTooltip('Abrir mi perfil'));
      await tester.pumpAndSettle();
      await _tap(tester, 'Cambiar o salir del colegio');
      await tester.tap(find.text('Salir del colegio'));
      await tester.pumpAndSettle();
      expect(find.text('Ingreso estudiantil'), findsOneWidget);
      // Sin subtítulos bajo los botones de la bienvenida.
      expect(find.textContaining('sin nombre ni correo'), findsNothing);
      expect(find.textContaining('Para Dirección'), findsNothing);
      await _go(tester, '/personal');
      expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('un enlace con código desconocido ofrece escribir el código', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _go(tester, '/colegio/enlace/AULA00');
    expect(find.text('No encontramos ese colegio'), findsOneWidget);
    await _tap(tester, 'Escribir código');
    expect(find.text('Ingresá el código de tu colegio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'el personal con sesión guardada vuelve a su superficie y queda en ella',
    (WidgetTester tester) async {
      _useTallView(tester);
      final DemoStaffBackend backend = DemoStaffBackend();
      await backend.signIn(
        email: 'direccion.cca@setu.test',
        password: DemoStaffBackend.demoPassword,
      );
      await tester.pumpWidget(_app(staff: backend));
      await tester.pumpAndSettle();
      // Sin pasar por la bienvenida ni escribir la contraseña otra vez.
      expect(find.text('Avisos y fichas'), findsOneWidget);
      expect(find.text('Ingreso estudiantil'), findsNothing);

      for (final String blocked in <String>[
        '/',
        '/colegio',
        '/colegio/enlace/AULA26',
        '/inicio',
        '/personal',
        '/personal/ambito',
        '/personal/mined',
        '/personal/mesa',
      ]) {
        await _go(tester, blocked);
        expect(find.text('Avisos y fichas'), findsOneWidget, reason: blocked);
      }

      // Dirección puede mostrar el cartel QR de su colegio.
      await tester.tap(find.byTooltip('Cartel QR del colegio'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      expect(
        tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel,
        contains('AULA26'),
      );
      expect(find.text('AULA26'), findsOneWidget);
      expect(find.text('Colegio Centro América'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      await _signOut(tester);
      expect(find.text('Ingresá con tu cuenta institucional.'), findsOneWidget);
      await _go(tester, '/');
      expect(find.text('Ingreso estudiantil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'con varios centros elige una vez y no cambia sin cerrar sesión',
    (WidgetTester tester) async {
      _useTallView(tester);
      final DemoStaffBackend backend = DemoStaffBackend();
      await backend.signIn(
        email: _desk,
        password: DemoStaffBackend.demoPassword,
      );
      await tester.pumpWidget(_app(staff: backend));
      await tester.pumpAndSettle();
      expect(find.text('¿Dónde vas a trabajar?'), findsOneWidget);
      await _go(tester, '/');
      expect(find.text('¿Dónde vas a trabajar?'), findsOneWidget);
      await _tap(tester, 'Colegio de prueba A');
      expect(find.text('Mis casos'), findsOneWidget);
      await _go(tester, '/personal/ambito');
      expect(find.text('Mis casos'), findsOneWidget);
      await tester.tap(find.byTooltip('Mi sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Cambiar de centro'), findsNothing);
      expect(
        find.textContaining('cerrá sesión e ingresá de nuevo'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('la demostración muestra el cartel QR de AULA26', (
    WidgetTester tester,
  ) async {
    _useTallView(tester);
    await tester.pumpWidget(_app(simulation: true));
    await tester.pumpAndSettle();
    await _tap(tester, 'Ingreso estudiantil');
    await _tap(tester, 'Ver cartel QR de demostración');
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Colegio Centro América'), findsOneWidget);
    expect(find.text('Managua, Nicaragua'), findsOneWidget);
    expect(find.text('AULA26'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('despacho a Mesa de Escucha', () {
    Future<DemoStaffBackend> openDesk(WidgetTester tester) async {
      _useTallView(tester);
      final DemoStaffBackend backend = DemoStaffBackend();
      await tester.pumpWidget(_app(staff: backend));
      await tester.pumpAndSettle();
      await _signIn(tester, _desk);
      await _tap(tester, 'Colegio Centro América — Demo');
      return backend;
    }

    testWidgets('tomar la alerta la pasa a Mis casos y abre el relato', (
      WidgetTester tester,
    ) async {
      final DemoStaffBackend backend = await openDesk(tester);
      expect(find.text('Alertas por tomar'), findsOneWidget);
      expect(find.text('DEMO-021'), findsOneWidget);
      expect(find.text('Equipo de planta'), findsOneWidget);
      // Antes de tomarla no hay relato para esta persona.
      expect(await backend.narrative('demo-case-021'), isNull);
      await _tap(tester, 'Tomar alerta');
      expect(find.textContaining('Tomaste DEMO-021'), findsOneWidget);
      expect(find.text('Alertas por tomar'), findsNothing);
      expect(find.text('DEMO-021'), findsOneWidget);
      expect(await backend.narrative('demo-case-021'), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('si otra persona la tomó antes, lo dice con claridad', (
      WidgetTester tester,
    ) async {
      final DemoStaffBackend backend = await openDesk(tester);
      backend.simulateOtherClaim('demo-case-021', notify: false);
      await _tap(tester, 'Tomar alerta');
      expect(
        find.textContaining('Otra persona de Mesa de Escucha tomó DEMO-021'),
        findsOneWidget,
      );
      expect(find.text('Alertas por tomar'), findsNothing);
      expect(find.text('DEMO-021'), findsNothing);
      // El relato sigue reservado a quien ganó la toma.
      expect(await backend.narrative('demo-case-021'), isNull);
      expect(await backend.messages('demo-case-021'), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la bandeja se actualiza en vivo cuando otra persona la toma', (
      WidgetTester tester,
    ) async {
      final DemoStaffBackend backend = await openDesk(tester);
      expect(find.text('Alertas por tomar'), findsOneWidget);
      backend.simulateOtherClaim('demo-case-021');
      await tester.pumpAndSettle();
      expect(find.text('Alertas por tomar'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('declinar deriva a la red externa y MINED ve el historial', (
      WidgetTester tester,
    ) async {
      final DemoStaffBackend backend = await openDesk(tester);
      await _tap(tester, 'Declinar');
      expect(find.text('Declinar DEMO-021'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Atiendo otra conversación',
      );
      await _tap(tester, 'Declinar alerta');
      expect(
        find.text('Declinaste DEMO-021. Se ofreció a la red externa.'),
        findsOneWidget,
      );
      expect(find.text('Alertas por tomar'), findsNothing);

      final List<CaseDispatchRecord> mine = await backend.dispatchHistory(
        caseId: 'demo-case-021',
      );
      // Mesa de Escucha solo ve sus propios despachos.
      expect(mine.map((CaseDispatchRecord r) => r.counselorUserId), <String>[
        _desk,
      ]);

      await _signOut(tester);
      await tester.enterText(
        find.byType(TextField).at(0),
        'mined.demo@setu.test',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        DemoStaffBackend.demoPassword,
      );
      await _tap(tester, 'Ingresar');
      expect(find.text('Alertas recibidas'), findsOneWidget);
      final Finder tile = find.ancestor(
        of: find.text('DEMO-021'),
        matching: find.byType(Column),
      );
      final Finder history = find.descendant(
        of: tile.first,
        matching: find.text('Historial de despacho'),
      );
      await tester.ensureVisible(history);
      await tester.pumpAndSettle();
      await tester.tap(history);
      await tester.pumpAndSettle();
      expect(find.text('Despacho de DEMO-021'), findsOneWidget);
      expect(find.text('Todavía nadie tomó esta alerta.'), findsOneWidget);
      expect(find.text('Equipo de planta'), findsOneWidget);
      expect(find.text('Red externa'), findsOneWidget);
      expect(find.text('Declinada'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(
        find.text('Motivo de declinación: Atiendo otra conversación'),
        findsOneWidget,
      );
      expect(find.text(DemoStaffBackend.externalCounselor), findsOneWidget);
      // El historial no trae relato.
      expect(find.textContaining('Relato ficticio'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
