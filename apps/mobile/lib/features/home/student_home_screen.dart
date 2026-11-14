import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/setu_bottom_nav.dart';
import '../../shared/widgets/setu_card.dart';
import '../piece/student_piece.dart';
import '../support/alert_screens.dart';
import 'learning_progress.dart';
import 'streak_screen.dart';
import 'student_activities.dart';
import 'student_preview_cards.dart';
import 'student_resources.dart';

export '../../shared/widgets/setu_bottom_nav.dart'
    show HomeSection, HomeSectionRequest;

/// Inicio estudiantil E03. Reúne «Pedir apoyo», adelantos de Información y
/// Actividades, y la navegación inferior. El estudiante no tiene una sección
/// de seguimiento de casos: tras pedir apoyo puede recibir un aviso que abre
/// su chat cuando una persona autorizada esté disponible.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.progress,
    required this.piece,
    this.sectionRequest,
  });

  final LearningProgress progress;
  final ValueNotifier<StudentPiece> piece;
  final HomeSectionRequest? sectionRequest;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  HomeSection _section = HomeSection.inicio;
  final GlobalKey _diceKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.progress.open();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showStreak() async {
    final bool? openActivities = await context.push<bool>('/inicio/racha');
    if (mounted && openActivities == true) _open(HomeSection.actividades);
  }

  @override
  void didUpdateWidget(StudentHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final HomeSectionRequest? request = widget.sectionRequest;
    if (request != null && !identical(request, oldWidget.sectionRequest)) {
      _section = request.section;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }
  }

  void _open(HomeSection section) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() => _section = section);
  }

  void _openDice() {
    _open(HomeSection.actividades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? dice = _diceKey.currentContext;
      if (dice != null) Scrollable.ensureVisible(dice);
    });
  }

  @override
  Widget build(BuildContext context) => CampaignScreen(
    scrollController: _scrollController,
    bodyRadius: _section == HomeSection.inicio
        ? null
        : const BorderRadius.vertical(top: Radius.circular(28)),
    bottomNavigationBar: SetuBottomNav(selected: _section, onSelected: _open),
    header: switch (_section) {
      HomeSection.inicio => _HomeHeader(piece: widget.piece),
      HomeSection.informacion => const _SectionHeader(
        title: 'Información',
        subtitle: 'Leé y mirá a tu ritmo. No hace falta reportar.',
      ),
      HomeSection.actividades => const _SectionHeader(
        title: 'Actividades',
        subtitle: 'Jugá y aprendé sobre emociones y convivencia.',
      ),
      HomeSection.ayuda => const _SectionHeader(
        title: 'Ayuda',
        subtitle: 'Personas y recursos que pueden acompañarte.',
      ),
    },
    body: Padding(
      padding: _section == HomeSection.inicio
          ? const EdgeInsets.fromLTRB(12, 14, 12, 16)
          : const EdgeInsets.all(20),
      child: switch (_section) {
        HomeSection.inicio => _InicioTab(
          onOpenSection: _open,
          progress: widget.progress,
          onOpenStreak: _showStreak,
          onOpenDice: _openDice,
        ),
        HomeSection.informacion => const _InformacionTab(),
        HomeSection.actividades => ActivitiesTab(
          progress: widget.progress,
          diceKey: _diceKey,
        ),
        HomeSection.ayuda => const _AyudaTab(),
      },
    ),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.piece});

  final ValueNotifier<StudentPiece> piece;

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    final Widget greeting = Semantics(
      header: true,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '¡Hola!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '¿Qué querés hacer hoy?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 192),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/home/fondo-homepage-banner.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                Color(0xD80C62EB),
                Color(0x660C62EB),
                Color(0x000C62EB),
              ],
              stops: <double>[0, 0.48, 0.85],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const CampaignSymbol(size: 28),
                    const Spacer(),
                    PieceHeaderButton(piece: piece),
                  ],
                ),
                const SizedBox(height: 22),
                if (largeText)
                  greeting
                else
                  Row(
                    children: <Widget>[
                      Expanded(flex: 6, child: greeting),
                      const Spacer(flex: 4),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const CampaignSymbol(size: 26),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _InicioTab extends StatelessWidget {
  const _InicioTab({
    required this.onOpenSection,
    required this.progress,
    required this.onOpenStreak,
    required this.onOpenDice,
  });

  final ValueChanged<HomeSection> onOpenSection;
  final LearningProgress progress;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenDice;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: CureandoTheme.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(60),
            textStyle: textTheme.labelLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: () => context.push<void>('/inicio/apoyo'),
          icon: const Icon(Icons.chat_outlined),
          label: const Row(
            children: <Widget>[
              Expanded(child: Text('Pedir apoyo')),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: progress,
          builder: (context, child) =>
              WeeklyStreakCard(progress: progress, onTap: onOpenStreak),
        ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: 'Explorá a tu ritmo',
          onSeeAll: () => onOpenSection(HomeSection.informacion),
        ),
        const SizedBox(height: 10),
        _AdaptiveRow(
          children: <Widget>[
            for (final SampleResource resource in sampleResources)
              StudentPreviewCard(
                cover: resource.cover,
                title: resource.title,
                detail: resource.format,
                onTap: () => context.push<void>(resource.route),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: 'Actividades',
          onSeeAll: () => onOpenSection(HomeSection.actividades),
        ),
        const SizedBox(height: 10),
        _AdaptiveRow(
          children: <Widget>[
            ListenableBuilder(
              listenable: progress,
              builder: (context, child) => StudentPreviewCard(
                cover: StudentCover.question,
                compact: true,
                title: 'Pregunta del día',
                detail: progress.answeredToday
                    ? 'Completada'
                    : '+${LearningProgress.questionXp} XP',
                onTap: () => onOpenSection(HomeSection.actividades),
              ),
            ),
            StudentPreviewCard(
              cover: StudentCover.dice,
              compact: true,
              title: 'Dado de emociones',
              onTap: onOpenDice,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
      TextButton(
        onPressed: onSeeAll,
        child: Semantics(
          label: 'Ver todo de $title',
          excludeSemantics: true,
          child: const Text('Ver todo'),
        ),
      ),
    ],
  );
}

/// Dos tarjetas lado a lado; apiladas cuando la pantalla es angosta o el
/// texto está ampliado, para que nada quede cortado.
class _AdaptiveRow extends StatelessWidget {
  const _AdaptiveRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bool stacked =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(16) > 22;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget child in children) ...<Widget>[
            child,
            if (child != children.last) const SizedBox(height: 10),
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget child in children) ...<Widget>[
            Expanded(child: child),
            if (child != children.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _InformacionTab extends StatelessWidget {
  const _InformacionTab();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SampleBanner(text: 'Catálogo de muestra'),
        const SizedBox(height: 12),
        const Text(
          'Explorá por tema y formato: guías para leer y videos para mirar. '
          'Leer no envía ninguna alerta ni cambia nada de tu caso.',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String topic in sampleTopics)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CureandoTheme.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  topic,
                  style: const TextStyle(
                    color: CureandoTheme.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (final SampleResource resource in sampleResources) ...<Widget>[
          SetuCard(
            onTap: () => context.push<void>(resource.route),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      resource.cover.assetPath,
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${resource.format} · ${resource.topic}',
                          style: const TextStyle(
                            color: CureandoTheme.secondaryInk,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resource.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(resource.summary),
                        if (resource.format == 'Video') ...<Widget>[
                          const SizedBox(height: 4),
                          const Text(
                            'Video pendiente de empaquetar · resumen en '
                            'texto disponible',
                            style: TextStyle(
                              color: CureandoTheme.secondaryInk,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Qué falta', style: textTheme.titleMedium),
                const SizedBox(height: 6),
                const Text(
                  'El catálogo completo, la revisión editorial, los derechos '
                  'y la reproducción de video siguen en preparación. Estos '
                  'contenidos son muestras propias.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AyudaTab extends StatelessWidget {
  const _AyudaTab();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SampleBanner(),
      const SizedBox(height: 12),
      const Text(
        'En este espacio vas a encontrar recursos de ayuda verificados para '
        'Nicaragua: personas e instituciones que pueden acompañarte.',
      ),
      const SizedBox(height: 14),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Los contactos y horarios se publican cuando estén verificados, '
            'con fuente, territorio, fecha y responsable editorial. No '
            'mostramos contactos de borrador como si ya funcionaran.',
          ),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
        ),
        onPressed: () => context.push<void>('/inicio/apoyo'),
        icon: const Icon(Icons.favorite_rounded),
        label: const Text('Pedir apoyo'),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Garantías de protección',
              style: TextStyle(
                color: CureandoTheme.blue,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tu relato es confidencial para la mesa de escucha. El colegio '
              'solo recibe avisos de seguimiento general.',
            ),
          ],
        ),
      ),
    ],
  );
}
