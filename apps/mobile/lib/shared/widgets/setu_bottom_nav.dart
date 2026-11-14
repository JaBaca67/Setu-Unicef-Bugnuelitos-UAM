import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Destinos de la navegación inferior de SéTú (basados en NavBar-01.svg).
enum HomeSection {
  inicio('Inicio'),
  informacion('Información'),
  actividades('Actividades'),
  ayuda('Ayuda');

  const HomeSection(this.label);

  final String label;
}

/// Pedido de abrir una pestaña del inicio desde otra pantalla. Cada pedido
/// es una instancia nueva para que repetir la misma pestaña vuelva a abrirla.
class HomeSectionRequest {
  HomeSectionRequest(this.section);
  final HomeSection section;
}

/// Ícono vectorial exacto de la barra inferior (`NavBar-01.svg`).
class SetuNavIcon extends StatelessWidget {
  const SetuNavIcon({
    super.key,
    required this.section,
    this.size = 28,
    this.color = CureandoTheme.blue,
  });

  final HomeSection section;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SetuNavIconPainter(section, color)),
    ),
  );
}

/// Barra de navegación inferior flotante en formato píldora de vidrio
/// translúcido, con íconos vectoriales de `NavBar-01.svg`. El contenido de la
/// pantalla se desliza por detrás (`Scaffold.extendBody`).
class SetuBottomNav extends StatelessWidget {
  const SetuBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HomeSection? selected;
  final ValueChanged<HomeSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final HomeSection? active = selected;
    final TextScaler clampedScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    // Con «alto contraste» del sistema el vidrio se vuelve blanco sólido:
    // la legibilidad no depende de lo que pase por detrás.
    final bool solid = MediaQuery.highContrastOf(context);
    final BorderRadius radius = BorderRadius.circular(999);

