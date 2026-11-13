import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import 'student_piece.dart';

enum _EditorTab {
  shape('Forma'),
  color('Color'),
  accessories('Accesorios');

  const _EditorTab(this.label);
  final String label;
}

/// «Mi pieza»: el estudiante arma un dibujo que lo acompaña en la app.
/// La elección vive en esta sesión; no usa fotos, nombres ni cuentas.
class PieceEditorScreen extends StatefulWidget {
  const PieceEditorScreen({super.key, required this.piece, this.random});

  final ValueNotifier<StudentPiece> piece;
  final math.Random? random;

  @override
  State<PieceEditorScreen> createState() => _PieceEditorScreenState();
}

class _PieceEditorScreenState extends State<PieceEditorScreen> {
  late StudentPiece _piece = widget.piece.value;
  late final math.Random _random = widget.random ?? math.Random();
  _EditorTab _tab = _EditorTab.shape;

  void _set(StudentPiece piece) => setState(() => _piece = piece);

  @override
  Widget build(BuildContext context) => FlowScaffold(
    header: const FlowHeader(
      title: 'Mi pieza',
      subtitle: 'Todas las piezas tienen un lugar.',
    ),
    bottom: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton(
          style: flowPrimaryStyle(),
          onPressed: () {
            widget.piece.value = _piece;
            context.pop();
          },
          child: const Text('Guardar mi pieza'),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'Ahora no',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Preview(
          piece: _piece,
          onRandom: () => _set(StudentPiece.random(_random)),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            for (final _EditorTab tab in _EditorTab.values) ...<Widget>[
              if (tab.index > 0) const SizedBox(width: 8),
              Expanded(
                child: _TabButton(
                  label: tab.label,
                  selected: _tab == tab,
                  onTap: () => setState(() => _tab = tab),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: _tab == _EditorTab.shape ? 1 : .82,
          children: switch (_tab) {
            _EditorTab.shape => <Widget>[
              for (final PieceShape shape in PieceShape.values)
                _OptionTile(
                  label: shape.label,
                  showLabel: false,
                  selected: _piece.shape == shape,
                  background: PieceColor.values[shape.index].soft,
                  onTap: () => _set(_piece.copyWith(shape: shape)),
                  child: PieceFigure(
                    piece: StudentPiece(
                      shape: shape,
                      color: PieceColor.values[shape.index],
                    ),
                    face: false,
                    height: 84,
                  ),
                ),
            ],
            _EditorTab.color => <Widget>[
              for (final PieceColor color in PieceColor.values)
                _OptionTile(
                  label: color.label,
                  selected: _piece.color == color,
                  background: color.soft,
                  onTap: () => _set(_piece.copyWith(color: color)),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
            _EditorTab.accessories => <Widget>[
              for (final PieceAccessory accessory in PieceAccessory.values)
                _OptionTile(
                  label: accessory.label,
                  selected: _piece.accessories.contains(accessory),
                  background: CureandoTheme.blueSoft,
                  onTap: () => _set(_piece.toggle(accessory)),
                  child: PieceFigure(
                    piece: StudentPiece(
                      shape: _piece.shape,
                      color: _piece.color,
                      accessories: <PieceAccessory>{accessory},
                    ),
                    legs: false,
                    height: 84,
                  ),
                ),
            ],
          },
        ),
      ],
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.piece, required this.onRandom});

  final StudentPiece piece;
  final VoidCallback onRandom;

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
    padding: const EdgeInsets.only(top: 18, bottom: 14),
    child: Column(
      children: <Widget>[
        Semantics(
          image: true,
          liveRegion: true,
          label: 'Tu pieza: ${piece.description}',
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              const Positioned(
                left: 0,
                right: 0,
                bottom: 38,
                child: DashedWave(color: Color(0xFFFF4FA3), height: 54),
              ),
              Positioned(
                bottom: 2,
                child: Container(
                  width: 150,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0x4D5BA8E8),
                    borderRadius: BorderRadius.all(Radius.elliptical(75, 11)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PieceFigure(piece: piece, height: 230, sparks: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onRandom,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.shuffle_rounded, color: CureandoTheme.blue),
                  SizedBox(width: 8),
                  Text(
                    'Al azar',
                    style: TextStyle(
                      color: CureandoTheme.blue,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? CureandoTheme.blue : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? CureandoTheme.blue : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : CureandoTheme.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.background,
    required this.onTap,
    required this.child,
    this.showLabel = true,
  });

  final String label;
  final bool selected;
  final Color background;
  final VoidCallback onTap;
  final Widget child;
  final bool showLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? CureandoTheme.blue : Colors.transparent,
            width: 3,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        child,
                        if (showLabel) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: CureandoTheme.blue,
                    child: Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
