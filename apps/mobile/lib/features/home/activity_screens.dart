import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import 'puzzle_board.dart';

export 'puzzle_board.dart'
    show PuzzleBoard, PuzzleBoardState, PuzzleOptionPiece;
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_nav.dart';
import 'learning_progress.dart';
import 'streak_screen.dart';
import 'student_activities.dart';

const _stickers = 'assets/home/info/stickers/';
const _sky = Color(0xFFE5EFFF);
const _heading = TextStyle(
  fontSize: 24,
  height: 1.25,
  fontWeight: FontWeight.w700,
);

void _finish(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/inicio', extra: HomeSectionRequest(HomeSection.actividades));
  }
}

/// El patrón lo aporta CampaignScreen; el sticker es una capa transparente.
class ActivityHeader extends StatelessWidget {
  const ActivityHeader({super.key, required this.title, required this.sticker});
  final String title;
  final String sticker;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => _finish(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                label: const Text(
                  'Actividades',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: _heading.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          '${_stickers}sticker_$sticker.png',
          width: 112,
          height: 128,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ],
    ),
  );
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({
    required this.title,
    required this.sticker,
    required this.children,
  });
  final String title;
  final String sticker;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CampaignScreen(
    header: ActivityHeader(title: title, sticker: sticker),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

Widget _primary(String label, VoidCallback? onPressed) => FilledButton(
  style: flowPrimaryStyle().copyWith(
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),
  ),
  onPressed: onPressed,
  child: Text(label),
);

ButtonStyle _secondaryStyle() => OutlinedButton.styleFrom(
  foregroundColor: CureandoTheme.blue,
  side: const BorderSide(color: Color(0xFFBFD6FF), width: 1.5),
  minimumSize: const Size(48, 50),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
    fontSize: 15,
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
);

Widget _message(Widget child, {Color color = _sky}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(20),
  ),
  child: child,
);

class TrafficLightScreen extends StatefulWidget {
  const TrafficLightScreen({super.key});
  @override
  State<TrafficLightScreen> createState() => _TrafficLightScreenState();
}

