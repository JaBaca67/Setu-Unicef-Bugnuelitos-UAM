import 'dart:async';

import 'package:cryptography/cryptography.dart';
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
import 'staff_mined_sheets.dart';
import 'staff_widgets.dart';

const List<String> _months = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Fecha corta en hora local, por ejemplo «13 nov · 10:24».
String staffShortDate(DateTime value) {
  final DateTime local = value.toLocal();
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month - 1]} · ${local.hour}:$minute';
}

/// Tipo y participación con las mismas palabras que eligió el estudiante.
String staffCaseKind(
  SetuSituationType type,
  SetuStudentCaseRole? role, {
  SetuAlertOrigin origin = SetuAlertOrigin.online,
}) {
  final String situation = switch (type) {
    SetuSituationType.physicalBullying => 'Acoso físico',
    SetuSituationType.verbalBullying => 'Acoso verbal',
    SetuSituationType.socialBullying => 'Acoso social',
    SetuSituationType.cyberbullying => 'Ciberacoso',
    SetuSituationType.sexualViolence => 'Violencia sexual',
    SetuSituationType.needToTalk => 'Necesito hablar',
  };
  // Un aviso docente no tiene participación del estudiante (rol nulo).
  final String part = origin == SetuAlertOrigin.teacherNotice
      ? 'Aviso docente'
      : switch (role) {
          null => 'Aviso docente',
          SetuStudentCaseRole.victim => 'Me pasó a mí',
          SetuStudentCaseRole.solidarityWitness => 'Lo vi o supe de alguien',
        };
  return '$situation · $part';
}

/// Texto de la valoración: nunca solo un número ni solo un color.
String staffLevelLabel(int? level) =>
    level == null ? 'Sin valorar' : 'Nivel $level · ${humanLevelLabels[level]}';

const TextStyle _heading = TextStyle(
  fontSize: 28,
  height: 1.15,
  fontWeight: FontWeight.w700,
  color: CureandoTheme.ink,
);

/// Etiqueta con texto; el color solo acompaña.
class StaffTag extends StatelessWidget {
  const StaffTag(this.text, {super.key, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: highlight ? const Color(0xFFFFF3C4) : const Color(0xFFDDEAFB),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CureandoTheme.ink,
      ),
    ),
  );
}

/// Aviso de estado Bluetooth/permisos para red mesh en bandejas de centro.
class StaffMeshStatusBanner extends StatelessWidget {
  const StaffMeshStatusBanner({
    super.key,
    required this.bluetoothRequired,
    required this.meshActive,
    required this.onEnableBluetooth,
    required this.description,
  });

  final bool bluetoothRequired;
  final bool meshActive;
  final VoidCallback onEnableBluetooth;
  final String description;

  @override
  Widget build(BuildContext context) {
    if (bluetoothRequired) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF5B800), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Bluetooth requerido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onEnableBluetooth,
                icon: const Icon(Icons.bluetooth_rounded),
                label: const Text('Activar Bluetooth'),
              ),
            ],
          ),
        ),
      );
    }
    if (meshActive) {
      return const Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: StaffTag(
          'Red mesh activa · escuchando alertas sin internet',
          highlight: true,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Código corto de referencia para alertas recibidas localmente por mesh.
String meshReferenceCode(String clientOperationId) {
  final String suffix = clientOperationId.length >= 6
      ? clientOperationId.substring(clientOperationId.length - 6).toUpperCase()
      : clientOperationId.toUpperCase();
  return 'MESH-$suffix';
}

/// Filtra alertas mínimas locales del colegio aún no sincronizadas en servidor.
List<MeshMinimalAlertPayload> filterUnsyncedSchoolMeshAlerts({
  required MeshRelayService? relay,
  required String? schoolCode,
  required List<StaffCaseSummary> remoteCases,
}) {
  final String? normalized = schoolCode?.trim().toUpperCase();
  if (relay == null || normalized == null || normalized.isEmpty) {
    return const <MeshMinimalAlertPayload>[];
  }
  final List<MeshMinimalAlertPayload> result = <MeshMinimalAlertPayload>[];
  for (final MeshMinimalAlertPayload alert in relay.schoolAlerts) {
    if (alert.involvesStaff) continue;
    if (alert.publicSchoolCode.trim().toUpperCase() != normalized) continue;
    if (relay.isOperationSynced(alert.clientOperationId)) continue;
    final bool alreadyInRemote = remoteCases.any(
      (StaffCaseSummary existing) =>
          existing.clientOperationId == alert.clientOperationId,
    );
    if (!alreadyInRemote) {
      result.add(alert);
    }
  }
  return result;
}

/// Diálogo informativo para una alerta mínima recibida por Bluetooth/mesh sin internet.
Future<void> showLocalMeshAlertDialog(
  BuildContext context, {
  required String referenceCode,
  required String kindLabel,
  required String detailMessage,
  Future<void> Function()? onSyncNow,
}) => showDialog<void>(
  context: context,
  builder: (BuildContext dialogContext) => AlertDialog(
    title: Text('$referenceCode · Recibido por mesh'),
    content: Text('$kindLabel\n\n$detailMessage'),
    actions: <Widget>[
      if (onSyncNow != null)
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await onSyncNow();
          },
          child: const Text('Sincronizar ahora'),
        ),
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Entendido'),
      ),
    ],
  ),
);

