import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import 'info_artwork.dart';
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
  InfoRoute _selectedRoute = infoRoutes.first;
  InfoTopic? _topic;
  String _query = '';
  final TextEditingController _search = TextEditingController();
  final ScrollController _categoriesScroll = ScrollController();
  final GlobalKey _categoriesViewport = GlobalKey();
  final List<GlobalKey> _categoryKeys = List<GlobalKey>.generate(
    InfoTopic.values.length + 1,
    (_) => GlobalKey(),
  );
  int _visibleCategories = 0;
  bool _visibilityScheduled = false;

  @override
  void initState() {
    super.initState();
    _categoriesScroll.addListener(_scheduleCategoryVisibility);
  }

  void _scheduleCategoryVisibility() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted) return;
      final RenderBox? viewport =
          _categoriesViewport.currentContext?.findRenderObject() as RenderBox?;
      if (viewport == null || !viewport.hasSize) return;
      final Rect bounds = viewport.localToGlobal(Offset.zero) & viewport.size;
      int visible = 0;
      for (int i = 0; i < _categoryKeys.length; i++) {
        final RenderBox? chip =
            _categoryKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (chip == null || !chip.hasSize) continue;
        final Rect rect = chip.localToGlobal(Offset.zero) & chip.size;
        if (rect.left >= bounds.left - .5 && rect.right <= bounds.right + .5) {
          visible |= 1 << i;
        }
      }
      if (_visibleCategories != visible) {
        setState(() => _visibleCategories = visible);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _categoriesScroll.dispose();
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
    ],
  );

  List<Widget> _library() {
    _scheduleCategoryVisibility();
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: CureandoTheme.blue,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          filled: true,
          fillColor: Colors.white,
          border: _searchBorder,
          enabledBorder: _searchBorder,
          focusedBorder: _searchBorder,
        ),
      ),
      const SizedBox(height: 8),
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _scheduleCategoryVisibility();
          return false;
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            const List<InfoTopic?> topics = <InfoTopic?>[
              null,
              InfoTopic.acoso,
              InfoTopic.emociones,
              InfoTopic.ciberacoso,
              InfoTopic.ansiedad,
              InfoTopic.depresion,
              InfoTopic.apoyo,
            ];
            // Cuatro etiquetas completas a tamaño normal; con texto ampliado
            // se conserva el tamaño de letra y se desplaza el carrusel.
            final double padding = box.maxWidth < 340 ? 3.5 : 8;
            return SizedBox(
              key: _categoriesViewport,
              child: SingleChildScrollView(
                key: const ValueKey<String>('information-categories'),
                controller: _categoriesScroll,
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 6,
                  children: <Widget>[
                    for (int i = 0; i < topics.length; i++)
                      _filter(i, topics[i], padding, box.maxWidth),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      if (filtered) ...<Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            Text(
              _topic?.label ?? 'Resultados de la biblioteca',
              style: const TextStyle(fontWeight: FontWeight.w700),
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
          ListenableBuilder(
            listenable: widget.progress,
            builder: (BuildContext context, _) => InfoResourceCard(
              resource: resource,
              read: widget.progress.completedResource(resource.id),
              onTap: () => _open(resource),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ] else ...<Widget>[
        _wideCard(infoCatalog.first, featured: true),
        for (final InfoTopic topic in InfoTopic.values) ...<Widget>[
          _topicHeading(topic),
          _topicPreview(topic),
          const SizedBox(height: 10),
        ],
      ],
    ];
  }

  static final OutlineInputBorder _searchBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: CureandoTheme.blue, width: 2),
  );

  Widget _filter(int index, InfoTopic? topic, double padding, double maxWidth) {
    final Color color = topic?.color ?? CureandoTheme.blue;
    final bool visible = _visibleCategories & (1 << index) != 0;
    return AnimatedOpacity(
      key: _categoryKeys[index],
      opacity: visible ? 1 : 0,
      duration: !visible || MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      // El lector puede enfocar y desplazar hasta un chip visualmente oculto.
      alwaysIncludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ChoiceChip(
          label: Text(topic?.chip ?? 'Todos'),
          padding: EdgeInsets.zero,
          labelPadding: EdgeInsets.symmetric(horizontal: padding),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.compact,
          selected: _topic == topic,
          showCheckmark: false,
          checkmarkColor: color == CureandoTheme.yellow
              ? CureandoTheme.ink
              : Colors.white,
          backgroundColor: color,
          selectedColor: color,
          shape: const StadiumBorder(),
          side: BorderSide(
            color: _topic == topic ? CureandoTheme.ink : color,
            width: _topic == topic ? 2 : 1,
          ),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
            color: color == CureandoTheme.yellow
                ? CureandoTheme.ink
                : Colors.white,
          ),
          onSelected: (_) => setState(() {
            _topic = topic;
            if (topic == null) {
              _query = '';
              _search.clear();
            }
          }),
        ),
      ),
    );
  }

  Widget _topicPreview(InfoTopic topic) {
    final List<InfoResource> preview = infoCatalog
        .where(
          (InfoResource r) =>
              r.topic == topic && !r.isQuiz && r != infoCatalog.first,
        )
        .take(3)
        .toList();
    if (preview.length == 1) return _wideCard(preview.single);
    final List<Widget> cards = <Widget>[
      for (final InfoResource resource in preview.take(2))
        InfoResourceCard(
          key: ValueKey<String>('preview-${resource.id}'),
          resource: resource,
          cover: true,
          onTap: () => _open(resource),
        ),
    ];
    return Column(
      key: ValueKey<String>('topic-preview-${topic.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (MediaQuery.textScalerOf(context).scale(14) > 21)
          ...cards.map(
            (Widget card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: cards
                .map((Widget card) => Expanded(child: card))
                .toList(),
          ),
        if (preview.length == 3) ...<Widget>[
          const SizedBox(height: 10),
          _wideCard(preview.last),
        ],
      ],
    );
  }

  Widget _topicHeading(InfoTopic topic) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: <Widget>[
        Text(
          topic.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        TextButton(
          onPressed: () {
            setState(() => _topic = topic);
            Scrollable.maybeOf(context)?.position.jumpTo(0);
          },
          child: Semantics(
            label: 'Ver catálogo de ${topic.label}',
            excludeSemantics: true,
            child: const Text('Ver catálogo ›'),
          ),
        ),
      ],
    ),
  );

  Widget _wideCard(
    InfoResource resource, {
    bool featured = false,
  }) => _LibraryCard(
    key: ValueKey<String>('banner-${resource.id}'),
    onTap: () => _open(resource),
    child: Container(
      constraints: BoxConstraints(minHeight: featured ? 120 : 90),
      decoration: BoxDecoration(
        color: CureandoTheme.blue,
        image: DecorationImage(
          image: AssetImage(
            resource.cardAsset!.contains('/stickers/')
                ? 'assets/welcome/campaign-pattern.png'
                : resource.cardAsset!,
          ),
          // El recorte centrado mantiene las figuras a la izquierda del
          // texto y evita costuras cuando el contenido aumenta el alto.
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: <Widget>[
          if (resource.cardAsset!.contains('/stickers/'))
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: .38,
                alignment: Alignment.centerLeft,
                child: InfoArtwork(
                  asset: resource.cardAsset!,
                  topic: resource.topic,
                ),
              ),
            ),
          if (!featured)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0x000C62EB), Color(0xF00C62EB)],
                    stops: <double>[0, .5],
                  ),
                ),
              ),
            ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => Padding(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth * .42,
                12,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (featured)
                    AvailabilityBadge(offline: resource.offline, onDark: true),
                  const SizedBox(height: 4),
                  Text(
                    resource.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_resourceMeta(resource)}${featured ? '' : ' · ${resource.availability}'}',
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
          ),
        ],
      ),
    ),
  );

  Widget _routeView() => ListenableBuilder(
    listenable: widget.progress,
    builder: (BuildContext context, _) {
      final InfoRoute route = _selectedRoute;
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: route.topic.color,
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/welcome/campaign-pattern.png'),
                fit: BoxFit.cover,
                opacity: .08,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        route.topic.label,
                        style: TextStyle(
                          color: route.topic.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: Image.asset(
                        route.topic.sticker,
                        excludeFromSemantics: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _RoutePieces(done: done, ink: route.topic.ink),
                    Text(
                      '$count de 3 pasos',
                      style: TextStyle(
                        color: route.topic.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _RouteReward(completed: done[2], label: '+$xp XP ganados'),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: route.topic.ink,
                      ),
                      onPressed: _changeTopic,
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Cambiar tema'),
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

  int _routeCompletedSteps(InfoRoute route) =>
      (widget.progress.completedResource(route.steps[0]) ? 1 : 0) +
      (widget.progress.completedResource(route.steps[1]) ? 1 : 0) +
      (widget.progress.completedRoute(route.id) ? 1 : 0);

  Future<void> _changeTopic() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .9,
    ),
    builder: (BuildContext sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Elegí tu ruta',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final bool single =
                    MediaQuery.textScalerOf(context).scale(16) > 24;
                final double width = single
                    ? box.maxWidth
                    : (box.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final InfoRoute route in infoRoutes)
                      SizedBox(
                        width: width,
                        child: _RouteChoice(
                          key: ValueKey<String>('route-choice-${route.id}'),
                          route: route,
                          done: <bool>[
                            widget.progress.completedResource(route.steps[0]),
                            widget.progress.completedResource(route.steps[1]),
                            widget.progress.completedRoute(route.id),
                          ],
                          count: _routeCompletedSteps(route),
                          selected: _selectedRoute == route,
                          onTap: () {
                            setState(() => _selectedRoute = route);
                            Navigator.pop(sheet);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
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
  const InformationHeader({super.key, this.title = 'Información'});

  final String title;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => ConstrainedBox(
      // Igual que Inicio: el Stack toma la altura del contenido y el arte
      // llena el banner hasta el borde de la hoja blanca, sin recortar figuras.
      constraints: BoxConstraints(minHeight: constraints.maxWidth * 308 / 780),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/home/info/e10a_header_figures.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              excludeFromSemantics: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 14, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const CampaignSymbol(size: 28),
                const SizedBox(height: 30),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: <Shadow>[
                        Shadow(
                          color: Color(0x40002B7A),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
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

/// Tarjeta compacta de búsqueda, o vertical para los bloques de portada.
class InfoResourceCard extends StatelessWidget {
  const InfoResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
    this.cover = false,
    this.read = false,
  });
  final InfoResource resource;
  final VoidCallback onTap;
  final bool cover;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final String asset =
        resource.thumbAsset ??
        resource.cardAsset ??
        resource.bannerAsset ??
        resource.cover.assetPath;
    final bool largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          resource.title,
          maxLines: largeText ? null : 2,
          overflow: largeText ? null : TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          cover
              ? '${_resourceMeta(resource)} · ${resource.availability}'
              : '${resource.topic.label} · ${_resourceMeta(resource)}',
          style: TextStyle(
            color: cover && resource.offline
                ? const Color(0xFF008A35)
                : CureandoTheme.blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!cover) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            resource.summary,
            maxLines: largeText ? null : 1,
            overflow: largeText ? null : TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
          ),
        ],
      ],
    );
    return _LibraryCard(
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
                      child: InfoArtwork(asset: asset, topic: resource.topic),
                    ),
                  ),
                  const SizedBox(height: 8),
                  details,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: InfoArtwork(asset: asset, topic: resource.topic),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 6,
                          runSpacing: 4,
                          children: <Widget>[
                            _CatalogPill(
                              label: resource.availability,
                              color: const Color(0xFFE4F9EB),
                              ink: const Color(0xFF008A35),
                            ),
                            if (!read)
                              const _CatalogPill(
                                label: '+5 XP',
                                color: CureandoTheme.blue,
                                ink: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        details,
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// No inventar duración para los videos cuyo tiempo aún no está verificado.
String _resourceMeta(InfoResource resource) =>
    '${resource.format.label}${resource.minutes == null ? '' : ' · ${resource.minutes} min'}';

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE1E6EF)),
    ),
    child: InkWell(onTap: onTap, child: child),
  );
}

class _CatalogPill extends StatelessWidget {
  const _CatalogPill({
    required this.label,
    required this.color,
    required this.ink,
  });
  final String label;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _RouteChoice extends StatelessWidget {
  const _RouteChoice({
    super.key,
    required this.route,
    required this.done,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final InfoRoute route;
  final List<bool> done;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool completed = done.last;
    final String status = completed
        ? '¡Completada!'
        : count > 0
        ? 'En curso'
        : 'Nueva';
    final Color ink = route.topic.ink;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${route.topic.label}, $status, $count de 3 pasos, '
          '${completed ? 'medalla ganada' : '+10 XP al completar'}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: route.topic.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: selected ? CureandoTheme.ink : Colors.transparent,
            width: 3,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/welcome/campaign-pattern.png'),
                fit: BoxFit.cover,
                opacity: .08,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: _RouteReward(completed: completed)),
                      if (selected) ...<Widget>[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle_rounded, color: ink, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Image.asset(
                      route.topic.sticker,
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    route.topic.label,
                    style: TextStyle(
                      color: ink,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Icon(
                        completed
                            ? Icons.verified_rounded
                            : count > 0
                            ? Icons.play_circle_outline_rounded
                            : Icons.auto_awesome_rounded,
                        size: 16,
                        color: ink,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _RoutePieces(done: done, ink: ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteReward extends StatelessWidget {
  const _RouteReward({required this.completed, this.label});
  final bool completed;
  final String? label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          completed ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
          color: CureandoTheme.blue,
          size: 18,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label ?? (completed ? '¡Ganada!' : '+10 XP'),
            style: const TextStyle(
              color: CureandoTheme.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoutePieces extends StatelessWidget {
  const _RoutePieces({required this.done, required this.ink});
  final List<bool> done;
  final Color ink;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < done.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              done[i] ? Icons.extension_rounded : Icons.extension_outlined,
              color: done[i] ? ink : ink.withValues(alpha: .5),
              size: 24,
            ),
          ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Semantics(
    label:
        'Paso ${index + 1}, ${resource.title}, '
        '${done ? 'completado' : 'pendiente'}',
    button: true,
    onTap: onTap,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    Icons.extension_rounded,
                    size: 58,
                    color: done ? CureandoTheme.yellow : Colors.white,
                  ),
                  Icon(
                    done
                        ? Icons.check_rounded
                        : <IconData>[
                            Icons.menu_book_outlined,
                            resource.isVideo
                                ? Icons.play_arrow_rounded
                                : Icons.menu_book_outlined,
                            Icons.question_mark_rounded,
                          ][index],
                    color: CureandoTheme.ink,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    resource.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${done ? '✓ ' : ''}${index == 2 ? '+10 XP' : '+5 XP'}',
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
