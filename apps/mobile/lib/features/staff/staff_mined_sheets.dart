import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import 'staff_backend.dart';
import 'staff_inbox_screens.dart';
import 'staff_widgets.dart';

/// Abre el panel de MINED para «Invitaciones de personal»:
/// revisar solicitudes, aprobar/emitir, reponer y revocar códigos individuales.
Future<void> showMinedInvitesSheet(
  BuildContext context,
  StaffSession session,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext sheet) => _MinedInvitesSheet(session: session),
);

/// Abre el panel de MINED para administrar la cobertura externa por colegio y
/// los colegios disponibles / asignados a cada profesional externo.
Future<void> showMinedCoverageSheet(
  BuildContext context,
  StaffSession session,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext sheet) => _MinedCoverageSheet(session: session),
);

String _tierLabel(String tier) => switch (tier) {
  'school_plant' => StaffTierKind.schoolPlant.label,
  'external_network' => StaffTierKind.externalNetwork.label,
  'practicante_5to' => StaffTierKind.practicante5to.label,
  'mined_central' => StaffTierKind.minedCentral.label,
  'school_director' => StaffTierKind.schoolDirector.label,
  _ => tier,
};

class _MinedInvitesSheet extends StatefulWidget {
  const _MinedInvitesSheet({required this.session});

  final StaffSession session;

  @override
  State<_MinedInvitesSheet> createState() => _MinedInvitesSheetState();
}

