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
                Image.asset(
                  'assets/home/dado-de-emociones.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
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
                            _DiceEmotionFace(emotionName: emotion.name),
                            const SizedBox(height: 8),
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

class _DiceEmotionFace extends StatelessWidget {
  const _DiceEmotionFace({required this.emotionName});

  final String emotionName;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 60,
    child: CustomPaint(painter: _DiceEmotionFacePainter(emotionName)),
  );
}

class _DiceEmotionFacePainter extends CustomPainter {
  const _DiceEmotionFacePainter(this.emotionName);

  final String emotionName;

  Color get _faceColor => switch (emotionName) {
    'Alegría' => CureandoTheme.yellow,
    'Enojo' => CureandoTheme.pink,
    'Calma' => CureandoTheme.green,
    'Sorpresa' => CureandoTheme.yellow,
    _ => CureandoTheme.blue,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset center = Offset(s / 2, s / 2);
    final double r = s * 0.46;
    const Color ink = Color(0xFF1D1D1B);

    canvas.drawCircle(center, r + 2, Paint()..color = Colors.white);
    canvas.drawCircle(center, r, Paint()..color = _faceColor);

    final bool lightFace =
        emotionName == 'Alegría' ||
        emotionName == 'Sorpresa' ||
        emotionName == 'Calma';
    final Color featureColor = lightFace ? ink : Colors.white;
    final Paint stroke = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;
    final Paint fill = Paint()..color = featureColor;

    final double eyeY = s * 0.42;
    final double leftX = s * 0.36;
    final double rightX = s * 0.64;

    if (emotionName == 'Calma') {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(leftX, eyeY), width: s * 0.14, height: s * 0.08),
        0,
        math.pi,
        false,
        stroke,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(rightX, eyeY), width: s * 0.14, height: s * 0.08),
        0,
        math.pi,
        false,
        stroke,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(leftX, eyeY), width: s * 0.11, height: s * 0.16),
        fill,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rightX, eyeY), width: s * 0.11, height: s * 0.16),
        fill,
      );
    }

    if (emotionName == 'Enojo') {
      canvas.drawLine(
        Offset(leftX - s * 0.07, eyeY - s * 0.14),
        Offset(leftX + s * 0.07, eyeY - s * 0.08),
        stroke,
      );
      canvas.drawLine(
        Offset(rightX + s * 0.07, eyeY - s * 0.14),
        Offset(rightX - s * 0.07, eyeY - s * 0.08),
        stroke,
      );
    } else if (emotionName == 'Miedo') {
      canvas.drawLine(
        Offset(leftX - s * 0.07, eyeY - s * 0.11),
        Offset(leftX + s * 0.06, eyeY - s * 0.15),
        stroke,
      );
      canvas.drawLine(
        Offset(rightX + s * 0.07, eyeY - s * 0.11),
        Offset(rightX - s * 0.06, eyeY - s * 0.15),
        stroke,
      );
    }

    switch (emotionName) {
      case 'Alegría':
      case 'Calma':
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.56),
            width: s * 0.34,
            height: s * 0.22,
          ),
          0.2,
          math.pi - 0.4,
          false,
          stroke,
        );
      case 'Tristeza':
      case 'Enojo':
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.72),
            width: s * 0.30,
            height: s * 0.18,
          ),
          math.pi + 0.25,
          math.pi - 0.5,
          false,
          stroke,
        );
      case 'Sorpresa':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.66),
            width: s * 0.15,
            height: s * 0.19,
          ),
          stroke,
        );
      case 'Miedo':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * 0.5, s * 0.67),
            width: s * 0.22,
            height: s * 0.12,
          ),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_DiceEmotionFacePainter oldDelegate) =>
      oldDelegate.emotionName != emotionName;
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