/// Carga una lista del servidor con espera, error y reintento visibles.
abstract class StaffInboxState<T extends StatefulWidget> extends State<T> {
  StaffSession get session;

  List<StaffCaseSummary>? cases;
  Map<String, String> schools = const <String, String>{};
  String? error;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final StaffBackend backend = session.backend;
      final String? institution = session.active?.institutionId;
      await beforeLoad();
      final List<StaffCaseSummary> found = await backend.cases(
        institutionId: institution,
      );
      final Map<String, String> names = await backend.institutionNames();
      await loadExtra();
      if (!mounted) return;
      setState(() {
        cases = found;
        schools = names;
      });
    } on Object catch (failure) {
      if (mounted) setState(() => error = staffErrorMessage(failure));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Datos adicionales de la bandeja; un fallo se informa como el resto.
  Future<void> loadExtra() async {}

  Future<void> beforeLoad() async {}

  String school(StaffCaseSummary item) =>
      schools[item.institutionId] ??
      session.active?.institutionName ??
      'Centro sin nombre disponible';

  /// Cuerpo común: error con reintento, espera, vacío o la lista.
  List<Widget> listBody({
    required List<StaffCaseSummary> visible,
    required String empty,
    required Widget Function(StaffCaseSummary item) tile,
  }) => <Widget>[
    if (error != null) ...<Widget>[
      StaffNotice(error!),
      TextButton(onPressed: load, child: const Text('Reintentar')),
    ] else if (cases == null)
      const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Cargando casos'),
        ),
      )
    else if (visible.isEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: StaffNotice(empty, error: false),
      )
    else
      for (final StaffCaseSummary item in visible)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: tile(item)),
  ];
}

/// Vista mínima de Supervisor MINED (`/personal/mined`): alertas del ámbito
/// y asignación manual. Nunca muestra relato, chat ni notas.
class MinedInboxScreen extends StatefulWidget {
  const MinedInboxScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<MinedInboxScreen> createState() => _MinedInboxScreenState();
}

class _MinedInboxScreenState extends StaffInboxState<MinedInboxScreen> {
  final OperationIds _operations = OperationIds();

  @override
  StaffSession get session => widget.session;

