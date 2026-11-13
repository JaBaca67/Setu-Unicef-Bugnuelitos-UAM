-- Migración 3: Funciones RPC transaccionales de SéTú con idempotencia y control de acceso.

-- ---------------------------------------------------------------------------
-- 1. Helper interno para códigos de referencia de caso y comparación segura
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.generate_case_reference_code()
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_bytes bytea;
  v_part1 text := '';
  v_part2 text := '';
  v_idx integer;
BEGIN
  v_bytes := pg_catalog.sha256(
    pg_catalog.convert_to(
      pg_catalog.gen_random_uuid()::text || '|' || pg_catalog.clock_timestamp()::text,
      'UTF8'
    )
  );
  FOR v_idx IN 0..3 LOOP
    v_part1 := v_part1 || pg_catalog.substr(v_alphabet, (pg_catalog.get_byte(v_bytes, v_idx) % 32) + 1, 1);
    v_part2 := v_part2 || pg_catalog.substr(v_alphabet, (pg_catalog.get_byte(v_bytes, v_idx + 4) % 32) + 1, 1);
  END LOOP;
  RETURN 'SETU-' || v_part1 || '-' || v_part2;
END;
$$;

REVOKE ALL ON FUNCTION private.generate_case_reference_code() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Normalización y validación pública del código escolar
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.normalize_school_code(p_code text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_clean text;
BEGIN
  v_clean := pg_catalog.upper(pg_catalog.btrim(COALESCE(p_code, '')));
  IF pg_catalog.char_length(v_clean) = 7 AND pg_catalog.substr(v_clean, 5, 1) = '-' THEN
    RETURN pg_catalog.substr(v_clean, 1, 4) || pg_catalog.substr(v_clean, 6, 2);
  END IF;
  RETURN v_clean;
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_public_school(p_public_code text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_normalized text;
  v_school public.institutions%ROWTYPE;
BEGIN
  v_normalized := public.normalize_school_code(p_public_code);
  IF v_normalized !~ '^[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'school_not_found_or_inactive'
      USING ERRCODE = 'P0002',
            DETAIL = 'El código del colegio debe tener 6 caracteres alfanuméricos.';
  END IF;

  SELECT *
  INTO v_school
  FROM public.institutions i
  WHERE i.public_code = v_normalized
    AND i.active = true
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'school_not_found_or_inactive'
      USING ERRCODE = 'P0002',
            DETAIL = 'No existe un centro escolar activo con ese código.';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'id', v_school.id,
    'public_code', v_school.public_code,
    'name', v_school.name,
    'municipality', v_school.municipality,
    'department', v_school.department,
    'reference_lat', v_school.reference_lat,
    'reference_lng', v_school.reference_lng,
    'radius_meters', v_school.radius_meters,
    'config_version', v_school.config_version
  );
END;
$$;

REVOKE ALL ON FUNCTION public.normalize_school_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.normalize_school_code(text) TO anon, authenticated;

REVOKE ALL ON FUNCTION public.resolve_public_school(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_public_school(text) TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Recepción transaccional e idempotente de alerta estudiantil (Online / Mesh)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_student_alert(
  p_client_operation_id text,
  p_public_school_code text,
  p_situation_type public.case_situation_type,
  p_student_role public.student_case_role,
  p_origin public.alert_origin DEFAULT 'online',
  p_involves_staff boolean DEFAULT false,
  p_declared_at timestamptz DEFAULT now(),
  p_capability_verifier_hash text DEFAULT NULL,
  p_narrative_text text DEFAULT NULL,
  p_location_text text DEFAULT '',
  p_approx_date_text text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_op_id text;
  v_school_code text;
  v_cap_hash text;
  v_narrative text;
  v_location text;
  v_approx_date text;
  v_school public.institutions%ROWTYPE;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
  v_case_id uuid;
  v_reference_code text;
  v_received_at timestamptz := pg_catalog.now();
  v_declared timestamptz;
  v_receipt jsonb;
  v_attempts integer := 0;
BEGIN
  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;

  IF p_origin NOT IN ('online'::public.alert_origin, 'mesh'::public.alert_origin) THEN
    RAISE EXCEPTION 'invalid_student_alert_origin'
      USING ERRCODE = '22023';
  END IF;

  IF p_student_role IS NULL THEN
    RAISE EXCEPTION 'student_role_required'
      USING ERRCODE = '22023';
  END IF;

  v_cap_hash := pg_catalog.lower(pg_catalog.btrim(COALESCE(p_capability_verifier_hash, '')));
  IF v_cap_hash !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'invalid_capability_verifier_hash'
      USING ERRCODE = '22023';
  END IF;

  v_narrative := NULLIF(pg_catalog.btrim(COALESCE(p_narrative_text, '')), '');
  v_location := pg_catalog.btrim(COALESCE(p_location_text, ''));
  v_approx_date := pg_catalog.btrim(COALESCE(p_approx_date_text, ''));

  IF p_origin = 'mesh'::public.alert_origin AND (
    v_narrative IS NOT NULL
    OR pg_catalog.char_length(v_location) > 0
    OR pg_catalog.char_length(v_approx_date) > 0
  ) THEN
    RAISE EXCEPTION 'mesh_origin_cannot_carry_narrative'
      USING ERRCODE = '22023';
  END IF;

  IF v_narrative IS NOT NULL AND pg_catalog.char_length(v_narrative) > 4000 THEN
    RAISE EXCEPTION 'narrative_too_long'
      USING ERRCODE = '22023';
  END IF;

  IF pg_catalog.char_length(v_location) > 500 OR pg_catalog.char_length(v_approx_date) > 200 THEN
    RAISE EXCEPTION 'context_too_long'
      USING ERRCODE = '22023';
  END IF;

  v_school_code := public.normalize_school_code(p_public_school_code);
  SELECT *
  INTO v_school
  FROM public.institutions i
  WHERE i.public_code = v_school_code
    AND i.active = true
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'school_not_found_or_inactive'
      USING ERRCODE = 'P0002';
  END IF;

  v_scope := 'student_alert:' || v_school.id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'institution_id', v_school.id,
    'situation_type', p_situation_type,
    'student_role', p_student_role,
    'origin', p_origin,
    'involves_staff', COALESCE(p_involves_staff, false),
    'capability_verifier_hash', v_cap_hash,
    'narrative_text', v_narrative,
    'location_text', v_location,
    'approx_date_text', v_approx_date
  );
  v_fingerprint := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_canonical::text, 'UTF8')),
    'hex'
  );

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(v_scope),
    pg_catalog.hashtext(v_op_id)
  );

  SELECT *
  INTO v_existing
  FROM public.inbound_operations io
  WHERE io.operation_scope = v_scope
    AND io.client_operation_id = v_op_id;

  IF FOUND THEN
    IF v_existing.payload_fingerprint = v_fingerprint THEN
      RETURN v_existing.receipt_json;
    END IF;
    RAISE EXCEPTION 'idempotency_conflict: client_operation_id reused with different payload'
      USING ERRCODE = '23505';
  END IF;

  v_declared := COALESCE(p_declared_at, v_received_at);

  LOOP
    v_attempts := v_attempts + 1;
    v_reference_code := private.generate_case_reference_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.cases c WHERE c.reference_code = v_reference_code
    );
    IF v_attempts >= 10 THEN
      RAISE EXCEPTION 'reference_code_generation_failed'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  INSERT INTO public.cases (
    institution_id,
    reference_code,
    situation_type,
    student_role,
    origin,
    status,
    involves_staff,
    declared_at,
    received_centrally_at
  )
  VALUES (
    v_school.id,
    v_reference_code,
    p_situation_type,
    p_student_role,
    p_origin,
    'received'::public.case_status,
    COALESCE(p_involves_staff, false),
    v_declared,
    v_received_at
  )
  RETURNING id INTO v_case_id;

  INSERT INTO public.case_private_capabilities (
    case_id,
    capability_verifier_hash
  )
  VALUES (
    v_case_id,
    v_cap_hash
  );

  INSERT INTO public.case_events (
    case_id,
    institution_id,
    event_type,
    from_status,
    to_status,
    actor_role,
    reason
  )
  VALUES (
    v_case_id,
    v_school.id,
    'alert_received',
    NULL,
    'received'::public.case_status,
    CASE WHEN p_origin = 'mesh'::public.alert_origin THEN 'mesh_bridge' ELSE 'student_device' END,
    'Recepción central registrada'
  );

  IF v_narrative IS NOT NULL THEN
    INSERT INTO public.case_narratives (
      case_id,
      narrative_text,
      location_text,
      approx_date_text
    )
    VALUES (
      v_case_id,
      v_narrative,
      v_location,
      v_approx_date
    );
  END IF;

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case_id,
    'reference_code', v_reference_code,
    'institution_id', v_school.id,
    'origin', p_origin,
    'received_centrally_at', v_received_at
  );

  INSERT INTO public.inbound_operations (
    operation_scope,
    client_operation_id,
    payload_fingerprint,
    case_id,
    receipt_json
  )
  VALUES (
    v_scope,
    v_op_id,
    v_fingerprint,
    v_case_id,
    v_receipt
  );

  RETURN v_receipt;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_student_alert(
  text,
  text,
  public.case_situation_type,
  public.student_case_role,
  public.alert_origin,
  boolean,
  timestamptz,
  text,
  text,
  text,
  text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.submit_student_alert(
  text,
  text,
  public.case_situation_type,
  public.student_case_role,
  public.alert_origin,
  boolean,
  timestamptz,
  text,
  text,
  text,
  text
) TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Sesión y envío de mensajes de chat humano E08 (sin exponer estados internos)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_student_chat_session(
  p_case_id uuid,
  p_capability_token text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_token text;
  v_token_hash text;
  v_chat_available boolean;
  v_messages jsonb;
BEGIN
  v_token := pg_catalog.btrim(COALESCE(p_capability_token, ''));
  IF p_case_id IS NULL OR pg_catalog.char_length(v_token) < 32 THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  v_token_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_token, 'UTF8')),
    'hex'
  );

  SELECT c.chat_available_notice
  INTO v_chat_available
  FROM public.cases c
  JOIN public.case_private_capabilities cpc
    ON cpc.case_id = c.id
  WHERE c.id = p_case_id
    AND cpc.capability_verifier_hash = v_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', m.id,
        'sender_role', m.sender_role,
        'body', m.body,
        'created_at', m.created_at
      )
      ORDER BY m.created_at ASC
    ),
    '[]'::jsonb
  )
  INTO v_messages
  FROM public.case_messages m
  WHERE m.case_id = p_case_id;

  RETURN pg_catalog.jsonb_build_object(
    'case_id', p_case_id,
    'chat_available_notice', v_chat_available,
    'messages', v_messages
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.send_student_chat_message(
  p_case_id uuid,
  p_capability_token text,
  p_client_operation_id text,
  p_body text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_token text;
  v_token_hash text;
  v_op_id text;
  v_body text;
  v_chat_available boolean;
  v_existing public.case_messages%ROWTYPE;
  v_created public.case_messages%ROWTYPE;
BEGIN
  v_token := pg_catalog.btrim(COALESCE(p_capability_token, ''));
  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  v_body := pg_catalog.btrim(COALESCE(p_body, ''));

  IF p_case_id IS NULL OR pg_catalog.char_length(v_token) < 32 THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;

  IF pg_catalog.char_length(v_body) NOT BETWEEN 1 AND 2000 THEN
    RAISE EXCEPTION 'invalid_message_body'
      USING ERRCODE = '22023';
  END IF;

  v_token_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_token, 'UTF8')),
    'hex'
  );

  SELECT c.chat_available_notice
  INTO v_chat_available
  FROM public.cases c
  JOIN public.case_private_capabilities cpc
    ON cpc.case_id = c.id
  WHERE c.id = p_case_id
    AND cpc.capability_verifier_hash = v_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  IF NOT v_chat_available THEN
    RAISE EXCEPTION 'chat_not_available'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT *
  INTO v_existing
  FROM public.case_messages m
  WHERE m.case_id = p_case_id
    AND m.sender_role = 'student'::public.case_message_sender
    AND m.client_operation_id = v_op_id;

  IF FOUND THEN
    IF v_existing.body = v_body THEN
      RETURN pg_catalog.jsonb_build_object(
        'id', v_existing.id,
        'case_id', v_existing.case_id,
        'sender_role', v_existing.sender_role,
        'body', v_existing.body,
        'created_at', v_existing.created_at
      );
    END IF;
    RAISE EXCEPTION 'idempotency_conflict: client_operation_id reused with different message'
      USING ERRCODE = '23505';
  END IF;

  INSERT INTO public.case_messages (
    case_id,
    sender_role,
    sender_user_id,
    body,
    client_operation_id
  )
  VALUES (
    p_case_id,
    'student'::public.case_message_sender,
    NULL,
    v_body,
    v_op_id
  )
  RETURNING * INTO v_created;

  RETURN pg_catalog.jsonb_build_object(
    'id', v_created.id,
    'case_id', v_created.case_id,
    'sender_role', v_created.sender_role,
    'body', v_created.body,
    'created_at', v_created.created_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_chat_session(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_chat_session(uuid, text) TO anon, authenticated;

REVOKE ALL ON FUNCTION public.send_student_chat_message(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_student_chat_message(uuid, text, text, text) TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5. Operaciones institucionales autenticadas (Dirección)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.record_teacher_notice(
  p_client_operation_id text,
  p_institution_id uuid,
  p_situation_type public.case_situation_type,
  p_involves_staff boolean DEFAULT false,
  p_declared_at timestamptz DEFAULT now()
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_op_id text;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
  v_case_id uuid;
  v_reference_code text;
  v_received_at timestamptz := pg_catalog.now();
  v_receipt jsonb;
  v_attempts integer := 0;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('school_director'::public.staff_role, p_institution_id) THEN
    RAISE EXCEPTION 'forbidden_school_director_required'
      USING ERRCODE = '42501';
  END IF;

  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;

  v_scope := 'teacher_notice:' || v_uid::text || ':' || p_institution_id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'institution_id', p_institution_id,
    'situation_type', p_situation_type,
    'involves_staff', COALESCE(p_involves_staff, false)
  );
  v_fingerprint := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_canonical::text, 'UTF8')),
    'hex'
  );

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(v_scope),
    pg_catalog.hashtext(v_op_id)
  );

  SELECT *
  INTO v_existing
  FROM public.inbound_operations io
  WHERE io.operation_scope = v_scope
    AND io.client_operation_id = v_op_id;

  IF FOUND THEN
    IF v_existing.payload_fingerprint = v_fingerprint THEN
      RETURN v_existing.receipt_json;
    END IF;
    RAISE EXCEPTION 'idempotency_conflict: client_operation_id reused with different payload'
      USING ERRCODE = '23505';
  END IF;

  LOOP
    v_attempts := v_attempts + 1;
    v_reference_code := private.generate_case_reference_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.cases c WHERE c.reference_code = v_reference_code
    );
    IF v_attempts >= 10 THEN
      RAISE EXCEPTION 'reference_code_generation_failed'
        USING ERRCODE = 'P0001';
    END IF;
  END LOOP;

  INSERT INTO public.cases (
    institution_id,
    reference_code,
    situation_type,
    student_role,
    origin,
    status,
    involves_staff,
    declared_at,
    received_centrally_at
  )
  VALUES (
    p_institution_id,
    v_reference_code,
    p_situation_type,
    NULL,
    'teacher_notice'::public.alert_origin,
    'received'::public.case_status,
    COALESCE(p_involves_staff, false),
    COALESCE(p_declared_at, v_received_at),
    v_received_at
  )
  RETURNING id INTO v_case_id;

  INSERT INTO public.case_events (
    case_id,
    institution_id,
    event_type,
    from_status,
    to_status,
    actor_user_id,
    actor_role,
    reason
  )
  VALUES (
    v_case_id,
    p_institution_id,
    'teacher_notice_recorded',
    NULL,
    'received'::public.case_status,
    v_uid,
    'school_director',
    'Aviso docente registrado por dirección'
  );

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case_id,
    'reference_code', v_reference_code,
    'institution_id', p_institution_id,
    'origin', 'teacher_notice',
    'received_centrally_at', v_received_at
  );

  INSERT INTO public.inbound_operations (
    operation_scope,
    client_operation_id,
    payload_fingerprint,
    case_id,
    receipt_json
  )
  VALUES (
    v_scope,
    v_op_id,
    v_fingerprint,
    v_case_id,
    v_receipt
  );

  RETURN v_receipt;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_school_action(
  p_client_operation_id text,
  p_case_id uuid,
  p_action_sheet_id uuid,
  p_step public.school_action_step,
  p_is_group_action boolean DEFAULT false,
  p_action_notes text DEFAULT '',
  p_proposes_closure boolean DEFAULT false,
  p_expected_concurrency_version integer DEFAULT 1
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_op_id text;
  v_notes text;
  v_case public.cases%ROWTYPE;
  v_sheet public.case_action_sheets%ROWTYPE;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
  v_action_id uuid;
  v_next_status public.case_status;
  v_next_version integer;
  v_receipt jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  v_notes := pg_catalog.btrim(COALESCE(p_action_notes, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.char_length(v_notes) NOT BETWEEN 1 AND 1500 THEN
    RAISE EXCEPTION 'invalid_action_notes'
      USING ERRCODE = '22023';
  END IF;

  SELECT *
  INTO v_case
  FROM public.cases c
  WHERE c.id = p_case_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'case_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT private.has_staff_role('school_director'::public.staff_role, v_case.institution_id) THEN
    RAISE EXCEPTION 'forbidden_school_director_required'
      USING ERRCODE = '42501';
  END IF;

  IF v_case.involves_staff THEN
    RAISE EXCEPTION 'restricted_due_to_staff_conflict'
      USING ERRCODE = '42501';
  END IF;

  v_scope := 'school_action:' || v_uid::text || ':' || p_case_id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'case_id', p_case_id,
    'action_sheet_id', p_action_sheet_id,
    'step', p_step,
    'is_group_action', COALESCE(p_is_group_action, false),
    'action_notes', v_notes,
    'proposes_closure', COALESCE(p_proposes_closure, false)
  );
  v_fingerprint := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_canonical::text, 'UTF8')),
    'hex'
  );

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(v_scope),
    pg_catalog.hashtext(v_op_id)
  );

  SELECT *
  INTO v_existing
  FROM public.inbound_operations io
  WHERE io.operation_scope = v_scope
    AND io.client_operation_id = v_op_id;

  IF FOUND THEN
    IF v_existing.payload_fingerprint = v_fingerprint THEN
      RETURN v_existing.receipt_json;
    END IF;
    RAISE EXCEPTION 'idempotency_conflict: client_operation_id reused with different payload'
      USING ERRCODE = '23505';
  END IF;

  IF v_case.concurrency_version <> p_expected_concurrency_version THEN
    RAISE EXCEPTION 'concurrency_conflict'
      USING ERRCODE = '40001';
  END IF;

  IF p_action_sheet_id IS NOT NULL THEN
    SELECT *
    INTO v_sheet
    FROM public.case_action_sheets s
    WHERE s.id = p_action_sheet_id
      AND s.case_id = v_case.id
      AND s.institution_id = v_case.institution_id;

    IF NOT FOUND OR v_sheet.omit_school_due_to_conflict THEN
      RAISE EXCEPTION 'action_sheet_not_authorized'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  IF p_step = 'notify_family_or_group'::public.school_action_step
     AND v_case.identity_reserved
     AND NOT COALESCE(p_is_group_action, false) THEN
    RAISE EXCEPTION 'family_contact_blocked_while_identity_reserved'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.school_actions (
    case_id,
    institution_id,
    action_sheet_id,
    step,
    is_group_action,
    action_notes,
    proposes_closure,
    recorded_by,
    client_operation_id
  )
  VALUES (
    v_case.id,
    v_case.institution_id,
    p_action_sheet_id,
    p_step,
    COALESCE(p_is_group_action, false),
    v_notes,
    COALESCE(p_proposes_closure, false),
    v_uid,
    v_op_id
  )
  RETURNING id INTO v_action_id;

  v_next_status := CASE
    WHEN v_case.status = 'sheet_sent'::public.case_status THEN 'school_acting'::public.case_status
    ELSE v_case.status
  END;
  v_next_version := v_case.concurrency_version + 1;

  UPDATE public.cases
  SET status = v_next_status,
      concurrency_version = v_next_version
  WHERE id = v_case.id;

  INSERT INTO public.case_events (
    case_id,
    institution_id,
    event_type,
    from_status,
    to_status,
    actor_user_id,
    actor_role,
    reason
  )
  VALUES (
    v_case.id,
    v_case.institution_id,
    'school_action_recorded',
    v_case.status,
    v_next_status,
    v_uid,
    'school_director',
    'Actuación escolar registrada (' || p_step::text || ')'
  );

  v_receipt := pg_catalog.jsonb_build_object(
    'action_id', v_action_id,
    'case_id', v_case.id,
    'status', v_next_status,
    'concurrency_version', v_next_version
  );

  INSERT INTO public.inbound_operations (
    operation_scope,
    client_operation_id,
    payload_fingerprint,
    case_id,
    receipt_json
  )
  VALUES (
    v_scope,
    v_op_id,
    v_fingerprint,
    v_case.id,
    v_receipt
  );

  RETURN v_receipt;
END;
$$;

REVOKE ALL ON FUNCTION public.record_teacher_notice(text, uuid, public.case_situation_type, boolean, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_teacher_notice(text, uuid, public.case_situation_type, boolean, timestamptz) TO authenticated;

REVOKE ALL ON FUNCTION public.record_school_action(text, uuid, uuid, public.school_action_step, boolean, text, boolean, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_school_action(text, uuid, uuid, public.school_action_step, boolean, text, boolean, integer) TO authenticated;
