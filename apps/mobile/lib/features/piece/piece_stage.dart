import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import 'student_piece.dart';

/// Escenario ilustrado de la pieza: fondo azul de campaña, contornos de
/// rompecabezas, ola punteada y chispas, con el nombre de juego debajo.
class PieceStage extends StatelessWidget {
  const PieceStage({
    super.key,
    required this.piece,
    required this.name,
    this.label,
    this.hop = 0,
    this.figureHeight = 190,
  });

  final StudentPiece piece;
  final Widget name;
  final String? label;

  /// Cambia cada vez que la pieza debe reaccionar con un salto corto.
  final int hop;
  final double figureHeight;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFDCEEFC), Color(0xFFC4E1F9)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFB9D8F5)),
    ),
    child: Stack(
      children: <Widget>[
        Positioned(
          left: -16,
          top: figureHeight * .22,
          child: Transform.rotate(
            angle: -.35,
            child: const PuzzleOutline(size: 82),
          ),
        ),
        Positioned(
          right: -14,
          top: 12,
          child: Transform.rotate(
            angle: .4,
            child: const PuzzleOutline(size: 74),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 18 + figureHeight * .52,
          child: const DashedWave(color: Color(0xFFFF4FA3), height: 54),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                image: true,
                label: 'Tu pieza: ${piece.description}',
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: figureHeight * .62,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0x4D5BA8E8),
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(figureHeight * .31, 10),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PieceHop(
                        tick: hop,
                        child: PieceFigure(
                          piece: piece,
                          height: figureHeight,
                          sparks: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (label != null) ...<Widget>[
                Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CureandoTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Center(child: name),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Salto corto de la pieza al probar un accesorio. Con «Quitar
/// animaciones» activado no hay movimiento.
class PieceHop extends StatelessWidget {
  const PieceHop({super.key, required this.tick, required this.child});

  final int tick;
  final Widget child;

  static const Duration duration = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    if (tick == 0 || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(tick),
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      child: child,
      builder: (BuildContext context, double t, Widget? child) {
        final double s = math.sin(math.pi * t);
        return Transform.translate(
          offset: Offset(0, -14 * s),
          child: Transform.scale(scale: 1 + .06 * s, child: child),
        );
      },
    );
  }
}

/// Píldora blanca con el nombre de juego. Sin nombre válido muestra
/// «Elegí un nombre de juego» y, si se puede tocar, abre la elección.
class PieceNamePill extends StatelessWidget {
  const PieceNamePill({super.key, required this.name, this.onTap});

  static const String placeholder = 'Elegí un nombre de juego';

  final String? name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool missing = name == null;
    final Widget text = Text(
      name ?? placeholder,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: missing ? 18 : 21,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: missing ? CureandoTheme.blue : CureandoTheme.ink,
      ),
    );
    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 1,
        shadowColor: const Color(0x330F172A),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: missing && onTap != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.edit_rounded,
                        color: CureandoTheme.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: text),
                    ],
                  )
                : text,
          ),
        ),
      ),
    );
  }
}