class _MinedInvitesSheetState extends State<_MinedInvitesSheet> {
  List<StaffActivationInviteView>? _invites;
  Map<String, String> _schools = const <String, String>{};
  List<AssignableCounselor> _counselors = const <AssignableCounselor>[];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final StaffBackend backend = widget.session.backend;
      final List<StaffActivationInviteView> invites = await backend.invites();
      final Map<String, String> schools = await backend.institutionNames();
      final List<AssignableCounselor> counselors = await backend.counselors();
      if (!mounted) return;
      setState(() {
        _invites = invites;
        _schools = schools;
        _counselors = counselors;
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

  Future<void> _showIssuedCodeDialog(StaffInviteIssueResult issued) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: const Text('Código de activación emitido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Correo vinculado: ${issued.institutionalEmail}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CureandoTheme.blueSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CureandoTheme.blue),
              ),
              child: SelectableText(
                issued.activationCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (issued.expiresAt != null)
              Text(
                'Vence: ${staffShortDate(issued.expiresAt!)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: CureandoTheme.secondaryInk,
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Entregalo en privado al correo institucional vinculado. El código '
              'no queda guardado en el historial.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: issued.activationCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado al portapapeles.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copiar código'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvite() async {
    final _InviteDraftResult? draft = await showDialog<_InviteDraftResult>(
      context: context,
      builder: (BuildContext dialog) => _IssueInviteDialog(
        schools: _schools,
        counselors: _counselors,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final StaffInviteIssueResult issued = await widget.session.backend
          .issueInvite(
            email: draft.email,
            role: draft.role,
            institutionId: draft.institutionId,
            staffTier: draft.staffTier,
            fullName: draft.fullName,
            supervisorUserId: draft.supervisorUserId,
          );
      if (!mounted) return;
      setState(() => _busy = false);
      await _showIssuedCodeDialog(issued);
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(staffErrorMessage(failure))));
    }
  }

  Future<void> _approveRequest(StaffActivationInviteView invite) async {
    String? supervisorId = invite.supervisorUserId;
    if (invite.staffTier == 'practicante_5to' &&
        (supervisorId == null || supervisorId.isEmpty)) {
      supervisorId = await _pickSupervisor();
      if (supervisorId == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final StaffInviteIssueResult issued = await widget.session.backend
          .issueInvite(
            pendingInviteId: invite.inviteId,
            supervisorUserId: supervisorId,
          );
      if (!mounted) return;
      setState(() => _busy = false);
      await _showIssuedCodeDialog(issued);
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(staffErrorMessage(failure))));
    }
  }

  Future<String?> _pickSupervisor() async {
    if (_counselors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay psicólogos tutores activos para asignar.'),
        ),
      );
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialog) => SimpleDialog(
        title: const Text('Elegí psicólogo tutor'),
        children: <Widget>[
          for (final AssignableCounselor counselor in _counselors)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialog).pop(counselor.userId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(counselor.email),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _replace(StaffActivationInviteView invite) async {
    final TextEditingController emailController = TextEditingController(
      text: invite.institutionalEmail,
    );
    final String? targetEmail = await showDialog<String>(
      context: context,
      builder: (BuildContext dialog) => AlertDialog(
        title: const Text('Reponer invitación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Revoca la invitación anterior y emite un código nuevo de un '
              'solo uso.',
            ),
            const SizedBox(height: 12),
            StaffField(
              label: 'Correo institucional',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialog).pop(emailController.text.trim()),
            child: const Text('Emitir reposición'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (targetEmail == null || targetEmail.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final StaffInviteIssueResult issued = await widget.session.backend
          .replaceInvite(
            inviteId: invite.inviteId,
            newEmail: targetEmail,
            reason: 'Reposición solicitada desde panel MINED',
          );
      if (!mounted) return;
      setState(() => _busy = false);
      await _showIssuedCodeDialog(issued);
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(staffErrorMessage(failure))));
    }
  }

  Future<void> _revoke(StaffActivationInviteView invite) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialog) => AlertDialog(
            title: const Text('Revocar invitación'),
            content: Text(
              'El código pendiente para ${invite.institutionalEmail} dejará de '
              'funcionar de inmediato.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialog).pop(true),
                child: const Text('Revocar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.session.backend.revokeInvite(
        inviteId: invite.inviteId,
        reason: 'Revocada por MINED central',
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(staffErrorMessage(failure))));
    }
  }

  Widget _inviteCard(StaffActivationInviteView invite) {
    final bool pendingRequest =
        invite.requestStatus == StaffInviteRequestStatus.pendingApproval;
    final bool canReplaceOrRevoke =
        invite.redeemedAt == null &&
        invite.revokedAt == null &&
        invite.replacedByInviteId == null;
    final String schoolLabel =
        invite.institutionName ??
        (invite.institutionId == null
            ? invite.scopeLabel
            : (_schools[invite.institutionId!] ?? invite.scopeLabel));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CureandoTheme.blueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5C1EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              Text(
                invite.institutionalEmail,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              StaffTag(
                invite.displayStatus,
                highlight: pendingRequest || invite.isActiveForRedemption,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${invite.role.label} · ${_tierLabel(invite.staffTier)}',
            style: const TextStyle(fontSize: 15),
          ),
          if (schoolLabel.isNotEmpty)
            Text(
              'Ámbito: $schoolLabel',
              style: const TextStyle(
                fontSize: 14,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          if (invite.supervisorName != null &&
              invite.supervisorName!.isNotEmpty)
            Text(
              'Tutor asignado: ${invite.supervisorName}',
              style: const TextStyle(
                fontSize: 14,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          if (invite.events.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            for (final StaffInviteEventView ev in invite.events.take(3))
              Text(
                '• ${ev.eventLabel} (${staffShortDate(ev.createdAt)})',
                style: const TextStyle(
                  fontSize: 13,
                  color: CureandoTheme.secondaryInk,
                ),
              ),
          ],
          if (pendingRequest || canReplaceOrRevoke) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (pendingRequest)
                  FilledButton(
                    onPressed: _busy ? null : () => _approveRequest(invite),
                    child: const Text('Aprobar y emitir'),
                  ),
                if (canReplaceOrRevoke && !pendingRequest)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _replace(invite),
                    child: const Text('Reponer código'),
                  ),
                if (canReplaceOrRevoke)
                  TextButton(
                    onPressed: _busy ? null : () => _revoke(invite),
                    child: const Text('Revocar'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<StaffActivationInviteView> list =
        _invites ?? const <StaffActivationInviteView>[];
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Invitaciones de personal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton.icon(
                style: flowPrimaryStyle(),
                onPressed: _loading || _busy ? null : _createInvite,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Emitir invitación'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_error != null) ...<Widget>[
                      StaffNotice(_error!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ] else if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Cargando invitaciones',
                          ),
                        ),
                      )
                    else if (list.isEmpty)
                      const StaffNotice(
                        'No hay solicitudes ni invitaciones registradas.',
                        error: false,
                      )
                    else
                      for (final StaffActivationInviteView invite in list)
                        _inviteCard(invite),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteDraftResult {
  const _InviteDraftResult({
    required this.email,
    required this.role,
    required this.staffTier,
    this.institutionId,
    this.fullName,
    this.supervisorUserId,
  });

  final String email;
  final SetuStaffRole role;
  final String staffTier;
  final String? institutionId;
  final String? fullName;
  final String? supervisorUserId;
}

class _IssueInviteDialog extends StatefulWidget {
  const _IssueInviteDialog({required this.schools, required this.counselors});

  final Map<String, String> schools;
  final List<AssignableCounselor> counselors;

  @override
  State<_IssueInviteDialog> createState() => _IssueInviteDialogState();
}

class _IssueInviteDialogState extends State<_IssueInviteDialog> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();
  SetuStaffRole _role = SetuStaffRole.counselingDesk;
  String _tier = 'external_network';
  String? _institutionId;
  String? _supervisorId;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.schools.isNotEmpty) {
      _institutionId = widget.schools.keys.first;
    }
    if (widget.counselors.isNotEmpty) {
      _supervisorId = widget.counselors.first.userId;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  void _onRoleChanged(SetuStaffRole next) {
    setState(() {
      _role = next;
      _tier = switch (next) {
        SetuStaffRole.minedSupervisor => 'mined_central',
        SetuStaffRole.schoolDirector => 'school_director',
        SetuStaffRole.counselingDesk => 'external_network',
      };
    });
  }

  void _submit() {
    final String email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Escribí un correo institucional válido.');
      return;
    }
    if ((_tier == 'school_plant' || _role == SetuStaffRole.schoolDirector) &&
        _institutionId == null) {
      setState(() => _error = 'Elegí el colegio para esta invitación.');
      return;
    }
    if (_tier == 'practicante_5to' && _supervisorId == null) {
      setState(() => _error = 'Elegí el psicólogo tutor.');
      return;
    }
    Navigator.of(context).pop(
      _InviteDraftResult(
        email: email,
        role: _role,
        staffTier: _tier,
        institutionId:
            (_tier == 'school_plant' || _role == SetuStaffRole.schoolDirector)
            ? _institutionId
            : null,
        fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        supervisorUserId: _tier == 'practicante_5to' ? _supervisorId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool needsSchool =
        _tier == 'school_plant' || _role == SetuStaffRole.schoolDirector;
    return AlertDialog(
      title: const Text('Nueva invitación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StaffField(
              label: 'Correo institucional',
              controller: _email,
              hint: 'nombre@colegio.edu.ni',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            StaffField(
              label: 'Nombre referencial (opcional)',
              controller: _name,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            const Text('Rol', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<SetuStaffRole>(
              initialValue: _role,
              items: <DropdownMenuItem<SetuStaffRole>>[
                for (final SetuStaffRole r in SetuStaffRole.values)
                  DropdownMenuItem<SetuStaffRole>(value: r, child: Text(r.label)),
              ],
              onChanged: (SetuStaffRole? value) {
                if (value != null) _onRoleChanged(value);
              },
            ),
            if (_role == SetuStaffRole.counselingDesk) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Equipo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _tier,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'school_plant',
                    child: Text('Planta del colegio'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'external_network',
                    child: Text('Red externa'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'practicante_5to',
                    child: Text('Practicante 5.º año'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) setState(() => _tier = value);
                },
              ),
            ],
            if (needsSchool && widget.schools.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Colegio',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _institutionId,
                items: <DropdownMenuItem<String>>[
                  for (final MapEntry<String, String> e
                      in widget.schools.entries)
                    DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                ],
                onChanged: (String? value) =>
                    setState(() => _institutionId = value),
              ),
            ],
            if (_tier == 'practicante_5to' &&
                widget.counselors.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Psicólogo tutor',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _supervisorId,
                items: <DropdownMenuItem<String>>[
                  for (final AssignableCounselor c in widget.counselors)
                    DropdownMenuItem<String>(
                      value: c.userId,
                      child: Text(c.email),
                    ),
                ],
                onChanged: (String? value) =>
                    setState(() => _supervisorId = value),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
              StaffNotice(_error!),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Emitir código'),
        ),
      ],
    );
  }
}

class _MinedCoverageSheet extends StatefulWidget {
  const _MinedCoverageSheet({required this.session});

  final StaffSession session;

  @override
  State<_MinedCoverageSheet> createState() => _MinedCoverageSheetState();
}

class _MinedCoverageSheetState extends State<_MinedCoverageSheet> {
  SchoolCoverageAndAssignmentsView? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final SchoolCoverageAndAssignmentsView res = await widget.session.backend
          .schoolCoverageAndAssignments();
      if (!mounted) return;
      setState(() {
        _data = res;
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

  Future<void> _toggleMinedSchool(SchoolCoverageStatusView school) async {
    setState(() => _busy = true);
    try {
      await widget.session.backend.setSchoolExternalCoverage(
        institutionId: school.institutionId,
        minedExternalEnabled: !school.minedExternalEnabled,
      );
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(staffErrorMessage(failure))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleAssignment(
    SchoolCoverageStatusView school,
    ExternalCounselorAssignmentView counselor,
    bool assign,
  ) async {
    setState(() => _busy = true);
    try {
      await widget.session.backend.assignExternalCounselorSchool(
        counselorUserId: counselor.userId,
        institutionId: school.institutionId,
        active: assign,
      );
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(staffErrorMessage(failure))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _schoolTile(
    SchoolCoverageStatusView school,
    List<ExternalCounselorAssignmentView> counselors,
  ) {
    final String statusText = !school.minedExternalEnabled
        ? 'Pausado por MINED'
        : school.externalSupportMode == ExternalCoverageMode.temporaryUntil &&
              school.externalSupportUntil != null
        ? 'Apoyo temporal hasta ${staffShortDate(school.externalSupportUntil!)}'
        : school.externalSupportMode.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CureandoTheme.blueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5C1EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      school.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CureandoTheme.secondaryInk,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: school.minedExternalEnabled,
                onChanged: _busy ? null : (_) => _toggleMinedSchool(school),
              ),
            ],
          ),
          if (counselors.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Profesionales externos:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final ExternalCounselorAssignmentView c in counselors)
                  FilterChip(
                    label: Text(c.displayName),
                    selected: c.assignedInstitutionIds.contains(
                      school.institutionId,
                    ),
                    onSelected: _busy
                        ? null
                        : (bool selected) =>
                              _toggleAssignment(school, c, selected),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SchoolCoverageAndAssignmentsView? data = _data;
    final List<SchoolCoverageStatusView> assigned =
        data?.schools
            .where((SchoolCoverageStatusView s) => s.assignedExternalCount > 0)
            .toList() ??
        const <SchoolCoverageStatusView>[];
    final List<SchoolCoverageStatusView> available =
        data?.schools
            .where((SchoolCoverageStatusView s) => s.assignedExternalCount == 0)
            .toList() ??
        const <SchoolCoverageStatusView>[];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Cobertura de Red externa',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_error != null) ...<Widget>[
                      StaffNotice(_error!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ] else if (_loading || data == null)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Cargando cobertura externa',
                          ),
                        ),
                      )
                    else ...<Widget>[
                      const Text(
                        'Colegios asignados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (assigned.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: Text(
                            'Ningún colegio tiene profesionales externos asignados todavía.',
                          ),
                        )
                      else
                        for (final SchoolCoverageStatusView s in assigned)
                          _schoolTile(s, data.externalCounselors),
                      const SizedBox(height: 12),
                      const Text(
                        'Colegios disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (available.isEmpty)
                        const Text('Todos los colegios ya tienen asignación externa.')
                      else
                        for (final SchoolCoverageStatusView s in available)
                          _schoolTile(s, data.externalCounselors),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
