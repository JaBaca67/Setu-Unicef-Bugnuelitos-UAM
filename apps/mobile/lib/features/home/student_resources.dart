import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import '../../shared/widgets/setu_bottom_nav.dart';
import '../../shared/widgets/setu_dialog.dart';
import 'external_links.dart';
import 'info_artwork.dart';
import 'info_catalog.dart';
import 'learning_progress.dart';
import 'streak_screen.dart';

export 'info_catalog.dart';

const Color _border = Color(0xFFE1E6EF);
const Color _okInk = Color(0xFF067D30);

Future<void> _requestSchool(BuildContext context) => showSetuBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext sheet) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Para pedir apoyo, ingresá con el código de tu colegio.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Podés seguir leyendo sin código. Tus XP de aprendizaje son locales y no requieren una cuenta.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.pop(sheet);
              context.push<void>('/colegio');
            },
            child: const Text('Ingresar al colegio'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(sheet),
            child: const Text('Seguir leyendo'),
          ),
        ],
      ),
    ),
  ),
);

/// Recurso E11: adaptación con fuente visible o pregunta de cierre de ruta.
class ResourcePreviewScreen extends StatefulWidget {
  const ResourcePreviewScreen({
    super.key,
    required this.resourceId,
    required this.progress,
    this.publicEntry = false,
  });

  final String resourceId;
  final LearningProgress progress;
  final bool publicEntry;

  @override
  State<ResourcePreviewScreen> createState() => _ResourcePreviewScreenState();
}

class _ResourcePreviewScreenState extends State<ResourcePreviewScreen> {
  bool _saving = false;
  int? _selected;
  String? _message;

  @override
  void initState() {
    super.initState();
    widget.progress.open();
  }

