import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../local/encrypted_local_store.dart';
import '../remote/setu_remote_gateway.dart';

/// Directorio público autenticado por HTTPS y caché para equipos preparados.
/// La clave privada se genera en el receptor y permanece en su almacén seguro.
class MeshRecipientDirectory {
  MeshRecipientDirectory(
    this.gateway, {
    KeyVault Function(String userId)? vaultForUser,
    Future<LocalStorePersistence> Function()? openCache,
  }) : _vaultForUser =
           vaultForUser ??
           ((String uid) => AndroidKeyVault('setu.mesh.recipient.$uid.v1')),
       _openCache = openCache ?? _onDevice;

  final SetuRemoteGateway gateway;
  final KeyVault Function(String userId) _vaultForUser;
  final Future<LocalStorePersistence> Function() _openCache;
  Future<LocalStorePersistence>? _cache;
  Future<SimpleKeyPair?>? _loadingKey;
  String? _keyUser;
  String? _receiverSchool;
  String? _registeredOwner;
  final Map<String, Future<void>> _warming = <String, Future<void>>{};

  /// Ruta de emergencia: usar solo claves obtenidas antes por HTTPS, sin
  /// demorar el inicio Nearby en otra consulta que requiere internet.
  Future<List<List<int>>> cachedRecipients(
    String schoolCode,
    bool involvesStaff,
  ) async {
    final String school = schoolCode.trim().toUpperCase();
    final LocalStorePersistence cache = await (_cache ??= _openCache());
    final Map<String, Object?> data = await cache.load() ?? <String, Object?>{};
    return _decodeKeys(
      data['$school:${involvesStaff ? 'external' : 'school'}'],
    );
  }

  static List<List<int>> _decodeKeys(Object? value) {
    final List<List<int>> keys = <List<int>>[];
    for (final Object? encoded
        in value is List<Object?> ? value : const <Object?>[]) {
      if (encoded is! String) continue;
      try {
        final List<int> key = base64Decode(encoded);
        if (key.length == 32) keys.add(key);
      } on FormatException {
        // Una entrada inválida no impide usar las otras claves verificadas.
      }
    }
    return keys;
  }

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_mesh_recipients.enc',
        keyName: 'setu.mesh.recipients.v1',
      );

  Future<SimpleKeyPair?> localKeyPair() {
    final String? uid = gateway.currentStaffUserId;
    if (uid == null) return Future<SimpleKeyPair?>.value();
    final String keyOwner = '$uid:${_receiverSchool ?? 'global'}';
    if (_keyUser != keyOwner) {
      _keyUser = keyOwner;
      _loadingKey = null;
    }
    return _loadingKey ??= _loadKey(keyOwner);
  }

  Future<SimpleKeyPair> _loadKey(String uid) async {
    final KeyVault vault = _vaultForUser(uid);
    final String? existing = await vault.read();
    if (existing != null) {
      final List<int> seed = base64Decode(existing);
      if (seed.length != 32) throw const FormatException('Clave mesh inválida');
      return X25519().newKeyPairFromSeed(seed);
    }
    final SimpleKeyPair pair = await X25519().newKeyPair();
    await vault.write(base64Encode(await pair.extractPrivateKeyBytes()));
    return pair;
  }

  /// El servidor comprueba el rol y el colegio; nunca publica claves privadas.
  Future<SimpleKeyPair?> registerReceiver(String? schoolCode) async {
    _receiverSchool = schoolCode?.trim().toUpperCase();
    final SimpleKeyPair? pair = await localKeyPair();
    if (pair == null) return null;
    final String owner =
        '${gateway.currentStaffUserId}:${_receiverSchool ?? 'global'}';
    if (_registeredOwner == owner) return pair;
    final SimplePublicKey publicKey = await pair.extractPublicKey();
    try {
      await gateway
          .registerMeshRecipient(
            publicSchoolCode: schoolCode,
            publicKeyBase64: base64Encode(publicKey.bytes),
          )
          .timeout(const Duration(seconds: 4));
      _registeredOwner = owner;
    } on Object {
      // Un receptor ya preparado sigue descifrando su cola sin internet.
      // La primera publicación requiere conexión y migración instalada.
    }
    return pair;
  }

  Future<List<List<int>>> recipients(
    String schoolCode,
    bool involvesStaff,
  ) async {
    final String school = schoolCode.trim().toUpperCase();
    final String cacheKey = '$school:${involvesStaff ? 'external' : 'school'}';
    final LocalStorePersistence cache = await (_cache ??= _openCache());
    final Map<String, Object?> data = await cache.load() ?? <String, Object?>{};
    List<String> encoded;
    try {
      encoded = await gateway
          .listMeshRecipientPublicKeys(
            publicSchoolCode: school,
            involvesStaff: involvesStaff,
          )
          .timeout(const Duration(seconds: 4));
      final Map<String, Object?> latest =
          await cache.load() ?? <String, Object?>{};
      latest[cacheKey] = encoded;
      await cache.save(latest);
    } on Object {
      encoded = (data[cacheKey] as List<Object?>? ?? const <Object?>[])
          .whereType<String>()
          .toList();
    }
    return _decodeKeys(encoded);
  }

  /// Preparar ambos destinos antes de desconectar el teléfono estudiantil.
  Future<void> warmSchool(String schoolCode) => _warming.putIfAbsent(
    schoolCode.trim().toUpperCase(),
    () => _warmSchool(schoolCode).whenComplete(() {
      _warming.remove(schoolCode.trim().toUpperCase());
    }),
  );

  Future<void> _warmSchool(String schoolCode) async {
    await recipients(schoolCode, false);
    await recipients(schoolCode, true);
  }
}
