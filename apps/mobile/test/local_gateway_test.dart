import 'dart:convert';
import 'dart:io';
import 'package:cureando_mobile/shared/contracts/cureando_gateway.dart';
import 'package:cureando_mobile/shared/local/credential_hasher.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:cureando_mobile/shared/local/local_cureando_gateway.dart';
import 'package:cureando_mobile/shared/mock/mock_cureando_gateway.dart';
import 'package:cureando_mobile/shared/models/cureando_models.dart';
import 'package:cureando_mobile/shared/models/staff_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Vault implements KeyVault {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String encodedKey) async {
    value = encodedKey;
  }
}

class _FailingStore extends MemoryTestStore {
  bool fail = false;
  @override
  Future<void> save(Map<String, Object?> value) async {
    if (fail) throw const GatewayException('storage', 'Fallo de prueba');
    await super.save(value);
  }
}

Matcher _error(String code) => isA<GatewayException>().having(
  (GatewayException e) => e.code,
  'code',
  code,
);
SubmitReportInput _input(
  String key, {
  String body = 'Relato completamente ficticio de prueba.',
  bool conflict = false,
  OrientationRole recipient = OrientationRole.counseling,
}) => SubmitReportInput(
  clientRequestId: key,
  relation: RelationType.witness,
  body: body,
  involvesStaff: conflict,
  recipient: recipient,
  situations: <SituationType>[SituationType.exclusion],
  place: PlaceType.playground,
  earlyWarning: EarlyWarning.recent,
);

LocalCureandoGateway _gateway(
  LocalStorePersistence store, {
  DateTime Function()? clock,
}) => LocalCureandoGateway(
  persistence: store,
  hasher: CredentialHasher(iterations: 1000),
  clock: clock,
);

