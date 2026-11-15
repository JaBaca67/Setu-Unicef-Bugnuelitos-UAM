import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/flow_scaffold.dart';
import 'piece_stage.dart';
import 'student_piece.dart';

/// Pestañas del editor. `query` es el valor de `?pestana=` en la ruta.
enum PieceEditorTab {
  shape('Forma', 'forma'),
  color('Color', 'color'),
  accessories('Accesorios', 'accesorios'),
  name('Nombre', 'nombre');

  const PieceEditorTab(this.label, this.query);
  final String label;
  final String query;

  static PieceEditorTab fromQuery(String? value) => PieceEditorTab.values
      .firstWhere((PieceEditorTab tab) => tab.query == value,
          orElse: () => PieceEditorTab.shape);
}

/// Editor «Mi pieza» (`/inicio/pieza/editar`). Trabaja sobre un borrador:
/// solo «Guardar mi pieza» lo escribe en la sesión. Volver atrás conserva la
/// última versión guardada. No usa fotos, nombres reales ni cuentas.
class PieceEditorScreen extends StatefulWidget {
  const PieceEditorScreen({
    super.key,
    required this.piece,
    this.initialTab = PieceEditorTab.shape,
    this.random,
  });

  final ValueNotifier<StudentPiece> piece;
  final PieceEditorTab initialTab;
  final math.Random? random;

  @override
  State<PieceEditorScreen> createState() => _PieceEditorScreenState();
}

class _PieceEditorScreenState extends State<PieceEditorScreen> {
  late final math.Random _random = widget.random ?? math.Random();
  late StudentPiece _draft = widget.piece.value;
  late PieceEditorTab _tab = widget.initialTab;
  late PieceNameNoun? _noun = _draft.name?.noun;
  late PieceNameTrait? _trait = _draft.name?.trait;
  String? _reaction;
  int _hop = 0;

  /// Eligió una sola de las dos palabras: falta la otra para guardar.
  bool get _halfName => (_noun == null) != (_trait == null);

  void _setName(PieceNameNoun? noun, PieceNameTrait? trait) => setState(() {
    _noun = noun;
    _trait = trait;
    _draft = noun != null && trait != null
        ? _draft.copyWith(name: PieceName(noun, trait))
        : _draft.copyWith(clearName: true);
  });

  void _randomName() {
    final PieceName name = PieceName.random(_random);
    _setName(name.noun, name.trait);
  }

  void _toggle(PieceAccessory accessory) => setState(() {
    final bool wearing = !_draft.accessories.contains(accessory);
    _draft = _draft.toggle(accessory);
    _reaction = wearing
        ? 'Tu pieza se puso ${accessory.article}.'
        : 'Tu pieza se quitó ${accessory.article}.';
    if (wearing) _hop++;
  });

