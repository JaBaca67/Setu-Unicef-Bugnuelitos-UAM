import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import '../contracts/cureando_gateway.dart';
import '../models/cureando_models.dart';
import '../models/staff_models.dart';
import 'credential_hasher.dart';
import 'encrypted_local_store.dart';

typedef _Json = Map<String, Object?>;

_Json _object(Object? value) => value! as Map<String, Object?>;
List<_Json> _rows(_Json state, String key) =>
    (state[key]! as List<Object?>).map(_object).toList();
const GatewayException _denied = GatewayException(
  'access',
  'No tienes acceso a este caso.',
);
const GatewayException _invalidCredential = GatewayException(
  'credentials',
  'No se pudo validar el acceso.',
);

class _LocalDatabase {
  _LocalDatabase(this.persistence, this.hasher, this.clock);
  final LocalStorePersistence persistence;
  final CredentialHasher hasher;
  final DateTime Function() clock;
  final Random random = Random.secure();
  _Json? _state;
  Future<void>? _opening;
  Future<void> _tail = Future<void>.value();

  Future<void> open() => _opening ??= _load();
  Future<void> _load() async {
    final _Json? loaded = await persistence.load();
    if (loaded != null) {
      if (loaded['schema'] != 1 ||
          <String>[
            'accounts',
            'reports',
            'messages',
            'notes',
            'requests',
            'operations',
            'attempts',
            'events',
          ].any((String k) => loaded[k] is! List<Object?>)) {
        throw const GatewayException(
          'storage',
          'Formato de almacenamiento no compatible. No se han borrado los datos.',
        );
      }
      _state = loaded;
    } else {
      final _Json initial = <String, Object?>{
        'schema': 1,
        'sequence': 0,
        for (final String key in <String>[
          'accounts',
          'reports',
          'messages',
          'notes',
          'requests',
          'operations',
          'attempts',
          'events',
        ])
          key: <Object?>[],
      };
      await persistence.save(initial);
      _state = initial;
    }
  }

  /// Serializes read/modify/write and publishes only after a successful atomic save.
  Future<T> transaction<T>(FutureOr<T> Function(_Json state) action) {
    final Completer<T> result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        await open();
        final _Json copy = jsonDecode(jsonEncode(_state)) as _Json;
        final T value = await action(copy);
        await persistence.save(copy);
        _state = copy;
        result.complete(value);
      } on Object catch (e, stack) {
        result.completeError(e, stack);
      }
    });
    return result.future;
  }

  String id() => base64UrlEncode(
    List<int>.generate(16, (_) => random.nextInt(256)),
  ).replaceAll('=', '');
  String code() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List<String>.generate(
      4,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  String now() => clock().toUtc().toIso8601String();
  int next(_Json state) =>
      (state['sequence'] = (state['sequence']! as int) + 1);

  bool locked(_Json state, String scope) {
    final List<_Json> found = _rows(
      state,
      'attempts',
    ).where((_Json r) => r['scope'] == scope).toList();
    return found.isNotEmpty &&
        DateTime.parse(
          found.first['until']! as String,
        ).isAfter(clock().toUtc());
  }

  void attempt(_Json state, String scope, {required bool success}) {
    final List<_Json> all = _rows(state, 'attempts');
    final List<_Json> found = all
        .where((_Json r) => r['scope'] == scope)
        .toList();
    if (success) {
      all.removeWhere((_Json r) => r['scope'] == scope);
    } else {
      final _Json record = found.isEmpty
          ? <String, Object?>{'scope': scope, 'failures': 0, 'until': now()}
          : found.first;
      if (DateTime.parse(
            record['until']! as String,
          ).isBefore(clock().toUtc()) &&
          (record['failures']! as int) >= 5) {
        record['failures'] = 0;
      }
      final int failures = (record['failures']! as int) + 1;
      record['failures'] = failures;
      record['until'] =
          (failures >= 5
                  ? clock().toUtc().add(const Duration(minutes: 5))
                  : clock().toUtc())
              .toIso8601String();
      if (found.isEmpty) all.add(record);
    }
    state['attempts'] = all;
  }

  Future<String> once(
    _Json state,
    String scope,
    String key,
    _Json payload,
    FutureOr<String> Function() action,
  ) async {
    if (key.trim().isEmpty || key.length > 128) {
      throw const GatewayException(
        'validation',
        'Se requiere una clave de operación válida.',
      );
    }
    final String fingerprint = base64Encode(
      (await Sha256().hash(utf8.encode(jsonEncode(payload)))).bytes,
    );
    final List<_Json> matches = _rows(
      state,
      'operations',
    ).where((_Json r) => r['scope'] == scope && r['key'] == key).toList();
    if (matches.isNotEmpty) {
      if (matches.first['fingerprint'] != fingerprint) {
        throw const GatewayException(
          'idempotency',
          'La clave ya se usó con otro contenido.',
        );
      }
      return matches.first['result']! as String;
    }
    final String id = await action();
    state['operations'] = <_Json>[
      ..._rows(state, 'operations'),
      <String, Object?>{
        'scope': scope,
        'key': key,
        'fingerprint': fingerprint,
        'result': id,
      },
    ];
    return id;
  }
}

