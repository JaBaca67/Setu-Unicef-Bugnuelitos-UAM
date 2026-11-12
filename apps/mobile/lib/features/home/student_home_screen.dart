import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/campaign_screen.dart';
import 'student_activities.dart';
import 'student_avatar.dart';
import 'student_resources.dart';

/// Destinos de la navegación inferior del inicio estudiantil (E03).
enum HomeSection {
  inicio('Inicio', Icons.home_outlined, Icons.home_rounded),
  informacion('Información', Icons.menu_book_outlined, Icons.menu_book_rounded),
  actividades('Actividades', Icons.extension_outlined, Icons.extension_rounded),
  ayuda(
    'Ayuda',
    Icons.volunteer_activism_outlined,
    Icons.volunteer_activism_rounded,
  );

  const HomeSection(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Inicio estudiantil E03. Reúne «Pedir apoyo», adelantos de Información y
/// Actividades, y la navegación inferior. El estudiante no tiene una sección
/// de seguimiento de casos: tras pedir apoyo puede recibir un aviso que abre
/// su chat cuando una persona autorizada esté disponible.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  HomeSection _section = HomeSection.inicio;
  StudentAvatar _avatar = StudentAvatar.initial;

  Future<void> _editAvatar() async {
    final StudentAvatar? updated = await showAvatarEditor(context, _avatar);
    if (updated != null && mounted) setState(() => _avatar = updated);
  }

  void _open(HomeSection section) => setState(() => _section = section);

  @override
  Widget build(BuildContext context) => CampaignScreen(
    bodyRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    bottomNavigationBar: _navigationBar(context),
    header: switch (_section) {
      HomeSection.inicio => _HomeHeader(avatar: _avatar, onAvatar: _editAvatar),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: switch (_section) {
        HomeSection.inicio => _InicioTab(onOpenSection: _open),
        HomeSection.informacion => const _InformacionTab(),
        HomeSection.actividades => const ActivitiesTab(),
        HomeSection.ayuda => const _AyudaTab(),
      },
    ),
  );

  Widget _navigationBar(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: CureandoTheme.blueSoft,
        selectedIndex: _section.index,
        onDestinationSelected: (int index) =>
            _open(HomeSection.values[index]),
        destinations: <Widget>[
          for (final HomeSection section in HomeSection.values)
            NavigationDestination(
              icon: Icon(section.icon),
              selectedIcon: Icon(section.selectedIcon, color: CureandoTheme.blue),
              label: section.label,
            ),
        ],
      ),
    ),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.avatar, required this.onAvatar});

  final StudentAvatar avatar;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      const SizedBox(height: 10),
      const CampaignSymbol(size: 30),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                label: '¡Hola! ¿Qué querés hacer hoy?',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text(
                      '¡Hola! 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '¿Qué querés hacer hoy?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Tooltip(
              message: 'Personalizar tu avatar',
              child: Semantics(
                button: true,
                label: 'Tu avatar virtual: ${avatar.description}. '
                    'Tocá para personalizarlo.',
                child: InkWell(
                  onTap: onAvatar,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      StudentAvatarBadge(avatar: avatar, size: 56),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: ExcludeSemantics(
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: CureandoTheme.yellow,
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: CureandoTheme.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52),
        child: AspectRatio(
          aspectRatio: 392 / 180,
          child: Image.asset(
            'assets/welcome/campaign-characters.png',
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
    child: Column(
      children: <Widget>[
        const CampaignSymbol(size: 30),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        ),
      ],
    ),
  );
}

class _InicioTab extends StatelessWidget {
  const _InicioTab({required this.onOpenSection});

  final ValueChanged<HomeSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: CureandoTheme.pink,
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
          icon: const Icon(Icons.favorite_rounded),
          label: const Text('Pedir apoyo'),
        ),
        const SizedBox(height: 14),
        const _StreakStrip(),
        const SizedBox(height: 22),
        _SectionTitle(
          title: 'Explorá a tu ritmo',
          onSeeAll: () => onOpenSection(HomeSection.informacion),
        ),
        const SizedBox(height: 10),
        _AdaptiveRow(
          children: <Widget>[
            for (final SampleResource resource in sampleResources)
              _ResourcePreviewCard(resource: resource),
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
            _ActivityPreviewCard(
              icon: Icons.quiz_outlined,
              iconColor: CureandoTheme.blue,
              tint: CureandoTheme.blueSoft,
              title: 'Pregunta del día',
              detail: '+10 XP · ejemplo',
              onTap: () => onOpenSection(HomeSection.actividades),
            ),
            _ActivityPreviewCard(
              icon: Icons.casino_outlined,
              iconColor: CureandoTheme.pink,
              tint: CureandoTheme.pinkSoft,
              title: 'Dado de emociones',
              detail: 'Jugá sin registrar nada',
              onTap: () => onOpenSection(HomeSection.actividades),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Pedir apoyo, el chat, Información y Ayuda están siempre '
          'disponibles, con o sin XP.',
          style: textTheme.bodyMedium?.copyWith(
            color: CureandoTheme.secondaryInk,
          ),
        ),
      ],
    );
  }
}

/// Franja compacta de racha y XP. Valores de ejemplo: la demo no registra
/// progreso real y los XP solo acompañan actividades educativas voluntarias.
class _StreakStrip extends StatelessWidget {
  const _StreakStrip();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Racha de 3 días y 120 XP. Valores de ejemplo por actividades '
        'educativas voluntarias.',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CureandoTheme.yellowSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: const <Widget>[
          _StreakItem(
            icon: Icons.local_fire_department_rounded,
            color: CureandoTheme.pink,
            text: '3 días',
          ),
          _StreakItem(
            icon: Icons.star_rounded,
            color: CureandoTheme.blue,
            text: '120 XP',
          ),
          Text(
            'Ejemplo',
            style: TextStyle(
              color: CureandoTheme.secondaryInk,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StreakItem extends StatelessWidget {
  const _StreakItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
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

class _ResourcePreviewCard extends StatelessWidget {
  const _ResourcePreviewCard({required this.resource});

  final SampleResource resource;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push<void>(resource.route),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: resource.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(resource.icon, color: resource.inkColor),
            ),
            const SizedBox(height: 10),
            Text(
              resource.format,
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
          ],
        ),
      ),
    ),
  );
}

class _ActivityPreviewCard extends StatelessWidget {
  const _ActivityPreviewCard({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              detail,
              style: const TextStyle(
                color: CureandoTheme.secondaryInk,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push<void>(resource.route),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: resource.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(resource.icon, color: resource.inkColor),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
        onPressed: () => context.push<void>('/inicio/apoyo'),
        icon: const Icon(Icons.favorite_rounded),
        label: const Text('Pedir apoyo'),
      ),
    ],
  );
}
