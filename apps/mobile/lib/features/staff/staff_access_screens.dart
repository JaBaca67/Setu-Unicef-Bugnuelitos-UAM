import 'dart:async';

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
  bool _needsRegistrationCompletion = false;
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
      setState(() {
        _needsRegistrationCompletion = false;
        _error = 'Escribí tu correo institucional y tu contraseña.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _needsRegistrationCompletion = false;
      _error = null;
    });
    final String? error = await widget.session.signIn(
      _email.text,
      _password.text,
    );
    if (!mounted) return;
    if (widget.session.isAuthenticated && widget.session.memberships.isEmpty) {
      setState(() {
        _busy = false;
        _needsRegistrationCompletion = true;
        _error =
            'Esta cuenta todavía no completó su registro con el código '
            'individual y tu nombre. Completá ese paso para iniciar sesión.';
      });
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      _password.clear();
      enterStaffArea(context, widget.session);
    }
  }

  Future<void> _leaveToWelcome() async {
    if (widget.session.isAuthenticated && widget.session.memberships.isEmpty) {
      await widget.session.signOut();
    }
    if (mounted) context.go('/');
  }

  Future<void> _openRegistration() async {
    if (_needsRegistrationCompletion &&
        widget.session.isAuthenticated &&
        widget.session.memberships.isEmpty) {
      context.push('/personal/activar');
      return;
    }
    if (widget.session.isAuthenticated && widget.session.memberships.isEmpty) {
      await widget.session.signOut();
    }
    if (mounted) context.push('/personal/activar');
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
              onChanged: (_) {
                if (_needsRegistrationCompletion) {
                  setState(() {
                    _needsRegistrationCompletion = false;
                    _error = null;
                  });
                  if (widget.session.memberships.isEmpty &&
                      widget.session.isAuthenticated) {
                    widget.session.signOut();
                  }
                }
              },
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
            if (_needsRegistrationCompletion) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _openRegistration,
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Continuar mi registro con código'),
              ),
            ],
            const SizedBox(height: 24),
            StaffPrimaryButton(
              label: 'Iniciar sesión',
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: flowSecondaryStyle(),
              onPressed: _openRegistration,
              child: const Text('Registrar cuenta'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: flowSecondaryStyle(),
              onPressed: () => context.push('/personal/solicitar'),
              child: const Text('Solicitar acceso'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/personal/ayuda'),
              child: const Text('Necesito ayuda con mi acceso', style: _link),
            ),
            TextButton(
              onPressed: _leaveToWelcome,
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

enum _ActivationStep { account, email, codeAndProfile }

/// Primer ingreso (`/personal/activar`): crear cuenta con correo institucional
/// y contraseña, confirmar el correo mediante el enlace, validar el código de
/// un solo uso y completar nombre y apellidos antes de entrar. El rol y el
/// ámbito provienen siempre del servidor.
class StaffActivationScreen extends StatefulWidget {
  const StaffActivationScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffActivationScreen> createState() => _StaffActivationScreenState();
}

class _StaffActivationScreenState extends State<StaffActivationScreen> {
  static const int _minPassword = 8;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();

  late _ActivationStep _step;
  AppLifecycleListener? _lifecycle;
  StreamSubscription<void>? _authSubscription;
  StaffActivationPreview? _preview;
  bool _hidden = true;
  bool _busy = false;
  String? _error;
  String? _info;

  StaffBackend get _backend => widget.session.backend;

  @override
  void initState() {
    super.initState();
    if (_backend.currentUserId != null) {
      _email.text = _backend.currentUserEmail ?? '';
      _step = _backend.isEmailConfirmed
          ? _ActivationStep.codeAndProfile
          : _ActivationStep.email;
    } else {
      _step = _ActivationStep.account;
    }
    _authSubscription = _backend.authStateChanges().listen((_) {
      _syncConfirmedFromAuth();
    });
    _lifecycle = AppLifecycleListener(onResume: _checkConfirmedOnResume);
  }

  void _syncConfirmedFromAuth() {
    if (!mounted) return;
    if (_backend.currentUserId == null) return;
    final String activeEmail = (_backend.currentUserEmail ?? '').trim();
    if (activeEmail.isNotEmpty && _email.text.trim().isEmpty) {
      _email.text = activeEmail;
    }
    if (_backend.isEmailConfirmed && _step != _ActivationStep.codeAndProfile) {
      setState(() {
        _step = _ActivationStep.codeAndProfile;
        _error = null;
        _info = null;
      });
    } else if (!_backend.isEmailConfirmed && _step == _ActivationStep.account) {
      setState(() {
        _step = _ActivationStep.email;
        _error = null;
      });
    }
  }

  Future<void> _checkConfirmedOnResume() async {
    if (!mounted || _busy || _step == _ActivationStep.codeAndProfile) return;
    if (_backend.currentUserId != null) {
      try {
        await _backend.refreshAuthSession();
      } on Object {
        return;
      }
      _syncConfirmedFromAuth();
      return;
    }
    if (_step == _ActivationStep.email &&
        _email.text.trim().contains('@') &&
        _password.text.isNotEmpty) {
      try {
        await _backend.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      } on Object {
        return;
      }
      _syncConfirmedFromAuth();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _lifecycle?.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    _code.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  /// Ejecuta una acción con espera visible. La acción devuelve el texto de
  /// error o null.
  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
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

  Future<String?> _createAccount() async {
    final String email = _email.text.trim();
    if (!email.contains('@')) return 'Escribí tu correo institucional.';
    if (_password.text.length < _minPassword) {
      return 'La contraseña necesita al menos $_minPassword caracteres.';
    }
    if (_password.text != _repeat.text) {
      return 'Las dos contraseñas no coinciden.';
    }
    try {
      await _backend.signUp(email: email, password: _password.text);
    } on GatewayException catch (failure) {
      final String text = '${failure.code} ${failure.message}'.toLowerCase();
      if (!text.contains('already')) rethrow;
      // Si la cuenta ya existe, intenta iniciar sesión o avanzar a confirmar
      // correo si todavía está pendiente.
      try {
        await _backend.signIn(email: email, password: _password.text);
      } on GatewayException catch (signFailure) {
        final String signMsg =
            '${signFailure.code} ${signFailure.message}'.toLowerCase();
        if (signMsg.contains('email_not_confirmed')) {
          _step = _ActivationStep.email;
          return null;
        }
        rethrow;
      }
    }
    if (_backend.currentUserId != null && _backend.isEmailConfirmed) {
      final String? membershipError = await widget.session.refresh();
      if (membershipError == null && widget.session.memberships.isNotEmpty) {
        await widget.session.signOut();
        return 'Esta cuenta ya completó su registro. Volvé atrás y usá '
            '«Iniciar sesión» para ingresar.';
      }
      _step = _ActivationStep.codeAndProfile;
      return null;
    }
    _step = _ActivationStep.email;
    return null;
  }

  Future<String?> _resendLink() async {
    final String email = (_backend.currentUserEmail ?? _email.text).trim();
    if (!email.contains('@')) {
      return 'Escribí tu correo institucional para reenviar el enlace.';
    }
    await _backend.resendConfirmationEmail(email: email);
    _info = 'Si la cuenta está pendiente de verificación, reenviamos el '
        'enlace a $email.';
    return null;
  }

  Future<String?> _confirmEmail() async {
    final String email = (_backend.currentUserEmail ?? _email.text).trim();
    if (_backend.currentUserId != null) {
      await _backend.refreshAuthSession();
    } else {
      if (!email.contains('@') || _password.text.isEmpty) {
        return 'Ingresá con tu correo y contraseña luego de abrir el enlace.';
      }
      await _backend.signIn(email: email, password: _password.text);
    }
    if (_backend.currentUserId == null || !_backend.isEmailConfirmed) {
      return 'Todavía no vemos tu correo confirmado. Abrí el enlace que te '
          'enviamos e intentá de nuevo.';
    }
    final String? membershipError = await widget.session.refresh();
    if (membershipError == null && widget.session.memberships.isNotEmpty) {
      if (mounted) enterStaffArea(context, widget.session);
      return null;
    }
    _step = _ActivationStep.codeAndProfile;
    return null;
  }

  Future<String?> _validateCode() async {
    if (_code.text.trim().isEmpty) {
      return 'Escribí el código de activación que recibiste.';
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

  Future<String?> _redeemWithProfile() async {
    if (_code.text.trim().isEmpty) {
      return 'Escribí el código de activación que recibiste.';
    }
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      return 'Completá tu nombre y apellidos para entrar al área autorizada.';
    }
    final StaffActivationRedemption result = await _backend
        .redeemActivationWithProfile(
          code: _code.text.trim(),
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
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

  Future<void> _restart() async {
    if (_backend.currentUserId != null) {
      await widget.session.signOut();
    }
    if (!mounted) return;
    setState(() {
      _step = _ActivationStep.account;
      _preview = null;
      _code.clear();
      _error = null;
      _info = null;
    });
  }

  Widget _assigned(StaffActivationPreview preview) {
    final String? tierLabel = StaffTierKind.fromWire(preview.staffTier)?.label;
    return Semantics(
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
              StaffSchoolLogo(
                schoolName: preview.institutionName,
                size: 48,
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
                        tierLabel == null
                            ? preview.role!.label
                            : '${preview.role!.label} · $tierLabel',
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
  }

  List<Widget> _accountStep() => <Widget>[
    Semantics(
      header: true,
      child: const Text('Creá tu cuenta', style: _title),
    ),
    const SizedBox(height: 10),
    const Text(
      'Paso 1 de 3. Registrá el correo institucional vinculado a tu invitación '
      'y elegí una contraseña. Luego confirmás el correo y activás tu código.',
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

  List<Widget> _emailStep() {
    final String activeEmail = (_backend.currentUserEmail ?? _email.text)
        .trim();
    return <Widget>[
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
      Text(
        'Paso 2 de 3. Enviamos un enlace de confirmación a '
        '${activeEmail.isEmpty ? 'tu correo institucional' : activeEmail}. '
        'Abrilo y después volvé a SéTú.',
        style: _lead,
      ),
      const SizedBox(height: 10),
      const Text(
        'Mientras tu correo no esté confirmado ni hayas canjeado tu código '
        'individual, tu cuenta no tendrá acceso al área de personal.',
        style: _lead,
      ),
    ];
  }

  List<Widget> _codeAndProfileStep() {
    final StaffActivationPreview? preview = _preview;
    final String confirmedEmail = (_backend.currentUserEmail ?? _email.text)
        .trim();
    return <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7ED),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF008F30),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                confirmedEmail.isEmpty
                    ? 'Correo confirmado · Sin membresía activa aún'
                    : 'Correo confirmado: $confirmedEmail',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CureandoTheme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (preview != null) ...<Widget>[
        _assigned(preview),
        const SizedBox(height: 20),
      ],
      Semantics(
        header: true,
        child: const Text('Código y datos personales', style: _title),
      ),
      const SizedBox(height: 8),
      const Text(
        'Paso 3 de 3. Ingresá tu código individual de un solo uso y completá '
        'tu nombre y apellidos.',
        style: _lead,
      ),
      const SizedBox(height: 18),
      StaffField(
        label: 'Código de activación',
        controller: _code,
        hint: 'Ej. SETU-XXXX-XXXX',
        capitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_preview != null) setState(() => _preview = null);
        },
        onSubmitted: (_) => _run(_validateCode),
      ),
      if (preview != null) ...<Widget>[
        const SizedBox(height: 18),
        StaffField(
          label: 'Nombre',
          controller: _firstName,
          hint: 'Tu nombre',
          autofillHints: const <String>[AutofillHints.givenName],
        ),
        const SizedBox(height: 14),
        StaffField(
          label: 'Apellidos',
          controller: _lastName,
          hint: 'Tus apellidos',
          autofillHints: const <String>[AutofillHints.familyName],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _run(_redeemWithProfile),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final (String label, Future<String?> Function() action) = switch (_step) {
      _ActivationStep.account => ('Crear mi cuenta', _createAccount),
      _ActivationStep.email => ('Ya confirmé mi correo', _confirmEmail),
      _ActivationStep.codeAndProfile when _preview == null => (
        'Validar código',
        _validateCode,
      ),
      _ActivationStep.codeAndProfile => (
        'Activar cuenta',
        _redeemWithProfile,
      ),
    };
    return FlowScaffold(
      header: const FlowHeader(title: 'Registrar cuenta'),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaffPrimaryButton(
            label: label,
            busy: _busy,
            onPressed: () => _run(action),
          ),
          if (_step == _ActivationStep.account)
            TextButton(
              onPressed: () => context.push('/personal/ayuda'),
              child: const Text('Necesito ayuda con mi acceso', style: _link),
            )
          else if (_step == _ActivationStep.email) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton(
              style: flowSecondaryStyle(),
              onPressed: _busy ? null : () => _run(_resendLink),
              child: const Text('Reenviar enlace de confirmación'),
            ),
          ] else if (_backend.currentUserId != null)
            TextButton(
              onPressed: _busy ? null : _restart,
              child: const Text(
                'Cerrar sesión y usar otra cuenta',
                style: _link,
              ),
            )
          else
            TextButton(
              onPressed: () => context.push('/personal/ayuda'),
              child: const Text('Necesito ayuda con mi acceso', style: _link),
            ),
        ],
      ),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...switch (_step) {
              _ActivationStep.account => _accountStep(),
              _ActivationStep.email => _emailStep(),
              _ActivationStep.codeAndProfile => _codeAndProfileStep(),
            },
            if (_info != null) ...<Widget>[
              const SizedBox(height: 16),
              StaffNotice(_info!, error: false),
            ],
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

enum _AccessHelpMode { resendLink, replaceCode, resetPassword }

/// Flujo interactivo «Necesito ayuda con mi acceso» (`/personal/ayuda`):
/// reenvío de enlace de confirmación, solicitud de reposición de código o
/// restablecimiento de contraseña mediante Supabase Auth.
class StaffAccessHelpScreen extends StatefulWidget {
  const StaffAccessHelpScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffAccessHelpScreen> createState() => _StaffAccessHelpScreenState();
}

class _StaffAccessHelpScreenState extends State<StaffAccessHelpScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  _AccessHelpMode _mode = _AccessHelpMode.resendLink;
  String _reasonCode = 'expired';
  bool _busy = false;
  String? _message;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    final String? current = widget.session.currentUserEmail;
    if (current != null && current.isNotEmpty) {
      _email.text = current;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _ok = false;
        _message = 'Escribí tu correo institucional.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      switch (_mode) {
        case _AccessHelpMode.resendLink:
          await widget.session.backend.resendConfirmationEmail(email: email);
          if (!mounted) return;
          setState(() {
            _busy = false;
            _ok = true;
            _message =
                'Si la cuenta existe y sigue pendiente de verificación, '
                'reenviamos el enlace a $email.';
          });
        case _AccessHelpMode.replaceCode:
          await widget.session.backend.requestInviteReplacement(
            email: email,
            reasonCode: _reasonCode,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
          if (!mounted) return;
          setState(() {
            _busy = false;
            _ok = true;
            _message =
                'Si hay una invitación vinculada a $email, registramos tu '
                'solicitud de reposición para revisión de MINED. La persona '
                'autorizada revocará el código anterior y te enviará uno nuevo.';
          });
        case _AccessHelpMode.resetPassword:
          await widget.session.backend.sendPasswordReset(email: email);
          if (!mounted) return;
          setState(() {
            _busy = false;
            _ok = true;
            _message =
                'Si ya tenés una cuenta activa con $email, enviamos un correo '
                'de recuperación de contraseña.';
          });
      }
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _ok = false;
        _message = staffErrorMessage(failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) => FlowScaffold(
    header: const FlowHeader(title: 'Necesito ayuda con mi acceso'),
    bottom: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StaffPrimaryButton(
          label: switch (_mode) {
            _AccessHelpMode.resendLink => 'Reenviar enlace de confirmación',
            _AccessHelpMode.replaceCode => 'Solicitar reposición de código',
            _AccessHelpMode.resetPassword => 'Enviar correo de recuperación',
          },
          busy: _busy,
          onPressed: _submit,
        ),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Elegí qué pasó con tu acceso para resolverlo sin compartir códigos '
          'ni datos por canales grupales:',
          style: _lead,
        ),
        const SizedBox(height: 16),
        SegmentedButton<_AccessHelpMode>(
          segments: const <ButtonSegment<_AccessHelpMode>>[
            ButtonSegment<_AccessHelpMode>(
              value: _AccessHelpMode.resendLink,
              label: Text('Enlace'),
            ),
            ButtonSegment<_AccessHelpMode>(
              value: _AccessHelpMode.replaceCode,
              label: Text('Código'),
            ),
            ButtonSegment<_AccessHelpMode>(
              value: _AccessHelpMode.resetPassword,
              label: Text('Clave'),
            ),
          ],
          selected: <_AccessHelpMode>{_mode},
          onSelectionChanged: (Set<_AccessHelpMode> next) {
            setState(() {
              _mode = next.first;
              _message = null;
            });
          },
        ),
        const SizedBox(height: 18),
        StaffField(
          label: 'Correo institucional',
          controller: _email,
          hint: 'nombre@colegio.edu.ni',
          keyboardType: TextInputType.emailAddress,
        ),
        if (_mode == _AccessHelpMode.replaceCode) ...<Widget>[
          const SizedBox(height: 16),
          const Text(
            'Motivo de la reposición',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: CureandoTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _reasonCode,
            onChanged: (String? value) {
              if (value != null) setState(() => _reasonCode = value);
            },
            child: const Column(
              children: <Widget>[
                RadioListTile<String>(
                  value: 'expired',
                  contentPadding: EdgeInsets.zero,
                  title: Text('El código venció o no funciona'),
                ),
                RadioListTile<String>(
                  value: 'lost',
                  contentPadding: EdgeInsets.zero,
                  title: Text('Perdí el código individual'),
                ),
                RadioListTile<String>(
                  value: 'wrong_email',
                  contentPadding: EdgeInsets.zero,
                  title: Text('Se emitió a un correo incorrecto'),
                ),
              ],
            ),
          ),
          StaffField(
            label: 'Detalle breve (opcional)',
            controller: _notes,
            hint: 'Ej. correo institucional correcto o colegio',
          ),
        ],
        if (_message != null) ...<Widget>[
          const SizedBox(height: 16),
          StaffNotice(_message!, error: !_ok),
        ],
      ],
    ),
  );
}

/// Selector de ámbito (`/personal/ambito`) cuando la persona tiene membresías
/// activas en más de un centro.
class StaffScopeScreen extends StatelessWidget {
  const StaffScopeScreen({super.key, required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: Navigator.of(context).canPop(),
    child: FlowScaffold(
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
            'cambiarlo después desde «Mi perfil».',
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
                        StaffSchoolLogo(schoolName: scope.place, size: 42),
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
    ),
  );
}

enum _AccessRequestRoleOption {
  schoolDirector(
    label: 'Dirección de colegio',
    subtitle: 'Gestión de alertas y actuaciones escolares en un colegio.',
    role: SetuStaffRole.schoolDirector,
    staffTier: 'school_director',
    requiresSchool: true,
    allowsOptionalSchool: false,
  ),
  schoolPlant(
    label: 'Psicólogo/a de planta del colegio',
    subtitle: 'Atención de primera línea asignada a un centro escolar.',
    role: SetuStaffRole.counselingDesk,
    staffTier: 'school_plant',
    requiresSchool: true,
    allowsOptionalSchool: false,
  ),
  externalNetwork(
    label: 'Psicólogo/a de red externa',
    subtitle: 'Mesa de escucha MINED / MINSA de cobertura compartida.',
    role: SetuStaffRole.counselingDesk,
    staffTier: 'external_network',
    requiresSchool: false,
    allowsOptionalSchool: false,
  ),
  practicante5to(
    label: 'Practicante de 5.º año',
    subtitle: 'Apoyo en formación bajo tutoría asignada por el MINED.',
    role: SetuStaffRole.counselingDesk,
    staffTier: 'practicante_5to',
    requiresSchool: false,
    allowsOptionalSchool: true,
  );

  const _AccessRequestRoleOption({
    required this.label,
    required this.subtitle,
    required this.role,
    required this.staffTier,
    required this.requiresSchool,
    required this.allowsOptionalSchool,
  });

  final String label;
  final String subtitle;
  final SetuStaffRole role;
  final String staffTier;
  final bool requiresSchool;
  final bool allowsOptionalSchool;
}

/// Formulario público (`/personal/solicitar`) para pedir alta al MINED con
/// nombre completo, correo, rol y colegio antes de recibir código individual.
class StaffAccessRequestScreen extends StatefulWidget {
  const StaffAccessRequestScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffAccessRequestScreen> createState() =>
      _StaffAccessRequestScreenState();
}

class _StaffAccessRequestScreenState extends State<StaffAccessRequestScreen> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _program = TextEditingController();

  _AccessRequestRoleOption _option = _AccessRequestRoleOption.schoolDirector;
  Map<String, String> _schools = const <String, String>{};
  String? _institutionId;
  bool _loadingSchools = true;
  bool _busy = false;
  bool _submitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _loadingSchools = true;
      _error = null;
    });
    try {
      final Map<String, String> schools = await widget.session.backend
          .institutionNames();
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _institutionId = schools.isEmpty ? null : schools.keys.first;
        _loadingSchools = false;
      });
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadingSchools = false;
        _error = staffErrorMessage(failure);
      });
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _program.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String fullName = _fullName.text.trim();
    final String email = _email.text.trim();
    if (fullName.length < 3) {
      setState(() => _error = 'Escribí tu nombre completo.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Escribí un correo válido.');
      return;
    }
    if (_option.requiresSchool &&
        (_institutionId == null || _institutionId!.isEmpty)) {
      setState(() => _error = 'Elegí el colegio al que pertenecés.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String? selectedSchoolId =
          (_option.requiresSchool || _option.allowsOptionalSchool)
          ? _institutionId
          : null;
      await widget.session.backend.submitAccessRequest(
        fullName: fullName,
        email: email,
        role: _option.role,
        institutionId: selectedSchoolId,
        staffTier: _option.staffTier,
        requesterProgramLabel: _program.text.trim().isEmpty
            ? null
            : _program.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitted = true;
      });
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = staffErrorMessage(failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showSchoolPicker =
        _option.requiresSchool || _option.allowsOptionalSchool;
    return FlowScaffold(
      header: const FlowHeader(title: 'Solicitar acceso de personal'),
      bottom: _submitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StaffPrimaryButton(
                  label: 'Volver al ingreso',
                  onPressed: () => context.go('/personal'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: flowSecondaryStyle(),
                  onPressed: () => context.pushReplacement('/personal/activar'),
                  child: const Text('Registrar cuenta'),
                ),
              ],
            )
          : StaffPrimaryButton(
              label: 'Enviar solicitud al MINED',
              busy: _busy,
              onPressed: _loadingSchools ? null : _submit,
            ),
      body: _submitted
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 56,
                  color: CureandoTheme.blue,
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: const Text('Solicitud enviada', style: _title),
                ),
                const SizedBox(height: 12),
                Text(
                  'Registramos tu solicitud a nombre de ${_fullName.text.trim()} '
                  '(${_email.text.trim()}) como ${_option.label}.',
                  style: _lead,
                ),
                const SizedBox(height: 12),
                const StaffNotice(
                  'El equipo supervisor del MINED revisará tu solicitud y '
                  'emitirá tu código individual de activación vinculado a tu '
                  'colegio y rol.',
                  error: false,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Completá tus datos para que supervisión del MINED apruebe y '
                  'emita tu código individual de acceso. Las cuentas centrales '
                  'del MINED no se solicitan desde aquí.',
                  style: _lead,
                ),
                const SizedBox(height: 18),
                StaffField(
                  label: 'Nombre completo',
                  controller: _fullName,
                  hint: 'Ej. Ana María López',
                  capitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                StaffField(
                  label: 'Correo institucional o de contacto',
                  controller: _email,
                  hint: 'nombre@colegio.edu.ni',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rol solicitado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<_AccessRequestRoleOption>(
                  initialValue: _option,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFA5C1EF),
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: <DropdownMenuItem<_AccessRequestRoleOption>>[
                    for (final _AccessRequestRoleOption item
                        in _AccessRequestRoleOption.values)
                      DropdownMenuItem<_AccessRequestRoleOption>(
                        value: item,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (_AccessRequestRoleOption? next) {
                    if (next == null) return;
                    setState(() {
                      _option = next;
                      if (_option.requiresSchool &&
                          (_institutionId == null || _institutionId!.isEmpty) &&
                          _schools.isNotEmpty) {
                        _institutionId = _schools.keys.first;
                      }
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _option.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CureandoTheme.secondaryInk,
                  ),
                ),
                if (showSchoolPicker) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _option.requiresSchool
                        ? 'Colegio'
                        : 'Colegio referencial (opcional)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingSchools)
                    const Center(child: CircularProgressIndicator())
                  else if (_schools.isEmpty)
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text('No pudimos cargar la lista de colegios.'),
                        ),
                        TextButton(
                          onPressed: _loadSchools,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<String?>(
                      key: ValueKey<String>('school-${_option.requiresSchool}'),
                      initialValue: _option.requiresSchool
                          ? _institutionId
                          : _institutionId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFA5C1EF),
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: <DropdownMenuItem<String?>>[
                        if (!_option.requiresSchool)
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sin colegio específico (cobertura general)'),
                          ),
                        for (final MapEntry<String, String> entry
                            in _schools.entries)
                          DropdownMenuItem<String?>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (String? value) {
                        setState(() => _institutionId = value);
                      },
                    ),
                ],
                if (_option == _AccessRequestRoleOption.practicante5to ||
                    _option == _AccessRequestRoleOption.externalNetwork) ...<Widget>[
                  const SizedBox(height: 16),
                  StaffField(
                    label: _option == _AccessRequestRoleOption.practicante5to
                        ? 'Universidad o programa de práctica (opcional)'
                        : 'Institución o red (opcional)',
                    controller: _program,
                    hint: _option == _AccessRequestRoleOption.practicante5to
                        ? 'Ej. Psicología 5.º año · UAM / UNAN'
                        : 'Ej. MINSA / Red de apoyo',
                    capitalization: TextCapitalization.sentences,
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 16),
                  StaffNotice(_error!),
                ],
              ],
            ),
    );
  }
}
