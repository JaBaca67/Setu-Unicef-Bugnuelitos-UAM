import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
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
  const DirectorInboxScreen({super.key, required this.session});

  final StaffSession session;

  @override
  State<DirectorInboxScreen> createState() => _DirectorInboxScreenState();
}

class _DirectorInboxScreenState extends StaffInboxState<DirectorInboxScreen> {
  Set<String> _withSheet = const <String>{};

  @override
  StaffSession get session => widget.session;

  @override
  Future<void> loadExtra() async {
    final List<CaseActionSheetView> sheets = await session.backend.sheets();
    _withSheet = <String>{
      for (final CaseActionSheetView sheet in sheets) sheet.caseId,
    };
  }

  Future<void> _open(StaffCaseSummary item) async {
    await context.push('/personal/direccion/caso/${item.id}');
    if (mounted) await load();
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
              tooltip: 'Actualizar',
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        Text(session.active?.place ?? '', style: _text),
        const SizedBox(height: 6),
        const Text(
          'Ves el aviso mínimo y las fichas autorizadas para tu centro. El '
          'relato y la conversación del estudiante no llegan a la dirección.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 16),
        ...listBody(
          visible: cases ?? const <StaffCaseSummary>[],
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
