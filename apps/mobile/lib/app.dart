import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/theme/app_theme.dart';

class CureandoApp extends StatefulWidget {
  const CureandoApp({super.key});

  @override
  State<CureandoApp> createState() => _CureandoAppState();
}

class _CureandoAppState extends State<CureandoApp> {
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const _EnvironmentCheckScreen(),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cureando Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

class _EnvironmentCheckScreen extends StatefulWidget {
  const _EnvironmentCheckScreen();

  @override
  State<_EnvironmentCheckScreen> createState() =>
      _EnvironmentCheckScreenState();
}

class _EnvironmentCheckScreenState extends State<_EnvironmentCheckScreen> {
  bool _interactionVerified = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cureando Demo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.spa_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                      semanticLabel: 'Cureando',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Un primer paso para pedir apoyo',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estamos preparando un espacio para estudiantes que '
                    'necesitan apoyo ante situaciones de acoso escolar.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Prototipo con datos ficticios',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No envía reportes reales. No hay conexión con '
                            'un centro educativo ni un servicio de atención.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _interactionVerified = true);
                    },
                    icon: const Icon(Icons.touch_app_outlined),
                    label: const Text('Comprobar funcionamiento'),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _interactionVerified
                          ? '¡Listo! La interfaz responde correctamente.'
                          : 'Toca el botón para probar la interacción.',
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'M0 · Verificación del entorno Android\n'
                    'El recorrido de reportes se añadirá en las siguientes fases.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
