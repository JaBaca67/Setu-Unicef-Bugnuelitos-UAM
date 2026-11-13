import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cureando_models.dart';

abstract class KeyVault {
  Future<String?> read();
  Future<void> write(String encodedKey);
}

class AndroidKeyVault implements KeyVault {
  AndroidKeyVault([this._name = 'setu.local.master.v1']);

  final String _name;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => _storage.read(key: _name);
  @override
  Future<void> write(String encodedKey) =>
      _storage.write(key: _name, value: encodedKey);
}

abstract class LocalStorePersistence {
  Future<Map<String, Object?>?> load();
  Future<void> save(Map<String, Object?> value);
}

/// Authenticated encryption. Only encrypted bytes ever reach a temporary file.
class EncryptedLocalStore implements LocalStorePersistence {
  EncryptedLocalStore({required this.file, required this.vault});
  final File file;
  final KeyVault vault;
  final AesGcm _cipher = AesGcm.with256bits();
  static final List<int> _aad = utf8.encode('setu-local-store:v1');

  static Future<EncryptedLocalStore> onDevice({
    String fileName = 'setu_local_store.enc',
    String keyName = 'setu.local.master.v1',
  }) async {
    final Directory dir = await getApplicationSupportDirectory();
    return EncryptedLocalStore(
      file: File('${dir.path}/$fileName'),
      vault: AndroidKeyVault(keyName),
    );
  }

  Future<SecretKey> _key({required bool mayCreate}) async {
    final String? encoded = await vault.read();
    if (encoded != null) {
      final List<int> bytes = base64Decode(encoded);
      if (bytes.length != 32) throw const FormatException('Clave inválida');
      return SecretKey(bytes);
    }
    if (!mayCreate) throw const FormatException('Clave no disponible');
    final SecretKey key = await _cipher.newSecretKey();
    await vault.write(base64Encode(await key.extractBytes()));
    return key;
  }

  @override
  Future<Map<String, Object?>?> load() async {
    try {
      if (!await file.exists()) {
        if (await File('${file.path}.tmp').exists()) {
          throw const FormatException('Escritura incompleta');
        }
        return null;
      }
      final SecretKey key = await _key(mayCreate: false);
      final Map<String, Object?> envelope =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      if (envelope['version'] != 1) {
        throw const FormatException('Versión no soportada');
      }
      final List<int> nonce = base64Decode(envelope['nonce']! as String);
      final List<int> mac = base64Decode(envelope['mac']! as String);
      if (nonce.length != 12 || mac.length != 16) {
        throw const FormatException('Sobre inválido');
      }
      final List<int> clear = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope['ciphertext']! as String),
          nonce: nonce,
          mac: Mac(mac),
        ),
        secretKey: key,
        aad: _aad,
      );
      return jsonDecode(utf8.decode(clear)) as Map<String, Object?>;
    } on Object {
      throw const GatewayException(
        'storage',
        'No se pudo abrir el almacenamiento protegido. No se han borrado los datos.',
      );
    }
  }

  @override
  Future<void> save(Map<String, Object?> value) async {
    try {
      final SecretKey key = await _key(mayCreate: !await file.exists());
      final SecretBox box = await _cipher.encrypt(
        utf8.encode(jsonEncode(value)),
        secretKey: key,
        aad: _aad,
      );
      final String envelope = jsonEncode(<String, Object?>{
        'version': 1,
        'nonce': base64Encode(box.nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      });
      await file.parent.create(recursive: true);
      final File temp = File('${file.path}.tmp');
      await temp.writeAsString(envelope, flush: true);
      await temp.rename(file.path);
    } on Object {
      throw const GatewayException(
        'storage',
        'No se pudo guardar. Los datos anteriores se conservan.',
      );
    }
  }
}
