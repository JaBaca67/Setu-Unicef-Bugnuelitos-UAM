import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

/// Estado del tablero del Rompecabezas del buen trato.
enum PuzzleBoardState { disconnected, connected }

const String _dir = 'assets/home/activities';

/// Las capas salen de la ilustración oficial «flor azul + pieza amarilla»
/// (302 × 250). Para encajar, el saliente de la pieza entra en la muesca de
/// la flor: la pieza se desplaza 40 px a la izquierda y 5 px hacia arriba.
const double _frameW = 302;
const double _frameH = 250;
const double _connectDx = -40;
const double _connectDy = -5;
const double _slideFrom = 64;

/// Recorte vertical: los arcos de la ilustración no forman parte del tablero.
const double _cropTop = 58;

String _pieceAsset(Color color) => color == CureandoTheme.green
    ? '$_dir/puzzle_pieza_verde.png'
    : '$_dir/puzzle_pieza_amarilla.png';

/// Tablero con la flor azul y la pieza amarilla oficiales. Desconectado
/// muestra la silueta punteada de la pieza en su lugar; conectado desliza la
/// pieza del color de la respuesta hasta encajar en la muesca.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.state,
    this.pieceColor = CureandoTheme.yellow,
  });

  final PuzzleBoardState state;
  final Color pieceColor;

  Widget _layer(String asset, {double dx = 0, double dy = 0}) => Positioned(
    left: dx,
    top: dy - _cropTop,
    width: _frameW,
    height: _frameH,
    child: Image.asset(asset, excludeFromSemantics: true),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: state == PuzzleBoardState.connected
        ? 'Piezas conectadas'
        : 'Piezas por conectar',
    child: Container(
      height: 188,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD9E7FD),
        borderRadius: BorderRadius.circular(24),
      ),
      child: FittedBox(
        child: SizedBox(
          width: _frameW,
          height: _frameH - _cropTop,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              end: state == PuzzleBoardState.connected ? 1 : 0,
            ),
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeOutBack,
            builder: (BuildContext context, double t, _) {
              final bool connected = t > 0.02;
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  if (!connected)
                    _layer(
                      '$_dir/puzzle_pieza_silueta.png',
                      dx: _connectDx,
                      dy: _connectDy,
                    ),
                  _layer('$_dir/puzzle_flor.png'),
                  if (connected)
                    Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          _layer(
                            _pieceAsset(pieceColor),
                            dx: _connectDx + (1 - t) * _slideFrom,
                            dy: _connectDy,
                          ),
                        ],
                      ),
                    ),
                  if (t > 0.9) ...<Widget>[
                    const Positioned(
                      left: 18,
                      top: 6,
                      child: _Sparks(color: Color(0xFFFF0092)),
                    ),
                    const Positioned(
                      right: 30,
                      top: 0,
                      child: _Sparks(color: CureandoTheme.yellow),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Pieza de opción: la pieza oficial con la misma forma en cada respuesta;
/// solo cambia el color.
class PuzzleOptionPiece extends StatelessWidget {
  const PuzzleOptionPiece({super.key, required this.color, this.size = 44});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Image.asset(
      color == CureandoTheme.green
          ? '$_dir/puzzle_opcion_verde.png'
          : '$_dir/puzzle_opcion_amarilla.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}

class _Sparks extends StatelessWidget {
  const _Sparks({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 30,
    child: CustomPaint(painter: _SparksPainter(color)),
  );
}

class _SparksPainter extends CustomPainter {
  const _SparksPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(4, 26), const Offset(0, 14), p)
      ..drawLine(const Offset(18, 22), const Offset(18, 6), p)
      ..drawLine(const Offset(30, 26), const Offset(38, 14), p);
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.color != color;
}