class LocalCureandoGateway implements CureandoGateway {
  LocalCureandoGateway({
    required LocalStorePersistence persistence,
    CredentialHasher? hasher,
    DateTime Function()? clock,
  }) : _db = _LocalDatabase(
         persistence,
         hasher ?? CredentialHasher(),
         clock ?? DateTime.now,
       );
  final _LocalDatabase _db;
  String? _accountId;
  String? _caseId;
  SimulatedNetwork simulatedNetwork = SimulatedNetwork.connected;

  /// Production app uses encrypted disk; alternative stores only serve tests.
  static Future<LocalCureandoGateway> onDevice() async =>
      LocalCureandoGateway(persistence: await EncryptedLocalStore.onDevice());

  static const List<InstitutionView> institutions = <InstitutionView>[
    InstitutionView(id: 'north', name: 'Colegio Público Demo Norte — CCE'),
    InstitutionView(id: 'south', name: 'Colegio Público Demo Sur — CCE'),
  ];

  @override
  Future<void> initialize() => _db.open();

  @override
  Future<InstitutionView> checkInstitutionInvite(String code) async {
    final String normalized = code.trim().toUpperCase();
    if (normalized == 'DEMO-NORTE' || normalized == 'QR-DEMO-NORTE') {
      return institutions[0];
    }
    if (normalized == 'DEMO-SUR' || normalized == 'QR-DEMO-SUR') {
      return institutions[1];
    }
    if (normalized == 'DEMO-PAUSA') {
      throw const GatewayException(
        'inactive',
        'El centro no está disponible para recibir casos.',
      );
    }
    throw const GatewayException('invite', 'Invitación inválida o vencida.');
  }

