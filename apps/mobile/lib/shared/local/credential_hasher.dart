import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class CredentialDigest {
  const CredentialDigest(this.salt, this.hash, this.iterations);
  final List<int> salt;
  final List<int> hash;
  final int iterations;

  Map<String, Object?> toJson() => <String, Object?>{
    'salt': base64Encode(salt),
    'hash': base64Encode(hash),
    'iterations': iterations,
  };

  factory CredentialDigest.fromJson(Map<String, Object?> json) {
    final List<int> salt = base64Decode(json['salt']! as String);
    final List<int> hash = base64Decode(json['hash']! as String);
    final int iterations = json['iterations']! as int;
    if (salt.length != 16 ||
        hash.length != 32 ||
        iterations < 1000 ||
        iterations > 2000000) {
      throw const FormatException('Derivación no válida');
    }
    return CredentialDigest(salt, hash, iterations);
  }
}

class CredentialHasher {
  CredentialHasher({this.iterations = 600000}) {
    if (iterations < 1000 || iterations > 2000000) {
      throw ArgumentError('Iteraciones fuera de rango');
    }
  }
  final int iterations;
  final Random _random = Random.secure();

  Future<CredentialDigest> digest(String value, String purpose) async {
    final List<int> salt = List<int>.generate(16, (_) => _random.nextInt(256));
    return CredentialDigest(
      salt,
      await _derive('$purpose:$value', salt, iterations),
      iterations,
    );
  }

  Future<bool> verify(
    String value,
    String purpose,
    CredentialDigest digest,
  ) async {
    final List<int> candidate = await _derive(
      '$purpose:$value',
      digest.salt,
      digest.iterations,
    );
    int difference = candidate.length ^ digest.hash.length;
    for (int i = 0; i < candidate.length; i++) {
      difference |= candidate[i] ^ digest.hash[i];
    }
    return difference == 0;
  }
}

Future<List<int>> _derive(String value, List<int> salt, int iterations) =>
    Isolate.run<List<int>>(() async {
      final Pbkdf2 algorithm = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      );
      final SecretKey key = await algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(value)),
        nonce: salt,
      );
      return key.extractBytes();
    });
