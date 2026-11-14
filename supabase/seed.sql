-- Semillas 100% ficticias de desarrollo y demostración para SéTú.
-- No contiene casos reales, identidad civil, credenciales reales ni contactos validados para operación.

-- ---------------------------------------------------------------------------
-- 1. Colegios ficticios (D1)
-- ---------------------------------------------------------------------------

INSERT INTO public.institutions (
  id,
  public_code,
  name,
  municipality,
  department,
  reference_lat,
  reference_lng,
  radius_meters,
  config_version,
  active
)
VALUES
  (
    '11111111-1111-4111-8111-000000000024',
    'AULA24',
    'Colegio Público Demo Centro América — CCE',
    'Managua',
    'Managua',
    12.098062,
    -86.2641465,
    150,
    1,
    true
  ),
  (
    '11111111-1111-4111-8111-000000000025',
    'AULA25',
    'Colegio Público Demo Sur — CCE',
    'Managua',
    'Managua',
    12.082500,
    -86.251200,
    150,
    1,
    true
  ),
  (
    '11111111-1111-4111-8111-000000000026',
    'AULA26',
    'Colegio Centro América',
    'Managua',
    'Managua',
    12.098062,
    -86.2641465,
    150,
    1,
    true
  )
ON CONFLICT (public_code) DO NOTHING;

-- Códigos privados de prueba únicamente para hash de demostración:
--   AULA24 -> 'DIR-AULA24-DEMO'
--   AULA25 -> 'DIR-AULA25-DEMO'
--   AULA26 -> 'DIR-AULA26-DEMO'
INSERT INTO public.institution_access_verifiers (
  institution_id,
  verifier_hash,
  label,
  active
)
SELECT
  v.institution_id,
  v.verifier_hash,
  v.label,
  true
FROM (
  VALUES
    (
      '11111111-1111-4111-8111-000000000024'::uuid,
      encode(sha256('DIR-AULA24-DEMO'::bytea), 'hex'),
      'Código privado demo AULA24'
    ),
    (
      '11111111-1111-4111-8111-000000000025'::uuid,
      encode(sha256('DIR-AULA25-DEMO'::bytea), 'hex'),
      'Código privado demo AULA25'
    ),
    (
      '11111111-1111-4111-8111-000000000026'::uuid,
      encode(sha256('DIR-AULA26-DEMO'::bytea), 'hex'),
      'Código privado demo AULA26'
    )
) AS v(institution_id, verifier_hash, label)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.institution_access_verifiers existing
  WHERE existing.institution_id = v.institution_id
    AND existing.verifier_hash = v.verifier_hash
);

-- ---------------------------------------------------------------------------
-- 2. Usuarios ficticios de personal (auth.users) y membresías (D1)
-- ---------------------------------------------------------------------------

-- Contraseña ficticia únicamente para pruebas de demostración local/remota: 'Demo-SeTu-2026'
INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  phone_change,
  phone_change_token,
  email_change_token_current,
  email_change_confirm_status,
  reauthentication_token,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous,
  created_at,
  updated_at
)
VALUES
  (
    '00000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'mined.demo@setu.test',
    extensions.crypt('Demo-SeTu-2026', extensions.gen_salt('bf')),
    now(),
    '', '', '', '', '', '', '', 0, '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"demo_role":"mined_supervisor"}'::jsonb,
    false,
    false,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000102',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'escucha.demo@setu.test',
    extensions.crypt('Demo-SeTu-2026', extensions.gen_salt('bf')),
    now(),
    '', '', '', '', '', '', '', 0, '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"demo_role":"counseling_desk"}'::jsonb,
    false,
    false,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000103',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'psicologia.cca@setu.test',
    extensions.crypt('Demo-SeTu-2026', extensions.gen_salt('bf')),
    now(),
    '', '', '', '', '', '', '', 0, '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"demo_role":"counseling_desk","school":"AULA26"}'::jsonb,
    false,
    false,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000201',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'direccion.aula24@setu.test',
    extensions.crypt('Demo-SeTu-2026', extensions.gen_salt('bf')),
    now(),
    '', '', '', '', '', '', '', 0, '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"demo_role":"school_director","school":"AULA24"}'::jsonb,
    false,
    false,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000202',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'direccion.aula25@setu.test',
    extensions.crypt('Demo-SeTu-2026', extensions.gen_salt('bf')),
    now(),
    '', '', '', '', '', '', '', 0, '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"demo_role":"school_director","school":"AULA25"}'::jsonb,
    false,
    false,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000203',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'direccion.cca@setu.test',
    extensions.crypt('Demo-SeTu-2026', extensions.gen_salt('bf')),
    now(),
    '', '', '', '', '', '', '', 0, '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"demo_role":"school_director","school":"AULA26"}'::jsonb,
    false,
    false,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000301',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'invitada.cca@setu.test',
    extensions.crypt('Demo-SeTu-2026', extensions.gen_salt('bf')),
    now(),
    '', '', '', '', '', '', '', 0, '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"demo_role":"pending_invite","school":"AULA26"}'::jsonb,
    false,
    false,
    now(),
    now()
  )
