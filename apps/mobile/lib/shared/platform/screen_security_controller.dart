import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenSecurityController extends ChangeNotifier {
  ScreenSecurityController({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('dev.cureando.app/screen_security');

  final MethodChannel _channel;
  bool enabled = true;
  bool busy = false;
  String? error;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      enabled =
          await _channel.invokeMethod<bool>('isSecureScreenEnabled') ?? true;
      error = null;
    } on PlatformException {
      error = 'No se pudo comprobar la protección de pantalla.';
    } on MissingPluginException {
      error = 'Protección disponible únicamente en Android.';
    }
    _notify();
  }

  Future<void> setSecureScreen(bool value) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      await _channel.invokeMethod<void>('setSecureScreen', value);
      enabled =
          await _channel.invokeMethod<bool>('isSecureScreenEnabled') ?? true;
      if (enabled != value) {
        error = 'Android no confirmó el cambio de protección.';
      }
    } on PlatformException {
      error = 'No se pudo cambiar la protección de pantalla.';
    } on MissingPluginException {
      error = 'Protección disponible únicamente en Android.';
    } finally {
      busy = false;
      _notify();
    }
  }
}
