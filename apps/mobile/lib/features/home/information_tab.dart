import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/setu_card.dart';
import 'learning_progress.dart';
import 'student_resources.dart';

/// E10 comparte el contenedor y la navegación del inicio estudiantil.
class InformationTab extends StatefulWidget {
  const InformationTab({
    super.key,
    required this.progress,
    this.publicEntry = false,
  });

  final LearningProgress progress;
  final bool publicEntry;

  @override
  State<InformationTab> createState() => _InformationTabState();
}

class _InformationTabState extends State<InformationTab> {
  bool _routes = false;
  InfoTopic? _topic;
  String _query = '';
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(InfoResource resource) => context.push<void>(
    widget.publicEntry ? '/informacion/recurso/${resource.id}' : resource.route,
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(value: false, label: Text('Biblioteca')),
            ButtonSegment<bool>(value: true, label: Text('Rutas')),
          ],
          selected: <bool>{_routes},
          showSelectedIcon: false,
          onSelectionChanged: (Set<bool> value) =>
              setState(() => _routes = value.single),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: CureandoTheme.blue,
            selectedForegroundColor: Colors.white,
            backgroundColor: CureandoTheme.background,
            foregroundColor: CureandoTheme.ink,
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
            minimumSize: const Size(0, 46),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_routes) _routeView() else ..._library(),
      const SizedBox(height: 16),
      const Text(
        'Catálogo de muestra · En revisión editorial. Leer no envía alertas. '
        'Los XP se guardan solo en este teléfono, sin cuenta.',
        style: TextStyle(fontSize: 11, color: CureandoTheme.secondaryInk),
      ),
    ],
  );

  List<Widget> _library() {
    final List<InfoResource> resources = infoCatalog.where((InfoResource r) {
      final String text = _normalize(
        '${r.title} ${r.summary} ${r.topic.label} ${r.format.label}',
      );
      return !r.isQuiz &&
          (_topic == null || _topic == r.topic) &&
          _normalize(_query).split(RegExp(r'\s+')).every(text.contains);
    }).toList();
    final bool filtered = _topic != null || _query.trim().isNotEmpty;
    return <Widget>[
      TextField(
        controller: _search,
        onChanged: (String value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Buscá un tema',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(8),
            child: Chip(
              label: Text(
                '${resources.length} recursos',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          filled: true,
          fillColor: CureandoTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        children: <Widget>[
          _filter(null, 'Todos', CureandoTheme.blue),
          _filter(InfoTopic.acoso, 'Acoso escolar', CureandoTheme.blue),
          _filter(InfoTopic.emociones, 'Emociones', CureandoTheme.yellow),
          _filter(InfoTopic.ciberacoso, 'Ciberacoso', CureandoTheme.pink),
          _filter(InfoTopic.apoyo, 'Apoyo', CureandoTheme.green),
        ],
      ),
      const SizedBox(height: 10),
      if (filtered) ...<Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Resultados de la biblioteca',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${resources.length} disponibles',
              style: const TextStyle(fontSize: 11, color: CureandoTheme.blue),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (resources.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No encontramos recursos. Probá con otro tema.'),
          ),
        for (final InfoResource resource in resources) ...<Widget>[
          InfoResourceCard(resource: resource, onTap: () => _open(resource)),
          const SizedBox(height: 10),
        ],
      ] else ...<Widget>[
        _wideCard(infoResourceById('broma')!, featured: true),
        _topicHeading(InfoTopic.acoso),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final List<Widget> cards = <Widget>[
              for (final String id in <String>['testigo', 'pedir-apoyo'])
                InfoResourceCard(
                  resource: infoResourceById(id)!,
                  cover: true,
                  onTap: () => _open(infoResourceById(id)!),
                ),
            ];
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(16) > 22) {
              return Column(
                children: <Widget>[
                  cards.first,
                  const SizedBox(height: 10),
                  cards.last,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: cards.first),
                  const SizedBox(width: 10),
                  Expanded(child: cards.last),
                ],
              ),
            );
          },
        ),
        _topicHeading(InfoTopic.ciberacoso),
        _wideCard(infoResourceById('chat-grupo')!),
        _topicHeading(InfoTopic.emociones),
        InfoResourceCard(
          resource: infoResourceById('emociones')!,
          onTap: () => _open(infoResourceById('emociones')!),
        ),
        _topicHeading(InfoTopic.apoyo),
        InfoResourceCard(
          resource: infoResourceById('alerta')!,
          onTap: () => _open(infoResourceById('alerta')!),
        ),
      ],
    ];
  }

  Widget _filter(InfoTopic? topic, String title, Color color) => ChoiceChip(
    label: Text(title),
    selected: _topic == topic,
    showCheckmark: false,
    selectedColor: color,
    labelStyle: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _topic == topic && color != CureandoTheme.yellow
          ? Colors.white
          : CureandoTheme.ink,
    ),
    onSelected: (_) => setState(() => _topic = topic),
  );

  Widget _topicHeading(InfoTopic topic) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            topic.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _topic = topic),
          child: Semantics(
            label: 'Ver todo de ${topic.label}',
            excludeSemantics: true,
            child: const Text('Ver todo ›'),
          ),
        ),
      ],
    ),
  );

  Widget _wideCard(InfoResource resource, {bool featured = false}) => SetuCard(
    onTap: () => _open(resource),
    child: Container(
      constraints: BoxConstraints(minHeight: featured ? 120 : 90),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(resource.cardAsset!),
          fit: BoxFit.cover,
        ),
      ),
      padding: EdgeInsets.fromLTRB(featured ? 142 : 110, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (featured) const AvailabilityBadge(offline: true, onDark: true),
          const SizedBox(height: 4),
          Text(
            resource.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${resource.meta}${featured ? '' : ' · Sin internet'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (featured)
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Leer ›',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _routeView() => ListenableBuilder(
    listenable: widget.progress,
    builder: (BuildContext context, _) {
      final InfoRoute route = infoRoutes.first;
      final LearningProgress p = widget.progress;
      final List<bool> done = <bool>[
        p.completedResource(route.steps[0]),
        p.completedResource(route.steps[1]),
        p.completedRoute(route.id),
      ];
      final int count = done.where((bool value) => value).length;
      final int xp = (done[0] ? 5 : 0) + (done[1] ? 5 : 0) + (done[2] ? 10 : 0);
      final int next = done.indexOf(false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: CureandoTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const Text(
                  'Acoso escolar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => _changeTopic(count),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: const Text('Cambiar tema'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE1E6EF)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$count de 3 pasos',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '+$xp XP ganados',
                      style: const TextStyle(
                        color: Color(0xFF067D30),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    for (int i = 0; i < 3; i++)
                      Expanded(
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: done[i]
                                ? CureandoTheme.blue
                                : CureandoTheme.blueSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: CureandoTheme.blue,
                image: DecorationImage(
                  image: AssetImage('assets/home/info/e10c_route_map.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: CustomPaint(
                painter: const _RoutePath(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < 3; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            left: i == 1 ? 48 : 0,
                            top: i == 0 ? 0 : 42,
                          ),
                          child: _RouteNode(
                            index: i,
                            done: done[i],
                            resource: infoResourceById(route.steps[i])!,
                            onTap: () =>
                                _open(infoResourceById(route.steps[i])!),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () =>
                _open(infoResourceById(route.steps[next < 0 ? 2 : next])!),
            child: Text(count == 3 ? 'Repasar ruta' : 'Continuar ruta'),
          ),
        ],
      );
    },
  );

  Future<void> _changeTopic(int count) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Elegí una ruta para aprender',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
            ),
            const Text(
              'Cada tema avanza paso a paso. También podés abrir cualquier recurso suelto en Biblioteca.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final InfoRoute route in infoRoutes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: route.ready ? () => Navigator.pop(sheet) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.centerLeft,
                    backgroundColor: route.ready
                        ? CureandoTheme.blueSoft
                        : Colors.white,
                    side: BorderSide(
                      color: route.ready
                          ? CureandoTheme.blue
                          : const Color(0xFFE1E6EF),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        route.topic.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: CureandoTheme.ink,
                        ),
                      ),
                      Text(
                        route.ready
                            ? 'Ruta completa · $count de 3'
                            : 'En preparación',
                        style: TextStyle(
                          fontSize: 11,
                          color: route.ready
                              ? CureandoTheme.blue
                              : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CureandoTheme.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Text(
              'Muestra: la ruta de Acoso escolar tiene 3 pasos; los otros temas están en revisión editorial.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(sheet),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _normalize(String value) {
  String result = value.toLowerCase().trim();
  const String accented = 'áéíóúü';
  const String plain = 'aeiouu';
  for (int i = 0; i < accented.length; i++) {
    result = result.replaceAll(accented[i], plain[i]);
  }
  return result;
}

class InformationHeader extends StatelessWidget {
  const InformationHeader({super.key});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 132),
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/home/info/e10a_header.png'),
        fit: BoxFit.cover,
        alignment: Alignment.centerRight,
      ),
    ),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CampaignSymbol(size: 28, showUnicef: false),
        SizedBox(height: 16),
        Text(
          'Información',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Tarjeta compacta de búsqueda, o vertical para los bloques de portada.
class InfoResourceCard extends StatelessWidget {
  const InfoResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
    this.cover = false,
  });
  final InfoResource resource;
  final VoidCallback onTap;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final String asset =
        resource.thumbAsset ??
        resource.cardAsset ??
        resource.bannerAsset ??
        resource.cover.assetPath;
    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!cover)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: <Widget>[
              AvailabilityBadge(offline: resource.offline),
              const Text(
                '+5 XP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CureandoTheme.blue,
                ),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Text(
          resource.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '${resource.meta} · ${cover ? resource.availability : resource.topic.chip}',
          style: const TextStyle(
            color: CureandoTheme.blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!cover)
          Text(
            resource.summary,
            style: const TextStyle(
              color: CureandoTheme.secondaryInk,
              fontSize: 12,
            ),
          ),
      ],
    );
    return SetuCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: cover
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2,
                      child: Image.asset(
                        asset,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  details,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      asset,
                      width: 54,
                      height: 60,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: details),
                ],
              ),
      ),
    );
  }
}

