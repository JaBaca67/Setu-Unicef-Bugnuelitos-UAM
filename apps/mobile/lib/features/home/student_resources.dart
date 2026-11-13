import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_bottom_nav.dart';
import 'learning_progress.dart';
import 'streak_screen.dart';
import 'student_preview_cards.dart';

/// Recurso editorial de muestra para el espacio Información (E10/E11).
/// Contenido propio identificado como muestra; el catálogo real, su revisión
/// editorial y los derechos siguen pendientes.
@immutable
class SampleResource {
  const SampleResource({
    required this.id,
    required this.format,
    required this.topic,
    required this.title,
    required this.summary,
    required this.body,
    required this.icon,
    required this.tint,
    required this.inkColor,
  });

  final String id;
  final String format;
  final String topic;
  final String title;
  final String summary;
  final List<String> body;
  final IconData icon;
  final Color tint;
  final Color inkColor;

  String get route => '/inicio/recurso/$id';
  bool get isVideo => format == 'Video';
  StudentCover get cover => isVideo ? StudentCover.video : StudentCover.guide;
}

const List<SampleResource> sampleResources = <SampleResource>[
  SampleResource(
    id: 'emociones',
    format: 'Guía',
    topic: 'Emociones',
    title: 'Entendé tus emociones',
    summary: 'Qué son las emociones y cómo ponerles nombre.',
    icon: Icons.menu_book_rounded,
    tint: CureandoTheme.blueSoft,
    inkColor: CureandoTheme.blue,
    body: <String>[
      'Las emociones son señales del cuerpo y de la mente. Todas son '
          'válidas: nos avisan que algo nos importa.',
      'Ponerle nombre a lo que sentís —alegría, tristeza, enojo, miedo, '
          'sorpresa o calma— ayuda a que se sienta menos grande.',
      'Cuando una emoción pesa mucho, podés respirar despacio, contarle a '
          'alguien de confianza o pedir apoyo desde esta app.',
    ],
  ),
  SampleResource(
    id: 'convivencia',
    format: 'Video',
    topic: 'Convivencia',
    title: 'Convivencia escolar',
    summary: 'Cómo construir un aula donde todas las personas se respeten.',
    icon: Icons.ondemand_video_rounded,
    tint: CureandoTheme.pinkSoft,
    inkColor: CureandoTheme.pink,
    body: <String>[
      'Convivir bien no es no tener conflictos: es resolverlos sin '
          'humillar ni excluir a nadie.',
      'Si ves que molestan a alguien, acompañarle o avisar a una persona '
          'adulta de confianza también es ayudar. A eso le llamamos ser '
          'Testigo Solidario.',
      'Pedir apoyo no es acusar: es cuidar de vos y de tu grupo.',
    ],
  ),
];

/// Temas propuestos del catálogo, organizados por tema y formato.
const List<String> sampleTopics = <String>[
  'Emociones',
  'Convivencia',
  'Acoso escolar',
  'Pedir apoyo',
];

SampleResource? sampleResourceById(String? id) {
  for (final SampleResource resource in sampleResources) {
    if (resource.id == id) return resource;
  }
  return null;
}

/// Vista de muestra de un recurso (E11). Identifica el contenido como
/// material propio sin revisión editorial final.
class ResourcePreviewScreen extends StatefulWidget {
  const ResourcePreviewScreen({
    super.key,
    required this.resourceId,
    required this.progress,
  });

  final String resourceId;
  final LearningProgress progress;

  @override
  State<ResourcePreviewScreen> createState() => _ResourcePreviewScreenState();
}

class _ResourcePreviewScreenState extends State<ResourcePreviewScreen> {
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    widget.progress.open();
  }

  Future<void> _complete(SampleResource resource) async {
    if (_saving || !widget.progress.canCompleteResource(resource.id)) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final int xp = await widget.progress.completeResource(resource.id);
      if (!mounted) return;
      setState(() {
        _message = xp > 0
            ? 'Sumaste $xp XP.'
            : 'Marcaste un día de aprendizaje.';
      });
    } on Object {
      if (!mounted) return;
      setState(() => _message = 'No se pudo guardar. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SampleResource? resource = sampleResourceById(widget.resourceId);
    if (resource == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Este recurso no está disponible.')),
      );
    }
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      bottomNavigationBar: SetuBottomNav(
        selected: HomeSection.informacion,
        onSelected: (HomeSection section) =>
            context.go('/inicio', extra: HomeSectionRequest(section)),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: Text(resource.format),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SampleBanner(),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _Tag(text: 'Tema: ${resource.topic}'),
                      _Tag(text: 'Formato: ${resource.format}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      resource.title,
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (resource.isVideo) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CureandoTheme.yellowSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'El video de muestra todavía no está empaquetado en la '
                        'app. Mientras tanto podés leer este resumen con la '
                        'misma información.',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (final String paragraph in resource.body) ...<Widget>[
                    Text(paragraph),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Contenido propio de muestra. Fuente, revisión '
                        'profesional y fecha de verificación quedan pendientes '
                        'antes de publicarlo.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: widget.progress,
                    builder: (context, child) {
                      final LearningProgress progress = widget.progress;
                      if (!progress.ready) {
                        return LearningProgressStatus(progress: progress);
                      }
                      final bool canComplete = progress.canCompleteResource(
                        resource.id,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          FilledButton(
                            onPressed: _saving || !canComplete
                                ? null
                                : () => _complete(resource),
                            child: Text(
                              !canComplete
                                  ? 'Lectura registrada'
                                  : resource.isVideo
                                  ? 'Marcar resumen leído'
                                  : 'Marcar como leída',
                            ),
                          ),
                          if (_message != null || _saving)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _saving ? 'Guardando tu progreso…' : _message!,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: CureandoTheme.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 14)),
  );
}
