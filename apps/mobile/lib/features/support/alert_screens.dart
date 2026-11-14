import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../piece/campaign_characters.dart';
import '../piece/student_piece.dart';
import 'support_flow.dart';

const Color _line = Color(0xFFCBD5E1);

Widget _question(BuildContext context, String text) => Semantics(
  header: true,
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 26,
      height: 1.2,
      fontWeight: FontWeight.w700,
    ),
  ),
);

/// Botón del avatar en el encabezado: abre «Mi perfil».
class PieceHeaderButton extends StatelessWidget {
  const PieceHeaderButton({super.key, required this.piece});

  final ValueNotifier<StudentPiece> piece;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<StudentPiece>(
    valueListenable: piece,
    builder: (BuildContext context, StudentPiece value, _) => Tooltip(
      message: 'Abrir mi perfil',
      child: Semantics(
        button: true,
        label:
            'Tu pieza ${value.nickname}: ${value.description}. Tocá para '
            'abrir tu perfil.',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push<void>('/inicio/pieza'),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                PieceBadge(piece: value, size: 50),
                const Positioned(
                  top: -2,
                  right: -2,
                  child: ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: CureandoTheme.yellow,
                      child: Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: CureandoTheme.ink,
                      ),
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

/// Pantalla 2 · Paso 1 de 3: qué está pasando.
class AlertSituationScreen extends StatelessWidget {
  const AlertSituationScreen({
    super.key,
    required this.flow,
    required this.piece,
  });

  final SupportFlow flow;
  final ValueNotifier<StudentPiece> piece;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: flow,
    builder: (BuildContext context, _) => FlowScaffold(
      header: FlowHeader(
        title: 'Enviar una alerta',
        showBrand: true,
        brandTrailing: PieceHeaderButton(piece: piece),
      ),
      bottom: FilledButton(
        style: flowPrimaryStyle(),
        onPressed: flow.situation == null
            ? null
            : () => context.push<void>('/inicio/apoyo/rol'),
        child: const Text('Continuar'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9FB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Paso 1 de 3',
              style: TextStyle(
                color: CureandoTheme.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _question(context, '¿Qué está pasando?'),
          const SizedBox(height: 14),
          for (final Situation option in Situation.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SituationTile(
                option: option,
                selected: flow.situation == option,
                onTap: () => flow.selectSituation(option),
              ),
            ),
        ],
      ),
    ),
  );
}

class _SituationTile extends StatelessWidget {
  const _SituationTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final Situation option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? CureandoTheme.blue : _line,
          width: selected ? 3 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: Icon(option.icon, color: option.color, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: selected
                      ? const CircleAvatar(
                          radius: 15,
                          backgroundColor: CureandoTheme.blue,
                          child: Icon(
                            Icons.check_rounded,
                            size: 21,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: CureandoTheme.blue,
                          size: 30,
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

FlowHeader _stepHeader(String step, StudentPiece piece) => FlowHeader(
  title: 'Enviar una alerta',
  subtitle: step,
  trailing: PieceFigure(piece: piece, height: 86, sparks: true),
);

/// Pantalla 3 · Paso 2 de 3: cómo se relaciona con lo que pasó.
class AlertRoleScreen extends StatelessWidget {
  const AlertRoleScreen({super.key, required this.flow, required this.piece});

  final SupportFlow flow;
  final ValueNotifier<StudentPiece> piece;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[flow, piece]),
    builder: (BuildContext context, _) => FlowScaffold(
      header: _stepHeader('Paso 2 de 3', piece.value),
      bottom: FilledButton(
        style: flowPrimaryStyle(),
        onPressed: flow.participation == null
            ? null
            : () => context.push<void>('/inicio/apoyo/detalles'),
        child: const Text('Continuar'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _question(context, '¿Cómo te relacionás con lo que pasó?'),
          const SizedBox(height: 18),
          _RoleCard(
            role: Participation.own,
            selected: flow.participation == Participation.own,
            onTap: () => flow.selectParticipation(Participation.own),
            art: const PieceFigure(
              piece: StudentPiece(
                shape: PieceShape.puzzle,
                color: PieceColor.blue,
              ),
              height: 104,
              sparks: true,
            ),
          ),
          const SizedBox(height: 14),
          _RoleCard(
            role: Participation.witness,
            tag: 'Testigo solidario',
            selected: flow.participation == Participation.witness,
            onTap: () => flow.selectParticipation(Participation.witness),
            art: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PieceFigure(
                  piece: StudentPiece(
                    shape: PieceShape.doublePuzzle,
                    color: PieceColor.yellow,
                  ),
                  height: 84,
                ),
                PieceFigure(
                  piece: StudentPiece(
                    shape: PieceShape.star,
                    color: PieceColor.blue,
                  ),
                  height: 84,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
    required this.art,
    this.tag,
  });

  final Participation role;
  final bool selected;
  final VoidCallback onTap;
  final Widget art;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFE3EEFD) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? CureandoTheme.blue : _line,
            width: selected ? 3 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 20, 40, 20),
                child: Row(
                  children: <Widget>[
                    if (!largeText) ...<Widget>[
                      FittedBox(child: art),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            role.label,
                            style: const TextStyle(
                              fontSize: 21,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (tag != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCE9FB),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag!,
                                style: const TextStyle(
                                  color: CureandoTheme.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: CureandoTheme.blue,
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla 4 · Paso 3 de 3: detalles opcionales.
class AlertDetailsScreen extends StatefulWidget {
  const AlertDetailsScreen({
    super.key,
    required this.flow,
    required this.piece,
  });

  final SupportFlow flow;
  final ValueNotifier<StudentPiece> piece;

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.flow.details,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<StudentPiece>(
    valueListenable: widget.piece,
    builder: (BuildContext context, StudentPiece piece, _) => FlowScaffold(
      header: _stepHeader('Paso 3 de 3', piece),
      bottom: FilledButton(
        style: flowPrimaryStyle(),
        onPressed: () => context.push<void>('/inicio/apoyo/revisar'),
        child: const Text('Revisar alerta'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _question(context, '¿Querés contar algo más?'),
          const SizedBox(height: 4),
          const Text(
            'Es opcional.',
            style: TextStyle(
              color: CureandoTheme.secondaryInk,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (String value) => widget.flow.details = value,
            minLines: 7,
            maxLines: 12,
            maxLength: SupportFlow.maxDetails,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Escribí lo que quieras compartir',
              counterText: '',
              helperText: 'Podés dejar este espacio en blanco.',
              helperMaxLines: 3,
              helperStyle: const TextStyle(
                color: CureandoTheme.secondaryInk,
                fontSize: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _line, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Pantalla 5: revisar la alerta y leer quién recibe cada dato.
class AlertReviewScreen extends StatefulWidget {
  const AlertReviewScreen({super.key, required this.flow, required this.piece});

  final SupportFlow flow;

  /// Pieza actual del estudiante; viaja con la alerta.
  final ValueNotifier<StudentPiece> piece;

  @override
  State<AlertReviewScreen> createState() => _AlertReviewScreenState();
}

class _AlertReviewScreenState extends State<AlertReviewScreen> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    final bool saved = await widget.flow.send(piece: widget.piece.value);
    if (!mounted) return;
    if (saved) {
      context.go('/inicio/apoyo/recibida');
      return;
    }
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo guardar la alerta en este teléfono. Intentá de nuevo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SupportFlow flow = widget.flow;
    final String details = flow.details.trim();
    final bool complete = flow.situation != null && flow.participation != null;
    return FlowScaffold(
      header: FlowHeader(
        title: 'Revisá tu alerta',
        showBrand: true,
        trailing: const SizedBox(width: 132, child: CampaignCharacters()),
      ),
      bottom: FilledButton(
        style: flowPrimaryStyle(),
        onPressed: complete && !_sending ? _send : null,
        child: Text(_sending ? 'Guardando…' : 'Enviar alerta'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: CureandoTheme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line, width: 1.5),
            ),
            child: Column(
              children: <Widget>[
                _ReviewRow(
                  icon: Icons.campaign_outlined,
                  color: CureandoTheme.blue,
                  label: 'Situación',
                  value: flow.situation?.label ?? 'Sin elegir',
                ),
                const Divider(height: 1, color: _line),
                _ReviewRow(
                  icon: Icons.person_outline_rounded,
                  color: const Color(0xFF057634),
                  label: 'Tu participación',
                  value: flow.participation?.label ?? 'Sin elegir',
                ),
                const Divider(height: 1, color: _line),
                _ReviewRow(
                  icon: Icons.sms_outlined,
                  color: CureandoTheme.pink,
                  label: 'Detalles',
                  value: details.isEmpty ? 'Sin detalles' : details,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _sending
                  ? null
                  : () => context.go('/inicio/apoyo/alerta'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Editar',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EEFD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: CureandoTheme.blue,
                    size: 40,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'El equipo de escucha asignado puede leer tu relato. El '
                    'MINED y tu colegio reciben solo datos limitados.',
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: MergeSemantics(
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
