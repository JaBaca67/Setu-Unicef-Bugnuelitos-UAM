import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

final RegExp _svgTokenPattern = RegExp(
  r'[+-]?(?:\d*\.\d+|\d+\.?)(?:[eE][+-]?\d+)?|[A-Za-z]',
);

/// Parses an SVG path `d` string into a Flutter [ui.Path].
///
/// Supports `M/m`, `L/l`, `H/h`, `V/v`, `C/c`, `S/s`, and `Z/z` commands.
ui.Path parseSvgPath(
  String d, {
  ui.PathFillType fillType = ui.PathFillType.nonZero,
}) {
  final List<String> tokens = _svgTokenPattern
      .allMatches(d)
      .map((Match m) => m.group(0)!)
      .toList();
  final ui.Path path = ui.Path()..fillType = fillType;
  int i = 0;
  String cmd = '';
  double cx = 0;
  double cy = 0;
  double sx = 0;
  double sy = 0;
  double? lastC2x;
  double? lastC2y;
  String lastCmd = '';

  double nextNum() => double.parse(tokens[i++]);
  bool isCmd(String token) {
    if (token.length != 1) return false;
    final int code = token.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        cx = sx;
        cy = sy;
        lastCmd = cmd;
        continue;
      }
    }
    switch (cmd) {
      case 'M':
        cx = nextNum();
        cy = nextNum();
        sx = cx;
        sy = cy;
        path.moveTo(cx, cy);
        lastCmd = 'M';
        cmd = 'L';
      case 'm':
        cx += nextNum();
        cy += nextNum();
        sx = cx;
        sy = cy;
        path.moveTo(cx, cy);
        lastCmd = 'm';
        cmd = 'l';
      case 'L':
        cx = nextNum();
        cy = nextNum();
        path.lineTo(cx, cy);
        lastCmd = 'L';
      case 'l':
        cx += nextNum();
        cy += nextNum();
        path.lineTo(cx, cy);
        lastCmd = 'l';
      case 'H':
        cx = nextNum();
        path.lineTo(cx, cy);
        lastCmd = 'H';
      case 'h':
        cx += nextNum();
        path.lineTo(cx, cy);
        lastCmd = 'h';
      case 'V':
        cy = nextNum();
        path.lineTo(cx, cy);
        lastCmd = 'V';
      case 'v':
        cy += nextNum();
        path.lineTo(cx, cy);
        lastCmd = 'v';
      case 'C':
        final double x1 = nextNum();
        final double y1 = nextNum();
        final double x2 = nextNum();
        final double y2 = nextNum();
        final double x3 = nextNum();
        final double y3 = nextNum();
        path.cubicTo(x1, y1, x2, y2, x3, y3);
        lastC2x = x2;
        lastC2y = y2;
        cx = x3;
        cy = y3;
        lastCmd = 'C';
      case 'c':
        final double x1 = cx + nextNum();
        final double y1 = cy + nextNum();
        final double x2 = cx + nextNum();
        final double y2 = cy + nextNum();
        final double x3 = cx + nextNum();
        final double y3 = cy + nextNum();
        path.cubicTo(x1, y1, x2, y2, x3, y3);
        lastC2x = x2;
        lastC2y = y2;
        cx = x3;
        cy = y3;
        lastCmd = 'c';
      case 'S':
        final bool hadCubic =
            lastCmd == 'c' ||
            lastCmd == 's' ||
            lastCmd == 'C' ||
            lastCmd == 'S';
        final double x1 = hadCubic && lastC2x != null ? 2 * cx - lastC2x : cx;
        final double y1 = hadCubic && lastC2y != null ? 2 * cy - lastC2y : cy;
        final double x2 = nextNum();
        final double y2 = nextNum();
        final double x3 = nextNum();
        final double y3 = nextNum();
        path.cubicTo(x1, y1, x2, y2, x3, y3);
        lastC2x = x2;
        lastC2y = y2;
        cx = x3;
        cy = y3;
        lastCmd = 'S';
      case 's':
        final bool hadCubic =
            lastCmd == 'c' ||
            lastCmd == 's' ||
            lastCmd == 'C' ||
            lastCmd == 'S';
        final double x1 = hadCubic && lastC2x != null ? 2 * cx - lastC2x : cx;
        final double y1 = hadCubic && lastC2y != null ? 2 * cy - lastC2y : cy;
        final double x2 = cx + nextNum();
        final double y2 = cy + nextNum();
        final double x3 = cx + nextNum();
        final double y3 = cy + nextNum();
        path.cubicTo(x1, y1, x2, y2, x3, y3);
        lastC2x = x2;
        lastC2y = y2;
        cx = x3;
        cy = y3;
        lastCmd = 's';
      default:
        throw FormatException('Comando SVG no soportado: $cmd');
    }
  }
  return path;
}

/// Combines and normalizes SVG paths into the unit square `0..1 x 0..1`.
ui.Path normalizeSvgPaths(
  List<String> paths, {
  ui.PathFillType fillType = ui.PathFillType.evenOdd,
}) {
  final ui.Path combined = ui.Path()..fillType = fillType;
  for (final String d in paths) {
    combined.addPath(parseSvgPath(d), ui.Offset.zero);
  }
  final ui.Rect bounds = combined.getBounds();
  final double maxDim = math.max(bounds.width, bounds.height);
  final double scale = maxDim > 0 ? 1 / maxDim : 1;
  final double dx = (1 - bounds.width * scale) / 2 - bounds.left * scale;
  final double dy = (1 - bounds.height * scale) / 2 - bounds.top * scale;
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
  return combined.transform(matrix)..fillType = fillType;
}
