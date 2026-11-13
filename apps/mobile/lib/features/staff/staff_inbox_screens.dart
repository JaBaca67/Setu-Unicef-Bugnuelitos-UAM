import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import 'staff_backend.dart';
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
String staffCaseKind(SetuSituationType type, SetuStudentCaseRole role) {
  final String situation = switch (type) {
    SetuSituationType.physicalBullying => 'Acoso físico',
    SetuSituationType.verbalBullying => 'Acoso verbal',
    SetuSituationType.socialBullying => 'Acoso social',
    SetuSituationType.cyberbullying => 'Ciberacoso',
    SetuSituationType.sexualViolence => 'Violencia sexual',
    SetuSituationType.needToTalk => 'Necesito hablar',
  };
  final String part = switch (role) {
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

/// Carga una lista del servidor con espera, error y reintento visibles.
abstract class _InboxState<T extends StatefulWidget> extends State<T> {
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
      final List<StaffCaseSummary> found = await backend.cases(
        institutionId: institution,
      );
      final Map<String, String> names = await backend.institutionNames();
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

class _MinedInboxScreenState extends _InboxState<MinedInboxScreen> {
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
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await load();
  }

  Widget _tile(StaffCaseSummary item) {
    final bool assigned = item.assignedCounselorId != null;
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
          const SizedBox(height: 6),
          Text(school(item), style: const TextStyle(fontSize: 16)),
          Text(
            staffCaseKind(item.situationType, item.studentRole),
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Recibida: ${staffShortDate(item.receivedCentrallyAt)}',
            style: const TextStyle(
              fontSize: 15,
              color: CureandoTheme.secondaryInk,
            ),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StaffAreaScaffold(
    session: session,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: const Text('Alertas recibidas', style: _heading),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Ves datos mínimos de cada alerta. El relato y la conversación son '
          'solo de la persona de Mesa de Escucha asignada.',
          style: TextStyle(fontSize: 15, height: 1.4),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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
  const DeskInboxScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<DeskInboxScreen> createState() => _DeskInboxScreenState();
}

class _DeskInboxScreenState extends _InboxState<DeskInboxScreen> {
  _DeskFilter _filter = _DeskFilter.review;

  @override
  StaffSession get session => widget.session;

  bool _matches(StaffCaseSummary item) {
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

  Widget _tile(StaffCaseSummary item) => Material(
    color: CureandoTheme.blueSoft,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: CureandoTheme.blue, width: 1.5),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _openCase(item),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: <Widget>[
                      Text(
                        item.referenceCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        staffShortDate(item.receivedCentrallyAt),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: <Widget>[
                      Text(school(item), style: const TextStyle(fontSize: 16)),
                      StaffTag(
                        staffLevelLabel(item.humanLevel),
                        highlight: item.isUnassessed,
                      ),
                    ],
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
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AssignmentBanner(session: session, onOpened: load),
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: const Text('Mis casos', style: _heading),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                  color: _filter == filter ? Colors.white : CureandoTheme.ink,
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
    ),
  );
}