ON CONFLICT (id) DO UPDATE
SET
  encrypted_password = COALESCE(auth.users.encrypted_password, EXCLUDED.encrypted_password),
  email_confirmed_at = COALESCE(auth.users.email_confirmed_at, EXCLUDED.email_confirmed_at),
  confirmation_token = COALESCE(auth.users.confirmation_token, ''),
  recovery_token = COALESCE(auth.users.recovery_token, ''),
  email_change_token_new = COALESCE(auth.users.email_change_token_new, ''),
  email_change = COALESCE(auth.users.email_change, ''),
  phone_change = COALESCE(auth.users.phone_change, ''),
  phone_change_token = COALESCE(auth.users.phone_change_token, ''),
  email_change_token_current = COALESCE(auth.users.email_change_token_current, ''),
  email_change_confirm_status = COALESCE(auth.users.email_change_confirm_status, 0),
  reauthentication_token = COALESCE(auth.users.reauthentication_token, '');

INSERT INTO auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT
  u.id,
  u.id,
  u.id::text,
  jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'email_verified', true,
    'phone_verified', false
  ),
  'email',
  NULL,
  now(),
  now()
FROM auth.users u
WHERE u.email LIKE '%@setu.test'
  AND NOT EXISTS (
    SELECT 1
    FROM auth.identities ai
    WHERE ai.user_id = u.id
      AND ai.provider = 'email'
  );

INSERT INTO public.staff_memberships (user_id, role, institution_id, active)
SELECT m.user_id, m.role, m.institution_id, true
FROM (
  VALUES
    ('00000000-0000-0000-0000-000000000101'::uuid, 'mined_supervisor'::public.staff_role, NULL::uuid),
    ('00000000-0000-0000-0000-000000000102'::uuid, 'counseling_desk'::public.staff_role, NULL::uuid),
    ('00000000-0000-0000-0000-000000000103'::uuid, 'counseling_desk'::public.staff_role, '11111111-1111-4111-8111-000000000026'::uuid),
    ('00000000-0000-0000-0000-000000000201'::uuid, 'school_director'::public.staff_role, '11111111-1111-4111-8111-000000000024'::uuid),
    ('00000000-0000-0000-0000-000000000202'::uuid, 'school_director'::public.staff_role, '11111111-1111-4111-8111-000000000025'::uuid),
    ('00000000-0000-0000-0000-000000000203'::uuid, 'school_director'::public.staff_role, '11111111-1111-4111-8111-000000000026'::uuid)
) AS m(user_id, role, institution_id)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.staff_memberships existing
  WHERE existing.user_id = m.user_id
    AND existing.role = m.role
    AND existing.institution_id IS NOT DISTINCT FROM m.institution_id
);

