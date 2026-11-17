import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/svg_path_parser.dart';

/// Estado del tablero del Rompecabezas del buen trato.
enum PuzzleBoardState { disconnected, connected }

/// Trazado original de `assets/brand/elements/elemento-05-pieza-azul.svg`
/// (viewBox 300 × 250): cuerpo de 65–235.6 × 40–210 con una muesca a la
/// derecha y otra abajo.
const String _baseSvgPath =
    'M64.98,204.4V74.94c0-19.31,15.65-34.97,34.97-34.97h129.46c3.1,0,5.62,'
    '2.52,5.62,5.62v48.73c0,4.02-4.09,6.72-7.8,5.18-3.38-1.41-7.09-2.16-'
    '10.99-2.11-14.96.2-27.13,12.44-27.23,27.4s12.29,27.82,27.61,27.82c3.76,'
    '0,7.34-.75,10.6-2.11,3.71-1.54,7.8,1.12,7.8,5.14v48.76c0,3.1-2.52,5.62-'
    '5.62,5.62h-47.17c-3.65,0-6.38-3.43-5.47-6.97.58-2.29.88-4.69.85-7.16-'
    '.17-14.98-12.42-27.18-27.4-27.29-15.34-.11-27.82,12.29-27.82,27.61,0,'
    '2.34.29,4.61.84,6.77.9,3.57-1.76,7.03-5.44,7.03h-47.19c-3.1,0-5.62-'
    '2.52-5.62-5.62Z';

const double _bodyLeft = 65;
const double _bodyTop = 40;
const double _bodyRight = 235.6;
const double _bodyBottom = 210;
const double _knobShift = 90;

/// Pieza con saliente a la izquierda que calza en la muesca derecha de la
/// pieza base, en el mismo sistema de coordenadas del SVG original.
Path _knobPiecePath() {
  final Path body = Path()
    ..addRRect(
      RRect.fromLTRBAndCorners(
        _bodyRight,
        _bodyTop,
        _bodyRight + (_bodyRight - _bodyLeft),
        _bodyBottom,
        topRight: const Radius.circular(35),
        topLeft: const Radius.circular(5.6),
        bottomLeft: const Radius.circular(5.6),
        bottomRight: const Radius.circular(5.6),
      ),
    );
  final Path knob = Path()
    ..addOval(Rect.fromCircle(center: const Offset(208.4, 120), radius: 27.2))
    ..addRect(const Rect.fromLTRB(208.4, 93.6, _bodyRight + 1, 146.4));
  return Path.combine(PathOperation.union, body, knob);
}

/// Tablero con la pieza azul original y la pieza que encaja. Desconectado
/// muestra la silueta punteada; conectado desliza la pieza hasta encajar.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.state,
    this.pieceColor = CureandoTheme.yellow,
  });

  final PuzzleBoardState state;
  final Color pieceColor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: state == PuzzleBoardState.connected
        ? 'Piezas conectadas'
        : 'Piezas por conectar',
    child: Container(
      height: 176,
      decoration: BoxDecoration(
        color: const Color(0xFFD9E7FD),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: state == PuzzleBoardState.connected ? 1 : 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double t, _) => CustomPaint(
          painter: _PuzzleBoardPainter(progress: t, pieceColor: pieceColor),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

/// Pieza de opción: misma forma para todas las respuestas, cambia el color.
class PuzzleOptionPiece extends StatelessWidget {
  const PuzzleOptionPiece({super.key, required this.color, this.size = 44});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 0.8,
    child: CustomPaint(painter: _OptionPiecePainter(color)),
  );
}

class _OptionPiecePainter extends CustomPainter {
  const _OptionPiecePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path piece = _knobPiecePath();
    final Rect bounds = piece.getBounds();
    final double scale = math.min(
      size.width / bounds.width,
      size.height / bounds.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - bounds.width * scale) / 2,
        (size.height - bounds.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top)
      ..drawPath(piece, Paint()..color = color);
    _drawFace(canvas, Offset(bounds.right - 85, 115));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OptionPiecePainter old) => old.color != color;
}

void _drawFace(Canvas canvas, Offset c) {
  final Paint white = Paint()..color = Colors.white;
  final Paint ink = Paint()..color = const Color(0xFF1D1D1B);
  for (final double dx in <double>[-24, 24]) {
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(dx, 0), width: 24, height: 34),
      white,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(dx + 3, 3), width: 14, height: 22),
      ink,
    );
  }
  canvas.drawPath(
    Path()
      ..moveTo(c.dx - 22, c.dy + 32)
      ..quadraticBezierTo(c.dx, c.dy + 54, c.dx + 22, c.dy + 32),
    Paint()
      ..color = const Color(0xFF1D1D1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round,
  );
}

class _PuzzleBoardPainter extends CustomPainter {
  _PuzzleBoardPainter({required this.progress, required this.pieceColor});

  final double progress;
  final Color pieceColor;
  static final Path _base = parseSvgPath(_baseSvgPath);
  static final Path _knob = _knobPiecePath();

  @override
  void paint(Canvas canvas, Size size) {
    // Ancho total: pieza base + pieza encajada + margen para el deslizamiento.
    const double contentLeft = _bodyLeft;
    const double contentRight =
        _bodyRight + (_bodyRight - _bodyLeft) + _knobShift * 0.35;
    const double contentWidth = contentRight - contentLeft;
    const double contentHeight = _bodyBottom - _bodyTop;
    final double scale = math.min(
      (size.width - 72) / contentWidth,
      (size.height - 64) / contentHeight,
    );
    canvas
      ..save()
      ..translate(
        (size.width - contentWidth * scale) / 2,
        (size.height - contentHeight * scale) / 2,
      )
      ..scale(scale)
      ..translate(-contentLeft, -_bodyTop);

    canvas.drawPath(_base, Paint()..color = CureandoTheme.blue);
    _drawFace(canvas, const Offset(150, 115));

    final double t = progress.clamp(0.0, 1.2);
    if (t < 0.02) {
      _drawDashed(canvas, _knob);
      _drawSparks(canvas, const Offset(372, 34), CureandoTheme.yellow);
    } else {
      final double dx = (1 - t) * _knobShift;
      canvas
        ..save()
        ..translate(dx, 0);
      canvas.drawPath(
        _knob,
        Paint()..color = pieceColor.withValues(alpha: t.clamp(0.0, 1.0)),
      );
      _drawFace(canvas, const Offset(_bodyRight + 85, 115));
      canvas.restore();
      if (t > 0.9) {
        _drawSparks(canvas, const Offset(84, 24), const Color(0xFFFF0092));
        _drawSparks(canvas, const Offset(372, 34), CureandoTheme.yellow);
      }
    }
    canvas.restore();
  }

  void _drawDashed(Canvas canvas, Path path) {
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.6));
    final Paint stroke = Paint()
      ..color = CureandoTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 16, metric.length)),
          stroke,
        );
        d += 28;
      }
    }
  }

  void _drawSparks(Canvas canvas, Offset at, Color color) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(at + const Offset(-22, 10), at + const Offset(-30, -6), p)
      ..drawLine(at + const Offset(-6, 4), at + const Offset(-6, -14), p)
      ..drawLine(at + const Offset(10, 10), at + const Offset(20, -4), p);
  }

  @override
  bool shouldRepaint(_PuzzleBoardPainter old) =>
      old.progress != progress || old.pieceColor != pieceColor;
}
