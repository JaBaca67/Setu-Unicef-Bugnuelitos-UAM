import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SetuBrandMark extends StatelessWidget {
  const SetuBrandMark({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'SéTú',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: const SetuBrandMarkPainter()),
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

enum BrandMotif { puzzle, flower, spiral }

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

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    switch (motif) {
      case BrandMotif.puzzle:
        Path shape = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(s * .16, s * .16, s * .68, s * .68),
              Radius.circular(s * .12),
            ),
          );
        shape = Path.combine(
          PathOperation.union,
          shape,
          Path()..addOval(
            Rect.fromCircle(center: Offset(s * .5, s * .16), radius: s * .14),
          ),
        );
        shape = Path.combine(
          PathOperation.difference,
          shape,
          Path()..addOval(
            Rect.fromCircle(center: Offset(s * .84, s * .5), radius: s * .14),
          ),
        );
        canvas.drawPath(shape, paint);
      case BrandMotif.flower:
        canvas.save();
        canvas.translate(s / 2, s / 2);
        canvas.drawCircle(Offset.zero, s * .29, paint);
        for (int i = 0; i < 12; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 6);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-s * .065, -s * .48, s * .13, s * .36),
              Radius.circular(s * .065),
            ),
            paint,
          );
          canvas.restore();
        }
        canvas.restore();
      case BrandMotif.spiral:
        final Path path = Path();
        for (int i = 0; i <= 210; i++) {
          final double t = i / 210;
          final double a = t * math.pi * 3.5;
          final double r = s * (.025 + .4 * t);
          final double x = s / 2 + r * math.cos(a);
          final double y = s / 2 + r * math.sin(a);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(
          path,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .11
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(BrandMotifPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.motif != motif;
}
