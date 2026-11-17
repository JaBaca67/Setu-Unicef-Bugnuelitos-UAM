import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/local/encrypted_local_store.dart';
import '../piece/student_piece.dart';
import 'school_location.dart';

/// Colegio que el estudiante confirmó en el acceso escolar. Son datos
/// públicos del centro: no identifican a la persona.
@immutable
class ConfirmedSchool {
  const ConfirmedSchool({
    required this.id,
    required this.publicCode,
    required this.name,
    required this.municipality,
    required this.department,
    this.referenceLat,
    this.referenceLng,
    this.radiusMeters = 150,
  });

  final String id;
  final String publicCode;
  final String name;
  final String municipality;
  final String department;
  final double? referenceLat;
  final double? referenceLng;
  final int radiusMeters;

  static const String setuDemoCode = 'AULA26';

  /// Colegio ficticio de la demo. También reconoce el nombre anterior por si
  /// un backend aún no aplicó el cambio de `supabase/seed.sql`.
  bool get isSetuDemoSchool {
    final String n = name
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('ú', 'u');
    return publicCode == setuDemoCode ||
        n.startsWith('colegio setu') ||
        n.startsWith('colegio centro america');
  }

  /// Nombre que se muestra al estudiante.
  String get displayName => isSetuDemoSchool ? 'Colegio SéTú' : name;

  String get place => '$municipality, Nicaragua';

  /// Escudo de prueba empaquetado; null si el centro no tiene uno en la app.
  String? get crestAsset =>
      isSetuDemoSchool ? 'assets/schools/colegio_setu_prueba.png' : null;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'publicCode': publicCode,
    'name': name,
    'municipality': municipality,
    'department': department,
    if (referenceLat != null) 'referenceLat': referenceLat,
    if (referenceLng != null) 'referenceLng': referenceLng,
    'radiusMeters': radiusMeters,
  };

  static ConfirmedSchool? tryParse(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final Object? id = raw['id'];
    final Object? code = raw['publicCode'];
    final Object? name = raw['name'];
    final Object? municipality = raw['municipality'];
    final Object? department = raw['department'];
    if (id is! String ||
        code is! String ||
        name is! String ||
        municipality is! String ||
        department is! String) {
      return null;
    }
    final Object? rawLat = raw['referenceLat'];
    final Object? rawLng = raw['referenceLng'];
    final Object? rawRadius = raw['radiusMeters'];
    return ConfirmedSchool(
      id: id,
      publicCode: code,
      name: name,
      municipality: municipality,
      department: department,
      referenceLat: rawLat is num ? rawLat.toDouble() : null,
      referenceLng: rawLng is num ? rawLng.toDouble() : null,
      radiusMeters: rawRadius is num && rawRadius > 0 ? rawRadius.toInt() : 150,
    );
  }
}

/// Catálogo de respaldo para cuando no hay red. Refleja los centros de
/// `supabase/seed.sql`.
const List<ConfirmedSchool> localSchoolCatalog = <ConfirmedSchool>[
  ConfirmedSchool(
    id: '11111111-1111-4111-8111-000000000026',
    publicCode: 'AULA26',
    name: 'Colegio SéTú',
    municipality: 'Managua',
    department: 'Managua',
    referenceLat: 12.098062,
    referenceLng: -86.2641465,
    radiusMeters: 150,
  ),
  ConfirmedSchool(
    id: '11111111-1111-4111-8111-000000000024',
    publicCode: 'AULA24',
    name: 'Colegio Público Demo Centro América — CCE',
    municipality: 'Managua',
    department: 'Managua',
    referenceLat: 12.098062,
    referenceLng: -86.2641465,
    radiusMeters: 150,
  ),
  ConfirmedSchool(
    id: '11111111-1111-4111-8111-000000000025',
    publicCode: 'AULA25',
    name: 'Colegio Público Demo Sur — CCE',
    municipality: 'Managua',
    department: 'Managua',
    referenceLat: 12.082500,
    referenceLng: -86.251200,
    radiusMeters: 150,
  ),
];

/// Consulta remota de un código público. Devuelve null si la plataforma
/// respondió que el código no existe; lanza si no pudo responder.
typedef SchoolResolver = Future<ConfirmedSchool?> Function(String publicCode);