  Future<void> _complete(InfoResource r) async {
    final LearningProgress p = widget.progress;
    if (_saving || !p.ready) return;
    if (r.isQuiz) {
      if (_selected != r.correct) return;
    } else if (!p.canCompleteResource(r.id)) {
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final int xp = r.isQuiz
          ? await p.completeRoute(routeOf(r.id)?.id ?? r.id)
          : await p.completeResource(r.id);
      if (!mounted) return;
      setState(
        () => _message = xp > 0
            ? 'Sumaste $xp XP.'
            : r.isQuiz
            ? 'Ya completaste esta ruta.'
            : 'Marcaste un día de aprendizaje.',
      );
    } on Object {
      if (mounted) {
        setState(() => _message = 'No se pudo guardar. Probá de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final InfoResource? r = infoResourceById(widget.resourceId);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Este recurso no está disponible.')),
      );
    }
    final InfoRoute? route = routeOf(r.id);
    final int step = route == null ? -1 : route.steps.indexOf(r.id) + 1;
    final String title = step > 0 && r.format != InfoFormat.guide
        ? '${r.format.label} · Paso $step de 3'
        : r.format.label;
    final int xp = r.isQuiz
        ? LearningProgress.routeQuizXp
        : LearningProgress.resourceXp;
    return ListenableBuilder(
      listenable: widget.progress,
      builder: (BuildContext context, _) => FlowScaffold(
        header: FlowHeader(
          title: title,
          trailing: _Pill(text: '+$xp XP', icon: Icons.add_rounded),
        ),
        bottom: _actions(context, r),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: r.isQuiz ? _quiz(r) : _content(r),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, InfoResource r) {
    final LearningProgress p = widget.progress;
    final bool done = r.isQuiz
        ? p.completedRoute(routeOf(r.id)?.id ?? r.id)
        : !p.canCompleteResource(r.id);
    final String label = r.isQuiz
        ? (done ? 'Ruta completada' : 'Completar ruta (3 de 3)')
        : done
        ? 'Lectura registrada'
        : p.completedResource(r.id)
        ? 'Marcar día de aprendizaje'
        : r.isVideo
        ? 'Marcar resumen leído (+5 XP)'
        : 'Marcar como leída (+5 XP)';
    final bool enabled =
        p.ready && !_saving && !done && (!r.isQuiz || _selected == r.correct);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_message != null || _saving)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _saving ? 'Guardando tu progreso…' : _message!,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () => showSourceSheet(
            context,
            resource: r,
            publicEntry: widget.publicEntry,
          ),
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text(
            'Fuente y revisión',
            style: TextStyle(decoration: TextDecoration.underline),
          ),
        ),
        if (!p.ready)
          LearningProgressStatus(progress: p)
        else
          FilledButton(
            style: _primary,
            onPressed: enabled ? () => _complete(r) : null,
            child: Text(label, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: _secondary,
          onPressed: () => widget.publicEntry
              ? _requestSchool(context)
              : context.push<void>('/inicio/apoyo'),
          child: const Text('Pedir apoyo'),
        ),
      ],
    );
  }

  void _goToHelp() => context.go(
    widget.publicEntry ? '/informacion' : '/inicio',
    extra: HomeSectionRequest(HomeSection.ayuda),
  );

  List<Widget> _content(InfoResource r) => <Widget>[
    if (r.bannerAsset != null) ...<Widget>[
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 358 / 128,
          child: InfoArtwork(asset: r.bannerAsset!, topic: r.topic),
        ),
      ),
      const SizedBox(height: 12),
    ],
    Semantics(
      header: true,
      child: Text(
        r.title,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
    ),
    const SizedBox(height: 4),
    Semantics(
      label: 'Resumen de ${r.organization}',
      excludeSemantics: true,
      child: Tooltip(
        message: r.organization,
        child: Text(
          'Resumen de ${r.organization}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: CureandoTheme.secondaryInk,
          ),
        ),
      ),
    ),
    const SizedBox(height: 12),
    if (r.isVideo) ...<Widget>[
      FilledButton.icon(
        onPressed: () => openExternalLink(context, r.url),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Ver video'),
      ),
      const Text('Video externo · Necesitás internet'),
      const SizedBox(height: 12),
    ],
    if (r.topic == InfoTopic.ansiedad ||
        r.topic == InfoTopic.depresion) ...<Widget>[
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CureandoTheme.yellowSoft,
          border: Border.all(color: CureandoTheme.blue),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Si estás en peligro o pensás en hacerte daño, hablá ya con un adulto de confianza.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(onPressed: _goToHelp, child: const Text('Ir a Ayuda')),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ],
    for (int i = 0; i < r.points.length; i++) ...<Widget>[
      _PointCard(point: r.points[i], story: false, panel: i),
      const SizedBox(height: 10),
    ],
    if (!r.isVideo)
      OutlinedButton.icon(
        onPressed: () => openExternalLink(context, r.url),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Ver fuente original'),
      ),
  ];

  List<Widget> _quiz(InfoResource r) {
    final bool done = widget.progress.completedRoute(routeOf(r.id)?.id ?? r.id);
    final int? selection = done ? r.correct : _selected;
    return <Widget>[
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CureandoTheme.blueSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFD3F7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                r.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${r.topic.label} · Escena ficticia (+${LearningProgress.routeQuizXp} XP)',
              style: const TextStyle(
                color: CureandoTheme.blue,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              r.caption!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (int i = 0; i < r.options.length; i++) ...<Widget>[
        _QuizOption(
          letter: String.fromCharCode(65 + i),
          text: r.options[i],
          state: selection != i
              ? null
              : i == r.correct
              ? true
              : false,
          onTap: done || _saving
              ? null
              : () => setState(() {
                  _selected = i;
                  _message = null;
                }),
        ),
        const SizedBox(height: 10),
      ],
      if (selection != null)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selection == r.correct
                ? CureandoTheme.greenSoft
                : CureandoTheme.yellowSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selection == r.correct
                  ? CureandoTheme.green
                  : CureandoTheme.blue,
            ),
          ),
          child: Text(
            r.optionFeedback[selection],
            style: TextStyle(
              color: selection == r.correct ? _okInk : CureandoTheme.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ];
  }
}

