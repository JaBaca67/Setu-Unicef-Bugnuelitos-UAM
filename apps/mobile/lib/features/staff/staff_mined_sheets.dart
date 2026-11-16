import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_alert.dart';
import 'staff_backend.dart';
import 'staff_inbox_screens.dart';
import 'staff_widgets.dart';

/// Abre la pantalla de MINED para «Invitaciones de personal»:
/// revisar solicitudes, aprobar/emitir, importar CSV, reponer y revocar códigos.
Future<void> showMinedInvitesSheet(
  BuildContext context,
  StaffSession session,
) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (BuildContext _) => _MinedInvitesScreen(session: session),
  ),
);

/// Abre la pantalla de MINED para administrar la cobertura externa por colegio
/// y los centros asignados a cada profesional externo.
Future<void> showMinedCoverageSheet(
  BuildContext context,
  StaffSession session,
) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (BuildContext _) => _MinedCoverageScreen(session: session),
  ),
);

String _tierLabel(String tier) => switch (tier) {
  'school_plant' => StaffTierKind.schoolPlant.label,
  'external_network' => StaffTierKind.externalNetwork.label,
  'practicante_5to' => StaffTierKind.practicante5to.label,
  'mined_central' => StaffTierKind.minedCentral.label,
  'school_director' => StaffTierKind.schoolDirector.label,
  _ => tier,
};

enum _InviteFilter { all, pending, active }

class _MinedInvitesScreen extends StatefulWidget {
  const _MinedInvitesScreen({required this.session});

  final StaffSession session;

  @override
  State<_MinedInvitesScreen> createState() => _MinedInvitesScreenState();
}

class _MinedInvitesScreenState extends State<_MinedInvitesScreen> {
  List<StaffActivationInviteView>? _invites;
  Map<String, String> _schools = const <String, String>{};
  List<AssignableCounselor> _counselors = const <AssignableCounselor>[];
  _InviteFilter _filter = _InviteFilter.all;
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

