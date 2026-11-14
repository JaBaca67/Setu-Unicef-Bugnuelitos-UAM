import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../piece/student_piece.dart';
import 'staff_backend.dart';
import 'staff_inbox_screens.dart';
import 'staff_widgets.dart';

const TextStyle _section = TextStyle(
  fontSize: 22,
  height: 1.2,
  fontWeight: FontWeight.w700,
  color: CureandoTheme.ink,
);
const TextStyle _text = TextStyle(fontSize: 16, height: 1.4);
const Color _blueTint = Color(0xFFDDEAFB);

/// Caso asignado a la sesión, o null si el servidor no lo autoriza.
Future<StaffCaseSummary?> _findCase(StaffSession session, String id) async =>
    (await session.backend.cases())
        .where((StaffCaseSummary item) => item.id == id)
        .firstOrNull;

StudentPiece? _pieceOf(StaffCaseSummary? item) {
  final StudentPieceSnapshot? snapshot = item?.studentPiece;
  return snapshot == null
      ? null
      : StudentPiece.tryParse(
          shape: snapshot.shape,
          color: snapshot.color,
          accessories: snapshot.accessories,
          displayName: snapshot.displayName,
        );
}

/// Detalle del caso en Mesa de Escucha (`/personal/mesa/caso/:id`): pieza,
/// folio, tipo, relato opcional, chat y valoración humana.
class DeskCaseScreen extends StatefulWidget {
  const DeskCaseScreen({
    super.key,
    required this.session,
    required this.caseId,
  });

  final StaffSession session;
  final String caseId;

  @override
  State<DeskCaseScreen> createState() => _DeskCaseScreenState();
}

class _DeskCaseScreenState extends State<DeskCaseScreen> {
  final OperationIds _operations = OperationIds();
  final TextEditingController _guidance = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  StaffCaseSummary? _case;
  CaseNarrativeView? _narrative;
  Map<String, String> _schools = const <String, String>{};
  bool _loaded = false;
  bool _busy = false;
  String? _loadError;
  String? _formError;
  bool _saved = false;

  int? _level;
  bool _urgent = false;
  bool _sheet = false;
  bool _omitSchool = false;
  bool _close = false;