final ButtonStyle _primary = FilledButton.styleFrom(
  backgroundColor: CureandoTheme.blue,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(48),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

final ButtonStyle _secondary = OutlinedButton.styleFrom(
  foregroundColor: CureandoTheme.blue,
  minimumSize: const Size.fromHeight(46),
  side: const BorderSide(color: Color(0xFFA5C1EF), width: 1.5),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class _PointCard extends StatelessWidget {
  const _PointCard({required this.point, required this.story, this.panel = 0});
  final InfoPoint point;
  final bool story;
  final int panel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: story
          ? <Color>[
              CureandoTheme.yellowSoft,
              CureandoTheme.pinkSoft,
              CureandoTheme.greenSoft,
            ][panel % 3]
          : CureandoTheme.background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(point.icon, color: CureandoTheme.blue, size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!point.title.startsWith('Idea ')) ...<Widget>[
                Text(
                  point.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                point.body,
                style: const TextStyle(
                  color: CureandoTheme.secondaryInk,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });
  final String letter;
  final String text;
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = state == null
        ? _border
        : state!
        ? CureandoTheme.green
        : CureandoTheme.pink;
    return Material(
      color: state == true ? CureandoTheme.greenSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: state == null ? 1 : 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 15,
                backgroundColor: state == true
                    ? CureandoTheme.green
                    : CureandoTheme.background,
                child: state == true
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : Text(
                        letter,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
              if (state != null)
                Text(
                  state! ? 'Correcta' : 'Incorrecta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: state! ? _okInk : CureandoTheme.pink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// E11-F · Fuente consultada y revisión profesional pendiente.
Future<void> showSourceSheet(
  BuildContext context, {
  required InfoResource resource,
  bool publicEntry = false,
}) => showSetuBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext sheet) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Fuente y revisión',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: _Pill(
              text: 'Pendiente revisión profesional',
              ink: Colors.white,
              background: CureandoTheme.blue,
            ),
          ),
          const SizedBox(height: 12),
          for (final InfoPoint p in <InfoPoint>[
            InfoPoint(
              'Fuente',
              resource.isQuiz
                  ? routeOf(resource.id)!.steps
                        .take(2)
                        .map((String id) {
                          final InfoResource source = infoResourceById(id)!;
                          return '${source.organization}\n${source.url}';
                        })
                        .join('\n\n')
                  : '${resource.organization}\n${resource.url}',
              Icons.menu_book_outlined,
            ),
            const InfoPoint(
              'Adaptación',
              'Resumen simplificado por el equipo SéTú; no reemplaza la fuente original.',
              Icons.short_text_rounded,
            ),
            const InfoPoint(
              'Territorio y público',
              'Contenido de UNICEF/MINED; adaptado para estudiantes de Nicaragua',
              Icons.public_rounded,
            ),
            const InfoPoint(
              'Revisión editorial y fecha',
              'Verificado el 16 de noviembre de 2026 · Pendiente revisión profesional (Psicología)',
              Icons.check_rounded,
            ),
            const InfoPoint(
              'Responsable',
              'Equipo SéTú (Bugñuelitos, UAM)',
              Icons.groups_outlined,
            ),
            const InfoPoint(
              'Privacidad y alcance',
              'Lecturas y XP se guardan solo en este teléfono. No sustituye atención profesional humana.',
              Icons.shield_outlined,
            ),
          ]) ...<Widget>[
            _PointCard(point: p, story: false),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton(
            style: _primary,
            onPressed: () => Navigator.pop(sheet),
            child: const Text('Entendido'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: _secondary,
            onPressed: () {
              Navigator.pop(sheet);
              context.go(
                publicEntry ? '/informacion' : '/inicio',
                extra: HomeSectionRequest(HomeSection.ayuda),
              );
            },
            child: const Text('Ir a Ayuda'),
          ),
        ],
      ),
    ),
  ),
);

/// Etiqueta de disponibilidad sin conexión (verde) o con internet (azul).
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({
    super.key,
    required this.offline,
    this.onDark = false,
  });
  final bool offline;
  final bool onDark;

  @override
  Widget build(BuildContext context) => _Pill(
    text: offline ? 'Sin internet' : 'Con internet',
    icon: offline ? Icons.download_done_rounded : Icons.wifi_rounded,
    ink: onDark ? CureandoTheme.blue : (offline ? _okInk : CureandoTheme.blue),
    background: onDark
        ? Colors.white
        : (offline ? CureandoTheme.greenSoft : CureandoTheme.blueSoft),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    this.icon,
    this.ink = CureandoTheme.blue,
    this.background = Colors.white,
  });
  final String text;
  final IconData? icon;
  final Color ink;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 13, color: ink),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Franja que identifica una vista como muestra de demostración.
class SampleBanner extends StatelessWidget {
  const SampleBanner({super.key, this.text = 'Vista de muestra'});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: CureandoTheme.blueSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.science_outlined, size: 18, color: CureandoTheme.blue),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: CureandoTheme.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
