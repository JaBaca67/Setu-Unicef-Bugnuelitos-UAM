import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/mesh/mesh_bridge_keys.dart';
import '../../shared/mesh/mesh_envelope.dart';
import '../../shared/mesh/mesh_relay_service.dart';
import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_alert.dart';
import 'staff_backend.dart';
import 'staff_inbox_screens.dart';
import 'staff_widgets.dart';

const TextStyle _heading = TextStyle(
  fontSize: 26,
  height: 1.15,
  fontWeight: FontWeight.w700,
  color: CureandoTheme.ink,
);
const TextStyle _section = TextStyle(
  fontSize: 21,
  height: 1.2,
  fontWeight: FontWeight.w700,
  color: CureandoTheme.ink,
);
const TextStyle _text = TextStyle(fontSize: 16, height: 1.4);
const TextStyle _muted = TextStyle(
  fontSize: 15,
  color: CureandoTheme.secondaryInk,
);

/// Estado del caso con las palabras que usa la dirección. Describe en qué
/// está el trámite, no un resultado.
String _directorStatus(SetuCaseStatus status) => switch (status) {
  SetuCaseStatus.received => 'Aviso recibido',
  SetuCaseStatus.inListening => 'En Mesa de Escucha',
  SetuCaseStatus.sheetSent => 'Ficha recibida',
  SetuCaseStatus.schoolActing => 'En actuación del centro',
  SetuCaseStatus.escalated => 'Escalado al MINED',
  SetuCaseStatus.closed => 'Cerrado',
};

const List<SetuSituationType> _teacherNoticeTypes = <SetuSituationType>[
  SetuSituationType.physicalBullying,
  SetuSituationType.verbalBullying,
  SetuSituationType.socialBullying,
  SetuSituationType.cyberbullying,
  SetuSituationType.sexualViolence,
];

String _situation(SetuSituationType type) =>
    staffCaseKind(type, SetuStudentCaseRole.victim).split(' · ').first;

/// Vista de Dirección (`/personal/direccion`): avisos mínimos y fichas
/// autorizadas del centro. Nunca muestra relato, chat ni notas.
class DirectorInboxScreen extends StatefulWidget {
  const DirectorInboxScreen({super.key, required this.session, this.meshRelay});

  final StaffSession session;
  final MeshRelayService? meshRelay;

  @override
  State<DirectorInboxScreen> createState() => _DirectorInboxScreenState();
}

class _DirectorInboxScreenState extends StaffInboxState<DirectorInboxScreen> {
  Set<String> _withSheet = const <String>{};
  SchoolCoverageStatusView? _coverage;
  List<StaffActivationInviteView> _invites =
      const <StaffActivationInviteView>[];
  bool _bluetoothRequired = false;
  bool _meshActive = false;
  int _lastSyncedCount = 0;

