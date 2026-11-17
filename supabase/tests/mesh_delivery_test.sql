-- Ejecutar SOLO sobre una BD LOCAL desechable con migraciones y seed cargados.
-- Ejemplo local: psql <conexion-local> -v ON_ERROR_STOP=1 -f supabase/tests/mesh_delivery_test.sql
-- No se ejecutó contra Supabase remoto. Todo es ficticio y se revierte.
BEGIN;
INSERT INTO auth.users(id, email) VALUES
  ('30000000-0000-4000-8000-000000000001', 'mesa-a@example.invalid'),
  ('30000000-0000-4000-8000-000000000002', 'mesa-b@example.invalid');
INSERT INTO public.staff_memberships(user_id, role, institution_id)
SELECT '30000000-0000-4000-8000-000000000001'::uuid, 'counseling_desk', id
FROM public.institutions WHERE public_code = 'AULA24';
INSERT INTO public.staff_memberships(user_id, role, institution_id)
SELECT '30000000-0000-4000-8000-000000000002'::uuid, 'counseling_desk', id
FROM public.institutions WHERE public_code = 'AULA25';

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '30000000-0000-4000-8000-000000000001', true);
SELECT public.register_mesh_recipient('AULA24', encode(decode(repeat('01', 32), 'hex'), 'base64'));
-- Repetir publicación es idempotente. No permite publicar para el centro B.
SELECT public.register_mesh_recipient('AULA24', encode(decode(repeat('01', 32), 'hex'), 'base64'));
DO $$ BEGIN
  BEGIN
    PERFORM public.register_mesh_recipient('AULA25', encode(decode(repeat('02', 32), 'hex'), 'base64'));
    RAISE EXCEPTION 'FAIL: se permitió registrar clave de otro colegio';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM 1 FROM public.mesh_envelope_custody;
    RAISE EXCEPTION 'FAIL: acceso directo a custodia';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT set_config('request.jwt.claim.sub', '30000000-0000-4000-8000-000000000002', true);
SELECT public.register_mesh_recipient('AULA25', encode(decode(repeat('02', 32), 'hex'), 'base64'));

SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);
DO $$ DECLARE v_keys jsonb; v_envelope jsonb; BEGIN
  v_keys := public.list_mesh_recipient_public_keys('AULA24', false);
  IF NOT v_keys @> jsonb_build_array(encode(decode(repeat('01', 32), 'hex'), 'base64'))
    OR v_keys @> jsonb_build_array(encode(decode(repeat('02', 32), 'hex'), 'base64')) THEN
    RAISE EXCEPTION 'FAIL: directorio cruza colegios';
  END IF;
  IF public.list_mesh_recipient_public_keys('AULA24', true)
    @> jsonb_build_array(encode(decode(repeat('01', 32), 'hex'), 'base64')) THEN
    RAISE EXCEPTION 'FAIL: conflicto enviado a planta';
  END IF;
  v_envelope := jsonb_build_object('kind','envelope','v',1,'ttl',4,'id',repeat('a',32),
    'recipient_key',encode(sha256(decode(repeat('01',32),'hex')),'hex'),
    'epk',encode(decode(repeat('03',32),'hex'),'base64'),
    'n',encode(decode(repeat('04',12),'hex'),'base64'),
    'm',encode(decode(repeat('05',16),'hex'),'base64'),'c','AQID');
  PERFORM public.relay_mesh_envelope(v_envelope);
  PERFORM public.relay_mesh_envelope(v_envelope || '{"ttl":2}'::jsonb);
  BEGIN
    PERFORM public.relay_mesh_envelope(v_envelope || '{"c":"BAUG"}'::jsonb);
    RAISE EXCEPTION 'FAIL: mismo paquete alterado aceptado';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN
    PERFORM public.relay_mesh_envelope(v_envelope || '{"narrative":"no permitido"}'::jsonb);
    RAISE EXCEPTION 'FAIL: campo privado en sobre público aceptado';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
END $$;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '30000000-0000-4000-8000-000000000002', true);
DO $$ BEGIN
  IF jsonb_array_length(public.list_my_mesh_envelopes()) <> 0 THEN
    RAISE EXCEPTION 'FAIL: centro B consulta custodia A';
  END IF;
END $$;
SELECT set_config('request.jwt.claim.sub', '30000000-0000-4000-8000-000000000001', true);
DO $$ BEGIN
  IF jsonb_array_length(public.list_my_mesh_envelopes()) <> 1 THEN
    RAISE EXCEPTION 'FAIL: falta sobre o se duplicó por TTL';
  END IF;
END $$;

SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);
DO $$ DECLARE v_first jsonb; v_again jsonb; BEGIN
  v_first := public.submit_student_alert('mesh_demo_operation_001','AULA24','social_bullying','victim',
    'mesh',false,'2026-11-16T12:00:00Z',repeat('a',64),NULL,'','',NULL);
  v_again := public.submit_student_alert('mesh_demo_operation_001','AULA24','social_bullying','victim',
    'online',false,'2026-11-16T12:00:00Z',repeat('a',64),'Relato ficticio solo local','','',NULL);
  IF v_first->>'case_id' IS DISTINCT FROM v_again->>'case_id' THEN
    RAISE EXCEPTION 'FAIL: mesh y online duplicaron caso';
  END IF;
  BEGIN
    PERFORM public.submit_student_alert('mesh_demo_operation_001','AULA24','physical_bullying','victim',
      'mesh',false,'2026-11-16T12:00:00Z',repeat('a',64),NULL,'','',NULL);
    RAISE EXCEPTION 'FAIL: operación alterada aceptada';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN
    PERFORM public.submit_student_alert('mesh_demo_operation_001','AULA24','social_bullying','victim',
      'mesh',false,'2026-11-16T12:00:00Z',repeat('b',64),NULL,'','',NULL);
    RAISE EXCEPTION 'FAIL: otro verificador obtuvo recibo';
  EXCEPTION WHEN unique_violation THEN NULL; END;
END $$;

RESET ROLE;
DO $$ DECLARE v_case uuid; BEGIN
  SELECT id INTO STRICT v_case FROM public.cases WHERE client_operation_id = 'mesh_demo_operation_001';
  IF NOT EXISTS (SELECT 1 FROM public.case_counselor_dispatches
    WHERE case_id = v_case AND counselor_user_id = '30000000-0000-4000-8000-000000000001')
    OR EXISTS (SELECT 1 FROM public.case_counselor_dispatches
    WHERE case_id = v_case AND counselor_user_id = '30000000-0000-4000-8000-000000000002') THEN
    RAISE EXCEPTION 'FAIL: despacho incorrecto del colegio';
  END IF;
END $$;
ROLLBACK;
