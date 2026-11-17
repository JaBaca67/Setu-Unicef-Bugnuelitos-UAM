import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_card.dart';
import 'learning_progress.dart';

class _LearningQuestion {
  const _LearningQuestion(this.prompt, this.options, this.correct);

  final String prompt;
  final List<String> options;
  final int correct;
}

const List<_LearningQuestion> _questions = <_LearningQuestion>[
  _LearningQuestion(
    'Según la guía «Entendé tus emociones», ¿cuál de estas ideas es cierta?',
    <String>[
      'Todas las emociones son válidas; lo importante es cómo las expresamos.',
      'Hay emociones malas que es mejor esconder siempre.',
      'Sentir miedo significa que algo anda mal con vos.',
    ],
    0,
  ),
  _LearningQuestion(
    'Según el recurso «Convivencia escolar», ¿qué podés hacer si ves que molestan a alguien?',
    <String>[
      'Reírte para pasar desapercibido.',
      'Acompañarle o avisar a una persona adulta de confianza.',
      'Compartir lo que pasó para que se haga viral.',
    ],
    1,
  ),
  _LearningQuestion(
    'Según la guía «Entendé tus emociones», ¿qué puede ayudar cuando una emoción pesa mucho?',
    <String>[
      'Guardar lo que sentís siempre.',
      'Culparte por tener esa emoción.',
      'Respirar despacio o hablar con alguien de confianza.',
    ],
    2,
  ),
];

/// Pregunta sobre los contenidos del catálogo. Solo se guarda el día completado.
class DailyQuestionCard extends StatefulWidget {
  const DailyQuestionCard({
    super.key,
    required this.progress,
    required this.day,
  });

  final LearningProgress progress;
  final DateTime day;

  @override
  State<DailyQuestionCard> createState() => _DailyQuestionCardState();
}

class _DailyQuestionCardState extends State<DailyQuestionCard> {
  _LearningQuestion get _question =>
      _questions[widget.day.difference(DateTime.utc(2026, 11, 12)).inDays %
          _questions.length];
  int? _selected;
  bool _saving = false;
  String? _message;

