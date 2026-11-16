import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/remote/setu_remote_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_alert.dart';
import '../piece/student_piece.dart';
import 'staff_backend.dart';
import 'staff_inbox_screens.dart';
import 'staff_widgets.dart';

const TextStyle _section = TextStyle(
  fontSize: 20,
  height: 1.2,
  fontWeight: FontWeight.w700,
  color: CureandoTheme.ink,
);
const TextStyle _text = TextStyle(fontSize: 16, height: 1.4);
const Color _blueTint = Color(0xFFDDEAFB);
const Color _stageTint = Color(0xFFE2EEFD);
const Color _line = Color(0xFFDBE6F5);

/// Apartado visible dentro de la pantalla de atención en Mesa de Escucha.
enum DeskCaseTab {
  chat,
  sheet;

  static DeskCaseTab fromQuery(String? value) =>
      value == 'ficha' ? DeskCaseTab.sheet : DeskCaseTab.chat;
}

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

String _hhmm(DateTime value) {
  final DateTime local = value.toLocal();
  final String h = local.hour.toString().padLeft(2, '0');
  final String m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _alertDateLabel(DateTime value) {
  final DateTime local = value.toLocal();
  final DateTime now = DateTime.now();
  final bool sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) return 'Hoy, ${_hhmm(local)}';
  return staffShortDate(local);
}

String _dayDividerLabel(DateTime value) {
  final DateTime local = value.toLocal();
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Hoy';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
  return staffShortDate(local).split(' · ').first;
}

(String, String) _splitKind(StaffCaseSummary item) {
  final String full = staffCaseKind(
    item.situationType,
    item.studentRole,
    origin: item.origin,
  );
  final List<String> parts = full.split(' · ');
  final String tipo = parts.first;
  final String participacion = parts.length > 1
      ? parts.sublist(1).join(' · ')
      : '';
  return (tipo, participacion);
}