  void _validateAlias(String alias) {
    if (!RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(alias)) {
      throw const GatewayException(
        'validation',
        'Usa un alias de 3 a 24 letras, números o guion bajo. Evita tu nombre y apellido.',
      );
    }
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      throw const GatewayException(
        'validation',
        'El PIN debe tener de 4 a 6 dígitos.',
      );
    }
  }

  StudentAccountView _accountView(_Json r) => StudentAccountView(
    id: r['id']! as String,
    alias: r['alias']! as String,
    institutionId: r['institutionId']! as String,
  );

  @override
  Future<AccountRegistration> registerStudent({
    required String alias,
    required String pin,
    required String inviteCode,
  }) async {
    alias = alias.trim();
    _validateAlias(alias);
    _validatePin(pin);
    final InstitutionView institution = await checkInstitutionInvite(
      inviteCode,
    );
    final String backup = 'SETU-${_db.code()}-${_db.code()}';
    final AccountRegistration registration = await _db
        .transaction<AccountRegistration>((_Json state) async {
          if (_rows(state, 'accounts').any(
            (_Json r) =>
                (r['alias']! as String).toLowerCase() == alias.toLowerCase(),
          )) {
            throw const GatewayException(
              'alias',
              'Este alias no está disponible. Elige otro.',
            );
          }
          final _Json row = <String, Object?>{
            'id': _db.id(),
            'alias': alias,
            'institutionId': institution.id,
            'pin': (await _db.hasher.digest(pin, 'account-pin')).toJson(),
            'backup': (await _db.hasher.digest(
              backup,
              'account-backup',
            )).toJson(),
          };
          state['accounts'] = <_Json>[..._rows(state, 'accounts'), row];
          return AccountRegistration(_accountView(row), backup);
        });
    _accountId = registration.account.id;
    _caseId = null;
    return registration;
  }

  @override
  Future<StudentAccountView> signIn({
    required String alias,
    required String pin,
  }) async {
    _accountId = null;
    _caseId = null;
    final String normalized = alias.trim().toLowerCase();
    final Object result = await _db.transaction<Object>((_Json state) async {
      final String scope = 'account:$normalized';
      if (_db.locked(state, scope)) {
        return const GatewayException(
          'locked',
          'Espera cinco minutos antes de volver a intentar.',
        );
      }
      final List<_Json> found = _rows(state, 'accounts')
          .where(
            (_Json r) => (r['alias']! as String).toLowerCase() == normalized,
          )
          .toList();
      final bool valid =
          found.isNotEmpty &&
          await _db.hasher.verify(
            pin,
            'account-pin',
            CredentialDigest.fromJson(_object(found.first['pin'])),
          );
      _db.attempt(state, scope, success: valid);
      return valid ? _accountView(found.first) : _invalidCredential;
    });
    if (result is GatewayException) throw result;
    final StudentAccountView account = result as StudentAccountView;
    _accountId = account.id;
    _caseId = null;
    return account;
  }

  @override
  Future<void> resetPin({
    required String alias,
    required String backupCode,
    required String newPin,
  }) async {
    _validatePin(newPin);
    final String normalized = alias.trim().toLowerCase();
    final Object? result = await _db.transaction<Object?>((_Json state) async {
      final String scope = 'backup:$normalized';
      if (_db.locked(state, scope)) {
        return const GatewayException(
          'locked',
          'Espera cinco minutos antes de volver a intentar.',
        );
      }
      final List<_Json> found = _rows(state, 'accounts')
          .where(
            (_Json r) => (r['alias']! as String).toLowerCase() == normalized,
          )
          .toList();
      final bool valid =
          found.isNotEmpty &&
          await _db.hasher.verify(
            backupCode.trim().toUpperCase(),
            'account-backup',
            CredentialDigest.fromJson(_object(found.first['backup'])),
          );
      _db.attempt(state, scope, success: valid);
      if (!valid) return _invalidCredential;
      found.first['pin'] = (await _db.hasher.digest(
        newPin,
        'account-pin',
      )).toJson();
      _db.attempt(state, 'account:$normalized', success: true);
      return null;
    });
    if (result is GatewayException) throw result;
    await signOut();
  }

  @override
  Future<void> signOut() async {
    _accountId = null;
    _caseId = null;
  }

  @override
  Future<StudentAccountView?> currentAccount() =>
      _db.transaction<StudentAccountView?>(
        (_Json s) =>
            _accountId == null ? null : _accountView(_requireAccount(s)),
      );

  _Json _requireAccount(_Json state) {
    final List<_Json> found = _rows(
      state,
      'accounts',
    ).where((_Json r) => r['id'] == _accountId).toList();
    if (_accountId == null || found.isEmpty) throw _denied;
    return found.first;
  }

  _Json _requireCase(_Json state, String id) {
    final _Json report = _findCase(state, id);
    final bool accountAccess =
        _accountId != null &&
        report['accountId'] == _accountId &&
        report['institutionId'] == _requireAccount(state)['institutionId'];
    if (!accountAccess && _caseId != id) throw _denied;
    return report;
  }

  void _networkBefore() {
    if (simulatedNetwork == SimulatedNetwork.offline) {
      throw const GatewayException(
        'offline',
        'No se ha guardado. Reintenta cuando termine la prueba sin conexión.',
      );
    }
  }

  void _networkAfter() {
    if (simulatedNetwork == SimulatedNetwork.uncertain) {
      throw const GatewayException(
        'uncertain',
        'No se pudo confirmar. Comprueba y reintenta con la misma operación.',
      );
    }
  }

  @override
  Future<ReportReceipt> submitReport(SubmitReportInput input) async {
    _networkBefore();
    _validateText(input.body);
    if (input.locationText.length > 500 ||
        input.approxDateText.length > 200 ||
        input.situations.length > SituationType.values.length) {
      throw const GatewayException(
        'validation',
        'El contexto del reporte es demasiado largo.',
      );
    }
    final ReportReceipt receipt = await _db.transaction<ReportReceipt>((
      _Json state,
    ) async {
      final _Json account = _requireAccount(state);
      final String id = await _db.once(
        state,
        'report:${account['id']}',
        input.clientRequestId,
        input.toJson(),
        () {
          final String id = _db.id();
          state['reports'] = <_Json>[
            ..._rows(state, 'reports'),
            <String, Object?>{
              ...input.toJson(),
              'id': id,
              'accountId': account['id'],
              'institutionId': account['institutionId'],
              'referenceCode':
                  'SETU-${_db.code()}${_db.code()}-${_db.code()}${_db.code()}',
              'createdAt': _db.now(),
              'status': ReportStatus.received.name,
              'lastReadSequence': 0,
            },
          ];
          return id;
        },
      );
      final _Json report = _findCase(state, id);
      return ReportReceipt(
        reportId: id,
        referenceCode: report['referenceCode']! as String,
        createdAt: DateTime.parse(report['createdAt']! as String),
      );
    });
    _networkAfter();
    return receipt;
  }

  @override
  Future<List<StudentCaseSummary>> listMyReports() =>
      _db.transaction<List<StudentCaseSummary>>((_Json state) {
        final _Json account = _requireAccount(state);
        return List<StudentCaseSummary>.unmodifiable(
          _rows(state, 'reports')
              .where(
                (_Json r) =>
                    r['accountId'] == account['id'] &&
                    r['institutionId'] == account['institutionId'],
              )
              .map((_Json r) => _summary(state, r)),
        );
      });

  @override
  Future<StudentCaseDetailView> getReportDetail(String reportId) =>
      _db.transaction<StudentCaseDetailView>((_Json state) {
        final _Json report = _requireCase(state, reportId);
        report['lastReadSequence'] = state['sequence'];
        return _studentDetail(state, report);
      });

  @override
  Future<void> sendStudentMessage(SendMessageInput input) async {
    _networkBefore();
    _validateText(input.body);
    await _db.transaction<void>((_Json state) async {
      final _Json report = _requireCase(state, input.reportId);
      await _db.once(
        state,
        'student-message:${report['accountId']}',
        input.clientRequestId,
        <String, Object?>{'id': input.reportId, 'body': input.body},
        () {
          final String id = _db.id();
          _addMessage(_db, state, report, id, AuthorRole.student, input.body);
          if (report['status'] == ReportStatus.closed.name) {
            report['reopenRequestedAt'] = _db.now();
          }
          return id;
        },
      );
    });
    _networkAfter();
  }

  @override
  Future<SupportRequestView> requestSupport({
    required String reportId,
    required SupportRequestType type,
    required String clientRequestId,
  }) async {
    _networkBefore();
    final SupportRequestView request = await _db
        .transaction<SupportRequestView>((_Json state) async {
          final _Json report = _requireCase(state, reportId);
          final String id = await _db.once(
            state,
            'request:${report['accountId']}',
            clientRequestId,
            <String, Object?>{'id': reportId, 'type': type.name},
            () {
              final String id = _db.id();
              state['requests'] = <_Json>[
                ..._rows(state, 'requests'),
                <String, Object?>{
                  'id': id,
                  'reportId': reportId,
                  'type': type.name,
                  'createdAt': _db.now(),
                },
              ];
              if (type == SupportRequestType.followUp) {
                report['reopenRequestedAt'] = _db.now();
              }
              return id;
            },
          );
          return _request(
            _rows(state, 'requests').firstWhere((_Json r) => r['id'] == id),
          );
        });
    _networkAfter();
    return request;
  }

  @override
  Future<CaseAccessCredential> createCaseAccess(String reportId) =>
      _db.transaction<CaseAccessCredential>((_Json state) async {
        final _Json account = _requireAccount(state);
        final _Json report = _requireCase(state, reportId);
        if (report['accountId'] != account['id']) throw _denied;
        final String pin = _db.random.nextInt(10000).toString().padLeft(4, '0');
        report['casePin'] = (await _db.hasher.digest(pin, 'case-pin')).toJson();
        return CaseAccessCredential(report['referenceCode']! as String, pin);
      });

  @override
  Future<StudentCaseDetailView> accessCase({
    required String referenceCode,
    required String pin,
  }) async {
    _accountId = null;
    _caseId = null;
    final String normalized = referenceCode.trim().toUpperCase();
    final Object result = await _db.transaction<Object>((_Json state) async {
      final String scope = 'case:$normalized';
      if (_db.locked(state, scope)) {
        return const GatewayException(
          'locked',
          'Espera cinco minutos antes de volver a intentar.',
        );
      }
      final List<_Json> found = _rows(
        state,
        'reports',
      ).where((_Json r) => r['referenceCode'] == normalized).toList();
      final bool valid =
          RegExp(r'^\d{4}$').hasMatch(pin) &&
          found.isNotEmpty &&
          found.first['casePin'] != null &&
          await _db.hasher.verify(
            pin,
            'case-pin',
            CredentialDigest.fromJson(_object(found.first['casePin'])),
          );
      _db.attempt(state, scope, success: valid);
      if (!valid) return _invalidCredential;
      found.first['lastReadSequence'] = state['sequence'];
      return _studentDetail(state, found.first);
    });
    if (result is GatewayException) throw result;
    final StudentCaseDetailView detail = result as StudentCaseDetailView;
    _accountId = null;
    _caseId = detail.summary.reportId;
    return detail;
  }

  /// A separate facade for explicitly fictitious, allowlisted local staff.
  StaffCureandoGateway staffForLocalTesting(String profileId) {
    final List<LocalStaffProfile> found = localStaffProfiles
        .where((LocalStaffProfile p) => p.id == profileId)
        .toList();
    if (found.isEmpty) throw _denied;
    return _LocalStaffGateway(_db, found.first);
  }

  static const List<LocalStaffProfile> localStaffProfiles = <LocalStaffProfile>[
    LocalStaffProfile(
      id: 'north-cce',
      institutionId: 'north',
      role: OrientationRole.counseling,
    ),
    LocalStaffProfile(
      id: 'north-psychology',
      institutionId: 'north',
      role: OrientationRole.psychology,
    ),
    LocalStaffProfile(
      id: 'north-supervisor',
      institutionId: 'north',
      role: OrientationRole.supervisor,
    ),
    LocalStaffProfile(
      id: 'south-cce',
      institutionId: 'south',
      role: OrientationRole.counseling,
    ),
    LocalStaffProfile(
      id: 'south-psychology',
      institutionId: 'south',
      role: OrientationRole.psychology,
    ),
    LocalStaffProfile(
      id: 'south-supervisor',
      institutionId: 'south',
      role: OrientationRole.supervisor,
    ),
  ];
}

