import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
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

/// Pregunta del día de muestra. Pregunta sobre el contenido de la guía,
/// nunca sobre experiencias personales.
class DailyQuestionCard extends StatefulWidget {
  const DailyQuestionCard({super.key});

  @override
  State<DailyQuestionCard> createState() => _DailyQuestionCardState();
}

class _DailyQuestionCardState extends State<DailyQuestionCard> {
  static const String _question =
      'Según la guía «Entendé tus emociones», ¿cuál de estas ideas es cierta?';
  static const List<(String, bool)> _options = <(String, bool)>[
    ('Todas las emociones son válidas; lo importante es cómo las expresamos.', true),
    ('Hay emociones malas que es mejor esconder siempre.', false),
    ('Sentir miedo significa que algo anda mal con vos.', false),
  ];

  int? _selected;
  bool get _answeredWell => _selected != null && _options[_selected!].$2;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.quiz_outlined, color: CureandoTheme.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          'Pregunta del día',
                          style: textTheme.titleMedium,
                        ),
                      ),
                      const ExampleXpTag(text: '+10 XP'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(_question),
            const SizedBox(height: 12),
            for (int index = 0; index < _options.length; index++) ...<Widget>[
              _OptionButton(
                text: _options[index].$1,
                selected: _selected == index,
                correct: _options[index].$2,
                answered: _selected != null,
                onPressed: _answeredWell
                    ? null
                    : () => setState(() => _selected = index),
              ),
              const SizedBox(height: 8),
            ],
            Semantics(
              liveRegion: true,
              child: Text(
                switch (_selected) {
                  null => 'Es sobre lo que dice la guía, no sobre tu vida '
                      'personal. Podés leerla antes de responder.',
                  _ when _answeredWell =>
                    '¡Así es! Sumaste 10 XP de ejemplo en esta demostración.',
                  _ => 'Esa no es la idea de la guía. Releela y probá de '
                      'nuevo: nada se descuenta.',
                },
                style: TextStyle(
                  color: _answeredWell
                      ? const Color(0xFF057634)
                      : CureandoTheme.secondaryInk,
                  fontWeight: _selected == null ? null : FontWeight.w600,
                ),
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
    return Card(
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
                    child: Text('Dado de emociones', style: textTheme.titleMedium),
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
              label: Text(emotion == null ? 'Lanzar el dado' : 'Lanzar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de XP de ejemplo: la gamificación de la demo no representa
/// progreso real y solo acompaña actividades educativas voluntarias.
class ExampleXpTag extends StatelessWidget {
  const ExampleXpTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$text, valor de ejemplo',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CureandoTheme.yellowSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$text · ejemplo',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Pantalla de actividades (pestaña Actividades). Solo actividades educativas
/// voluntarias; ninguna pide experiencias personales ni envía datos.
class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SampleBanner(text: 'Actividades de muestra'),
      const SizedBox(height: 12),
      const Text(
        'Actividades voluntarias para aprender sobre emociones y convivencia. '
        'La racha y los XP son valores de ejemplo y nunca condicionan pedir '
        'apoyo ni usar la app.',
      ),
      const SizedBox(height: 16),
      const DailyQuestionCard(),
      const SizedBox(height: 4),
      const EmotionDiceCard(),
      const SizedBox(height: 4),
      Card(
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