-- Invitaciones individuales ficticias de activación (solo SHA-256 del código normalizado):
--   'CCA-DIR-2026'  -> invitada.cca@setu.test (activa, Dirección en Colegio Centro América — Demo)
--   'CCA-MESA-2026' -> practicante.cca@setu.test (activa, Mesa de Escucha en Colegio Centro América — Demo)
--   'CCA-EXP-2026'  -> expirada.cca@setu.test (vencida para pruebas)
--   'CCA-REV-2026'  -> revocada.cca@setu.test (revocada para pruebas)
INSERT INTO public.staff_activation_invites (
  institutional_email,
  role,
  institution_id,
  scope_label,
  verifier_hash,
  expires_at,
  revoked_at,
  issued_by
)
VALUES
  (
    'invitada.cca@setu.test',
    'school_director',
    '11111111-1111-4111-8111-000000000026',
    'Colegio Centro América (Dirección)',
    encode(sha256(convert_to(public.normalize_activation_code('CCA-DIR-2026'), 'UTF8')), 'hex'),
    now() + interval '14 days',
    NULL,
    '00000000-0000-0000-0000-000000000101'
  ),
  (
    'practicante.cca@setu.test',
    'counseling_desk',
    '11111111-1111-4111-8111-000000000026',
    'Colegio Centro América (Mesa de Escucha)',
    encode(sha256(convert_to(public.normalize_activation_code('CCA-MESA-2026'), 'UTF8')), 'hex'),
    now() + interval '14 days',
    NULL,
    '00000000-0000-0000-0000-000000000101'
  ),
  (
    'expirada.cca@setu.test',
    'school_director',
    '11111111-1111-4111-8111-000000000026',
    'Colegio Centro América (Vencida)',
    encode(sha256(convert_to(public.normalize_activation_code('CCA-EXP-2026'), 'UTF8')), 'hex'),
    now() - interval '1 day',
    NULL,
    '00000000-0000-0000-0000-000000000101'
  ),
  (
    'revocada.cca@setu.test',
    'school_director',
    '11111111-1111-4111-8111-000000000026',
    'Colegio Centro América (Revocada)',
    encode(sha256(convert_to(public.normalize_activation_code('CCA-REV-2026'), 'UTF8')), 'hex'),
    now() + interval '14 days',
    now() - interval '1 hour',
    '00000000-0000-0000-0000-000000000101'
  )
ON CONFLICT (verifier_hash) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Catálogo público D8 (Información ADR 0009 y líneas de ayuda)
-- ---------------------------------------------------------------------------