    final Widget bar = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 68,
          // Cápsula translúcida: el estado activo también lo marca el peso
          // de la etiqueta, no solo el color.
          indicatorColor: active == null
              ? Colors.transparent
              : CureandoTheme.blue.withValues(alpha: 0.14),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            final bool isSelected =
                active != null && states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11.5,
              color: CureandoTheme.blue,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              height: 1.1,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: active?.index ?? 0,
          onDestinationSelected: (int index) =>
              onSelected(HomeSection.values[index]),
          destinations: <Widget>[
            for (final HomeSection section in HomeSection.values)
              NavigationDestination(
                icon: SetuNavIcon(section: section, size: 28),
                selectedIcon: SetuNavIcon(section: section, size: 28),
                label: section.label,
              ),
          ],
        ),
      ),
    );

    final Widget glass = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: solid ? Colors.white : null,
        gradient: solid
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.78),
                  Colors.white.withValues(alpha: 0.62),
                ],
              ),
        border: Border.all(
          color: solid
              ? CureandoTheme.blue
              : Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
      ),
      child: bar,
    );

    // Sin fondo opaco de lado a lado: la píldora flota sobre el contenido.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 452),
            child: DecoratedBox(
              // La sombra va fuera del recorte para que no se corte.
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: <BoxShadow>[
                  // Contorno exterior tintado.
                  BoxShadow(
                    color: CureandoTheme.blue.withValues(alpha: 0.18),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: CureandoTheme.blue.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: solid
                    ? glass
                    : BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: glass,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetuNavIconPainter extends CustomPainter {
  const _SetuNavIconPainter(this.section, this.color);

  final HomeSection section;
  final Color color;

  static final Map<HomeSection, ui.Path> _normalizedCache =
      <HomeSection, ui.Path>{};

  static const Map<HomeSection, List<String>>
  _svgPaths = <HomeSection, List<String>>{
    HomeSection.inicio: <String>[
      'M203.47,2350.23h46.82c0,12.93-5.24,24.64-13.71,33.11-8.47,8.47-20.18,13.71-33.11,13.71v-46.82Z',
      'M236.58,2413.2c8.47,8.47,13.71,20.18,13.71,33.11h-46.82v-46.82c12.93,0,24.64,5.24,33.11,13.71Z',
      'M299.54,2397.06v49.25c-25.86,0-46.82-20.96-46.82-46.82v-49.25c12.93,0,24.63,5.24,33.11,13.71,8.47,8.47,13.71,20.18,13.71,33.11Z',
    ],
    HomeSection.informacion: <String>[
      'M518.01,2392.33l-13.17-2.06,10.37-8.36c5.34-4.31.46-12.77-5.94-10.3l-12.43,4.8,4.8-12.43c2.47-6.4-5.98-11.27-10.29-5.93l-8.36,10.36-2.07-13.16c-1.06-6.78-10.81-6.78-11.88,0l-2.06,13.16-8.36-10.36c-4.31-5.34-12.77-.46-10.3,5.93l4.8,12.43-12.43-4.8c-6.4-2.47-11.27,5.99-5.93,10.3l10.36,8.36-13.16,2.06c-6.77,1.06-6.77,10.82,0,11.88l13.16,2.07-10.36,8.36c-5.34,4.3-.46,12.76,5.93,10.29l12.43-4.79-4.8,12.43c-2.47,6.4,5.99,11.27,10.3,5.93l8.36-10.37,2.06,13.17c1.07,6.77,10.82,6.77,11.88,0l2.07-13.17,8.36,10.37c4.31,5.34,12.76.46,10.29-5.93l-4.8-12.43,12.43,4.79c6.41,2.47,11.28-5.99,5.94-10.29l-10.37-8.36,13.17-2.07c6.77-1.06,6.77-10.82,0-11.88ZM480.47,2420.77h-11.95v-11.54h11.95v11.54ZM479.51,2404.73h-10.09l-1.38-28.95h12.91l-1.45,28.95Z',
    ],
    HomeSection.actividades: <String>[
      'M762.13,2404.65v32.8c0,4.89-3.97,8.86-8.86,8.86h-32.8c-.79,0-1.42-.64-1.42-1.42v-12.35c0-1.02,1.04-1.7,1.98-1.31.86.36,1.8.55,2.78.53,3.79-.05,6.87-3.15,6.9-6.94.03-3.89-3.11-7.05-6.99-7.05-.95,0-1.86.19-2.69.53-.94.39-1.98-.28-1.98-1.3v-12.35c0-.79.64-1.42,1.42-1.42h11.95c.92,0,1.62.87,1.39,1.76-.15.58-.22,1.19-.22,1.81.04,3.8,3.15,6.89,6.94,6.91s7.05-3.11,7.05-6.99c0-.59-.07-1.17-.21-1.72-.23-.9.45-1.78,1.38-1.78h11.96c.79,0,1.42.64,1.42,1.42Z',
      'M667.09,2391.64v-32.6c0-4.86,3.94-8.81,8.81-8.81h32.6c.78,0,1.41.63,1.41,1.41v12.27c0,1.01-1.03,1.69-1.96,1.3-.85-.35-1.79-.54-2.77-.53-3.77.05-6.83,3.13-6.86,6.9s3.1,7.01,6.95,7.01c.95,0,1.85-.19,2.67-.53.93-.39,1.97.28,1.97,1.29v12.28c0,.78-.63,1.41-1.41,1.41h-11.88c-.92,0-1.61-.86-1.38-1.75.15-.58.22-1.18.21-1.8-.04-3.77-3.13-6.84-6.9-6.87s-7.01,3.1-7.01,6.95c0,.59.07,1.16.21,1.71.23.9-.44,1.77-1.37,1.77h-11.88c-.78,0-1.41-.63-1.41-1.41Z',
      'M721.5,2424.95c-.03,3.77-3.09,6.85-6.86,6.9-.98.01-1.92-.18-2.77-.53-.93-.39-1.96.29-1.96,1.3v12.28c0,.78-.63,1.41-1.41,1.41h-32.6c-4.86,0-8.81-3.94-8.81-8.81v-32.6c0-.78.63-1.41,1.41-1.41h11.88c.92,0,1.61-.86,1.38-1.75-.15-.58-.22-1.18-.21-1.8.04-3.77,3.13-6.84,6.9-6.87,3.86-.03,7.01,3.1,7.01,6.95,0,.59-.07,1.16-.21,1.71-.23.9.44,1.77,1.37,1.77h11.89c.78,0,1.41.63,1.41,1.41v12.28c0,1.01,1.03,1.68,1.97,1.29.82-.34,1.72-.53,2.67-.53,3.86,0,6.98,3.14,6.95,7.01Z',
      'M760.72,2392.85h-11.82c-.91,0-1.6.86-1.37,1.75.15.57.22,1.17.21,1.79-.04,3.75-3.11,6.81-6.87,6.84s-6.97-3.08-6.97-6.92c0-.59.07-1.16.21-1.7.23-.89-.44-1.76-1.36-1.76h-11.83c-.78,0-1.41-.63-1.41-1.41v-12.22c0-1-1.02-1.68-1.95-1.29-.85.35-1.78.54-2.76.53-3.75-.05-6.8-3.12-6.83-6.87-.03-3.85,3.08-6.97,6.92-6.97.94,0,1.84.19,2.66.53.93.39,1.96-.28,1.96-1.29v-12.22c0-.78.63-1.41,1.41-1.41h32.45c4.84,0,8.76,3.92,8.76,8.76v32.45c0,.78-.63,1.41-1.41,1.41Z',
    ],
    HomeSection.ayuda: <String>[
      'M962.99,2395.13c-1.7,0-3.33.34-4.82.95-1.68.71-3.55-.51-3.55-2.34v-22.16c0-1.4-1.14-2.54-2.54-2.54h-21.46c-1.66,0-2.87-1.58-2.46-3.19.25-.99.38-2.02.38-3.08,0-6.96-5.67-12.6-12.64-12.54-6.81.05-12.37,5.59-12.45,12.39-.01,1.13.12,2.22.39,3.26.41,1.61-.83,3.17-2.49,3.17h-21.43c-1.41,0-2.55,1.14-2.55,2.54v58.83c0,8.77,7.11,15.89,15.89,15.89h58.83c1.4,0,2.54-1.15,2.54-2.55v-22.15c0-1.82,1.86-3.05,3.54-2.35,1.54.64,3.23.98,5,.96,6.8-.09,12.32-5.66,12.37-12.45.05-6.97-5.59-12.64-12.54-12.64ZM921.01,2427.08c0,1.41-1.15,2.56-2.56,2.56h-7.46c-1.41,0-2.56-1.15-2.56-2.56v-7.02c0-1.41,1.15-2.56,2.56-2.56h7.46c1.41,0,2.56,1.15,2.56,2.56v7.02ZM930.62,2403.96c-2.09,1.86-4.71,2.98-7.87,3.38-1.28.16-2.24,1.24-2.24,2.54v.18c0,1.41-1.15,2.56-2.56,2.56h-6.58c-1.41,0-2.56-1.15-2.56-2.56v-7.91c0-1.41,1.15-2.56,2.56-2.56h2.24c2.79,0,4.92-.36,6.42-1.08,1.5-.71,2.24-1.96,2.24-3.73,0-1.1-.3-1.95-.91-2.56-.61-.6-1.4-.91-2.37-.91-1.15,0-2.03.36-2.66,1.08-.3.34-.52.73-.69,1.16-.36.99-1.32,1.62-2.38,1.62h-6.92c-1.57,0-2.8-1.38-2.54-2.92.25-1.46.73-2.82,1.42-4.1,1.16-2.1,2.94-3.78,5.35-5.02,2.4-1.25,5.35-1.87,8.86-1.87,4.55,0,8.2,1.15,10.94,3.44,2.75,2.3,4.12,5.64,4.12,10.02,0,3.88-1.29,6.96-3.86,9.23Z',
    ],
  };

  static final RegExp _tokenPattern = RegExp(
    r'[+-]?(?:\d*\.\d+|\d+\.?)(?:[eE][+-]?\d+)?|[A-Za-z]',
  );

  static ui.Path _pathFor(HomeSection section) =>
      _normalizedCache.putIfAbsent(section, () {
        final ui.Path combined = ui.Path()..fillType = ui.PathFillType.evenOdd;
        for (final String d in _svgPaths[section]!) {
          combined.addPath(_parseSvgPath(d), Offset.zero);
        }
        final Rect bounds = combined.getBounds();
        final double maxDim = math.max(bounds.width, bounds.height);
        final double scale = maxDim > 0 ? 1 / maxDim : 1;
        final double dx = (1 - bounds.width * scale) / 2 - bounds.left * scale;
        final double dy = (1 - bounds.height * scale) / 2 - bounds.top * scale;
        final Matrix4 matrix = Matrix4.translationValues(dx, dy, 0)
          ..scaleByDouble(scale, scale, 1, 1);
        return combined.transform(matrix.storage)
          ..fillType = ui.PathFillType.evenOdd;
      });

  static ui.Path _parseSvgPath(String d) {
    final List<String> tokens = _tokenPattern
        .allMatches(d)
        .map((Match m) => m.group(0)!)
        .toList();
    final ui.Path path = ui.Path();
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
    bool isCmd(String token) =>
        token.length == 1 && token.codeUnitAt(0) >= 65; // A-Z / a-z

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
        case 'h':
          cx += nextNum();
          path.lineTo(cx, cy);
          lastCmd = 'h';
        case 'v':
          cy += nextNum();
          path.lineTo(cx, cy);
          lastCmd = 'v';
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
        case 's':
          final bool hadCubic = lastCmd == 'c' || lastCmd == 's';
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
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    canvas.save();
    canvas.scale(s);
    canvas.drawPath(
      _pathFor(section),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SetuNavIconPainter oldDelegate) =>
      oldDelegate.section != section || oldDelegate.color != color;
}
