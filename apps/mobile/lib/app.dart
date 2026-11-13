import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/learning_progress.dart';
import 'features/home/streak_screen.dart';
import 'features/home/student_home_screen.dart';
import 'features/home/student_resources.dart';
import 'features/piece/piece_editor_screen.dart';
import 'features/piece/student_piece.dart';
import 'features/school_access/school_access_screen.dart';
import 'features/school_access/school_location.dart';
import 'features/support/alert_screens.dart';
import 'features/support/support_flow.dart';
import 'features/support/support_screens.dart';
import 'features/welcome/welcome_screen.dart';
import 'shared/contracts/cureando_gateway.dart';
import 'shared/local/local_cureando_gateway.dart';
import 'shared/platform/screen_security_controller.dart';
import 'shared/remote/setu_remote_gateway.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/setu_brand_mark.dart';
import 'shared/widgets/student_transition.dart';

class CureandoApp extends StatefulWidget {
  const CureandoApp({
    super.key,
    this.gateway,
    this.remoteGateway,
    this.learningProgress,
    this.supportFlow,
    this.screenSecurity,
    this.showM1Verification = false,
    this.allowDesignCapture = false,
    this.allowSchoolSimulation = false,
    this.checkSchoolProximity = checkSchoolLocation,
  });
  final CureandoGateway? gateway;
  final SetuRemoteGateway? remoteGateway;
  final LearningProgress? learningProgress;
  final SupportFlow? supportFlow;
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
  late final SupportFlow _support =
      widget.supportFlow ?? SupportFlow(remote: widget.remoteGateway);
  final ValueNotifier<StudentPiece> _piece = ValueNotifier<StudentPiece>(
    StudentPiece.initial,
  );
  late final ScreenSecurityController _security =
      widget.screenSecurity ?? ScreenSecurityController();
  late final GoRouter _router = GoRouter(
    initialLocation: widget.showM1Verification ? '/verificacion-m1' : '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const WelcomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'colegio',
            pageBuilder: (context, state) => studentTransition(
              context,
              state,
              const SchoolAccessScreen(step: SchoolAccessStep.method),
            ),
            routes: <RouteBase>[
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
                  PieceEditorScreen(piece: _piece),
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
                        'revisar': () => AlertReviewScreen(flow: _support),
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
            path: 'prueba-mesh',
            pageBuilder: (context, state) => studentTransition(
              context,
              state,
              MeshTestScreen(remoteGateway: widget.remoteGateway),
            ),
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
    _learningLifecycle = AppLifecycleListener(onResume: _learning.refreshDay);
    if (widget.showM1Verification) {
      _security.addListener(_refresh);
      _security.initialize();
      _open();
    } else if (widget.allowDesignCapture) {
      _security.setSecureScreen(false);
    }
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
    _piece.dispose();
    if (widget.showM1Verification) {
      _security.removeListener(_refresh);
    }
    if ((widget.showM1Verification || widget.allowDesignCapture) &&
        widget.screenSecurity == null) {
      _security.dispose();
    }
    _router.dispose();
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
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: CureandoTheme.readingScale(
          MediaQuery.textScalerOf(context),
          large: _large,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
