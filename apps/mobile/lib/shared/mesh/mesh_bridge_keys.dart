import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Claves públicas X25519 del nodo puente para cifrado E2EE de sobres mesh.
///
/// En producción se inyecta mediante `--dart-define=SETU_MESH_BRIDGE_PUBKEY=...`
/// (Base64 de 32 bytes). Si no se define, usa el par determinístico de demo
/// compartido con `MeshTestScreen`.
class MeshBridgeKeys {
  MeshBridgeKeys._();

  static final X25519 _x25519 = X25519();
  static const String _envPubKeyB64 = String.fromEnvironment(
    'SETU_MESH_BRIDGE_PUBKEY',
  );
  static const String _demoSeed = 'setu-demo-mesh-bridge-key-v1-32b';

  static Future<SimpleKeyPair> demoBridgeKeyPair() => _x25519.newKeyPairFromSeed(
    utf8.encode(_demoSeed).sublist(0, 32),
  );

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
