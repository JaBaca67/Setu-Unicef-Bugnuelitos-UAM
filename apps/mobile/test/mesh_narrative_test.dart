import 'package:cryptography/cryptography.dart';
import 'package:cureando_mobile/shared/mesh/mesh_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

MeshMinimalAlertPayload _payload({String? narrative}) =>
    MeshMinimalAlertPayload(
      clientOperationId: 'op_mesh_narrativa_01',
      publicSchoolCode: 'AULA26',
      situationType: 'verbal_bullying',
      studentRole: 'victim',
      capabilityVerifierHash: 'a' * 64,
      declaredAt: DateTime.utc(2026, 11, 17, 10, 24),
      narrativeText: narrative,
      studentPiece: const <String, Object?>{
        'shape': 'puzzle',
        'color': 'green',
        'accessories': <String>['cap', 'glasses'],
        'displayName': 'Chispa Cósmica',
      },
    );

void main() {
  test(
    'relato y pieza viajan cifrados y solo los abre el destinatario',
    () async {
      final X25519 x25519 = X25519();
      final SimpleKeyPair staff = await x25519.newKeyPair();
      final SimpleKeyPair relayer = await x25519.newKeyPair();
      final MeshEnvelope envelope = await MeshEnvelope.seal(
        _payload(narrative: 'Me cuesta participar porque se burlan de mí.'),
        recipientPublicKeyBytes: (await staff.extractPublicKey()).bytes,
      );
      expect(envelope.toJson().toString(), isNot(contains('burlan')));
      expect(envelope.toJson().toString(), isNot(contains('Chispa')));

      final MeshMinimalAlertPayload opened = await envelope.open(
        recipientKeyPair: staff,
      );
      expect(
        opened.narrativeText,
        'Me cuesta participar porque se burlan de mí.',
      );
      expect(opened.studentPiece!['displayName'], 'Chispa Cósmica');
      expect(opened.studentPiece!['accessories'], <Object?>['cap', 'glasses']);

      await expectLater(
        envelope.open(recipientKeyPair: relayer),
        throwsA(anything),
      );
    },
  );

  test('el relato máximo con emojis cabe en el sobre de 4 KB', () async {
    final String fitted = MeshMinimalAlertPayload.fitNarrative('😢' * 1000)!;
    expect(fitted.endsWith('…'), isTrue);
    final MeshEnvelope envelope = await MeshEnvelope.seal(
      _payload(narrative: fitted),
      recipientPublicKeyBytes:
          (await (await X25519().newKeyPair()).extractPublicKey()).bytes,
    );
    expect(
      envelope.toWireBytes().length,
      lessThanOrEqualTo(MeshEnvelope.maxWireBytes),
    );
    expect(MeshMinimalAlertPayload.fitNarrative('  '), isNull);
    expect(MeshMinimalAlertPayload.fitNarrative(' Hola '), 'Hola');
  });

  test('la copia para la clave escolar simulada no lleva relato ni pieza', () {
    final MeshMinimalAlertPayload safe = _payload(
      narrative: 'x',
    ).withoutPrivateFields();
    expect(safe.narrativeText, isNull);
    expect(safe.studentPiece, isNull);
    expect(safe.toJson().containsKey('narrative_text'), isFalse);
  });
}
