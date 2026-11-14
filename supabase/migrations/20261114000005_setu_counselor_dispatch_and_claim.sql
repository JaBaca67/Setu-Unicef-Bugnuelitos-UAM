-- Applied remotely as 20261114032358 (setu_counselor_dispatch_and_claim)
CREATE TABLE IF NOT EXISTS public.case_counselor_dispatches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE RESTRICT,
  counselor_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dispatch_tier text NOT NULL CHECK (dispatch_tier IN ('school_plant', 'external_pool')),
  dispatch_status text NOT NULL DEFAULT 'pending' CHECK (
    dispatch_status IN ('pending', 'claimed', 'taken_by_other', 'declined')
  ),
  notified_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,
  decline_reason text CHECK (decline_reason IS NULL OR char_length(btrim(decline_reason)) <= 500),
  UNIQUE (case_id, counselor_user_id)
);

CREATE INDEX IF NOT EXISTS case_counselor_dispatches_counselor_status_idx
  ON public.case_counselor_dispatches (counselor_user_id, dispatch_status, notified_at DESC);

CREATE INDEX IF NOT EXISTS case_counselor_dispatches_case_status_idx
  ON public.case_counselor_dispatches (case_id, dispatch_status);

CREATE INDEX IF NOT EXISTS case_counselor_dispatches_institution_idx
  ON public.case_counselor_dispatches (institution_id, notified_at DESC);

REVOKE ALL ON TABLE public.case_counselor_dispatches FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.case_counselor_dispatches TO authenticated;

ALTER TABLE public.case_counselor_dispatches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_counselor_dispatches FORCE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'case_counselor_dispatches'
      AND policyname = 'case_counselor_dispatches_select_mined'
  ) THEN
    CREATE POLICY case_counselor_dispatches_select_mined
      ON public.case_counselor_dispatches
      FOR SELECT
      TO authenticated
      USING (
        (SELECT private.has_staff_role('mined_supervisor'::public.staff_role, institution_id))
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'case_counselor_dispatches'
      AND policyname = 'case_counselor_dispatches_select_counselor'
  ) THEN
    CREATE POLICY case_counselor_dispatches_select_counselor
      ON public.case_counselor_dispatches
      FOR SELECT
      TO authenticated
      USING (
        counselor_user_id = (SELECT auth.uid())
        AND (SELECT private.has_staff_role('counseling_desk'::public.staff_role, institution_id))
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'cases'
      AND policyname = 'cases_select_dispatched_counselor'
  ) THEN
    CREATE POLICY cases_select_dispatched_counselor
      ON public.cases
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1
          FROM public.case_counselor_dispatches d
          WHERE d.case_id = cases.id
            AND d.counselor_user_id = (SELECT auth.uid())
            AND d.dispatch_status IN ('pending', 'claimed')
        )
        AND (SELECT private.has_staff_role('counseling_desk'::public.staff_role, institution_id))
      );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION private.dispatch_case_to_counselors(
  p_case_id uuid,
  p_institution_id uuid,
  p_involves_staff boolean,
  p_force_external boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_has_plant boolean := false;
  v_tier text;
  v_count integer := 0;
BEGIN
  IF NOT COALESCE(p_involves_staff, false) AND NOT COALESCE(p_force_external, false) THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.staff_memberships sm
      WHERE sm.role = 'counseling_desk'::public.staff_role
        AND sm.institution_id = p_institution_id
        AND sm.active = true
        AND sm.revoked_at IS NULL
    )
    INTO v_has_plant;
  END IF;

  IF v_has_plant THEN
    v_tier := 'school_plant';
    INSERT INTO public.case_counselor_dispatches (
      case_id,
      institution_id,
      counselor_user_id,
      dispatch_tier,
      dispatch_status
    )
    SELECT DISTINCT
      p_case_id,
      p_institution_id,
      sm.user_id,
      v_tier,
      'pending'
    FROM public.staff_memberships sm
    WHERE sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id = p_institution_id
      AND sm.active = true
      AND sm.revoked_at IS NULL
    ON CONFLICT (case_id, counselor_user_id) DO NOTHING;
  ELSE
    v_tier := 'external_pool';
    INSERT INTO public.case_counselor_dispatches (
      case_id,
      institution_id,
      counselor_user_id,
      dispatch_tier,
      dispatch_status
    )
    SELECT DISTINCT
      p_case_id,
      p_institution_id,
      sm.user_id,
      v_tier,
      'pending'
    FROM public.staff_memberships sm
    WHERE sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id IS NULL
      AND sm.active = true
      AND sm.revoked_at IS NULL
    ON CONFLICT (case_id, counselor_user_id) DO NOTHING;
  END IF;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  RETURN pg_catalog.jsonb_build_object(
    'dispatch_tier', v_tier,
    'dispatched_count', v_count
  );