/// Detalle de la alerta en Mesa de Escucha (`/personal/mesa/caso/:id`):
/// la pieza cuenta el relato compartido, datos mínimos de la alerta y acceso
/// directo a «Atender por chat» o a la ficha del caso.
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
  StaffCaseSummary? _case;
  CaseNarrativeView? _narrative;
  Map<String, String> _schools = const <String, String>{};
  bool _loaded = false;
  bool _busy = false;
  String? _loadError;
  String? _actionError;

  StaffBackend get _backend => widget.session.backend;

  @override
  void initState() {
    super.initState();
    _load();
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
      });
    } on Object catch (failure) {
      if (mounted) setState(() => _loadError = staffErrorMessage(failure));
    }
  }

  Future<void> _openRoute(String location) async {
    await context.push(location);
    if (mounted) _load();
  }

  Future<void> _attendByChat(StaffCaseSummary item) async {
    if (_busy) return;
    if (item.chatAvailableNotice || item.isConversationEnded) {
      await _openRoute('/personal/mesa/caso/${widget.caseId}/chat');
      return;
    }
    setState(() {
      _busy = true;
      _actionError = null;
    });
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
      _actionError = error;
    });
    if (error == null) {
      await _openRoute('/personal/mesa/caso/${widget.caseId}/chat');
    }
  }

  Widget _header(StaffCaseSummary? item) {
    final bool closed = item?.status == SetuCaseStatus.closed;
    final String statusText = closed
        ? 'Cerrado'
        : staffLevelLabel(item?.humanLevel);
    final bool unassessed = (item?.isUnassessed ?? true) && !closed;
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!largeText) ...<Widget>[
            Row(
              children: <Widget>[
                const SizedBox(width: 6),
                const CampaignSymbol(size: 26, showUnicef: false),
                const SizedBox(width: 8),
                const ExcludeSemantics(
                  child: Text(
                    'SéTú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Mi perfil',
                  onPressed: () => context.push('/personal/perfil'),
                  icon: const CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: CureandoTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                tooltip: 'Volver',
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        item == null
                            ? 'Alerta'
                            : 'Alerta ${item.referenceCode}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item != null) ...<Widget>[
                      const SizedBox(height: 6),
                      StaffTag(statusText, highlight: unassessed),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _content(StaffCaseSummary item) {
    final StudentPiece? piece = _pieceOf(item);
    final CaseNarrativeView? narrative = _narrative;
    final String schoolName =
        _schools[item.institutionId] ?? widget.session.active?.place ?? '';
    final (String tipo, String participacion) = _splitKind(item);
    final bool closed = item.status == SetuCaseStatus.closed;

    return <Widget>[
      AssignmentBanner(session: widget.session),
      _PieceStoryCard(
        piece: piece,
        displayName: item.studentPiece?.displayName,
        narrative: narrative,
      ),
      const SizedBox(height: 18),
      Semantics(
        header: true,
        child: const Text('Datos de la alerta', style: _section),
      ),
      const SizedBox(height: 10),
      _AlertDataCard(
        schoolName: schoolName,
        tipo: tipo,
        participacion: participacion,
        receivedLabel: _alertDateLabel(item.receivedCentrallyAt),
      ),
      if (_actionError != null) ...<Widget>[
        const SizedBox(height: 12),
        StaffNotice(_actionError!),
      ],
      if (item.urgentReferralTriggered) ...<Widget>[
        const SizedBox(height: 12),
        const StaffNotice('Derivación urgente registrada.', error: false),
      ],
      if (closed) ...<Widget>[
        const SizedBox(height: 12),
        StaffNotice(
          'Este caso está cerrado.'
          '${item.closedReason == null ? '' : ' Motivo: ${item.closedReason}'}',
          error: false,
        ),
      ],
    ];
  }

  Widget? _bottom(StaffCaseSummary? item) {
    if (item == null) return null;
    final bool readOnlyChat =
        item.isConversationEnded && !item.chatAvailableNotice;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StaffPrimaryButton(
          label: readOnlyChat ? 'Ver conversación' : 'Atender por chat',
          icon: Icons.chat_bubble_outline_rounded,
          busy: _busy,
          onPressed: () => _attendByChat(item),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: CureandoTheme.blue,
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: _busy
              ? null
              : () => _openRoute(
                  '/personal/mesa/caso/${widget.caseId}/chat?apartado=ficha',
                ),
          icon: const Icon(Icons.assignment_outlined, size: 18),
          label: Text(
            item.status == SetuCaseStatus.closed
                ? 'Ver ficha y notas'
                : 'Abrir ficha sin chat',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final StaffCaseSummary? item = _case;
    return FlowScaffold(
      onRefresh: _load,
      header: _header(item),
      bottom: _bottom(item),
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

class _PieceStoryCard extends StatelessWidget {
  const _PieceStoryCard({
    required this.piece,
    required this.displayName,
    required this.narrative,
  });

  final StudentPiece? piece;
  final String? displayName;
  final CaseNarrativeView? narrative;

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    final String storyText = narrative == null || narrative!.narrativeText.isEmpty
        ? 'El estudiante no escribió detalles. La alerta es válida igual.'
        : narrative!.narrativeText;

    final Widget character = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (piece != null)
          Semantics(
            image: true,
            label: 'Pieza del estudiante: ${piece!.description}',
            child: PieceFigure(piece: piece!, height: 112, sparks: true),
          )
        else
          const Icon(
            Icons.extension_rounded,
            size: 64,
            color: CureandoTheme.green,
          ),
        if (displayName != null && displayName!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              displayName!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CureandoTheme.ink,
              ),
            ),
          ),
        ],
      ],
    );

    final Widget bubble = _SpeechBubble(
      pointLeft: !largeText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            storyText,
            style: const TextStyle(
              fontSize: 16,
              height: 1.38,
              color: CureandoTheme.ink,
            ),
          ),
          if (narrative != null && narrative!.locationText.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Lugar: ${narrative!.locationText}',
              style: const TextStyle(
                fontSize: 14,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          ],
          if (narrative != null &&
              narrative!.approxDateText.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'Cuándo: ${narrative!.approxDateText}',
              style: const TextStyle(
                fontSize: 14,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          ],
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _stageTint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: const Text(
              'Comentario de la alerta',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CureandoTheme.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (largeText) ...<Widget>[
            Center(child: character),
            const SizedBox(height: 12),
            bubble,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Flexible(flex: 4, child: Center(child: character)),
                const SizedBox(width: 8),
                Expanded(flex: 6, child: bubble),
              ],
            ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.child, this.pointLeft = true});

  final Widget child;
  final bool pointLeft;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      if (pointLeft)
        Positioned(
          left: -10,
          bottom: 24,
          child: CustomPaint(
            size: const Size(14, 16),
            painter: _BubbleTailPainter(),
          ),
        ),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    ],
  );
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height * 0.72)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlertDataCard extends StatelessWidget {
  const _AlertDataCard({
    required this.schoolName,
    required this.tipo,
    required this.participacion,
    required this.receivedLabel,
  });

  final String schoolName;
  final String tipo;
  final String participacion;
  final String receivedLabel;

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CureandoTheme.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: CureandoTheme.ink),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: <Widget>[
        _row('Colegio', schoolName.isEmpty ? 'Centro asignado' : schoolName),
        const Divider(height: 1, color: _line),
        _row('Tipo', tipo),
        if (participacion.isNotEmpty) ...<Widget>[
          const Divider(height: 1, color: _line),
          _row('Participación', participacion),
        ],
        const Divider(height: 1, color: _line),
        _row('Recibida', receivedLabel),
      ],
    ),
  );
}

