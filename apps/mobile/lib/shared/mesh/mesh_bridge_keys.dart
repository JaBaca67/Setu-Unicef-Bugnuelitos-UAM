import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../features/school_access/school_location.dart';

/// Claves efímeras para pruebas locales. No se comparten entre instalaciones.
/// El flujo conectado usa [MeshRecipientDirectory].
class MeshBridgeKeys {
  MeshBridgeKeys._();

  static final X25519 _x25519 = X25519();
  static const String _envPubKeyB64 = String.fromEnvironment(
    'SETU_MESH_BRIDGE_PUBKEY',
  );
  static Future<SimpleKeyPair>? _demoPair;

  static Future<SimpleKeyPair> demoBridgeKeyPair() =>
      _demoPair ??= _x25519.newKeyPair();

  static Future<SimpleKeyPair?> resolveBridgeKeyPair() async {
    final String raw = _envPubKeyB64.trim();
    if (raw.isNotEmpty) {
      try {
        if (base64Decode(raw).length == 32) {
          return null;
        }
      } on Object {
        // Si el formato es inválido, recurre a la clave demo en entorno de prueba.
      }
    }
    return demoBridgeKeyPair();
  }

  static Future<List<int>> resolvePublicKeyBytes() async {
    final String raw = _envPubKeyB64.trim();
    if (raw.isNotEmpty) {
      try {
        final List<int> decoded = base64Decode(raw);
        if (decoded.length == 32) {
          return decoded;
        }
      } on Object {
        // Si el formato es inválido, recurre a la clave demo en entorno de prueba.
      }
    }
    final SimpleKeyPair pair = await demoBridgeKeyPair();
    final SimplePublicKey pub = await pair.extractPublicKey();
    return pub.bytes;
  }
}

/// Claves X25519 por colegio para entrega mínima local a Dirección sin internet.
///
/// Solo para simulaciones dentro de un proceso; nunca se derivan del código.
class MeshSchoolKeys {
  MeshSchoolKeys._();

  static final X25519 _x25519 = X25519();
  static final Map<String, Future<SimpleKeyPair>> _pairs =
      <String, Future<SimpleKeyPair>>{};

  static Future<SimpleKeyPair> demoSchoolKeyPair(
    String publicSchoolCode,
  ) async {
    final String normalized = normalizeSchoolCode(publicSchoolCode);
    return _pairs.putIfAbsent(normalized, _x25519.newKeyPair);
  }

  static Future<List<int>> resolveSchoolPublicKeyBytes(
    String publicSchoolCode,
  ) async {
    final SimpleKeyPair pair = await demoSchoolKeyPair(publicSchoolCode);
    final SimplePublicKey pub = await pair.extractPublicKey();
    return pub.bytes;
  }
}
