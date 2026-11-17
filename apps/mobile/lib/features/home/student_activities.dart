import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';

/// Cinco actividades voluntarias; no otorgan XP ni registran respuestas.
class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bool stacked =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(16) > 17.6;
    const items = <(String, String, String)>[
      (
        'Semáforo de emociones',
        'assets/home/activities/sticker_semaforo_tarjeta.png',
        'semaforo',
      ),
      ('Dados emocionales', 'dado', 'dados'),
      (
        'Pregunta libre',
        'assets/home/activities/sticker_pregunta_hd.png',
        'pregunta',
      ),
      (
        'Dibujo libre',
        'assets/home/activities/sticker_dibujo_hoja.png',
        'dibujo',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ActivityCard(
          title: 'Rompecabezas del buen trato',
          sticker: 'assets/home/activities/rompecabezas_pareja.png',
          route: 'rompecabezas',
          featured: true,
        ),
        const SizedBox(height: 16),
        for (int row = 0; row < 2; row++) ...<Widget>[
          if (stacked)
            for (final item in items.skip(row * 2).take(2)) ...<Widget>[
              ActivityCard(title: item.$1, sticker: item.$2, route: item.$3),
              const SizedBox(height: 14),
            ]
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int col = 0; col < 2; col++) ...<Widget>[
                    if (col > 0) const SizedBox(width: 10),
                    Expanded(
                      child: ActivityCard(
                        title: items[row * 2 + col].$1,
                        sticker: items[row * 2 + col].$2,
                        route: items[row * 2 + col].$3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!stacked) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Tarjeta azul de actividad (patrón de campaña + sticker). La usa también
/// el Inicio para «Pregunta del día» y «Dado de emociones».
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.title,
    required this.sticker,
    required this.route,
    this.featured = false,
    this.detail,
    this.onTap,
  });
  final String title;
  final String sticker;
  final String route;
  final bool featured;

  /// Texto breve bajo el título (por ejemplo «+10 XP» o «Completada»).
  final String? detail;

  /// Acción propia; por defecto abre `/inicio/actividades/[route]`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: detail == null ? title : '$title, $detail',
    excludeSemantics: true,
    child: Material(
      color: CureandoTheme.blue,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink.image(
        image: const AssetImage('assets/welcome/campaign-pattern.png'),
        fit: BoxFit.cover,
        child: InkWell(
          onTap:
              onTap ?? () => context.push<void>('/inicio/actividades/$route'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: featured ? 146 : 122),
            child: Padding(
              padding: EdgeInsets.all(featured ? 14 : 6),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    sticker.contains('/')
                        ? sticker
                        : 'assets/home/info/stickers/sticker_$sticker.png',
                    width: featured ? 112 : 48,
                    height: featured ? 108 : 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: featured ? 20 : 14,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (detail != null && !featured) ...<Widget>[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              detail!,
                              style: const TextStyle(
                                color: CureandoTheme.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (featured) ...<Widget>[
                          const SizedBox(height: 6),
                          const Text(
                            'Uní piezas para ayudar',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text(
                                'Jugar ›',
                                style: TextStyle(
                                  color: CureandoTheme.blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
      ),
    ),
  );
}
