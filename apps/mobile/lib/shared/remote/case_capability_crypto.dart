import 'dart:convert';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';

/// Par criptográfico por caso para acceso privado sin cuentas estudiantiles.
///
/// [capabilityToken] permanece exclusivamente en el almacén cifrado del
/// dispositivo y solo se presenta para consultar o enviar mensajes del caso;
/// [capabilityVerifierHash] (SHA-256 hex en minúsculas) es lo único que recibe
/// Supabase al registrar la alerta.
class CaseCapabilityPair {
  const CaseCapabilityPair({
    required this.capabilityToken,
    required this.capabilityVerifierHash,
  });

  final String capabilityToken;
  final String capabilityVerifierHash;
}

/// Generación de secretos por caso e identificadores de idempotencia.
class CaseCapabilityCrypto {
  CaseCapabilityCrypto({Sha256? sha256}) : _sha256 = sha256 ?? Sha256();

  final Sha256 _sha256;

  /// Genera un token aleatorio de 256 bits codificado en 64 caracteres hex.
  static String generateCapabilityToken({math.Random? random}) {
    final math.Random rng = random ?? math.Random.secure();
    return _randomHex(32, rng);
  }

  /// Genera un `client_operation_id` único (longitud 8..128) para RPCs idempotentes.
  static String generateClientOperationId({
    String prefix = 'op',
    math.Random? random,
  }) {
    final String cleanPrefix = prefix.trim().isEmpty ? 'op' : prefix.trim();
    final math.Random rng = random ?? math.Random.secure();
    return '$cleanPrefix-${_randomHex(16, rng)}';
  }

  /// Calcula el hash SHA-256 en minúsculas (64 caracteres hex) del token.
  Future<String> computeVerifierHash(String capabilityToken) async {
    final String normalized = capabilityToken.trim();
    if (normalized.length < 32) {
      throw ArgumentError.value(
        capabilityToken.length,
        'capabilityToken',
        'El token de capacidad debe tener al menos 32 caracteres.',
      );
    }
    final Hash digest = await _sha256.hash(utf8.encode(normalized));
    return _bytesToHex(digest.bytes);
  }

  /// Crea un par completo token + verificador SHA-256 para una nueva alerta.
  Future<CaseCapabilityPair> generateCapabilityPair({
    math.Random? random,
  }) async {
    final String token = generateCapabilityToken(random: random);
    final String verifierHash = await computeVerifierHash(token);
    return CaseCapabilityPair(
      capabilityToken: token,
      capabilityVerifierHash: verifierHash,
    );
  }

  static String _randomHex(int byteCount, math.Random rng) {
    final List<int> bytes = List<int>.generate(
      byteCount,
      (_) => rng.nextInt(256),
      growable: false,
    );
    return _bytesToHex(bytes);
  }

  static String _bytesToHex(List<int> bytes) {
    final StringBuffer buffer = StringBuffer();
    for (final int value in bytes) {
      buffer.write(value.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
