import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

/// Formas de pieza disponibles. Son dibujos de la marca: no usan fotos,
/// nombres ni datos de la persona.
enum PieceShape {
  puzzle('Rompecabezas'),
  doublePuzzle('Rompecabezas doble'),
  star('Estrella'),
  block('Bloque'),
  bell('Campana'),
  flower('Flor');

  const PieceShape(this.label);
  final String label;
}

/// Colores de pieza. Azul y amarillo son de marca; los demás son tonos
/// derivados de interfaz tomados de la maqueta de «Mi pieza».
enum PieceColor {
  green('Verde', Color(0xFF5FE68B), Color(0xFFE6FAEC)),
  yellow('Amarillo', CureandoTheme.yellow, Color(0xFFFFF6DC)),
  blue('Azul', CureandoTheme.blue, Color(0xFFDCE9FB)),
  pink('Rosa', Color(0xFFFF4FA3), Color(0xFFFFE4F1)),
  sky('Celeste', Color(0xFF5BB8FF), Color(0xFFDCEBFA)),
  lime('Lima', Color(0xFFA4E000), Color(0xFFEAF7D5));

  const PieceColor(this.label, this.color, this.soft);
  final String label;
  final Color color;
  final Color soft;
}

enum PieceAccessory {
  cap('Gorra'),
  glasses('Lentes'),
  bowTie('Corbatín');

  const PieceAccessory(this.label);
  final String label;
}

@immutable
class StudentPiece {
  const StudentPiece({
    required this.shape,
    required this.color,
    this.accessories = const <PieceAccessory>{},
  });

  final PieceShape shape;
  final PieceColor color;
  final Set<PieceAccessory> accessories;

  static const StudentPiece initial = StudentPiece(
    shape: PieceShape.puzzle,
    color: PieceColor.green,
    accessories: <PieceAccessory>{PieceAccessory.cap, PieceAccessory.glasses},
  );

  factory StudentPiece.random(math.Random random) => StudentPiece(
    shape: PieceShape.values[random.nextInt(PieceShape.values.length)],
    color: PieceColor.values[random.nextInt(PieceColor.values.length)],
    accessories: <PieceAccessory>{
      for (final PieceAccessory accessory in PieceAccessory.values)
        if (random.nextBool()) accessory,
    },
  );

  String get description {
    final String base = '${shape.label} de color ${color.label.toLowerCase()}';
    if (accessories.isEmpty) return base;
    final String extras = PieceAccessory.values
        .where(accessories.contains)
        .map((PieceAccessory a) => a.label.toLowerCase())
        .join(', ');
    return '$base con $extras';
  }

  /// Forma serializable que viaja con la alerta. No lleva nombres ni fotos.
  Map<String, Object?> toJson() => <String, Object?>{
    'shape': shape.name,
    'color': color.name,
    'accessories': <String>[
      for (final PieceAccessory accessory in PieceAccessory.values)
        if (accessories.contains(accessory)) accessory.name,
    ],
  };

  /// Reconstruye la pieza recibida; null si falta la forma o el color, o si
  /// no son valores conocidos.
  static StudentPiece? tryParse({
    String? shape,
    String? color,
    Iterable<String> accessories = const <String>[],
  }) {
    final PieceShape? parsedShape = PieceShape.values
        .where((PieceShape value) => value.name == shape)
        .firstOrNull;
    final PieceColor? parsedColor = PieceColor.values
        .where((PieceColor value) => value.name == color)
        .firstOrNull;
    if (parsedShape == null || parsedColor == null) return null;
    return StudentPiece(
      shape: parsedShape,
      color: parsedColor,
      accessories: <PieceAccessory>{
        for (final PieceAccessory accessory in PieceAccessory.values)
          if (accessories.contains(accessory.name)) accessory,
      },
    );
  }

  StudentPiece copyWith({
    PieceShape? shape,
    PieceColor? color,
    Set<PieceAccessory>? accessories,
  }) => StudentPiece(
    shape: shape ?? this.shape,
    color: color ?? this.color,
    accessories: accessories ?? this.accessories,
  );

  StudentPiece toggle(PieceAccessory accessory) => copyWith(
    accessories: accessories.contains(accessory)
        ? (<PieceAccessory>{...accessories}..remove(accessory))
        : <PieceAccessory>{...accessories, accessory},
  );
}

/// Dibujo vectorial de la pieza con contorno blanco tipo calcomanía.
class PieceFigure extends StatelessWidget {
  const PieceFigure({
    super.key,
    required this.piece,
    this.height = 120,
    this.sparks = false,
    this.face = true,
    this.smile = true,
    this.legs = true,
  });

  final StudentPiece piece;
  final double height;
  final bool sparks;
  final bool face;
  final bool smile;
  final bool legs;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: height * 100 / 124,
      height: height,
      child: CustomPaint(
        painter: _PiecePainter(
          piece,
          sparks: sparks,
          face: face,
          smile: smile,
          legs: legs,
        ),
      ),
    ),
  );
}

/// Insignia circular con la pieza, para encabezados.
class PieceBadge extends StatelessWidget {
  const PieceBadge({super.key, required this.piece, this.size = 56});

  final StudentPiece piece;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: piece.color.soft, shape: BoxShape.circle),
    foregroundDecoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: OverflowBox(
      maxHeight: size * 1.25,
      maxWidth: size * 1.25,
      alignment: const Alignment(0, -.35),
      child: PieceFigure(piece: piece, height: size * 1.25),
    ),
  );
}

class _PiecePainter extends CustomPainter {
  const _PiecePainter(
    this.piece, {
    required this.sparks,
    required this.face,
    required this.smile,
    required this.legs,
  });

  final StudentPiece piece;
  final bool sparks;
  final bool face;
  final bool smile;
  final bool legs;

