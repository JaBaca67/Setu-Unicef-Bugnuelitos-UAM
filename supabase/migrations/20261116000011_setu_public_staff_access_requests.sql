-- Migración M7: Auto-solicitud pública de acceso para personal (excepto MINED central),
-- soporte de practicantes pendientes sin tutor previo e importación masiva CSV para MINED.

ALTER TABLE public.staff_activation_invites
  DROP CONSTRAINT IF EXISTS staff_activation_invites_practicante_requires_supervisor;

ALTER TABLE public.staff_activation_invites
  ADD CONSTRAINT staff_activation_invites_practicante_requires_supervisor
  CHECK (
    request_status IN ('pending_approval', 'rejected', 'replacement_requested')
    OR staff_tier <> 'practicante_5to'
    OR supervisor_user_id IS NOT NULL
  );

ALTER TABLE public.staff_invite_events
  DROP CONSTRAINT IF EXISTS staff_invite_events_event_type_check;

ALTER TABLE public.staff_invite_events
  ADD CONSTRAINT staff_invite_events_event_type_check
  CHECK (
    event_type IN (
      'requested',
      'approved_and_issued',
      'revoked',
      'replaced',
      'redeemed',
      'replacement_requested',
      'rejected',
      'email_sent'
    )
  );

CREATE OR REPLACE FUNCTION public.submit_staff_access_request(
  p_full_name text,
  p_institutional_email text,
  p_role public.staff_role,
  p_institution_id uuid DEFAULT NULL,
  p_staff_tier text DEFAULT 'school_plant',
  p_requester_program_label text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_full_name text;
  v_email text;
  v_tier text;
  v_inst_id uuid;
  v_school public.institutions%ROWTYPE;
  v_scope text;
  v_program text;
  v_invite_id uuid;
  v_placeholder_hash text;
BEGIN
  v_uid := (SELECT auth.uid());
  v_full_name := NULLIF(pg_catalog.btrim(COALESCE(p_full_name, '')), '');
  IF v_full_name IS NULL OR pg_catalog.char_length(v_full_name) < 3 OR pg_catalog.char_length(v_full_name) > 160 THEN
    RAISE EXCEPTION 'invalid_full_name'
      USING ERRCODE = '22023';
  END IF;

  v_email := private.assert_real_institutional_email(p_institutional_email);

  v_tier := NULLIF(pg_catalog.btrim(COALESCE(p_staff_tier, '')), '');
  IF p_role = 'mined_supervisor'::public.staff_role OR v_tier = 'mined_central' THEN
    RAISE EXCEPTION 'forbidden_mined_self_request'
      USING ERRCODE = '42501';
  END IF;

  IF p_role = 'school_director'::public.staff_role THEN
    v_tier := 'school_director';
  ELSIF p_role = 'counseling_desk'::public.staff_role THEN
    IF v_tier IS NULL OR v_tier NOT IN ('school_plant', 'external_network', 'practicante_5to') THEN
      RAISE EXCEPTION 'invalid_staff_tier'
        USING ERRCODE = '22023';
    END IF;
  ELSE
    RAISE EXCEPTION 'invalid_staff_role'
      USING ERRCODE = '22023';
  END IF;

  v_inst_id := p_institution_id;
  IF (v_tier IN ('school_director', 'school_plant')) AND v_inst_id IS NULL THEN
    RAISE EXCEPTION 'institution_required_for_role'
      USING ERRCODE = '22023';
  END IF;

  IF v_inst_id IS NOT NULL THEN
    SELECT *
    INTO v_school
    FROM public.institutions i
    WHERE i.id = v_inst_id
      AND i.active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'institution_not_found'
        USING ERRCODE = 'P0002';
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.staff_activation_invites i
    WHERE pg_catalog.lower(pg_catalog.btrim(i.institutional_email)) = v_email
      AND i.revoked_at IS NULL
      AND i.redeemed_at IS NULL
      AND i.replaced_by_invite_id IS NULL
      AND (i.request_status = 'pending_approval' OR i.expires_at > pg_catalog.now())
  ) THEN
    RAISE EXCEPTION 'duplicate_pending_staff_request'
      USING ERRCODE = '23505';
  END IF;

  v_program := NULLIF(pg_catalog.btrim(COALESCE(p_requester_program_label, '')), '');
  IF v_program IS NOT NULL AND pg_catalog.char_length(v_program) > 160 THEN
    RAISE EXCEPTION 'invalid_program_label'
      USING ERRCODE = '22023';
  END IF;

  v_scope := COALESCE(
    CASE WHEN v_inst_id IS NOT NULL THEN v_school.name ELSE NULL END,
    CASE
      WHEN v_tier = 'practicante_5to' THEN 'Practicante 5.º año · Mesa de escucha'
      ELSE 'Red externa nacional'
    END
  );
  v_placeholder_hash := pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');

  INSERT INTO public.staff_activation_invites (
    institutional_email,
    role,
    institution_id,
    scope_label,
    verifier_hash,
    expires_at,
    full_name,
    staff_tier,
    supervisor_user_id,
    request_status,
    requested_by,
    requester_program_label
  )
  VALUES (
    v_email,
    p_role,
    v_inst_id,
    v_scope,
    v_placeholder_hash,
    pg_catalog.now() + interval '14 days',
    v_full_name,
    v_tier,
    NULL,
    'pending_approval',
    v_uid,
    v_program
  )
  RETURNING id INTO v_invite_id;

  INSERT INTO public.staff_invite_events (
    invite_id,
    institution_id,
    event_type,
    actor_user_id,
    details
  )
  VALUES (
    v_invite_id,
    v_inst_id,
    'requested',
    v_uid,
    'Solicitud de acceso enviada para aprobación del MINED'
  );

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'invite_id', v_invite_id,
    'request_status', 'pending_approval',
    'full_name', v_full_name,
    'institutional_email', v_email,
    'role', p_role,
    'staff_tier', v_tier,
    'institution_id', v_inst_id,
    'scope_label', v_scope
  );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_staff_access_request(text, text, public.staff_role, uuid, text, text)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_staff_access_request(text, text, public.staff_role, uuid, text, text)
  TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.issue_staff_invites_bulk(
  p_rows jsonb,
  p_expires_in_hours integer DEFAULT 72
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_item jsonb;
  v_idx integer := 0;
  v_results jsonb := '[]'::jsonb;
  v_issued_count integer := 0;
  v_error_count integer := 0;
  v_email text;
  v_full_name text;
  v_role_raw text;
  v_role public.staff_role;
  v_tier text;
  v_school_ref text;
  v_school public.institutions%ROWTYPE;
  v_inst_id uuid;
  v_supervisor_email text;
  v_supervisor_id uuid;
  v_scope text;
  v_code text;
  v_hash text;
  v_expires_at timestamptz;
  v_invite_id uuid;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('mined_supervisor'::public.staff_role, NULL) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  IF p_rows IS NULL OR jsonb_typeof(p_rows) <> 'array' THEN
    RAISE EXCEPTION 'invalid_bulk_rows_array'
      USING ERRCODE = '22023';
  END IF;

  IF pg_catalog.jsonb_array_length(p_rows) = 0 OR pg_catalog.jsonb_array_length(p_rows) > 200 THEN
    RAISE EXCEPTION 'invalid_bulk_rows_count'
      USING ERRCODE = '22023';
  END IF;

  v_expires_at := pg_catalog.now() + pg_catalog.make_interval(hours => GREATEST(COALESCE(p_expires_in_hours, 72), 1));

  FOR v_item IN SELECT value FROM pg_catalog.jsonb_array_elements(p_rows)
  LOOP
    v_idx := v_idx + 1;
    v_email := NULL;
    v_full_name := NULL;
    v_inst_id := NULL;
    v_supervisor_id := NULL;
    BEGIN
      v_email := private.assert_real_institutional_email(v_item->>'institutional_email');
      v_full_name := NULLIF(pg_catalog.btrim(COALESCE(v_item->>'full_name', '')), '');
      IF v_full_name IS NOT NULL AND (pg_catalog.char_length(v_full_name) < 2 OR pg_catalog.char_length(v_full_name) > 160) THEN
        RAISE EXCEPTION 'invalid_full_name' USING ERRCODE = '22023';
      END IF;

      v_role_raw := pg_catalog.lower(pg_catalog.btrim(COALESCE(v_item->>'role', 'counseling_desk')));
      IF v_role_raw IN ('school_director', 'director', 'direccion', 'dirección') THEN
        v_role := 'school_director'::public.staff_role;
        v_tier := 'school_director';
      ELSIF v_role_raw IN ('mined_supervisor', 'mined') THEN
        v_role := 'mined_supervisor'::public.staff_role;
        v_tier := 'mined_central';
      ELSE
        v_role := 'counseling_desk'::public.staff_role;
        v_tier := NULLIF(pg_catalog.lower(pg_catalog.btrim(COALESCE(v_item->>'staff_tier', ''))), '');
        IF v_tier IS NULL THEN
          v_tier := 'school_plant';
        END IF;
      END IF;

      IF v_tier NOT IN ('school_plant', 'external_network', 'practicante_5to', 'mined_central', 'school_director') THEN
        RAISE EXCEPTION 'invalid_staff_tier' USING ERRCODE = '22023';
      END IF;

      v_school_ref := NULLIF(pg_catalog.btrim(COALESCE(v_item->>'school_ref', v_item->>'institution_id', '')), '');
      IF v_school_ref IS NOT NULL THEN
        SELECT *
        INTO v_school
        FROM public.institutions i
        WHERE i.active = true
          AND (
            i.id::text = v_school_ref
            OR pg_catalog.upper(pg_catalog.btrim(i.public_code)) = pg_catalog.upper(v_school_ref)
            OR pg_catalog.lower(pg_catalog.btrim(i.name)) = pg_catalog.lower(v_school_ref)
          )
        LIMIT 1;

        IF NOT FOUND THEN
          RAISE EXCEPTION 'institution_not_found' USING ERRCODE = 'P0002';
        END IF;
        v_inst_id := v_school.id;
      END IF;

      IF (v_role = 'school_director'::public.staff_role OR v_tier = 'school_plant') AND v_inst_id IS NULL THEN
        RAISE EXCEPTION 'institution_required_for_role' USING ERRCODE = '22023';
      END IF;

      IF v_tier = 'practicante_5to' THEN
        v_supervisor_email := NULLIF(pg_catalog.lower(pg_catalog.btrim(COALESCE(v_item->>'supervisor_email', ''))), '');
        IF v_supervisor_email IS NOT NULL THEN
          SELECT sm.user_id
          INTO v_supervisor_id
          FROM public.staff_memberships sm
          JOIN auth.users u ON u.id = sm.user_id
          WHERE pg_catalog.lower(u.email) = v_supervisor_email
            AND sm.role = 'counseling_desk'::public.staff_role
            AND sm.active = true
            AND sm.revoked_at IS NULL
          LIMIT 1;
        END IF;
        IF v_supervisor_id IS NULL THEN
          RAISE EXCEPTION 'practicante_requires_active_supervisor' USING ERRCODE = '22023';
        END IF;
      END IF;

      IF EXISTS (
        SELECT 1
        FROM public.staff_activation_invites i
        WHERE pg_catalog.lower(pg_catalog.btrim(i.institutional_email)) = v_email
          AND i.revoked_at IS NULL
          AND i.redeemed_at IS NULL
          AND i.replaced_by_invite_id IS NULL
          AND i.request_status = 'approved'
          AND i.expires_at > pg_catalog.now()
      ) THEN
        RAISE EXCEPTION 'duplicate_active_invite' USING ERRCODE = '23505';
      END IF;

      v_scope := COALESCE(
        CASE WHEN v_inst_id IS NOT NULL THEN v_school.name ELSE NULL END,
        CASE
          WHEN v_role = 'mined_supervisor'::public.staff_role THEN 'MINED central'
          ELSE 'Red externa nacional'
        END
      );

      v_code := private.generate_staff_activation_code();
      v_hash := pg_catalog.encode(
        pg_catalog.sha256(pg_catalog.convert_to(public.normalize_activation_code(v_code), 'UTF8')),
        'hex'
      );

      INSERT INTO public.staff_activation_invites (
        institutional_email,
        role,
        institution_id,
        scope_label,
        verifier_hash,
        expires_at,
        issued_by,
        full_name,
        staff_tier,
        supervisor_user_id,
        request_status,
        requested_by,
        approved_by,
        approved_at
      )
      VALUES (
        v_email,
        v_role,
        v_inst_id,
        v_scope,
        v_hash,
        v_expires_at,
        v_uid,
        v_full_name,
        v_tier,
        v_supervisor_id,
        'approved',
        v_uid,
        v_uid,
        pg_catalog.now()
      )
      RETURNING id INTO v_invite_id;

      INSERT INTO public.staff_invite_events (
        invite_id,
        institution_id,
        event_type,
        actor_user_id,
        details
      )
      VALUES (
        v_invite_id,
        v_inst_id,
        'approved_and_issued',
        v_uid,
        'Invitación emitida por carga masiva CSV desde MINED'
      );

      v_issued_count := v_issued_count + 1;
      v_results := v_results || pg_catalog.jsonb_build_array(
        pg_catalog.jsonb_build_object(
          'index', v_idx,
          'ok', true,
          'invite_id', v_invite_id,
          'institutional_email', v_email,
          'full_name', v_full_name,
          'role', v_role,
          'staff_tier', v_tier,
          'institution_id', v_inst_id,
          'scope_label', v_scope,
          'activation_code', v_code,
          'expires_at', v_expires_at
        )
      );
    EXCEPTION WHEN OTHERS THEN
      v_error_count := v_error_count + 1;
      v_results := v_results || pg_catalog.jsonb_build_array(
        pg_catalog.jsonb_build_object(
          'index', v_idx,
          'ok', false,
          'institutional_email', COALESCE(v_email, COALESCE(v_item->>'institutional_email', '')),
          'full_name', COALESCE(v_full_name, COALESCE(v_item->>'full_name', '')),
          'error', SQLERRM
        )
      );
    END;
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'issued_count', v_issued_count,
    'error_count', v_error_count,
    'results', v_results
  );
END;
$$;

REVOKE ALL ON FUNCTION public.issue_staff_invites_bulk(jsonb, integer)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.issue_staff_invites_bulk(jsonb, integer)
  TO authenticated;