/// Sesión estudiantil guardada en el teléfono: el colegio confirmado y la
/// pieza con su nombre de juego. No hay cuenta, nombre real, correo ni foto.
class StudentSession extends ChangeNotifier {
  StudentSession({
    Future<LocalStorePersistence> Function()? openStore,
    this.resolver,
    this.resolveTimeout = const Duration(seconds: 8),
  }) : _openStore = openStore ?? _onDevice {
    piece.addListener(_onPieceChanged);
  }

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_student_session.enc',
        keyName: 'setu.student.session.v1',
      );

  final Future<LocalStorePersistence> Function() _openStore;
  final SchoolResolver? resolver;
  final Duration resolveTimeout;

  final ValueNotifier<StudentPiece> piece = ValueNotifier<StudentPiece>(
    StudentPiece.initial,
  );

  LocalStorePersistence? _store;
  Future<void>? _opening;
  bool _opened = false;
  bool _disposed = false;
  bool _schoolTouched = false;
  bool _pieceTouched = false;
  bool _loadingPiece = false;
  ConfirmedSchool? _school;
  ConfirmedSchool? _candidate;

  /// Colegio confirmado; null si todavía no hay uno o si se salió.
  ConfirmedSchool? get school => _school;

  /// Colegio encontrado por código que todavía falta confirmar.
  ConfirmedSchool? get candidate => _candidate;

  Future<void> open() => _opened ? Future<void>.value() : _opening ??= _load();

  Future<void> _load() async {
    bool legacyNickname = false;
    try {
      final LocalStorePersistence store =
          await Future<LocalStorePersistence>.sync(_openStore);
      final Map<String, Object?>? data = await store.load();
      if (data != null && data['version'] == 1) {
        // Lo que cambió mientras abría el almacén gana sobre lo guardado.
        if (!_schoolTouched) {
          _school = ConfirmedSchool.tryParse(data['school']);
        }
        final Object? saved = data['piece'];
        if (!_pieceTouched && saved is Map<Object?, Object?>) {
          final Object? accessories = saved['accessories'];
          final StudentPiece? parsed = StudentPiece.tryParse(
            shape: saved['shape'] as String?,
            color: saved['color'] as String?,
            accessories: accessories is List<Object?>
                ? accessories.whereType<String>()
                : const <String>[],
            displayName: saved['displayName'] as String?,
          );
          if (parsed != null) {
            _loadingPiece = true;
            piece.value = parsed;
            _loadingPiece = false;
            // Un apodo libre anterior (fuera del catálogo) se descarta del
            // almacén: podría ser un nombre real. La apariencia se conserva.
            if (saved['displayName'] != null && parsed.name == null) {
              legacyNickname = true;
            }
          }
        }
      }
      _store = store;
      if (_schoolTouched || _pieceTouched || legacyNickname) _save();
    } on Object {
      // Sin almacén la sesión vive solo mientras la app está abierta.
    } finally {
      _opened = true;
      _opening = null;
      if (!_disposed) notifyListeners();
    }
  }

  void _onPieceChanged() {
    if (_loadingPiece) return;
    _pieceTouched = true;
    _save();
  }

  /// Busca el colegio de un código público. Consulta la plataforma si hay
  /// cliente remoto y usa el catálogo local solo cuando no pudo responder.
  Future<ConfirmedSchool?> resolve(String rawCode) async {
    final String code = normalizeSchoolCode(rawCode);
    ConfirmedSchool? found;
    bool answered = false;
    final SchoolResolver? remote = resolver;
    if (remote != null) {
      try {
        found = await remote(code).timeout(resolveTimeout);
        answered = true;
      } on Object {
        // Sin red: sigue el catálogo local.
      }
    }
    if (!answered) {
      found = localSchoolCatalog
          .where((ConfirmedSchool school) => school.publicCode == code)
          .firstOrNull;
    }
    _candidate = found;
    return found;
  }

  /// Guarda como colegio activo el que se encontró con [resolve]. El cambio
  /// es inmediato; la escritura en el teléfono no bloquea la navegación.
  void confirmCandidate() {
    final ConfirmedSchool? found = _candidate;
    if (found == null) return;
    _setSchool(found);
  }

  /// Sale del colegio activo. La pieza y el progreso se conservan.
  void leaveSchool() => _setSchool(null);

  void _setSchool(ConfirmedSchool? value) {
    _school = value;
    _candidate = null;
    _schoolTouched = true;
    if (_opened) {
      _save();
    } else {
      unawaited(open());
    }
    if (!_disposed) notifyListeners();
  }

  void _save() {
    _store
        ?.save(<String, Object?>{
          'version': 1,
          'school': _school?.toJson(),
          'piece': piece.value.toJson(),
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _disposed = true;
    piece.dispose();
    super.dispose();
  }
}
