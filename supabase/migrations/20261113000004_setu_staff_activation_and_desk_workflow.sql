-- Migración 4: Activación individual de personal autorizado (D1), pieza estudiantil en caso (D2),
-- y flujo completo de asignación MINED / Mesa de Escucha / valoración, ficha mínima y Realtime (D2-D4).
-- Sincronizado con las migraciones aplicadas en Supabase:
--   - 20261113173152 (setu_staff_activation_schema)
--   - 20261113173252 (setu_staff_activation_and_desk_rpcs)


-- === 20261113173152 (setu_staff_activation_schema) ===
CREATE UNIQUE INDEX IF NOT EXISTS staff_memberships_user_role_scope_uniq_idx
  ON public.staff_memberships (
    user_id,
    role,
    COALESCE(institution_id, '00000000-0000-0000-0000-000000000000'::uuid)
  );

CREATE TABLE IF NOT EXISTS public.staff_activation_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institutional_email text NOT NULL CHECK (char_length(btrim(institutional_email)) BETWEEN 5 AND 254),
  role public.staff_role NOT NULL,
  institution_id uuid REFERENCES public.institutions(id) ON DELETE RESTRICT,
  scope_label text NOT NULL CHECK (char_length(btrim(scope_label)) BETWEEN 2 AND 160),
  verifier_hash text NOT NULL UNIQUE CHECK (verifier_hash ~ '^[0-9a-f]{64}$'),
  failed_attempts integer NOT NULL DEFAULT 0 CHECK (failed_attempts >= 0),
  max_attempts integer NOT NULL DEFAULT 5 CHECK (max_attempts BETWEEN 1 AND 20),
  locked_until timestamptz,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  redeemed_at timestamptz,
  redeemed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  issued_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT staff_activation_invites_director_requires_institution
    CHECK (role <> 'school_director' OR institution_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS staff_activation_invites_email_idx
  ON public.staff_activation_invites (lower(btrim(institutional_email)));

CREATE INDEX IF NOT EXISTS staff_activation_invites_institution_id_idx
  ON public.staff_activation_invites (institution_id);

CREATE INDEX IF NOT EXISTS staff_activation_invites_redeemed_by_idx
  ON public.staff_activation_invites (redeemed_by);

CREATE INDEX IF NOT EXISTS staff_activation_invites_issued_by_idx
  ON public.staff_activation_invites (issued_by);

REVOKE ALL ON TABLE public.staff_activation_invites FROM PUBLIC, anon, authenticated;

ALTER TABLE public.staff_activation_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_activation_invites FORCE ROW LEVEL SECURITY;

CREATE POLICY staff_activation_invites_deny_all
  ON public.staff_activation_invites
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

ALTER TABLE public.cases
  ADD COLUMN IF NOT EXISTS student_piece jsonb
  CHECK (student_piece IS NULL OR jsonb_typeof(student_piece) = 'object');

-- === 20261113173252 (setu_staff_activation_and_desk_rpcs) ===
CREATE OR REPLACE FUNCTION public.submit_student_alert(
  p_client_operation_id text,
  p_public_school_code text,
  p_situation_type public.case_situation_type,
  p_student_role public.student_case_role,
  p_origin public.alert_origin,
  p_involves_staff boolean,
  p_declared_at timestamptz,
  p_capability_verifier_hash text,
  p_narrative_text text,
  p_location_text text,
  p_approx_date_text text,
  p_student_piece jsonb
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

  IF p_student_piece IS NOT NULL AND pg_catalog.jsonb_typeof(p_student_piece) <> 'object' THEN
    RAISE EXCEPTION 'invalid_student_piece'
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
    'approx_date_text', v_approx_date,
    'student_piece', p_student_piece
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
    student_piece,
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
    p_student_piece,
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
    'received_centrally_at', v_received_at,
    'student_piece', p_student_piece
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
  text,
  jsonb
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
  text,
  jsonb
) TO anon, authenticated;

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
  v_student_piece jsonb;
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

  SELECT c.chat_available_notice, c.student_piece
  INTO v_chat_available, v_student_piece
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
    'student_piece', v_student_piece,
    'messages', v_messages
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_chat_session(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_chat_session(uuid, text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.normalize_activation_code(p_code text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT pg_catalog.regexp_replace(
    pg_catalog.upper(pg_catalog.btrim(COALESCE(p_code, ''))),
    '[\s-]+',
    '',
    'g'
  );
$$;

REVOKE ALL ON FUNCTION public.normalize_activation_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.normalize_activation_code(text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.preview_staff_activation_code(
  p_activation_code text,
  p_institutional_email text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_norm_code text;
  v_code_hash text;
  v_email text;
  v_invite public.staff_activation_invites%ROWTYPE;
  v_email_invite public.staff_activation_invites%ROWTYPE;
  v_school public.institutions%ROWTYPE;
  v_next_attempts integer;
  v_locked_until timestamptz;
BEGIN
  v_norm_code := public.normalize_activation_code(p_activation_code);
  IF pg_catalog.char_length(v_norm_code) < 6 THEN
    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'invalid_activation_code'
    );
  END IF;

  v_code_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_norm_code, 'UTF8')),
    'hex'
  );
  v_email := NULLIF(pg_catalog.lower(pg_catalog.btrim(COALESCE(p_institutional_email, ''))), '');

  IF v_email IS NOT NULL THEN
    PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('staff_invite_email:' || v_email));
  END IF;

  SELECT *
  INTO v_invite
  FROM public.staff_activation_invites i
  WHERE i.verifier_hash = v_code_hash
  FOR UPDATE;

  IF NOT FOUND OR (v_email IS NOT NULL AND pg_catalog.lower(pg_catalog.btrim(v_invite.institutional_email)) <> v_email) THEN
    IF v_email IS NOT NULL THEN
      SELECT *
      INTO v_email_invite
      FROM public.staff_activation_invites i
      WHERE pg_catalog.lower(pg_catalog.btrim(i.institutional_email)) = v_email
        AND i.revoked_at IS NULL
        AND i.redeemed_at IS NULL
        AND i.expires_at > pg_catalog.now()
      ORDER BY i.created_at DESC
      LIMIT 1
      FOR UPDATE;

      IF FOUND THEN
        IF v_email_invite.locked_until IS NOT NULL AND v_email_invite.locked_until > pg_catalog.now() THEN
          RETURN pg_catalog.jsonb_build_object(
            'ok', false,
            'error', 'activation_rate_limited',
            'locked_until', v_email_invite.locked_until
          );
        END IF;

        v_next_attempts := v_email_invite.failed_attempts + 1;
        v_locked_until := CASE
          WHEN v_next_attempts >= v_email_invite.max_attempts
            THEN pg_catalog.now() + interval '15 minutes'
          ELSE NULL
        END;

        UPDATE public.staff_activation_invites
        SET failed_attempts = v_next_attempts,
            locked_until = v_locked_until
        WHERE id = v_email_invite.id;

        RETURN pg_catalog.jsonb_build_object(
          'ok', false,
          'error', CASE WHEN v_locked_until IS NOT NULL THEN 'activation_rate_limited' ELSE 'invalid_activation_code' END,
          'remaining_attempts', GREATEST(v_email_invite.max_attempts - v_next_attempts, 0),
          'locked_until', v_locked_until
        );
      END IF;
    END IF;

    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'invalid_activation_code'
    );
  END IF;

  IF v_invite.revoked_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_revoked');
  END IF;

  IF v_invite.redeemed_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_already_used');
  END IF;

  IF v_invite.expires_at <= pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_expired');
  END IF;

  IF v_invite.locked_until IS NOT NULL AND v_invite.locked_until > pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'activation_rate_limited',
      'locked_until', v_invite.locked_until
    );
  END IF;

  IF v_invite.institution_id IS NOT NULL THEN
    SELECT *
    INTO v_school
    FROM public.institutions inst
    WHERE inst.id = v_invite.institution_id;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'invite_id', v_invite.id,
    'role', v_invite.role,
    'institution_id', v_invite.institution_id,
    'institution_public_code', v_school.public_code,
    'institution_name', v_school.name,
    'scope_label', v_invite.scope_label,
    'expires_at', v_invite.expires_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.preview_staff_activation_code(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.preview_staff_activation_code(text, text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.redeem_staff_activation_code(p_activation_code text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_user_email text;
  v_email_confirmed timestamptz;
  v_norm_code text;
  v_code_hash text;
  v_invite public.staff_activation_invites%ROWTYPE;
  v_active_invite public.staff_activation_invites%ROWTYPE;
  v_other_invite public.staff_activation_invites%ROWTYPE;
  v_next_attempts integer;
  v_locked_until timestamptz;
  v_membership_id uuid;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT pg_catalog.lower(pg_catalog.btrim(u.email)), u.email_confirmed_at
  INTO v_user_email, v_email_confirmed
  FROM auth.users u
  WHERE u.id = v_uid;

  IF v_user_email IS NULL OR v_email_confirmed IS NULL THEN
    RAISE EXCEPTION 'email_not_verified'
      USING ERRCODE = '42501';
  END IF;

  v_norm_code := public.normalize_activation_code(p_activation_code);
  IF pg_catalog.char_length(v_norm_code) < 6 THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'invalid_activation_code');
  END IF;

  v_code_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_norm_code, 'UTF8')),
    'hex'
  );

  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('staff_invite_email:' || v_user_email));

  SELECT *
  INTO v_invite
  FROM public.staff_activation_invites i
  WHERE pg_catalog.lower(pg_catalog.btrim(i.institutional_email)) = v_user_email
    AND i.verifier_hash = v_code_hash
  FOR UPDATE;

  IF NOT FOUND THEN
    SELECT *
    INTO v_active_invite
    FROM public.staff_activation_invites i
    WHERE pg_catalog.lower(pg_catalog.btrim(i.institutional_email)) = v_user_email
      AND i.revoked_at IS NULL
      AND i.redeemed_at IS NULL
      AND i.expires_at > pg_catalog.now()
    ORDER BY i.created_at DESC
    LIMIT 1
    FOR UPDATE;

    IF FOUND THEN
      IF v_active_invite.locked_until IS NOT NULL AND v_active_invite.locked_until > pg_catalog.now() THEN
        RETURN pg_catalog.jsonb_build_object(
          'ok', false,
          'error', 'activation_rate_limited',
          'locked_until', v_active_invite.locked_until
        );
      END IF;

      v_next_attempts := v_active_invite.failed_attempts + 1;
      v_locked_until := CASE
        WHEN v_next_attempts >= v_active_invite.max_attempts
          THEN pg_catalog.now() + interval '15 minutes'
        ELSE NULL
      END;

      UPDATE public.staff_activation_invites
      SET failed_attempts = v_next_attempts,
          locked_until = v_locked_until
      WHERE id = v_active_invite.id;

      RETURN pg_catalog.jsonb_build_object(
        'ok', false,
        'error', CASE WHEN v_locked_until IS NOT NULL THEN 'activation_rate_limited' ELSE 'invalid_activation_code' END,
        'remaining_attempts', GREATEST(v_active_invite.max_attempts - v_next_attempts, 0),
        'locked_until', v_locked_until
      );
    END IF;

    SELECT *
    INTO v_other_invite
    FROM public.staff_activation_invites i
    WHERE i.verifier_hash = v_code_hash
    LIMIT 1;

    IF FOUND THEN
      RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_email_mismatch');
    END IF;

    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'invalid_activation_code');
  END IF;

  IF v_invite.revoked_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_revoked');
  END IF;

  IF v_invite.redeemed_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_already_used');
  END IF;

  IF v_invite.expires_at <= pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_expired');
  END IF;

  IF v_invite.locked_until IS NOT NULL AND v_invite.locked_until > pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'activation_rate_limited',
      'locked_until', v_invite.locked_until
    );
  END IF;

  UPDATE public.staff_activation_invites
  SET redeemed_at = pg_catalog.now(),
      redeemed_by = v_uid,
      failed_attempts = 0,
      locked_until = NULL
  WHERE id = v_invite.id
    AND redeemed_at IS NULL
    AND revoked_at IS NULL;

  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_already_used');
  END IF;

  INSERT INTO public.staff_memberships (user_id, role, institution_id, active)
  VALUES (v_uid, v_invite.role, v_invite.institution_id, true)
  ON CONFLICT DO NOTHING;

  SELECT sm.id
  INTO v_membership_id
  FROM public.staff_memberships sm
  WHERE sm.user_id = v_uid
    AND sm.role = v_invite.role
    AND sm.institution_id IS NOT DISTINCT FROM v_invite.institution_id
    AND sm.active = true
    AND sm.revoked_at IS NULL
  LIMIT 1;

  IF v_membership_id IS NULL THEN
    RAISE EXCEPTION 'membership_revoked_or_inactive'
      USING ERRCODE = '42501';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'membership_id', v_membership_id,
    'role', v_invite.role,
    'institution_id', v_invite.institution_id,
    'scope_label', v_invite.scope_label
  );
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_staff_activation_code(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.redeem_staff_activation_code(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_my_staff_memberships()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_rows jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'membership_id', sm.id,
        'role', sm.role,
        'institution_id', sm.institution_id,
        'institution_public_code', i.public_code,
        'institution_name', i.name,
        'scope_label', COALESCE(i.name, 'Ámbito central MINED / Mesa de Escucha')
      )
      ORDER BY sm.role ASC, i.name ASC NULLS FIRST
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.staff_memberships sm
  LEFT JOIN public.institutions i
    ON i.id = sm.institution_id
   AND i.active = true
  WHERE sm.user_id = v_uid
    AND sm.active = true
    AND sm.revoked_at IS NULL
    AND (sm.institution_id IS NULL OR i.id IS NOT NULL);

  RETURN v_rows;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_staff_memberships() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_staff_memberships() TO authenticated;

CREATE OR REPLACE FUNCTION public.list_assignable_counselors(p_institution_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_rows jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('mined_supervisor'::public.staff_role, p_institution_id) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'user_id', u.id,
        'email', u.email,
        'institution_id', sm.institution_id
      )
      ORDER BY u.email ASC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.staff_memberships sm
  JOIN auth.users u
    ON u.id = sm.user_id
  WHERE sm.role = 'counseling_desk'::public.staff_role
    AND sm.active = true
    AND sm.revoked_at IS NULL
    AND (
      p_institution_id IS NULL
      OR sm.institution_id IS NULL
      OR sm.institution_id = p_institution_id
    );

  RETURN v_rows;
END;
$$;

REVOKE ALL ON FUNCTION public.list_assignable_counselors(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_assignable_counselors(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.assign_case_counselor(
  p_client_operation_id text,
  p_case_id uuid,
  p_counselor_user_id uuid
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
  v_case public.cases%ROWTYPE;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
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
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
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

  IF NOT private.has_staff_role('mined_supervisor'::public.staff_role, v_case.institution_id) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = p_counselor_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
      AND (sm.institution_id IS NULL OR sm.institution_id = v_case.institution_id)
  ) THEN
    RAISE EXCEPTION 'counselor_not_authorized_for_institution'
      USING ERRCODE = '42501';
  END IF;

  v_scope := 'assign_counselor:' || v_case.id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'counselor_user_id', p_counselor_user_id
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

  v_next_status := CASE
    WHEN v_case.status = 'received'::public.case_status THEN 'in_listening'::public.case_status
    ELSE v_case.status
  END;
  v_next_version := v_case.concurrency_version + 1;

  UPDATE public.cases
  SET assigned_counselor_id = p_counselor_user_id,
      status = v_next_status,
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
    'counselor_assigned',
    v_case.status,
    v_next_status,
    v_uid,
    'mined_supervisor',
    'Tenés una alerta asignada'
  );

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'assigned_counselor_id', p_counselor_user_id,
    'status', v_next_status,
    'human_level', v_case.human_level,
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

REVOKE ALL ON FUNCTION public.assign_case_counselor(text, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assign_case_counselor(text, uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.enable_case_chat(
  p_client_operation_id text,
  p_case_id uuid,
  p_opening_message text DEFAULT NULL
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
  v_opening text;
  v_case public.cases%ROWTYPE;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
  v_next_status public.case_status;
  v_next_version integer;
  v_receipt jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_assigned_counselor(p_case_id) THEN
    RAISE EXCEPTION 'forbidden_assigned_counselor_required'
      USING ERRCODE = '42501';
  END IF;

  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;

  v_opening := NULLIF(pg_catalog.btrim(COALESCE(p_opening_message, '')), '');
  IF v_opening IS NOT NULL AND pg_catalog.char_length(v_opening) > 2000 THEN
    RAISE EXCEPTION 'invalid_message_body'
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

  v_scope := 'enable_chat:' || v_uid::text || ':' || v_case.id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'opening_message', v_opening
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

  v_next_status := CASE
    WHEN v_case.status = 'received'::public.case_status THEN 'in_listening'::public.case_status
    ELSE v_case.status
  END;
  v_next_version := v_case.concurrency_version + 1;

  UPDATE public.cases
  SET chat_available_notice = true,
      status = v_next_status,
      concurrency_version = v_next_version
  WHERE id = v_case.id;

  INSERT INTO public.case_events (
    case_id,
    institution_id,
    event_type,
    from_status,
    to_status,
    human_level,
    actor_user_id,
    actor_role,
    reason
  )
  VALUES (
    v_case.id,
    v_case.institution_id,
    'status_changed',
    v_case.status,
    v_next_status,
    v_case.human_level,
    v_uid,
    'counseling_desk',
    'Chat humano habilitado por Mesa de Escucha'
  );

  IF v_opening IS NOT NULL THEN
    INSERT INTO public.case_messages (
      case_id,
      sender_role,
      sender_user_id,
      body,
      client_operation_id
    )
    VALUES (
      v_case.id,
      'counseling_desk'::public.case_message_sender,
      v_uid,
      v_opening,
      v_op_id || ':greeting'
    )
    ON CONFLICT (case_id, sender_role, client_operation_id) DO NOTHING;
  END IF;

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'chat_available_notice', true,
    'status', v_next_status,
    'human_level', v_case.human_level,
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

REVOKE ALL ON FUNCTION public.enable_case_chat(text, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.enable_case_chat(text, uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.send_counselor_chat_message(
  p_case_id uuid,
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
  v_uid uuid;
  v_op_id text;
  v_body text;
  v_case public.cases%ROWTYPE;
  v_existing public.case_messages%ROWTYPE;
  v_created public.case_messages%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_assigned_counselor(p_case_id) THEN
    RAISE EXCEPTION 'forbidden_assigned_counselor_required'
      USING ERRCODE = '42501';
  END IF;

  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  v_body := pg_catalog.btrim(COALESCE(p_body, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.char_length(v_body) NOT BETWEEN 1 AND 2000 THEN
    RAISE EXCEPTION 'invalid_message_body'
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

  IF NOT v_case.chat_available_notice THEN
    UPDATE public.cases
    SET chat_available_notice = true,
        concurrency_version = concurrency_version + 1
    WHERE id = v_case.id;
  END IF;

  SELECT *
  INTO v_existing
  FROM public.case_messages m
  WHERE m.case_id = p_case_id
    AND m.sender_role = 'counseling_desk'::public.case_message_sender
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
    'counseling_desk'::public.case_message_sender,
    v_uid,
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

REVOKE ALL ON FUNCTION public.send_counselor_chat_message(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_counselor_chat_message(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.save_case_internal_note(
  p_case_id uuid,
  p_client_operation_id text,
  p_note_body text
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
  v_body text;
  v_existing public.case_internal_notes%ROWTYPE;
  v_created public.case_internal_notes%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_assigned_counselor(p_case_id) THEN
    RAISE EXCEPTION 'forbidden_assigned_counselor_required'
      USING ERRCODE = '42501';
  END IF;

  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  v_body := pg_catalog.btrim(COALESCE(p_note_body, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.char_length(v_body) NOT BETWEEN 1 AND 4000 THEN
    RAISE EXCEPTION 'invalid_note_body'
      USING ERRCODE = '22023';
  END IF;

  SELECT *
  INTO v_existing
  FROM public.case_internal_notes n
  WHERE n.case_id = p_case_id
    AND n.author_user_id = v_uid
    AND n.client_operation_id = v_op_id;

  IF FOUND THEN
    IF v_existing.note_body = v_body THEN
      RETURN pg_catalog.jsonb_build_object(
        'id', v_existing.id,
        'case_id', v_existing.case_id,
        'note_body', v_existing.note_body,
        'created_at', v_existing.created_at
      );
    END IF;
    RAISE EXCEPTION 'idempotency_conflict: client_operation_id reused with different note'
      USING ERRCODE = '23505';
  END IF;

  INSERT INTO public.case_internal_notes (
    case_id,
    author_user_id,
    note_body,
    client_operation_id
  )
  VALUES (
    p_case_id,
    v_uid,
    v_body,
    v_op_id
  )
  RETURNING * INTO v_created;

  RETURN pg_catalog.jsonb_build_object(
    'id', v_created.id,
    'case_id', v_created.case_id,
    'note_body', v_created.note_body,
    'created_at', v_created.created_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.save_case_internal_note(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_case_internal_note(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.assess_case_and_issue_sheet(
  p_client_operation_id text,
  p_case_id uuid,
  p_human_level smallint,
  p_trigger_urgent_referral boolean DEFAULT false,
  p_issue_sheet boolean DEFAULT false,
  p_guidance_notes text DEFAULT NULL,
  p_omit_school_due_to_conflict boolean DEFAULT false,
  p_close_case boolean DEFAULT false,
  p_closed_reason text DEFAULT NULL
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
  v_guidance text;
  v_closed_reason text;
  v_case public.cases%ROWTYPE;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
  v_next_status public.case_status;
  v_next_version integer;
  v_sheet_id uuid;
  v_sheet_version integer;
  v_omit_school boolean;
  v_urgent boolean;
  v_receipt jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_assigned_counselor(p_case_id) THEN
    RAISE EXCEPTION 'forbidden_assigned_counselor_required'
      USING ERRCODE = '42501';
  END IF;

  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;

  IF p_human_level IS NULL OR p_human_level NOT IN (1, 2, 3) THEN
    RAISE EXCEPTION 'invalid_human_level'
      USING ERRCODE = '22023';
  END IF;

  IF p_human_level = 1 AND COALESCE(p_issue_sheet, false) THEN
    RAISE EXCEPTION 'level_1_cannot_issue_school_sheet'
      USING ERRCODE = '22023';
  END IF;

  v_guidance := NULLIF(pg_catalog.btrim(COALESCE(p_guidance_notes, '')), '');
  IF COALESCE(p_issue_sheet, false) AND (v_guidance IS NULL OR pg_catalog.char_length(v_guidance) > 1500) THEN
    RAISE EXCEPTION 'invalid_guidance_notes'
      USING ERRCODE = '22023';
  END IF;

  v_closed_reason := NULLIF(pg_catalog.btrim(COALESCE(p_closed_reason, '')), '');
  IF COALESCE(p_close_case, false) THEN
    IF p_human_level <> 1 THEN
      RAISE EXCEPTION 'counselor_can_only_close_level_1_directly'
        USING ERRCODE = '42501';
    END IF;
    IF v_closed_reason IS NULL OR pg_catalog.char_length(v_closed_reason) > 500 THEN
      RAISE EXCEPTION 'closed_reason_required'
        USING ERRCODE = '22023';
    END IF;
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

  v_omit_school := v_case.involves_staff OR COALESCE(p_omit_school_due_to_conflict, false);
  v_urgent := v_case.urgent_referral_triggered OR (p_human_level = 3 AND COALESCE(p_trigger_urgent_referral, false));

  v_scope := 'assess_case:' || v_uid::text || ':' || v_case.id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'human_level', p_human_level,
    'trigger_urgent_referral', COALESCE(p_trigger_urgent_referral, false),
    'issue_sheet', COALESCE(p_issue_sheet, false),
    'guidance_notes', v_guidance,
    'omit_school_due_to_conflict', v_omit_school,
    'close_case', COALESCE(p_close_case, false),
    'closed_reason', v_closed_reason
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

  v_next_status := CASE
    WHEN COALESCE(p_close_case, false) THEN 'closed'::public.case_status
    WHEN COALESCE(p_issue_sheet, false) AND v_case.status IN ('received'::public.case_status, 'in_listening'::public.case_status)
      THEN 'sheet_sent'::public.case_status
    WHEN v_case.status = 'received'::public.case_status THEN 'in_listening'::public.case_status
    ELSE v_case.status
  END;
  v_next_version := v_case.concurrency_version + 1;

  UPDATE public.cases
  SET human_level = p_human_level,
      urgent_referral_triggered = v_urgent,
      status = v_next_status,
      closed_at = CASE WHEN v_next_status = 'closed'::public.case_status THEN pg_catalog.now() ELSE closed_at END,
      closed_reason = CASE WHEN v_next_status = 'closed'::public.case_status THEN v_closed_reason ELSE closed_reason END,
      concurrency_version = v_next_version
  WHERE id = v_case.id;

  INSERT INTO public.case_events (
    case_id,
    institution_id,
    event_type,
    from_status,
    to_status,
    human_level,
    actor_user_id,
    actor_role,
    reason
  )
  VALUES (
    v_case.id,
    v_case.institution_id,
    'level_assessed',
    v_case.status,
    v_next_status,
    p_human_level,
    v_uid,
    'counseling_desk',
    'Valoración humana registrada: Nivel ' || p_human_level::text
  );

  IF p_human_level = 3 AND COALESCE(p_trigger_urgent_referral, false) AND NOT v_case.urgent_referral_triggered THEN
    INSERT INTO public.case_events (
      case_id,
      institution_id,
      event_type,
      from_status,
      to_status,
      human_level,
      actor_user_id,
      actor_role,
      reason
    )
    VALUES (
      v_case.id,
      v_case.institution_id,
      'urgent_referral',
      v_next_status,
      v_next_status,
      3,
      v_uid,
      'counseling_desk',
      'Derivación urgente humana activada (independiente de escalamiento por demora)'
    );
  END IF;

  IF COALESCE(p_issue_sheet, false) THEN
    SELECT COALESCE(MAX(s.version), 0) + 1
    INTO v_sheet_version
    FROM public.case_action_sheets s
    WHERE s.case_id = v_case.id;

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
      v_case.id,
      v_case.institution_id,
      v_sheet_version,
      v_uid,
      p_human_level,
      v_case.situation_type,
      v_case.student_role,
      v_omit_school,
      v_guidance
    )
    RETURNING id INTO v_sheet_id;

    INSERT INTO public.case_events (
      case_id,
      institution_id,
      event_type,
      from_status,
      to_status,
      human_level,
      actor_user_id,
      actor_role,
      reason
    )
    VALUES (
      v_case.id,
      v_case.institution_id,
      'sheet_issued',
      v_case.status,
      v_next_status,
      p_human_level,
      v_uid,
      'counseling_desk',
      'Ficha mínima v' || v_sheet_version::text || ' emitida sin relato ni chat'
    );
  END IF;

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'human_level', p_human_level,
    'urgent_referral_triggered', v_urgent,
    'status', v_next_status,
    'sheet_id', v_sheet_id,
    'sheet_version', v_sheet_version,
    'omit_school_due_to_conflict', v_omit_school,
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

REVOKE ALL ON FUNCTION public.assess_case_and_issue_sheet(
  text,
  uuid,
  smallint,
  boolean,
  boolean,
  text,
  boolean,
  boolean,
  text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.assess_case_and_issue_sheet(
  text,
  uuid,
  smallint,
  boolean,
  boolean,
  text,
  boolean,
  boolean,
  text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.mined_update_case_supervision(
  p_client_operation_id text,
  p_case_id uuid,
  p_next_status public.case_status,
  p_reason text
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
  v_reason text;
  v_case public.cases%ROWTYPE;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
  v_next_version integer;
  v_receipt jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  v_op_id := pg_catalog.btrim(COALESCE(p_client_operation_id, ''));
  v_reason := pg_catalog.btrim(COALESCE(p_reason, ''));
  IF pg_catalog.char_length(v_op_id) NOT BETWEEN 8 AND 128 THEN
    RAISE EXCEPTION 'invalid_client_operation_id'
      USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.char_length(v_reason) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'supervision_reason_required'
      USING ERRCODE = '22023';
  END IF;

  IF p_next_status NOT IN (
    'escalated'::public.case_status,
    'closed'::public.case_status,
    'in_listening'::public.case_status
  ) THEN
    RAISE EXCEPTION 'invalid_mined_status_transition'
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

  IF NOT private.has_staff_role('mined_supervisor'::public.staff_role, v_case.institution_id) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  v_scope := 'mined_supervision:' || v_uid::text || ':' || v_case.id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'next_status', p_next_status,
    'reason', v_reason
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

  v_next_version := v_case.concurrency_version + 1;

  UPDATE public.cases
  SET status = p_next_status,
      closed_at = CASE WHEN p_next_status = 'closed'::public.case_status THEN pg_catalog.now() ELSE NULL END,
      closed_reason = CASE WHEN p_next_status = 'closed'::public.case_status THEN v_reason ELSE NULL END,
      concurrency_version = v_next_version
  WHERE id = v_case.id;

  INSERT INTO public.case_events (
    case_id,
    institution_id,
    event_type,
    from_status,
    to_status,
    human_level,
    actor_user_id,
    actor_role,
    reason
  )
  VALUES (
    v_case.id,
    v_case.institution_id,
    'status_changed',
    v_case.status,
    p_next_status,
    v_case.human_level,
    v_uid,
    'mined_supervisor',
    v_reason
  );

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'status', p_next_status,
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

REVOKE ALL ON FUNCTION public.mined_update_case_supervision(text, uuid, public.case_status, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mined_update_case_supervision(text, uuid, public.case_status, text) TO authenticated;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'cases'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.cases;
    END IF;
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'case_messages'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.case_messages;
    END IF;
  END IF;
END $$;
