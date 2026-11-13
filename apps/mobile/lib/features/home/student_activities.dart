import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_card.dart';
import 'learning_progress.dart';
import 'streak_screen.dart';
import 'student_resources.dart';

/// Emociones del dado, adaptadas del material impreso del equipo
/// («Dado Muestra»). La selección digital final queda pendiente de revisión
/// con el equipo de diseño.
@immutable
class DiceEmotion {
  const DiceEmotion(this.name, this.emoji, this.prompt, this.tint);

  final String name;
  final String emoji;
  final String prompt;
  final Color tint;
}

const List<DiceEmotion> diceEmotions = <DiceEmotion>[
  DiceEmotion(
    'Alegría',
    '😄',
    'Pensá: ¿cómo se nota la alegría en la cara y en el cuerpo?',
    CureandoTheme.yellowSoft,
  ),
  DiceEmotion(
    'Tristeza',
    '😢',
    'Pensá: ¿qué puede ayudar a una persona cuando está triste?',
    CureandoTheme.blueSoft,
  ),
  DiceEmotion(
    'Enojo',
    '😠',
    'Pensá: ¿qué se puede hacer con el enojo sin lastimar a nadie?',
    CureandoTheme.pinkSoft,
  ),
  DiceEmotion(
    'Miedo',
    '😨',
    'Pensá: ¿para qué sirve el miedo? ¿Cuándo conviene pedir compañía?',
    CureandoTheme.blueSoft,
  ),
  DiceEmotion(
    'Sorpresa',
    '😮',
    'Pensá: ¿en qué se parecen la sorpresa y el susto? ¿En qué cambian?',
    CureandoTheme.yellowSoft,
  ),
  DiceEmotion(
    'Calma',
    '😌',
    'Pensá: ¿qué te ayuda a volver a la calma? Respirar lento es un inicio.',
    CureandoTheme.greenSoft,
  ),
];

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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const Icon(Icons.quiz_outlined, color: CureandoTheme.blue),
                Semantics(
                  header: true,
                  child: Text(
                    'Pregunta del día',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
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

/// Dado de emociones digital, adaptado del material del equipo. Invita a
/// reconocer emociones; no registra respuestas ni genera puntajes emocionales.
class EmotionDiceCard extends StatefulWidget {
  const EmotionDiceCard({super.key, this.random});

  final math.Random? random;

  @override
  State<EmotionDiceCard> createState() => _EmotionDiceCardState();
}

class _EmotionDiceCardState extends State<EmotionDiceCard> {
  late final math.Random _random = widget.random ?? math.Random();
  DiceEmotion? _emotion;

  void _roll() => setState(
    () => _emotion = diceEmotions[_random.nextInt(diceEmotions.length)],
  );

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final DiceEmotion? emotion = _emotion;
    return SetuCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.casino_outlined, color: CureandoTheme.pink),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Dado de emociones',
                      style: textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Adaptación de muestra del dado impreso del equipo. Lanzalo y '
              'pensá cómo se ve esa emoción. Nada de lo que pienses se guarda.',
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: emotion == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey<String>(emotion.name),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: emotion.tint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Semantics(
                        liveRegion: true,
                        label: 'Salió ${emotion.name}. ${emotion.prompt}',
                        excludeSemantics: true,
                        child: Column(
                          children: <Widget>[
                            Text(
                              emotion.emoji,
                              style: const TextStyle(fontSize: 42),
                            ),
                            const SizedBox(height: 6),
                            Text(emotion.name, style: textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(emotion.prompt, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
            ),
            if (emotion != null) const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _roll,
              icon: const Icon(Icons.casino_outlined),
              label: Text(
                emotion == null ? 'Lanzar el dado' : 'Lanzar de nuevo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de actividades (pestaña Actividades). Solo actividades educativas
/// voluntarias; ninguna pide experiencias personales ni envía datos.
class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key, required this.progress, this.diceKey});

  final LearningProgress progress;
  final Key? diceKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SampleBanner(text: 'Actividades de muestra'),
      const SizedBox(height: 12),
      const Text(
        'Actividades voluntarias para aprender sobre emociones y convivencia.',
      ),
      const SizedBox(height: 16),
      ListenableBuilder(
        listenable: progress,
        builder: (context, child) {
          if (!progress.ready) {
            return LearningProgressStatus(progress: progress);
          }
          return DailyQuestionCard(
            key: ValueKey<DateTime>(progress.today),
            progress: progress,
            day: progress.today,
          );
        },
      ),
      const SizedBox(height: 8),
      EmotionDiceCard(key: diceKey),
      const SizedBox(height: 8),
      SetuCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Más actividades del equipo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'El equipo diseñó otros materiales impresos (como el semáforo '
                'de emociones) que todavía están en adaptación digital.',
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
