import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';

enum SchoolAccessStep {
  method(
    '',
    'Confirmá tu colegio',
    'Usá el código público que te dio tu colegio.',
  ),
  scan('qr', 'Escaneá el QR', 'Colocá el código dentro del recuadro.'),
  manual('codigo', 'Escribí el código', 'Tu colegio te comparte el código.'),
  proximity(
    'cercania',
    'Comprobá si estás cerca',
    'Primero revisá que este sea tu colegio.',
  ),
  result('resultado', 'Colegio confirmado'),
  home('inicio', 'Inicio');

  const SchoolAccessStep(this.path, this.title, [this.subtitle]);

  final String path;
  final String title;
  final String? subtitle;

  String get location => path.isEmpty ? '/colegio' : '/colegio/$path';
}

enum SchoolProximity { nearby, unconfirmed }

class SchoolAccessScreen extends StatelessWidget {
  const SchoolAccessScreen({
    super.key,
    required this.step,
    this.proximity = SchoolProximity.unconfirmed,
  });

  final SchoolAccessStep step;
  final SchoolProximity proximity;

  @override
  Widget build(BuildContext context) {
    final bool confirmed = proximity == SchoolProximity.nearby;
    final List<Widget> content = switch (step) {
      SchoolAccessStep.method => _chooseMethod(context),
      SchoolAccessStep.scan => _scan(context),
      SchoolAccessStep.manual => <Widget>[const _ManualCodeForm()],
      SchoolAccessStep.proximity => _checkProximity(context),
      SchoolAccessStep.result => _showResult(context, confirmed),
      SchoolAccessStep.home => <Widget>[
        const _SchoolCard(),
        const SizedBox(height: 18),
        const Text('Vista de demostración', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ..._supportActions(context),
      ],
    };
    return CampaignScreen(
      header: _SchoolHeader(
        title: step == SchoolAccessStep.result && !confirmed
            ? 'Cercanía sin confirmar'
            : step.title,
        subtitle: step.subtitle,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: content,
        ),
      ),
    );
  }

  List<Widget> _chooseMethod(BuildContext context) => <Widget>[
    const SizedBox(height: 10),
    const _SchoolBadge(
      icon: Icons.qr_code_scanner_rounded,
      ink: CureandoTheme.blue,
      background: CureandoTheme.blueSoft,
    ),
    const SizedBox(height: 22),
    const Text(
      'Buscá el QR en el cartel de tu colegio.',
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: 36),
    _SchoolButton(
      label: 'Escanear QR',
      icon: Icons.qr_code_scanner_rounded,
      onPressed: () => context.push<void>(SchoolAccessStep.scan.location),
    ),
    const SizedBox(height: 12),
    _SchoolButton(
      label: 'Escribir código',
      icon: Icons.keyboard_alt_outlined,
      outlined: true,
      onPressed: () => context.push<void>(SchoolAccessStep.manual.location),
    ),
    const SizedBox(height: 16),
    TextButton(
      onPressed: () => context.push<void>('/informacion'),
      child: const Text('Explorar Información', textAlign: TextAlign.center),
    ),
  ];

  List<Widget> _scan(BuildContext context) => <Widget>[
    const _ScanPreview(),
    const SizedBox(height: 14),
    const Text('Vista de demostración', textAlign: TextAlign.center),
    const SizedBox(height: 20),
    _SchoolButton(
      label: 'Simular escaneo',
      onPressed: () => context.push<void>(
        SchoolAccessStep.proximity.location,
        extra: SchoolProximity.nearby,
      ),
    ),
    const SizedBox(height: 12),
    _SchoolButton(
      label: 'Escribir código',
      icon: Icons.keyboard_alt_outlined,
      outlined: true,
      onPressed: () =>
          context.pushReplacement(SchoolAccessStep.manual.location),
    ),
  ];

  List<Widget> _checkProximity(BuildContext context) => <Widget>[
    const _SchoolCard(),
    const SizedBox(height: 24),
    const Text(
      'En la versión real, usaríamos tu ubicación una vez para saber si estás cerca de este colegio. Tu ubicación exacta no se guardaría.',
    ),
    const SizedBox(height: 12),
    const Text('Esta comprobación es simulada.'),
    const SizedBox(height: 32),
    _SchoolButton(
      label: 'Comprobar cercanía',
      onPressed: () => context.push<void>(
        SchoolAccessStep.result.location,
        extra: proximity,
      ),
    ),
    const SizedBox(height: 12),
    TextButton(
      onPressed: () => context.go(SchoolAccessStep.method.location),
      child: const Text('Ahora no'),
    ),
  ];

