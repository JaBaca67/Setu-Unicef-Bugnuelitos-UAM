import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/cureando_models.dart';
import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_alert.dart';
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
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Volver',
              color: Colors.white,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
              icon: Icons.login_rounded,
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: flowSecondaryStyle(),
              onPressed: _openRegistration,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 22),
              label: const Text('Registrar cuenta'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/personal/ayuda'),
              icon: const Icon(Icons.help_outline_rounded, size: 20),
              label: const Text('Ayuda', style: _link),
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

enum _ActivationStep { profileAndRole, account, email, code }

/// Primer ingreso (`/personal/activar`):
/// 1) Nombre, apellidos y rol/colegio al que aplica;
/// 2) Correo y contraseña;
/// 3) Confirmación de correo;
/// 4) Código individual en casillas (o envío de solicitud al MINED).
class StaffActivationScreen extends StatefulWidget {
  const StaffActivationScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffActivationScreen> createState() => _StaffActivationScreenState();
}

class _StaffActivationScreenState extends State<StaffActivationScreen> {
  static const int _minPassword = 8;

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  late _ActivationStep _step;
  _AccessRequestRoleOption _roleOption = _AccessRequestRoleOption.schoolDirector;
  Map<String, String> _schools = const <String, String>{};
  String? _institutionId;
  bool _loadingSchools = true;
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
    final StaffSession session = widget.session;
    if (session.pendingFirstName.isNotEmpty) {
      _firstName.text = session.pendingFirstName;
    }
    if (session.pendingLastName.isNotEmpty) {
      _lastName.text = session.pendingLastName;
    }
    if (session.pendingEmail.isNotEmpty) {
      _email.text = session.pendingEmail;
    }
    if (session.pendingPassword.isNotEmpty) {
      _password.text = session.pendingPassword;
      _repeat.text = session.pendingPassword;
    }
    for (final _AccessRequestRoleOption opt
        in _AccessRequestRoleOption.values) {
      if (opt.staffTier == session.pendingStaffTier) {
        _roleOption = opt;
        break;
      }
    }
    _institutionId = session.pendingInstitutionId;

    if (_backend.currentUserId != null) {
      final String activeEmail = (_backend.currentUserEmail ?? '').trim();
      if (activeEmail.isNotEmpty) _email.text = activeEmail;
      _step = _backend.isEmailConfirmed
          ? _ActivationStep.code
          : _ActivationStep.email;
    } else {
      _step = _ActivationStep.profileAndRole;
    }
    _loadSchools();
    _authSubscription = _backend.authStateChanges().listen((_) {
      _syncConfirmedFromAuth();
    });
    _lifecycle = AppLifecycleListener(onResume: _checkConfirmedOnResume);
  }

  Future<void> _loadSchools() async {
    try {
      final Map<String, String> schools = await _backend.institutionNames();
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _institutionId ??= schools.isEmpty ? null : schools.keys.first;
        _loadingSchools = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loadingSchools = false);
    }
  }

  void _syncConfirmedFromAuth() {
    if (!mounted) return;
    if (_backend.currentUserId == null) return;
    final String activeEmail = (_backend.currentUserEmail ?? '').trim();
    if (activeEmail.isNotEmpty && _email.text.trim().isEmpty) {
      _email.text = activeEmail;
    }
    if (_backend.isEmailConfirmed && _step != _ActivationStep.code) {
      setState(() {
        _step = _ActivationStep.code;
        _error = null;
        _info = null;
      });
    } else if (!_backend.isEmailConfirmed &&
        (_step == _ActivationStep.account ||
            _step == _ActivationStep.profileAndRole)) {
      setState(() {
        _step = _ActivationStep.email;
        _error = null;
      });
    }
  }

  Future<void> _checkConfirmedOnResume() async {
    if (!mounted || _busy || _step == _ActivationStep.code) return;
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
    _codeFocus.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    _code.dispose();
    super.dispose();
  }

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

  Future<String?> _completeProfileStep() async {
    if (_firstName.text.trim().length < 2 || _lastName.text.trim().length < 2) {
      return 'Escribí tu nombre y apellidos.';
    }
    if (_roleOption.requiresSchool &&
        (_institutionId == null || _institutionId!.isEmpty)) {
      return 'Elegí el colegio al que aplicás.';
    }
    widget.session
      ..pendingFirstName = _firstName.text.trim()
      ..pendingLastName = _lastName.text.trim()
      ..pendingStaffTier = _roleOption.staffTier
      ..pendingInstitutionId = _institutionId;
    _step = _backend.currentUserId != null && _backend.isEmailConfirmed
        ? _ActivationStep.code
        : _ActivationStep.account;
    return null;
  }

  Future<String?> _createAccount() async {
    final String email = _email.text.trim();
    if (!email.contains('@')) return 'Escribí un correo válido.';
    if (_password.text.length < _minPassword) {
      return 'La contraseña necesita al menos $_minPassword caracteres.';
    }
    if (_password.text != _repeat.text) {
      return 'Las dos contraseñas no coinciden.';
    }
    widget.session
      ..pendingEmail = email
      ..pendingPassword = _password.text;
    try {
      await _backend.signUp(email: email, password: _password.text);
    } on GatewayException catch (failure) {
      final String text = '${failure.code} ${failure.message}'.toLowerCase();
      if (!text.contains('already')) rethrow;
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
        return 'Esta cuenta ya completó su registro. Volvé atrás e iniciá sesión.';
      }
      _step = _ActivationStep.code;
      return null;
    }
    _step = _ActivationStep.email;
    return null;
  }

  Future<String?> _resendLink() async {
    final String email = (_backend.currentUserEmail ?? _email.text).trim();
    if (!email.contains('@')) {
      return 'Escribí tu correo para reenviar el enlace.';
    }
    await _backend.resendConfirmationEmail(email: email);
    _info = 'Reenviamos el enlace de confirmación a $email.';
    return null;
  }

  Future<String?> _confirmEmail() async {
    final String email = (_backend.currentUserEmail ?? _email.text).trim();
    if (_backend.currentUserId != null) {
      await _backend.refreshAuthSession();
    } else {
      if (!email.contains('@') || _password.text.isEmpty) {
        return 'Iniciá sesión luego de confirmar tu correo.';
      }
      await _backend.signIn(email: email, password: _password.text);
    }
    if (_backend.currentUserId == null || !_backend.isEmailConfirmed) {
      return 'Todavía no vemos tu correo confirmado. Abrí el enlace e intentá de nuevo.';
    }
    final String? membershipError = await widget.session.refresh();
    if (membershipError == null && widget.session.memberships.isNotEmpty) {
      if (mounted) enterStaffArea(context, widget.session);
      return null;
    }
    _step = _ActivationStep.code;
    return null;
  }

  Future<String?> _activateWithCode() async {
    final String cleanCode = _code.text.trim();
    if (cleanCode.isEmpty) {
      return 'Ingresá el código individual que recibiste.';
    }
    if (_firstName.text.trim().length < 2 || _lastName.text.trim().length < 2) {
      return 'Completá tu nombre y apellidos para continuar.';
    }
    if (_preview == null) {
      final StaffActivationPreview preview = await _backend.previewActivation(
        cleanCode,
      );
      if (!preview.ok) {
        return activationErrorMessage(
          preview.error,
          remainingAttempts: preview.remainingAttempts,
        );
      }
      _preview = preview;
      if (mounted) setState(() {});
    }
    final StaffActivationRedemption result = await _backend
        .redeemActivationWithProfile(
          code: cleanCode,
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
    if (error == null) {
      widget.session.clearPendingRegistration();
      if (mounted) enterStaffArea(context, widget.session);
    }
    return error;
  }

  Future<String?> _requestAccessFromCodeStep() async {
    final String email = (_backend.currentUserEmail ?? _email.text).trim();
    final String fullName =
        '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
    if (fullName.length < 3 || !email.contains('@')) {
      if (mounted) context.push('/personal/solicitar');
      return null;
    }
    if (_roleOption.requiresSchool &&
        (_institutionId == null || _institutionId!.isEmpty)) {
      if (mounted) context.push('/personal/solicitar');
      return null;
    }
    await _backend.submitAccessRequest(
      fullName: fullName,
      email: email,
      role: _roleOption.role,
      institutionId:
          (_roleOption.requiresSchool || _roleOption.allowsOptionalSchool)
          ? _institutionId
          : null,
      staffTier: _roleOption.staffTier,
    );
    _info = 'Solicitud enviada al MINED para $email. Al aprobarse recibirás tu código.';
    if (mounted) {
      showSetuBottomAlert(
        context,
        'Solicitud enviada al MINED.',
        kind: SetuAlertKind.success,
      );
    }
    return null;
  }

  Future<void> _restart() async {
    if (_backend.currentUserId != null) {
      await widget.session.signOut();
    }
    widget.session.clearPendingRegistration();
    if (!mounted) return;
    setState(() {
      _firstName.clear();
      _lastName.clear();
      _email.clear();
      _password.clear();
      _repeat.clear();
      _step = _ActivationStep.profileAndRole;
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CureandoTheme.blueSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFA5C1EF)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: <Widget>[
              StaffSchoolLogo(
                schoolName: preview.institutionName,
                size: 44,
              ),
              const VerticalDivider(
                width: 24,
                thickness: 1.5,
                color: CureandoTheme.blue,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      preview.institutionName ??
                          preview.scopeLabel ??
                          'Centro asignado',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (preview.role != null)
                      Text(
                        tierLabel == null
                            ? preview.role!.label
                            : '${preview.role!.label} · $tierLabel',
                        style: const TextStyle(
                          fontSize: 14,
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

  List<Widget> _profileAndRoleStep() {
    final bool showSchool =
        _roleOption.requiresSchool || _roleOption.allowsOptionalSchool;
    return <Widget>[
      const StaffStepProgress(
        current: 1,
        total: 4,
        caption: 'Paso 1 de 4 · Tus datos y rol',
      ),
      const SizedBox(height: 14),
      Semantics(
        header: true,
        child: const Text('¿Quién sos?', style: _title),
      ),
      const SizedBox(height: 16),
      StaffField(
        label: 'Nombre',
        controller: _firstName,
        hint: 'Tu nombre',
        capitalization: TextCapitalization.words,
        autofillHints: const <String>[AutofillHints.givenName],
      ),
      const SizedBox(height: 14),
      StaffField(
        label: 'Apellidos',
        controller: _lastName,
        hint: 'Tus apellidos',
        capitalization: TextCapitalization.words,
        autofillHints: const <String>[AutofillHints.familyName],
      ),
      const SizedBox(height: 14),
      StaffDropdown<_AccessRequestRoleOption>(
        label: 'Rol al que aplicás',
        value: _roleOption,
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
            _roleOption = next;
            if (_roleOption.requiresSchool &&
                (_institutionId == null || _institutionId!.isEmpty) &&
                _schools.isNotEmpty) {
              _institutionId = _schools.keys.first;
            }
            _error = null;
          });
        },
      ),
      if (showSchool) ...<Widget>[
        const SizedBox(height: 14),
        if (_loadingSchools)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_schools.isNotEmpty)
          StaffDropdown<String?>(
            label: _roleOption.requiresSchool
                ? 'Colegio'
                : 'Colegio (opcional)',
            value: _institutionId,
            items: <DropdownMenuItem<String?>>[
              if (!_roleOption.requiresSchool)
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin colegio específico'),
                ),
              for (final MapEntry<String, String> entry in _schools.entries)
                DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
            ],
            onChanged: (String? value) =>
                setState(() => _institutionId = value),
          ),
      ],
    ];
  }

  List<Widget> _accountStep() => <Widget>[
    const StaffStepProgress(
      current: 2,
      total: 4,
      caption: 'Paso 2 de 4 · Correo y contraseña',
    ),
    const SizedBox(height: 14),
    Semantics(
      header: true,
      child: const Text('Tu correo de acceso', style: _title),
    ),
    const SizedBox(height: 6),
    const Text('Usá tu Gmail o correo institucional.', style: _lead),
    const SizedBox(height: 18),
    StaffField(
      label: 'Correo institucional',
      controller: _email,
      hint: 'nombre@gmail.com',
      keyboardType: TextInputType.emailAddress,
      autofillHints: const <String>[AutofillHints.email],
    ),
    const SizedBox(height: 16),
    StaffField(
      label: 'Contraseña nueva',
      controller: _password,
      hint: 'Mínimo $_minPassword caracteres',
      obscure: _hidden,
      onToggleObscure: () => setState(() => _hidden = !_hidden),
      autofillHints: const <String>[AutofillHints.newPassword],
    ),
    const SizedBox(height: 16),
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
      const StaffStepProgress(
        current: 3,
        total: 4,
        caption: 'Paso 3 de 4 · Confirmación',
      ),
      const SizedBox(height: 20),
      const Icon(
        Icons.mark_email_unread_outlined,
        size: 54,
        color: CureandoTheme.blue,
      ),
      const SizedBox(height: 14),
      Semantics(
        header: true,
        child: const Text('Confirmá tu correo', style: _title),
      ),
      const SizedBox(height: 10),
      Text(
        'Abrí el enlace enviado a '
        '${activeEmail.isEmpty ? 'tu correo' : activeEmail} '
        'y volvé a SéTú.',
        style: _lead,
      ),
    ];
  }

  List<Widget> _codeStep() {
    final StaffActivationPreview? preview = _preview;
    final String confirmedEmail = (_backend.currentUserEmail ?? _email.text)
        .trim();
    final bool needsNameInputs =
        _firstName.text.trim().length < 2 || _lastName.text.trim().length < 2;
    return <Widget>[
      const StaffStepProgress(
        current: 4,
        total: 4,
        caption: 'Paso 4 de 4 · Código individual',
      ),
      const SizedBox(height: 14),
      if (confirmedEmail.isNotEmpty) ...<Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: CureandoTheme.greenSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4ADE80)),
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
                  confirmedEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CureandoTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (preview != null) ...<Widget>[
        _assigned(preview),
        const SizedBox(height: 14),
      ],
      Semantics(
        header: true,
        child: const Text('Ingresá tu código', style: _title),
      ),
      const SizedBox(height: 6),
      const Text(
        'Escribí o pegá el código de 12 caracteres.',
        style: _lead,
      ),
      const SizedBox(height: 16),
      _ActivationCodeSlots(
        controller: _code,
        focusNode: _codeFocus,
        onChanged: () {
          if (_preview != null || _error != null) {
            setState(() {
              _preview = null;
              _error = null;
            });
          }
        },
        onSubmitted: () => _run(_activateWithCode),
      ),
      if (needsNameInputs) ...<Widget>[
        const SizedBox(height: 16),
        StaffField(
          label: 'Nombre',
          controller: _firstName,
          hint: 'Tu nombre',
          capitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.givenName],
        ),
        const SizedBox(height: 12),
        StaffField(
          label: 'Apellidos',
          controller: _lastName,
          hint: 'Tus apellidos',
          capitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.familyName],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _run(_activateWithCode),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final (String label, IconData stepIcon, Future<String?> Function() action) =
        switch (_step) {
          _ActivationStep.profileAndRole => (
            'Continuar',
            Icons.arrow_forward_rounded,
            _completeProfileStep,
          ),
          _ActivationStep.account => (
            'Crear mi cuenta',
            Icons.person_add_alt_1_rounded,
            _createAccount,
          ),
          _ActivationStep.email => (
            'Ya confirmé mi correo',
            Icons.mark_email_read_outlined,
            _confirmEmail,
          ),
          _ActivationStep.code => (
            'Activar cuenta',
            Icons.verified_user_outlined,
            _activateWithCode,
          ),
        };
    final bool canSelfRequestFromStep4 =
        _firstName.text.trim().length >= 2 &&
        _lastName.text.trim().length >= 2 &&
        (_backend.currentUserEmail ?? _email.text).trim().contains('@');
    return FlowScaffold(
      header: const FlowHeader(title: 'Registrar cuenta'),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaffPrimaryButton(
            label: label,
            icon: stepIcon,
            busy: _busy,
            onPressed: () => _run(action),
          ),
          if (_step == _ActivationStep.profileAndRole)
            TextButton.icon(
              onPressed: () => context.push('/personal/ayuda'),
              icon: const Icon(Icons.help_outline_rounded, size: 20),
              label: const Text('Ayuda', style: _link),
            )
          else if (_step == _ActivationStep.account) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: flowSecondaryStyle(),
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _step = _ActivationStep.profileAndRole;
                      _error = null;
                    }),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Volver al paso anterior'),
            ),
          ] else if (_step == _ActivationStep.email) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: flowSecondaryStyle(),
              onPressed: _busy ? null : () => _run(_resendLink),
              icon: const Icon(Icons.forward_to_inbox_rounded, size: 20),
              label: const Text('Reenviar enlace de confirmación'),
            ),
          ] else if (canSelfRequestFromStep4) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: flowSecondaryStyle(),
              onPressed: _busy ? null : () => _run(_requestAccessFromCodeStep),
              icon: const Icon(Icons.send_rounded, size: 20),
              label: const Text('No tengo código · Solicitar'),
            ),
          ] else
            TextButton.icon(
              onPressed: _busy ? null : _restart,
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              label: const Text(
                'Cerrar sesión y usar otra cuenta',
                style: _link,
              ),
            ),
        ],
      ),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...switch (_step) {
              _ActivationStep.profileAndRole => _profileAndRoleStep(),
              _ActivationStep.account => _accountStep(),
              _ActivationStep.email => _emailStep(),
              _ActivationStep.code => _codeStep(),
            },
            if (_info != null) ...<Widget>[
              const SizedBox(height: 14),
              StaffNotice(_info!, error: false),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 14),
              StaffNotice(_error!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Casillas estilizadas al estilo SéTú (3 grupos de 4 caracteres) para
/// códigos individuales (`SETU-XXXX-XXXX` o códigos cortos de prueba).
class _ActivationCodeSlots extends StatelessWidget {
  const _ActivationCodeSlots({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  static const int _maxRawLength = 14;
  static const int _slotCount = 12;

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  String _normalized(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: <Widget>[
      Positioned.fill(
        child: Semantics(
          label: 'Código de activación',
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            showCursor: false,
            style: const TextStyle(color: Colors.transparent),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              LengthLimitingTextInputFormatter(_maxRawLength),
            ],
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmitted(),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ),
      IgnorePointer(
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[controller, focusNode]),
              builder: (BuildContext context, _) {
                final String chars = _normalized(controller.text);
                final int activeIndex = math.min(chars.length, _slotCount - 1);
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (int group = 0; group < 3; group++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (int offset = 0; offset < 4; offset++) ...<Widget>[
                            Builder(
                              builder: (BuildContext context) {
                                final int index = group * 4 + offset;
                                final String char =
                                    index < chars.length ? chars[index] : '';
                                final bool isCurrent =
                                    focusNode.hasFocus && index == activeIndex;
                                final bool filled = char.isNotEmpty;
                                return Container(
                                  width: 24,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: filled || isCurrent
                                        ? CureandoTheme.blueSoft
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isCurrent
                                          ? CureandoTheme.blue
                                          : filled
                                          ? const Color(0xFF7CA9F5)
                                          : const Color(0xFFC7D7F2),
                                      width: isCurrent ? 2 : 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    char,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: CureandoTheme.ink,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (offset < 3) const SizedBox(width: 4),
                          ],
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ],
  );
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
                StaffDropdown<_AccessRequestRoleOption>(
                  label: 'Rol solicitado',
                  value: _option,
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
                    StaffDropdown<String?>(
                      label: _option.requiresSchool
                          ? 'Colegio'
                          : 'Colegio referencial (opcional)',
                      value: _institutionId,
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