  @override
  StaffSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _lastSyncedCount = widget.meshRelay?.syncedCount ?? 0;
    widget.meshRelay?.addListener(_onMeshChanged);
    unawaited(_ensureDirectorMesh());
  }

  @override
  void dispose() {
    widget.meshRelay?.removeListener(_onMeshChanged);
    super.dispose();
  }

  void _onMeshChanged() {
    final MeshRelayService? relay = widget.meshRelay;
    if (relay != null && relay.syncedCount > _lastSyncedCount) {
      _lastSyncedCount = relay.syncedCount;
      unawaited(load());
    }
    if (mounted) setState(() {});
  }

  Future<void> _ensureDirectorMesh() async {
    final MeshRelayService? relay = widget.meshRelay;
    final String? schoolCode = session.active?.institutionPublicCode;
    if (relay == null || schoolCode == null || schoolCode.trim().isEmpty) {
      return;
    }
    try {
      if (relay.recipientDirectory != null) {
        await relay.prepareSchoolReceiver(schoolCode);
      }
      final bool started = await relay.ensureReadyAndStart(
        endpointName: 'setu-node',
      );
      if (!mounted) return;
      if (!started) {
        setState(() {
          _bluetoothRequired = true;
          _meshActive = false;
        });
        return;
      }
      if (relay.recipientDirectory == null) {
        final schoolKey = await MeshSchoolKeys.demoSchoolKeyPair(schoolCode);
        await relay.setSchoolContext(
          schoolCode: schoolCode,
          schoolKeyPair: schoolKey,
        );
      }
      if (!mounted) return;
      setState(() {
        _bluetoothRequired = false;
        _meshActive = true;
      });
    } on MissingPluginException {
      // Entorno sin canal nativo Android (ej. pruebas de widgets en escritorio).
    } on Object {
      if (!mounted) return;
      setState(() {
        _bluetoothRequired = true;
        _meshActive = false;
      });
    }
  }

  @override
  Future<void> beforeLoad() async {
    await widget.meshRelay?.syncPendingAsBridge();
  }

  @override
  Future<void> loadExtra() async {
    final StaffBackend backend = session.backend;
    final String? institution = session.active?.institutionId;
    final List<CaseActionSheetView> sheets = await backend.sheets();
    _withSheet = <String>{
      for (final CaseActionSheetView sheet in sheets) sheet.caseId,
    };
    if (institution != null) {
      final SchoolCoverageAndAssignmentsView coverageView = await backend
          .schoolCoverageAndAssignments(institutionId: institution);
      _coverage = coverageView.schools
          .where((SchoolCoverageStatusView s) => s.institutionId == institution)
          .firstOrNull;
      _invites = await backend.invites(institutionId: institution);
    }
  }

  Future<void> _open(StaffCaseSummary item) async {
    if (item.id.startsWith('mesh:')) {
      await showLocalMeshAlertDialog(
        context,
        referenceCode: item.referenceCode,
        kindLabel: staffCaseKind(
          item.situationType,
          item.studentRole,
          origin: item.origin,
        ),
        detailMessage:
            'Esta alerta mínima llegó por Bluetooth/mesh sin internet. '
            'Cuando un teléfono puente tenga conexión, se sincronizará con la '
            'plataforma central.',
        onSyncNow: widget.meshRelay?.remoteGateway == null
            ? null
            : () async {
                final int synced =
                    await widget.meshRelay?.syncPendingAsBridge() ?? 0;
                if (!mounted) return;
                if (synced > 0) {
                  showSetuBottomAlert(
                    context,
                    'Alerta sincronizada con la plataforma.',
                    kind: SetuAlertKind.success,
                  );
                  await load();
                } else {
                  showSetuBottomAlert(
                    context,
                    'Todavía no pudimos sincronizar. Revisá tu conexión e intentá de nuevo.',
                    kind: SetuAlertKind.warning,
                  );
                }
              },
      );
      return;
    }
    await context.push('/personal/direccion/caso/${item.id}');
    if (mounted) await load();
  }

  List<StaffCaseSummary> _visibleCases() {
    final List<StaffCaseSummary> remote = cases ?? const <StaffCaseSummary>[];
    final List<MeshMinimalAlertPayload> localAlerts =
        filterUnsyncedSchoolMeshAlerts(
          relay: widget.meshRelay,
          schoolCode: session.active?.institutionPublicCode,
          remoteCases: remote,
        );
    if (localAlerts.isEmpty) return remote;
    final List<StaffCaseSummary> merged = <StaffCaseSummary>[...remote];
    for (final MeshMinimalAlertPayload alert in localAlerts) {
      merged.insert(
        0,
        StaffCaseSummary(
          id: 'mesh:${alert.clientOperationId}',
          referenceCode: meshReferenceCode(alert.clientOperationId),
          institutionId: session.active?.institutionId ?? '',
          situationType: SetuSituationType.fromWire(alert.situationType),
          studentRole: SetuStudentCaseRole.fromWire(alert.studentRole),
          origin: SetuAlertOrigin.mesh,
          status: SetuCaseStatus.received,
          humanLevel: null,
          involvesStaff: false,
          assignedCounselorId: null,
          chatAvailableNotice: false,
          urgentReferralTriggered: false,
          concurrencyVersion: 0,
          declaredAt: alert.declaredAt,
          receivedCentrallyAt: alert.declaredAt,
        ),
      );
    }
    return merged;
  }

  Future<void> _teacherNotice() async {
    final String? institution = session.active?.institutionId;
    if (institution == null) return;
    final bool saved =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext sheet) => _TeacherNoticeSheet(
            backend: session.backend,
            institutionId: institution,
          ),
        ) ??
        false;
    if (saved && mounted) await load();
  }

  Future<void> _manageCoverage() async {
    final SchoolCoverageStatusView? coverage = _coverage;
    if (coverage == null) return;
    final bool saved =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext sheet) => _DirectorCoverageSheet(
            backend: session.backend,
            coverage: coverage,
          ),
        ) ??
        false;
    if (saved && mounted) await load();
  }

  Future<void> _requestPlantInvite() async {
    final String? institution = session.active?.institutionId;
    if (institution == null) return;
    final bool saved =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext sheet) => _DirectorInviteRequestSheet(
            backend: session.backend,
            institutionId: institution,
            schoolName: session.active?.place ?? '',
            existingInvites: _invites,
          ),
        ) ??
        false;
    if (saved && mounted) await load();
  }

  Widget _coverageBanner(SchoolCoverageStatusView coverage) {
    final String statusLabel;
    if (!coverage.minedExternalEnabled) {
      statusLabel = 'Pausado por MINED central';
    } else if (coverage.externalSupportMode ==
            ExternalCoverageMode.temporaryUntil &&
        coverage.externalSupportUntil != null) {
      statusLabel =
          'Apoyo temporal hasta ${staffShortDate(coverage.externalSupportUntil!)}';
    } else {
      statusLabel = coverage.externalSupportMode.label;
    }

    return Container(
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
              const Icon(Icons.hub_outlined, color: CureandoTheme.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Cobertura de Red externa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _manageCoverage,
                child: const Text('Configurar'),
              ),
            ],
          ),
          Text(statusLabel, style: _muted),
          if (!coverage.minedExternalEnabled)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'MINED deshabilitó o pausó el apoyo externo para tu centro.',
                style: TextStyle(
                  fontSize: 13,
                  color: CureandoTheme.secondaryInk,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(StaffCaseSummary item) => Material(
    color: CureandoTheme.blueSoft,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFA5C1EF)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _open(item),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        item.referenceCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      StaffTag(
                        _directorStatus(item.status),
                        highlight:
                            _withSheet.contains(item.id) &&
                            item.status == SetuCaseStatus.sheetSent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    staffCaseKind(
                      item.situationType,
                      item.studentRole,
                      origin: item.origin,
                    ),
                    style: _text,
                  ),
                  Text(
                    'Recibido: ${staffShortDate(item.receivedCentrallyAt)}',
                    style: _muted,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 32,
              color: CureandoTheme.blue,
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => StaffAreaScaffold(
    session: session,
    onRefresh: load,
    bottom: session.backend.supportsTeacherNotice
        ? OutlinedButton(
            style: flowSecondaryStyle(),
            onPressed: _teacherNotice,
            child: const Text('Registrar aviso docente'),
          )
        : null,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: const Text('Avisos y fichas', style: _heading),
              ),
            ),
            IconButton(
              tooltip: 'Cartel QR del colegio',
              onPressed: () => context.push<void>('/personal/direccion/cartel'),
              icon: const Icon(Icons.qr_code_2_rounded),
            ),
          ],
        ),
        Text(session.active?.place ?? '', style: _text),
        const SizedBox(height: 12),
        StaffMeshStatusBanner(
          bluetoothRequired: _bluetoothRequired,
          meshActive: _meshActive,
          onEnableBluetooth: _ensureDirectorMesh,
          description:
              'Activá el Bluetooth de este teléfono para recibir alertas '
              'mínimas del centro sin internet.',
        ),
        if (_coverage != null) ...<Widget>[
          _coverageBanner(_coverage!),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: CureandoTheme.ink,
            side: const BorderSide(color: CureandoTheme.blue, width: 1.5),
          ),
          onPressed: _requestPlantInvite,
          icon: const Icon(
            Icons.person_add_outlined,
            color: CureandoTheme.blue,
          ),
          label: const Text('Solicitar invitación de planta'),
        ),
        const SizedBox(height: 16),
        ...listBody(
          visible: _visibleCases(),
          empty: 'No hay avisos para tu centro.',
          tile: _tile,
        ),
      ],
    ),
  );
}

