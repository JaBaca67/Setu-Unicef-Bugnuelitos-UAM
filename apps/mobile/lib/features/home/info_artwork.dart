import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import 'info_catalog.dart';

extension InfoTopicArtwork on InfoTopic {
  Color get color => switch (this) {
    InfoTopic.acoso => CureandoTheme.yellow,
    InfoTopic.ansiedad || InfoTopic.apoyo => CureandoTheme.blue,
    InfoTopic.ciberacoso => CureandoTheme.pink,
    InfoTopic.emociones || InfoTopic.depresion => CureandoTheme.green,
  };

  Color get ink =>
      color == CureandoTheme.blue ? Colors.white : CureandoTheme.ink;

  String get sticker =>
      'assets/home/info/stickers/${switch (this) {
        InfoTopic.acoso => 'sticker_rompecabezas',
        InfoTopic.ansiedad => 'sticker_semaforo',
        InfoTopic.depresion => 'sticker_dibujo',
        InfoTopic.ciberacoso => 'sticker_pregunta',
        InfoTopic.emociones => 'sticker_dado',
        InfoTopic.apoyo => 'sticker_pieza_azul',
      }}.png';
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
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