void main() {
  group('Archivo AES-GCM', () {
    late Directory dir;
    late File file;
    late _Vault vault;
    late EncryptedLocalStore store;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('setu_m1_test_');
      file = File('${dir.path}/setu_local_store.enc');
      vault = _Vault();
      store = EncryptedLocalStore(file: file, vault: vault);
    });
    tearDown(() async {
      final String absolute = dir.absolute.path;
      if (!absolute.startsWith(Directory.systemTemp.absolute.path) ||
          !dir.path.contains('setu_m1_test_')) {
        throw StateError('Ruta temporal inesperada');
      }
      await dir.delete(recursive: true);
    });

    test(
      'roundtrip y nonce distinto; nunca escribe el relato en claro',
      () async {
        const Map<String, Object?> data = <String, Object?>{
          'body': 'SECRETO_FICTICIO_NO_REAL',
        };
        await store.save(data);
        final String first = await file.readAsString();
        expect(first, isNot(contains('SECRETO_FICTICIO_NO_REAL')));
        expect(await store.load(), data);
        expect(base64Decode(vault.value!).length, 32);
        await store.save(data);
        final Map<String, Object?> a =
            jsonDecode(first) as Map<String, Object?>;
        final Map<String, Object?> b =
            jsonDecode(await file.readAsString()) as Map<String, Object?>;
        expect(a['nonce'], isNot(b['nonce']));
        expect(base64Decode(b['nonce']! as String).length, 12);
        expect(base64Decode(b['mac']! as String).length, 16);
      },
    );

    test(
      'alteración de ciphertext, nonce, MAC y versión falla sin borrar',
      () async {
        await store.save(<String, Object?>{'body': 'Ficticio'});
        final String original = await file.readAsString();
        for (final String field in <String>[
          'ciphertext',
          'nonce',
          'mac',
          'version',
        ]) {
          final Map<String, Object?> data =
              jsonDecode(original) as Map<String, Object?>;
          if (field == 'version') {
            data[field] = 2;
          } else {
            final List<int> bytes = base64Decode(data[field]! as String);
            bytes[0] ^= 1;
            data[field] = base64Encode(bytes);
          }
          final String damaged = jsonEncode(data);
          await file.writeAsString(damaged);
          await expectLater(store.load(), throwsA(_error('storage')));
          expect(await file.readAsString(), damaged);
        }
      },
    );

    test('clave ausente o distinta no reemplaza el archivo', () async {
      await store.save(<String, Object?>{'body': 'Ficticio'});
      final String original = await file.readAsString();
      vault.value = null;
      await expectLater(store.load(), throwsA(_error('storage')));
      await expectLater(
        store.save(<String, Object?>{}),
        throwsA(_error('storage')),
      );
      expect(vault.value, isNull);
      vault.value = base64Encode(List<int>.filled(32, 0));
      await expectLater(store.load(), throwsA(_error('storage')));
      expect(await file.readAsString(), original);
    });

    test(
      'archivo temporal huérfano se informa, no se pierde silenciosamente',
      () async {
        await File(
          '${file.path}.tmp',
        ).writeAsString('escritura interrumpida ficticia');
        await expectLater(store.load(), throwsA(_error('storage')));
        expect(await file.exists(), isFalse);
      },
    );

    test(
      'cuentas y casos sobreviven a nueva instancia; sesión no persiste',
      () async {
        final LocalCureandoGateway first = _gateway(store);
        await first.registerStudent(
          alias: 'LunaLocal',
          pin: '123456',
          inviteCode: 'DEMO-NORTE',
        );
        final ReportReceipt receipt = await first.submitReport(
          _input('persist-1'),
        );
        final LocalCureandoGateway second = _gateway(
          EncryptedLocalStore(file: file, vault: vault),
        );
        await second.initialize();
        expect(await second.currentAccount(), isNull);
        await second.signIn(alias: 'LunaLocal', pin: '123456');
        expect(
          (await second.listMyReports()).single.reportId,
          receipt.reportId,
        );
        expect(
          (await second.getReportDetail(receipt.reportId)).body,
          contains('ficticio'),
        );
      },
    );
  });

  group('Cuentas, permisos y seguimiento', () {
    late MemoryTestStore store;
    late LocalCureandoGateway gateway;
    setUp(() {
      store = MemoryTestStore();
      gateway = _gateway(store);
    });

    test(
      'alias y PIN válidos, salt único y respaldo sin credenciales en claro',
      () async {
        final AccountRegistration first = await gateway.registerStudent(
          alias: 'SolAzul24',
          pin: '2468',
          inviteCode: 'DEMO-NORTE',
        );
        expect(first.backupCode, matches(r'^SETU-[A-Z2-9]{4}-[A-Z2-9]{4}$'));
        await gateway.registerStudent(
          alias: 'LunaVerde',
          pin: '2468',
          inviteCode: 'DEMO-SUR',
        );
        final Map<String, Object?> data = (await store.load())!;
        final String serialized = jsonEncode(data);
        expect(serialized, isNot(contains('"2468"')));
        expect(serialized, isNot(contains(first.backupCode)));
        final List<Object?> accounts = data['accounts']! as List<Object?>;
        final Map<String, Object?> a = accounts[0]! as Map<String, Object?>;
        final Map<String, Object?> b = accounts[1]! as Map<String, Object?>;
        expect(
          (a['pin']! as Map<String, Object?>)['salt'],
          isNot((b['pin']! as Map<String, Object?>)['salt']),
        );
        await gateway.resetPin(
          alias: 'SolAzul24',
          backupCode: first.backupCode,
          newPin: '678901',
        );
        await expectLater(
          gateway.signIn(alias: 'SolAzul24', pin: '2468'),
          throwsA(_error('credentials')),
        );
        expect(
          (await gateway.signIn(alias: 'solazul24', pin: '678901')).id,
          first.account.id,
        );
        await expectLater(
          gateway.registerStudent(
            alias: 'solazul24',
            pin: '1234',
            inviteCode: 'DEMO-NORTE',
          ),
          throwsA(_error('alias')),
        );
        await expectLater(
          gateway.registerStudent(
            alias: 'Nombre Apellido',
            pin: '1234',
            inviteCode: 'DEMO-NORTE',
          ),
          throwsA(_error('validation')),
        );
        await expectLater(
          gateway.registerStudent(
            alias: 'AliasPrueba',
            pin: '12ab',
            inviteCode: 'DEMO-NORTE',
          ),
          throwsA(_error('validation')),
        );
      },
    );

    test('bloqueo de PIN tras cinco fallos persiste al reiniciar', () async {
      DateTime now = DateTime.utc(2026, 11, 5);
      gateway = _gateway(store, clock: () => now);
      await gateway.registerStudent(
        alias: 'AliasSeguro',
        pin: '1234',
        inviteCode: 'DEMO-NORTE',
      );
      for (int i = 0; i < 5; i++) {
        await expectLater(
          gateway.signIn(alias: 'AliasSeguro', pin: '0000'),
          throwsA(_error('credentials')),
        );
      }
      final LocalCureandoGateway restarted = _gateway(store, clock: () => now);
      await expectLater(
        restarted.signIn(alias: 'AliasSeguro', pin: '1234'),
        throwsA(_error('locked')),
      );
      now = now.add(const Duration(minutes: 6));
      expect(
        (await restarted.signIn(alias: 'AliasSeguro', pin: '1234')).alias,
        'AliasSeguro',
      );
    });

    test(
      'aislamiento entre cuentas del mismo centro y de otro centro',
      () async {
        await gateway.registerStudent(
          alias: 'CuentaNorte1',
          pin: '1234',
          inviteCode: 'DEMO-NORTE',
        );
        final ReportReceipt receipt = await gateway.submitReport(
          _input('norte-1'),
        );
        for (final (String, String) fixture in <(String, String)>[
          ('CuentaNorte2', 'DEMO-NORTE'),
          ('CuentaSur', 'DEMO-SUR'),
        ]) {
          await gateway.registerStudent(
            alias: fixture.$1,
            pin: '1234',
            inviteCode: fixture.$2,
          );
          expect(await gateway.listMyReports(), isEmpty);
          await expectLater(
            gateway.getReportDetail(receipt.reportId),
            throwsA(_error('access')),
          );
          await expectLater(
            gateway.sendStudentMessage(
              SendMessageInput(
                reportId: receipt.reportId,
                clientRequestId: 'cross',
                body: 'Ficticio',
              ),
            ),
            throwsA(_error('access')),
          );
        }
        await gateway.signOut();
        await expectLater(gateway.listMyReports(), throwsA(_error('access')));
      },
    );

    test(
      'ruta alternativa y elección de interlocutor se aplican en datos',
      () async {
        await gateway.registerStudent(
          alias: 'TestigoRuta',
          pin: '1234',
          inviteCode: 'DEMO-NORTE',
        );
        final ReportReceipt conflict = await gateway.submitReport(
          _input('conflict', conflict: true),
        );
        final ReportReceipt psychology = await gateway.submitReport(
          _input('psych', recipient: OrientationRole.psychology),
        );
        final StaffCureandoGateway cce = gateway.staffForLocalTesting(
          'north-cce',
        );
        final StaffCureandoGateway psych = gateway.staffForLocalTesting(
          'north-psychology',
        );
        final StaffCureandoGateway supervisor = gateway.staffForLocalTesting(
          'north-supervisor',
        );
        expect(await cce.listReports(), isEmpty);
        expect(
          (await psych.listReports()).single.reportId,
          psychology.reportId,
        );
        for (final StaffCureandoGateway denied in <StaffCureandoGateway>[
          cce,
          psych,
          gateway.staffForLocalTesting('south-supervisor'),
        ]) {
          await expectLater(
            denied.getReportDetail(conflict.reportId),
            throwsA(_error('access')),
          );
          await expectLater(
            denied.sendReply(
              SendMessageInput(
                reportId: conflict.reportId,
                clientRequestId: 'blocked',
                body: 'No debe guardarse',
              ),
            ),
            throwsA(_error('access')),
          );
          await expectLater(
            denied.addInternalNote(
              SendMessageInput(
                reportId: conflict.reportId,
                clientRequestId: 'blocked-note',
                body: 'No debe guardarse',
              ),
            ),
            throwsA(_error('access')),
          );
        }
        expect(
          (await supervisor.getReportDetail(
            conflict.reportId,
          )).studentView.recipient,
          OrientationRole.supervisor,
        );
      },
    );

    test(
      'notas internas separadas y respuesta nueva se marca al abrir',
      () async {
        await gateway.registerStudent(
          alias: 'TestigoNotas',
          pin: '1234',
          inviteCode: 'DEMO-NORTE',
        );
        final ReportReceipt receipt = await gateway.submitReport(
          _input('notes'),
        );
        final StaffCureandoGateway staff = gateway.staffForLocalTesting(
          'north-cce',
        );
        await staff.addInternalNote(
          SendMessageInput(
            reportId: receipt.reportId,
            clientRequestId: 'note1',
            body: 'NOTA_INTERNA_FICTICIA',
          ),
        );
        await staff.sendReply(
          SendMessageInput(
            reportId: receipt.reportId,
            clientRequestId: 'reply1',
            body: 'Respuesta visible ficticia',
          ),
        );
        expect(
          (await gateway.listMyReports()).single.hasUnreadStaffReply,
          isTrue,
        );
        final StudentCaseDetailView student = await gateway.getReportDetail(
          receipt.reportId,
        );
        expect(student.messages.single.body, 'Respuesta visible ficticia');
        expect(
          (await gateway.listMyReports()).single.hasUnreadStaffReply,
          isFalse,
        );
        final StaffCaseDetailView staffView = await staff.getReportDetail(
          receipt.reportId,
        );
        expect(staffView.internalNotes.single.body, 'NOTA_INTERNA_FICTICIA');
        expect(
          student.messages.any(
            (VisibleMessage m) => m.body.contains('NOTA_INTERNA'),
          ),
          isFalse,
        );
        expect(student.runtimeType, StudentCaseDetailView);
      },
    );

    test(
      'operaciones concurrentes e inciertas son idempotentes tras reapertura',
      () async {
        await gateway.registerStudent(
          alias: 'TestigoReintento',
          pin: '1234',
          inviteCode: 'DEMO-NORTE',
        );
        gateway.simulatedNetwork = SimulatedNetwork.offline;
        await expectLater(
          gateway.submitReport(_input('offline')),
          throwsA(_error('offline')),
        );
        expect(await gateway.listMyReports(), isEmpty);
        gateway.simulatedNetwork = SimulatedNetwork.uncertain;
        await expectLater(
          gateway.submitReport(_input('same')),
          throwsA(_error('uncertain')),
        );
        gateway = _gateway(store);
        await gateway.signIn(alias: 'TestigoReintento', pin: '1234');
        final List<ReportReceipt> receipts =
            await Future.wait(<Future<ReportReceipt>>[
              gateway.submitReport(_input('same')),
              gateway.submitReport(_input('same')),
            ]);
        expect(receipts[0].reportId, receipts[1].reportId);
        expect(await gateway.listMyReports(), hasLength(1));
        await expectLater(
          gateway.submitReport(_input('same', body: 'Contenido diferente')),
          throwsA(_error('idempotency')),
        );
        final String id = receipts[0].reportId;
        gateway.simulatedNetwork = SimulatedNetwork.uncertain;
        await expectLater(
          gateway.sendStudentMessage(
            SendMessageInput(
              reportId: id,
              clientRequestId: 'message',
              body: 'Mensaje ficticio',
            ),
          ),
          throwsA(_error('uncertain')),
        );
        gateway.simulatedNetwork = SimulatedNetwork.connected;
        await gateway.sendStudentMessage(
          SendMessageInput(
            reportId: id,
            clientRequestId: 'message',
            body: 'Mensaje ficticio',
          ),
        );
        expect((await gateway.getReportDetail(id)).messages, hasLength(1));
      },
    );

    test(
      'ticket limita a un caso y permite solicitar seguimiento sin reabrir',
      () async {
        await gateway.registerStudent(
          alias: 'TestigoTicket',
          pin: '1234',
          inviteCode: 'DEMO-NORTE',
        );
        final ReportReceipt receipt = await gateway.submitReport(
          _input('ticket1'),
        );
        final ReportReceipt other = await gateway.submitReport(
          _input('ticket2'),
        );
        final CaseAccessCredential credential = await gateway.createCaseAccess(
          receipt.reportId,
        );
        final StaffCureandoGateway staff = gateway.staffForLocalTesting(
          'north-cce',
        );
        await staff.changeStatus(
          reportId: receipt.reportId,
          status: ReportStatus.inReview,
          reason: 'Revisión ficticia',
          clientRequestId: 'state1',
        );
        await staff.changeStatus(
          reportId: receipt.reportId,
          status: ReportStatus.closed,
          reason: 'Cierre ficticio',
          clientRequestId: 'state2',
        );
        await gateway.signOut();
        await gateway.accessCase(
          referenceCode: credential.referenceCode,
          pin: credential.pin,
        );
        await expectLater(gateway.listMyReports(), throwsA(_error('access')));
        await expectLater(
          gateway.getReportDetail(other.reportId),
          throwsA(_error('access')),
        );
        final SupportRequestView request = await gateway.requestSupport(
          reportId: receipt.reportId,
          type: SupportRequestType.followUp,
          clientRequestId: 'follow',
        );
        final SupportRequestView repeated = await gateway.requestSupport(
          reportId: receipt.reportId,
          type: SupportRequestType.followUp,
          clientRequestId: 'follow',
        );
        expect(request.id, repeated.id);
        await gateway.requestSupport(
          reportId: receipt.reportId,
          type: SupportRequestType.discreetAppointment,
          clientRequestId: 'appointment',
        );
        await gateway.requestSupport(
          reportId: receipt.reportId,
          type: SupportRequestType.externalSupport,
          clientRequestId: 'external',
        );
        final StudentCaseDetailView detail = await gateway.getReportDetail(
          receipt.reportId,
        );
        expect(detail.summary.status, ReportStatus.closed);
        expect(detail.requests, hasLength(3));
        await expectLater(
          staff.changeStatus(
            reportId: receipt.reportId,
            status: ReportStatus.accompanied,
            reason: 'Salto inválido',
            clientRequestId: 'bad-transition',
          ),
          throwsA(_error('transition')),
        );
        await gateway.signOut();
        await expectLater(
          gateway.getReportDetail(receipt.reportId),
          throwsA(_error('access')),
        );
      },
    );

    test('fallo de persistencia no publica un reporte en memoria', () async {
      final _FailingStore failing = _FailingStore();
      gateway = _gateway(failing);
      await gateway.registerStudent(
        alias: 'TestigoDisco',
        pin: '1234',
        inviteCode: 'DEMO-NORTE',
      );
      failing.fail = true;
      await expectLater(
        gateway.submitReport(_input('disk-fail')),
        throwsA(_error('storage')),
      );
      failing.fail = false;
      expect(await gateway.listMyReports(), isEmpty);
      await gateway.submitReport(_input('disk-fail'));
      expect(await gateway.listMyReports(), hasLength(1));
    });
  });
}