class _TeacherNoticeSheet extends StatefulWidget {
  const _TeacherNoticeSheet({
    required this.backend,
    required this.institutionId,
  });

  final StaffBackend backend;
  final String institutionId;

  @override
  State<_TeacherNoticeSheet> createState() => _TeacherNoticeSheetState();
}

class _TeacherNoticeSheetState extends State<_TeacherNoticeSheet> {
  final OperationIds _operations = OperationIds();
  SetuSituationType? _type;
  bool _involvesStaff = false;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final SetuSituationType? type = _type;
    if (type == null) {
      setState(() => _error = 'Elegí el tipo de situación.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.backend.recordTeacherNotice(
        operationId: _operations.idFor('${type.wireValue}|$_involvesStaff'),
        institutionId: widget.institutionId,
        situationType: type,
        involvesStaff: _involvesStaff,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = staffErrorMessage(failure);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'Aviso docente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registrá lo que avisó una persona docente. No escribas nombres '
            'ni detalles: el aviso solo lleva el tipo de situación.',
            style: _text,
          ),
          const SizedBox(height: 8),
          RadioGroup<SetuSituationType>(
            groupValue: _type,
            onChanged: (SetuSituationType? value) =>
                setState(() => _type = value),
            child: Column(
              children: <Widget>[
                for (final SetuSituationType type in _teacherNoticeTypes)
                  RadioListTile<SetuSituationType>(
                    contentPadding: EdgeInsets.zero,
                    value: type,
                    title: Text(_situation(type)),
                  ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _involvesStaff,
            onChanged: (bool? value) =>
                setState(() => _involvesStaff = value ?? false),
            title: const Text('Involucra a personal del centro'),
            subtitle: const Text(
              'El aviso pasa a la supervisión del MINED y deja de verse en '
              'esta bandeja.',
            ),
          ),
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            const SizedBox(height: 8),
          ],
          StaffPrimaryButton(
            label: 'Registrar aviso',
            busy: _saving,
            onPressed: _save,
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}

/// Aviso del centro (`/personal/direccion/caso/:id`): datos mínimos, ficha
/// autorizada y registro de los cinco pasos de actuación.
class DirectorCaseScreen extends StatefulWidget {
  const DirectorCaseScreen({
    super.key,
    required this.session,
    required this.caseId,
  });

  final StaffSession session;
  final String caseId;

  @override
  State<DirectorCaseScreen> createState() => _DirectorCaseScreenState();
}

class _DirectorCaseScreenState extends State<DirectorCaseScreen> {
  StaffCaseSummary? _case;
  List<CaseActionSheetView> _sheets = const <CaseActionSheetView>[];
  List<SchoolActionRecordView> _actions = const <SchoolActionRecordView>[];
  bool _loaded = false;
  String? _error;

  StaffBackend get _backend => widget.session.backend;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final StaffCaseSummary? found = (await _backend.cases())
          .where((StaffCaseSummary item) => item.id == widget.caseId)
          .firstOrNull;
      final List<CaseActionSheetView> sheets = found == null
          ? const <CaseActionSheetView>[]
          : await _backend.sheets(caseId: found.id);
      final List<SchoolActionRecordView> actions = found == null
          ? const <SchoolActionRecordView>[]
          : await _backend.schoolActions(found.id);
      if (!mounted) return;
      setState(() {
        _case = found;
        _sheets = sheets;
        _actions = actions;
        _loaded = true;
      });
    } on Object catch (failure) {
      if (mounted) setState(() => _error = staffErrorMessage(failure));
    }
  }

  Future<void> _record(StaffCaseSummary item, SetuSchoolActionStep step) async {
    final bool saved =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext sheet) => _ActionSheet(
            backend: _backend,
            item: item,
            step: step,
            actionSheetId: _sheets.firstOrNull?.id,
          ),
        ) ??
        false;
    if (saved && mounted) await _load();
  }

