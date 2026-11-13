import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_card.dart';
import '../../shared/widgets/setu_brand_mark.dart';

enum StudentCover {
  guide(CureandoTheme.yellow, Icons.sentiment_very_satisfied_rounded),
  video(Color(0xFFFF8AC7), Icons.forum_rounded),
  question(Color(0xFFEAE0FE), Icons.contact_support_outlined),
  dice(Color(0xFFD8FBE9), Icons.casino_rounded);

  const StudentCover(this.color, this.icon);
  final Color color;
  final IconData icon;
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
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  _CoverIcon(cover: cover, size: 37),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        label,
                        if (caption != null) ...<Widget>[
                          const SizedBox(height: 4),
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
    child: ColoredBox(
      color: cover.color,
      child: SizedBox(
        height: 100,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: -24,
              left: -22,
              child: BrandDecoration(
                motif: BrandMotif.spiral,
                color: Colors.white.withValues(alpha: .45),
                size: 80,
              ),
            ),
            Positioned(
              bottom: -24,
              right: -15,
              child: BrandDecoration(
                motif: BrandMotif.flower,
                color: cover == StudentCover.video
                    ? const Color(0xFFE8007E)
                    : const Color(0xFFFFA800),
                size: 82,
              ),
            ),
            _CoverIcon(cover: cover, size: 55),
            if (cover == StudentCover.video)
              const Positioned(
                right: 8,
                bottom: 8,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 19,
                    color: CureandoTheme.blue,
                  ),
                ),
              ),
          ],
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
    child: switch (cover) {
      StudentCover.video => SizedBox(
        width: size * 1.4,
        height: size,
        child: Stack(
          children: <Widget>[
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.chat_bubble_rounded,
                color: CureandoTheme.blue,
                size: size * .84,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Icon(Icons.chat_rounded, color: Colors.white, size: size),
            ),
            Positioned(
              left: size * .13,
              top: size * .14,
              child: Icon(
                Icons.more_horiz_rounded,
                color: CureandoTheme.pink,
                size: size * .73,
              ),
            ),
          ],
        ),
      ),
      StudentCover.dice => Transform.rotate(
        angle: -.18,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: CureandoTheme.blue, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cover.icon, size: size * .85, color: CureandoTheme.pink),
        ),
      ),
      _ => Icon(
        cover.icon,
        size: size,
        color: cover == StudentCover.guide ? Colors.white : CureandoTheme.blue,
      ),
    },
  );
}