  Future<void> _assign(StaffCaseSummary item) async {
    final AssignableCounselor? chosen =
        await showModalBottomSheet<AssignableCounselor>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext sheet) => _CounselorSheet(
            session: session,
            item: item,
            school: school(item),
          ),
        );
    if (chosen == null || !mounted) return;
    String message = 'Caso ${item.referenceCode} asignado.';
    SetuAlertKind kind = SetuAlertKind.success;
    try {
      final String key = '${item.id}|${chosen.userId}';
      await session.backend.assignCounselor(
        operationId: _operations.idFor(key),
        caseId: item.id,
        counselorUserId: chosen.userId,
      );
      _operations.done();
    } on Object catch (failure) {
      message = staffErrorMessage(failure);
      kind = SetuAlertKind.error;
    }
    if (!mounted) return;
    showSetuBottomAlert(context, message, kind: kind);
    await load();
  }

  void _history(StaffCaseSummary item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheet) => _DispatchHistorySheet(
        session: session,
        item: item,
        school: school(item),
      ),
    );
  }

  Widget _tile(StaffCaseSummary item) {
    final bool assigned = item.assignedCounselorId != null;
    final String schoolName = school(item);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CureandoTheme.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA5C1EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              StaffSchoolLogo(schoolName: schoolName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        Text(
                          item.referenceCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        StaffTag(
                          assigned ? 'Asignada' : 'Sin asignar',
                          highlight: !assigned,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(schoolName, style: const TextStyle(fontSize: 16)),
                    Text(
                      staffCaseKind(
                        item.situationType,
                        item.studentRole,
                        origin: item.origin,
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      'Recibida: ${staffShortDate(item.receivedCentrallyAt)}',
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
          const SizedBox(height: 10),
          OutlinedButton(
            style: flowSecondaryStyle(),
            onPressed: item.status == SetuCaseStatus.closed
                ? null
                : () => _assign(item),
            child: Text(
              assigned ? 'Cambiar asignación' : 'Asignar a Mesa de Escucha',
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => _history(item),
            child: const Text('Historial de despacho'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StaffAreaScaffold(
    session: session,
    onRefresh: load,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: const Text('Alertas recibidas', style: _heading),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: CureandoTheme.ink,
                side: const BorderSide(color: CureandoTheme.blue, width: 1.5),
              ),
              onPressed: () => showMinedInvitesSheet(context, session),
              icon: const Icon(Icons.badge_outlined, color: CureandoTheme.blue),
              label: const Text('Invitaciones de personal'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: CureandoTheme.ink,
                side: const BorderSide(color: CureandoTheme.blue, width: 1.5),
              ),
              onPressed: () => showMinedCoverageSheet(context, session),
              icon: const Icon(Icons.hub_outlined, color: CureandoTheme.blue),
              label: const Text('Cobertura externa'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...listBody(
          visible: cases ?? const <StaffCaseSummary>[],
          empty: 'No hay alertas en tu ámbito.',
          tile: _tile,
        ),
      ],
    ),
  );
}

class _CounselorSheet extends StatefulWidget {
  const _CounselorSheet({
    required this.session,
    required this.item,
    required this.school,
  });

  final StaffSession session;
  final StaffCaseSummary item;
  final String school;

  @override
  State<_CounselorSheet> createState() => _CounselorSheetState();
}

class _CounselorSheetState extends State<_CounselorSheet> {
  late Future<List<AssignableCounselor>> _counselors = _load();

  Future<List<AssignableCounselor>> _load() => widget.session.backend
      .counselors(institutionId: widget.item.institutionId);

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
              'Asignar ${widget.item.referenceCode}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          Text('Profesionales activos de Mesa de Escucha · ${widget.school}'),
          const SizedBox(height: 12),
          FutureBuilder<List<AssignableCounselor>>(
            future: _counselors,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<AssignableCounselor>> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        StaffNotice(staffErrorMessage(snapshot.error!)),
                        TextButton(
                          onPressed: () =>
                              setState(() => _counselors = _load()),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }
                  final List<AssignableCounselor>? found = snapshot.data;
                  if (found == null) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Cargando profesionales',
                        ),
                      ),
                    );
                  }
                  if (found.isEmpty) {
                    return const StaffNotice(
                      'No hay profesionales activos para este centro.',
                      error: false,
                    );
                  }
                  return Column(
                    children: <Widget>[
                      for (final AssignableCounselor counselor in found)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          minVerticalPadding: 14,
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(counselor.email),
                          selected:
                              counselor.userId ==
                              widget.item.assignedCounselorId,
                          subtitle:
                              counselor.userId ==
                                  widget.item.assignedCounselorId
                              ? const Text('Asignación actual')
                              : null,
                          onTap: () => Navigator.of(context).pop(counselor),
                        ),
                    ],
                  );
                },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}

/// Historial de despacho de un caso para MINED: a quién se ofreció, por qué
/// nivel, qué respondió cada persona y quién la atiende. Sin relato ni chat.
class _DispatchHistorySheet extends StatefulWidget {
  const _DispatchHistorySheet({
    required this.session,
    required this.item,
    required this.school,
  });

  final StaffSession session;
  final StaffCaseSummary item;
  final String school;

  @override
  State<_DispatchHistorySheet> createState() => _DispatchHistorySheetState();
}

class _DispatchHistorySheetState extends State<_DispatchHistorySheet> {
  late Future<List<CaseDispatchRecord>> _records = _load();

  Future<List<CaseDispatchRecord>> _load() =>
      widget.session.backend.dispatchHistory(
        institutionId: widget.item.institutionId,
        caseId: widget.item.id,
      );

  Widget _entry(CaseDispatchRecord record) {
    final DateTime? responded = record.respondedAt;
    final String? reason = record.declineReason;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CureandoTheme.blueSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            record.counselorEmail ?? 'Profesional de Mesa de Escucha',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              StaffTag(dispatchTierLabel(record.dispatchTier)),
              StaffTag(
                record.dispatchStatus.label,
                highlight: record.dispatchStatus == CaseDispatchStatus.pending,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Avisada: ${staffShortDate(record.notifiedAt)}'
            '${responded == null ? '' : '\nRespondió: ${staffShortDate(responded)}'}',
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: CureandoTheme.secondaryInk,
            ),
          ),
          if (reason != null && reason.isNotEmpty)
            Text(
              'Motivo de declinación: $reason',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
        ],
      ),
    );
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
              'Despacho de ${widget.item.referenceCode}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.school),
          const SizedBox(height: 12),
          FutureBuilder<List<CaseDispatchRecord>>(
            future: _records,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<CaseDispatchRecord>> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        StaffNotice(staffErrorMessage(snapshot.error!)),
                        TextButton(
                          onPressed: () => setState(() => _records = _load()),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }
                  final List<CaseDispatchRecord>? found = snapshot.data;
                  if (found == null) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Cargando historial',
                        ),
                      ),
                    );
                  }
                  if (found.isEmpty) {
                    return const StaffNotice(
                      'Esta alerta todavía no se ofreció a nadie de Mesa de '
                      'Escucha.',
                      error: false,
                    );
                  }
                  final CaseDispatchRecord? attending = found
                      .where(
                        (CaseDispatchRecord record) =>
                            record.dispatchStatus == CaseDispatchStatus.claimed,
                      )
                      .firstOrNull;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      StaffNotice(
                        attending == null
                            ? 'Todavía nadie tomó esta alerta.'
                            : 'La atiende: '
                                  '${attending.counselorEmail ?? 'una persona de Mesa de Escucha'}',
                        error: false,
                      ),
                      const SizedBox(height: 12),
                      for (final CaseDispatchRecord record in found)
                        _entry(record),
                    ],
                  );
                },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}