  Future<void> _showIssuedCodeDialog(
    StaffInviteIssueResult issued, {
    InviteEmailDispatchResult? emailResult,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialog) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Código de activación emitido',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issued.institutionalEmail,
                style: const TextStyle(
                  fontSize: 15,
                  color: CureandoTheme.secondaryInk,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: CureandoTheme.blueSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CureandoTheme.blue, width: 1.5),
                ),
                child: SelectableText(
                  issued.activationCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: CureandoTheme.ink,
                  ),
                ),
              ),
              if (issued.expiresAt != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Vence: ${staffShortDate(issued.expiresAt!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CureandoTheme.secondaryInk,
                  ),
                ),
              ],
              if (emailResult != null) ...<Widget>[
                const SizedBox(height: 12),
                StaffNotice(
                  emailResult.ok && emailResult.sentCount > 0
                      ? 'Código enviado por correo a ${issued.institutionalEmail}.'
                      : !emailResult.configured
                      ? 'Envío por correo pendiente de configurar; copiá y compartí el código en privado.'
                      : 'No pudimos enviar el correo (${emailResult.reason ?? 'error SMTP'}). Copiá el código manualmente.',
                  error: !(emailResult.ok && emailResult.sentCount > 0),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CureandoTheme.blue,
                        side: const BorderSide(
                          color: CureandoTheme.blue,
                          width: 1.5,
                        ),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: issued.activationCode),
                        );
                        showSetuBottomAlert(
                          context,
                          'Código copiado al portapapeles.',
                          kind: SetuAlertKind.success,
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CureandoTheme.blue,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialog).pop(),
                      child: const Text('Listo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInvite() async {
    final _InviteDraftResult? draft = await Navigator.of(context)
        .push<_InviteDraftResult>(
          MaterialPageRoute<_InviteDraftResult>(
            builder: (BuildContext _) => _IssueInviteScreen(
              schools: _schools,
              counselors: _counselors,
            ),
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
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
    }
  }

  Future<void> _openBulkCsvImport() async {
    final _BulkCsvImportDraft? draft = await Navigator.of(context)
        .push<_BulkCsvImportDraft>(
          MaterialPageRoute<_BulkCsvImportDraft>(
            builder: (BuildContext _) => const _BulkCsvImportScreen(),
          ),
        );
    if (draft == null || draft.rows.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final BulkInviteResult bulk = await widget.session.backend
          .issueInvitesBulk(rows: draft.rows);
      InviteEmailDispatchResult? emailResult;
      if (draft.sendEmail) {
        final List<InviteEmailRecipient> recipients = <InviteEmailRecipient>[
          for (final BulkInviteRowResult row in bulk.results)
            if (row.ok &&
                row.activationCode != null &&
                row.activationCode!.isNotEmpty)
              InviteEmailRecipient(
                inviteId: row.inviteId,
                institutionalEmail: row.institutionalEmail,
                fullName: row.fullName,
                roleLabel: row.role == null
                    ? null
                    : '${row.role!.label} · ${_tierLabel(row.staffTier ?? '')}',
                scopeLabel: row.scopeLabel,
                activationCode: row.activationCode!,
                expiresAt: row.expiresAt,
              ),
        ];
        if (recipients.isNotEmpty) {
          emailResult = await widget.session.backend.sendInviteEmails(
            recipients: recipients,
          );
        }
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await _showBulkImportSummary(bulk, emailResult);
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
    }
  }

  Future<void> _showBulkImportSummary(
    BulkInviteResult bulk,
    InviteEmailDispatchResult? emailResult,
  ) async {
    final String exportLines = <String>[
      for (final BulkInviteRowResult r in bulk.results)
        if (r.ok && r.activationCode != null)
          '${r.fullName ?? ''};${r.institutionalEmail};${r.activationCode};${r.scopeLabel ?? ''}',
    ].join('\n');
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialog) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Resultado de importación CSV',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CureandoTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emitidas: ${bulk.issuedCount} · Con error: ${bulk.errorCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (emailResult != null) ...<Widget>[
                  const SizedBox(height: 10),
                  StaffNotice(
                    emailResult.configured
                        ? 'Correos enviados: ${emailResult.sentCount} · Fallidos: ${emailResult.failedCount}'
                        : 'Gmail SMTP pendiente de configurar; podés copiar la lista de códigos.',
                    error: !emailResult.ok,
                  ),
                ],
                const SizedBox(height: 12),
                for (final BulkInviteRowResult r in bulk.results.take(15))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      r.ok
                          ? '✓ ${r.institutionalEmail} → ${r.activationCode}'
                          : '✕ ${r.institutionalEmail}: ${r.error ?? 'error'}',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: r.ok ? CureandoTheme.ink : CureandoTheme.pink,
                      ),
                    ),
                  ),
                if (bulk.results.length > 15)
                  Text(
                    '... y ${bulk.results.length - 15} filas más.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CureandoTheme.secondaryInk,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    if (exportLines.isNotEmpty) ...<Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CureandoTheme.blue,
                            side: const BorderSide(
                              color: CureandoTheme.blue,
                              width: 1.5,
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: exportLines));
                            showSetuBottomAlert(
                              context,
                              'Lista de códigos copiada al portapapeles.',
                              kind: SetuAlertKind.success,
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copiar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: CureandoTheme.blue,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialog).pop(),
                        child: const Text('Listo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      InviteEmailDispatchResult? emailResult;
      if (!widget.session.backend.isDemo) {
        emailResult = await widget.session.backend.sendInviteEmails(
          recipients: <InviteEmailRecipient>[
            InviteEmailRecipient(
              inviteId: issued.inviteId,
              institutionalEmail: issued.institutionalEmail,
              fullName: invite.fullName,
              roleLabel: '${issued.role.label} · ${_tierLabel(issued.staffTier)}',
              scopeLabel: issued.scopeLabel,
              activationCode: issued.activationCode,
              expiresAt: issued.expiresAt,
            ),
          ],
        );
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await _showIssuedCodeDialog(issued, emailResult: emailResult);
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
    }
  }

  Future<String?> _pickSupervisor() async {
    if (_counselors.isEmpty) {
      showSetuBottomAlert(
        context,
        'No hay psicólogos tutores activos para asignar.',
        kind: SetuAlertKind.warning,
      );
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialog) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Elegí psicólogo tutor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.ink,
                ),
              ),
              const SizedBox(height: 12),
              for (final AssignableCounselor counselor in _counselors)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(counselor.email),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: CureandoTheme.blue,
                  ),
                  onTap: () => Navigator.of(dialog).pop(counselor.userId),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replace(StaffActivationInviteView invite) async {
    final TextEditingController emailController = TextEditingController(
      text: invite.institutionalEmail,
    );
    final String? targetEmail = await showDialog<String>(
      context: context,
      builder: (BuildContext dialog) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Reponer código',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anula el código anterior y emite uno nuevo.',
                style: TextStyle(color: CureandoTheme.secondaryInk),
              ),
              const SizedBox(height: 14),
              StaffField(
                label: 'Correo vinculado',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CureandoTheme.blue,
                        side: const BorderSide(
                          color: CureandoTheme.blue,
                          width: 1.5,
                        ),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialog).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CureandoTheme.blue,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(
                        dialog,
                      ).pop(emailController.text.trim()),
                      child: const Text('Reponer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
    }
  }

  Future<void> _revoke(
    StaffActivationInviteView invite, {
    bool rejectRequest = false,
  }) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialog) => Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    rejectRequest ? 'Rechazar solicitud' : 'Revocar acceso',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CureandoTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rejectRequest
                        ? 'La solicitud de ${invite.fullName ?? invite.institutionalEmail} quedará rechazada.'
                        : 'El código de ${invite.institutionalEmail} dejará de funcionar.',
                    style: const TextStyle(color: CureandoTheme.secondaryInk),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CureandoTheme.blue,
                            side: const BorderSide(
                              color: CureandoTheme.blue,
                              width: 1.5,
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialog).pop(false),
                          child: const Text('Volver'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: CureandoTheme.pink,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialog).pop(true),
                          child: Text(rejectRequest ? 'Rechazar' : 'Revocar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.session.backend.revokeInvite(
        inviteId: invite.inviteId,
        reason: rejectRequest
            ? 'Solicitud rechazada por MINED central'
            : 'Revocada por MINED central',
      );
      if (!mounted) return;
      setState(() => _busy = false);
      showSetuBottomAlert(
        context,
        rejectRequest ? 'Solicitud rechazada.' : 'Invitación revocada.',
        kind: SetuAlertKind.info,
      );
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
    }
  }

  Widget _filterPill(String label, _InviteFilter target) {
    final bool selected = _filter == target;
    return Material(
      color: selected ? CureandoTheme.blue : CureandoTheme.blueSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _filter = target),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? CureandoTheme.blue : const Color(0xFFA5C1EF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : CureandoTheme.ink,
            ),
          ),
        ),
      ),
    );
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
    final bool hasName =
        invite.fullName != null && invite.fullName!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pendingRequest
              ? CureandoTheme.blue
              : const Color(0xFFD5E2F7),
          width: pendingRequest ? 1.5 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hasName
                          ? invite.fullName!.trim()
                          : invite.institutionalEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CureandoTheme.ink,
                      ),
                    ),
                    if (hasName)
                      Text(
                        invite.institutionalEmail,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: CureandoTheme.secondaryInk,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StaffTag(
                invite.displayStatus,
                highlight: pendingRequest || invite.isActiveForRedemption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${invite.role.label} · ${_tierLabel(invite.staffTier)}',
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          if (schoolLabel.isNotEmpty)
            Text(
              schoolLabel,
              style: const TextStyle(
                fontSize: 14,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          if (invite.requesterProgramLabel != null &&
              invite.requesterProgramLabel!.isNotEmpty)
            Text(
              invite.requesterProgramLabel!,
              style: const TextStyle(
                fontSize: 13.5,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          if (pendingRequest || canReplaceOrRevoke) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                if (pendingRequest) ...<Widget>[
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CureandoTheme.blue,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _busy ? null : () => _approveRequest(invite),
                      child: const Text('Aprobar y emitir'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _revoke(invite, rejectRequest: true),
                    child: const Text('Rechazar'),
                  ),
                ] else ...<Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CureandoTheme.blue,
                        side: const BorderSide(
                          color: Color(0xFFA5C1EF),
                          width: 1.5,
                        ),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _busy ? null : () => _replace(invite),
                      child: const Text('Reponer código'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _busy ? null : () => _revoke(invite),
                    child: const Text('Revocar'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<StaffActivationInviteView> allInvites =
        _invites ?? const <StaffActivationInviteView>[];
    final int pendingCount = allInvites
        .where(
          (StaffActivationInviteView i) =>
              i.requestStatus == StaffInviteRequestStatus.pendingApproval &&
              i.revokedAt == null,
        )
        .length;
    final List<StaffActivationInviteView> list = switch (_filter) {
      _InviteFilter.all => allInvites,
      _InviteFilter.pending => allInvites
          .where(
            (StaffActivationInviteView i) =>
                i.requestStatus == StaffInviteRequestStatus.pendingApproval &&
                i.revokedAt == null,
          )
          .toList(),
      _InviteFilter.active => allInvites
          .where((StaffActivationInviteView i) => i.isActiveForRedemption)
          .toList(),
    };

    return FlowScaffold(
      onRefresh: _load,
      header: FlowHeader(
        title: 'Invitaciones de personal',
        onBack: () => Navigator.of(context).pop(),
        trailing: IconButton(
          tooltip: 'Cerrar',
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaffPrimaryButton(
            label: 'Emitir invitación',
            busy: _busy,
            onPressed: _loading ? null : _createInvite,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: flowSecondaryStyle(),
            onPressed: _loading || _busy ? null : _openBulkCsvImport,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Importar CSV'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _filterPill('Todas (${allInvites.length})', _InviteFilter.all),
              _filterPill(
                'Por aprobar ($pendingCount)',
                _InviteFilter.pending,
              ),
              _filterPill('Vigentes', _InviteFilter.active),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
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
              'No hay solicitudes ni invitaciones en esta vista.',
              error: false,
            )
          else
            for (final StaffActivationInviteView invite in list)
              _inviteCard(invite),
        ],
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

class _IssueInviteScreen extends StatefulWidget {
  const _IssueInviteScreen({required this.schools, required this.counselors});

  final Map<String, String> schools;
  final List<AssignableCounselor> counselors;

  @override
  State<_IssueInviteScreen> createState() => _IssueInviteScreenState();
}

class _IssueInviteScreenState extends State<_IssueInviteScreen> {
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
      _error = null;
    });
  }

  void _submit() {
    final String email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Escribí un correo válido.');
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
    return FlowScaffold(
      header: FlowHeader(
        title: 'Nueva invitación',
        onBack: () => Navigator.of(context).pop(),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaffPrimaryButton(
            label: 'Emitir código',
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: flowSecondaryStyle(),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaffField(
            label: 'Correo institucional',
            controller: _email,
            hint: 'nombre@colegio.edu.ni',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          StaffField(
            label: 'Nombre referencial (opcional)',
            controller: _name,
            hint: 'Nombre y apellidos',
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          StaffDropdown<SetuStaffRole>(
            label: 'Rol',
            value: _role,
            items: <DropdownMenuItem<SetuStaffRole>>[
              for (final SetuStaffRole r in SetuStaffRole.values)
                DropdownMenuItem<SetuStaffRole>(value: r, child: Text(r.label)),
            ],
            onChanged: (SetuStaffRole? value) {
              if (value != null) _onRoleChanged(value);
            },
          ),
          if (_role == SetuStaffRole.counselingDesk) ...<Widget>[
            const SizedBox(height: 14),
            StaffDropdown<String>(
              label: 'Equipo',
              value: _tier,
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
            const SizedBox(height: 14),
            StaffDropdown<String?>(
              label: 'Colegio',
              value: _institutionId,
              items: <DropdownMenuItem<String?>>[
                for (final MapEntry<String, String> e in widget.schools.entries)
                  DropdownMenuItem<String?>(
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
            const SizedBox(height: 14),
            StaffDropdown<String?>(
              label: 'Psicólogo tutor',
              value: _supervisorId,
              items: <DropdownMenuItem<String?>>[
                for (final AssignableCounselor c in widget.counselors)
                  DropdownMenuItem<String?>(
                    value: c.userId,
                    child: Text(c.email),
                  ),
              ],
              onChanged: (String? value) =>
                  setState(() => _supervisorId = value),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 14),
            StaffNotice(_error!),
          ],
        ],
      ),
    );
  }
}

class _MinedCoverageScreen extends StatefulWidget {
  const _MinedCoverageScreen({required this.session});

  final StaffSession session;

  @override
  State<_MinedCoverageScreen> createState() => _MinedCoverageScreenState();
}

class _MinedCoverageScreenState extends State<_MinedCoverageScreen> {
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
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
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
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E2F7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              StaffSchoolLogo(schoolName: school.name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      school.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 13.5,
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
            const SizedBox(height: 10),
            const Text(
              'Profesionales externos:',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final ExternalCounselorAssignmentView c in counselors)
                  FilterChip(
                    selectedColor: CureandoTheme.blueSoft,
                    checkmarkColor: CureandoTheme.blue,
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

    return FlowScaffold(
      onRefresh: _load,
      header: FlowHeader(
        title: 'Cobertura de Red externa',
        onBack: () => Navigator.of(context).pop(),
        trailing: IconButton(
          tooltip: 'Cerrar',
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
    );
  }
}

class _BulkCsvImportDraft {
  const _BulkCsvImportDraft({required this.rows, required this.sendEmail});

  final List<BulkInviteRowDraft> rows;
  final bool sendEmail;
}

class _BulkCsvParseOutput {
  const _BulkCsvParseOutput({required this.rows, required this.errors});

  final List<BulkInviteRowDraft> rows;
  final List<String> errors;
}

const String _csvTemplateText =
    'nombre_completo,correo,rol,equipo,colegio_codigo,tutor_correo\n'
    'Ana María López,ana.lopez@colegio.edu.ni,school_director,school_director,AULA26,\n'
    'Carlos Ruiz,carlos.ruiz@minsa.gob.ni,counseling_desk,external_network,,';

_BulkCsvParseOutput _parseInviteCsv(String raw) {
  final List<String> lines = raw
      .split(RegExp(r'\r?\n'))
      .map((String l) => l.trim())
      .where((String l) => l.isNotEmpty)
      .toList();
  final List<BulkInviteRowDraft> rows = <BulkInviteRowDraft>[];
  final List<String> errors = <String>[];
  if (lines.isEmpty) {
    return const _BulkCsvParseOutput(
      rows: <BulkInviteRowDraft>[],
      errors: <String>[],
    );
  }

  for (int idx = 0; idx < lines.length; idx++) {
    final String line = lines[idx];
    final String sep = line.contains(';') && !line.contains(',') ? ';' : ',';
    final List<String> cols = line
        .split(sep)
        .map((String c) => c.trim().replaceAll(RegExp(r'^"|"$'), '').trim())
        .toList();
    if (idx == 0 &&
        cols.length >= 2 &&
        (cols[0].toLowerCase().contains('nombre') ||
            cols[1].toLowerCase().contains('correo') ||
            cols[1].toLowerCase().contains('email'))) {
      continue;
    }
    if (cols.length < 2) {
      errors.add('Línea ${idx + 1}: faltan columnas (mínimo nombre,correo).');
      continue;
    }
    final String fullName = cols[0];
    final String email = cols[1];
    final String rawRole =
        cols.length > 2 ? cols[2].toLowerCase() : 'counseling_desk';
    final String rawTier = cols.length > 3 ? cols[3].toLowerCase() : '';
    final String schoolRef = cols.length > 4 ? cols[4] : '';
    final String supervisorEmail = cols.length > 5 ? cols[5] : '';
    if (!email.contains('@') || !email.contains('.')) {
      errors.add('Línea ${idx + 1}: correo inválido ($email).');
      continue;
    }
    final String role = switch (rawRole) {
      'school_director' || 'director' || 'direccion' || 'dirección' =>
        'school_director',
      'mined_supervisor' || 'mined' => 'mined_supervisor',
      _ => 'counseling_desk',
    };
    final String tier = switch (rawTier) {
      '' => role == 'school_director'
          ? 'school_director'
          : role == 'mined_supervisor'
          ? 'mined_central'
          : 'school_plant',
      'planta' || 'school_plant' => 'school_plant',
      'externa' || 'red externa' || 'external_network' => 'external_network',
      'practicante' || 'practicante_5to' => 'practicante_5to',
      'director' || 'school_director' => 'school_director',
      'mined' || 'mined_central' => 'mined_central',
      _ => rawTier,
    };
    rows.add(
      BulkInviteRowDraft(
        fullName: fullName,
        institutionalEmail: email,
        role: role,
        staffTier: tier,
        schoolRef: schoolRef,
        supervisorEmail: supervisorEmail,
      ),
    );
  }
  return _BulkCsvParseOutput(rows: rows, errors: errors);
}

class _BulkCsvImportScreen extends StatefulWidget {
  const _BulkCsvImportScreen();

  @override
  State<_BulkCsvImportScreen> createState() => _BulkCsvImportScreenState();
}

class _BulkCsvImportScreenState extends State<_BulkCsvImportScreen> {
  final TextEditingController _csv = TextEditingController();
  bool _sendEmail = true;

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  void _insertTemplate() {
    setState(() => _csv.text = _csvTemplateText);
  }

  void _copyTemplate() {
    Clipboard.setData(const ClipboardData(text: _csvTemplateText));
    showSetuBottomAlert(
      context,
      'Plantilla CSV copiada para abrir o pegar en Excel.',
      kind: SetuAlertKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _BulkCsvParseOutput parsed = _parseInviteCsv(_csv.text);
    return FlowScaffold(
      header: FlowHeader(
        title: 'Importar invitaciones CSV',
        onBack: () => Navigator.of(context).pop(),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaffPrimaryButton(
            label: 'Importar (${parsed.rows.length})',
            onPressed: parsed.rows.isEmpty
                ? null
                : () => Navigator.of(context).pop(
                    _BulkCsvImportDraft(
                      rows: parsed.rows,
                      sendEmail: _sendEmail,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: flowSecondaryStyle(),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Pegá filas exportadas de Excel (.csv): '
            'nombre_completo, correo, rol, equipo, colegio_codigo, tutor_correo.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              TextButton.icon(
                onPressed: _insertTemplate,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Cargar ejemplo'),
              ),
              TextButton.icon(
                onPressed: _copyTemplate,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar plantilla'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StaffField(
            label: 'Contenido CSV',
            controller: _csv,
            hint: 'nombre_completo,correo,rol,equipo,colegio_codigo',
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sendEmail,
            onChanged: (bool value) => setState(() => _sendEmail = value),
            title: const Text(
              'Enviar códigos por correo (Gmail SMTP)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (parsed.rows.isNotEmpty)
            StaffNotice(
              '${parsed.rows.length} fila(s) listas para emitir.',
              error: false,
            ),
          if (parsed.errors.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            StaffNotice(parsed.errors.take(3).join('\n')),
          ],
        ],
      ),
    );
  }
}
