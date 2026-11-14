import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/cureando_models.dart';
import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import 'staff_backend.dart';
import 'staff_widgets.dart';

const TextStyle _title = TextStyle(
  fontSize: 30,
  height: 1.12,
  fontWeight: FontWeight.w700,
  color: CureandoTheme.ink,
);
const TextStyle _lead = TextStyle(fontSize: 17, height: 1.4);
const TextStyle _link = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

/// Ingreso de personal autorizado (`/personal`). El alumnado nunca pasa por
/// acá: sigue entrando sin cuenta, con el código de su colegio.
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(
        () => _error = 'Escribí tu correo institucional y tu contraseña.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? error = await widget.session.signIn(
      _email.text,
      _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      _password.clear();
      enterStaffArea(context, widget.session);
    }
  }

  @override
  Widget build(BuildContext context) => CampaignScreen(
    header: Column(
      children: <Widget>[
        const SizedBox(height: 44),
        Semantics(
          label: 'SéTú',
          excludeSemantics: true,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CampaignSymbol(size: 54, showUnicef: false),
              SizedBox(width: 12),
              Text(
                'SéTú',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const SizedBox(
          height: 46,
          width: double.infinity,
          child: CustomPaint(painter: _WavePainter()),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(27, 8, 27, 24),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: const Text('Personal autorizado', style: _title),
            ),
            const SizedBox(height: 12),
            const Text('Ingresá con tu cuenta institucional.', style: _lead),
            if (widget.session.backend.isDemo) ...<Widget>[
              const SizedBox(height: 12),
              const StaffNotice(
                'Demostración sin conexión al servidor. Solo datos ficticios.',
                error: false,
              ),
            ],
            const SizedBox(height: 24),
            StaffField(
              label: 'Correo institucional',
              controller: _email,
              hint: 'nombre@colegio.edu.ni',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.username],
            ),
            const SizedBox(height: 18),
            StaffField(
              label: 'Contraseña',
              controller: _password,
              hint: 'Ingresá tu contraseña',
              obscure: _hidden,
              onToggleObscure: () => setState(() => _hidden = !_hidden),
              autofillHints: const <String>[AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              StaffNotice(_error!),
            ],
            const SizedBox(height: 24),
            StaffPrimaryButton(
              label: 'Ingresar',
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: flowSecondaryStyle(),
              onPressed: () => context.push('/personal/activar'),
              child: const Text('Activar mi cuenta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver a la bienvenida', style: _link),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * .45)
        ..cubicTo(w * .3, -h * .2, w * .62, h * 1.15, w, h * .3)
        ..lineTo(w, h + 1)
        ..lineTo(0, h + 1)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}

enum _ActivationStep { code, account, email }

/// Primer ingreso (`/personal/activar`): validar la invitación de un solo
/// uso, crear la contraseña, confirmar el correo y canjear el código. El rol
/// y el centro los decide el servidor, nunca un campo de esta pantalla.
class StaffActivationScreen extends StatefulWidget {
  const StaffActivationScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffActivationScreen> createState() => _StaffActivationScreenState();
}

class _StaffActivationScreenState extends State<StaffActivationScreen> {
  static const int _minPassword = 8;

  final TextEditingController _code = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();
  _ActivationStep _step = _ActivationStep.code;
  StaffActivationPreview? _preview;
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  StaffBackend get _backend => widget.session.backend;

  @override
  void dispose() {
    _code.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  /// Ejecuta una acción con espera visible. La acción devuelve el texto de
  /// error o null.
  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      error = await action();
    } on Object catch (failure) {
      error = staffErrorMessage(failure);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<String?> _validateCode() async {
    if (_code.text.trim().isEmpty) {
      return 'Escribí el código de activación.';
    }
    final StaffActivationPreview preview = await _backend.previewActivation(
      _code.text.trim(),
    );
    if (!preview.ok) {
      return activationErrorMessage(
        preview.error,
        remainingAttempts: preview.remainingAttempts,
      );
    }
    _preview = preview;
    return null;
  }

  Future<String?> _createAccount() async {
    final String email = _email.text.trim();
    if (!email.contains('@')) return 'Escribí tu correo institucional.';
    if (_password.text.length < _minPassword) {
      return 'La contraseña necesita al menos $_minPassword caracteres.';
    }
    if (_password.text != _repeat.text) {
      return 'Las dos contraseñas no coinciden.';
    }
    final StaffActivationPreview preview = await _backend.previewActivation(
      _code.text.trim(),
      email: email,
    );
    if (!preview.ok) {
      return activationErrorMessage(
        preview.error,
        remainingAttempts: preview.remainingAttempts,
      );
    }
    try {
      await _backend.signUp(email: email, password: _password.text);
    } on GatewayException catch (failure) {
      // Si la cuenta ya existía, la persona sigue al paso de confirmación e
      // ingresa con la contraseña que escribió.
      final String text = '${failure.code} ${failure.message}'.toLowerCase();
      if (!text.contains('already')) rethrow;
    }
    if (_backend.currentUserId != null && await _redeem() == null) {
      return null;
    }
    _step = _ActivationStep.email;
    return null;
  }

  Future<String?> _confirmEmail() async {
    await _backend.signIn(email: _email.text.trim(), password: _password.text);
    return _redeem();
  }

  /// Canjea el código con la sesión abierta y entra a la superficie del rol.
  Future<String?> _redeem() async {
    final StaffActivationRedemption result = await _backend.redeemActivation(
      _code.text.trim(),
    );
    if (!result.ok) {
      return activationErrorMessage(
        result.error,
        remainingAttempts: result.remainingAttempts,
      );
    }
    final String? error = await widget.session.refresh();
    if (error == null && mounted) enterStaffArea(context, widget.session);
    return error;
  }

  void _restart() => setState(() {
    _step = _ActivationStep.code;
    _preview = null;
    _error = null;
  });

  void _help() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheet) => SafeArea(
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
                  'Ayuda con tu acceso',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'El código de activación es personal, sirve una sola vez y '
                'vence. Te lo entrega quien administra los accesos de tu '
                'institución, junto con el correo institucional al que quedó '
                'asociado.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Si el código venció, ya se usó o no lo tenés, pedí uno nuevo '
                'por esa misma vía. No compartas tu código ni tu contraseña.',
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assigned(StaffActivationPreview preview) => Semantics(
    container: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDEAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.school_outlined,
              size: 44,
              color: CureandoTheme.ink,
            ),
            const VerticalDivider(
              width: 28,
              thickness: 1.5,
              color: CureandoTheme.blue,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    preview.institutionName == null
                        ? 'Ámbito asignado'
                        : 'Colegio asignado',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview.institutionName ??
                        preview.scopeLabel ??
                        'Sin centro específico',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (preview.role != null)
                    Text(
                      preview.role!.label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: CureandoTheme.secondaryInk,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  List<Widget> _codeStep() {
    final StaffActivationPreview? preview = _preview;
    return <Widget>[
      if (preview != null) ...<Widget>[
        _assigned(preview),
        const SizedBox(height: 24),
      ],
      Semantics(
        header: true,
        child: const Text('Código de activación', style: _title),
      ),
      const SizedBox(height: 10),
      const Text(
        'Ingresá el código que te entregaron para tu cuenta.',
        style: _lead,
      ),
      const SizedBox(height: 20),
      StaffField(
        label: 'Código de activación',
        controller: _code,
        hint: 'Ej. CCA-DIR-2026',
        capitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_preview != null) setState(() => _preview = null);
        },
        onSubmitted: (_) => _run(_validateCode),
      ),
    ];
  }

  List<Widget> _accountStep() => <Widget>[
    _assigned(_preview!),
    const SizedBox(height: 24),
    Semantics(
      header: true,
      child: const Text('Creá tu contraseña', style: _title),
    ),
    const SizedBox(height: 10),
    const Text(
      'Usá el correo institucional al que te entregaron el código.',
      style: _lead,
    ),
    const SizedBox(height: 20),
    StaffField(
      label: 'Correo institucional',
      controller: _email,
      hint: 'nombre@colegio.edu.ni',
      keyboardType: TextInputType.emailAddress,
      autofillHints: const <String>[AutofillHints.email],
    ),
    const SizedBox(height: 18),
    StaffField(
      label: 'Contraseña nueva',
      controller: _password,
      hint: 'Al menos $_minPassword caracteres',
      obscure: _hidden,
      onToggleObscure: () => setState(() => _hidden = !_hidden),
      autofillHints: const <String>[AutofillHints.newPassword],
    ),
    const SizedBox(height: 18),
    StaffField(
      label: 'Repetí la contraseña',
      controller: _repeat,
      hint: 'Escribí la misma contraseña',
      obscure: _hidden,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _run(_createAccount),
    ),
  ];

  List<Widget> _emailStep() => <Widget>[
    const Icon(
      Icons.mark_email_unread_outlined,
      size: 56,
      color: CureandoTheme.blue,
    ),
    const SizedBox(height: 16),
    Semantics(
      header: true,
      child: const Text('Revisá tu correo institucional', style: _title),
    ),
    const SizedBox(height: 10),
    const Text(
      'Si el correo es válido, vas a recibir un enlace para confirmarlo. '
      'Abrilo y después volvé a esta pantalla.',
      style: _lead,
    ),
    const SizedBox(height: 10),
    const Text(
      'Tu acceso se activa recién cuando el correo queda confirmado.',
      style: _lead,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (String label, Future<String?> Function() action) = switch (_step) {
      _ActivationStep.code when _preview == null => (
        'Validar código',
        _validateCode,
      ),
      _ActivationStep.code => (
        'Confirmar acceso',
        () async {
          _step = _ActivationStep.account;
          return null;
        },
      ),
      _ActivationStep.account => ('Crear mi cuenta', _createAccount),
      _ActivationStep.email => ('Ya confirmé mi correo', _confirmEmail),
    };
    return FlowScaffold(
      header: const FlowHeader(title: 'Confirmá tu acceso'),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaffPrimaryButton(
            label: label,
            busy: _busy,
            onPressed: () => _run(action),
          ),
          if (_step == _ActivationStep.code)
            TextButton(
              onPressed: _help,
              child: const Text('Necesito ayuda con mi acceso', style: _link),
            )
          else
            TextButton(
              onPressed: _busy ? null : _restart,
              child: const Text('Usar otro código', style: _link),
            ),
        ],
      ),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...switch (_step) {
              _ActivationStep.code => _codeStep(),
              _ActivationStep.account => _accountStep(),
              _ActivationStep.email => _emailStep(),
            },
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              StaffNotice(_error!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Selector de ámbito (`/personal/ambito`) cuando la persona tiene membresías
/// activas en más de un centro.
class StaffScopeScreen extends StatelessWidget {
  const StaffScopeScreen({super.key, required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context) => FlowScaffold(
    header: const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Text(
        '¿Dónde vas a trabajar?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    bottom: TextButton(
      onPressed: session.signOut,
      child: const Text('Cerrar sesión', style: _link),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Tu cuenta tiene acceso a más de un centro. Elegí uno; podés '
          'cambiarlo después desde «Mi sesión».',
          style: _lead,
        ),
        const SizedBox(height: 16),
        for (final StaffMembershipScope scope in session.memberships)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: CureandoTheme.blueSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFA5C1EF)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  session.choose(scope);
                  context.go(scope.role.path);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.school_outlined,
                        size: 36,
                        color: CureandoTheme.ink,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              scope.place,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              scope.role.label,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: CureandoTheme.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
