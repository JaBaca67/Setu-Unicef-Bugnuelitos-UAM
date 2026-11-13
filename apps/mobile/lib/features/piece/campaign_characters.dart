import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/setu_brand_mark.dart';
import 'student_piece.dart';

/// Ilustración de campaña completa para encabezados azules: espiral, pieza
/// amarilla, pieza azul y flor, unidas por trazos punteados. Se dibuja en
/// vector para que nunca quede recortada y se adapta al espacio disponible.
class CampaignCharacters extends StatelessWidget {
  const CampaignCharacters({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 312,
        height: 158,
        child: Stack(
          children: const <Widget>[
            Positioned.fill(child: CustomPaint(painter: _ArcsPainter())),
            Positioned(
              left: 2,
              top: 42,
              child: BrandDecoration(
                motif: BrandMotif.spiral,
                color: CureandoTheme.green,
                size: 50,
              ),
            ),
            Positioned(
              left: 60,
              top: 44,
              child: PieceFigure(
                piece: StudentPiece(
                  shape: PieceShape.puzzle,
                  color: PieceColor.yellow,
                ),
                height: 112,
                smile: false,
              ),
            ),
            Positioned(
              left: 140,
              top: 44,
              child: PieceFigure(
                piece: StudentPiece(
                  shape: PieceShape.star,
                  color: PieceColor.blue,
                ),
                height: 112,
                smile: false,
              ),
            ),
            Positioned(
              left: 224,
              top: 68,
              child: BrandDecoration(
                motif: BrandMotif.flower,
                color: CureandoTheme.yellow,
                size: 86,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ArcsPainter extends CustomPainter {
  const _ArcsPainter();

  static void _dashed(Canvas canvas, Path path, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 15) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 8, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _dashed(
      canvas,
      Path()
        ..moveTo(44, 60)
        ..quadraticBezierTo(52, 10, 122, 14),
      Colors.white,
    );
    _dashed(
      canvas,
      Path()
        ..moveTo(196, 22)
        ..quadraticBezierTo(262, 12, 270, 66),
      CureandoTheme.pink,
    );
  }

  @override
  bool shouldRepaint(_ArcsPainter oldDelegate) => false;
}
