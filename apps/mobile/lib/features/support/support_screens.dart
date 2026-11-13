import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../home/student_home_screen.dart';
import '../piece/student_piece.dart';
import 'alert_screens.dart';
import 'support_flow.dart';

const Color _blueTint = Color(0xFFDCE9FB);

/// Pantallas 1 y 7 · «Pedir apoyo». Mientras nadie esté disponible muestra
/// la entrada con «Enviar una alerta»; cuando llega el aviso de
/// disponibilidad ofrece abrir el chat humano.
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
    widget.flow.open();
  }

  void _alert() => context.push<void>('/inicio/apoyo/alerta');

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[widget.flow, widget.piece]),
    builder: (BuildContext context, _) =>
        widget.flow.chatAvailable ? _available(context) : _entry(context),
  );

  Widget _entry(BuildContext context) => FlowScaffold(
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
                      borderRadius: BorderRadius.all(Radius.elliptical(65, 9)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: PieceFigure(
                    piece: widget.piece.value,
                    height: 186,
                    sparks: true,
                  ),
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
            color: const Color(0xFFE6E9FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: MergeSemantics(
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
                      Text(switch (widget.flow.delivery) {
                        AlertDelivery.pending =>
                          'Tu alerta está guardada en este teléfono. Falta '
                              'confirmar la entrega.',
                        _ =>
                          'Te avisamos aquí cuando alguien pueda conversar '
                              'con vos.',
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _available(BuildContext context) => FlowScaffold(
    header: const FlowHeader(title: 'Pedir apoyo'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
          decoration: BoxDecoration(
            color: _blueTint,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const ExcludeSemantics(
                child: Icon(
                  Icons.sms_outlined,
                  color: CureandoTheme.blue,
                  size: 84,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                liveRegion: true,
                child: const Text(
                  'El equipo de escucha puede conversar con vos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: flowPrimaryStyle(),
                onPressed: () => context.push<void>('/inicio/apoyo/chat'),
                child: const Text('Abrir chat'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          style: flowSecondaryStyle(),
          onPressed: _alert,
          child: const Text('Enviar una alerta'),
        ),
      ],
    ),
  );
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
      final bool received = flow.delivery == AlertDelivery.received;
      return FlowScaffold(
        header: FlowHeader(
          title: 'Pedir apoyo',
          showBrand: true,
          trailing: Image.asset(
            'assets/welcome/campaign-characters.png',
            width: 132,
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
                          ? 'Alerta recibida'
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

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _draft = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _useIdea(String idea) {
    _draft.value = TextEditingValue(
      text: idea,
      selection: TextSelection.collapsed(offset: idea.length),
    );
    _focus.requestFocus();
  }

  void _send() {
    widget.flow.sendMessage(_draft.text);
    _draft.clear();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
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
                        child: FlowHeader(
                          title: 'Equipo de escucha',
                          subtitle: 'Chat privado',
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: <Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          sliver: SliverList.list(
                            children: <Widget>[
                              if (!open)
                                const Text(
                                  'Todavía no hay una persona disponible para '
                                  'conversar. Te avisamos en Pedir apoyo.',
                                ),
                              for (final ChatMessage message in flow.messages)
                                _Bubble(message: message),
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
                              ),
                            ),
                          ),
                      ],
                    ),
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
                              focusNode: _focus,
                              enabled: open,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Escribí un mensaje',
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
                            onPressed: open ? _send : null,
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
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.fromStudent;
    const Radius round = Radius.circular(20);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: mine ? 'Vos' : 'Equipo de escucha',
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .78,
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
      ),
    );
  }
}

class _Icebreakers extends StatelessWidget {
  const _Icebreakers({required this.piece, required this.onPick});

  final StudentPiece piece;
  final ValueChanged<String> onPick;

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
            PieceFigure(piece: piece, height: 132, sparks: true),
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
