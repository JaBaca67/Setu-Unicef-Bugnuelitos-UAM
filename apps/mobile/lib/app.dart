import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'features/home/learning_progress.dart';
import 'features/home/streak_screen.dart';
import 'features/home/student_home_screen.dart';
import 'features/home/student_resources.dart';
import 'features/piece/student_piece.dart';
import 'features/piece/student_profile_screen.dart';
import 'features/school_access/school_access_screen.dart';
import 'features/school_access/school_location.dart';
import 'features/school_access/school_qr_poster.dart';
import 'features/school_access/student_session.dart';
import 'features/staff/demo_staff_backend.dart';
import 'features/staff/staff_access_screens.dart';
import 'features/staff/staff_backend.dart';
import 'features/staff/staff_case_screens.dart';
import 'features/staff/staff_director_screens.dart';
import 'features/staff/staff_inbox_screens.dart';
import 'features/support/alert_screens.dart';
import 'features/support/support_flow.dart';
import 'features/support/support_screens.dart';
import 'features/welcome/welcome_screen.dart';
import 'shared/contracts/cureando_gateway.dart';
import 'shared/local/local_cureando_gateway.dart';
import 'shared/platform/screen_security_controller.dart';
import 'shared/remote/setu_remote_models.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/setu_brand_mark.dart';
import 'shared/widgets/student_transition.dart';

class CureandoApp extends StatefulWidget {
  const CureandoApp({
    super.key,
    this.gateway,
    this.learningProgress,
    this.supportFlow,
    this.studentSession,
    this.staffBackend,
    this.screenSecurity,
    this.showM1Verification = false,
    this.allowDesignCapture = false,
    this.allowSchoolSimulation = false,
    this.checkSchoolProximity = checkSchoolLocation,
  });
  final CureandoGateway? gateway;
  final LearningProgress? learningProgress;
  final SupportFlow? supportFlow;

  /// Colegio confirmado y pieza guardados en el teléfono. Sin valor se usa
  /// el almacén cifrado del dispositivo y el catálogo local de colegios.
  final StudentSession? studentSession;

  /// Puerto de personal autorizado. Sin valor se usa la demostración en
  /// memoria; `main.dart` inyecta el adaptador de Supabase.
  final StaffBackend? staffBackend;
  final ScreenSecurityController? screenSecurity;
  final bool showM1Verification;
  final bool allowDesignCapture;
  final bool allowSchoolSimulation;
  final Future<SchoolProximity> Function() checkSchoolProximity;
  @override
  State<CureandoApp> createState() => _CureandoAppState();
}

