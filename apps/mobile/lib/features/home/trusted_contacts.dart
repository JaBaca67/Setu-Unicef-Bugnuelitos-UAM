import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/local/encrypted_local_store.dart';

/// Número de confianza que el estudiante anota para llamar rápido (ADR 0025).
@immutable
class TrustedContact {
  const TrustedContact({required this.name, required this.number});

  final String name;
  final String number;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'number': number,
  };
}

/// Números de confianza del estudiante. Opcionales, cifrados solo en este
/// teléfono (AES-GCM, almacén de ADR 0004) y nunca enviados al servidor.
class TrustedContacts extends ChangeNotifier {
  TrustedContacts({Future<LocalStorePersistence> Function()? openStore})
    : _openStore = openStore ?? _onDevice;

  static const int maxContacts = 5;
  static const int maxNameLength = 30;

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_trusted_contacts.enc',
        keyName: 'setu.trusted.master.v1',
      );

  final Future<LocalStorePersistence> Function() _openStore;
  LocalStorePersistence? _store;
  List<TrustedContact> _contacts = const <TrustedContact>[];
  bool _ready = false;
  bool _failed = false;
  bool _disposed = false;

  List<TrustedContact> get contacts => _contacts;
  bool get ready => _ready;
  bool get failed => _failed;
  bool get isFull => _contacts.length >= maxContacts;

  /// Deja solo dígitos y un `+` inicial; devuelve `null` si no es válido.
  static String? normalizeNumber(String raw) {
    final String trimmed = raw.trim();
    final bool plus = trimmed.startsWith('+');
    final String digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 3 || digits.length > 15) return null;
    return plus ? '+$digits' : digits;
  }

  static String? normalizeName(String raw) {
    final String name = raw.trim();
    if (name.isEmpty || name.length > maxNameLength) return null;
    return name;
  }

  Future<void> open() async {
    try {
      final LocalStorePersistence store = await _openStore();
      final Map<String, Object?>? data = await store.load();
      if (data != null) {
        if (data['version'] != 1) {
          throw const FormatException('Versión no soportada');
        }
        _contacts = List<TrustedContact>.unmodifiable(
          (data['contacts'] as List<Object?>).map((Object? item) {
            final Map<String, Object?> map = Map<String, Object?>.from(
              item! as Map<Object?, Object?>,
            );
            return TrustedContact(
              name: map['name']! as String,
              number: map['number']! as String,
            );
          }),
        );
      }
      _store = store;
    } on Object {
      _failed = true;
    } finally {
      _ready = true;
      _notify();
    }
  }

  /// Agrega un contacto. Devuelve un mensaje de error o `null` si se guardó.
  Future<String?> add({required String name, required String number}) async {
    final String? cleanName = normalizeName(name);
    final String? cleanNumber = normalizeNumber(number);
    if (cleanName == null) return 'Escribí un nombre corto (hasta 30 letras).';
    if (cleanNumber == null) return 'Escribí un número de teléfono válido.';
    if (isFull) return 'Podés guardar hasta $maxContacts números.';
    return _save(<TrustedContact>[
      ..._contacts,
      TrustedContact(name: cleanName, number: cleanNumber),
    ]);
  }

  Future<String?> removeAt(int index) {
    if (index < 0 || index >= _contacts.length) {
      return Future<String?>.value();
    }
    return _save(<TrustedContact>[..._contacts]..removeAt(index));
  }

  Future<String?> _save(List<TrustedContact> next) async {
    final LocalStorePersistence? store = _store;
    if (store == null) return 'No se pudo guardar en este teléfono.';
    try {
      await store.save(<String, Object?>{
        'version': 1,
        'contacts': <Map<String, Object?>>[
          for (final TrustedContact contact in next) contact.toJson(),
        ],
      });
      _contacts = List<TrustedContact>.unmodifiable(next);
      _notify();
      return null;
    } on Object {
      return 'No se pudo guardar en este teléfono.';
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
