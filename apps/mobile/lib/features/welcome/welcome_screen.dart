import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final TextStyle? buttonText = Theme.of(context).textTheme.labelLarge;
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );

    return CampaignScreen(
      header: const _CampaignHeader(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(27, 20, 27, 24),
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
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 52),
                shape: shape,
                textStyle: buttonText,
              ),
              onPressed: () => hasSchool?.call() ?? false
                  ? context.go('/inicio')
                  : context.push('/colegio'),
              icon: const Icon(Icons.school_rounded, size: 20),
              label: const Text(
                'Ingreso estudiantil',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                shape: shape,
                side: const BorderSide(color: Color(0xFFA5C1EF)),
                textStyle: buttonText,
              ),
              onPressed: () => context.go('/personal'),
              icon: const Icon(Icons.badge_outlined, size: 20),
              label: const Text(
                'Personal autorizado',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => context.push('/${WelcomeDestination.help.path}'),
              icon: const Icon(Icons.help_outline_rounded, size: 20),
              label: const Text('Ayuda'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignHeader extends StatefulWidget {
  const _CampaignHeader();

  @override
  State<_CampaignHeader> createState() => _CampaignHeaderState();
}

/// Alterna los dos titulares de campaña del Manual de Marca:
/// «Simplemente #SoloSéTú» y «Todos podemos encajar».
class _CampaignHeaderState extends State<_CampaignHeader> {
  static const Duration _every = Duration(seconds: 4);
  Timer? _timer;
  int _slide = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_every, (_) {
      if (mounted) setState(() => _slide = 1 - _slide);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _soloSetu() => Semantics(
    key: const ValueKey<String>('campaign-solosetu'),
    header: true,
    label: 'Simplemente #SoloSéTú',
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Image.asset(
            'assets/welcome/campaign-simplemente.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 4),
        Transform.rotate(
          angle: 0.95 * math.pi / 180,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Image.asset(
              'assets/welcome/campaign-solosetu.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _encajar() => Semantics(
    key: const ValueKey<String>('campaign-encajar'),
    header: true,
    label: 'Todos podemos encajar',
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Image.asset(
            'assets/welcome/campaign-todos-podemos.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Image.asset(
            'assets/welcome/campaign-encajar.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Stack(
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
          const SizedBox(height: 16),
          const CampaignSymbol(size: 38),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            // Alto fijo: el cambio de titular no mueve el resto de la pantalla.
            child: SizedBox(
              height: 146,
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                child: FittedBox(
                  key: ValueKey<int>(_slide),
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: _slide == 0 ? _soloSetu() : _encajar(),
                  ),
                ),
              ),
            ),
          ),
          const AspectRatio(aspectRatio: 392 / 168),
        ],
      ),
    ],
  );
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
