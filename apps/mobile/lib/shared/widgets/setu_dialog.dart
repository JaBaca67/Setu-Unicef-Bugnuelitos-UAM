import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const BorderSide _border = BorderSide(color: Color(0xFFD6E2F5));
const TextStyle _titleStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  height: 1.3,
  color: CureandoTheme.ink,
);
const TextStyle _bodyStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 15,
  height: 1.45,
  color: CureandoTheme.secondaryInk,
);

ThemeData _popupTheme(BuildContext context, {bool destructive = false}) {
  final ThemeData theme = Theme.of(context);
  final Color primary = destructive ? CureandoTheme.pink : CureandoTheme.blue;
  final RoundedRectangleBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  const TextStyle label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  return theme.copyWith(
    textTheme: theme.textTheme.copyWith(
      titleLarge: _titleStyle,
      bodyLarge: _bodyStyle,
      bodyMedium: _bodyStyle,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: shape,
        textStyle: label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CureandoTheme.blue,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: const BorderSide(color: Color(0xFFA5C1EF)),
        shape: shape,
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CureandoTheme.blue,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: shape,
        textStyle: label,
      ),
    ),
  );
}

/// Conserva el resultado y el contexto de la ruta de diálogo de Material.
Future<T?> showSetuDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<T>(context: context, builder: builder);

/// Diálogo de marca con contenido desplazable y acciones apiladas.
/// Las acciones originales conservan sus callbacks, claves y Semantics.
class SetuDialog extends StatelessWidget {
  const SetuDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const <Widget>[],
    this.icon,
    this.destructive = false,
  });

  final Widget title;
  final Widget? content;
  final List<Widget> actions;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Theme(
    data: _popupTheme(context, destructive: destructive),
    child: Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: _border,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: destructive
                                ? CureandoTheme.pinkSoft
                                : CureandoTheme.blueSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 28,
                            color: destructive
                                ? CureandoTheme.pink
                                : CureandoTheme.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Semantics(
                    namesRoute: true,
                    header: true,
                    child: DefaultTextStyle(style: _titleStyle, child: title),
                  ),
                  if (content != null) ...<Widget>[
                    const SizedBox(height: 12),
                    DefaultTextStyle(style: _bodyStyle, child: content!),
                  ],
                ],
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 8),
                    actions[i],
                  ],
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Hoja SéTú; mantiene las opciones de tamaño y área segura de cada flujo.
Future<T?> showSetuBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  BoxConstraints? constraints,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  constraints: constraints,
  showDragHandle: true,
  backgroundColor: Colors.white,
  barrierColor: Colors.black54,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    side: _border,
  ),
  clipBehavior: Clip.antiAlias,
  builder: (BuildContext sheet) => Theme(
    data: _popupTheme(sheet),
    child: Builder(builder: builder),
  ),
);