class _LocalStaffGateway implements StaffCureandoGateway {
  _LocalStaffGateway(this.db, this.profile);
  final _LocalDatabase db;
  final LocalStaffProfile profile;

  bool _allowed(_Json report) =>
      report['institutionId'] == profile.institutionId &&
      (report['involvesStaff'] == true
          ? profile.role == OrientationRole.supervisor
          : profile.role == OrientationRole.supervisor ||
                report['recipient'] == profile.role.name);
  _Json _require(_Json state, String id) {
    final _Json report = _findCase(state, id);
    if (!_allowed(report)) throw _denied;
    return report;
  }

  @override
  Future<List<StudentCaseSummary>> listReports() =>
      db.transaction<List<StudentCaseSummary>>(
        (_Json s) => List<StudentCaseSummary>.unmodifiable(
          _rows(s, 'reports').where(_allowed).map((_Json r) => _summary(s, r)),
        ),
      );
  @override
  Future<StaffCaseDetailView> getReportDetail(String reportId) =>
      db.transaction<StaffCaseDetailView>((_Json s) {
        final _Json report = _require(s, reportId);
        s['events'] = <_Json>[
          ..._rows(s, 'events'),
          <String, Object?>{
            'action': 'staff-open',
            'actor': profile.id,
            'reportId': reportId,
            'at': db.now(),
          },
        ];
        return StaffCaseDetailView(
          studentView: _studentDetail(s, report),
          internalNotes: _rows(s, 'notes')
              .where((_Json n) => n['reportId'] == reportId)
              .map(
                (_Json n) => InternalNoteView(
                  id: n['id']! as String,
                  body: n['body']! as String,
                  createdAt: DateTime.parse(n['createdAt']! as String),
                ),
              )
              .toList(),
        );
      });
  @override
  Future<void> sendReply(SendMessageInput input) =>
      db.transaction<void>((_Json s) async {
        _validateText(input.body);
        final _Json report = _require(s, input.reportId);
        await db.once(
          s,
          'staff-reply:${profile.id}',
          input.clientRequestId,
          <String, Object?>{'id': input.reportId, 'body': input.body},
          () {
            final String id = db.id();
            _addMessage(db, s, report, id, AuthorRole.staff, input.body);
            return id;
          },
        );
      });
  @override
  Future<void> addInternalNote(SendMessageInput input) =>
      db.transaction<void>((_Json s) async {
        _validateText(input.body);
        _require(s, input.reportId);
        await db.once(
          s,
          'staff-note:${profile.id}',
          input.clientRequestId,
          <String, Object?>{'id': input.reportId, 'body': input.body},
          () {
            final String id = db.id();
            s['notes'] = <_Json>[
              ..._rows(s, 'notes'),
              <String, Object?>{
                'id': id,
                'reportId': input.reportId,
                'body': input.body,
                'actor': profile.id,
                'createdAt': db.now(),
              },
            ];
            return id;
          },
        );
      });
  @override
  Future<void> changeStatus({
    required String reportId,
    required ReportStatus status,
    required String reason,
    required String clientRequestId,
  }) => db.transaction<void>((_Json s) async {
    final _Json report = _require(s, reportId);
    _validateText(reason);
    await db.once(
      s,
      'staff-state:${profile.id}',
      clientRequestId,
      <String, Object?>{
        'id': reportId,
        'status': status.name,
        'reason': reason,
      },
      () {
        final ReportStatus old = ReportStatus.values.byName(
          report['status']! as String,
        );
        final Map<ReportStatus, Set<ReportStatus>> allowed =
            <ReportStatus, Set<ReportStatus>>{
              ReportStatus.received: {ReportStatus.inReview},
              ReportStatus.inReview: {
                ReportStatus.accompanied,
                ReportStatus.closed,
              },
              ReportStatus.accompanied: {ReportStatus.closed},
              ReportStatus.closed: {ReportStatus.inReview},
            };
        if (!allowed[old]!.contains(status)) {
          throw const GatewayException(
            'transition',
            'Cambio de estado no permitido.',
          );
        }
        report['status'] = status.name;
        report['closedReason'] = status == ReportStatus.closed ? reason : null;
        if (old == ReportStatus.closed) report['reopenRequestedAt'] = null;
        final String id = db.id();
        s['events'] = <_Json>[
          ..._rows(s, 'events'),
          <String, Object?>{
            'id': id,
            'action': 'status',
            'actor': profile.id,
            'reportId': reportId,
            'from': old.name,
            'to': status.name,
            'reason': reason,
            'at': db.now(),
          },
        ];
        return id;
      },
    );
  });
}

