import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_nav.dart';
import '../../shared/widgets/setu_dialog.dart';
import '../piece/student_piece.dart';
import 'alert_screens.dart';
import 'support_flow.dart';

const Color _blueTint = Color(0xFFDCE9FB);

/// Pantallas 1 y 7 · «Pedir apoyo». Conserva siempre la pantalla inicial con
/// «Enviar una alerta» y «Ver recursos de ayuda»; cuando llega el aviso de
/// disponibilidad habilita «Abrir chat» dentro de la tarjeta del equipo.
class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({super.key, required this.flow, required this.piece});

  final SupportFlow flow;
  final ValueNotifier<StudentPiece> piece;

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.flow.addListener(_markSeen);
    widget.flow.open().then((_) => _markSeen());
  }

  @override
  void dispose() {
    widget.flow.removeListener(_markSeen);
    super.dispose();
  }

  /// Entrar a «Pedir apoyo» revisa los avisos: el contador del inicio vuelve
  /// a 0. Se agenda fuera del build para no notificar mientras se dibuja.
  void _markSeen() {
    if (widget.flow.unreadSupport == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.flow.markSupportSeen();
    });
  }

  void _alert() => context.push<void>('/inicio/apoyo/alerta');

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[widget.flow, widget.piece]),
    builder: (BuildContext context, _) => _entry(context),
  );

  Widget _entry(BuildContext context) {
    final bool chatAvailable = widget.flow.chatAvailable;
    return FlowScaffold(
      bottomNavigationBar: SetuBottomNav(
        selected: HomeSection.ayuda,
        onSelected: (HomeSection section) =>
            context.go('/inicio', extra: HomeSectionRequest(section)),
      ),
      header: FlowHeader(
        title: 'Pedir apoyo',
        showBrand: true,
        brandTrailing: PieceHeaderButton(piece: widget.piece),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox(
              height: 196,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 30,
                    child: DashedWave(color: CureandoTheme.pink, height: 44),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 130,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: _blueTint,
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(65, 9),
                        ),
                      ),
                    ),
                  ),
                  // La misma pieza que el estudiante armó en «Mi perfil».
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: PieceFigure(piece: widget.piece.value, height: 186),
                  ),
                  Align(
                    alignment: const Alignment(.78, -.55),
                    child: Container(
                      width: 74,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: CureandoTheme.blue, width: 3),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: CureandoTheme.pink,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: const Text(
              '¿En qué te podemos ayudar?',
              style: TextStyle(
                fontSize: 27,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: flowPrimaryStyle(),
            onPressed: _alert,
            icon: const Icon(Icons.notifications_active_outlined, size: 28),
            label: const Text('Enviar una alerta'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: chatAvailable ? _blueTint : const Color(0xFFE6E9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MergeSemantics(
                  child: Row(
                    children: <Widget>[
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.sms_outlined,
                          color: Color(0xFF0B3FA8),
                          size: 46,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Chat con el equipo de escucha',
                              style: TextStyle(
                                fontSize: 19,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (chatAvailable)
                              Semantics(
                                liveRegion: true,
                                child: const Text(
                                  'El equipo de escucha puede conversar con vos',
                                ),
                              )
                            else if (widget.flow.caseClosed)
                              const Text(
                                'Este caso ya cerró. Podés revisar los '
                                'mensajes anteriores.',
                              )
                            else
                              Text(
                                widget.flow.minimalAlertDelivered &&
                                        widget.flow.delivery !=
                                            AlertDelivery.received
                                    ? 'Alerta entregada al dispositivo autorizado. Falta sincronizar con la plataforma.'
                                    : switch (widget.flow.delivery) {
                                        AlertDelivery.pending =>
                                          'Tu alerta está guardada en este teléfono. '
                                              'Falta confirmar la entrega.',
                                        _ =>
                                          'Te avisamos aquí cuando alguien pueda '
                                              'conversar con vos.',
                                      },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (chatAvailable || widget.flow.caseClosed) ...<Widget>[
                  const SizedBox(height: 14),
                  FilledButton(
                    style: flowPrimaryStyle(),
                    onPressed: () => context.push<void>('/inicio/apoyo/chat'),
                    child: Text(chatAvailable ? 'Abrir chat' : 'Ver chat'),
                  ),
                ],
              ],
            ),
          ),
          if (!chatAvailable && !widget.flow.caseClosed) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              key: const Key('alert-waiting-help-card'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFC2E2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    '¿Sin internet o todavía sin respuesta?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Si necesitás hablar con alguien ahora, en Ayuda tenés '
                    'líneas de emergencia verificadas a las que podés llamar.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: flowPrimaryStyle(),
                    onPressed: () => context.go(
                      '/inicio',
                      extra: HomeSectionRequest(HomeSection.ayuda),
                    ),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Ir a contactos de ayuda'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            style: flowSecondaryStyle(),
            onPressed: () => context.go(
              '/inicio',
              extra: HomeSectionRequest(HomeSection.ayuda),
            ),
            child: const Text('Ver recursos de ayuda'),
          ),
        ],
      ),
    );
  }
}

/// Pantalla 6: acuse de la alerta. Distingue «guardada en este teléfono»
/// de «recibida»; nunca muestra recepción antes del acuse.
class AlertReceivedScreen extends StatelessWidget {
  const AlertReceivedScreen({super.key, required this.flow});

  final SupportFlow flow;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: flow,
    builder: (BuildContext context, _) {
      final bool centrallyReceived = flow.delivery == AlertDelivery.received;
      final bool received = centrallyReceived || flow.minimalAlertDelivered;
      return FlowScaffold(
        bottomNavigationBar: SetuBottomNav(
          selected: HomeSection.ayuda,
          onSelected: (HomeSection section) =>
              context.go('/inicio', extra: HomeSectionRequest(section)),
        ),
        header: FlowHeader(
          title: 'Pedir apoyo',
          showBrand: true,
          trailing: Image.asset(
            'assets/brand/png/personaje-14.png',
            width: 132,
            height: 92,
            excludeFromSemantics: true,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 20),
            ExcludeSemantics(
              child: Center(
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: received
                        ? const Color(0xFFD3F8DF)
                        : const Color(0xFFFFF3C4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    received
                        ? Icons.check_rounded
                        : Icons.hourglass_top_rounded,
                    size: 88,
                    color: received
                        ? const Color(0xFF00A738)
                        : const Color(0xFF8A6A00),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Semantics(
              liveRegion: true,
              child: Column(
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      received
                          ? 'Alerta entregada'
                          : 'Guardada en este teléfono',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    received
                        ? 'Te avisaremos aquí cuando alguien pueda conversar '
                              'con vos.'
                        : 'Falta confirmar la entrega.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (flow.minimalAlertDelivered &&
                      !centrallyReceived) ...<Widget>[
                    const SizedBox(height: 12),
                    const Text(
                      'Un dispositivo autorizado recibió la alerta mínima. El relato sigue en este teléfono. Falta sincronizar con la plataforma; esto no confirma lectura ni atención.',
                      textAlign: TextAlign.center,
                    ),
                  ] else if (flow.meshPending) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      flow.needsBluetoothForMesh
                          ? 'Sin internet. Permití dispositivos cercanos y Bluetooth en Android para intentar el envío. Tu alerta sigue guardada.'
                          : 'Sin internet: tu alerta se enviará por un dispositivo cercano cuando esté disponible. Falta confirmar la entrega.',
                      textAlign: TextAlign.center,
                    ),
                  ] else if (flow.deliveryFailed) ...<Widget>[
                    const SizedBox(height: 12),
                    const Text(
                      'No pudimos confirmar la entrega. Revisá tu conexión a '
                      'internet. Tu alerta sigue guardada y se vuelve a '
                      'intentar sola.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: flow.retryDelivery,
                      child: const Text('Reintentar ahora'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: flowPrimaryStyle(),
              onPressed: () => context.go('/inicio/apoyo'),
              child: const Text('Volver a Pedir apoyo'),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              style: flowSecondaryStyle().copyWith(
                foregroundColor: const WidgetStatePropertyAll<Color>(
                  CureandoTheme.ink,
                ),
              ),
              onPressed: () => context.go(
                '/inicio',
                extra: HomeSectionRequest(HomeSection.informacion),
              ),
              child: const Text('Explorar Información'),
            ),
          ],
        ),
      );
    },
  );
}

/// Pantalla 8: chat humano con el equipo de escucha. No hay respuestas
/// automáticas: las burbujas rompehielos solo llenan el borrador.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, required this.flow, required this.piece});

  final SupportFlow flow;
  final ValueNotifier<StudentPiece> piece;

  static const List<String> icebreakers = <String>[
    'No sé por dónde empezar',
    'Quiero contar algo',
  ];

  /// Tarjetas rompehielo que abre la pieza del estudiante dentro del chat.
  /// Frases cortas en primera persona; el estudiante puede editarlas antes de
  /// enviar. No sugieren detalles del caso ni prometen resultados.
  static const Map<String, List<String>> icebreakerGroups =
      <String, List<String>>{
        'Para empezar': <String>[
          'No sé por dónde empezar',
          'Quiero contar algo',
          'Hola, necesito hablar con alguien',
          'Me cuesta escribir esto',
          '¿Puedo contarte algo sin que me juzgues?',
        ],
        'Lo que pasó': <String>[
          'Me están molestando en el colegio',
          'Pasó algo en el recreo',
          'Me molestan por internet o en el chat del grupo',
          'Vi que molestaban a otra persona',
          'Ya pasó varias veces',
        ],
        'Cómo me siento': <String>[
          'Me siento triste',
          'Tengo miedo de ir al colegio',
          'Estoy nervioso o nerviosa',
          'Me siento solo o sola',
          'Estoy enojado y no sé qué hacer',
        ],
        'Lo que necesito': <String>[
          'Necesito que alguien me escuche',
          'Quiero saber qué puedo hacer',
          'Prefiero ir despacio',
          'Hoy solo quiero desahogarme',
        ],
        'Preguntas': <String>[
          '¿Quién va a leer lo que escribo?',
          '¿Qué pasa después de que te cuento?',
          '¿Se van a enterar en mi casa?',
          '¿Cuándo me vas a responder?',
        ],
      };

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _draft = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.flow.messages.length;
    widget.flow.addListener(_onFlowChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(jump: true);
      widget.flow.refreshChat();
      widget.flow.markSupportSeen();
    });
  }

  @override
  void dispose() {
    widget.flow.removeListener(_onFlowChanged);
    _scroll.dispose();
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFlowChanged() {
    // Con el chat abierto, los mensajes nuevos ya se están viendo.
    if (widget.flow.unreadSupport > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.flow.markSupportSeen();
      });
    }
    final int count = widget.flow.messages.length;
    final bool grew = count > _lastMessageCount;
    _lastMessageCount = count;
    if (grew) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom({bool jump = false}) {
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
  }

  /// La pieza del estudiante abre las tarjetas rompehielo agrupadas.
  Future<void> _openIdeas() async {
    final String? idea = await showSetuBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheet) => _IdeasSheet(piece: widget.piece.value),
    );
    if (idea != null && mounted) _useIdea(idea);
  }

  void _useIdea(String idea) {
    _draft.value = TextEditingValue(
      text: idea,
      selection: TextSelection.collapsed(offset: idea.length),
    );
    _focus.requestFocus();
  }

  bool _sending = false;
  bool _sendFailed = false;

  Future<void> _send() async {
    final String text = _draft.text;
    if (_sending || text.trim().isEmpty) return;
    setState(() => _sending = true);
    final bool sent = await widget.flow.sendMessage(text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sendFailed = !sent;
    });
    // Solo se borra lo enviado; lo escrito mientras tanto se conserva.
    if (sent && _draft.text == text) _draft.clear();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: CureandoTheme.statusBarOverlayLight,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[
              widget.flow,
              widget.piece,
            ]),
            builder: (BuildContext context, _) {
              final SupportFlow flow = widget.flow;
              final bool open = flow.chatAvailable;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const ClipRect(
                    child: CampaignBackground(
                      child: SafeArea(
                        bottom: false,
                        child: FlowHeader(title: 'Equipo de escucha'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      controller: _scroll,
                      slivers: <Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          sliver: SliverList.list(
                            children: <Widget>[
                              if (!open)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    flow.caseClosed
                                        ? 'Este caso ya cerró. Podés revisar '
                                              'los mensajes anteriores.'
                                        : 'Todavía no hay una persona '
                                              'disponible para conversar. Te '
                                              'avisamos en Pedir apoyo.',
                                  ),
                                ),
                              for (final ChatMessage message in flow.messages)
                                _Bubble(
                                  message: message,
                                  piece: widget.piece.value,
                                ),
                            ],
                          ),
                        ),
                        if (open && !flow.studentWrote)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _Icebreakers(
                                piece: widget.piece.value,
                                onPick: _useIdea,
                                onMore: _openIdeas,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_sendFailed)
                    Semantics(
                      liveRegion: true,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(Icons.error_outline_rounded),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No se pudo enviar el mensaje. Tu texto '
                                'sigue acá; revisá tu conexión e intentá de '
                                'nuevo.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SafeArea(
                    top: false,
                    maintainBottomViewPadding: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: <Widget>[
                          _PieceIdeasButton(
                            piece: widget.piece.value,
                            onPressed: open ? _openIdeas : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _draft,
                              focusNode: _focus,
                              enabled: open,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: flow.caseClosed
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
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.piece});

  final ChatMessage message;
  final StudentPiece piece;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.fromStudent;
    const Radius round = Radius.circular(20);
    final Widget bubble = Semantics(
      label: mine ? 'Vos' : 'Equipo de escucha',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .72,
        ),
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
          message.text,
          style: TextStyle(
            fontSize: 17,
            color: mine ? Colors.white : CureandoTheme.ink,
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Flexible(child: bubble),
          // Los mensajes propios llevan la pieza del estudiante como ícono.
          if (mine) ...<Widget>[
            const SizedBox(width: 6),
            PieceBadge(piece: piece, size: 32),
          ],
        ],
      ),
    );
  }
}

