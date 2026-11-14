import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';

enum WelcomeDestination {
  information(
    'informacion',
    'Información',
    'Aquí vas a encontrar artículos, videos, testimonios y guías para comprender lo que sentís y conocer formas de pedir apoyo.',
  ),
  help(
    'ayuda',
    'Ayuda',
    'En este espacio vas a encontrar recursos de ayuda verificados para Nicaragua.',
  );

  const WelcomeDestination(this.path, this.title, this.description);

  final String path;
  final String title;
  final String description;
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.hasSchool});

  /// Indica si ya hay un colegio confirmado en este teléfono; con uno, el
  /// ingreso estudiantil entra directo al inicio.
  final bool Function()? hasSchool;

  static const TextStyle _caption = TextStyle(
    fontSize: 14,
    height: 1.35,
    color: CureandoTheme.secondaryInk,
  );

  void _showPrivacy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      barrierLabel: 'Cerrar privacidad',
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (BuildContext context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  'Cómo cuidamos tu información',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Si pedís apoyo, solo vos y el equipo de escucha asignado pueden leer tu relato y tu chat. El MINED y tu colegio reciben datos limitados para dar seguimiento. Lo que escribás puede revelar quién sos.',
              ),
              const SizedBox(height: 8),
              const Text('Esta es una prueba de navegación.'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? buttonText = Theme.of(context).textTheme.labelLarge;
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );

    return CampaignScreen(
      header: const _CampaignHeader(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(27, 24, 27, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Aquí podés aprender sobre lo que sentís y conocer cómo pedir apoyo en tu colegio.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, height: 1.5),
              ),
            ),
            const SizedBox(height: 34),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: shape,
                textStyle: buttonText,
              ),
              onPressed: () => hasSchool?.call() ?? false
                  ? context.go('/inicio')
                  : context.push('/colegio'),
              child: const Text(
                'Ingreso estudiantil',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Entrás con el código de tu colegio, sin nombre ni correo.',
              textAlign: TextAlign.center,
              style: _caption,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                shape: shape,
                side: const BorderSide(color: Color(0xFFA5C1EF)),
                textStyle: buttonText,
              ),
              onPressed: () => context.push('/personal'),
              icon: const Icon(Icons.badge_outlined),
              label: const Text(
                'Personal autorizado',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Para Dirección, Mesa de Escucha y MINED.',
              textAlign: TextAlign.center,
              style: _caption,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/${WelcomeDestination.help.path}'),
              child: const Text('Ayuda'),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: CureandoTheme.secondaryInk,
              ),
              onPressed: () => _showPrivacy(context),
              child: const Text(
                'Cómo cuidamos tu información',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader();

  @override
  Widget build(BuildContext context) {
    const TextStyle title = TextStyle(
      color: Colors.white,
      fontSize: 29,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    return Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AspectRatio(
            aspectRatio: 392 / 180,
            child: Image.asset(
              'assets/welcome/campaign-characters.png',
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
        Column(
          children: <Widget>[
            const SizedBox(height: 24),
            const CampaignSymbol(size: 45),
            const SizedBox(height: 23),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                header: true,
                label: 'Tu salud mental sí importa',
                excludeSemantics: true,
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Tu salud mental',
                      style: title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CureandoTheme.pink,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'sí importa',
                        style: title.copyWith(fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AspectRatio(aspectRatio: 392 / 166),
          ],
        ),
      ],
    );
  }
}

class WelcomePreviewScreen extends StatelessWidget {
  const WelcomePreviewScreen({super.key, required this.destination});

  final WelcomeDestination destination;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text(destination.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Vista de demostración', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(destination.description),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
