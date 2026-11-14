import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import 'school_location.dart';
import 'school_qr_scanner.dart';
import 'student_session.dart';

enum SchoolAccessStep {
  method(
    '',
    'Confirmá tu colegio',
    'Usá el código público que te dio tu colegio.',
  ),
  scan('qr', 'Escaneá el QR', 'Colocá el código dentro del recuadro.'),
  manual(
    'codigo',
    'Ingresá el código de tu colegio',
    'Te lo dio tu colegio. No te pedimos nombre ni carné.',
  ),
  proximity(
    'cercania',
    'Comprobá si estás cerca',
    'Primero revisá que este sea tu colegio.',
  ),
  result('resultado', 'Colegio confirmado');

  const SchoolAccessStep(this.path, this.title, [this.subtitle]);

  final String path;
  final String title;
  final String? subtitle;

  String get location => path.isEmpty ? '/colegio' : '/colegio/$path';
}

class SchoolAccessScreen extends StatelessWidget {
  const SchoolAccessScreen({
    super.key,
    required this.step,
    required this.session,
    this.proximity = SchoolProximity.unavailable,
    this.checkProximity = checkSchoolLocation,
    this.allowSimulation = false,
  });

  final SchoolAccessStep step;

  /// Sesión estudiantil: resuelve el código y guarda el colegio confirmado.
  final StudentSession session;
  final SchoolProximity proximity;
  final Future<SchoolProximity> Function() checkProximity;
  final bool allowSimulation;

  @override
  Widget build(BuildContext context) {
    final List<Widget> content = switch (step) {
      SchoolAccessStep.method => _chooseMethod(context),
      SchoolAccessStep.scan => _scan(context),
      SchoolAccessStep.manual => <Widget>[_ManualCodeForm(session: session)],
      SchoolAccessStep.proximity => <Widget>[
        _ProximityCheck(
          school: session.candidate ?? session.school,
          check: checkProximity,
          allowSimulation: allowSimulation,
        ),
      ],
      SchoolAccessStep.result => _showResult(context),
    };
    return CampaignScreen(
      header: _SchoolHeader(
        title: step == SchoolAccessStep.result ? proximity.title : step.title,
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
    SchoolQrScanner(
      resolve: (String code) async => await session.resolve(code) != null,
      onAccepted: () =>
          context.pushReplacement(SchoolAccessStep.proximity.location),
      onManual: () => context.pushReplacement(SchoolAccessStep.manual.location),
    ),
  ];

  List<Widget> _showResult(BuildContext context) => proximity.canContinue
      ? <Widget>[
          _SchoolBadge(
            icon: proximity == SchoolProximity.simulated
                ? Icons.science_outlined
                : Icons.check_rounded,
            ink: proximity == SchoolProximity.simulated
                ? CureandoTheme.blue
                : const Color(0xFF057634),
            background: proximity == SchoolProximity.simulated
                ? CureandoTheme.blueSoft
                : CureandoTheme.greenSoft,
          ),
          const SizedBox(height: 28),
          _SchoolCard(
            school: session.candidate ?? session.school,
            simulated: proximity == SchoolProximity.simulated,
          ),
          const SizedBox(height: 20),
          Text(proximity.message, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _SchoolButton(
            label: 'Continuar',
            onPressed: () {
              // El colegio queda guardado en este teléfono para no pedir
              // el código en cada ingreso.
              session.confirmCandidate();
              context.go('/inicio');
            },
          ),
        ]
      : <Widget>[
          const _SchoolBadge(
            icon: Icons.gps_off_rounded,
            ink: Color(0xFFA90855),
            background: CureandoTheme.pinkSoft,
          ),
          const SizedBox(height: 20),
          Text(proximity.message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _SchoolButton(label: 'Reintentar', onPressed: () => context.pop()),
          if (proximity == SchoolProximity.permissionBlocked ||
              proximity == SchoolProximity.permissionApproximate ||
              proximity == SchoolProximity.locationDisabled)
            TextButton(
              onPressed: proximity == SchoolProximity.locationDisabled
                  ? Geolocator.openLocationSettings
                  : Geolocator.openAppSettings,
              child: const Text('Abrir ajustes'),
            ),
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

class _ProximityCheck extends StatefulWidget {
  const _ProximityCheck({
    required this.school,
    required this.check,
    required this.allowSimulation,
  });

  final ConfirmedSchool? school;
  final Future<SchoolProximity> Function() check;
  final bool allowSimulation;

  @override
  State<_ProximityCheck> createState() => _ProximityCheckState();
}

class _ProximityCheckState extends State<_ProximityCheck> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    final SchoolProximity result = await widget.check();
    if (!mounted) return;
    setState(() => _checking = false);
    if (ModalRoute.isCurrentOf(context) == true) _openResult(result);
  }

  void _openResult(SchoolProximity result) =>
      context.push<void>(SchoolAccessStep.result.location, extra: result);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _SchoolCard(school: widget.school),
      const SizedBox(height: 24),
      const Text(
        'Usamos tu ubicación una vez para saber si estás cerca de este colegio. Tu ubicación exacta no se guarda.',
      ),
      const SizedBox(height: 32),
      _SchoolButton(
        label: _checking ? 'Comprobando cercanía…' : 'Comprobar cercanía',
        onPressed: _checking ? null : _check,
      ),
      if (widget.allowSimulation) ...<Widget>[
        const SizedBox(height: 12),
        _SchoolButton(
          label: 'Simular cercanía para la demo',
          outlined: true,
          onPressed: _checking
              ? null
              : () => _openResult(SchoolProximity.simulated),
        ),
      ],
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => context.go(SchoolAccessStep.method.location),
        child: const Text('Ahora no'),
      ),
    ],
  );
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
  const _ManualCodeForm({required this.session});

  final StudentSession session;

  @override
  State<_ManualCodeForm> createState() => _ManualCodeFormState();
}

class _ManualCodeFormState extends State<_ManualCodeForm> {
  static const int _codeLength = 6;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String? _error;
  bool _searching = false;