  void _save() {
    widget.piece.value = _draft;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) => FlowScaffold(
    header: const FlowHeader(title: 'Mi pieza'),
    bottom: FilledButton(
      style: flowPrimaryStyle(),
      onPressed: _halfName ? null : _save,
      child: const Text('Guardar mi pieza'),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PieceStage(
          piece: _draft,
          hop: _hop,
          figureHeight: 200,
          name: Semantics(
            liveRegion: true,
            child: PieceNamePill(name: _draft.displayName),
          ),
        ),
        if (_reaction != null) ...<Widget>[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(
              _reaction!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CureandoTheme.ink,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _Tabs(
          selected: _tab,
          onSelected: (PieceEditorTab tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 16),
        if (_tab == PieceEditorTab.name) _nameTab() else ..._appearanceTab(),
      ],
    ),
  );

  List<Widget> _appearanceTab() => <Widget>[
    GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: _tab == PieceEditorTab.shape ? 1 : .82,
      children: switch (_tab) {
        PieceEditorTab.shape => <Widget>[
          for (final PieceShape shape in PieceShape.values)
            _OptionTile(
              label: shape.label,
              showLabel: false,
              selected: _draft.shape == shape,
              background: PieceColor.values[shape.index].soft,
              onTap: () => setState(() => _draft = _draft.copyWith(shape: shape)),
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
        PieceEditorTab.color => <Widget>[
          for (final PieceColor color in PieceColor.values)
            _OptionTile(
              label: color.label,
              selected: _draft.color == color,
              background: color.soft,
              onTap: () => setState(() => _draft = _draft.copyWith(color: color)),
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
        _ => <Widget>[
          for (final PieceAccessory accessory in PieceAccessory.values)
            _OptionTile(
              label: accessory.label,
              selected: _draft.accessories.contains(accessory),
              background: CureandoTheme.blueSoft,
              onTap: () => _toggle(accessory),
              child: PieceFigure(
                piece: StudentPiece(
                  shape: _draft.shape,
                  color: _draft.color,
                  accessories: <PieceAccessory>{accessory},
                ),
                legs: false,
                height: 84,
              ),
            ),
        ],
      },
    ),
    const SizedBox(height: 14),
    Center(
      child: _ShuffleButton(
        label: 'Apariencia al azar',
        onTap: () => setState(
          () => _draft = StudentPiece.random(_random, name: _draft.name),
        ),
      ),
    ),
  ];

  Widget _nameTab() {
    final NameGender? gender = _noun?.gender;
    String traitLabel(PieceNameTrait trait) {
      if (gender != null) return trait.formFor(gender);
      return trait.masculine == trait.feminine
          ? trait.masculine
          : '${trait.masculine} / ${trait.feminine}';
    }

    final Widget nounField = _NameDropdown<PieceNameNoun>(
      key: ValueKey<Object?>(('noun', _noun)),
      label: 'Nombre',
      value: _noun,
      items: PieceNameNoun.values,
      itemLabel: (PieceNameNoun noun) => noun.label,
      onChanged: (PieceNameNoun? noun) => _setName(noun, _trait),
    );
    final Widget traitField = _NameDropdown<PieceNameTrait>(
      key: ValueKey<Object?>(('trait', _trait, gender)),
      label: 'Apodo',
      value: _trait,
      items: PieceNameTrait.values,
      itemLabel: traitLabel,
      onChanged: (PieceNameTrait? trait) => _setName(_noun, trait),
    );
    final bool stacked = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: const Text(
            PieceNamePill.placeholder,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        if (stacked) ...<Widget>[
          nounField,
          const SizedBox(height: 12),
          traitField,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: nounField),
              const SizedBox(width: 10),
              Expanded(child: traitField),
            ],
          ),
        if (_halfName) ...<Widget>[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _noun == null
                  ? 'Elegí también el nombre para poder guardar.'
                  : 'Elegí también el apodo para poder guardar.',
              style: const TextStyle(
                fontSize: 15,
                color: CureandoTheme.secondaryInk,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Center(child: _ShuffleButton(label: 'Al azar', onTap: _randomName)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CureandoTheme.blueSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.lock_outline_rounded, color: CureandoTheme.ink),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Usá un nombre de juego para tu pieza. Si pedís apoyo, el '
                  'equipo de escucha lo ve junto a tu pieza.',
                  style: TextStyle(fontSize: 15, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});

  final PieceEditorTab selected;
  final ValueChanged<PieceEditorTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool large = MediaQuery.textScalerOf(context).scale(16) > 22;
    final List<Widget> buttons = <Widget>[
      for (final PieceEditorTab tab in PieceEditorTab.values)
        PieceTabButton(
          label: tab.label,
          selected: selected == tab,
          onTap: () => onSelected(tab),
        ),
    ];
    if (large) {
      // Con letra grande, dos pestañas por fila para que se lean completas.
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final Widget button in buttons)
              SizedBox(width: (constraints.maxWidth - 8) / 2, child: button),
          ],
        ),
      );
    }
    return Row(
      children: <Widget>[
        for (int i = 0; i < buttons.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

class _NameDropdown<T> extends StatelessWidget {
  const _NameDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    menuMaxHeight: 360,
    borderRadius: BorderRadius.circular(14),
    hint: const Text('Elegir'),
    icon: const Icon(
      Icons.keyboard_arrow_down_rounded,
      color: CureandoTheme.blue,
    ),
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: CureandoTheme.ink,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF9DBEF2), width: 1.5),
      ),
    ),
    items: <DropdownMenuItem<T>>[
      for (final T item in items)
        DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
    ],
    onChanged: onChanged,
  );
}

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: CureandoTheme.blue,
      backgroundColor: Colors.white,
      minimumSize: const Size(48, 50),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      side: const BorderSide(color: CureandoTheme.blue, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    onPressed: onTap,
    icon: const Icon(Icons.shuffle_rounded),
    label: Text(label),
  );
}

/// Pestaña de selección del editor de pieza.
class PieceTabButton extends StatelessWidget {
  const PieceTabButton({
    super.key,
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
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : CureandoTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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
