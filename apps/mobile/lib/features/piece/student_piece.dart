import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/svg_path_parser.dart';

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
    this.nickname = defaultNickname,
  });

  static const String defaultNickname = 'Pulgin Valiente';
  static const int maxNickname = 24;

  final PieceShape shape;
  final PieceColor color;
  final Set<PieceAccessory> accessories;

  /// Apodo de la pieza. Es un nombre de juego: nunca el nombre real.
  final String nickname;

  /// Apodo listo para guardar: sin espacios sobrantes, con tope de largo y
  /// con el apodo por defecto si queda vacío.
  static String cleanNickname(String? raw) {
    final String clean = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return defaultNickname;
    return clean.length > maxNickname
        ? clean.substring(0, maxNickname).trim()
        : clean;
  }

  static const StudentPiece initial = StudentPiece(
    shape: PieceShape.puzzle,
    color: PieceColor.green,
    accessories: <PieceAccessory>{PieceAccessory.cap, PieceAccessory.glasses},
  );

  /// Pieza al azar; conserva el apodo que se le pase.
  factory StudentPiece.random(
    math.Random random, {
    String nickname = defaultNickname,
  }) => StudentPiece(
    nickname: nickname,
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

  /// Forma serializable que viaja con la alerta. Lleva el apodo de la
  /// pieza (`displayName`); nunca nombres reales ni fotos.
  Map<String, Object?> toJson() => <String, Object?>{
    'displayName': nickname,
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
    String? displayName,
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
      nickname: cleanNickname(displayName),
    );
  }

  StudentPiece copyWith({
    PieceShape? shape,
    PieceColor? color,
    Set<PieceAccessory>? accessories,
    String? nickname,
  }) => StudentPiece(
    shape: shape ?? this.shape,
    color: color ?? this.color,
    accessories: accessories ?? this.accessories,
    nickname: nickname ?? this.nickname,
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

  static const String _personaje01BodySvg =
      'M226.99,53.4v94.28c0,14.06-11.4,25.47-25.47,25.47h-94.28c-2.26,0-4.08-1.83-4.08-4.08v-34.36c0-.11,0-.23-.01-.33-.2-2.48-2.59-4.28-5.06-3.65-1.66.42-3.41.64-5.22.62-10.9-.12-19.79-9.04-19.87-19.95-.09-11.18,8.95-20.26,20.11-20.26,1.71,0,3.36.21,4.94.61,2.26.57,4.46-.82,4.98-2.96.09-.31.13-.65.13-1v-34.39c0-2.25,1.82-4.08,4.08-4.08h35.5c2.92,0,4.89-2.97,3.76-5.67-1.02-2.46-1.58-5.17-1.54-8.01.15-10.9,9.06-19.75,19.95-19.83,11.17-.09,20.26,8.95,20.26,20.11,0,2.73-.54,5.34-1.54,7.72-1.12,2.7.82,5.68,3.75,5.68h35.51c2.26,0,4.09,1.83,4.09,4.08Z';

  static const String _personaje01LegLeftSvg =
      'M151.32,160.79h0c3.77,0,6.74,3.23,6.41,6.99l-5.23,60.53c-.31,3.57-3.47,6.2-7.03,5.85l-27.4-2.64c-3-.29-5.39-2.62-5.77-5.61-.72-5.71.18-13.95,11.78-12.68.23.03.46.04.69.04h9.29c3.28,0,6.04-2.47,6.4-5.74l4.46-41c.36-3.27,3.11-5.74,6.4-5.74Z';

  static const String _personaje01LegRightSvg =
      'M184.69,160.79h0c-3.77,0-6.74,3.23-6.41,6.99l5.23,60.53c.31,3.57,3.47,6.2,7.03,5.85l27.4-2.64c3-.29,5.39-2.62,5.77-5.61.72-5.71-.18-13.95-11.78-12.68-.23.03-.46.04-.69.04h-9.29c-3.28,0-6.04-2.47-6.4-5.74l-4.46-41c-.36-3.27-3.11-5.74-6.4-5.74Z';

  static const String _elemento06CornerSvg =
      'M223.55,190.06h-41.64c-3.22,0-5.63,3.03-4.83,6.15.51,2.02.78,4.14.75,6.32-.15,13.22-10.96,23.99-24.19,24.09s-24.55-10.85-24.55-24.37c0-2.07.26-4.07.74-5.99.79-3.14-1.55-6.19-4.79-6.19h-41.68c-2.73,0-4.95-2.22-4.95-4.95v-43.03c0-3.54-3.6-5.92-6.87-4.56-2.98,1.24-6.27,1.91-9.71,1.87-13.2-.18-23.94-10.98-24.04-24.19-.1-13.54,10.85-24.55,24.37-24.55,3.32,0,6.48.66,9.36,1.86,3.28,1.36,6.89-.99,6.89-4.54v-43.05c0-2.73,2.22-4.95,4.95-4.95h114.27c17.04,0,30.86,13.82,30.86,30.86v114.27c0,2.73-2.22,4.95-4.95,4.95Z';

  static const String _elemento10FlowerSvg =
      'M228.4,137.09l-26.8,4.2,21.1,17.03c10.88,8.76.95,25.96-12.09,20.94l-25.3-9.75,9.76,25.3c5.02,13.02-12.18,22.96-20.94,12.09l-17.03-21.11-4.2,26.8c-2.16,13.79-22.03,13.79-24.19,0l-4.19-26.8-17.03,21.11c-8.78,10.86-25.98.93-20.95-12.09l9.76-25.3-25.3,9.75c-13.02,5.02-22.96-12.18-12.09-20.94l21.1-17.03-26.78-4.2c-13.8-2.16-13.8-22.03,0-24.19l26.78-4.19-21.1-17.03c-10.86-8.78-.93-25.98,12.09-20.95l25.3,9.76-9.76-25.3c-5.02-13.02,12.18-22.96,20.95-12.09l17.03,21.09,4.19-26.78c2.16-13.8,22.03-13.8,24.19,0l4.2,26.78,17.03-21.09c8.76-10.86,25.96-.93,20.94,12.09l-9.76,25.3,25.3-9.76c13.04-5.02,22.97,12.18,12.09,20.95l-21.1,17.03,26.8,4.19c13.79,2.16,13.79,22.03,0,24.19Z';

  static Path _transformSvg(
    String d, {
    required Offset srcCenter,
    required Offset dstCenter,
    required double scale,
  }) {
    final double dx = dstCenter.dx - srcCenter.dx * scale;
    final double dy = dstCenter.dy - srcCenter.dy * scale;
    final Float64List matrix = Float64List.fromList(<double>[
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      dx,
      dy,
      0,
      1,
    ]);
    return parseSvgPath(d).transform(matrix);
  }

  // Maps `personaje-01.svg` (300x250) into the 100x124 piece canvas so
  // accessories (`glasses`, `bowTie`, `cap`) align with the character features.
  static final Path _svgPuzzleBody = _transformSvg(
    _personaje01BodySvg,
    srcCenter: const Offset(165, 111),
    dstCenter: const Offset(50, 54),
    scale: 0.385,
  );

  static final Path _svgCornerBody = _transformSvg(
    _elemento06CornerSvg,
    srcCenter: const Offset(152, 114),
    dstCenter: const Offset(50, 52),
    scale: 0.33,
  );

  static final Path _svgFlowerBody = _transformSvg(
    _elemento10FlowerSvg,
    srcCenter: const Offset(141, 125),
    dstCenter: const Offset(50, 52),
    scale: 0.32,
  );

  static final Path _svgLegs = _union(
    _transformSvg(
      _personaje01LegLeftSvg,
      srcCenter: const Offset(165, 111),
      dstCenter: const Offset(50, 54),
      scale: 0.385,
    ),
    _transformSvg(
      _personaje01LegRightSvg,
      srcCenter: const Offset(165, 111),
      dstCenter: const Offset(50, 54),
      scale: 0.385,
    ),
  );

  static Path _circle(double x, double y, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  static Path _rrect(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

  static Path _union(Path a, Path b) => Path.combine(PathOperation.union, a, b);

  Path _body() {
    final Path left = _circle(24, 54, 9);
    switch (piece.shape) {
      case PieceShape.puzzle:
        return _svgPuzzleBody;
      case PieceShape.doublePuzzle:
        return _svgCornerBody;
      case PieceShape.star:
        return Path.combine(
          PathOperation.difference,
          _svgFlowerBody,
          _circle(76, 52, 7.5),
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
        return _svgFlowerBody;
    }
  }

  Path _legs() => _svgLegs;

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
      final Paint black = Paint()..color = const Color(0xFF1D1D1B);
      for (final double x in <double>[41.7, 58.3]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 49.5), width: 10.6, height: 16.4),
          white,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + .3, 51.8), width: 7.4, height: 11.4),
          black,
        );
      }
      if (smile) {
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(50, 61.5), width: 11.5, height: 9.5),
          .25,
          math.pi - .5,
          false,
          Paint()
            ..color = const Color(0xFF1D1D1B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
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
