import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import '../../shared/widgets/setu_bottom_nav.dart';
import '../piece/student_piece.dart';
import '../support/alert_screens.dart';
import 'help_contacts.dart';
import 'information_tab.dart';
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
    this.publicEntry = false,
  });

  final LearningProgress progress;
  final ValueNotifier<StudentPiece> piece;
  final HomeSectionRequest? sectionRequest;
  final bool publicEntry;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  HomeSection _section = HomeSection.inicio;
  final GlobalKey _diceKey = GlobalKey();
  late final PageController _pageController;
  final List<ScrollController> _scrollControllers =
      List<ScrollController>.generate(
        HomeSection.values.length,
        (_) => ScrollController(),
      );

  @override
  void initState() {
    super.initState();
    _section =
        widget.sectionRequest?.section ??
        (widget.publicEntry ? HomeSection.informacion : HomeSection.inicio);
    _pageController = PageController(initialPage: _section.index);
    widget.progress.open();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final ScrollController controller in _scrollControllers) {
      controller.dispose();
    }
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
      _pageController.jumpToPage(request.section.index);
      final ScrollController scroll = _scrollControllers[request.section.index];
      if (scroll.hasClients) scroll.jumpTo(0);
    }
  }

  Future<void> _open(HomeSection section) async {
    if (widget.publicEntry && section == HomeSection.inicio) {
      context.go('/');
      return;
    }
    final ScrollController scroll = _scrollControllers[section.index];
    if (scroll.hasClients) scroll.jumpTo(0);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(section.index);
    } else {
      await _pageController.animateToPage(
        section.index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openDice() async {
    await _open(HomeSection.actividades);
    if (!mounted) return;
    final BuildContext? dice = _diceKey.currentContext;
    if (dice != null && dice.mounted) await Scrollable.ensureVisible(dice);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.publicEntry,
    onPopInvokedWithResult: (bool didPop, Object? _) {
      if (!didPop && _section != HomeSection.inicio) {
        _open(HomeSection.inicio);
      }
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: CureandoTheme.statusBarOverlayLight.copyWith(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        bottomNavigationBar: SetuBottomNav(
          selected: _section,
          onSelected: _open,
          pageController: _pageController,
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: HomeSection.values.length,
          onPageChanged: (int index) {
            if (widget.publicEntry && index == 0) {
              context.go('/');
              return;
            }
            setState(() => _section = HomeSection.values[index]);
          },
          itemBuilder: (BuildContext context, int index) =>
              _page(HomeSection.values[index]),
        ),
      ),
    ),
  );

  Widget _page(HomeSection section) => CampaignPage(
    key: ValueKey<HomeSection>(section),
    scrollController: _scrollControllers[section.index],
    // Inicio e Información usan el mismo corte recto del banner: el arte
    // llega completo hasta la hoja sin una esquina blanca sobre las figuras.
    bodyRadius:
        section == HomeSection.inicio ||
            section == HomeSection.informacion ||
            section == HomeSection.ayuda
        ? null
        : const BorderRadius.vertical(top: Radius.circular(28)),
    header: switch (section) {
      HomeSection.inicio => _HomeHeader(piece: widget.piece),
      HomeSection.informacion => const InformationHeader(),
      HomeSection.actividades => const _SectionHeader(title: 'Actividades'),
      HomeSection.ayuda => const InformationHeader(title: 'Ayuda'),
    },
    body: Padding(
      padding: section == HomeSection.inicio
          ? const EdgeInsets.fromLTRB(12, 14, 12, 16)
          : const EdgeInsets.all(20),
      child: switch (section) {
        HomeSection.inicio => _InicioTab(
          onOpenSection: _open,
          progress: widget.progress,
          onOpenStreak: _showStreak,
          onOpenDice: _openDice,
        ),
        HomeSection.informacion => InformationTab(
          progress: widget.progress,
          publicEntry: widget.publicEntry,
        ),
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

  static const List<Shadow> _textShadows = <Shadow>[
    Shadow(color: Color(0x40002B7A), blurRadius: 8, offset: Offset(0, 1)),
  ];

  /// Distancia vertical desde la fila superior (logos/avatar) hasta «¡Hola!».
  /// Aumentá este número para bajar más el texto o disminuílo para subirlo.
  static const double greetingTopOffset = 22;

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    final Widget greeting = Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '¡Hola!',
            style: TextStyle(
              color: Colors.white,
              fontSize: largeText ? 48 : 200,
              fontWeight: FontWeight.w700,
              height: 1.05,
              shadows: _textShadows,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué querés hacer hoy?',
            style: TextStyle(
              color: Colors.white,
              fontSize: largeText ? 18 : 60,
              fontWeight: FontWeight.w700,
              height: 1.25,
              shadows: _textShadows,
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'assets/home/home-header-girl.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomRight,
            excludeFromSemantics: true,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 196),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const CampaignSymbol(size: 28),
                    const Spacer(),
                    PieceHeaderButton(piece: piece),
                  ],
                ),
                const SizedBox(height: greetingTopOffset),
                if (largeText)
                  greeting
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 58,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24, right: 6),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: greeting,
                          ),
                        ),
                      ),
                      const Spacer(flex: 51),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

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
            for (final InfoResource resource in homeResources)
              StudentPreviewCard(
                cover: resource.topic == InfoTopic.emociones
                    ? StudentCover.video
                    : resource.cover,
                title: resource.title,
                detail: resource.meta,
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
          alwaysSideBySide: true,
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
  const _AdaptiveRow({required this.children, this.alwaysSideBySide = false});

  final List<Widget> children;
  final bool alwaysSideBySide;

  @override
  Widget build(BuildContext context) {
    final bool stacked =
        !alwaysSideBySide &&
        (MediaQuery.sizeOf(context).width < 340 ||
            MediaQuery.textScalerOf(context).scale(16) > 22);
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

class _AyudaTab extends StatelessWidget {
  const _AyudaTab();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      EmergencyContactsCard(),
      SizedBox(height: 24),
      TrustedContactsSection(),
      SizedBox(height: 24),
      HelpFaqSection(),
    ],
  );
}
