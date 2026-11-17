import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Activa `FLAG_SECURE` (sin capturas ni grabación de pantalla) solo mientras
/// el [child] está montado. Se usa en los chats estudiante–profesional; el
/// resto de la app permite capturas (ADR 0024).
class SecureScreenGuard extends StatefulWidget {
  const SecureScreenGuard({super.key, required this.child, this.channel});

  final Widget child;

  /// Canal nativo; se inyecta en pruebas.
  final MethodChannel? channel;

  static const MethodChannel _defaultChannel = MethodChannel(
    'dev.cureando.app/screen_security',
  );

  /// Cantidad de chats montados (p. ej. durante una transición entre dos).
  static int _active = 0;

  @override
  State<SecureScreenGuard> createState() => _SecureScreenGuardState();
}

class _SecureScreenGuardState extends State<SecureScreenGuard> {
  MethodChannel get _channel =>
      widget.channel ?? SecureScreenGuard._defaultChannel;

  @override
  void initState() {
    super.initState();
    SecureScreenGuard._active += 1;
    _set(true);
  }

  @override
  void dispose() {
    SecureScreenGuard._active -= 1;
    if (SecureScreenGuard._active <= 0) {
      SecureScreenGuard._active = 0;
      _set(false);
    }
    super.dispose();
  }

  Future<void> _set(bool value) async {
    try {
      await _channel.invokeMethod<void>('setSecureScreen', value);
    } on Object {
      // Sin canal nativo (pruebas u otra plataforma): no hay nada que proteger.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