class _Icebreakers extends StatelessWidget {
  const _Icebreakers({
    required this.piece,
    required this.onPick,
    required this.onMore,
  });

  final StudentPiece piece;
  final ValueChanged<String> onPick;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EEFD),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!largeText) ...<Widget>[
            Semantics(
              button: true,
              label: 'Tu pieza: ver más ideas para escribir',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onMore,
                child: PieceFigure(piece: piece, height: 120, sparks: true),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: const Text(
                    'Ideas para empezar',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                for (final String idea in SupportChatScreen.icebreakers)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: CureandoTheme.ink,
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(48, 52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        side: const BorderSide(
                          color: CureandoTheme.blue,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => onPick(idea),
                      child: Text(
                        idea,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

/// Botón con la pieza del estudiante junto al cuadro de texto: abre las
/// tarjetas rompehielo.
class _PieceIdeasButton extends StatelessWidget {
  const _PieceIdeasButton({required this.piece, required this.onPressed});

  final StudentPiece piece;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Ideas para escribir',
    child: Semantics(
      button: true,
      enabled: onPressed != null,
      label: 'Ideas para escribir',
      excludeSemantics: true,
      child: InkResponse(
        key: const ValueKey<String>('chat-piece-ideas'),
        onTap: onPressed,
        radius: 30,
        child: Opacity(
          opacity: onPressed == null ? .5 : 1,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                PieceBadge(piece: piece, size: 54),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: CureandoTheme.yellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      size: 13,
                      color: CureandoTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Hoja con todas las tarjetas rompehielo, agrupadas por tema.
class _IdeasSheet extends StatelessWidget {
  const _IdeasSheet({required this.piece});

  final StudentPiece piece;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            PieceFigure(piece: piece, height: 64, sparks: true),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  piece.displayName == null
                      ? 'Ideas para escribir'
                      : '${piece.displayName} te da ideas',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tocá una tarjeta para usarla. Podés cambiarla antes de enviar.',
          style: TextStyle(fontSize: 14, color: CureandoTheme.secondaryInk),
        ),
        for (final MapEntry<String, List<String>> group
            in SupportChatScreen.icebreakerGroups.entries) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            group.key,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CureandoTheme.blue,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String idea in group.value)
                ActionChip(
                  label: Text(idea),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CureandoTheme.ink,
                  ),
                  backgroundColor: const Color(0xFFE3EEFD),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () => Navigator.of(context).pop(idea),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}
