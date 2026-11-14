import 'dart:math' as math;

import 'package:cureando_mobile/shared/remote/case_capability_crypto.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_gateway.dart';
import 'package:cureando_mobile/shared/remote/setu_remote_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseCapabilityCrypto', () {
    test(
      'genera token de 64 hex, hash SHA-256 determinístico y operationId válido',
      () async {
        final CaseCapabilityCrypto crypto = CaseCapabilityCrypto();
        final math.Random seeded = math.Random(2026);
        final CaseCapabilityPair pair1 = await crypto.generateCapabilityPair(
          random: seeded,
        );
        final String recomputed = await crypto.computeVerifierHash(
          pair1.capabilityToken,
        );

        expect(pair1.capabilityToken, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(
          pair1.capabilityVerifierHash,
          matches(RegExp(r'^[0-9a-f]{64}$')),
        );
        expect(pair1.capabilityVerifierHash, equals(recomputed));
        expect(
          pair1.capabilityVerifierHash,
          isNot(equals(pair1.capabilityToken)),
        );

        final String opId = CaseCapabilityCrypto.generateClientOperationId(
          prefix: 'alert',
          random: seeded,
        );
        expect(opId, startsWith('alert-'));
        expect(opId.length, inInclusiveRange(8, 128));
      },
    );

    test('rechaza tokens menores a 32 caracteres', () async {
      final CaseCapabilityCrypto crypto = CaseCapabilityCrypto();
      await expectLater(
        () => crypto.computeVerifierHash('corto'),
        throwsArgumentError,
      );
    });
  });

  group('SetuSupabaseConfig', () {
    test('expone URL de proyecto SéTú y llave pública sin service_role', () {
      final SetuSupabaseConfig config = SetuSupabaseConfig.fromEnvironment();
      expect(config.url, equals('https://rliiwzovgpnxhrkdkmus.supabase.co'));
      expect(config.anonKey, startsWith('sb_publishable_'));
      expect(config.anonKey.toLowerCase(), isNot(contains('service_role')));
    });
  });

  group('SetuRemoteModels', () {
    test('parsea PublicSchoolResolution y StudentAlertReceipt con pieza', () {
      final PublicSchoolResolution school =
          PublicSchoolResolution.fromJson(const <String, Object?>{
            'id': '11111111-1111-4111-8111-000000000026',
            'public_code': 'AULA26',
            'name': 'Colegio Centro América — Demo',
            'municipality': 'Managua',
            'department': 'Managua',
            'reference_lat': 12.1045,
            'reference_lng': -86.2598,
            'radius_meters': 150,
            'config_version': 1,
          });
      expect(school.publicCode, equals('AULA26'));
      expect(school.radiusMeters, equals(150));

      final StudentAlertReceipt receipt = StudentAlertReceipt.fromJson(
        const <String, Object?>{
          'case_id': 'aaaaaaaa-aaaa-4aaa-8aaa-000000000001',
          'reference_code': 'SETU-2026-0009',
          'institution_id': '11111111-1111-4111-8111-000000000026',
          'origin': 'online',
          'received_centrally_at': '2026-11-13T17:10:00Z',
          'student_piece': <String, Object?>{
            'shape': 'puzzle',
            'color': 'blue',
            'accessories': <Object?>['cap', 'glasses'],
          },
        },
      );
      expect(receipt.origin, equals(SetuAlertOrigin.online));
      expect(receipt.studentPiece?.shape, equals('puzzle'));
      expect(receipt.studentPiece?.color, equals('blue'));
      expect(
        receipt.studentPiece?.accessories,
        containsAll(<String>['cap', 'glasses']),
      );
    });

    test(
      'parsea StudentChatSessionView sin exponer estado ni nivel interno',
      () {
        final StudentChatSessionView session = StudentChatSessionView.fromJson(
          const <String, Object?>{
            'case_id': 'aaaaaaaa-aaaa-4aaa-8aaa-000000000001',
            'chat_available_notice': true,
            'student_piece': <String, Object?>{
              'displayName': 'Pulgin Azul',
              'variant': 'pulgin',
              'paletteKey': 'blue',
            },
            'messages': <Object?>[
              <String, Object?>{
                'id': 'm1',
                'sender_role': 'counseling_desk',
                'body': 'Hola, te escuchamos con calma.',
                'created_at': '2026-11-13T17:12:00Z',
              },
              <String, Object?>{
                'id': 'm2',
                'sender_role': 'student',
                'body': 'Gracias, hoy pasó en el pasillo.',
                'created_at': '2026-11-13T17:13:00Z',
              },
            ],
          },
        );
        expect(session.chatAvailableNotice, isTrue);
        expect(session.studentPiece?.displayName, equals('Pulgin Azul'));
        expect(session.messages, hasLength(2));
        expect(
          session.messages.first.senderRole,
          equals(SetuMessageSender.counselingDesk),
        );
        expect(
          session.messages.last.senderRole,
          equals(SetuMessageSender.student),
        );
      },
    );

    test('parsea preview, canje y membresías de personal autorizado', () {
      final StaffActivationPreview preview =
          StaffActivationPreview.fromJson(const <String, Object?>{
            'ok': true,
            'invite_id': 'inv-1',
            'role': 'school_director',
            'institution_id': '11111111-1111-4111-8111-000000000026',
            'institution_public_code': 'AULA26',
            'institution_name': 'Colegio Centro América — Demo',
            'scope_label': 'Colegio Centro América — Demo (Dirección)',
            'expires_at': '2026-11-27T00:00:00Z',
          });
      expect(preview.ok, isTrue);
      expect(preview.role, equals(SetuStaffRole.schoolDirector));
      expect(preview.institutionPublicCode, equals('AULA26'));

      final StaffActivationRedemption locked =
          StaffActivationRedemption.fromJson(const <String, Object?>{
            'ok': false,
            'error': 'activation_rate_limited',
            'remaining_attempts': 0,
            'locked_until': '2026-11-13T17:30:00Z',
          });
      expect(locked.ok, isFalse);
      expect(locked.error, equals('activation_rate_limited'));
      expect(locked.remainingAttempts, equals(0));
      expect(locked.lockedUntil, isNotNull);

      final StaffMembershipScope scope =
          StaffMembershipScope.fromJson(const <String, Object?>{
            'membership_id': 'mem-1',
            'role': 'mined_supervisor',
            'institution_id': null,
            'institution_public_code': null,
            'institution_name': null,
            'scope_label': 'Ámbito central MINED / Mesa de Escucha',
          });
      expect(scope.role, equals(SetuStaffRole.minedSupervisor));
      expect(scope.institutionId, isNull);
    });

    test(
      'identifica casos Sin valorar vs En conversación y aviso asignado',
      () {
        final StaffCaseSummary unassessed =
            StaffCaseSummary.fromJson(const <String, Object?>{
              'id': 'case-1',
              'institution_id': '11111111-1111-4111-8111-000000000026',
              'reference_code': 'SETU-2026-0010',
              'situation_type': 'verbal_bullying',
              'student_role': 'victim',
              'origin': 'online',
              'status': 'in_listening',
              'human_level': null,
              'involves_staff': false,
              'assigned_counselor_id': '00000000-0000-0000-0000-000000000102',
              'chat_available_notice': true,
              'urgent_referral_triggered': false,
              'concurrency_version': 2,
              'declared_at': '2026-11-13T17:00:00Z',
              'received_centrally_at': '2026-11-13T17:01:00Z',
            });
        expect(unassessed.isUnassessed, isTrue);
        expect(unassessed.isInConversation, isTrue);

        final SetuAssignmentNotice notice =
            SetuAssignmentNotice.fromCaseRow(const <String, Object?>{
              'id': 'case-1',
              'reference_code': 'SETU-2026-0010',
              'institution_id': '11111111-1111-4111-8111-000000000026',
              'assigned_counselor_id': '00000000-0000-0000-0000-000000000102',
            });
        expect(notice.headline, equals('Tenés una alerta asignada'));
      },
    );

    test('parsea ficha mínima D4 y catálogos D8 con metadatos verificados', () {
      final CaseActionSheetView sheet =
          CaseActionSheetView.fromJson(const <String, Object?>{
            'id': 'sheet-1',
            'case_id': 'case-1',
            'institution_id': '11111111-1111-4111-8111-000000000026',
            'version': 1,
            'issued_by': '00000000-0000-0000-0000-000000000102',
            'human_level': 2,
            'summary_type': 'social_bullying',
            'summary_role': 'solidarity_witness',
            'omit_school_due_to_conflict': false,
            'guidance_notes': 'Acompañar al grupo sin exponer identidad.',
            'issued_at': '2026-11-13T17:20:00Z',
          });
      expect(sheet.humanLevel, equals(2));
      expect(sheet.summaryType, equals(SetuSituationType.socialBullying));

      final EditorialResourceRecord editorial =
          EditorialResourceRecord.fromJson(const <String, Object?>{
            'id': 'ed-1',
            'version': 1,
            'topic': 'emociones',
            'format': 'guide',
            'title': 'Cómo pedir apoyo sin miedo',
            'summary': 'Guía breve para estudiantes.',
            'body_paragraphs': <Object?>['Paso 1', 'Paso 2'],
            'school_stage': 'Secundaria',
            'duration_label': '3 min',
            'source_name': 'Equipo Bugñuelitos',
            'reviewer_name': 'María Cecilia Aguilera Zamora',
            'verified_at': '2026-11-10T12:00:00Z',
            'rights_notice': 'Material educativo demo',
            'offline_packable': true,
          });
      expect(editorial.format, equals(SetuEditorialFormat.guide));
      expect(editorial.bodyParagraphs, hasLength(2));

      final HelpResourceRecord help =
          HelpResourceRecord.fromJson(const <String, Object?>{
            'id': 'help-1',
            'name': 'Línea Demo Apoyo Escolar',
            'phone_or_channel': 'Canal institucional demo',
            'territory': 'Managua, Nicaragua',
            'hours_label': 'Lunes a viernes, horario escolar',
            'source_name': 'Pendiente de validación oficial',
            'editorial_responsible': 'Equipo Bugñuelitos',
            'verified_at': '2026-11-10T12:00:00Z',
            'is_verified_for_pilot': false,
            'display_order': 1,
          });
      expect(help.territory, equals('Managua, Nicaragua'));
      expect(help.isVerifiedForPilot, isFalse);
    });

    test(
      'parsea resultado de toma, declinación e historial multi-psicólogo',
      () {
        final CaseClaimResult claimed =
            CaseClaimResult.fromJson(const <String, Object?>{
              'ok': true,
              'claimed': true,
              'already_assigned_to_you': false,
              'case_id': 'case-10',
              'assigned_counselor_id': '00000000-0000-0000-0000-000000000105',
              'status': 'in_listening',
              'human_level': null,
              'concurrency_version': 2,
            });
        expect(claimed.ok, isTrue);
        expect(claimed.claimed, isTrue);
        expect(claimed.isAlreadyTaken, isFalse);
        expect(claimed.status, equals(SetuCaseStatus.inListening));
        expect(claimed.concurrencyVersion, equals(2));

        final CaseClaimResult taken =
            CaseClaimResult.fromJson(const <String, Object?>{
              'ok': false,
              'claimed': false,
              'error': 'case_already_taken',
              'case_id': 'case-10',
              'assigned_counselor_id': '00000000-0000-0000-0000-000000000102',
            });
        expect(taken.ok, isFalse);
        expect(taken.claimed, isFalse);
        expect(taken.isAlreadyTaken, isTrue);
        expect(taken.status, isNull);

        final CaseDeclineResult declinedWithFallback =
            CaseDeclineResult.fromJson(const <String, Object?>{
              'ok': true,
              'case_id': 'case-10',
              'dispatch_status': 'declined',
              'fallback': <String, Object?>{
                'dispatch_tier': 'external_pool',
                'dispatched_count': 2,
              },
            });
        expect(declinedWithFallback.ok, isTrue);
        expect(
          declinedWithFallback.dispatchStatus,
          equals(CaseDispatchStatus.declined),
        );
        expect(
          declinedWithFallback.fallbackTier,
          equals(CaseDispatchTier.externalPool),
        );
        expect(declinedWithFallback.fallbackDispatchedCount, equals(2));

        final CaseDispatchRecord historyRecord =
            CaseDispatchRecord.fromJson(const <String, Object?>{
              'id': 'disp-1',
              'case_id': 'case-10',
              'reference_code': 'SETU-2026-0099',
              'institution_id': '11111111-1111-4111-8111-000000000026',
              'institution_name': 'Colegio Centro América',
              'situation_type': 'cyberbullying',
              'case_status': 'received',
              'assigned_counselor_id': null,
              'counselor_user_id': '00000000-0000-0000-0000-000000000105',
              'counselor_email': 'psicologia.cca@setu.test',
              'dispatch_tier': 'school_plant',
              'dispatch_status': 'pending',
              'notified_at': '2026-11-14T03:00:00Z',
              'responded_at': null,
              'decline_reason': null,
            });
        expect(historyRecord.institutionName, equals('Colegio Centro América'));
        expect(
          historyRecord.dispatchTier,
          equals(CaseDispatchTier.schoolPlant),
        );
        expect(
          historyRecord.dispatchStatus,
          equals(CaseDispatchStatus.pending),
        );
        expect(
          historyRecord.situationType,
          equals(SetuSituationType.cyberbullying),
        );

        final CaseDispatchRecord realtimeRow =
            CaseDispatchRecord.fromJson(const <String, Object?>{
              'id': 'disp-1',
              'case_id': 'case-10',
              'institution_id': '11111111-1111-4111-8111-000000000026',
              'counselor_user_id': '00000000-0000-0000-0000-000000000105',
              'dispatch_tier': 'school_plant',
              'dispatch_status': 'taken_by_other',
              'notified_at': '2026-11-14T03:00:00Z',
              'responded_at': '2026-11-14T03:01:00Z',
              'decline_reason': null,
            });
        expect(
          realtimeRow.dispatchStatus,
          equals(CaseDispatchStatus.takenByOther),
        );
        expect(realtimeRow.referenceCode, isNull);
        expect(realtimeRow.respondedAt, isNotNull);
      },
    );
  });
}