void _validateText(String body) {
  if (body.trim().isEmpty || body.length > 5000) {
    throw const GatewayException(
      'validation',
      'Escribe un texto de hasta 5000 caracteres.',
    );
  }
}

_Json _findCase(_Json state, String id) {
  final List<_Json> found = _rows(
    state,
    'reports',
  ).where((_Json r) => r['id'] == id).toList();
  if (found.isEmpty) throw _denied;
  return found.first;
}

void _addMessage(
  _LocalDatabase db,
  _Json state,
  _Json report,
  String id,
  AuthorRole role,
  String body,
) {
  state['messages'] = <_Json>[
    ..._rows(state, 'messages'),
    <String, Object?>{
      'id': id,
      'reportId': report['id'],
      'role': role.name,
      'body': body,
      'createdAt': db.now(),
      'sequence': db.next(state),
    },
  ];
}

StudentCaseSummary _summary(_Json state, _Json report) {
  final bool unread = _rows(state, 'messages').any(
    (_Json m) =>
        m['reportId'] == report['id'] &&
        m['role'] == AuthorRole.staff.name &&
        (m['sequence']! as int) > (report['lastReadSequence']! as int),
  );
  return StudentCaseSummary(
    reportId: report['id']! as String,
    referenceCode: report['referenceCode']! as String,
    status: ReportStatus.values.byName(report['status']! as String),
    createdAt: DateTime.parse(report['createdAt']! as String),
    hasUnreadStaffReply: unread,
  );
}

