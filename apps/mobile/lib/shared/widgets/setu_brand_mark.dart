import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'svg_path_parser.dart';

class SetuBrandMark extends StatelessWidget {
  const SetuBrandMark({
    super.key,
    this.size = 64,
    this.color = CureandoTheme.blue,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'SéTú',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: SetuBrandMarkPainter(color: color)),
    ),
  );
}

class SetuBrandMarkPainter extends CustomPainter {
  const SetuBrandMarkPainter({this.color = CureandoTheme.blue});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double r = s * (42.734 / 87.6853);
    final double g = s - 2 * r;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final Path topLeft = Path()
      ..moveTo(0, 0)
      ..lineTo(r, 0)
      ..arcToPoint(Offset(0, r), radius: Radius.circular(r))
      ..close();
    final Path bottomLeft = Path()
      ..moveTo(0, s)
      ..lineTo(0, r + g)
      ..arcToPoint(Offset(r, s), radius: Radius.circular(r))
      ..close();
    final double x0 = r + g;
    final Path rightLeaf = Path()
      ..moveTo(x0, 0)
      ..arcToPoint(Offset(s, r), radius: Radius.circular(r))
      ..lineTo(s, s)
      ..arcToPoint(Offset(x0, s - r), radius: Radius.circular(r))
      ..close();
    canvas.drawPath(topLeft, paint);
    canvas.drawPath(bottomLeft, paint);
    canvas.drawPath(rightLeaf, paint);
  }

  @override
  bool shouldRepaint(SetuBrandMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

enum BrandMotif { puzzle, roundedPuzzle, flower, spiral }

class BrandDecoration extends StatelessWidget {
  const BrandDecoration({
    super.key,
    required this.motif,
    this.color = CureandoTheme.blue,
    this.size = 48,
  });

  final BrandMotif motif;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: BrandMotifPainter(motif, color)),
    ),
  );
}

class BrandMotifPainter extends CustomPainter {
  const BrandMotifPainter(this.motif, this.color);

  final BrandMotif motif;
  final Color color;

  static final Map<BrandMotif, Path> _pathCache = <BrandMotif, Path>{};

  static const Map<BrandMotif, String> _svgPaths = <BrandMotif, String>{
    BrandMotif.puzzle:
        'M64.98,204.4V74.94c0-19.31,15.65-34.97,34.97-34.97h129.46c3.1,0,5.62,2.52,5.62,5.62v48.73c0,4.02-4.09,6.72-7.8,5.18-3.38-1.41-7.09-2.16-10.99-2.11-14.96.2-27.13,12.44-27.23,27.4s12.29,27.82,27.61,27.82c3.76,0,7.34-.75,10.6-2.11,3.71-1.54,7.8,1.12,7.8,5.14v48.76c0,3.1-2.52,5.62-5.62,5.62h-47.17c-3.65,0-6.38-3.43-5.47-6.97.58-2.29.88-4.69.85-7.16-.17-14.98-12.42-27.18-27.4-27.29-15.34-.11-27.82,12.29-27.82,27.61,0,2.34.29,4.61.84,6.77.9,3.57-1.76,7.03-5.44,7.03h-47.19c-3.1,0-5.62-2.52-5.62-5.62Z',
    BrandMotif.roundedPuzzle:
        'M223.55,190.06h-41.64c-3.22,0-5.63,3.03-4.83,6.15.51,2.02.78,4.14.75,6.32-.15,13.22-10.96,23.99-24.19,24.09s-24.55-10.85-24.55-24.37c0-2.07.26-4.07.74-5.99.79-3.14-1.55-6.19-4.79-6.19h-41.68c-2.73,0-4.95-2.22-4.95-4.95v-43.03c0-3.54-3.6-5.92-6.87-4.56-2.98,1.24-6.27,1.91-9.71,1.87-13.2-.18-23.94-10.98-24.04-24.19-.1-13.54,10.85-24.55,24.37-24.55,3.32,0,6.48.66,9.36,1.86,3.28,1.36,6.89-.99,6.89-4.54v-43.05c0-2.73,2.22-4.95,4.95-4.95h114.27c17.04,0,30.86,13.82,30.86,30.86v114.27c0,2.73-2.22,4.95-4.95,4.95Z',
    BrandMotif.flower:
        'M228.4,137.09l-26.8,4.2,21.1,17.03c10.88,8.76.95,25.96-12.09,20.94l-25.3-9.75,9.76,25.3c5.02,13.02-12.18,22.96-20.94,12.09l-17.03-21.11-4.2,26.8c-2.16,13.79-22.03,13.79-24.19,0l-4.19-26.8-17.03,21.11c-8.78,10.86-25.98.93-20.95-12.09l9.76-25.3-25.3,9.75c-13.02,5.02-22.96-12.18-12.09-20.94l21.1-17.03-26.78-4.2c-13.8-2.16-13.8-22.03,0-24.19l26.78-4.19-21.1-17.03c-10.86-8.78-.93-25.98,12.09-20.95l25.3,9.76-9.76-25.3c-5.02-13.02,12.18-22.96,20.95-12.09l17.03,21.09,4.19-26.78c2.16-13.8,22.03-13.8,24.19,0l4.2,26.78,17.03-21.09c8.76-10.86,25.96-.93,20.94,12.09l-9.76,25.3,25.3-9.76c13.04-5.02,22.97,12.18,12.09,20.95l-21.1,17.03,26.8,4.19c13.79,2.16,13.79,22.03,0,24.19Z',
    BrandMotif.spiral:
        'M129.34,39.98c54.61,0,98.88,44.27,98.88,98.88,0,39.3-31.86,71.17-71.17,71.17-28.29,0-51.22-22.93-51.22-51.22,0-20.36,16.51-36.87,36.87-36.87,14.66,0,26.54,11.88,26.54,26.54,0,10.55-8.55,19.1-19.1,19.1-7.59,0-13.75-6.16-13.75-13.75,0-5.46,4.43-9.9,9.9-9.9,3.93,0,7.12,3.19,7.12,7.12,0,2.83-2.3,5.13-5.13,5.13-2.04,0-3.69-1.65-3.69-3.69,0-1.47,1.19-2.66,2.66-2.66,1.06,0,1.91.86,1.91,1.91,0,.76-.62,1.38-1.38,1.38-.55,0-.99-.44-.99-.99,0-.39.32-.71.71-.71.28,0,.51.23.51.51,0,.2-.17.37-.37.37',
  };

  static Path _pathFor(BrandMotif motif) => _pathCache.putIfAbsent(
    motif,
    () => normalizeSvgPaths(<String>[_svgPaths[motif]!]),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    canvas.save();
    if (motif == BrandMotif.spiral) {
      // Reserve stroke width margin (20 / ~170 SVG units ≈ 0.12) inside bounds.
      canvas.translate(s * 0.06, s * 0.06);
      canvas.scale(s * 0.88);
      canvas.drawPath(
        _pathFor(motif),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      canvas.scale(s);
      canvas.drawPath(_pathFor(motif), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMotifPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.motif != motif;
}