  StaffBackend get _backend => widget.session.backend;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _guidance.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final StaffCaseSummary? found = await _findCase(
        widget.session,
        widget.caseId,
      );
      final CaseNarrativeView? narrative = found == null
          ? null
          : await _backend.narrative(found.id);
      final Map<String, String> schools = await _backend.institutionNames();
      if (!mounted) return;
      setState(() {
        _case = found;
        _narrative = narrative;
        _schools = schools;
        _loaded = true;
        _level ??= found?.humanLevel;
      });
    } on Object catch (failure) {
      if (mounted) setState(() => _loadError = staffErrorMessage(failure));
    }
  }

  void _pick(int level) => setState(() {
    _level = level;
    _formError = null;
    _saved = false;
    if (level == 1) _sheet = false;
    if (level != 1) _close = false;
    if (level != 3) _urgent = false;
  });

  void _openChat() => context.push('/personal/mesa/caso/${widget.caseId}/chat');

  Future<void> _enableChat() async {
    setState(() => _busy = true);
    String? error;
    try {
      await _backend.enableChat(
        operationId: _operations.idFor('chat|${widget.caseId}'),
        caseId: widget.caseId,
      );
      _operations.done();
      await _load();
    } on Object catch (failure) {
      error = staffErrorMessage(failure);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = error;
      _saved = false;
    });
    if (error == null && (_case?.chatAvailableNotice ?? false)) _openChat();
  }

  Future<void> _save() async {
    final StaffCaseSummary? item = _case;
    final int? level = _level;
    if (item == null || level == null) return;
    if (_sheet && _guidance.text.trim().isEmpty) {
      setState(() => _formError = 'Escribí la orientación para el centro.');
      return;
    }
    if (_close && _reason.text.trim().isEmpty) {
      setState(() => _formError = 'Escribí el motivo del cierre.');
      return;
    }
    final CaseAssessment assessment = CaseAssessment(
      caseId: item.id,
      level: level,
      urgentReferral: _urgent,
      issueSheet: _sheet,
      guidanceNotes: _sheet ? _guidance.text.trim() : '',
      omitSchool: _sheet && _omitSchool,
      closeCase: _close,
      closedReason: _close ? _reason.text.trim() : '',
    );
    final bool confirmed =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext sheet) =>
              _ReviewSheet(item: item, assessment: assessment),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _formError = null;
    });
    String? error;
    try {
      await _backend.assess(
        operationId: _operations.idFor(assessment.fingerprint),
        assessment: assessment,
      );
      _operations.done();
      _sheet = _urgent = _close = _omitSchool = false;
      _guidance.clear();
      _reason.clear();
      await _load();
    } on Object catch (failure) {
      error = staffErrorMessage(failure);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = error;
      _saved = error == null;
    });
  }

  List<Widget> _assessment(StaffCaseSummary item) => <Widget>[
    Semantics(
      header: true,
      child: const Text('Valoración profesional', style: _section),
    ),
    const SizedBox(height: 4),
    const Text(
      'La decidís vos, durante o después de conversar. La app no clasifica.',
      style: TextStyle(fontSize: 15, color: CureandoTheme.secondaryInk),
    ),
    const SizedBox(height: 10),
    RadioGroup<int>(
      groupValue: _level,
      onChanged: (int? value) {
        if (value != null) _pick(value);
      },
      child: Column(
        children: <Widget>[
          for (final MapEntry<int, String> level in humanLevelLabels.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _level == level.key
                        ? CureandoTheme.blue
                        : const Color(0xFFCBD5E1),
                    width: _level == level.key ? 2 : 1.5,
                  ),
                ),
                child: RadioListTile<int>(
                  value: level.key,
                  title: Text(
                    '${level.key} · ${level.value}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    if (_level == 3)
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _urgent || item.urgentReferralTriggered,
        onChanged: item.urgentReferralTriggered
            ? null
            : (bool value) => setState(() => _urgent = value),
        title: const Text('Registrar derivación urgente'),
        subtitle: Text(
          item.urgentReferralTriggered
              ? 'Ya quedó registrada para este caso.'
              : 'Es una acción aparte de la valoración. Deja constancia de '
                    'que derivaste sin esperar los pasos del centro.',
        ),
      ),
    if (_level == 2 || _level == 3) ...<Widget>[
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _sheet,
        onChanged: (bool value) => setState(() => _sheet = value),
        title: const Text('Enviar ficha mínima'),
        subtitle: const Text(
          'Lleva tipo, participación, nivel y tu orientación. No incluye el '
          'relato, los mensajes ni las notas internas.',
        ),
      ),
      if (_sheet) ...<Widget>[
        const SizedBox(height: 8),
        StaffField(
          label: 'Orientación para el centro',
          controller: _guidance,
          hint: 'Qué se espera que haga el centro',
          maxLines: 4,
          maxLength: 1500,
          capitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _omitSchool,
          onChanged: (bool? value) =>
              setState(() => _omitSchool = value ?? false),
          title: const Text('No enviar a la dirección del centro'),
          subtitle: const Text(
            'Usalo si hay conflicto de interés. La ficha queda solo en la '
            'supervisión del MINED.',
          ),
        ),
      ],
    ],
    if (_level == 1) ...<Widget>[
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _close,
        onChanged: (bool value) => setState(() => _close = value),
        title: const Text('Cerrar el caso en Mesa de Escucha'),
        subtitle: const Text(
          'Solo para acompañamientos que ya concluyeron. Queda registrado '
          'el motivo.',
        ),
      ),
      if (_close) ...<Widget>[
        const SizedBox(height: 8),
        StaffField(
          label: 'Motivo del cierre',
          controller: _reason,
          hint:
              'Explicá brevemente cómo se acompañó y por qué se cierra el caso',
          maxLines: 3,
          maxLength: 500,
          capitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
        ),
      ],
    ],
    if (_formError != null) ...<Widget>[
      const SizedBox(height: 8),
      StaffNotice(_formError!),
    ],
    const SizedBox(height: 12),
    OutlinedButton(
      style: flowSecondaryStyle(),
      onPressed: _level == null || _busy ? null : _save,
      child: const Text('Guardar valoración'),
    ),
  ];

  List<Widget> _content(StaffCaseSummary item) {
    final StudentPiece? piece = _pieceOf(item);
    final CaseNarrativeView? narrative = _narrative;
    final bool closed = item.status == SetuCaseStatus.closed;
    return <Widget>[
      AssignmentBanner(session: widget.session),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (piece != null) ...<Widget>[
            Semantics(
              image: true,
              label: 'Pieza del estudiante: ${piece.description}',
              child: PieceBadge(piece: piece, size: 60),
            ),
            const SizedBox(width: 12),
          ],
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
                      _schools[item.institutionId] ??
                          widget.session.active?.place ??
                          '',
                      style: _text,
                    ),
                    StaffTag(
                      closed ? 'Cerrado' : staffLevelLabel(item.humanLevel),
                      highlight: item.isUnassessed && !closed,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  staffCaseKind(
                    item.situationType,
                    item.studentRole,
                    origin: item.origin,
                  ),
                  style: _text,
                ),
                if (item.studentPiece?.displayName case final String nick)
                  Text('Apodo de la pieza: $nick', style: _text),
                Text(
                  'Recibida: ${staffShortDate(item.receivedCentrallyAt)}',
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
      if (_saved) ...<Widget>[
        const SizedBox(height: 12),
        const StaffNotice('Valoración guardada.', error: false),
      ],
      if (item.urgentReferralTriggered) ...<Widget>[
        const SizedBox(height: 12),
        const StaffNotice('Derivación urgente registrada.', error: false),
      ],
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _blueTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: const Text('Relato compartido', style: _section),
            ),
            const SizedBox(height: 6),
            Text(
              narrative == null
                  ? 'El estudiante no escribió detalles. La alerta es válida '
                        'igual.'
                  : '“${narrative.narrativeText}”',
              style: const TextStyle(fontSize: 17, height: 1.4),
            ),
            if (narrative != null && narrative.locationText.isNotEmpty)
              Text('Lugar: ${narrative.locationText}', style: _text),
            if (narrative != null && narrative.approxDateText.isNotEmpty)
              Text('Cuándo: ${narrative.approxDateText}', style: _text),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (closed)
        StaffNotice(
          'Este caso está cerrado.'
          '${item.closedReason == null ? '' : ' Motivo: ${item.closedReason}'}',
          error: false,
        )
      else
        ..._assessment(item),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final StaffCaseSummary? item = _case;
    final bool chat = item?.chatAvailableNotice ?? false;
    return FlowScaffold(
      header: FlowHeader(
        title: item == null ? 'Alerta' : 'Alerta ${item.referenceCode}',
      ),
      bottom: item == null
          ? null
          : item.status == SetuCaseStatus.closed && !chat
          ? null
          : StaffPrimaryButton(
              label: chat ? 'Abrir conversación' : 'Habilitar chat',
              busy: _busy,
              onPressed: chat ? _openChat : _enableChat,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_loadError != null) ...<Widget>[
            StaffNotice(_loadError!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ] else if (!_loaded)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando caso',
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

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({required this.item, required this.assessment});

  final StaffCaseSummary item;
  final CaseAssessment assessment;

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        Text(value, style: _text),
      ],
    ),
  );

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
              'Revisá antes de guardar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          _row('Valoración', staffLevelLabel(assessment.level)),
          if (assessment.urgentReferral)
            _row('Derivación urgente', 'Se registra ahora.'),
          if (assessment.issueSheet) ...<Widget>[
            _row(
              'Ficha mínima para',
              assessment.omitSchool
                  ? 'Solo la supervisión del MINED, por conflicto de interés.'
                  : 'La dirección del centro y la supervisión del MINED.',
            ),
            _row(
              'Contenido de la ficha',
              '${staffCaseKind(item.situationType, item.studentRole, origin: item.origin)}\n'
                  '${staffLevelLabel(assessment.level)}',
            ),
            _row('Orientación', assessment.guidanceNotes),
            const StaffNotice(
              'La ficha no incluye el relato, los mensajes ni las notas '
              'internas.',
              error: false,
            ),
            const SizedBox(height: 8),
          ],
          if (assessment.closeCase)
            _row('Cierre en Mesa de Escucha', assessment.closedReason),
          const SizedBox(height: 8),
          FilledButton(
            style: flowPrimaryStyle(),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar y guardar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver a editar'),
          ),
        ],
      ),
    ),
  );
}