/// Hoja inferior para declinar una alerta despachada con motivo opcional.
class _DeclineSheet extends StatefulWidget {
  const _DeclineSheet({required this.reference, required this.school});

  final String reference;
  final String school;

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              '¿Declinar esta alerta?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CureandoTheme.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                StaffSchoolLogo(
                  schoolName: widget.school,
                  size: 28,
                  borderRadius: 8,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${widget.school} · ${widget.reference}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'La alerta seguirá disponible para otras personas autorizadas.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: CureandoTheme.secondaryInk,
            ),
          ),
          const SizedBox(height: 14),
          StaffField(
            label: 'Motivo (opcional)',
            controller: _reason,
            hint: 'Ej. Estoy atendiendo otra conversación',
            maxLines: 3,
            maxLength: 500,
            capitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: flowPrimaryStyle(),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: flowSecondaryStyle(),
            onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
            child: const Text('Confirmar declinación'),
          ),
        ],
      ),
    ),
  );
}

/// Aviso dentro de la app: «Tenés una alerta asignada». No lleva datos del
/// caso; al tocarlo se vuelve a verificar la sesión antes de abrir la bandeja.
class AssignmentBanner extends StatelessWidget {
  const AssignmentBanner({super.key, required this.session, this.onOpened});

  final StaffSession session;
  final VoidCallback? onOpened;

  Future<void> _open(BuildContext context) async {
    final String? error = await session.refresh();
    if (!context.mounted) return;
    if (error != null) {
      showSetuBottomAlert(context, error, kind: SetuAlertKind.error);
      return;
    }
    session.clearAssignment();
    // Si el rol ya no corresponde, la guía de rutas lleva a otro lugar.
    context.go('/personal/mesa');
    onOpened?.call();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (BuildContext context, _) => !session.assignmentPending
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              liveRegion: true,
              button: true,
              child: Material(
                color: const Color(0xFFDDEAFB),
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 30,
                          color: CureandoTheme.ink,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            SetuAssignmentNotice.defaultHeadline,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
  );
}

enum _DeskFilter {
  review('Por revisar', 'No tenés casos pendientes de valoración.'),
  talking('En conversación', 'No tenés conversaciones activas.');

  const _DeskFilter(this.label, this.empty);
  final String label;
  final String empty;
}

/// Bandeja de Mesa de Escucha (`/personal/mesa`): «Mis casos».
class DeskInboxScreen extends StatefulWidget {
  const DeskInboxScreen({super.key, required this.session, this.meshRelay});

  final StaffSession session;
  final MeshRelayService? meshRelay;