class _TrafficLightScreenState extends State<TrafficLightScreen> {
  int? _selected;
  static const choices = <(String, String, String, Color, String)>[
    (
      'Rojo',
      'Necesito una pausa',
      'roja',
      Color(0xFFFFE8EF),
      'Respirá hondo tres veces y buscá un lugar tranquilo.',
    ),
    (
      'Amarillo',
      'Quiero entender qué siento',
      'amarilla',
      Color(0xFFFFF7DA),
      'Probá ponerle un nombre a lo que sentís.',
    ),
    (
      'Verde',
      'Me siento en calma',
      'verde',
      Color(0xFFE0F6DF),
      '¡Qué bien! Fijate qué te ayudó a sentirte así.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Semáforo de emociones',
    sticker: 'semaforo',
    children: <Widget>[
      const Text('¿Cómo te sentís hoy?', style: _heading),
      const SizedBox(height: 16),
      const Text('Tocá el color que más se acerque a lo que sentís.'),
      const SizedBox(height: 16),
      for (int i = 0; i < choices.length; i++) ...<Widget>[
        Semantics(
          button: true,
          selected: _selected == i,
          child: Material(
            color: choices[i].$4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _selected == i ? CureandoTheme.blue : Colors.transparent,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() => _selected = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      '${_stickers}sticker_cara_${choices[i].$3}.png',
                      width: 58,
                      height: 58,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            choices[i].$1,
                            style: _heading.copyWith(fontSize: 21),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            choices[i].$2,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _selected == i
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selected == i
                          ? CureandoTheme.blue
                          : Colors.blueGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (_selected != null) ...<Widget>[
        Semantics(
          liveRegion: true,
          child: _message(
            Row(
              children: <Widget>[
                const Icon(Icons.lightbulb, color: Color(0xFF967500), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choices[_selected!].$5,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      _primary('Listo', () => _finish(context)),
    ],
  );
}

@immutable
class DiceEmotion {
  const DiceEmotion(this.name, this.prompt);
  final String name;
  final String prompt;
}

const diceEmotions = <DiceEmotion>[
  DiceEmotion('Calma', '¿Qué te ayuda a volver a la calma?'),
  DiceEmotion('Alegría', '¿Qué te hizo sonreír hoy?'),
  DiceEmotion('Tristeza', '¿Con quién podés hablar cuando estás triste?'),
  DiceEmotion('Enojo', '¿Qué hacés para calmarte cuando te enojás?'),
  DiceEmotion('Miedo', '¿Qué te ayuda a sentirte seguro o segura?'),
  DiceEmotion('Sorpresa', '¿Qué cosa nueva aprendiste esta semana?'),
];

class EmotionDiceScreen extends StatefulWidget {
  const EmotionDiceScreen({super.key, this.random});
  final math.Random? random;
  @override
  State<EmotionDiceScreen> createState() => _EmotionDiceScreenState();
}

class _EmotionDiceScreenState extends State<EmotionDiceScreen>
    with SingleTickerProviderStateMixin {
  late final math.Random _random = widget.random ?? math.Random();
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  DiceEmotion? _emotion;
  bool _rolling = false;

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() {
      _rolling = true;
      _emotion = null;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _animation.forward(from: 0).orCancel.catchError((Object _) {});
    }
    if (!mounted) return;
    setState(() {
      _emotion = diceEmotions[_random.nextInt(diceEmotions.length)];
      _rolling = false;
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Dados emocionales',
    sticker: 'dado',
    children: <Widget>[
      const Text('¿Qué emoción saldrá?', style: _heading),
      const SizedBox(height: 16),
      const Text('Lanzá el dado y descubrí una emoción.'),
      const SizedBox(height: 16),
      Container(
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF9CCBFF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              bottom: 28,
              child: Container(
                width: 150,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0x44004099),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x44004099), blurRadius: 14),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Transform.rotate(
                angle: _rolling ? _animation.value * math.pi * 4 : 0,
                child: Transform.scale(
                  scale: _rolling
                      ? 1 - .16 * math.sin(_animation.value * math.pi)
                      : 1,
                  child: child,
                ),
              ),
              child: Image.asset(
                '${_stickers}sticker_dado.png',
                width: 210,
                height: 210,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _primary(
        _rolling
            ? 'Lanzando…'
            : _emotion == null
            ? 'Lanzar el dado'
            : 'Volver a lanzar',
        _rolling ? null : _roll,
      ),
      const SizedBox(height: 14),
      const Text(
        'Después, pensá en lo que te salió.',
        textAlign: TextAlign.center,
      ),
      if (_emotion case final emotion?) ...<Widget>[
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: _message(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Te salió: ${emotion.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(emotion.prompt),
              ],
            ),
            color: CureandoTheme.greenSoft,
          ),
        ),
      ],
    ],
  );
}

const freeQuestions = <String>[
  '¿Qué te hace sentir parte de un grupo?',
  '¿Qué te gusta hacer con tus amistades?',
  '¿Qué te ayuda cuando tenés un mal día?',
  '¿Qué te hace sentir orgullo de vos?',
  '¿A quién le darías las gracias hoy?',
  '¿Qué lugar de tu escuela te gusta más?',
  '¿Cómo podés ayudar a alguien que está solo?',
  '¿Qué te hace reír?',
];

class FreeQuestionScreen extends StatefulWidget {
  const FreeQuestionScreen({super.key});
  @override
  State<FreeQuestionScreen> createState() => _FreeQuestionScreenState();
}

class _FreeQuestionScreenState extends State<FreeQuestionScreen> {
  final TextEditingController _answer = TextEditingController();
  int _question = 0;
  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Pregunta libre',
    sticker: 'pregunta',
    children: <Widget>[
      _message(
        Column(
          children: <Widget>[
            const Icon(Icons.sms_rounded, color: CureandoTheme.blue, size: 36),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                freeQuestions[_question],
                textAlign: TextAlign.center,
                style: _heading.copyWith(color: CureandoTheme.blue),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Center(
        child: OutlinedButton.icon(
          style: _secondaryStyle(),
          onPressed: () => setState(() {
            _question = (_question + 1) % freeQuestions.length;
            _answer.clear();
          }),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Otra pregunta'),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Tu respuesta (opcional)',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _answer,
        minLines: 4,
        maxLines: 8,
        maxLength: 2000,
        enableIMEPersonalizedLearning: false,
        autocorrect: false,
        decoration: const InputDecoration(
          hintText: 'Escribí acá si querés…',
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Row(
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Podés pensarlo sin escribir. Lo que escribís queda solo durante la actividad.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _primary('Terminar', () => _finish(context)),
    ],
  );
}

@immutable
class DrawingStroke {
  const DrawingStroke(this.color, this.points);
  final Color color;
  final List<Offset> points;
}

class FreeDrawingScreen extends StatefulWidget {
  const FreeDrawingScreen({super.key});
  @override
  State<FreeDrawingScreen> createState() => _FreeDrawingScreenState();
}

class _FreeDrawingScreenState extends State<FreeDrawingScreen> {
  static const colors = <Color>[
    Color(0xFF0F172A),
    CureandoTheme.blue,
    CureandoTheme.pink,
    CureandoTheme.yellow,
    CureandoTheme.green,
  ];
  final List<DrawingStroke> _strokes = <DrawingStroke>[];
  Color _color = colors.first;

  void _add(Offset point) => setState(() {
    final DrawingStroke last = _strokes.removeLast();
    _strokes.add(DrawingStroke(last.color, <Offset>[...last.points, point]));
  });

  Future<void> _clear() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar todo el dibujo?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) setState(_strokes.clear);
  }

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Dibujo libre',
    sticker: 'dibujo',
    children: <Widget>[
      const Text(
        'Dibujá lo que querás.',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      Semantics(
        label: 'Lienzo para dibujar con el dedo',
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFBFD6FF), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          // El lienzo gana el gesto apenas se toca: así un trazo vertical
          // dibuja en lugar de desplazar la pantalla.
          child: RawGestureDetector(
            key: const ValueKey<String>('drawing-canvas'),
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              _EagerPanRecognizer:
                  GestureRecognizerFactoryWithHandlers<_EagerPanRecognizer>(
                    _EagerPanRecognizer.new,
                    (_EagerPanRecognizer r) {
                      r.onStart = (DragStartDetails details) {
                        setState(
                          () => _strokes.add(
                            DrawingStroke(_color, <Offset>[
                              details.localPosition,
                            ]),
                          ),
                        );
                      };
                      r.onUpdate = (DragUpdateDetails details) {
                        _add(details.localPosition);
                      };
                    },
                  ),
            },
            child: CustomPaint(
              painter: DrawingPainter(List<DrawingStroke>.of(_strokes)),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFBFD6FF)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            for (int i = 0; i < colors.length; i++)
              Semantics(
                selected: _color == colors[i],
                child: IconButton(
                  tooltip: <String>[
                    'Negro',
                    'Azul',
                    'Rosa',
                    'Amarillo',
                    'Verde',
                  ][i],
                  onPressed: () => setState(() => _color = colors[i]),
                  icon: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == colors[i]
                            ? CureandoTheme.ink
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _color == colors[i]
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: i == 3 ? CureandoTheme.ink : Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          OutlinedButton.icon(
            style: _secondaryStyle(),
            onPressed: _strokes.isEmpty
                ? null
                : () => setState(_strokes.removeLast),
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Deshacer'),
          ),
          OutlinedButton.icon(
            style: _secondaryStyle(),
            onPressed: _strokes.isEmpty ? null : _clear,
            icon: const Icon(Icons.auto_fix_normal),
            label: const Text('Borrador'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _primary('Terminar', () => _finish(context)),
    ],
  );
}

class DrawingPainter extends CustomPainter {
  const DrawingPainter(this.strokes);
  final List<DrawingStroke> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    for (final DrawingStroke stroke in strokes) {
      final Paint paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          4,
          Paint()..color = stroke.color,
        );
      } else {
        canvas.drawPoints(ui.PointMode.polygon, stroke.points, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}

const _scenes = <(String, String, String, int, String)>[
  (
    'En el recreo, alguien se queda sin grupo.',
    'Invitarle a jugar',
    'Seguir jugando',
    0,
    'Una invitación puede hacerle sentir parte del grupo.',
  ),
  (
    'En clase, alguien se equivoca y el grupo se ríe.',
    'Reírme con el grupo',
    'Preguntarle si quiere ayuda',
    1,
    'Ofrecer ayuda con respeto puede acompañarle.',
  ),
  (
    'En el chat del grupo, se burlan de alguien.',
    'Pedir ayuda a una persona adulta',
    'Reenviar la burla',
    0,
    'Buscar apoyo puede ayudar a detener la burla.',
  ),
];
const _retry = <String>[
  'A veces no nos damos cuenta de quién queda fuera. Invitarle puede ayudar.',
  'La risa puede doler aunque no sea nuestra intención. Podemos ofrecer ayuda.',
  'Compartir la burla puede hacerla llegar a más personas. Podemos buscar apoyo.',
];

/// Composición aislada para la siguiente pasada gráfica; no decide respuestas.
class KindnessPuzzleScreen extends StatefulWidget {
  const KindnessPuzzleScreen({super.key});
  @override
  State<KindnessPuzzleScreen> createState() => _KindnessPuzzleScreenState();
}

class _KindnessPuzzleScreenState extends State<KindnessPuzzleScreen> {
  int _scene = 0;
  int? _selected;
  bool _done = false;
  bool get _correct => _selected == _scenes[_scene].$4;

  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Rompecabezas del buen trato',
    sticker: 'rompecabezas',
    children: <Widget>[
      if (_done) ...<Widget>[
        const Text(
          '¡Completaste el rompecabezas!',
          style: _heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Image.asset(
          '${_stickers}sticker_rompecabezas.png',
          height: 180,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 20),
        const Text('Cada gesto de buen trato puede ayudar a alguien.'),
        const SizedBox(height: 20),
        _primary('Volver a Actividades', () => _finish(context)),
      ] else ...<Widget>[
        Text(
          '${_scene + 1} de 3',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i <= _scene ? CureandoTheme.blue : _sky,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _message(
          Text(
            _scenes[_scene].$1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '¿Qué pieza puede ayudar?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        PuzzleBoard(
          state: _correct
              ? PuzzleBoardState.connected
              : PuzzleBoardState.disconnected,
          pieceColor: _scenes[_scene].$4 == 0
              ? CureandoTheme.yellow
              : CureandoTheme.green,
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < 2; i++) ...<Widget>[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(12),
              backgroundColor: _selected == i ? _sky : Colors.white,
              side: BorderSide(
                color: _selected == i
                    ? CureandoTheme.blue
                    : const Color(0xFFBFD6FF),
                width: 2,
              ),
            ),
            onPressed: _correct ? null : () => setState(() => _selected = i),
            child: Row(
              children: <Widget>[
                PuzzleOptionPiece(
                  color: i == 0 ? CureandoTheme.yellow : CureandoTheme.green,
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    i == 0 ? _scenes[_scene].$2 : _scenes[_scene].$3,
                    style: const TextStyle(
                      color: CureandoTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_selected != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: _message(
              Text(
                _correct
                    ? '¡Encajó! ${_scenes[_scene].$5}'
                    : '${_retry[_scene]} Probá otra pieza',
              ),
              color: _correct
                  ? CureandoTheme.greenSoft
                  : CureandoTheme.yellowSoft,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _primary(
          'Siguiente escena',
          _correct
              ? () => setState(() {
                  if (_scene == 2) {
                    _done = true;
                  } else {
                    _scene++;
                    _selected = null;
                  }
                })
              : null,
        ),
      ],
    ],
  );
}

/// Conserva las reglas y el almacenamiento de la pregunta educativa diaria.
class DailyQuestionScreen extends StatelessWidget {
  const DailyQuestionScreen({super.key, required this.progress});
  final LearningProgress progress;
  @override
  Widget build(BuildContext context) => _ActivityPage(
    title: 'Pregunta del día',
    sticker: 'pregunta',
    children: <Widget>[
      ListenableBuilder(
        listenable: progress,
        builder: (context, _) => progress.ready
            ? DailyQuestionCard(
                key: ValueKey<DateTime>(progress.today),
                progress: progress,
                day: progress.today,
              )
            : LearningProgressStatus(progress: progress),
      ),
    ],
  );
}

/// Reconocedor de arrastre que acepta el gesto de inmediato para que el
/// lienzo no compita con el desplazamiento de la página.
class _EagerPanRecognizer extends PanGestureRecognizer {
  _EagerPanRecognizer() : super(debugOwner: null);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