/// Conversación humana con el estudiante (`…/caso/:id/chat`). La nota
/// interna vive en otro espacio y nunca se mezcla con los mensajes.
class DeskChatScreen extends StatefulWidget {
  const DeskChatScreen({
    super.key,
    required this.session,
    required this.caseId,
    this.refreshEvery = const Duration(seconds: 3),
  });

  final StaffSession session;
  final String caseId;
  final Duration refreshEvery;

  @override
  State<DeskChatScreen> createState() => _DeskChatScreenState();
}

class _DeskChatScreenState extends State<DeskChatScreen> {
  final OperationIds _operations = OperationIds();
  final TextEditingController _draft = TextEditingController();
  final ScrollController _scroll = ScrollController();
  StaffCaseSummary? _case;
  List<CaseChatMessageView>? _messages;
  String? _error;
  bool _sending = false;
  bool _refreshing = false;
  int _lastMessageCount = 0;
  String? _sendError;
  Timer? _timer;
  StreamSubscription<CaseChatMessageView>? _liveMessages;

  StaffBackend get _backend => widget.session.backend;

  @override
  void initState() {
    super.initState();
    _refresh();
    _liveMessages = _backend
        .watchMessages(widget.caseId)
        .listen(_onLiveMessage);
    _timer = Timer.periodic(widget.refreshEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _liveMessages?.cancel();
    _timer?.cancel();
    _scroll.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final double target = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onLiveMessage(CaseChatMessageView message) {
    if (!mounted) return;
    final List<CaseChatMessageView>? current = _messages;
    if (current == null) {
      _refresh();
      return;
    }
    if (current.any((CaseChatMessageView item) => item.id == message.id)) {
      return;
    }
    final List<CaseChatMessageView> updated = <CaseChatMessageView>[
      ...current,
      message,
    ];
    setState(() {
      _messages = updated;
      _lastMessageCount = updated.length;
    });
    _scheduleScrollToBottom();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final StaffCaseSummary? found = await _findCase(
        widget.session,
        widget.caseId,
      );
      final List<CaseChatMessageView> messages = await _backend.messages(
        widget.caseId,
      );
      if (!mounted) return;
      final int previousCount = _lastMessageCount;
      setState(() {
        _case = found;
        _messages = messages;
        _lastMessageCount = messages.length;
        _error = found == null
            ? 'Ese caso no está disponible para tu cuenta.'
            : null;
      });
      if (messages.length > previousCount) {
        _scheduleScrollToBottom(jump: previousCount == 0);
      }
    } on Object catch (failure) {
      // Con mensajes ya cargados, un fallo de actualización no los oculta.
      if (mounted && _messages == null) {
        setState(() => _error = staffErrorMessage(failure));
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _send() async {
    final String text = _draft.text.trim();
    if (_sending || text.isEmpty) return;
    setState(() => _sending = true);
    String? error;
    try {
      await _backend.sendMessage(
        operationId: _operations.idFor(text),
        caseId: widget.caseId,
        body: text,
      );
      _operations.done();
      if (_draft.text.trim() == text) _draft.clear();
      await _refresh();
    } on Object catch (failure) {
      error = staffErrorMessage(failure);
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sendError = error == null
          ? null
          : '$error Tu texto sigue en el borrador.';
    });
  }

  void _notes() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: CureandoTheme.yellowSoft,
      builder: (BuildContext sheet) =>
          _NotesSheet(backend: _backend, caseId: widget.caseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StaffCaseSummary? item = _case;
    final StudentPiece? piece = _pieceOf(item);
    final List<CaseChatMessageView>? messages = _messages;
    final bool open =
        item != null &&
        item.chatAvailableNotice &&
        item.status != SetuCaseStatus.closed;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRect(
                  child: CampaignBackground(
                    child: SafeArea(
                      bottom: false,
                      child: FlowHeader(
                        title: 'Conversación',
                        subtitle: item?.referenceCode,
                        trailing: piece == null
                            ? null
                            : PieceFigure(piece: piece, height: 62),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CureandoTheme.ink,
                            minimumSize: const Size(48, 48),
                            side: const BorderSide(
                              color: CureandoTheme.blue,
                              width: 1.5,
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: item == null ? null : _notes,
                          icon: const Icon(Icons.lock_outline_rounded),
                          label: const Text('Nota interna'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_error != null)
                        StaffNotice(_error!)
                      else if (messages == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Cargando conversación',
                            ),
                          ),
                        )
                      else ...<Widget>[
                        if (!open)
                          StaffNotice(
                            item?.status == SetuCaseStatus.closed
                                ? 'El caso está cerrado. La conversación '
                                      'queda solo para lectura.'
                                : 'El chat todavía no está habilitado. '
                                      'Habilitalo desde la alerta para '
                                      'escribirle al estudiante.',
                            error: false,
                          )
                        else if (messages.isEmpty) ...<Widget>[
                          const StaffNotice(
                            'El estudiante ya recibió el aviso de que podés '
                            'conversar. Todavía no hay mensajes.',
                            error: false,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CureandoTheme.ink,
                                minimumSize: const Size(48, 48),
                                side: const BorderSide(
                                  color: CureandoTheme.blue,
                                  width: 1.5,
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                const String greeting =
                                    'Hola, soy parte del equipo de escucha. '
                                    'Cuando quieras, podés contarme lo que '
                                    'pasó.';
                                _draft.value = const TextEditingValue(
                                  text: greeting,
                                  selection: TextSelection.collapsed(
                                    offset: greeting.length,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.waving_hand_outlined),
                              label: const Text('Usar saludo de bienvenida'),
                            ),
                          ),
                        ],
                        for (final CaseChatMessageView message in messages)
                          _DeskBubble(message: message, piece: piece),
                      ],
                    ],
                  ),
                ),
                if (_sendError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: StaffNotice(_sendError!),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _draft,
                            enabled: open,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: item?.status == SetuCaseStatus.closed
                                  ? 'Chat cerrado (solo lectura)'
                                  : 'Escribí un mensaje',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          tooltip: 'Enviar mensaje',
                          onPressed: open && !_sending ? _send : null,
                          style: IconButton.styleFrom(
                            backgroundColor: CureandoTheme.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(54, 54),
                          ),
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeskBubble extends StatelessWidget {
  const _DeskBubble({required this.message, required this.piece});

  final CaseChatMessageView message;
  final StudentPiece? piece;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.senderRole == SetuMessageSender.counselingDesk;
    const Radius round = Radius.circular(20);
    final Widget bubble = Flexible(
      child: Semantics(
        label: mine ? 'Vos' : 'Estudiante',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: mine ? CureandoTheme.blue : _blueTint,
            borderRadius: BorderRadius.only(
              topLeft: round,
              topRight: round,
              bottomLeft: mine ? round : const Radius.circular(4),
              bottomRight: mine ? const Radius.circular(4) : round,
            ),
          ),
          child: Text(
            message.body,
            style: TextStyle(
              fontSize: 17,
              color: mine ? Colors.white : CureandoTheme.ink,
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: mine ? 48 : 0,
        right: mine ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!mine && piece != null) ...<Widget>[
            ExcludeSemantics(child: PieceBadge(piece: piece!, size: 38)),
            const SizedBox(width: 8),
          ],
          bubble,
        ],
      ),
    );
  }
}

/// Espacio privado de notas internas. Usa otro almacén y otra operación que
/// el chat: lo escrito acá nunca llega al estudiante.
class _NotesSheet extends StatefulWidget {
  const _NotesSheet({required this.backend, required this.caseId});

  final StaffBackend backend;
  final String caseId;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  final OperationIds _operations = OperationIds();
  final TextEditingController _note = TextEditingController();
  List<CaseInternalNoteView>? _notes;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<CaseInternalNoteView> found = await widget.backend.notes(
        widget.caseId,
      );
      if (mounted) setState(() => _notes = found);
    } on Object catch (failure) {
      if (mounted) setState(() => _error = staffErrorMessage(failure));
    }
  }

  Future<void> _save() async {
    final String text = _note.text.trim();
    if (_saving) return;
    if (text.isEmpty) {
      setState(() => _error = 'Escribí la nota antes de guardarla.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.backend.saveNote(
        operationId: _operations.idFor(text),
        caseId: widget.caseId,
        body: text,
      );
      _operations.done();
      _note.clear();
      await _load();
    } on Object catch (failure) {
      if (mounted) setState(() => _error = staffErrorMessage(failure));
    }
    if (mounted) setState(() => _saving = false);
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
          Row(
            children: <Widget>[
              const Icon(Icons.lock_outline_rounded, color: CureandoTheme.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Notas internas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Solo las ve la persona de Mesa de Escucha asignada. El '
            'estudiante, la dirección y el MINED no las reciben.',
            style: _text,
          ),
          const SizedBox(height: 14),
          StaffField(
            label: 'Nota nueva',
            controller: _note,
            hint:
                'Anotá observaciones privadas de escucha (solo visibles para '
                'vos)...',
            maxLines: 3,
            maxLength: 2000,
            capitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
          ),
          if (_error != null) ...<Widget>[
            StaffNotice(_error!),
            const SizedBox(height: 8),
          ],
          StaffPrimaryButton(
            label: 'Guardar nota',
            busy: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 16),
          if (_notes == null && _error == null)
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando notas',
              ),
            )
          else if (_notes?.isEmpty ?? false)
            const Text('Todavía no hay notas en este caso.', style: _text)
          else
            for (final CaseInternalNoteView note
                in _notes ?? const <CaseInternalNoteView>[])
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5C100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(note.noteBody, style: _text),
                    const SizedBox(height: 4),
                    Text(
                      staffShortDate(note.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: CureandoTheme.secondaryInk,
                      ),
                    ),
                  ],
                ),
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