  List<Widget> _showResult(BuildContext context, bool confirmed) => confirmed
      ? <Widget>[
          const _SchoolBadge(
            icon: Icons.check_rounded,
            ink: Color(0xFF057634),
            background: CureandoTheme.greenSoft,
          ),
          const SizedBox(height: 28),
          const _SchoolCard(),
          const SizedBox(height: 20),
          const Text('Comprobación simulada', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _SchoolButton(
            label: 'Continuar',
            onPressed: () => context.push<void>(SchoolAccessStep.home.location),
          ),
        ]
      : <Widget>[
          const _SchoolBadge(
            icon: Icons.gps_off_rounded,
            ink: Color(0xFFA90855),
            background: CureandoTheme.pinkSoft,
          ),
          const SizedBox(height: 20),
          const Text(
            'Revisá si estás cerca del colegio y si tu ubicación está disponible.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text('Comprobación simulada', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _SchoolButton(label: 'Reintentar', onPressed: () => context.pop()),
          const SizedBox(height: 12),
          ..._supportActions(context),
        ];

  List<Widget> _supportActions(BuildContext context) => <Widget>[
    _SchoolButton(
      label: 'Explorar Información',
      outlined: true,
      onPressed: () => context.push<void>('/informacion'),
    ),
    const SizedBox(height: 12),
    TextButton(
      onPressed: () => context.push<void>('/ayuda'),
      child: const Text('Ayuda'),
    ),
  ];
}

class _SchoolHeader extends StatelessWidget {
  const _SchoolHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 22),
    child: Column(
      children: <Widget>[
        SizedBox(
          height: 48,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: () => context.pop(),
                  color: Colors.white,
                  tooltip: 'Volver',
                  icon: const BackButtonIcon(),
                ),
              ),
              const Center(child: CampaignSymbol(size: 27)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
        if (subtitle case final String text) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ManualCodeForm extends StatefulWidget {
  const _ManualCodeForm();

  @override
  State<_ManualCodeForm> createState() => _ManualCodeFormState();
}

class _ManualCodeFormState extends State<_ManualCodeForm> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  void _continue() {
    final SchoolProximity? result = switch (_controller.text
        .trim()
        .toUpperCase()) {
      'AULA-24' => SchoolProximity.nearby,
      'AULA-00' => SchoolProximity.unconfirmed,
      _ => null,
    };
    if (result == null) {
      setState(() => _error = 'Ingresá uno de los códigos de muestra.');
      return;
    }
    FocusScope.of(context).unfocus();
    context.push<void>(SchoolAccessStep.proximity.location, extra: result);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SizedBox(height: 18),
      const ExcludeSemantics(
        child: Text(
          'Código del colegio',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 10),
      Semantics(
        label: 'Código del colegio',
        child: TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _continue(),
          decoration: InputDecoration(
            hintText: 'AULA-24',
            helperText: 'Probá AULA-24 o AULA-00',
            helperMaxLines: 3,
            errorText: _error,
            errorMaxLines: 3,
          ),
        ),
      ),
      const SizedBox(height: 36),
      _SchoolButton(label: 'Continuar', onPressed: _continue),
      const SizedBox(height: 12),
      _SchoolButton(
        label: 'Escanear QR',
        icon: Icons.qr_code_scanner_rounded,
        outlined: true,
        onPressed: () {
          FocusScope.of(context).unfocus();
          context.pushReplacement(SchoolAccessStep.scan.location);
        },
      ),
    ],
  );
}

class _SchoolButton extends StatelessWidget {
  const _SchoolButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon case final IconData data) ...<Widget>[
          Icon(data, size: 20),
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );
    return outlined
        ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 52),
              shape: shape,
              side: const BorderSide(color: Color(0xFFA9C3EE)),
            ),
            onPressed: onPressed,
            child: child,
          )
        : FilledButton(
            style: FilledButton.styleFrom(shape: shape),
            onPressed: onPressed,
            child: child,
          );
  }
}

class _SchoolBadge extends StatelessWidget {
  const _SchoolBadge({
    required this.icon,
    required this.ink,
    required this.background,
  });

  final IconData icon;
  final Color ink;
  final Color background;

  @override
  Widget build(BuildContext context) => Center(
    child: ExcludeSemantics(
      child: CircleAvatar(
        radius: 45,
        backgroundColor: background,
        child: Icon(icon, color: ink, size: 43),
      ),
    ),
  );
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CureandoTheme.blueSoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD8E4F5)),
    ),
    child: const Row(
      children: <Widget>[
        Icon(Icons.school_outlined, color: CureandoTheme.blue),
        SizedBox(width: 12),
        Flexible(
          child: Text(
            'Colegio de demostración',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ScanPreview extends StatelessWidget {
  const _ScanPreview();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 222,
      decoration: BoxDecoration(
        color: const Color(0xFF10244A),
        borderRadius: BorderRadius.circular(21),
      ),
      alignment: Alignment.center,
      child: const SizedBox.square(
        dimension: 140,
        child: CustomPaint(
          foregroundPainter: _ScanCorners(),
          child: ColoredBox(
            color: Color(0xFF172F57),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 62,
              color: Color(0xFFA6BAE1),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ScanCorners extends CustomPainter {
  const _ScanCorners();

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 2;
    const double length = 22;
    final double right = size.width - inset;
    final double bottom = size.height - inset;
    final Path corners = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(right - length, inset)
      ..lineTo(right, inset)
      ..lineTo(right, inset + length)
      ..moveTo(inset, bottom - length)
      ..lineTo(inset, bottom)
      ..lineTo(inset + length, bottom)
      ..moveTo(right - length, bottom)
      ..lineTo(right, bottom)
      ..lineTo(right, bottom - length);
    canvas.drawPath(
      corners,
      Paint()
        ..color = CureandoTheme.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_ScanCorners oldDelegate) => false;
}