  Widget _sheetCard(CaseActionSheetView sheet) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFDDEAFB),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: const Text('Ficha de Mesa de Escucha', style: _section),
        ),
        const SizedBox(height: 6),
        Text(
          staffLevelLabel(sheet.humanLevel),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(sheet.guidanceNotes, style: _text),
        const SizedBox(height: 4),
        Text('Emitida: ${staffShortDate(sheet.issuedAt)}', style: _muted),
      ],
    ),
  );

  Widget _stepTile(StaffCaseSummary item, SetuSchoolActionStep step) {
    final List<SchoolActionRecordView> done = _actions
        .where((SchoolActionRecordView action) => action.step == step)
        .toList();
    final bool closed = item.status == SetuCaseStatus.closed;
    final int number = SetuSchoolActionStep.values.indexOf(step) + 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                done.isEmpty
                    ? Icons.radio_button_unchecked_rounded
                    : Icons.check_circle_rounded,
                color: done.isEmpty
                    ? CureandoTheme.secondaryInk
                    : const Color(0xFF008A2E),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$number · ${step.label}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      done.isEmpty ? 'Pendiente' : 'Registrado',
                      style: _muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final SchoolActionRecordView action in done)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(action.actionNotes, style: _text),
                  Text(
                    <String>[
                      staffShortDate(action.createdAt),
                      if (action.isGroupAction) 'Acción grupal',
                      if (action.proposesClosure) 'Cierre propuesto al MINED',
                    ].join(' · '),
                    style: _muted,
                  ),
                ],
              ),
            ),
          if (!closed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _record(item, step),
                child: Text(
                  done.isEmpty ? 'Registrar' : 'Agregar otro registro',
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _content(StaffCaseSummary item) => <Widget>[
    Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        StaffTag(_directorStatus(item.status)),
        if (item.urgentReferralTriggered)
          const StaffTag('Derivación urgente registrada', highlight: true),
      ],
    ),
    const SizedBox(height: 8),
    Text(
      staffCaseKind(item.situationType, item.studentRole, origin: item.origin),
      style: _text,
    ),
    Text(
      'Recibido: ${staffShortDate(item.receivedCentrallyAt)}',
      style: _muted,
    ),
    const SizedBox(height: 16),
    if (_sheets.isEmpty)
      const StaffNotice(
        'Todavía no hay una ficha autorizada para este aviso. La emite Mesa '
        'de Escucha después de su valoración.',
        error: false,
      )
    else
      for (final CaseActionSheetView sheet in _sheets) _sheetCard(sheet),
    const SizedBox(height: 16),
    Semantics(
      header: true,
      child: const Text('Actuaciones del centro', style: _section),
    ),
    const SizedBox(height: 4),
    const Text(
      'Registrá lo que hizo el centro en cada paso. No escribas nombres de '
      'estudiantes.',
      style: _muted,
    ),
    const SizedBox(height: 10),
    for (final SetuSchoolActionStep step in SetuSchoolActionStep.values)
      _stepTile(item, step),
  ];

  @override
  Widget build(BuildContext context) {
    final StaffCaseSummary? item = _case;
    return FlowScaffold(
      header: FlowHeader(
        title: item == null ? 'Aviso' : 'Aviso ${item.referenceCode}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ] else if (!_loaded)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando aviso',
                ),
              ),
            )
          else if (item == null)
            const StaffNotice('Ese caso no está disponible para tu cuenta.')
          else
            ..._content(item),
        ],
      ),
    );
  }
}