class _CureandoAppState extends State<CureandoApp> {
  late final LearningProgress _learning =
      widget.learningProgress ?? LearningProgress();
  late final AppLifecycleListener _learningLifecycle;
  late final SupportFlow _support = widget.supportFlow ?? SupportFlow();
  late final StaffSession _staff = StaffSession(
    widget.staffBackend ?? DemoStaffBackend(),
  );
  late final StudentSession _session =
      widget.studentSession ?? StudentSession();
  ValueNotifier<StudentPiece> get _piece => _session.piece;
  late final ScreenSecurityController _security =
      widget.screenSecurity ?? ScreenSecurityController();
  late final GoRouter _router = GoRouter(
    initialLocation: widget.showM1Verification ? '/verificacion-m1' : '/',
    // La guía de rutas se reevalúa al cambiar cualquiera de las sesiones.
    refreshListenable: Listenable.merge(<Listenable>[_staff, _session]),
    redirect: _sessionRedirect,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            WelcomeScreen(hasSchool: () => _session.school != null),
        routes: <RouteBase>[
          GoRoute(
            path: 'colegio',
            pageBuilder: (context, state) => studentTransition(
              context,
              state,
              SchoolAccessScreen(
                step: SchoolAccessStep.method,
                session: _session,
                allowSimulation: widget.allowSchoolSimulation,
              ),
            ),
            routes: <RouteBase>[
              // Llegada por el QR del cartel leído con la cámara del teléfono.
              GoRoute(
                path: 'enlace/:code',
                pageBuilder: (context, state) => studentTransition(
                  context,
                  state,
                  SchoolLinkScreen(
                    session: _session,
                    code: state.pathParameters['code'] ?? '',
                  ),
                ),
              ),
              // Cartel de demostración del Colegio Centro América (AULA26).
              GoRoute(
                path: 'cartel',
                pageBuilder: (context, state) => studentTransition(
                  context,
                  state,
                  SchoolQrPosterScreen(school: localSchoolCatalog.first),
                ),
              ),
              for (final SchoolAccessStep step in SchoolAccessStep.values)
                if (step.path.isNotEmpty)
                  GoRoute(
                    path: step.path,
                    pageBuilder: (context, state) {
                      final Object? extra = state.extra;
                      return studentTransition(
                        context,
                        state,
                        SchoolAccessScreen(
                          step: step,
                          session: _session,
                          proximity:
                              extra is SchoolProximity &&
                                  (extra != SchoolProximity.simulated ||
                                      widget.allowSchoolSimulation)
                              ? extra
                              : SchoolProximity.unavailable,
                          checkProximity: widget.checkSchoolProximity,
                          allowSimulation: widget.allowSchoolSimulation,
                        ),
                      );
                    },
                  ),
            ],
          ),
          GoRoute(
            path: 'inicio',
            pageBuilder: (context, state) => studentTransition(
              context,
              state,
              StudentHomeScreen(
                progress: _learning,
                piece: _piece,
                sectionRequest: state.extra is HomeSectionRequest
                    ? state.extra! as HomeSectionRequest
                    : null,
              ),
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'racha',
                pageBuilder: (context, state) => studentTransition<bool>(
                  context,
                  state,
                  StreakScreen(progress: _learning),
                ),
              ),
              GoRoute(
                path: 'pieza',
                pageBuilder: (context, state) => studentTransition(
                  context,
                  state,
                  StudentProfileScreen(session: _session, progress: _learning),
                ),
              ),
              GoRoute(
                path: 'apoyo',
                pageBuilder: (context, state) => studentTransition(
                  context,
                  state,
                  SupportHomeScreen(flow: _support, piece: _piece),
                ),
                routes: <RouteBase>[
                  for (final MapEntry<String, Widget Function()> step
                      in <String, Widget Function()>{
                        'alerta': () =>
                            AlertSituationScreen(flow: _support, piece: _piece),
                        'rol': () =>
                            AlertRoleScreen(flow: _support, piece: _piece),
                        'detalles': () =>
                            AlertDetailsScreen(flow: _support, piece: _piece),
                        'revisar': () =>
                            AlertReviewScreen(flow: _support, piece: _piece),
                        'recibida': () => AlertReceivedScreen(flow: _support),
                        'chat': () =>
                            SupportChatScreen(flow: _support, piece: _piece),
                      }.entries)
                    GoRoute(
                      path: step.key,
                      pageBuilder: (context, state) =>
                          studentTransition(context, state, step.value()),
                    ),
                ],
              ),
              GoRoute(
                path: 'recurso/:id',
                pageBuilder: (context, state) => studentTransition(
                  context,
                  state,
                  ResourcePreviewScreen(
                    resourceId: state.pathParameters['id'] ?? '',
                    progress: _learning,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'personal/mined',
            builder: (BuildContext context, GoRouterState state) =>
                MinedInboxScreen(session: _staff),
          ),
          GoRoute(
            path: 'personal/mesa',
            builder: (BuildContext context, GoRouterState state) =>
                DeskInboxScreen(session: _staff),
            routes: <RouteBase>[
              GoRoute(
                path: 'caso/:id',
                builder: (BuildContext context, GoRouterState state) =>
                    DeskCaseScreen(
                      session: _staff,
                      caseId: state.pathParameters['id'] ?? '',
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'chat',
                    builder: (BuildContext context, GoRouterState state) =>
                        DeskChatScreen(
                          session: _staff,
                          caseId: state.pathParameters['id'] ?? '',
                        ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'personal/direccion',
            builder: (BuildContext context, GoRouterState state) =>
                DirectorInboxScreen(session: _staff),
            routes: <RouteBase>[
              GoRoute(
                path: 'cartel',
                builder: (BuildContext context, GoRouterState state) {
                  final StaffMembershipScope? scope = _staff.active;
                  return SchoolQrPosterScreen(
                    school: ConfirmedSchool(
                      id: scope?.institutionId ?? '',
                      publicCode: scope?.institutionPublicCode ?? '',
                      name: scope?.institutionName ?? 'Tu colegio',
                      municipality: '',
                      department: '',
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'caso/:id',
                builder: (BuildContext context, GoRouterState state) =>
                    DirectorCaseScreen(
                      session: _staff,
                      caseId: state.pathParameters['id'] ?? '',
                    ),
              ),
            ],
          ),
          GoRoute(
            path: 'personal',
            builder: (BuildContext context, GoRouterState state) =>
                StaffLoginScreen(session: _staff),
            routes: <RouteBase>[
              GoRoute(
                path: 'activar',
                builder: (BuildContext context, GoRouterState state) =>
                    StaffActivationScreen(session: _staff),
              ),
              GoRoute(
                path: 'ambito',
                builder: (BuildContext context, GoRouterState state) =>
                    StaffScopeScreen(session: _staff),
              ),
            ],
          ),
          for (final WelcomeDestination destination
              in WelcomeDestination.values)
            GoRoute(
              path: destination.path,
              pageBuilder: (context, state) => studentTransition(
                context,
                state,
                WelcomePreviewScreen(destination: destination),
              ),
            ),
          if (widget.showM1Verification)
            GoRoute(
              path: 'verificacion-m1',
              builder: (BuildContext context, GoRouterState state) =>
                  ValueListenableBuilder<int>(
                    valueListenable: _revision,
                    builder: (BuildContext context, int value, Widget? child) =>
                        _home(context),
                  ),
            ),
        ],
      ),
    ],
  );
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  /// Guía de navegación por sesión. Mientras haya una sesión abierta
  /// (personal con ingreso o estudiante con colegio confirmado) no se puede
  /// volver a la bienvenida ni cambiar de código o de rol: primero hay que
  /// «Cerrar sesión» o «Salir del colegio». No es control de acceso: los
  /// permisos los aplica el servidor en cada consulta.
  String? _sessionRedirect(BuildContext context, GoRouterState state) {
    // Enlace del cartel abierto desde fuera de la app.
    if (state.uri.scheme == 'setu' && state.uri.host == 'colegio') {
      final String? code = extractSchoolCode(state.uri.toString());
      return code == null ? '/colegio' : '/colegio/enlace/$code';
    }
    final String location = state.matchedLocation;
    if (widget.showM1Verification && location == '/verificacion-m1') {
      return null;
    }
    final bool personal = location.startsWith('/personal');
    final StaffMembershipScope? active = _staff.active;
    if (_staff.memberships.isNotEmpty) {
      if (location == '/personal/activar') return null;
      if (active == null) {
        return location == '/personal/ambito' ? null : '/personal/ambito';
      }
      return location.startsWith(active.role.path) ? null : active.role.path;
    }
    if (_session.school != null) {
      final bool entry =
          location == '/' || location.startsWith('/colegio') || personal;
      return entry ? '/inicio' : null;
    }
    if (!personal ||
        location == '/personal' ||
        location == '/personal/activar') {
      return null;
    }
    return '/personal';
  }

  void _update(VoidCallback action) {
    setState(action);
    _revision.value++;
  }

  bool _large = false;
  bool _verified = false;
  bool _storageReady = false;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    _learningLifecycle = AppLifecycleListener(
      onResume: () {
        _learning.refreshDay();
        _support.refreshChat();
      },
    );
    _session.addListener(_syncSchool);
    // Al abrir, cada sesión guardada se restaura y la guía de rutas lleva a
    // su superficie: el colegio del estudiante o el ámbito del personal.
    _session.open();
    _support.open();
    _staff.restore();
    if (widget.showM1Verification) {
      _security.addListener(_refresh);
      _security.initialize();
      _open();
    } else if (widget.allowDesignCapture) {
      _security.setSecureScreen(false);
    }
  }

  /// Las alertas se registran en el colegio activo del estudiante.
  void _syncSchool() {
    final String? code = _session.school?.publicCode;
    if (code != null) _support.schoolCode = code;
  }

  void _refresh() {
    if (mounted) _update(() {});
  }

  Future<void> _open() async {
    try {
      final CureandoGateway gateway =
          widget.gateway ?? await LocalCureandoGateway.onDevice();
      await gateway.initialize();
      if (mounted) {
        _update(() {
          _storageReady = true;
          _storageError = null;
        });
      }
    } on Object {
      if (mounted) {
        _update(
          () => _storageError =
              'No se pudo abrir el almacenamiento protegido. No se borraron los datos.',
        );
      }
    }
  }

  @override
  void dispose() {
    _learningLifecycle.dispose();
    if (widget.learningProgress == null) _learning.dispose();
    if (widget.supportFlow == null) _support.dispose();
    _session.removeListener(_syncSchool);
    if (widget.studentSession == null) _session.dispose();
    if (widget.showM1Verification) {
      _security.removeListener(_refresh);
    }
    if ((widget.showM1Verification || widget.allowDesignCapture) &&
        widget.screenSecurity == null) {
      _security.dispose();
    }
    _router.dispose();
    _staff.dispose();
    _revision.dispose();
    super.dispose();
  }

  Future<void> _setProtection(bool enabled) async {
    if (!enabled) {
      final bool confirm =
          await showDialog<bool>(
            context: _router.routerDelegate.navigatorKey.currentContext!,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Permitir capturas y proyección'),
              content: const Text(
                'La pantalla podrá aparecer en capturas y proyección. Usa únicamente datos ficticios. La protección vuelve al reiniciar la aplicación.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Permitir'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirm || !mounted) return;
    }
    await _security.setSecureScreen(enabled);
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );
  Widget _home(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SéTú')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CureandoTheme.blueSoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SetuBrandMark(size: 72),
                        const SizedBox(height: 20),
                        Text(
                          'SéTú',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: CureandoTheme.blue,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu voz importa.',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pedir apoyo también es cuidar. Estamos construyendo un espacio para ti y para quienes quieren ser testigos solidarios.',
                        ),
                        const SizedBox(height: 20),
                        const Wrap(
                          spacing: 16,
                          children: <Widget>[
                            BrandDecoration(
                              motif: BrandMotif.puzzle,
                              color: CureandoTheme.blue,
                            ),
                            BrandDecoration(
                              motif: BrandMotif.flower,
                              color: CureandoTheme.pink,
                            ),
                            BrandDecoration(
                              motif: BrandMotif.spiral,
                              color: CureandoTheme.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(context, 'Guardado protegido en este teléfono', <
                    Widget
                  >[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _storageError ??
                            (_storageReady
                                ? 'Almacenamiento local cifrado listo.'
                                : 'Abriendo almacenamiento protegido…'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Los datos guardados permanecerán al cerrar la app. Todavía no se envían a un centro ni se sincronizan con otros dispositivos.',
                    ),
                    if (_storageError != null)
                      TextButton(
                        onPressed: _open,
                        child: const Text('Reintentar apertura'),
                      ),
                  ]),
                  _section(context, 'Privacidad de pantalla', <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Proteger pantalla'),
                      subtitle: Text(
                        _security.enabled
                            ? 'Capturas y proyección bloqueadas.'
                            : 'Capturas y proyección permitidas · solo datos ficticios.',
                      ),
                      value: _security.enabled,
                      onChanged: _security.busy ? null : _setProtection,
                    ),
                    if (_security.error != null)
                      Text(
                        _security.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ]),
                  _section(context, 'Tamaño de lectura', <Widget>[
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: const Text('Normal'),
                          selected: !_large,
                          onSelected: (_) => _update(() => _large = false),
                        ),
                        ChoiceChip(
                          label: const Text('Grande +20%'),
                          selected: _large,
                          onSelected: (_) => _update(() => _large = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'También respetamos el tamaño de texto que elegiste en Android.',
                    ),
                  ]),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _storageReady
                        ? () => _update(() => _verified = true)
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Comprobar funcionamiento'),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _verified
                          ? '¡Listo! La interfaz responde correctamente.'
                          : 'Prueba la interfaz y los controles de esta base funcional.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CureandoTheme.yellowSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'M1 · Identidad y almacenamiento local. Los formularios de cuentas, reportes y seguimiento se integrarán en las próximas fases. Solo datos ficticios; no es un servicio de emergencias.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'SéTú',
    debugShowCheckedModeBanner: false,
    theme: CureandoTheme.light,
    routerConfig: _router,
    builder: (BuildContext context, Widget? child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: CureandoTheme.statusBarOverlayLight,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: CureandoTheme.readingScale(
            MediaQuery.textScalerOf(context),
            large: _large,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