  @override
  State<DeskInboxScreen> createState() => _DeskInboxScreenState();
}

enum _DeskTab { toClaim, myCases }

class _DeskInboxScreenState extends StaffInboxState<DeskInboxScreen> {
  _DeskTab _tab = _DeskTab.myCases;
  bool _tabChosenByUser = false;
  _DeskFilter _filter = _DeskFilter.review;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedInstitutionId;
  bool _oldestFirst = true;
  final OperationIds _operations = OperationIds();
  List<CaseDispatchRecord> _pending = const <CaseDispatchRecord>[];
  List<PracticanteSupervisorNoticeView> _supervisorNotices =
      const <PracticanteSupervisorNoticeView>[];
  StreamSubscription<CaseDispatchRecord>? _live;
  String? _busyCase;
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
    unawaited(_ensureDeskMesh());
    // La bandeja se actualiza sola cuando llega, se toma o se retira una
    // alerta despachada a esta persona.
    _live = session.backend.incomingDispatches().listen((_) {
      if (mounted) load();
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    widget.meshRelay?.removeListener(_onMeshChanged);
    _searchController.dispose();
    _live?.cancel();
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

  Future<void> _ensureDeskMesh() async {
    final MeshRelayService? relay = widget.meshRelay;
    if (relay == null) return;
    final String? schoolCode = session.active?.institutionPublicCode?.trim();
    final bool hasSchool = schoolCode != null && schoolCode.isNotEmpty;
    try {
      const String endpoint = 'setu-node';
      if (relay.recipientDirectory != null) {
        await relay.prepareSchoolReceiver(hasSchool ? schoolCode : null);
      }
      final bool started = await relay.ensureReadyAndStart(
        endpointName: endpoint,
      );
      if (!mounted) return;
      if (!started) {
        setState(() {
          _bluetoothRequired = true;
          _meshActive = false;
        });
        return;
      }
      if (hasSchool && relay.recipientDirectory == null) {
        final SimpleKeyPair schoolKey = await MeshSchoolKeys.demoSchoolKeyPair(
          schoolCode,
        );
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

  List<MeshMinimalAlertPayload> _localMeshAlerts() =>
      filterUnsyncedSchoolMeshAlerts(
        relay: widget.meshRelay,
        schoolCode: session.active?.institutionPublicCode,
        remoteCases: cases ?? const <StaffCaseSummary>[],
      );

  @override
  Future<void> beforeLoad() async {
    await widget.meshRelay?.syncPendingAsBridge();
  }

  @override
  Future<void> loadExtra() async {
    final StaffBackend backend = session.backend;
    final String? me = backend.currentUserId;
    final List<CaseDispatchRecord> mine = await backend.dispatchHistory(
      institutionId: session.active?.institutionId,
    );
    _pending = <CaseDispatchRecord>[
      for (final CaseDispatchRecord record in mine)
        if (record.dispatchStatus == CaseDispatchStatus.pending &&
            record.counselorUserId == me)
          record,
    ];
    _supervisorNotices = await backend.supervisorNotices();
    if (!_tabChosenByUser) {
      _tabChosenByUser = true;
      _tab = (_pending.isNotEmpty || _localMeshAlerts().isNotEmpty)
          ? _DeskTab.toClaim
          : _DeskTab.myCases;
    }
    if (_selectedInstitutionId != null &&
        !_pending.any(
          (CaseDispatchRecord r) => r.institutionId == _selectedInstitutionId,
        )) {
      _selectedInstitutionId = null;
    }
  }

  void _say(String message, {SetuAlertKind kind = SetuAlertKind.info}) {
    if (!mounted) return;
    showSetuBottomAlert(context, message, kind: kind);
  }

  Future<void> _claim(CaseDispatchRecord record) async {
    if (_busyCase != null) return;
    final String reference = record.referenceCode ?? 'la alerta';
    setState(() => _busyCase = record.caseId);
    String message;
    SetuAlertKind kind = SetuAlertKind.info;
    try {
      final CaseClaimResult result = await session.backend.claimCase(
        operationId: _operations.idFor('claim|${record.caseId}'),
        caseId: record.caseId,
      );
      _operations.done();
      if (result.isAlreadyTaken) {
        message =
            'Otra persona de Mesa de Escucha tomó $reference antes. Ya no está disponible.';
        kind = SetuAlertKind.warning;
      } else if (result.claimed || result.alreadyAssignedToYou) {
        message = 'Tomaste $reference. Ya está en «Mis casos».';
        kind = SetuAlertKind.success;
      } else {
        message =
            'No pudimos tomar $reference. Actualizá la bandeja e intentá de nuevo.';
        kind = SetuAlertKind.warning;
      }
    } on Object catch (failure) {
      message = staffErrorMessage(failure);
      kind = SetuAlertKind.error;
    }
    if (!mounted) return;
    setState(() => _busyCase = null);
    _say(message, kind: kind);
    await load();
  }

  Future<void> _recoverAndReload(String caseId) async {
    try {
      final CaseDispatchRecoverResult res = await session.backend
          .recoverDeclinedDispatch(caseId);
      if (!mounted) return;
      if (res.ok) {
        _say(
          'La alerta volvió a tu bandeja «Por tomar».',
          kind: SetuAlertKind.success,
        );
      } else {
        _say(
          res.availabilityState?.label ??
              'Ya no pudimos recuperar esta alerta.',
          kind: SetuAlertKind.warning,
        );
      }
      await load();
    } on Object catch (failure) {
      if (mounted) _say(staffErrorMessage(failure), kind: SetuAlertKind.error);
    }
  }

  Future<void> _decline(CaseDispatchRecord record) async {
    if (_busyCase != null) return;
    final String reference = record.referenceCode ?? 'la alerta';
    final String schoolLabel =
        record.institutionName ??
        schools[record.institutionId] ??
        'Centro escolar';
    final String? reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheet) =>
          _DeclineSheet(reference: reference, school: schoolLabel),
    );
    if (reason == null || !mounted) return;
    setState(() => _busyCase = record.caseId);
    bool declined = false;
    String? errorMessage;
    try {
      await session.backend.declineDispatch(
        operationId: _operations.idFor('decline|${record.caseId}|$reason'),
        caseId: record.caseId,
        reason: reason.isEmpty ? null : reason,
      );
      _operations.done();
      declined = true;
    } on Object catch (failure) {
      errorMessage = staffErrorMessage(failure);
    }
    if (!mounted) return;
    setState(() => _busyCase = null);
    await load();
    if (!mounted) return;
    if (!declined) {
      _say(
        errorMessage ?? 'No pudimos declinar la alerta.',
        kind: SetuAlertKind.error,
      );
      return;
    }
    showSetuBottomAlert(
      context,
      'Alerta declinada',
      kind: SetuAlertKind.info,
      actionLabel: 'Deshacer',
      onAction: () => _recoverAndReload(record.caseId),
    );
  }

  List<CaseDispatchRecord> _filteredPending() {
    final String q = _searchQuery.trim().toLowerCase();
    final List<CaseDispatchRecord> items = <CaseDispatchRecord>[
      for (final CaseDispatchRecord r in _pending)
        if ((_selectedInstitutionId == null ||
                r.institutionId == _selectedInstitutionId) &&
            (q.isEmpty ||
                (r.referenceCode ?? '').toLowerCase().contains(q) ||
                (r.institutionName ?? schools[r.institutionId] ?? '')
                    .toLowerCase()
                    .contains(q)))
          r,
    ];
    items.sort((CaseDispatchRecord a, CaseDispatchRecord b) {
      final int cmp = a.notifiedAt.compareTo(b.notifiedAt);
      return _oldestFirst ? cmp : -cmp;
    });
    return items;
  }

  String _hhmm(DateTime value) {
    final DateTime local = value.toLocal();
    final String h = local.hour.toString().padLeft(2, '0');
    final String m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static const BoxDecoration _alertCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(18)),
    border: Border.fromBorderSide(BorderSide(color: Color(0xFFDBE6F5))),
    boxShadow: <BoxShadow>[
      BoxShadow(color: Color(0x0D0A2E5C), blurRadius: 10, offset: Offset(0, 4)),
    ],
  );

  Widget _meshDispatchTile(MeshMinimalAlertPayload alert) {
    final String schoolName =
        session.active?.institutionName ?? 'Centro escolar';
    final String ref = meshReferenceCode(alert.clientOperationId);
    final String kind = staffCaseKind(
      SetuSituationType.fromWire(alert.situationType),
      SetuStudentCaseRole.fromWire(alert.studentRole),
      origin: SetuAlertOrigin.mesh,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _alertCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              StaffSchoolLogo(schoolName: schoolName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            schoolName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CureandoTheme.ink,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: CureandoTheme.secondaryInk,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _hhmm(alert.declaredAt),
                          style: const TextStyle(
                            fontSize: 13,
                            color: CureandoTheme.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$kind · $ref',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CureandoTheme.secondaryInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const StaffTag('Red mesh · Sin internet', highlight: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: flowSecondaryStyle(),
            onPressed: () => showLocalMeshAlertDialog(
              context,
              referenceCode: ref,
              kindLabel: kind,
              detailMessage:
                  'Esta alerta mínima llegó por Bluetooth/mesh sin internet. '
                  'Cuando este teléfono o un puente recupere conexión, se '
                  'subirá automáticamente para habilitar la toma del caso y el chat.',
              onSyncNow: widget.meshRelay?.remoteGateway == null
                  ? null
                  : () async {
                      final int synced =
                          await widget.meshRelay?.syncPendingAsBridge() ?? 0;
                      if (!mounted) return;
                      if (synced > 0) {
                        _say(
                          'Alerta sincronizada con la plataforma.',
                          kind: SetuAlertKind.success,
                        );
                        await load();
                      } else {
                        _say(
                          'Todavía no pudimos sincronizar. Revisá tu conexión e intentá de nuevo.',
                          kind: SetuAlertKind.warning,
                        );
                      }
                    },
            ),
            icon: const Icon(Icons.bluetooth_connected_rounded, size: 18),
            label: const Text('Ver aviso local'),
          ),
        ],
      ),
    );
  }

  Widget _dispatchTile(CaseDispatchRecord record) {
    final bool busy = _busyCase == record.caseId;
    final SetuSituationType? type = record.situationType;
    final String schoolName =
        record.institutionName ??
        schools[record.institutionId] ??
        'Centro sin nombre disponible';
    final String tierText = record.dispatchTier == CaseDispatchTier.externalPool
        ? 'Red externa'
        : 'Equipo de planta';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _alertCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              StaffSchoolLogo(schoolName: schoolName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            schoolName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CureandoTheme.ink,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: CureandoTheme.secondaryInk,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _hhmm(record.notifiedAt),
                          style: const TextStyle(
                            fontSize: 13,
                            color: CureandoTheme.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${type == null ? 'Alerta' : staffCaseKind(type, SetuStudentCaseRole.victim).split(' · ').first} · ${record.referenceCode ?? 'Alerta'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CureandoTheme.secondaryInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StaffTag(tierText),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: FilledButton(
                  style: flowPrimaryStyle().copyWith(
                    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    textStyle: const WidgetStatePropertyAll<TextStyle>(
                      TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onPressed: _busyCase == null ? () => _claim(record) : null,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                'Tomar alerta',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: flowSecondaryStyle().copyWith(
                    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    ),
                    textStyle: const WidgetStatePropertyAll<TextStyle>(
                      TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onPressed: _busyCase == null ? () => _decline(record) : null,
                  child: const Text(
                    'Declinar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _matches(StaffCaseSummary item) {
    // Solo los casos que esta persona atiende: una alerta ofrecida que
    // todavía no tomó aparece en «Por tomar», no en «Mis casos».
    if (item.assignedCounselorId != session.backend.currentUserId) {
      return false;
    }
    if (item.status == SetuCaseStatus.closed) return false;
    return switch (_filter) {
      _DeskFilter.review => item.isUnassessed,
      _DeskFilter.talking => item.isInConversation,
    };
  }

  Future<void> _openCase(StaffCaseSummary item) async {
    await context.push('/personal/mesa/caso/${item.id}');
    if (mounted) await load();
  }

  Future<void> _openDeclined() async {
    await context.push('/personal/mesa/declinadas');
    if (mounted) await load();
  }

  Widget _tile(StaffCaseSummary item) {
    final String schoolName = school(item);
    final String kind = staffCaseKind(
      item.situationType,
      item.studentRole,
      origin: item.origin,
    );
    return DecoratedBox(
      decoration: _alertCardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openCase(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    StaffSchoolLogo(schoolName: schoolName, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  schoolName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: CureandoTheme.ink,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.schedule_rounded,
                                size: 15,
                                color: CureandoTheme.secondaryInk,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hhmm(item.receivedCentrallyAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CureandoTheme.secondaryInk,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Text(
                                '$kind ·',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CureandoTheme.secondaryInk,
                                ),
                              ),
                              Text(
                                item.referenceCode,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CureandoTheme.secondaryInk,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              StaffTag(
                                staffLevelLabel(item.humanLevel),
                                highlight: item.isUnassessed,
                              ),
                              if (item.isInConversation)
                                const StaffTag('Chat habilitado'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: flowPrimaryStyle().copyWith(
                    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    textStyle: const WidgetStatePropertyAll<TextStyle>(
                      TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onPressed: () => _openCase(item),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'Abrir caso',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentedTabs() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFDBE6F5)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _tabPill(
            label: 'Por tomar',
            selected: _tab == _DeskTab.toClaim,
            onTap: () => setState(() {
              _tabChosenByUser = true;
              _tab = _DeskTab.toClaim;
            }),
          ),
        ),
        Expanded(
          child: _tabPill(
            label: 'Mis casos',
            selected: _tab == _DeskTab.myCases,
            onTap: () => setState(() {
              _tabChosenByUser = true;
              _tab = _DeskTab.myCases;
            }),
          ),
        ),
      ],
    ),
  );

  Widget _tabPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? CureandoTheme.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : CureandoTheme.ink,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<CaseDispatchRecord> filteredPending = _filteredPending();
    final List<MeshMinimalAlertPayload> localMeshAlerts = _localMeshAlerts();
    final int totalToClaim = _pending.length + localMeshAlerts.length;
    final Map<String, String> pendingSchools = <String, String>{
      for (final CaseDispatchRecord r in _pending)
        r.institutionId:
            r.institutionName ?? schools[r.institutionId] ?? r.institutionId,
    };

    return StaffAreaScaffold(
      session: session,
      onRefresh: load,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AssignmentBanner(session: session, onOpened: load),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: const Text('Mesa de escucha', style: _heading),
              ),
              Text(
                '$totalToClaim ${totalToClaim == 1 ? 'alerta' : 'alertas'} por tomar',
                style: const TextStyle(
                  fontSize: 15,
                  color: CureandoTheme.secondaryInk,
                ),
              ),
            ],
          ),
          StaffMeshStatusBanner(
            bluetoothRequired: _bluetoothRequired,
            meshActive: _meshActive,
            onEnableBluetooth: _ensureDeskMesh,
            description:
                'Activá el Bluetooth y permisos cercanos para recibir alertas '
                'de estudiantes sin internet.',
          ),
          if (_supervisorNotices.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CureandoTheme.yellowSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5C100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Aviso de supervisión a tu cargo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  for (final PracticanteSupervisorNoticeView notice
                      in _supervisorNotices.take(3))
                    Text(
                      '• ${notice.institutionName} (${notice.referenceCode}): cierre propuesto por ${notice.practicanteName ?? 'practicante'} · Nivel ${notice.humanLevel}',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _segmentedTabs(),
          const SizedBox(height: 14),
          if (_tab == _DeskTab.toClaim) ...<Widget>[
            TextField(
              controller: _searchController,
              onChanged: (String v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscá por colegio o referencia',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 160,
                    maxWidth: 240,
                  ),
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedInstitutionId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Todos los colegios',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      for (final MapEntry<String, String> entry
                          in pendingSchools.entries)
                        DropdownMenuItem<String?>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (String? value) =>
                        setState(() => _selectedInstitutionId = value),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _oldestFirst = !_oldestFirst),
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: Text(
                    _oldestFirst
                        ? 'Más antiguas primero'
                        : 'Más recientes primero',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredPending.isEmpty && localMeshAlerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No tenés alertas pendientes por tomar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: CureandoTheme.secondaryInk,
                  ),
                ),
              )
            else ...<Widget>[
              for (final MeshMinimalAlertPayload alert in localMeshAlerts)
                _meshDispatchTile(alert),
              for (final CaseDispatchRecord record in filteredPending)
                _dispatchTile(record),
            ],
            Center(
              child: TextButton(
                onPressed: _openDeclined,
                child: const Text(
                  'Declinadas recientes',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ] else ...<Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                for (final _DeskFilter filter in _DeskFilter.values)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    showCheckmark: true,
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _filter == filter
                          ? Colors.white
                          : CureandoTheme.ink,
                    ),
                    checkmarkColor: Colors.white,
                    selectedColor: CureandoTheme.blue,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: const StadiumBorder(
                      side: BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...listBody(
              visible: (cases ?? const <StaffCaseSummary>[])
                  .where(_matches)
                  .toList(),
              empty: _filter.empty,
              tile: _tile,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pantalla de alertas declinadas recientes (`/personal/mesa/declinadas`).
class DeskDeclinedScreen extends StatefulWidget {
  const DeskDeclinedScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<DeskDeclinedScreen> createState() => _DeskDeclinedScreenState();
}

class _DeskDeclinedScreenState extends State<DeskDeclinedScreen> {
  List<DeclinedDispatchRecord>? _records;
  Map<String, String> _schools = const <String, String>{};
  bool _loading = true;
  String? _error;
  String? _busyCaseId;

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
      final CounselorDispatchCasesResult result = await widget.session.backend
          .counselorDispatches();
      final Map<String, String> schools = await widget.session.backend
          .institutionNames();
      if (!mounted) return;
      setState(() {
        _records = result.declinedDispatches;
        _schools = schools;
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

  Future<void> _recover(DeclinedDispatchRecord record) async {
    setState(() => _busyCaseId = record.caseId);
    try {
      final CaseDispatchRecoverResult res = await widget.session.backend
          .recoverDeclinedDispatch(record.caseId);
      if (!mounted) return;
      setState(() => _busyCaseId = null);
      if (res.ok) {
        showSetuBottomAlert(
          context,
          'Alerta devuelta a tu bandeja «Por tomar».',
          kind: SetuAlertKind.success,
        );
        context.pop();
        return;
      }
      showSetuBottomAlert(
        context,
        res.availabilityState?.label ?? 'La alerta ya no está disponible.',
        kind: SetuAlertKind.warning,
      );
      await _load();
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() => _busyCaseId = null);
      showSetuBottomAlert(
        context,
        staffErrorMessage(failure),
        kind: SetuAlertKind.error,
      );
    }
  }

  Widget _recordTile(DeclinedDispatchRecord record) {
    final String schoolName =
        record.institutionName ??
        _schools[record.institutionId] ??
        'Centro escolar';
    final bool available =
        record.availabilityState == DeclinedDispatchAvailability.available &&
        record.canRecover;
    final Color badgeBg = available
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF1F5F9);
    final Color badgeFg = available
        ? const Color(0xFF166534)
        : CureandoTheme.secondaryInk;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              StaffSchoolLogo(schoolName: schoolName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      schoolName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      record.referenceCode ?? record.caseId,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CureandoTheme.secondaryInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        record.availabilityState.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (available) ...<Widget>[
            const SizedBox(height: 12),
            FilledButton(
              style: flowPrimaryStyle().copyWith(
                padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              onPressed: _busyCaseId == record.caseId
                  ? null
                  : () => _recover(record),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'Volver a la bandeja',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DeclinedDispatchRecord> records =
        _records ?? const <DeclinedDispatchRecord>[];
    return FlowScaffold(
      onRefresh: _load,
      header: const FlowHeader(title: 'Declinadas recientes'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Podés recuperar las alertas que sigan disponibles.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ] else if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando declinadas',
                ),
              ),
            )
          else if (records.isEmpty)
            const StaffNotice(
              'No tenés alertas declinadas recientes.',
              error: false,
            )
          else
            for (final DeclinedDispatchRecord r in records) _recordTile(r),
        ],
      ),
    );
  }
}