class _RouteNode extends StatelessWidget {
  const _RouteNode({
    required this.index,
    required this.done,
    required this.resource,
    required this.onTap,
  });
  final int index;
  final bool done;
  final InfoResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 2
                  ? CureandoTheme.pink
                  : done
                  ? CureandoTheme.green
                  : CureandoTheme.blue,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              done
                  ? Icons.check_rounded
                  : <IconData>[
                      Icons.menu_book_outlined,
                      Icons.play_arrow_rounded,
                      Icons.question_mark_rounded,
                    ][index],
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  index == 0 ? 'Reconocé el acoso' : resource.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${resource.format.label} · ${done
                      ? 'Completada'
                      : index == 2
                      ? '+10 XP'
                      : '${resource.minutes} min'}${index == 2 ? '' : ' · ${resource.availability}'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _RoutePath extends CustomPainter {
  const _RoutePath();
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(48, 65)
      ..cubicTo(
        10,
        size.height * .35,
        105,
        size.height * .37,
        96,
        size.height * .5,
      )
      ..cubicTo(
        90,
        size.height * .62,
        10,
        size.height * .65,
        48,
        size.height - 65,
      );
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 13) {
        canvas.drawPath(metric.extractPath(offset, offset + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePath oldDelegate) => false;
}