  Future<void> _continue() async {
    if (_searching) return;
    final String code = normalizeSchoolCode(_controller.text);
    if (code.length != _codeLength) {
      setState(() => _error = 'Ingresá los seis caracteres del código.');
      _focus.requestFocus();
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    final ConfirmedSchool? school = await widget.session.resolve(code);
    if (!mounted) return;
    setState(() => _searching = false);
    if (school == null) {
      setState(
        () => _error =
            'Ese código no corresponde a un colegio registrado. Revisá el código e intentá de nuevo.',
      );
      _focus.requestFocus();
      return;
    }
    _focus.unfocus();
    context.push<void>(SchoolAccessStep.proximity.location);
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _codeSlots(context),
      const SizedBox(height: 10),
      if (_error case final String error)
        Semantics(
          liveRegion: true,
          child: Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        )
      else
        const Text('Tiene seis caracteres. Está en el cartel de tu colegio.'),
      const SizedBox(height: 24),
      _SchoolButton(
        label: _searching ? 'Buscando tu colegio…' : 'Entrar',
        onPressed: _searching ? null : _continue,
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('o', textAlign: TextAlign.center),
      ),
      _SchoolButton(
        label: 'Escanear el QR del colegio',
        icon: Icons.qr_code_scanner_rounded,
        outlined: true,
        onPressed: () {
          _focus.unfocus();
          context.pushReplacement(SchoolAccessStep.scan.location);
        },
      ),
      const SizedBox(height: 16),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Podés comprobar la cercanía con tu ubicación. Tu ubicación exacta no se guarda.',
          ),
        ),
      ),
    ],
  );

  Widget _codeSlots(BuildContext context) => SizedBox(
    height: math.max(58.0, MediaQuery.textScalerOf(context).scale(22) + 24),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Semantics(
          label: 'Código del colegio, seis caracteres',
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            showCursor: false,
            style: const TextStyle(color: Colors.transparent),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(_codeLength),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _continue(),
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false,
            ),
          ),
        ),
        IgnorePointer(
          child: ExcludeSemantics(
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[_controller, _focus]),
              builder: (context, _) {
                final String value = _controller.text.toUpperCase();
                final int active = _controller.selection.isValid
                    ? math.min(
                        _controller.selection.extentOffset,
                        _codeLength - 1,
                      )
                    : 0;
                return Row(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < _codeLength;
                      index++
                    ) ...<Widget>[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              width: _focus.hasFocus && index == active
                                  ? 2.5
                                  : 1.5,
                              color: _focus.hasFocus && index == active
                                  ? CureandoTheme.blue
                                  : const Color(0xFFC6CDD8),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              index < value.length ? value[index] : '',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
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
  final VoidCallback? onPressed;
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
  const _SchoolCard({required this.school, this.simulated = false});

  final ConfirmedSchool? school;

  /// Solo el modo de simulación de cercanía rotula el colegio como prueba.
  final bool simulated;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CureandoTheme.blueSoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD8E4F5)),
    ),
    child: Row(
      children: <Widget>[
        SchoolCrest(school: school, size: 56),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                school?.displayName ?? 'Tu colegio',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (school case final ConfirmedSchool found)
                Text(
                  found.place,
                  style: const TextStyle(color: CureandoTheme.secondaryInk),
                ),
              if (simulated)
                const Text(
                  'Colegio de prueba · cercanía simulada',
                  style: TextStyle(color: CureandoTheme.secondaryInk),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Escudo oficial del colegio, o un ícono escolar si la app no lo tiene.
class SchoolCrest extends StatelessWidget {
  const SchoolCrest({super.key, required this.school, this.size = 40});

  final ConfirmedSchool? school;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String? asset = school?.crestAsset;
    return asset == null
        ? ExcludeSemantics(
            child: Icon(
              Icons.school_outlined,
              color: CureandoTheme.blue,
              size: size * .6,
            ),
          )
        : Image.asset(
            asset,
            width: size,
            height: size,
            semanticLabel: 'Escudo del ${school!.displayName}',
          );
  }
}
