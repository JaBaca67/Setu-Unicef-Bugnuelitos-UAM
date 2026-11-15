import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_nav.dart';
import '../home/learning_progress.dart';
import '../school_access/school_access_screen.dart' show SchoolCrest;
import '../school_access/student_session.dart';
import 'piece_editor_screen.dart';
import 'piece_stage.dart';
import 'student_piece.dart';

const Color _line = Color(0xFFCBD5E1);
const TextStyle _label = TextStyle(
  fontSize: 15,
  height: 1.3,
  color: CureandoTheme.secondaryInk,
);

String _days(int count) => count == 1 ? '1 día' : '$count días';

/// «Mi perfil» (`/inicio/pieza`): la pieza en su escenario, su nombre de juego,
/// los accesorios que lleva, el progreso de aprendizaje y el colegio activo.
/// No pide nombre real, correo ni foto: todo vive cifrado en este teléfono.
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.session,
    required this.progress,
  });

  final StudentSession session;
  final LearningProgress progress;

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _saved = false;
  bool _schoolExpanded = false;

  @override
  void initState() {
    super.initState();
    widget.progress.open();
  }

  Future<void> _openEditor(PieceEditorTab tab) async {
    if (_saved) setState(() => _saved = false);
    final bool? saved = await context.push<bool>(
      '/inicio/pieza/editar?pestana=${tab.query}',
    );
    if (mounted && saved == true) {
      setState(() => _saved = true);
    }
  }

  Future<void> _openStreak() async {
    final bool? openActivities = await context.push<bool>('/inicio/racha');
    if (mounted && openActivities == true) {
      context.go('/inicio', extra: HomeSectionRequest(HomeSection.actividades));
    }
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
    header: const FlowHeader(title: 'Mi perfil', trailing: _HeaderBrand()),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
          listenable: widget.session.piece,
          builder: (BuildContext context, _) {
            final StudentPiece piece = widget.session.piece.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PieceStage(
                  piece: piece,
                  figureHeight: 154,
                  label: 'Nombre de mi pieza',
                  name: PieceNamePill(
                    name: piece.displayName,
                    onTap: piece.displayName == null
                        ? () => _openEditor(PieceEditorTab.name)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: flowPrimaryStyle(),
                  onPressed: () => _openEditor(PieceEditorTab.shape),
                  child: const Text('Personalizar mi pieza'),
                ),
                const SizedBox(height: 14),
                _EquippedSection(
                  accessories: piece.accessories,
                  onOpenAccessories: () =>
                      _openEditor(PieceEditorTab.accessories),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: widget.progress,
          builder: (BuildContext context, _) => _LearningCard(
            progress: widget.progress,
            onOpenStreak: _openStreak,
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: widget.session,
          builder: (BuildContext context, _) => _SchoolSettingsCard(
            school: widget.session.school,
            expanded: _schoolExpanded,
            onToggle: () =>
                setState(() => _schoolExpanded = !_schoolExpanded),
            onLeave: _leaveSchool,
          ),
        ),
      ],
    ),
  );
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/welcome/setu-symbol-white.png',
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 6),
        const Text(
          'SéTú',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _EquippedSection extends StatelessWidget {
  const _EquippedSection({
    required this.accessories,
    required this.onOpenAccessories,
  });

  final Set<PieceAccessory> accessories;
  final VoidCallback onOpenAccessories;

  static Color _tintFor(PieceAccessory accessory) => switch (accessory) {
    PieceAccessory.cap => CureandoTheme.yellowSoft,
    PieceAccessory.glasses => CureandoTheme.blueSoft,
    PieceAccessory.bowTie => CureandoTheme.pinkSoft,
  };

  @override
  Widget build(BuildContext context) {
    final List<PieceAccessory> equipped = PieceAccessory.values
        .where(accessories.contains)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: const Text(
            'Lo que lleva',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: CureandoTheme.ink,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (equipped.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CureandoTheme.blueSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFB9D8F5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Tu pieza no lleva accesorios.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CureandoTheme.ink,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: flowSecondaryStyle(),
                  onPressed: onOpenAccessories,
                  child: const Text('Probar accesorios'),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool largeText =
                  MediaQuery.textScalerOf(context).scale(16) > 22;
              final int columns = largeText || equipped.length == 1 ? 1 : 2;
              final double itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final PieceAccessory accessory in equipped)
                    SizedBox(
                      width: itemWidth,
                      child: _EquippedTile(
                        accessory: accessory,
                        background: _tintFor(accessory),
                        onTap: onOpenAccessories,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _EquippedTile extends StatelessWidget {
  const _EquippedTile({
    required this.accessory,
    required this.background,
    required this.onTap,
  });

  final PieceAccessory accessory;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${accessory.fullLabel}. Tocá para cambiar accesorios.',
    excludeSemantics: true,
    child: Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Stack(
            children: <Widget>[
              const Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: CureandoTheme.blue,
                  child: Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      height: 54,
                      child: Center(
                        child: AccessoryFigure(
                          accessory: accessory,
                          width: accessory == PieceAccessory.bowTie ? 56 : 86,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      accessory.fullLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CureandoTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.progress, required this.onOpenStreak});

  final LearningProgress progress;
  final VoidCallback onOpenStreak;

  @override
  Widget build(BuildContext context) {
    const int goal = LearningProgress.xpPerLevel;
    final int current = progress.levelXp;
    final String streakLabel = 'Racha de ${_days(progress.streak)}';
    final String xpLabel = '${progress.xp} XP';
    final String levelLabel = 'Nivel ${progress.level} · ${progress.levelTitle}';
    final String semanticSummary =
        'Mi aprendizaje. $streakLabel. $xpLabel. $levelLabel. '
        '$current de $goal XP. '
        'Te faltan ${goal - current} XP para el nivel ${progress.level + 1}.';
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;

    return Container(
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
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              Semantics(
                header: true,
                child: const Text(
                  'Mi aprendizaje',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: CureandoTheme.ink,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenStreak,
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  foregroundColor: CureandoTheme.blue,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                label: const Text(
                  'Ver mi racha',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: semanticSummary,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (largeText) ...<Widget>[
                    _StatLine(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFF97316),
                      text: streakLabel,
                    ),
                    const SizedBox(height: 6),
                    _StatLine(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFACC15),
                      text: xpLabel,
                    ),
                  ] else
                    IntrinsicHeight(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: _StatLine(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: const Color(0xFFF97316),
                              text: streakLabel,
                              centered: true,
                            ),
                          ),
                          const VerticalDivider(
                            width: 12,
                            thickness: 1,
                            color: _line,
                          ),
                          Expanded(
                            flex: 2,
                            child: _StatLine(
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFACC15),
                              text: xpLabel,
                              centered: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: current / goal,
                      minHeight: 12,
                      color: CureandoTheme.green,
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    levelLabel,
                    textAlign: TextAlign.center,
                    style: _label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: CureandoTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.centered = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: centered
        ? MainAxisAlignment.center
        : MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, color: iconColor, size: 26),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: CureandoTheme.ink,
          ),
        ),
      ),
    ],
  );
}

class _SchoolSettingsCard extends StatelessWidget {
  const _SchoolSettingsCard({
    required this.school,
    required this.expanded,
    required this.onToggle,
    required this.onLeave,
  });

  final ConfirmedSchool? school;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          toggled: expanded,
          child: InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.settings_outlined,
                      color: CureandoTheme.blue,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mi colegio y ajustes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CureandoTheme.ink,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.chevron_right_rounded,
                      color: CureandoTheme.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded) ...<Widget>[
          const Divider(height: 1, color: _line),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SchoolCrest(school: school, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        school == null
                            ? 'Sin colegio confirmado'
                            : '${school!.displayName} · ${school!.municipality}',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: CureandoTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (school != null) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: flowSecondaryStyle(),
                    onPressed: onLeave,
                    child: const Text('Salir del colegio'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