/// Atención de Mesa de Escucha (`/personal/mesa/caso/:id/chat`): permite
/// conversar con el estudiante y alternar hacia «Ficha» sin perder borradores,
/// para consultar datos, tomar notas privadas, valorar el nivel, guardar
/// borrador y finalmente enviar el reporte cerrando el chat.
class DeskChatScreen extends StatefulWidget {
  const DeskChatScreen({
    super.key,
    required this.session,
    required this.caseId,
    this.initialTab = DeskCaseTab.chat,
    this.refreshEvery = const Duration(seconds: 3),
  });

  final StaffSession session;
  final String caseId;
  final DeskCaseTab initialTab;
  final Duration refreshEvery;

  @override
  State<DeskChatScreen> createState() => _DeskChatScreenState();
}

class _DeskChatScreenState extends State<DeskChatScreen> {
  final OperationIds _operations = OperationIds();
  final TextEditingController _messageDraft = TextEditingController();
  final TextEditingController _noteDraft = TextEditingController();
  final TextEditingController _guidanceDraft = TextEditingController();
  final TextEditingController _closeReason = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  late DeskCaseTab _tab = widget.initialTab;
  StaffCaseSummary? _case;
  CaseNarrativeView? _narrative;
  Map<String, String> _schools = const <String, String>{};
  List<CaseChatMessageView>? _messages;
  List<CaseInternalNoteView> _notes = const <CaseInternalNoteView>[];

  bool _loadedMeta = false;
  bool _draftHydrated = false;
  String? _error;
  String? _sendError;
  String? _noteError;
  String? _sheetError;
  String? _sheetSuccess;
  bool _sendingMessage = false;
  bool _enablingChat = false;
  bool _savingNote = false;
  bool _savingDraft = false;
  bool _submittingReport = false;
  bool _refreshing = false;
  int _lastMessageCount = 0;