INSERT INTO public.editorial_resources (
  id,
  version,
  topic,
  format,
  title,
  summary,
  body_paragraphs,
  school_stage,
  duration_label,
  source_name,
  reviewer_name,
  verified_at,
  rights_notice,
  accessible_alternative,
  offline_packable,
  published
)
VALUES
  (
    'emociones',
    1,
    'Emociones',
    'guide',
    'Entendé tus emociones',
    'Qué son las emociones y cómo ponerles nombre.',
    '["Las emociones son señales del cuerpo y de la mente. Todas son válidas: nos avisan que algo nos importa.", "Ponerle nombre a lo que sentís —alegría, tristeza, enojo, miedo, sorpresa o calma— ayuda a que se sienta menos grande.", "Cuando una emoción pesa mucho, podés respirar despacio, contarle a alguien de confianza o pedir apoyo desde esta app."]'::jsonb,
    '3.º a 11.º grado',
    '3 min',
    'Equipo SéTú (muestra académica)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Material propio de demostración académica UAM - UNICEF 2026.',
    'Lectura completa disponible en texto sin conexión.',
    true,
    true
  ),
  (
    'convivencia',
    1,
    'Convivencia',
    'video',
    'Convivencia escolar',
    'Cómo construir un aula donde todas las personas se respeten.',
    '["Convivir bien no es no tener conflictos: es resolverlos sin humillar ni excluir a nadie.", "Si ves que molestan a alguien, acompañarle o avisar a una persona adulta de confianza también es ayudar. A eso le llamamos ser Testigo Solidario.", "Pedir apoyo no es acusar: es cuidar de vos y de tu grupo."]'::jsonb,
    '3.º a 11.º grado',
    '2 min',
    'Equipo SéTú (muestra académica)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Material propio de demostración académica UAM - UNICEF 2026.',
    'Resumen textual accesible mientras no haya video empaquetado.',
    true,
    true
  ),
  (
    'acoso-escolar',
    1,
    'Acoso escolar',
    'article',
    'Cuando las bromas dejan de ser bromas',
    'Señales para distinguir un conflicto pasajero del acoso escolar repetido.',
    '["No tenés que acostumbrarte a que te empujen, te insulten, te dejen fuera del grupo o compartan burlas sobre vos en redes.", "El acoso ocurre cuando el daño se repite y busca hacer sentir menos o aislar a una persona.", "Contarlo a tiempo permite que personas adultas capacitadas acompañen sin exponerte."]'::jsonb,
    '3.º a 11.º grado',
    '4 min',
    'Equipo SéTú (muestra académica)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Material propio de demostración académica UAM - UNICEF 2026.',
    'Artículo breve en español sencillo con lectura fuera de línea.',
    true,
    true
  ),
  (
    'pedir-apoyo',
    1,
    'Pedir apoyo',
    'testimony',
    'Hablar primero también cuesta, y ayuda',
    'Cómo dar el primer paso cuando no sabés con qué palabras empezar.',
    '["Muchas veces da miedo pensar que nadie va a creer lo que pasa o que la situación va a empeorar si alguien se entera.", "En SéTú podés empezar eligiendo solo el tipo de situación, sin tener que escribir todo desde el inicio.", "Si querés conversar, una persona real del equipo de escucha te responde cuando esté conectada."]'::jsonb,
    '3.º a 11.º grado',
    '3 min',
    'Equipo SéTú (testimonio editorial de muestra)',
    'Revisión clínica pendiente para piloto',
    '2026-11-12',
    'Testimonio editorial ficticio; no proviene de un caso privado real.',
    'Texto narrado disponible sin conexión.',
    true,
    true
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.help_resources (
  id,
  name,
  phone_or_channel,
  territory,
  hours_label,
  source_name,
  editorial_responsible,
  verified_at,
  is_verified_for_pilot,
  display_order,
  published
)
VALUES
  (
    'mifan-133',
    'Línea 133 · MIFAN (orientación y protección a la niñez)',
    '133',
    'Nicaragua',
    'Horario y cobertura por confirmar antes del piloto',
    'Referencia de documentos del equipo (pendiente de verificación institucional)',
    'Equipo Bugñuelitos · Validación editorial pendiente',
    '2026-11-12',
    false,
    1,
    true
  ),
  (
    'policia-118',
    'Línea 118 · Policía Nacional (emergencias)',
    '118',
    'Nicaragua',
    'Atención de emergencias (verificar alcance territorial antes del piloto)',
    'Referencia de documentos del equipo (pendiente de verificación institucional)',
    'Equipo Bugñuelitos · Validación editorial pendiente',
    '2026-11-12',
    false,
    2,
    true
  )
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4. Casos ficticios de demostración para verificar D2, D3, D4 y RLS
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_receipt_a24 jsonb;
  v_receipt_a25 jsonb;
  v_receipt_a26 jsonb;
  v_receipt_unassessed jsonb;
  v_receipt_conflict jsonb;
  v_case_a24 uuid;
  v_case_unassessed uuid;
  v_case_a24_conflict uuid;
  v_counselor_id constant uuid := '00000000-0000-0000-0000-000000000102';
BEGIN
  v_receipt_a24 := public.submit_student_alert(
    p_client_operation_id => 'seed-op-aula24-demo-0001',
    p_public_school_code => 'AULA24',
    p_situation_type => 'verbal_bullying',
    p_student_role => 'victim',
    p_origin => 'online',
    p_involves_staff => false,
    p_declared_at => now() - interval '2 hours',
    p_capability_verifier_hash => encode(sha256('demo-capability-token-aula24-00000000000000000000000000000001'::bytea), 'hex'),
    p_narrative_text => 'Relato ficticio de demostración en AULA24 para validar que Dirección y MINED no leen D3.',
    p_location_text => 'Patio central (dato ficticio)',
    p_approx_date_text => 'Esta semana (dato ficticio)'
  );
  v_case_a24 := (v_receipt_a24 ->> 'case_id')::uuid;

  UPDATE public.cases
  SET assigned_counselor_id = v_counselor_id,
      status = 'sheet_sent',
      human_level = 2,
      chat_available_notice = true,
      concurrency_version = 2
  WHERE id = v_case_a24
    AND assigned_counselor_id IS NULL;

  INSERT INTO public.case_messages (
    case_id,
    sender_role,
    sender_user_id,
    body,
    client_operation_id
  )
  VALUES (
    v_case_a24,
    'counseling_desk',
    v_counselor_id,
    'Hola, gracias por escribir. Este es un mensaje ficticio de la Mesa de Escucha para pruebas de E08.',
    'seed-msg-counselor-0001'
  )
  ON CONFLICT (case_id, sender_role, client_operation_id) DO NOTHING;

  INSERT INTO public.case_internal_notes (
    case_id,
    author_user_id,
    note_body,
    client_operation_id
  )
  VALUES (
    v_case_a24,
    v_counselor_id,
    'Nota clínica interna ficticia: nunca debe exponerse al estudiante, Dirección ni MINED.',
    'seed-note-counselor-0001'
  )
  ON CONFLICT (case_id, author_user_id, client_operation_id) DO NOTHING;

  INSERT INTO public.case_action_sheets (
    case_id,
    institution_id,
    version,
    issued_by,
    human_level,
    summary_type,
    summary_role,
    omit_school_due_to_conflict,
    guidance_notes
  )
  VALUES (
    v_case_a24,
    '11111111-1111-4111-8111-000000000024',
    1,
    v_counselor_id,
    2,
    'verbal_bullying',
    'victim',
    false,
    'Ficha mínima ficticia nivel 2: activar protocolo de convivencia escolar sin exponer relato ni identidad.'
  )
  ON CONFLICT (case_id, version) DO NOTHING;

  v_receipt_a25 := public.submit_student_alert(
    p_client_operation_id => 'seed-op-aula25-demo-0001',
    p_public_school_code => 'AULA25',
    p_situation_type => 'cyberbullying',
    p_student_role => 'solidarity_witness',
    p_origin => 'mesh',
    p_involves_staff => false,
    p_declared_at => now() - interval '1 hour',
    p_capability_verifier_hash => encode(sha256('demo-capability-token-aula25-00000000000000000000000000000002'::bytea), 'hex'),
    p_narrative_text => NULL,
    p_location_text => '',
    p_approx_date_text => ''
  );

  v_receipt_conflict := public.submit_student_alert(
    p_client_operation_id => 'seed-op-aula24-conflict-0001',
    p_public_school_code => 'AULA24',
    p_situation_type => 'social_bullying',
    p_student_role => 'victim',
    p_origin => 'online',
    p_involves_staff => true,
    p_declared_at => now() - interval '30 minutes',
    p_capability_verifier_hash => encode(sha256('demo-capability-token-conflict-0000000000000000000000000003'::bytea), 'hex'),
    p_narrative_text => 'Caso ficticio con conflicto institucional en AULA24; Dirección no debe verlo por RLS.',
    p_location_text => 'Aula ficticia',
    p_approx_date_text => 'Hoy'
  );
  v_case_a24_conflict := (v_receipt_conflict ->> 'case_id')::uuid;

  UPDATE public.cases
  SET assigned_counselor_id = v_counselor_id,
      status = 'sheet_sent',
      human_level = 2
  WHERE id = v_case_a24_conflict
    AND assigned_counselor_id IS NULL;

  INSERT INTO public.case_action_sheets (
    case_id,
    institution_id,
    version,
    issued_by,
    human_level,
    summary_type,
    summary_role,
    omit_school_due_to_conflict,
    guidance_notes
  )
  VALUES (
    v_case_a24_conflict,
    '11111111-1111-4111-8111-000000000024',
    1,
    v_counselor_id,
    2,
    'social_bullying',
    'victim',
    true,
    'Ficha ficticia retenida para supervisión MINED por conflicto institucional.'
  )
  ON CONFLICT (case_id, version) DO NOTHING;

  -- Caso ficticio pendiente de asignación en Colegio Centro América — Demo (AULA26) con student_piece
  v_receipt_a26 := public.submit_student_alert(
    'seed-op-aula26-demo-0001',
    'AULA26',
    'verbal_bullying'::public.case_situation_type,
    'victim'::public.student_case_role,
    'online'::public.alert_origin,
    false,
    now() - interval '20 minutes',
    encode(sha256('demo-capability-token-aula26-00000000000000000000000000000004'::bytea), 'hex'),
    'Relato ficticio en Colegio Centro América — Demo para asignación por MINED y conversación inicial.',
    'Pasillo de secundaria (dato ficticio)',
    'Hoy por la mañana',
    '{"displayName":"Pulgin Azul","variant":"pulgin","paletteKey":"blue","accessoryKey":"star"}'::jsonb
  );

  -- Caso ficticio ya asignado a Mesa de Escucha pero todavía "Sin valorar" (human_level IS NULL)
  v_receipt_unassessed := public.submit_student_alert(
    'seed-op-aula24-unassessed-0001',
    'AULA24',
    'physical_bullying'::public.case_situation_type,
    'solidarity_witness'::public.student_case_role,
    'online'::public.alert_origin,
    false,
    now() - interval '15 minutes',
    encode(sha256('demo-capability-token-aula24-unassessed-000000000000000000000005'::bytea), 'hex'),
    'Relato ficticio asignado en AULA24 esperando escucha previa antes de valorar nivel.',
    'Cancha norte (dato ficticio)',
    'Hoy en el recreo',
    '{"displayName":"Tapudín Rosa","variant":"tapudin","paletteKey":"magenta","accessoryKey":"leaf"}'::jsonb
  );
  v_case_unassessed := (v_receipt_unassessed ->> 'case_id')::uuid;

  UPDATE public.cases
  SET assigned_counselor_id = v_counselor_id,
      status = 'in_listening',
      human_level = NULL,
      chat_available_notice = false,
      concurrency_version = 2
  WHERE id = v_case_unassessed
    AND assigned_counselor_id IS NULL;

  INSERT INTO public.case_counselor_dispatches (
    case_id,
    institution_id,
    counselor_user_id,
    dispatch_tier,
    dispatch_status,
    notified_at,
    responded_at
  )
  SELECT
    c.id,
    c.institution_id,
    sr.user_id,
    CASE
      WHEN sr.institution_id = c.institution_id THEN 'school_plant'
      ELSE 'external_pool'
    END,
    CASE
      WHEN c.assigned_counselor_id IS NULL THEN 'pending'
      WHEN c.assigned_counselor_id = sr.user_id THEN 'claimed'
      ELSE 'taken_by_other'
    END,
    c.created_at,
    CASE
      WHEN c.assigned_counselor_id IS NOT NULL THEN now()
      ELSE NULL
    END
  FROM public.cases c
  JOIN public.staff_roles sr
    ON sr.role = 'counseling_desk'
   AND sr.is_active = true
   AND (
     (sr.institution_id = c.institution_id AND NOT c.involves_staff)
     OR (sr.institution_id IS NULL AND (
       c.involves_staff
       OR NOT EXISTS (
         SELECT 1
         FROM public.staff_roles sp
         WHERE sp.role = 'counseling_desk'
           AND sp.is_active = true
           AND sp.institution_id = c.institution_id
       )
     ))
   )
  ON CONFLICT (case_id, counselor_user_id) DO NOTHING;
END $$;
