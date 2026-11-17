import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../shared/remote/push_notification_service.dart';
import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_dialog.dart';
import '../school_access/school_location.dart';
import 'staff_backend.dart';
import 'staff_widgets.dart';

/// Encabezado con el logotipo de SéTú a la derecha para subpantallas de perfil.
Widget _profileHeader(BuildContext context, String title) => Padding(
  padding: const EdgeInsets.fromLTRB(6, 8, 16, 12),
  child: Row(
    children: <Widget>[
      IconButton(
        tooltip: 'Volver',
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      const CampaignSymbol(size: 26, showUnicef: false),
      const SizedBox(width: 6),
      const ExcludeSemantics(
        child: Text(
          'SéTú',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  ),
);

/// Perfil del personal autorizado (`/personal/perfil`), alineado con los datos
/// reales de `get_my_staff_profile` y la maqueta de referencia.
class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  StaffProfileView? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profile = widget.session.profile;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _profile == null;
      _error = null;
    });
    try {
      final StaffProfileView? loaded = await widget.session.backend.profile();
      await widget.session.reloadProfile();
      if (!mounted) return;
      setState(() {
        _profile = loaded;
        _loading = false;
      });
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = staffErrorMessage(failure);
      });
    }
  }

  Future<void> _openSecuritySheet(StaffProfileView profile) async {
    bool sending = false;
    String? notice;
    bool ok = false;
    await showSetuBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext sheet) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setSheet) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    'Seguridad de la cuenta',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu cuenta está vinculada al correo institucional '
                  '${profile.email}. El acceso al área de personal requiere '
                  'correo confirmado y membresía activa autorizada.',
                ),
                const SizedBox(height: 12),
                if (profile.supervisorName != null) ...<Widget>[
                  Text(
                    'Tutor asignado (practicante de 5.º año): '
                    '${profile.supervisorName}.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                ],
                if (notice != null) ...<Widget>[
                  StaffNotice(notice!, error: !ok),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          setSheet(() {
                            sending = true;
                            notice = null;
                          });
                          try {
                            await widget.session.backend.sendPasswordReset(
                              email: profile.email,
                            );
                            if (!ctx.mounted) return;
                            setSheet(() {
                              sending = false;
                              ok = true;
                              notice =
                                  'Te enviamos un enlace para restablecer tu '
                                  'contraseña a ${profile.email}.';
                            });
                          } on Object catch (failure) {
                            if (!ctx.mounted) return;
                            setSheet(() {
                              sending = false;
                              ok = false;
                              notice = staffErrorMessage(failure);
                            });
                          }
                        },
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: Text(
                    sending
                        ? 'Enviando enlace…'
                        : 'Cambiar o restablecer contraseña',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (BuildContext context, _) {
      final StaffProfileView? profile = widget.session.profile ?? _profile;
      final StaffMembershipScope? active = widget.session.active;
      return FlowScaffold(
        header: _profileHeader(context, 'Mi perfil'),
        body: _loading && profile == null
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            : profile == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  StaffNotice(
                    _error ?? 'No pudimos cargar tu perfil institucional.',
                  ),
                  const SizedBox(height: 12),
                  StaffPrimaryButton(label: 'Reintentar', onPressed: _load),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ProfileIdentityCard(profile: profile, active: active),
                  const SizedBox(height: 14),
                  _ScopeSchoolsCard(profile: profile, active: active),
                  const SizedBox(height: 14),
                  if (extractSchoolCode(active?.institutionPublicCode ?? '')
                      case final String code) ...<Widget>[
                    _StudentQrCard(code: code, schoolName: active!.place),
                    const SizedBox(height: 14),
                  ],
                  _ProfileActionTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: profile.isAvailable
                          ? const Color(0xFF00A83A)
                          : const Color(0xFF8B98AB),
                      child: Icon(
                        profile.isAvailable
                            ? Icons.check_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: profile.isAvailable
                        ? 'Disponible para nuevas alertas'
                        : 'Pausada para nuevas alertas',
                    subtitle: 'Disponibilidad y avisos',
                    onTap: () async {
                      await context.push('/personal/perfil/disponibilidad');
                      if (mounted) _load();
                    },
                  ),
                  const SizedBox(height: 10),
                  _ProfileActionTile(
                    leading: const Icon(
                      Icons.shield_outlined,
                      color: CureandoTheme.blue,
                      size: 26,
                    ),
                    title: 'Seguridad de la cuenta',
                    onTap: () => _openSecuritySheet(profile),
                  ),
                  const SizedBox(height: 10),
                  _ProfileActionTile(
                    leading: const Icon(
                      Icons.help_outline_rounded,
                      color: CureandoTheme.blue,
                      size: 26,
                    ),
                    title: 'Ayuda con mi acceso',
                    onTap: () => context.push('/personal/ayuda'),
                  ),
                  const SizedBox(height: 16),
                  if (widget.session.memberships.length > 1) ...<Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Para trabajar con otro centro, cerrá sesión e '
                        'ingresá de nuevo.',
                        style: TextStyle(
                          fontSize: 13,
                          color: CureandoTheme.secondaryInk,
                        ),
                      ),
                    ),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(
                        color: Color(0xFFC62828),
                        width: 1.5,
                      ),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: widget.session.signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.profile, required this.active});

  final StaffProfileView profile;
  final StaffMembershipScope? active;

  @override
  Widget build(BuildContext context) {
    final String subtitle =
        '${active?.role.label ?? 'Personal'} · ${profile.staffTierLabel}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E2F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFDDEAFB),
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: CureandoTheme.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CureandoTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CureandoTheme.secondaryInk,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(
                      profile.emailConfirmed
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 16,
                      color: profile.emailConfirmed
                          ? const Color(0xFF00A83A)
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        profile.emailConfirmed
                            ? 'Correo verificado'
                            : 'Verificación pendiente',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CureandoTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CureandoTheme.secondaryInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeSchoolsCard extends StatelessWidget {
  const _ScopeSchoolsCard({required this.profile, required this.active});

  final StaffProfileView profile;
  final StaffMembershipScope? active;

  @override
  Widget build(BuildContext context) {
    final List<String> places = <String>[
      if (profile.assignedSchools.isNotEmpty)
        for (final StaffSchoolScopeItem s in profile.assignedSchools) s.name
      else
        for (final StaffMembershipScope m in profile.memberships) m.place,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ámbito de atención',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CureandoTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.staffTierLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CureandoTheme.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (places.isEmpty && active != null)
            _SchoolLine(name: active!.place)
          else
            for (int i = 0; i < places.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 16),
              _SchoolLine(name: places[i]),
            ],
          if (profile.supervisorName != null) ...<Widget>[
            const Divider(height: 16),
            Text(
              'Tutor de práctica: ${profile.supervisorName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SchoolLine extends StatelessWidget {
  const _SchoolLine({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      StaffSchoolLogo(schoolName: name, size: 32, borderRadius: 8),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CureandoTheme.ink,
          ),
        ),
      ),
    ],
  );
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFD6E2F5)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CureandoTheme.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CureandoTheme.secondaryInk,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CureandoTheme.secondaryInk,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Pantalla de «Disponibilidad y avisos» (`/personal/perfil/disponibilidad`),
/// conectada con `update_my_staff_availability_and_notices`.
class StaffAvailabilityScreen extends StatefulWidget {
  const StaffAvailabilityScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<StaffAvailabilityScreen> createState() =>
      _StaffAvailabilityScreenState();
}

class _StaffAvailabilityScreenState extends State<StaffAvailabilityScreen> {
  late bool _available;
  late bool _notifyAlerts;
  late bool _notifyMessages;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final StaffProfileView? p = widget.session.profile;
    _available = p?.isAvailable ?? true;
    _notifyAlerts = p?.notifyNewAlerts ?? true;
    _notifyMessages = p?.notifyNewMessages ?? true;
    _syncFromServer();
  }

  Future<void> _syncFromServer() async {
    try {
      final StaffProfileView? fresh = await widget.session.backend.profile();
      if (!mounted || fresh == null) return;
      setState(() {
        _available = fresh.isAvailable;
        _notifyAlerts = fresh.notifyNewAlerts;
        _notifyMessages = fresh.notifyNewMessages;
      });
    } on Object {
      // Mantiene valores en caché si no hay red en este instante.
    }
  }

  Future<void> _update({
    required bool available,
    required bool notifyAlerts,
    required bool notifyMessages,
  }) async {
    final bool prevA = _available;
    final bool prevN = _notifyAlerts;
    final bool prevM = _notifyMessages;
    setState(() {
      _available = available;
      _notifyAlerts = notifyAlerts;
      _notifyMessages = notifyMessages;
      _saving = true;
      _error = null;
    });
    try {
      await widget.session.backend.updateAvailabilityAndNotices(
        isAvailable: available,
        notifyNewAlerts: notifyAlerts,
        notifyNewMessages: notifyMessages,
      );
      await widget.session.reloadProfile();
      if (!mounted) return;
      setState(() => _saving = false);
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _available = prevA;
        _notifyAlerts = prevN;
        _notifyMessages = prevM;
        _saving = false;
        _error = staffErrorMessage(failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      header: _profileHeader(context, 'Disponibilidad y avisos'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            const SizedBox(height: 12),
          ],
          const Text(
            'Disponibilidad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CureandoTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFD6E2F5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Recibir nuevas alertas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CureandoTheme.ink,
                  ),
                ),
                subtitle: const Text(
                  'Tus casos asignados siguen en Mis casos.',
                ),
                value: _available,
                onChanged: _saving
                    ? null
                    : (bool value) => _update(
                        available: value,
                        notifyAlerts: _notifyAlerts,
                        notifyMessages: _notifyMessages,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Avisos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CureandoTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFD6E2F5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.notifications_none_rounded,
                      color: CureandoTheme.blue,
                    ),
                    title: const Text(
                      'Nuevas alertas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CureandoTheme.ink,
                      ),
                    ),
                    value: _notifyAlerts,
                    onChanged: _saving
                        ? null
                        : (bool value) => _update(
                            available: _available,
                            notifyAlerts: value,
                            notifyMessages: _notifyMessages,
                          ),
                  ),
                  const Divider(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: CureandoTheme.blue,
                    ),
                    title: const Text(
                      'Mensajes nuevos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CureandoTheme.ink,
                      ),
                    ),
                    value: _notifyMessages,
                    onChanged: _saving
                        ? null
                        : (bool value) => _update(
                            available: _available,
                            notifyAlerts: _notifyAlerts,
                            notifyMessages: value,
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const StaffPushDeviceCard(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4E4FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: CureandoTheme.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Pantalla bloqueada',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CureandoTheme.ink,
                            ),
                          ),
                          Text(
                            'Los avisos ocultan los datos del caso.',
                            style: TextStyle(
                              fontSize: 13,
                              color: CureandoTheme.secondaryInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD6E2F5)),
                  ),
                  child: const Row(
                    children: <Widget>[
                      CampaignSymbol(size: 26, showUnicef: false),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'SéTú',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CureandoTheme.ink,
                              ),
                            ),
                            Text(
                              'Tenés una alerta asignada',
                              style: TextStyle(
                                fontSize: 13,
                                color: CureandoTheme.secondaryInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado del registro push de este teléfono para el personal, con un botón
/// para volver a registrarlo. No muestra el token ni datos de casos.
class StaffPushDeviceCard extends StatefulWidget {
  const StaffPushDeviceCard({super.key, this.service});

  final PushNotificationService? service;

  @override
  State<StaffPushDeviceCard> createState() => _StaffPushDeviceCardState();
}

class _StaffPushDeviceCardState extends State<StaffPushDeviceCard> {
  PushNotificationService get _service =>
      widget.service ?? PushNotificationService.instance;

  @override
  void initState() {
    super.initState();
    if (_service.staffStatus.value != StaffPushStatus.registered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _service.registerStaffNow();
      });
    }
  }

  String _label(StaffPushStatus status) => switch (status) {
    StaffPushStatus.registered =>
      'Este teléfono recibe avisos de nuevas alertas y mensajes.',
    StaffPushStatus.registering => 'Registrando este teléfono…',
    StaffPushStatus.noSession =>
      'Iniciá sesión de personal para recibir avisos en este teléfono.',
    StaffPushStatus.noToken =>
      'No se pudo obtener el permiso de avisos del teléfono. Revisá que las '
          'notificaciones de SéTú estén activadas y volvé a intentar.',
    StaffPushStatus.failed =>
      'No se pudo registrar este teléfono. Revisá tu conexión y volvé a '
          'intentar.',
    StaffPushStatus.unknown => 'Comprobando avisos de este teléfono…',
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StaffPushStatus>(
      valueListenable: _service.staffStatus,
      builder: (BuildContext context, StaffPushStatus status, _) {
        final bool ok = status == StaffPushStatus.registered;
        final bool busy =
            status == StaffPushStatus.registering ||
            status == StaffPushStatus.unknown;
        return Material(
          key: const Key('staff-push-device-card'),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFD6E2F5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      ok
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      color: ok ? CureandoTheme.green : CureandoTheme.blue,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Avisos en este teléfono',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CureandoTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_label(status)),
                if (!ok) ...<Widget>[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: busy ? null : _service.registerStaffNow,
                    child: const Text('Registrar este teléfono'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Activación del QR estudiantil en el perfil del personal del colegio.
/// Se recuerda mientras la app está abierta; el QR solo lleva el código
/// público del centro (`setu://colegio/CODIGO`) y no identifica a nadie.
final ValueNotifier<bool> staffStudentQrEnabled = ValueNotifier<bool>(false);

class _StudentQrCard extends StatelessWidget {
  const _StudentQrCard({required this.code, required this.schoolName});

  final String code;
  final String schoolName;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: staffStudentQrEnabled,
    // Material propio para que el interruptor pinte su efecto de toque.
    builder: (BuildContext context, bool enabled, _) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD6E2F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SwitchListTile(
              key: const ValueKey<String>('staff-student-qr-switch'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.qr_code_2_rounded,
                color: CureandoTheme.blue,
                size: 28,
              ),
              title: const Text(
                'QR estudiantil',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Mostralo para que el estudiante entre a tu colegio escaneándolo.',
              ),
              value: enabled,
              onChanged: (bool value) => staffStudentQrEnabled.value = value,
            ),
            if (enabled) ...<Widget>[
              const SizedBox(height: 8),
              Center(
                child: QrImageView(
                  data: schoolQrLink(code),
                  size: 220,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  semanticsLabel: 'Código QR de $schoolName, código $code',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                schoolName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              SelectableText(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.blue,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'En SéTú, el estudiante toca «Escanear QR» y queda dentro del '
                'espacio de este colegio. No se le pide nombre ni carné.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: CureandoTheme.secondaryInk,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