  Future<void> _choose(int index) async {
    if (_saving || widget.progress.answeredToday) return;
    if (index != _question.correct) {
      setState(() {
        _selected = index;
        _message = 'Revisá el recurso y probá de nuevo.';
      });
      return;
    }
    setState(() {
      _selected = index;
      _saving = true;
      _message = null;
    });
    try {
      final int xp = await widget.progress.completeQuestion(widget.day);
      if (!mounted) return;
      setState(() {
        _message = xp > 0
            ? '¡Así es! Sumaste $xp XP.'
            : 'Ya completaste esta pregunta.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _selected = null;
        _message = 'No se pudo guardar. Tocá la respuesta para reintentar.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool done = widget.progress.answeredToday;
    final int? selection = done ? _question.correct : _selected;
    return SetuCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/home/pregunta-del-dia.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Pregunta del día',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  done ? 'Completada' : '+${LearningProgress.questionXp} XP',
                  style: const TextStyle(
                    color: CureandoTheme.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_question.prompt),
            const SizedBox(height: 12),
            for (
              int index = 0;
              index < _question.options.length;
              index++
            ) ...<Widget>[
              _OptionButton(
                text: _question.options[index],
                selected: selection == index,
                correct: _question.correct == index,
                answered: selection != null && !_saving,
                onPressed: done || _saving || !widget.progress.ready
                    ? null
                    : () => _choose(index),
              ),
              const SizedBox(height: 8),
            ],
            Semantics(
              liveRegion: true,
              child: Text(
                _message ??
                    (done
                        ? 'Ya completaste la pregunta de hoy.'
                        : _saving
                        ? 'Guardando tu progreso…'
                        : 'Podés leer el recurso antes de responder.'),
                style: const TextStyle(color: CureandoTheme.secondaryInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final bool correct;
  final bool answered;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool showState = answered && selected;
    final Color border = showState
        ? (correct ? CureandoTheme.green : CureandoTheme.pink)
        : const Color(0xFFC6CDD8);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        alignment: Alignment.centerLeft,
        side: BorderSide(color: border, width: showState ? 2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: CureandoTheme.ink,
      ),
      onPressed: onPressed,
      child: Row(
        children: <Widget>[
          Expanded(child: Text(text)),
          if (showState) ...<Widget>[
            const SizedBox(width: 8),
            Icon(
              correct ? Icons.check_rounded : Icons.close_rounded,
              color: correct ? const Color(0xFF057634) : CureandoTheme.pink,
              semanticLabel: correct ? 'Correcta' : 'Incorrecta',
            ),
          ],
        ],
      ),
    );
  }
}

/// Cinco actividades voluntarias; no otorgan XP ni registran respuestas.
class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bool stacked =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(16) > 17.6;
    const items = <(String, String, String)>[
      (
        'Semáforo de emociones',
        'assets/home/activities/sticker_semaforo_tarjeta.png',
        'semaforo',
      ),
      ('Dados emocionales', 'dado', 'dados'),
      (
        'Pregunta libre',
        'assets/home/activities/sticker_pregunta_hd.png',
        'pregunta',
      ),
      (
        'Dibujo libre',
        'assets/home/activities/sticker_dibujo_hoja.png',
        'dibujo',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ActivityCard(
          title: 'Rompecabezas del buen trato',
          sticker: 'assets/home/activities/rompecabezas_pareja.png',
          route: 'rompecabezas',
          featured: true,
        ),
        const SizedBox(height: 16),
        for (int row = 0; row < 2; row++) ...<Widget>[
          if (stacked)
            for (final item in items.skip(row * 2).take(2)) ...<Widget>[
              ActivityCard(title: item.$1, sticker: item.$2, route: item.$3),
              const SizedBox(height: 14),
            ]
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int col = 0; col < 2; col++) ...<Widget>[
                    if (col > 0) const SizedBox(width: 10),
                    Expanded(
                      child: ActivityCard(
                        title: items[row * 2 + col].$1,
                        sticker: items[row * 2 + col].$2,
                        route: items[row * 2 + col].$3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!stacked) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Tarjeta azul de actividad (patrón de campaña + sticker). La usa también
/// el Inicio para «Pregunta del día» y «Dado de emociones».
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.title,
    required this.sticker,
    required this.route,
    this.featured = false,
    this.detail,
    this.onTap,
  });
  final String title;
  final String sticker;
  final String route;
  final bool featured;

  /// Texto breve bajo el título (por ejemplo «+10 XP» o «Completada»).
  final String? detail;

  /// Acción propia; por defecto abre `/inicio/actividades/[route]`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: detail == null ? title : '$title, $detail',
    excludeSemantics: true,
    child: Material(
      color: CureandoTheme.blue,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink.image(
        image: const AssetImage('assets/welcome/campaign-pattern.png'),
        fit: BoxFit.cover,
        child: InkWell(
          onTap:
              onTap ?? () => context.push<void>('/inicio/actividades/$route'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: featured ? 146 : 122),
            child: Padding(
              padding: EdgeInsets.all(featured ? 14 : 6),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    sticker.contains('/')
                        ? sticker
                        : 'assets/home/info/stickers/sticker_$sticker.png',
                    width: featured ? 112 : 48,
                    height: featured ? 108 : 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: featured ? 20 : 14,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (detail != null && !featured) ...<Widget>[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              detail!,
                              style: const TextStyle(
                                color: CureandoTheme.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (featured) ...<Widget>[
                          const SizedBox(height: 6),
                          const Text(
                            'Uní piezas para ayudar',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text(
                                'Jugar ›',
                                style: TextStyle(
                                  color: CureandoTheme.blue,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ),
      ),
    ),
  );
}
