import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Capacidad privada de 256 bits por caso (ADR 0016) e identificadores
/// idempotentes de operación para los RPCs de Supabase.
class CaseCapability {
  const CaseCapability({
    required this.token,
    required this.verifierHash,
  });

  final String token;
  final String verifierHash;

  static final Sha256 _sha256 = Sha256();
  static final Random _random = Random.secure();

  /// Genera un token secreto de 32 bytes (64 hex minúsculas) y su hash SHA-256.
  static Future<CaseCapability> generate() async {
    final List<int> bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final String token = _toHex(bytes);
    final String verifierHash = await hashToken(token);
    return CaseCapability(token: token, verifierHash: verifierHash);
  }

  /// Calcula el hash SHA-256 en hex minúsculas esperado por `case_private_capabilities`.
  static Future<String> hashToken(String token) async {
    final Hash digest = await _sha256.hash(utf8.encode(token));
    return _toHex(digest.bytes);
  }

  /// Genera un `client_operation_id` único (entre 8 y 128 caracteres).
  static String newOperationId({String prefix = 'op'}) {
    final int millis = DateTime.now().toUtc().millisecondsSinceEpoch;
    final List<int> salt = List<int>.generate(8, (_) => _random.nextInt(256));
    return '${prefix}_${millis}_${_toHex(salt)}';
  }

  static String _toHex(List<int> bytes) {
    final StringBuffer buffer = StringBuffer();
    for (final int byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