  int? _level;
  bool _urgent = false;
  bool _omitSchool = false;

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
    _chatScroll.dispose();
    _messageDraft.dispose();
    _noteDraft.dispose();
    _guidanceDraft.dispose();
    _closeReason.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScroll.hasClients) return;
      final double target = _chatScroll.position.maxScrollExtent;
      if (jump) {
        _chatScroll.jumpTo(target);
      } else {
        _chatScroll.animateTo(
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
      final Map<String, String> schools = await _backend.institutionNames();
      final List<CaseChatMessageView> messages = await _backend.messages(
        widget.caseId,
      );
      final List<CaseInternalNoteView> notes = found == null
          ? const <CaseInternalNoteView>[]
          : await _backend.notes(widget.caseId);
      final CaseNarrativeView? narrative = found == null || _loadedMeta
          ? _narrative
          : await _backend.narrative(widget.caseId);
      final CaseSheetDraftView? draft = found == null || _draftHydrated
          ? null
          : await _backend.sheetDraft(widget.caseId);
      if (!mounted) return;
      final int previousCount = _lastMessageCount;
      setState(() {
        _case = found;
        _schools = schools;
        _messages = messages;
        _notes = notes;
        _narrative = narrative;
        _loadedMeta = true;
        _level ??= found?.humanLevel;
        if (!_draftHydrated) {
          _draftHydrated = true;
          if (draft != null && draft.guidanceDraft.isNotEmpty) {
            if (_level == 1) {
              _closeReason.text = draft.guidanceDraft;
            } else {
              _guidanceDraft.text = draft.guidanceDraft;
            }
          }
        }
        _lastMessageCount = messages.length;
        _error = found == null
            ? 'Ese caso no está disponible para tu cuenta.'
            : null;
      });
      if (_tab == DeskCaseTab.chat && messages.length > previousCount) {
        _scheduleScrollToBottom(jump: previousCount == 0);
      }
    } on Object catch (failure) {
      if (mounted && _messages == null) {
        setState(() => _error = staffErrorMessage(failure));
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _sendMessage() async {
    final String text = _messageDraft.text.trim();
    if (_sendingMessage || text.isEmpty) return;
    setState(() => _sendingMessage = true);
    String? error;
    try {
      await _backend.sendMessage(
        operationId: _operations.idFor(text),
        caseId: widget.caseId,
        body: text,
      );
      _operations.done();
      if (_messageDraft.text.trim() == text) _messageDraft.clear();
      await _refresh();
    } on Object catch (failure) {
      error = staffErrorMessage(failure);
    }
    if (!mounted) return;
    setState(() {
      _sendingMessage = false;
      _sendError = error == null
          ? null
          : '$error Tu texto sigue en el borrador.';
    });
  }

  Future<void> _enableChatFromHere() async {
    if (_enablingChat) return;
    setState(() => _enablingChat = true);
    try {
      await _backend.enableChat(
        operationId: _operations.idFor('enable-chat|${widget.caseId}'),
        caseId: widget.caseId,
      );
      _operations.done();
      await _refresh();
    } on Object catch (failure) {
      if (mounted) {
        showSetuBottomAlert(
          context,
          staffErrorMessage(failure),
          kind: SetuAlertKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _enablingChat = false);
    }
  }

  Future<void> _saveNote() async {
    final String text = _noteDraft.text.trim();
    if (_savingNote) return;
    if (text.isEmpty) {
      setState(() => _noteError = 'Escribí la nota antes de guardarla.');
      return;
    }
    setState(() {
      _savingNote = true;
      _noteError = null;
    });
    try {
      await _backend.saveNote(
        operationId: _operations.idFor('note|$text'),
        caseId: widget.caseId,
        body: text,
      );
      _operations.done();
      _noteDraft.clear();
      await _refresh();
    } on Object catch (failure) {
      if (mounted) setState(() => _noteError = staffErrorMessage(failure));
    }
    if (mounted) setState(() => _savingNote = false);
  }

  Future<void> _saveDraft() async {
    if (_savingDraft) return;
    final String text = (_level == 1 ? _closeReason.text : _guidanceDraft.text)
        .trim();
    setState(() {
      _savingDraft = true;
      _sheetError = null;
      _sheetSuccess = null;
    });
    try {
      await _backend.saveSheetDraft(
        caseId: widget.caseId,
        guidanceDraft: text,
      );
      if (!mounted) return;
      setState(() => _sheetSuccess = 'Borrador guardado.');
    } on Object catch (failure) {
      if (mounted) setState(() => _sheetError = staffErrorMessage(failure));
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _submitReportAndCloseChat() async {
    final StaffCaseSummary? item = _case;
    final int? level = _level;
    if (item == null || level == null || _submittingReport) return;
    final bool isLevel1 = level == 1;
    final String notesText = isLevel1
        ? _closeReason.text.trim()
        : _guidanceDraft.text.trim();
    if (isLevel1 && notesText.isEmpty) {
      setState(() {
        _sheetError = 'Escribí el motivo del cierre.';
        _sheetSuccess = null;
      });
      return;
    }
    if (!isLevel1 && notesText.isEmpty) {
      setState(() {
        _sheetError = 'Escribí los comentarios para la ficha.';
        _sheetSuccess = null;
      });
      return;
    }

    final CaseAssessment assessment = CaseAssessment(
      caseId: item.id,
      level: level,
      urgentReferral: !isLevel1 && level == 3 && _urgent,
      issueSheet: !isLevel1,
      guidanceNotes: isLevel1 ? '' : notesText,
      omitSchool: !isLevel1 && _omitSchool,
      closeCase: isLevel1,
      closedReason: isLevel1 ? notesText : '',
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
      _submittingReport = true;
      _sheetError = null;
      _sheetSuccess = null;
    });
    try {
      await _backend.assess(
        operationId: _operations.idFor(assessment.fingerprint),
        assessment: assessment,
      );
      _operations.done();
      if (!isLevel1) {
        await _backend.endConversation(
          operationId: _operations.idFor('end|${item.id}'),
          caseId: item.id,
        );
        _operations.done();
      }
      await _refresh();
      if (!mounted) return;
      setState(() {
        _sheetSuccess = isLevel1
            ? 'Caso cerrado y chat finalizado.'
            : 'Reporte enviado y chat cerrado.';
      });
    } on Object catch (failure) {
      if (mounted) setState(() => _sheetError = staffErrorMessage(failure));
    } finally {
      if (mounted) setState(() => _submittingReport = false);
    }
  }

  Widget _header(StaffCaseSummary? item, StudentPiece? piece) {
    final bool closed = item?.status == SetuCaseStatus.closed;
    final String? displayName = item?.studentPiece?.displayName;
    final bool hasName = displayName != null && displayName.isNotEmpty;
    final String title = hasName
        ? displayName
        : item?.referenceCode ?? 'Conversación';
    final String status = closed
        ? 'Cerrado'
        : staffLevelLabel(item?.humanLevel);
    final String subtitle = item == null
        ? ''
        : hasName
        ? '${item.referenceCode} · $status'
        : status;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            tooltip: 'Volver',
            onPressed: () => context.pop(),
          ),
          if (piece != null) ...<Widget>[
            PieceBadge(piece: piece, size: 44),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _tab = _tab == DeskCaseTab.chat
                      ? DeskCaseTab.sheet
                      : DeskCaseTab.chat;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      _tab == DeskCaseTab.chat
                          ? Icons.assignment_outlined
                          : Icons.chat_bubble_outline_rounded,
                      color: CureandoTheme.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tab == DeskCaseTab.chat ? 'Ficha' : 'Chat',
                      style: const TextStyle(
                        color: CureandoTheme.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBody(
    StaffCaseSummary item,
    StudentPiece? piece,
    List<CaseChatMessageView> messages,
  ) {
    final bool open = item.chatAvailableNotice && !item.isConversationEnded;
    final bool ended = item.isConversationEnded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: _chatScroll,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            children: <Widget>[
              if (!item.chatAvailableNotice && !ended) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CureandoTheme.blueSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Chat sin habilitar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CureandoTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StaffPrimaryButton(
                        label: 'Habilitar chat',
                        busy: _enablingChat,
                        onPressed: _enableChatFromHere,
                      ),
                    ],
                  ),
                ),
              ] else ...<Widget>[
                if (ended) ...<Widget>[
                  StaffNotice(
                    item.status == SetuCaseStatus.closed
                        ? 'Caso cerrado. Solo lectura.'
                        : 'Chat finalizado. Solo lectura.',
                    error: false,
                  ),
                  const SizedBox(height: 12),
                ] else if (messages.isEmpty) ...<Widget>[
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
                            'Hola, soy parte del equipo de escucha. Cuando '
                            'quieras, podés contarme lo que pasó.';
                        _messageDraft.value = const TextEditingValue(
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
                  const SizedBox(height: 12),
                ],
                for (int i = 0; i < messages.length; i++) ...<Widget>[
                  if (i == 0 ||
                      _dayDividerLabel(messages[i].createdAt) !=
                          _dayDividerLabel(messages[i - 1].createdAt))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5EDF9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _dayDividerLabel(messages[i].createdAt),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CureandoTheme.secondaryInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  _DeskBubble(message: messages[i], piece: piece),
                ],
              ],
            ],
          ),
        ),
        if (_sendError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
                    controller: _messageDraft,
                    enabled: open,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: ended
                          ? 'Chat cerrado (solo lectura)'
                          : 'Escribí un mensaje',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Enviar mensaje',
                  onPressed: open && !_sendingMessage ? _sendMessage : null,
                  style: IconButton.styleFrom(
                    backgroundColor: CureandoTheme.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheetBody(StaffCaseSummary item, StudentPiece? piece) {
    final String schoolName =
        _schools[item.institutionId] ?? widget.session.active?.place ?? '';
    final (String tipo, String participacion) = _splitKind(item);
    final bool closed = item.status == SetuCaseStatus.closed;
    final bool isLevel1 = _level == 1;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PieceStoryCard(
            piece: piece,
            displayName: item.studentPiece?.displayName,
            narrative: _narrative,
          ),
          const SizedBox(height: 14),
          _AlertDataCard(
            schoolName: schoolName,
            tipo: tipo,
            participacion: participacion,
            receivedLabel: _alertDateLabel(item.receivedCentrallyAt),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CureandoTheme.yellowSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5C100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: CureandoTheme.ink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: const Text(
                          'Notas privadas de escucha',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CureandoTheme.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_notes.isEmpty)
                  const Text(
                    'Todavía no hay notas en este caso.',
                    style: _text,
                  )
                else
                  for (final CaseInternalNoteView note in _notes)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                              fontSize: 13,
                              color: CureandoTheme.secondaryInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 8),
                StaffField(
                  label: 'Nueva nota privada',
                  controller: _noteDraft,
                  hint: 'Observaciones privadas (no se envían en la ficha)',
                  maxLines: 3,
                  maxLength: 2000,
                  capitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                ),
                if (_noteError != null) ...<Widget>[
                  const SizedBox(height: 8),
                  StaffNotice(_noteError!),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  style: flowSecondaryStyle(),
                  onPressed: _savingNote ? null : _saveNote,
                  child: Text(_savingNote ? 'Guardando…' : 'Guardar nota'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: const Text('Ficha y valoración', style: _section),
                  ),
                  const SizedBox(height: 12),
                  if (_sheetSuccess != null) ...<Widget>[
                    StaffNotice(_sheetSuccess!, error: false),
                    const SizedBox(height: 10),
                  ],
                  if (closed)
                    StaffNotice(
                      'Este caso está cerrado.'
                      '${item.closedReason == null ? '' : ' Motivo: ${item.closedReason}'}',
                      error: false,
                    )
                  else ...<Widget>[
                    RadioGroup<int>(
                      groupValue: _level,
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            _level = value;
                            _sheetError = null;
                            _sheetSuccess = null;
                            if (value != 3) _urgent = false;
                          });
                        }
                      },
                      child: Column(
                        children: <Widget>[
                          for (final MapEntry<int, String> level
                              in humanLevelLabels.entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _level == level.key
                                        ? CureandoTheme.blue
                                        : const Color(0xFFCBD5E1),
                                    width: _level == level.key ? 2 : 1.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: RadioListTile<int>(
                                  value: level.key,
                                  title: Text(
                                    '${level.key} · ${level.value}',
                                    style: const TextStyle(
                                      fontSize: 16,
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
                      ),
                    if (!isLevel1) ...<Widget>[
                      const SizedBox(height: 8),
                      StaffField(
                        label: 'Comentarios para la ficha',
                        controller: _guidanceDraft,
                        hint: 'Orientación para el centro y seguimiento',
                        maxLines: 4,
                        maxLength: 1500,
                        capitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                      ),
                      if (_level != null)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _omitSchool,
                          onChanged: (bool? value) =>
                              setState(() => _omitSchool = value ?? false),
                          title: const Text('No enviar a la dirección del centro'),
                          subtitle: const Text('Solo quedará en el MINED.'),
                        ),
                    ],
                    if (isLevel1) ...<Widget>[
                      const SizedBox(height: 8),
                      StaffField(
                        label: 'Motivo del cierre',
                        controller: _closeReason,
                        hint: 'Cómo se acompañó y por qué se cierra el caso',
                        maxLines: 3,
                        maxLength: 500,
                        capitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                    if (_sheetError != null) ...<Widget>[
                      const SizedBox(height: 8),
                      StaffNotice(_sheetError!),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: flowSecondaryStyle(),
                      onPressed: _savingDraft || _submittingReport
                          ? null
                          : _saveDraft,
                      child: Text(
                        _savingDraft ? 'Guardando…' : 'Guardar borrador',
                      ),
                    ),
                    const SizedBox(height: 10),
                    StaffPrimaryButton(
                      label: isLevel1
                          ? 'Cerrar caso y chat'
                          : 'Enviar reporte y cerrar chat',
                      busy: _submittingReport,
                      onPressed: _level == null
                          ? null
                          : _submitReportAndCloseChat,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StaffCaseSummary? item = _case;
    final StudentPiece? piece = _pieceOf(item);
    final List<CaseChatMessageView>? messages = _messages;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: CureandoTheme.statusBarOverlayLight,
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
                      child: _header(item, piece),
                    ),
                  ),
                ),
                Expanded(
                  child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: StaffNotice(_error!),
                        )
                      : messages == null || item == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Cargando caso',
                          ),
                        )
                      : _tab == DeskCaseTab.chat
                      ? _chatBody(item, piece, messages)
                      : _sheetBody(item, piece),
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
    final String time = _hhmm(message.createdAt);

    final Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
          fontSize: 16,
          color: mine ? Colors.white : CureandoTheme.ink,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: mine ? 52 : 0,
        right: mine ? 0 : 40,
      ),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: mine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (!mine) ...<Widget>[
                ExcludeSemantics(
                  child: piece != null
                      ? PieceFigure(piece: piece!, height: 42, sparks: true)
                      : const Icon(
                          Icons.extension_rounded,
                          size: 32,
                          color: CureandoTheme.green,
                        ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Semantics(
                  label: mine ? 'Vos' : 'Estudiante',
                  child: bubble,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: mine ? 0 : 46),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({required this.item, required this.assessment});

  final StaffCaseSummary item;
  final CaseAssessment assessment;

  Widget _dataRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CureandoTheme.secondaryInk,
            ),
          ),
        ),
        Expanded(child: Text(value, style: _text)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final (String tipo, String participacion) = _splitKind(item);
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
                assessment.closeCase
                    ? 'Confirmar cierre'
                    : 'Revisar ficha antes de enviar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CureandoTheme.blueSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.referenceCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StaffTag(staffLevelLabel(assessment.level)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Datos de la alerta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  _dataRow('Tipo', tipo),
                  if (participacion.isNotEmpty)
                    _dataRow('Participación', participacion),
                  _dataRow('Hora', staffShortDate(item.receivedCentrallyAt)),
                  if (assessment.urgentReferral)
                    _dataRow('Derivación urgente', 'Se registra ahora.'),
                ],
              ),
            ),
            if (assessment.issueSheet) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Comentarios para la ficha',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CureandoTheme.blueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(assessment.guidanceNotes, style: _text),
              ),
              const SizedBox(height: 12),
              const Text(
                'Destinatarios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                assessment.omitSchool
                    ? 'Solo la supervisión del MINED, por conflicto de interés.'
                    : 'La dirección del centro y la supervisión del MINED.',
                style: _text,
              ),
              const SizedBox(height: 8),
              const StaffNotice(
                'La ficha no incluye el relato, los mensajes ni las notas '
                'internas. Al enviar se cerrará el chat.',
                error: false,
              ),
            ],
            if (assessment.closeCase) ...<Widget>[
              const SizedBox(height: 12),
              _dataRow('Motivo del cierre', assessment.closedReason),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: flowPrimaryStyle(),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                assessment.closeCase
                    ? 'Confirmar cierre'
                    : 'Enviar reporte y cerrar chat',
              ),
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
}
