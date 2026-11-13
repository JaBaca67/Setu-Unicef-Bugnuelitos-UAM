import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_card.dart';

enum StudentCover {
  guide(
    CureandoTheme.yellow,
    Icons.sentiment_very_satisfied_rounded,
    'assets/home/guia-emociones.png',
  ),
  video(
    Color(0xFFFF8AC7),
    Icons.forum_rounded,
    'assets/home/video-convivencia.png',
  ),
  question(
    Color(0xFFE9E0FD),
    Icons.contact_support_outlined,
    'assets/home/pregunta-del-dia.png',
  ),
  dice(
    Color(0xFFDBFBE3),
    Icons.casino_rounded,
    'assets/home/dado-de-emociones.png',
  );

  const StudentCover(this.color, this.icon, this.assetPath);
  final Color color;
  final IconData icon;
  final String assetPath;
}

class StudentPreviewCard extends StatelessWidget {
  const StudentPreviewCard({
    super.key,
    required this.cover,
    required this.title,
    required this.onTap,
    this.detail,
    this.compact = false,
  });

  final StudentCover cover;
  final String title;
  final VoidCallback onTap;
  final String? detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: CureandoTheme.ink,
      ),
    );
    final Widget? caption = detail == null
        ? null
        : Text(
            detail!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CureandoTheme.blue,
              fontWeight: FontWeight.w700,
            ),
          );
    return SetuCard(
      onTap: onTap,
      color: compact ? cover.color : Colors.white,
      child: compact
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: <Widget>[
                  _CoverIcon(cover: cover, size: 44),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        label,
                        if (caption != null) ...<Widget>[
                          const SizedBox(height: 3),
                          caption,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ResourceArtwork(cover: cover),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (caption != null) ...<Widget>[
                        caption,
                        const SizedBox(height: 2),
                      ],
                      label,
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ResourceArtwork extends StatelessWidget {
  const _ResourceArtwork({required this.cover});

  final StudentCover cover;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 291 / 153,
          child: Image.asset(
            cover.assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}

class _CoverIcon extends StatelessWidget {
  const _CoverIcon({required this.cover, required this.size});

  final StudentCover cover;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          cover.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