END;
$$;

REVOKE ALL ON FUNCTION private.dispatch_case_to_counselors(uuid, uuid, boolean, boolean) FROM PUBLIC, anon, authenticated;

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
  v_dispatch jsonb;
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

  v_dispatch := private.dispatch_case_to_counselors(
    v_case_id,
    v_school.id,
    COALESCE(p_involves_staff, false),
    false
  );

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case_id,
    'reference_code', v_reference_code,
    'institution_id', v_school.id,
    'origin', p_origin,
    'received_centrally_at', v_received_at,
    'student_piece', p_student_piece,
    'dispatch', v_dispatch
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

CREATE OR REPLACE FUNCTION public.claim_case_counselor(
  p_client_operation_id text,
  p_case_id uuid
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
  v_tier text := 'external_pool';
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

  IF p_case_id IS NULL THEN
    RAISE EXCEPTION 'case_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  -- Serializar clicks simultáneos sobre el mismo caso para garantizar un único ganador.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('claim_case'),
    pg_catalog.hashtext(p_case_id::text)
  );

  SELECT *
  INTO v_case
  FROM public.cases c
  WHERE c.id = p_case_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'case_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT private.has_staff_role('counseling_desk'::public.staff_role, v_case.institution_id) THEN
    RAISE EXCEPTION 'forbidden_counseling_desk_required'
      USING ERRCODE = '42501';
  END IF;

  IF v_case.involves_staff AND NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_uid
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id IS NULL
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'forbidden_staff_conflict_requires_external_counselor'
      USING ERRCODE = '42501';
  END IF;

  v_scope := 'claim_case:' || v_uid::text || ':' || v_case.id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'counselor_user_id', v_uid
  );
  v_fingerprint := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_canonical::text, 'UTF8')),
    'hex'
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

  IF v_case.assigned_counselor_id IS NOT NULL THEN
    IF v_case.assigned_counselor_id = v_uid THEN
      UPDATE public.case_counselor_dispatches
      SET dispatch_status = 'claimed',
          responded_at = COALESCE(responded_at, pg_catalog.now())
      WHERE case_id = v_case.id
        AND counselor_user_id = v_uid;

      v_receipt := pg_catalog.jsonb_build_object(
        'ok', true,
        'claimed', true,
        'already_assigned_to_you', true,
        'case_id', v_case.id,
        'assigned_counselor_id', v_uid,
        'status', v_case.status,
        'human_level', v_case.human_level,
        'concurrency_version', v_case.concurrency_version
      );
    ELSE
      UPDATE public.case_counselor_dispatches
      SET dispatch_status = 'taken_by_other',
          responded_at = COALESCE(responded_at, pg_catalog.now())
      WHERE case_id = v_case.id
        AND counselor_user_id = v_uid
        AND dispatch_status = 'pending';

      v_receipt := pg_catalog.jsonb_build_object(
        'ok', false,
        'claimed', false,
        'error', 'case_already_taken',
        'case_id', v_case.id,
        'assigned_counselor_id', v_case.assigned_counselor_id
      );
    END IF;

    INSERT INTO public.inbound_operations (
      operation_scope, client_operation_id, payload_fingerprint, case_id, receipt_json
    )
    VALUES (
      v_scope, v_op_id, v_fingerprint, v_case.id, v_receipt
    );

    RETURN v_receipt;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_uid
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id = v_case.institution_id
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    v_tier := 'school_plant';
  END IF;

  v_next_status := CASE
    WHEN v_case.status = 'received'::public.case_status THEN 'in_listening'::public.case_status
    ELSE v_case.status
  END;
  v_next_version := v_case.concurrency_version + 1;

  UPDATE public.cases
  SET assigned_counselor_id = v_uid,
      status = v_next_status,
      concurrency_version = v_next_version
  WHERE id = v_case.id;

  INSERT INTO public.case_counselor_dispatches (
    case_id,
    institution_id,
    counselor_user_id,
    dispatch_tier,
    dispatch_status,
    notified_at,
    responded_at
  )
  VALUES (
    v_case.id,
    v_case.institution_id,
    v_uid,
    v_tier,
    'claimed',
    pg_catalog.now(),
    pg_catalog.now()
  )
  ON CONFLICT (case_id, counselor_user_id) DO UPDATE
  SET dispatch_status = 'claimed',
      responded_at = pg_catalog.now(),
      decline_reason = NULL;

  UPDATE public.case_counselor_dispatches
  SET dispatch_status = 'taken_by_other',
      responded_at = pg_catalog.now()
  WHERE case_id = v_case.id
    AND counselor_user_id <> v_uid
    AND dispatch_status = 'pending';

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
    'counseling_desk',
    'Caso tomado por profesional de Mesa de Escucha'
  );

  v_receipt := pg_catalog.jsonb_build_object(
    'ok', true,
    'claimed', true,
    'already_assigned_to_you', false,
    'case_id', v_case.id,
    'assigned_counselor_id', v_uid,
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

REVOKE ALL ON FUNCTION public.claim_case_counselor(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_case_counselor(text, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.decline_case_dispatch(
  p_client_operation_id text,
  p_case_id uuid,
  p_reason text DEFAULT NULL
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
  v_pending_left integer := 0;
  v_fallback jsonb := NULL;
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

  v_reason := NULLIF(pg_catalog.btrim(COALESCE(p_reason, '')), '');
  IF v_reason IS NOT NULL AND pg_catalog.char_length(v_reason) > 500 THEN
    RAISE EXCEPTION 'invalid_decline_reason'
      USING ERRCODE = '22023';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('claim_case'),
    pg_catalog.hashtext(p_case_id::text)
  );

  SELECT *
  INTO v_case
  FROM public.cases c
  WHERE c.id = p_case_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'case_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT private.has_staff_role('counseling_desk'::public.staff_role, v_case.institution_id) THEN
    RAISE EXCEPTION 'forbidden_counseling_desk_required'
      USING ERRCODE = '42501';
  END IF;

  v_scope := 'decline_dispatch:' || v_uid::text || ':' || v_case.id::text;
  v_canonical := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'counselor_user_id', v_uid,
    'reason', v_reason
  );
  v_fingerprint := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_canonical::text, 'UTF8')),
    'hex'
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

  UPDATE public.case_counselor_dispatches
  SET dispatch_status = 'declined',
      responded_at = pg_catalog.now(),
      decline_reason = v_reason
  WHERE case_id = v_case.id
    AND counselor_user_id = v_uid
    AND dispatch_status = 'pending';

  IF v_case.assigned_counselor_id IS NULL THEN
    SELECT COUNT(*)::integer
    INTO v_pending_left
    FROM public.case_counselor_dispatches d
    WHERE d.case_id = v_case.id
      AND d.dispatch_status = 'pending';

    IF v_pending_left = 0 THEN
      v_fallback := private.dispatch_case_to_counselors(
        v_case.id,
        v_case.institution_id,
        v_case.involves_staff,
        true
      );
      IF COALESCE((v_fallback ->> 'dispatched_count')::integer, 0) > 0 THEN
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
          'status_changed',
          v_case.status,
          v_case.status,
          v_uid,
          'counseling_desk',
          'Derivado a psicólogos externos tras declinación de planta'
        );
      END IF;
    END IF;
  END IF;

  v_receipt := pg_catalog.jsonb_build_object(
    'ok', true,
    'case_id', v_case.id,
    'dispatch_status', 'declined',
    'fallback', v_fallback
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

REVOKE ALL ON FUNCTION public.decline_case_dispatch(text, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.decline_case_dispatch(text, uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.list_case_dispatch_history(
  p_institution_id uuid DEFAULT NULL,
  p_case_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_is_mined boolean := false;
  v_is_counselor boolean := false;
  v_case_institution_id uuid;
  v_rows jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  IF p_case_id IS NOT NULL THEN
    SELECT c.institution_id
    INTO v_case_institution_id
    FROM public.cases c
    WHERE c.id = p_case_id;
  END IF;

  v_is_mined := private.has_staff_role(
    'mined_supervisor'::public.staff_role,
    COALESCE(p_institution_id, v_case_institution_id)
  );
  v_is_counselor := private.has_staff_role(
    'counseling_desk'::public.staff_role,
    COALESCE(p_institution_id, v_case_institution_id)
  );

  IF NOT v_is_mined AND NOT v_is_counselor THEN
    RAISE EXCEPTION 'forbidden_staff_role_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', d.id,
        'case_id', d.case_id,
        'reference_code', c.reference_code,
        'institution_id', d.institution_id,
        'institution_name', i.name,
        'situation_type', c.situation_type,
        'case_status', c.status,
        'assigned_counselor_id', c.assigned_counselor_id,
        'counselor_user_id', d.counselor_user_id,
        'counselor_email', u.email,
        'dispatch_tier', d.dispatch_tier,
        'dispatch_status', d.dispatch_status,
        'notified_at', d.notified_at,
        'responded_at', d.responded_at,
        'decline_reason', d.decline_reason
      )
      ORDER BY d.notified_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.case_counselor_dispatches d
  JOIN public.cases c ON c.id = d.case_id
  JOIN public.institutions i ON i.id = d.institution_id
  JOIN auth.users u ON u.id = d.counselor_user_id
  WHERE (p_institution_id IS NULL OR d.institution_id = p_institution_id)
    AND (p_case_id IS NULL OR d.case_id = p_case_id)
    AND (v_is_mined OR d.counselor_user_id = v_uid);

  RETURN v_rows;
END;
$$;

REVOKE ALL ON FUNCTION public.list_case_dispatch_history(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_case_dispatch_history(uuid, uuid) TO authenticated;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'case_counselor_dispatches'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.case_counselor_dispatches;
    END IF;
  END IF;
END $$;

-- Applied remotely as 20261114032447 (setu_counselor_dispatch_history_and_assign_sync)
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
  v_tier text := 'external_pool';
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

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('claim_case'),
    pg_catalog.hashtext(p_case_id::text)
  );

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

  IF EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = p_counselor_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id = v_case.institution_id
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    v_tier := 'school_plant';
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

  INSERT INTO public.case_counselor_dispatches (
    case_id,
    institution_id,
    counselor_user_id,
    dispatch_tier,
    dispatch_status,
    notified_at,
    responded_at
  )
  VALUES (
    v_case.id,
    v_case.institution_id,
    p_counselor_user_id,
    v_tier,
    'claimed',
    pg_catalog.now(),
    pg_catalog.now()
  )
  ON CONFLICT (case_id, counselor_user_id) DO UPDATE
  SET dispatch_status = 'claimed',
      responded_at = pg_catalog.now(),
      decline_reason = NULL;

  UPDATE public.case_counselor_dispatches
  SET dispatch_status = 'taken_by_other',
      responded_at = pg_catalog.now()
  WHERE case_id = v_case.id
    AND counselor_user_id <> p_counselor_user_id
    AND dispatch_status IN ('pending', 'claimed');

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

CREATE OR REPLACE FUNCTION public.list_case_dispatch_history(
  p_institution_id uuid DEFAULT NULL,
  p_case_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_is_mined boolean := false;
  v_is_counselor boolean := false;
  v_case_institution_id uuid;
  v_rows jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  IF p_case_id IS NOT NULL THEN
    SELECT c.institution_id
    INTO v_case_institution_id
    FROM public.cases c
    WHERE c.id = p_case_id;
  END IF;

  v_is_mined := private.has_staff_role(
    'mined_supervisor'::public.staff_role,
    COALESCE(p_institution_id, v_case_institution_id)
  );
  v_is_counselor := private.has_staff_role(
    'counseling_desk'::public.staff_role,
    COALESCE(p_institution_id, v_case_institution_id)
  );

  IF NOT v_is_mined AND NOT v_is_counselor THEN
    RAISE EXCEPTION 'forbidden_staff_role_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', d.id,
        'case_id', d.case_id,
        'reference_code', c.reference_code,
        'institution_id', d.institution_id,
        'institution_name', i.name,
        'situation_type', c.situation_type,
        'case_status', c.status,
        'assigned_counselor_id', c.assigned_counselor_id,
        'counselor_user_id', d.counselor_user_id,
        'counselor_email', u.email,
        'dispatch_tier', d.dispatch_tier,
        'dispatch_status', d.dispatch_status,
        'notified_at', d.notified_at,
        'responded_at', d.responded_at,
        'decline_reason', d.decline_reason
      )
      ORDER BY d.notified_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.case_counselor_dispatches d
  JOIN public.cases c ON c.id = d.case_id
  JOIN public.institutions i ON i.id = d.institution_id
  JOIN auth.users u ON u.id = d.counselor_user_id
  WHERE (p_institution_id IS NULL OR d.institution_id = p_institution_id)
    AND (p_case_id IS NULL OR d.case_id = p_case_id)
    AND (
      private.has_staff_role('mined_supervisor'::public.staff_role, d.institution_id)
      OR (
        d.counselor_user_id = v_uid
        AND private.has_staff_role('counseling_desk'::public.staff_role, d.institution_id)
      )
    );

  RETURN v_rows;
END;
$$;
