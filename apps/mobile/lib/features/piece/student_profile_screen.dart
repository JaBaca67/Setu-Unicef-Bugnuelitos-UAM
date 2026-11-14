import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../home/learning_progress.dart';
import '../school_access/school_access_screen.dart' show SchoolCrest;
import '../school_access/student_session.dart';
import 'piece_editor_screen.dart';
import 'student_piece.dart';

const Color _line = Color(0xFFCBD5E1);
const TextStyle _label = TextStyle(
  fontSize: 15,
  height: 1.3,
  color: CureandoTheme.secondaryInk,
);

String _days(int count) => count == 1 ? '1 día' : '$count días';

/// «Mi perfil» (`/inicio/pieza`): la pieza con su apodo, el colegio activo,
/// el nivel de aprendizaje y la personalización de la pieza. No pide nombre
/// real, correo ni foto: todo vive cifrado en este teléfono.
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.session,
    required this.progress,
    this.random,
  });

  final StudentSession session;
  final LearningProgress progress;
  final math.Random? random;

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late StudentPiece _draft = widget.session.piece.value;
  late final TextEditingController _nickname = TextEditingController(
    text: _draft.nickname,
  );
  bool _editing = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    widget.progress.open();
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _show({required bool editing}) => setState(() {
    _editing = editing;
    if (editing) {
      _saved = false;
      _draft = widget.session.piece.value;
      _nickname.text = _draft.nickname;
    }
  });

  void _save() {
    final StudentPiece piece = _draft.copyWith(
      nickname: StudentPiece.cleanNickname(_nickname.text),
    );
    widget.session.piece.value = piece;
    FocusScope.of(context).unfocus();
    setState(() {
      _draft = piece;
      _editing = false;
      _saved = true;
    });
  }

  Future<void> _leaveSchool() async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialog) => AlertDialog(
            title: const Text('¿Salir de este colegio?'),
            content: const Text(
              'Vas a volver a la bienvenida y, para entrar de nuevo, vas a '
              'necesitar el código de un colegio. Tu pieza, tu racha y tus '
              'XP se quedan guardados en este teléfono.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialog).pop(true),
                child: const Text('Salir del colegio'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || !mounted) return;
    widget.session.leaveSchool();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) => FlowScaffold(
    header: const FlowHeader(
      title: 'Mi perfil',
      subtitle: 'Sin nombre real, correo ni foto.',
    ),
    bottom: _editing
        ? FilledButton(
            style: flowPrimaryStyle(),
            onPressed: _save,
            child: const Text('Guardar mi pieza'),
          )
        : null,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: PieceTabButton(
                label: 'Resumen',
                selected: !_editing,
                onTap: () => _show(editing: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PieceTabButton(
                label: 'Mi pieza',
                selected: _editing,
                onTap: () => _show(editing: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_editing) ..._editor() else ..._summary(),
      ],
    ),
  );

  List<Widget> _editor() => <Widget>[
    const Text(
      'Apodo de tu pieza',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 8),
    Semantics(
      label: 'Apodo de tu pieza',
      child: TextField(
        controller: _nickname,
        maxLength: StudentPiece.maxNickname,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(StudentPiece.maxNickname),
        ],
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Ej. Pulgin Valiente (no uses tu nombre real)',
          hintStyle: const TextStyle(
            color: Color(0xFF5F6F8A),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          helperText:
              'Es un nombre de juego. Si pedís apoyo, el equipo de escucha '
              'lo ve junto a tu pieza.',
          helperMaxLines: 3,
          helperStyle: _label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    const SizedBox(height: 16),
    PieceEditorPanel(
      piece: _draft,
      random: widget.random,
      onChanged: (StudentPiece piece) => setState(() => _draft = piece),
    ),
  ];

  List<Widget> _summary() => <Widget>[
    if (_saved) ...<Widget>[
      Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CureandoTheme.greenSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline_rounded,
                color: CureandoTheme.ink,
              ),
              SizedBox(width: 10),
              Expanded(child: Text('Pieza guardada en este teléfono.')),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
    ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.session,
        widget.session.piece,
      ]),
      builder: (BuildContext context, _) => _IdentityCard(
        piece: widget.session.piece.value,
        school: widget.session.school,
      ),
    ),
    const SizedBox(height: 14),
    ListenableBuilder(
      listenable: widget.progress,
      builder: (BuildContext context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _LevelCard(progress: widget.progress),
          const SizedBox(height: 12),
          _Stats(progress: widget.progress),
        ],
      ),
    ),
    const SizedBox(height: 18),
    OutlinedButton.icon(
      style: flowSecondaryStyle(),
      onPressed: () => _show(editing: true),
      icon: const Icon(Icons.edit_rounded),
      label: const Text('Personalizar mi pieza'),
    ),
    if (widget.session.school != null) ...<Widget>[
      const SizedBox(height: 8),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: _leaveSchool,
        child: const Text(
          'Cambiar o salir del colegio',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  ];
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.piece, required this.school});

  final StudentPiece piece;
  final ConfirmedSchool? school;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFDCEEFC), Color(0xFFC4E1F9)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFB9D8F5)),
    ),
    child: Column(
      children: <Widget>[
        Semantics(
          image: true,
          label: 'Tu pieza: ${piece.description}',
          child: PieceFigure(piece: piece, height: 170, sparks: true),
        ),
        const SizedBox(height: 10),
        Text(
          piece.nickname,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SchoolCrest(school: school, size: 40),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  school == null
                      ? 'Sin colegio confirmado'
                      : '${school!.displayName} · ${school!.municipality}',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.progress});

  final LearningProgress progress;

  @override
  Widget build(BuildContext context) {
    const int goal = LearningProgress.xpPerLevel;
    final int current = progress.levelXp;
    final String title = 'Nivel ${progress.level} · ${progress.levelTitle}';
    final String amount = '$current / $goal XP';
    final String missing =
        'Te faltan ${goal - current} XP para el nivel ${progress.level + 1}.';
    return Semantics(
      container: true,
      label: '$title. $amount. $missing',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CureandoTheme.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: current / goal,
                  minHeight: 14,
                  color: CureandoTheme.blue,
                  backgroundColor: CureandoTheme.blueSoft,
                ),
              ),
              const SizedBox(height: 8),
              Text(missing, style: _label),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.progress});

  final LearningProgress progress;

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String, String)> items = <(IconData, String, String)>[
      (
        Icons.local_fire_department_rounded,
        'Racha actual',
        _days(progress.streak),
      ),
      (Icons.emoji_events_rounded, 'Mejor racha', _days(progress.bestStreak)),
      (Icons.bolt_rounded, 'XP total', '${progress.xp} XP'),
      (
        Icons.menu_book_rounded,
        'Actividades y lecturas',
        '${progress.completedCount}',
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Con letra grande las tarjetas pasan a una sola columna.
        final bool single = MediaQuery.textScalerOf(context).scale(16) > 22;
        final double width = single
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final (IconData icon, String label, String value) in items)
              SizedBox(
                width: width,
                child: Semantics(
                  container: true,
                  label: '$label: $value',
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CureandoTheme.blueSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(icon, color: CureandoTheme.blue, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(label, style: _label),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