class _ActionSheet extends StatefulWidget {
  const _ActionSheet({
    required this.backend,
    required this.item,
    required this.step,
    required this.actionSheetId,
  });

  final StaffBackend backend;
  final StaffCaseSummary item;
  final SetuSchoolActionStep step;
  final String? actionSheetId;

  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  final OperationIds _operations = OperationIds();
  final TextEditingController _notes = TextEditingController();
  bool _closure = false;
  bool _saving = false;
  String? _error;

  /// Con la identidad reservada, este paso solo se hace con el grupo.
  bool get _family => widget.step == SetuSchoolActionStep.notifyFamilyOrGroup;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_notes.text.trim().isEmpty) {
      setState(() => _error = 'Escribí qué hizo el centro en este paso.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final SchoolActionDraft draft = SchoolActionDraft(
      caseId: widget.item.id,
      actionSheetId: widget.actionSheetId,
      step: widget.step,
      isGroupAction: _family,
      notes: _notes.text.trim(),
      proposesClosure: _closure,
      expectedVersion: widget.item.concurrencyVersion,
    );
    try {
      await widget.backend.recordSchoolAction(
        operationId: _operations.idFor(draft.fingerprint),
        action: draft,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = staffErrorMessage(failure);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              widget.step.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (_family) ...<Widget>[
            const SizedBox(height: 8),
            const StaffNotice(
              'La identidad del estudiante está reservada. Este paso se '
              'registra como acción con el grupo, sin contactar a una '
              'familia en particular.',
              error: false,
            ),
          ],
          const SizedBox(height: 12),
          StaffField(
            label: 'Qué hizo el centro',
            controller: _notes,
            hint:
                'Describí la actuación realizada por el colegio (sin datos '
                'clínicos)...',
            maxLines: 4,
            maxLength: 1500,
            capitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _closure,
            onChanged: (bool? value) =>
                setState(() => _closure = value ?? false),
            title: const Text('Documentar y enviar al MINED'),
            subtitle: const Text(
              'Propone el cierre. El MINED lo revisa; el caso no se cierra '
              'desde el centro.',
            ),
          ),
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            const SizedBox(height: 8),
          ],
          StaffPrimaryButton(
            label: 'Guardar registro',
            busy: _saving,
            onPressed: _save,
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}

class _DirectorCoverageSheet extends StatefulWidget {
  const _DirectorCoverageSheet({required this.backend, required this.coverage});

  final StaffBackend backend;
  final SchoolCoverageStatusView coverage;

  @override
  State<_DirectorCoverageSheet> createState() => _DirectorCoverageSheetState();
}

class _DirectorCoverageSheetState extends State<_DirectorCoverageSheet> {
  late ExternalCoverageMode _mode = widget.coverage.externalSupportMode;
  late DateTime _until =
      widget.coverage.externalSupportUntil ?? _defaultEndOfDay();
  bool _saving = false;
  String? _error;

  static DateTime _defaultEndOfDay() {
    final DateTime now = DateTime.now();
    final DateTime eod = DateTime(now.year, now.month, now.day, 18);
    return eod.isAfter(now) ? eod : now.add(const Duration(hours: 4));
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _until.isAfter(now) ? _until : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_until.toLocal()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _until = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.backend.setSchoolExternalCoverage(
        institutionId: widget.coverage.institutionId,
        mode: _mode,
        until: _mode == ExternalCoverageMode.temporaryUntil
            ? _until.toUtc()
            : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = staffErrorMessage(failure);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allowedByMined = widget.coverage.minedExternalEnabled;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                'Cobertura de Red externa',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 6),
            Text(widget.coverage.name, style: _muted),
            const SizedBox(height: 12),
            if (!allowedByMined) ...<Widget>[
              const StaffNotice(
                'La supervisión del MINED tiene pausada la cobertura externa '
                'para este colegio. Consultá con MINED para reactivarla.',
              ),
              const SizedBox(height: 12),
            ],
            RadioGroup<ExternalCoverageMode>(
              groupValue: _mode,
              onChanged: (ExternalCoverageMode? value) {
                if (value != null && allowedByMined) {
                  setState(() => _mode = value);
                }
              },
              child: Column(
                children: <Widget>[
                  RadioListTile<ExternalCoverageMode>(
                    value: ExternalCoverageMode.disabled,
                    enabled: allowedByMined,
                    title: const Text('Apoyo externo desactivado'),
                    subtitle: const Text(
                      'Solo atiende el equipo de planta autorizado.',
                    ),
                  ),
                  RadioListTile<ExternalCoverageMode>(
                    value: ExternalCoverageMode.enabled,
                    enabled: allowedByMined,
                    title: const Text('Apoyo externo habilitado'),
                    subtitle: const Text(
                      'Deriva a Red externa asignada si planta declina o no está.',
                    ),
                  ),
                  RadioListTile<ExternalCoverageMode>(
                    value: ExternalCoverageMode.temporaryUntil,
                    enabled: allowedByMined,
                    title: const Text('Apoyo temporal hasta fecha y hora'),
                    subtitle: Text(
                      'Vence automáticamente el ${staffShortDate(_until)}.',
                    ),
                  ),
                ],
              ),
            ),
            if (_mode == ExternalCoverageMode.temporaryUntil &&
                allowedByMined) ...<Widget>[
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text('Cambiar vencimiento (${staffShortDate(_until)})'),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
              StaffNotice(_error!),
            ],
            const SizedBox(height: 14),
            if (allowedByMined)
              StaffPrimaryButton(
                label: 'Guardar cobertura',
                busy: _saving,
                onPressed: _save,
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectorInviteRequestSheet extends StatefulWidget {
  const _DirectorInviteRequestSheet({
    required this.backend,
    required this.institutionId,
    required this.schoolName,
    required this.existingInvites,
  });

  final StaffBackend backend;
  final String institutionId;
  final String schoolName;
  final List<StaffActivationInviteView> existingInvites;

  @override
  State<_DirectorInviteRequestSheet> createState() =>
      _DirectorInviteRequestSheetState();
}

class _DirectorInviteRequestSheetState
    extends State<_DirectorInviteRequestSheet> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Escribí el correo institucional de la persona.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.backend.requestInvite(
        email: email,
        role: SetuStaffRole.counselingDesk,
        institutionId: widget.institutionId,
        staffTier: 'school_plant',
        fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = staffErrorMessage(failure);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'Solicitar invitación de planta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Centro: ${widget.schoolName}. MINED revisa y emite el código en '
            'privado.',
            style: _muted,
          ),
          const SizedBox(height: 14),
          StaffField(
            label: 'Correo institucional',
            controller: _email,
            hint: 'psicologia@colegio.edu.ni',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          StaffField(
            label: 'Nombre y apellidos (opcional)',
            controller: _name,
            capitalization: TextCapitalization.words,
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            StaffNotice(_error!),
          ],
          const SizedBox(height: 14),
          StaffPrimaryButton(
            label: 'Enviar solicitud a MINED',
            busy: _saving,
            onPressed: _submit,
          ),
          if (widget.existingInvites.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            const Text(
              'Solicitudes e invitaciones del centro',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final StaffActivationInviteView inv in widget.existingInvites)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${inv.institutionalEmail} · ${inv.displayStatus}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}
