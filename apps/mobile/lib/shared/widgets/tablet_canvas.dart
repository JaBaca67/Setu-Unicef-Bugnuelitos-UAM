import 'package:flutter/widgets.dart';

/// Adapta SéTú a tabletas sin cortar bordes: en pantallas con lado corto de
/// 600 dp o más, dibuja la interfaz del teléfono con [designWidth] dp de ancho
/// y la escala hasta ocupar todo el ancho. La app es solo vertical, así que el
/// alto lógico resultante (≈ 690 dp en una tableta de 10") equivale a un
/// teléfono y todo el contenido se desplaza como en el celular.
class TabletCanvas extends StatelessWidget {
  const TabletCanvas({super.key, required this.child});

  /// Ancho lógico del diseño de Figma (teléfono grande).
  static const double designWidth = 430;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final Size size = media.size;
    if (size.shortestSide < 600 || size.width <= designWidth) return child;
    final double scale = size.width / designWidth;
    final Size logical = Size(designWidth, size.height / scale);
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: logical,
        child: MediaQuery(
          data: media.copyWith(
            size: logical,
            devicePixelRatio: media.devicePixelRatio * scale,
            padding: media.padding / scale,
            viewPadding: media.viewPadding / scale,
            viewInsets: media.viewInsets / scale,
            systemGestureInsets: media.systemGestureInsets / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}
