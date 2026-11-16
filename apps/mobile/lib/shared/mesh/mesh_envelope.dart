import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Carga mínima permitida para transporte por red mesh (ADR 0005 / ADR 0016).
///
/// Nunca transporta relato clínico, chat, nombres ni credenciales del emisor.
@immutable
class MeshMinimalAlertPayload {
  const MeshMinimalAlertPayload({
    required this.clientOperationId,
    required this.publicSchoolCode,
    required this.situationType,
    required this.studentRole,
    required this.capabilityVerifierHash,
    required this.declaredAt,
    this.involvesStaff = false,
  });

  factory MeshMinimalAlertPayload.fromJson(Map<String, Object?> json) =>
      MeshMinimalAlertPayload(
        clientOperationId: json['client_operation_id']! as String,
        publicSchoolCode: json['public_school_code']! as String,
        situationType: json['situation_type']! as String,
        studentRole: json['student_role']! as String,
        capabilityVerifierHash: json['capability_verifier_hash']! as String,
        declaredAt: DateTime.parse(json['declared_at']! as String),
        involvesStaff: json['involves_staff'] == true,
      );

  final String clientOperationId;
  final String publicSchoolCode;
  final String situationType;
  final String studentRole;
  final String capabilityVerifierHash;
  final DateTime declaredAt;
  final bool involvesStaff;

  Map<String, Object?> toJson() => <String, Object?>{
        'client_operation_id': clientOperationId,
        'public_school_code': publicSchoolCode,
        'situation_type': situationType,
        'student_role': studentRole,
        'capability_verifier_hash': capabilityVerifierHash,
        'declared_at': declaredAt.toUtc().toIso8601String(),
        'involves_staff': involvesStaff,
      };
}

/// Sobre cifrado de extremo a extremo (X25519 + HKDF-SHA256 + AES-GCM-256).
///
/// Los retransmisores solo validan versión, tamaño, [packetId] y [ttl]; no
/// poseen la clave privada del destinatario y no pueden descifrar [ciphertextB64].
@immutable
class MeshEnvelope {
  const MeshEnvelope({
    required this.version,
    required this.packetId,
    required this.ttl,
    required this.ephemeralPublicKeyB64,
    required this.nonceB64,
    required this.macB64,
    required this.ciphertextB64,
  });

  factory MeshEnvelope.fromJson(Map<String, Object?> json) {
    final int version = (json['v']! as num).toInt();
    final int ttl = (json['ttl']! as num).toInt();
    if (version != currentVersion) {
      throw const FormatException('Versión de sobre mesh no soportada');
    }
    return MeshEnvelope(
      version: version,
      packetId: json['id']! as String,
      ttl: ttl,
      ephemeralPublicKeyB64: json['epk']! as String,
      nonceB64: json['n']! as String,
      macB64: json['m']! as String,
      ciphertextB64: json['c']! as String,
    );
  }

  static const int currentVersion = 1;
  static const int maxWireBytes = 4096;
  static const int defaultTtl = 5;

  static final X25519 _x25519 = X25519();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Random _random = Random.secure();
  static final List<int> _aad = utf8.encode('setu-mesh-envelope:v1');

  final int version;
  final String packetId;
  final int ttl;
  final String ephemeralPublicKeyB64;
  final String nonceB64;
  final String macB64;
  final String ciphertextB64;

  static Future<MeshEnvelope> seal(
    MeshMinimalAlertPayload payload, {
    required List<int> recipientPublicKeyBytes,
    int ttl = defaultTtl,
  }) async {
    if (recipientPublicKeyBytes.length != 32) {
      throw ArgumentError('La clave pública X25519 debe tener 32 bytes.');
    }
    final SimpleKeyPair ephemeral = await _x25519.newKeyPair();
    final SimplePublicKey ephemeralPublic = await ephemeral.extractPublicKey();
    final SimplePublicKey recipientPublic = SimplePublicKey(
      recipientPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    final SecretKey shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: recipientPublic,
    );
    final String packetId = _randomHex(16);
    final SecretKey aesKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode(packetId),
      info: _aad,
    );

    final List<int> clearBytes = utf8.encode(jsonEncode(payload.toJson()));
    final SecretBox box = await _aesGcm.encrypt(
      clearBytes,
      secretKey: aesKey,
      aad: _aad,
    );

    return MeshEnvelope(
      version: currentVersion,
      packetId: packetId,
      ttl: ttl,
      ephemeralPublicKeyB64: base64Encode(ephemeralPublic.bytes),
      nonceB64: base64Encode(box.nonce),
      macB64: base64Encode(box.mac.bytes),
      ciphertextB64: base64Encode(box.cipherText),
    );
  }

  Future<MeshMinimalAlertPayload> open({
    required SimpleKeyPair recipientKeyPair,
  }) async {
    final SimplePublicKey ephemeralPublic = SimplePublicKey(
      base64Decode(ephemeralPublicKeyB64),
      type: KeyPairType.x25519,
    );
    final SecretKey shared = await _x25519.sharedSecretKey(
      keyPair: recipientKeyPair,
      remotePublicKey: ephemeralPublic,
    );
    final SecretKey aesKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode(packetId),
      info: _aad,
    );
    final SecretBox box = SecretBox(
      base64Decode(ciphertextB64),
      nonce: base64Decode(nonceB64),
      mac: Mac(base64Decode(macB64)),
    );
    final List<int> clearBytes = await _aesGcm.decrypt(
      box,
      secretKey: aesKey,
      aad: _aad,
    );
    final Object? decoded = jsonDecode(utf8.decode(clearBytes));
    return MeshMinimalAlertPayload.fromJson(
      Map<String, Object?>.from(decoded! as Map<Object?, Object?>),
    );
  }

  /// Devuelve una copia con `ttl - 1` sin modificar el texto cifrado.
  MeshEnvelope nextHop() => MeshEnvelope(
        version: version,
        packetId: packetId,
        ttl: ttl > 0 ? ttl - 1 : 0,
        ephemeralPublicKeyB64: ephemeralPublicKeyB64,
        nonceB64: nonceB64,
        macB64: macB64,
        ciphertextB64: ciphertextB64,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'kind': 'envelope',
        'v': version,
        'id': packetId,
        'ttl': ttl,
        'epk': ephemeralPublicKeyB64,
        'n': nonceB64,
        'm': macB64,
        'c': ciphertextB64,
      };

  Uint8List toWireBytes() {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
    if (bytes.length > maxWireBytes) {
      throw const FormatException('Sobre mesh excede el límite permitido.');
    }
    return bytes;
  }

  static String _randomHex(int byteCount) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < byteCount; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

/// Acuse de custodia o sincronización devuelto al vecino emisor.
@immutable
class MeshAckPacket {
  const MeshAckPacket({
    required this.packetId,
    required this.centrallySynced,
  });

  factory MeshAckPacket.fromJson(Map<String, Object?> json) => MeshAckPacket(
        packetId: json['id']! as String,
        centrallySynced: json['synced'] == true,
      );

  final String packetId;
  final bool centrallySynced;

  Uint8List toWireBytes() => Uint8List.fromList(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'kind': 'ack',
            'id': packetId,
            'synced': centrallySynced,
          }),
        ),
      );
}