SupportRequestView _request(_Json r) => SupportRequestView(
  id: r['id']! as String,
  type: SupportRequestType.values.byName(r['type']! as String),
  createdAt: DateTime.parse(r['createdAt']! as String),
);
StudentCaseDetailView _studentDetail(_Json state, _Json report) =>
    StudentCaseDetailView(
      summary: _summary(state, report),
      body: report['body']! as String,
      relation: RelationType.values.byName(report['relation']! as String),
      recipient: report['involvesStaff'] == true
          ? OrientationRole.supervisor
          : OrientationRole.values.byName(report['recipient']! as String),
      involvesStaff: report['involvesStaff']! as bool,
      situations: (report['situations']! as List<Object?>)
          .map((Object? value) => SituationType.values.byName(value! as String))
          .toList(),
      place: report['place'] == null
          ? null
          : PlaceType.values.byName(report['place']! as String),
      earlyWarning: report['earlyWarning'] == null
          ? null
          : EarlyWarning.values.byName(report['earlyWarning']! as String),
      locationText: report['locationText']! as String,
      approxDateText: report['approxDateText']! as String,
      closedReason: report['closedReason'] as String?,
      messages: _rows(state, 'messages')
          .where((_Json m) => m['reportId'] == report['id'])
          .map(
            (_Json m) => VisibleMessage(
              id: m['id']! as String,
              role: AuthorRole.values.byName(m['role']! as String),
              body: m['body']! as String,
              createdAt: DateTime.parse(m['createdAt']! as String),
            ),
          )
          .toList(),
      requests: _rows(state, 'requests')
          .where((_Json r) => r['reportId'] == report['id'])
          .map(_request)
          .toList(),
    );