  static Path _circle(double x, double y, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  static Path _rrect(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

  static Path _union(Path a, Path b) => Path.combine(PathOperation.union, a, b);

  static Path _petals(int count, double reach, double radius, double core) {
    Path path = _circle(50, 52, core);
    for (int i = 0; i < count; i++) {
      final double a = i * 2 * math.pi / count - math.pi / 2;
      path = _union(
        path,
        _circle(50 + reach * math.cos(a), 52 + reach * math.sin(a), radius),
      );
    }
    return path;
  }

  Path _body() {
    final Path square = _rrect(26, 28, 74, 76, 7);
    final Path top = _circle(50, 25, 9);
    final Path left = _circle(24, 54, 9);
    switch (piece.shape) {
      case PieceShape.puzzle:
        return Path.combine(
          PathOperation.difference,
          _union(_union(square, top), left),
          _circle(76, 54, 8),
        );
      case PieceShape.doublePuzzle:
        return _union(_union(_union(square, top), left), _circle(76, 54, 9));
      case PieceShape.star:
        return Path.combine(
          PathOperation.difference,
          _petals(12, 24, 5.5, 23),
          _circle(79, 52, 7),
        );
      case PieceShape.block:
        return _union(_rrect(27, 27, 75, 76, 12), left);
      case PieceShape.bell:
        return _union(
          Path()..addRRect(
            RRect.fromLTRBAndCorners(
              26,
              27,
              74,
              76,
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: const Radius.circular(7),
              bottomRight: const Radius.circular(7),
            ),
          ),
          _circle(50, 23, 8),
        );
      case PieceShape.flower:
        return _petals(8, 19, 10.5, 20);
    }
  }

  Path _legs() => _union(
    _union(_rrect(36, 68, 43, 109, 3.5), _rrect(27, 101, 43, 109, 4)),
    _union(_rrect(57, 68, 64, 109, 3.5), _rrect(57, 101, 73, 109, 4)),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.height / 124;
    canvas.save();
    canvas.scale(k);
    final Paint outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()..color = piece.color.color;
    final Path figure = legs ? _union(_body(), _legs()) : _body();
    canvas.drawPath(
      figure.shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0x260F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(figure, outline);
    canvas.drawPath(figure, fill);

    if (face) {
      final Paint white = Paint()..color = Colors.white;
      final Paint black = Paint()..color = Colors.black;
      for (final double x in <double>[42, 58]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 50), width: 9.5, height: 13.5),
          white,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + .6, 51), width: 5.6, height: 9),
          black,
        );
      }
      if (smile) {
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(50, 60), width: 12, height: 10),
          .25,
          math.pi - .5,
          false,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    if (piece.accessories.contains(PieceAccessory.glasses)) {
      final Paint frame = Paint()
        ..color = CureandoTheme.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(const Offset(41.5, 50), 9, frame);
      canvas.drawCircle(const Offset(58.5, 50), 9, frame);
      canvas.drawLine(const Offset(26, 49), const Offset(32.5, 49.5), frame);
      canvas.drawLine(const Offset(67.5, 49.5), const Offset(74, 49), frame);
    }

    if (piece.accessories.contains(PieceAccessory.bowTie)) {
      final Paint pink = Paint()..color = CureandoTheme.pink;
      final Path bow = Path()
        ..moveTo(50, 71)
        ..lineTo(40, 65.5)
        ..lineTo(40, 76.5)
        ..close()
        ..moveTo(50, 71)
        ..lineTo(60, 65.5)
        ..lineTo(60, 76.5)
        ..close();
      canvas.drawPath(
        bow,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(bow, pink);
      canvas.drawCircle(const Offset(50, 71), 2.8, pink);
    }

    if (piece.accessories.contains(PieceAccessory.cap)) {
      final Path dome = Path()
        ..moveTo(33, 27)
        ..cubicTo(32, 4, 68, 2, 70, 24)
        ..close();
      final Path visor = Path()
        ..moveTo(52, 22)
        ..cubicTo(64, 14, 86, 20, 88, 28)
        ..cubicTo(80, 33, 62, 31, 52, 26)
        ..close();
      final Path cap = _union(_union(dome, visor), _circle(51, 6, 2.6));
      canvas.drawPath(cap, outline..strokeWidth = 5);
      canvas.drawPath(cap, Paint()..color = CureandoTheme.yellow);
      canvas.drawPath(
        Path()
          ..moveTo(54, 25)
          ..cubicTo(64, 30, 80, 32, 88, 28),
        Paint()
          ..color = const Color(0xFFE0B400)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    if (sparks) {
      final Paint spark = Paint()
        ..color = CureandoTheme.yellow
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(8, 30), const Offset(17, 32), spark);
      canvas.drawLine(const Offset(11, 17), const Offset(19, 24), spark);
      canvas.drawLine(const Offset(22, 8), const Offset(26, 17), spark);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.piece.shape != piece.shape ||
      old.piece.color != piece.color ||
      old.sparks != sparks ||
      old.face != face ||
      old.smile != smile ||
      old.legs != legs ||
      old.piece.accessories.length != piece.accessories.length ||
      !old.piece.accessories.containsAll(piece.accessories);
}

/// Línea ondulada punteada, motivo decorativo de la campaña.
class DashedWave extends StatelessWidget {
  const DashedWave({super.key, required this.color, this.height = 40});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter(color)),
    ),
  );
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path wave = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final double y =
          size.height / 2 +
          math.sin(x / size.width * 2.6 * math.pi) * (size.height / 2 - 3);
      x == 0 ? wave.moveTo(x, y) : wave.lineTo(x, y);
    }
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final ui.PathMetric metric in wave.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 16) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 8, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}
