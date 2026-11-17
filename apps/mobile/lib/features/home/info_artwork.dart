import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import 'info_catalog.dart';

extension InfoTopicArtwork on InfoTopic {
  // Sin fondos amarillos: con el patrón encima el #FFE000 se veía mostaza.
  Color get color => switch (this) {
    InfoTopic.acoso ||
    InfoTopic.depresion ||
    InfoTopic.apoyo => CureandoTheme.blue,
    InfoTopic.ciberacoso => CureandoTheme.pink,
    InfoTopic.ansiedad || InfoTopic.emociones => CureandoTheme.green,
  };

  Color get ink =>
      color == CureandoTheme.green ? CureandoTheme.ink : Colors.white;
}

/// Personajes oficiales de la campaña (flor azul y pieza amarilla) sobre una
/// insignia blanca, para que contrasten con el fondo.
class OfficialCharactersBadge extends StatelessWidget {
  const OfficialCharactersBadge({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .14),
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: Image.asset(
      'assets/home/activities/rompecabezas_pareja.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}

/// Los PNG transparentes conservan su silueta sobre una superficie de marca.
class InfoArtwork extends StatelessWidget {
  const InfoArtwork({super.key, required this.asset, required this.topic});

  final String asset;
  final InfoTopic topic;

  @override
  Widget build(BuildContext context) {
    final bool sticker = asset.contains('/stickers/');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: topic.color,
        image: sticker
            ? const DecorationImage(
                image: AssetImage('assets/welcome/campaign-pattern.png'),
                fit: BoxFit.cover,
                opacity: .12,
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(sticker ? 10 : 0),
        child: Image.asset(
          asset,
          fit: sticker ? BoxFit.contain : BoxFit.cover,
          // Los banners 3:1 llevan al niño en el tercio izquierdo: las
          // miniaturas cuadradas y las portadas 2:1 lo mantienen a la vista.
          alignment: asset.contains('/banners/')
              ? Alignment.centerLeft
              : Alignment.center,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
