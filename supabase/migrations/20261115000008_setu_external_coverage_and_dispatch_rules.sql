-- Migración M6 / Bloque B: Cobertura de Red externa por colegio, asignaciones externas,
-- vencimiento de apoyo temporal, recuperación de declinadas y aviso de supervisión a practicantes.

ALTER TABLE public.institutions
  ADD COLUMN IF NOT EXISTS mined_external_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS external_support_mode text NOT NULL DEFAULT 'disabled' CHECK (
    external_support_mode IN ('disabled', 'enabled', 'temporary_until')
  ),
  ADD COLUMN IF NOT EXISTS external_support_until timestamptz,
  ADD COLUMN IF NOT EXISTS external_support_updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS external_support_updated_at timestamptz NOT NULL DEFAULT pg_catalog.now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.institutions'::regclass
      AND conname = 'institutions_temp_external_requires_until'
  ) THEN
    ALTER TABLE public.institutions
      ADD CONSTRAINT institutions_temp_external_requires_until
      CHECK (external_support_mode <> 'temporary_until' OR external_support_until IS NOT NULL);
  END IF;
END $$;

ALTER TABLE public.case_counselor_dispatches
  ADD COLUMN IF NOT EXISTS withdrawn_reason text CHECK (
    withdrawn_reason IS NULL OR char_length(btrim(withdrawn_reason)) <= 120
  );

CREATE TABLE IF NOT EXISTS public.external_counselor_school_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  counselor_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  active boolean NOT NULL DEFAULT true,
  assigned_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  UNIQUE (counselor_user_id, institution_id)
);

CREATE INDEX IF NOT EXISTS idx_ext_assignments_school_active
  ON public.external_counselor_school_assignments (institution_id, counselor_user_id)
  WHERE active = true AND revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_ext_assignments_counselor_active
  ON public.external_counselor_school_assignments (counselor_user_id, institution_id)
  WHERE active = true AND revoked_at IS NULL;

ALTER TABLE public.external_counselor_school_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_counselor_school_assignments FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.external_counselor_school_assignments FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.external_counselor_school_assignments TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'external_counselor_school_assignments' AND policyname = 'ext_assignments_select_mined'
  ) THEN
    CREATE POLICY ext_assignments_select_mined
      ON public.external_counselor_school_assignments
      FOR SELECT
      TO authenticated
      USING ((SELECT private.has_staff_role('mined_supervisor'::public.staff_role, NULL)));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'external_counselor_school_assignments' AND policyname = 'ext_assignments_select_director'
  ) THEN
    CREATE POLICY ext_assignments_select_director
      ON public.external_counselor_school_assignments
      FOR SELECT
      TO authenticated
      USING ((SELECT private.has_staff_role('school_director'::public.staff_role, institution_id)));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'external_counselor_school_assignments' AND policyname = 'ext_assignments_select_own'
  ) THEN
    CREATE POLICY ext_assignments_select_own
      ON public.external_counselor_school_assignments
      FOR SELECT
      TO authenticated
      USING (counselor_user_id = (SELECT auth.uid()));
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.practicante_supervisor_notices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  practicante_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  supervisor_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  human_level smallint NOT NULL CHECK (human_level IN (1, 2, 3)),
  reason text NOT NULL CHECK (char_length(btrim(reason)) BETWEEN 2 AND 500),
  acknowledged_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now()
);

CREATE INDEX IF NOT EXISTS idx_practicante_notices_supervisor
  ON public.practicante_supervisor_notices (supervisor_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_practicante_notices_case
  ON public.practicante_supervisor_notices (case_id, created_at DESC);

ALTER TABLE public.practicante_supervisor_notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practicante_supervisor_notices FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.practicante_supervisor_notices FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.practicante_supervisor_notices TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'practicante_supervisor_notices' AND policyname = 'practicante_notices_select_supervisor'
  ) THEN
    CREATE POLICY practicante_notices_select_supervisor
      ON public.practicante_supervisor_notices
      FOR SELECT
      TO authenticated
      USING (
        supervisor_user_id = (SELECT auth.uid())
        OR practicante_user_id = (SELECT auth.uid())
        OR (SELECT private.has_staff_role('mined_supervisor'::public.staff_role, NULL))
      );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION private.is_school_external_coverage_active(p_institution_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.institutions i
    WHERE i.id = p_institution_id
      AND i.active = true
      AND i.mined_external_enabled = true
      AND (
        i.external_support_mode = 'enabled'
        OR (
          i.external_support_mode = 'temporary_until'
          AND i.external_support_until IS NOT NULL
          AND i.external_support_until > pg_catalog.now()
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION private.is_school_external_coverage_active(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.withdraw_external_pending_dispatches(p_institution_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_count integer := 0;
BEGIN
  UPDATE public.case_counselor_dispatches d
  SET dispatch_status = 'taken_by_other',
      withdrawn_reason = 'withdrawn_coverage',
      responded_at = pg_catalog.now()
  WHERE d.institution_id = p_institution_id
    AND d.dispatch_tier = 'external_pool'
    AND d.dispatch_status = 'pending'
    AND EXISTS (
      SELECT 1
      FROM public.cases c
      WHERE c.id = d.case_id
        AND c.assigned_counselor_id IS NULL
        AND c.status <> 'closed'::public.case_status
    );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION private.withdraw_external_pending_dispatches(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.expire_temporary_external_coverages()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_expired_count integer := 0;
BEGIN
  WITH expired_schools AS (
    UPDATE public.institutions i
    SET external_support_mode = 'disabled',
        external_support_until = NULL,
        external_support_updated_at = pg_catalog.now()
    WHERE i.external_support_mode = 'temporary_until'
      AND i.external_support_until IS NOT NULL
      AND i.external_support_until <= pg_catalog.now()
    RETURNING i.id
  )
  SELECT COUNT(*)::integer
  INTO v_expired_count
  FROM expired_schools;

  UPDATE public.case_counselor_dispatches d
  SET dispatch_status = 'taken_by_other',
      withdrawn_reason = 'withdrawn_coverage',
      responded_at = pg_catalog.now()
  WHERE d.dispatch_tier = 'external_pool'
    AND d.dispatch_status = 'pending'
    AND NOT private.is_school_external_coverage_active(d.institution_id)
    AND EXISTS (
      SELECT 1
      FROM public.cases c
      WHERE c.id = d.case_id
        AND c.assigned_counselor_id IS NULL
    );

  RETURN v_expired_count;
END;
$$;

REVOKE ALL ON FUNCTION private.expire_temporary_external_coverages() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.dispatch_case_to_counselors(
  p_case_id uuid,
  p_institution_id uuid,
  p_involves_staff boolean,
  p_force_external boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_has_plant boolean := false;
  v_has_ext_coverage boolean := false;
  v_tier text := 'mined_pending_review';
  v_count integer := 0;
BEGIN
  PERFORM private.expire_temporary_external_coverages();

  IF NOT COALESCE(p_involves_staff, false) AND NOT COALESCE(p_force_external, false) THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.staff_memberships sm
      LEFT JOIN public.staff_profiles sp ON sp.user_id = sm.user_id
      WHERE sm.role = 'counseling_desk'::public.staff_role
        AND sm.institution_id = p_institution_id
        AND sm.active = true
        AND sm.revoked_at IS NULL
        AND COALESCE(sp.is_available, true) = true
        AND (
          sp.staff_tier IS DISTINCT FROM 'practicante_5to'
          OR EXISTS (
            SELECT 1
            FROM public.staff_memberships sup
            WHERE sup.user_id = sp.supervisor_user_id
              AND sup.role = 'counseling_desk'::public.staff_role
              AND sup.active = true
              AND sup.revoked_at IS NULL
              AND (sup.institution_id IS NULL OR sup.institution_id = p_institution_id)
          )
        )
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
    LEFT JOIN public.staff_profiles sp ON sp.user_id = sm.user_id
    WHERE sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id = p_institution_id
      AND sm.active = true
      AND sm.revoked_at IS NULL
      AND COALESCE(sp.is_available, true) = true
      AND (
        sp.staff_tier IS DISTINCT FROM 'practicante_5to'
        OR EXISTS (
          SELECT 1
          FROM public.staff_memberships sup
          WHERE sup.user_id = sp.supervisor_user_id
            AND sup.role = 'counseling_desk'::public.staff_role
            AND sup.active = true
            AND sup.revoked_at IS NULL
            AND (sup.institution_id IS NULL OR sup.institution_id = p_institution_id)
        )
      )
    ON CONFLICT (case_id, counselor_user_id) DO NOTHING;

    GET DIAGNOSTICS v_count = ROW_COUNT;
  ELSE
    v_has_ext_coverage := private.is_school_external_coverage_active(p_institution_id);
    IF v_has_ext_coverage THEN
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
      JOIN public.external_counselor_school_assignments a
        ON a.counselor_user_id = sm.user_id
       AND a.institution_id = p_institution_id
       AND a.active = true
       AND a.revoked_at IS NULL
      LEFT JOIN public.staff_profiles sp ON sp.user_id = sm.user_id
      WHERE sm.role = 'counseling_desk'::public.staff_role
        AND sm.institution_id IS NULL
        AND sm.active = true
        AND sm.revoked_at IS NULL
        AND COALESCE(sp.is_available, true) = true
        AND (
          sp.staff_tier IS DISTINCT FROM 'practicante_5to'
          OR EXISTS (
            SELECT 1
            FROM public.staff_memberships sup
            WHERE sup.user_id = sp.supervisor_user_id
              AND sup.role = 'counseling_desk'::public.staff_role
              AND sup.active = true
              AND sup.revoked_at IS NULL
          )
        )
      ON CONFLICT (case_id, counselor_user_id) DO NOTHING;

      GET DIAGNOSTICS v_count = ROW_COUNT;
    END IF;
  END IF;

  IF v_count = 0 THEN
    v_tier := 'mined_pending_review';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'dispatch_tier', v_tier,
    'dispatched_count', v_count
  );
END;
$$;

REVOKE ALL ON FUNCTION private.dispatch_case_to_counselors(uuid, uuid, boolean, boolean)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.claim_case_counselor(
  p_client_operation_id text,
  p_case_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
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
  v_is_plant boolean := false;
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

  PERFORM private.expire_temporary_external_coverages();

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

  -- Continuidad garantizada: si el caso ya fue tomado por este profesional,
  -- sigue autorizado aunque la cobertura temporal externa haya expirado.
  IF v_case.assigned_counselor_id IS NOT NULL THEN
    IF v_case.assigned_counselor_id = v_uid THEN
      UPDATE public.case_counselor_dispatches
      SET dispatch_status = 'claimed',
          withdrawn_reason = NULL,
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

  SELECT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_uid
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id = v_case.institution_id
      AND sm.active = true
      AND sm.revoked_at IS NULL
  )
  INTO v_is_plant;

  IF v_is_plant THEN
    v_tier := 'school_plant';
  ELSE
    v_tier := 'external_pool';
    IF NOT private.is_school_external_coverage_active(v_case.institution_id)
       OR NOT EXISTS (
         SELECT 1
         FROM public.external_counselor_school_assignments a
         WHERE a.counselor_user_id = v_uid
           AND a.institution_id = v_case.institution_id
           AND a.active = true
           AND a.revoked_at IS NULL
       ) THEN
      UPDATE public.case_counselor_dispatches
      SET dispatch_status = 'taken_by_other',
          withdrawn_reason = 'withdrawn_coverage',
          responded_at = pg_catalog.now()
      WHERE case_id = v_case.id
        AND counselor_user_id = v_uid
        AND dispatch_status = 'pending';

      v_receipt := pg_catalog.jsonb_build_object(
        'ok', false,
        'claimed', false,
        'error', 'external_coverage_inactive',
        'case_id', v_case.id
      );

      INSERT INTO public.inbound_operations (
        operation_scope, client_operation_id, payload_fingerprint, case_id, receipt_json
      )
      VALUES (
        v_scope, v_op_id, v_fingerprint, v_case.id, v_receipt
      );

      RETURN v_receipt;
    END IF;
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
      withdrawn_reason = NULL,
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

CREATE OR REPLACE FUNCTION public.decline_case_dispatch(
  p_client_operation_id text,
  p_case_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
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

  PERFORM private.expire_temporary_external_coverages();

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
      withdrawn_reason = NULL,
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
          'Derivado a psicólogos de Red externa con cobertura activa tras declinación'
        );
      ELSE
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
          'Caso pendiente de revisión MINED: sin cobertura externa habilitada o disponible'
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

CREATE OR REPLACE FUNCTION public.recover_declined_case_dispatch(p_case_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_case public.cases%ROWTYPE;
  v_dispatch public.case_counselor_dispatches%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  PERFORM private.expire_temporary_external_coverages();

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

  SELECT *
  INTO v_dispatch
  FROM public.case_counselor_dispatches d
  WHERE d.case_id = p_case_id
    AND d.counselor_user_id = v_uid
  FOR UPDATE;

  IF NOT FOUND OR v_dispatch.dispatch_status <> 'declined' THEN
    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'dispatch_not_declined',
      'case_id', p_case_id
    );
  END IF;

  IF v_case.assigned_counselor_id IS NOT NULL AND v_case.assigned_counselor_id <> v_uid THEN
    UPDATE public.case_counselor_dispatches
    SET dispatch_status = 'taken_by_other',
        responded_at = pg_catalog.now()
    WHERE id = v_dispatch.id;

    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'case_already_taken',
      'availability_state', 'already_in_care',
      'case_id', p_case_id
    );
  END IF;

  IF v_case.status = 'closed'::public.case_status THEN
    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'case_closed',
      'availability_state', 'closed',
      'case_id', p_case_id
    );
  END IF;

  IF v_dispatch.dispatch_tier = 'external_pool' AND (
    NOT private.is_school_external_coverage_active(v_case.institution_id)
    OR NOT EXISTS (
      SELECT 1
      FROM public.external_counselor_school_assignments a
      WHERE a.counselor_user_id = v_uid
        AND a.institution_id = v_case.institution_id
        AND a.active = true
        AND a.revoked_at IS NULL
    )
  ) THEN
    UPDATE public.case_counselor_dispatches
    SET dispatch_status = 'taken_by_other',
        withdrawn_reason = 'withdrawn_coverage',
        responded_at = pg_catalog.now()
    WHERE id = v_dispatch.id;

    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'external_coverage_inactive',
      'availability_state', 'coverage_inactive',
      'case_id', p_case_id
    );
  END IF;

  UPDATE public.case_counselor_dispatches
  SET dispatch_status = 'pending',
      withdrawn_reason = NULL,
      responded_at = NULL,
      decline_reason = NULL
  WHERE id = v_dispatch.id;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'case_id', p_case_id,
    'dispatch_status', 'pending'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.recover_declined_case_dispatch(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.recover_declined_case_dispatch(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.list_counselor_dispatch_cases()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_pending jsonb := '[]'::jsonb;
  v_declined jsonb := '[]'::jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  IF NOT private.has_staff_role('counseling_desk'::public.staff_role, NULL) THEN
    RAISE EXCEPTION 'forbidden_counseling_desk_required'
      USING ERRCODE = '42501';
  END IF;

  PERFORM private.expire_temporary_external_coverages();

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', d.id,
        'case_id', d.case_id,
        'reference_code', c.reference_code,
        'institution_id', d.institution_id,
        'institution_name', i.name,
        'situation_type', c.situation_type,
        'student_role', c.student_role,
        'case_status', c.status,
        'assigned_counselor_id', c.assigned_counselor_id,
        'counselor_user_id', d.counselor_user_id,
        'dispatch_tier', d.dispatch_tier,
        'dispatch_status', d.dispatch_status,
        'notified_at', d.notified_at,
        'responded_at', d.responded_at,
        'decline_reason', d.decline_reason,
        'declared_at', c.declared_at,
        'involves_staff', c.involves_staff
      )
      ORDER BY d.notified_at ASC
    ),
    '[]'::jsonb
  )
  INTO v_pending
  FROM public.case_counselor_dispatches d
  JOIN public.cases c ON c.id = d.case_id
  JOIN public.institutions i ON i.id = d.institution_id
  WHERE d.counselor_user_id = v_uid
    AND d.dispatch_status = 'pending'
    AND c.assigned_counselor_id IS NULL
    AND c.status <> 'closed'::public.case_status
    AND private.has_staff_role('counseling_desk'::public.staff_role, d.institution_id);

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', d.id,
        'case_id', d.case_id,
        'reference_code', c.reference_code,
        'institution_id', d.institution_id,
        'institution_name', i.name,
        'situation_type', c.situation_type,
        'student_role', c.student_role,
        'case_status', c.status,
        'assigned_counselor_id', c.assigned_counselor_id,
        'counselor_user_id', d.counselor_user_id,
        'dispatch_tier', d.dispatch_tier,
        'dispatch_status', d.dispatch_status,
        'notified_at', d.notified_at,
        'responded_at', d.responded_at,
        'decline_reason', d.decline_reason,
        'declared_at', c.declared_at,
        'involves_staff', c.involves_staff,
        'can_recover', (
          c.assigned_counselor_id IS NULL
          AND c.status <> 'closed'::public.case_status
          AND (
            d.dispatch_tier = 'school_plant'
            OR (
              private.is_school_external_coverage_active(d.institution_id)
              AND EXISTS (
                SELECT 1
                FROM public.external_counselor_school_assignments a
                WHERE a.counselor_user_id = v_uid
                  AND a.institution_id = d.institution_id
                  AND a.active = true
                  AND a.revoked_at IS NULL
              )
            )
          )
        ),
        'availability_state', CASE
          WHEN c.assigned_counselor_id IS NOT NULL AND c.assigned_counselor_id <> v_uid THEN 'already_in_care'
          WHEN c.status = 'closed'::public.case_status THEN 'closed'
          WHEN d.dispatch_tier = 'external_pool' AND (
            NOT private.is_school_external_coverage_active(d.institution_id)
            OR NOT EXISTS (
              SELECT 1
              FROM public.external_counselor_school_assignments a
              WHERE a.counselor_user_id = v_uid
                AND a.institution_id = d.institution_id
                AND a.active = true
                AND a.revoked_at IS NULL
            )
          ) THEN 'coverage_inactive'
          ELSE 'available'
        END
      )
      ORDER BY COALESCE(d.responded_at, d.notified_at) DESC
    ),
    '[]'::jsonb
  )
  INTO v_declined
  FROM public.case_counselor_dispatches d
  JOIN public.cases c ON c.id = d.case_id
  JOIN public.institutions i ON i.id = d.institution_id
  WHERE d.counselor_user_id = v_uid
    AND d.dispatch_status = 'declined'
    AND private.has_staff_role('counseling_desk'::public.staff_role, d.institution_id);

  RETURN pg_catalog.jsonb_build_object(
    'pending_dispatches', v_pending,
    'declined_dispatches', v_declined
  );
END;
$$;

REVOKE ALL ON FUNCTION public.list_counselor_dispatch_cases() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_counselor_dispatch_cases() TO authenticated;

CREATE OR REPLACE FUNCTION public.list_case_dispatch_history(
  p_institution_id uuid DEFAULT NULL,
  p_case_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
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

  PERFORM private.expire_temporary_external_coverages();

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
        'counselor_name', NULLIF(pg_catalog.btrim(COALESCE(sp.first_name, '') || ' ' || COALESCE(sp.last_name, '')), ''),
        'dispatch_tier', d.dispatch_tier,
        'dispatch_status', CASE WHEN d.withdrawn_reason IS NOT NULL THEN 'withdrawn_coverage' ELSE d.dispatch_status END,
        'withdrawn_reason', d.withdrawn_reason,
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
  LEFT JOIN public.staff_profiles sp ON sp.user_id = d.counselor_user_id
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

CREATE OR REPLACE FUNCTION public.set_school_external_coverage(
  p_institution_id uuid,
  p_mode text DEFAULT NULL,
  p_until timestamptz DEFAULT NULL,
  p_mined_external_enabled boolean DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_is_mined boolean := false;
  v_is_director boolean := false;
  v_school public.institutions%ROWTYPE;
  v_next_mined_enabled boolean;
  v_next_mode text;
  v_next_until timestamptz;
  v_withdrawn integer := 0;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  PERFORM private.expire_temporary_external_coverages();

  SELECT *
  INTO v_school
  FROM public.institutions i
  WHERE i.id = p_institution_id
    AND i.active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'institution_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  v_is_mined := private.has_staff_role('mined_supervisor'::public.staff_role, NULL);
  v_is_director := private.has_staff_role('school_director'::public.staff_role, p_institution_id);

  IF NOT v_is_mined AND NOT v_is_director THEN
    RAISE EXCEPTION 'forbidden_coverage_manager_required'
      USING ERRCODE = '42501';
  END IF;

  IF p_mined_external_enabled IS NOT NULL AND NOT v_is_mined THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  v_next_mined_enabled := COALESCE(p_mined_external_enabled, v_school.mined_external_enabled);
  v_next_mode := COALESCE(p_mode, v_school.external_support_mode);

  IF v_next_mode NOT IN ('disabled', 'enabled', 'temporary_until') THEN
    RAISE EXCEPTION 'invalid_external_support_mode'
      USING ERRCODE = '22023';
  END IF;

  IF NOT v_is_mined AND NOT v_next_mined_enabled AND v_next_mode IN ('enabled', 'temporary_until') THEN
    RAISE EXCEPTION 'mined_paused_external_coverage'
      USING ERRCODE = '42501';
  END IF;

  IF v_next_mode = 'temporary_until' THEN
    v_next_until := COALESCE(p_until, v_school.external_support_until);
    IF v_next_until IS NULL OR v_next_until <= pg_catalog.now() THEN
      RAISE EXCEPTION 'invalid_temporary_until_timestamp'
        USING ERRCODE = '22023';
    END IF;
  ELSE
    v_next_until := NULL;
  END IF;

  UPDATE public.institutions
  SET mined_external_enabled = v_next_mined_enabled,
      external_support_mode = v_next_mode,
      external_support_until = v_next_until,
      external_support_updated_by = v_uid,
      external_support_updated_at = pg_catalog.now()
  WHERE id = v_school.id;

  IF NOT private.is_school_external_coverage_active(v_school.id) THEN
    v_withdrawn := private.withdraw_external_pending_dispatches(v_school.id);
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'institution_id', v_school.id,
    'mined_external_enabled', v_next_mined_enabled,
    'external_support_mode', v_next_mode,
    'external_support_until', v_next_until,
    'coverage_active_now', private.is_school_external_coverage_active(v_school.id),
    'withdrawn_pending_count', v_withdrawn
  );
END;
$$;

REVOKE ALL ON FUNCTION public.set_school_external_coverage(uuid, text, timestamptz, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_school_external_coverage(uuid, text, timestamptz, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.assign_external_counselor_school(
  p_counselor_user_id uuid,
  p_institution_id uuid,
  p_active boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_withdrawn integer := 0;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('mined_supervisor'::public.staff_role, NULL) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = p_counselor_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id IS NULL
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'counselor_must_be_external_network'
      USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.institutions i
    WHERE i.id = p_institution_id
      AND i.active = true
  ) THEN
    RAISE EXCEPTION 'institution_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.external_counselor_school_assignments (
    counselor_user_id,
    institution_id,
    active,
    assigned_by,
    revoked_at,
    updated_at
  )
  VALUES (
    p_counselor_user_id,
    p_institution_id,
    COALESCE(p_active, true),
    v_uid,
    CASE WHEN COALESCE(p_active, true) THEN NULL ELSE pg_catalog.now() END,
    pg_catalog.now()
  )
  ON CONFLICT (counselor_user_id, institution_id) DO UPDATE
  SET active = EXCLUDED.active,
      assigned_by = EXCLUDED.assigned_by,
      revoked_at = EXCLUDED.revoked_at,
      updated_at = pg_catalog.now();

  IF NOT COALESCE(p_active, true) THEN
    UPDATE public.case_counselor_dispatches d
    SET dispatch_status = 'taken_by_other',
        withdrawn_reason = 'withdrawn_coverage',
        responded_at = pg_catalog.now()
    WHERE d.counselor_user_id = p_counselor_user_id
      AND d.institution_id = p_institution_id
      AND d.dispatch_tier = 'external_pool'
      AND d.dispatch_status = 'pending';

    GET DIAGNOSTICS v_withdrawn = ROW_COUNT;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'counselor_user_id', p_counselor_user_id,
    'institution_id', p_institution_id,
    'active', COALESCE(p_active, true),
    'withdrawn_pending_count', v_withdrawn
  );
END;
$$;

REVOKE ALL ON FUNCTION public.assign_external_counselor_school(uuid, uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assign_external_counselor_school(uuid, uuid, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.list_school_coverage_and_assignments(
  p_institution_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_is_mined boolean := false;
  v_is_director boolean := false;
  v_schools jsonb := '[]'::jsonb;
  v_counselors jsonb := '[]'::jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  PERFORM private.expire_temporary_external_coverages();

  v_is_mined := private.has_staff_role('mined_supervisor'::public.staff_role, NULL);
  v_is_director := EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_uid
      AND sm.role = 'school_director'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
      AND (p_institution_id IS NULL OR sm.institution_id = p_institution_id)
  );

  IF NOT v_is_mined AND NOT v_is_director THEN
    RAISE EXCEPTION 'forbidden_coverage_viewer_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'institution_id', i.id,
        'public_code', i.public_code,
        'name', i.name,
        'mined_external_enabled', i.mined_external_enabled,
        'external_support_mode', i.external_support_mode,
        'external_support_until', i.external_support_until,
        'coverage_active_now', private.is_school_external_coverage_active(i.id),
        'has_plant_counselor', EXISTS (
          SELECT 1
          FROM public.staff_memberships sm
          WHERE sm.role = 'counseling_desk'::public.staff_role
            AND sm.institution_id = i.id
            AND sm.active = true
            AND sm.revoked_at IS NULL
        ),
        'assigned_external_count', (
          SELECT COUNT(*)::integer
          FROM public.external_counselor_school_assignments a
          WHERE a.institution_id = i.id
            AND a.active = true
            AND a.revoked_at IS NULL
        )
      )
      ORDER BY i.name ASC
    ),
    '[]'::jsonb
  )
  INTO v_schools
  FROM public.institutions i
  WHERE i.active = true
    AND (
      (v_is_mined AND (p_institution_id IS NULL OR i.id = p_institution_id))
      OR (
        NOT v_is_mined
        AND v_is_director
        AND (p_institution_id IS NULL OR i.id = p_institution_id)
        AND private.has_staff_role('school_director'::public.staff_role, i.id)
      )
    );

  IF v_is_mined THEN
    SELECT COALESCE(
      pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'user_id', sm.user_id,
          'email', u.email,
          'first_name', sp.first_name,
          'last_name', sp.last_name,
          'staff_tier', COALESCE(sp.staff_tier, 'external_network'),
          'is_available', COALESCE(sp.is_available, true),
          'assigned_institution_ids', COALESCE(
            (
              SELECT pg_catalog.jsonb_agg(a.institution_id)
              FROM public.external_counselor_school_assignments a
              WHERE a.counselor_user_id = sm.user_id
                AND a.active = true
                AND a.revoked_at IS NULL
            ),
            '[]'::jsonb
          )
        )
        ORDER BY COALESCE(sp.first_name, u.email) ASC
      ),
      '[]'::jsonb
    )
    INTO v_counselors
    FROM public.staff_memberships sm
    JOIN auth.users u ON u.id = sm.user_id
    LEFT JOIN public.staff_profiles sp ON sp.user_id = sm.user_id
    WHERE sm.role = 'counseling_desk'::public.staff_role
      AND sm.institution_id IS NULL
      AND sm.active = true
      AND sm.revoked_at IS NULL;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'schools', v_schools,
    'external_counselors', v_counselors
  );
END;
$$;

REVOKE ALL ON FUNCTION public.list_school_coverage_and_assignments(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_school_coverage_and_assignments(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.re_dispatch_unassigned_case(p_case_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_case public.cases%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('mined_supervisor'::public.staff_role, NULL) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
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

  IF v_case.assigned_counselor_id IS NOT NULL OR v_case.status = 'closed'::public.case_status THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'case_already_assigned_or_closed');
  END IF;

  RETURN private.dispatch_case_to_counselors(
    v_case.id,
    v_case.institution_id,
    v_case.involves_staff,
    false
  );
END;
$$;

REVOKE ALL ON FUNCTION public.re_dispatch_unassigned_case(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.re_dispatch_unassigned_case(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.revoke_staff_membership_and_reassign(
  p_membership_id uuid,
  p_reassign_to_user_id uuid DEFAULT NULL,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_membership public.staff_memberships%ROWTYPE;
  v_reason text;
  v_reassigned_count integer := 0;
  v_case record;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('mined_supervisor'::public.staff_role, NULL) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  v_reason := COALESCE(
    NULLIF(pg_catalog.btrim(COALESCE(p_reason, '')), ''),
    'Membresía revocada por MINED; casos abiertos reasignados'
  );

  SELECT *
  INTO v_membership
  FROM public.staff_memberships sm
  WHERE sm.id = p_membership_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'membership_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF p_reassign_to_user_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = p_reassign_to_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'reassign_target_inactive'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.staff_memberships
  SET active = false,
      revoked_at = COALESCE(revoked_at, pg_catalog.now())
  WHERE id = v_membership.id;

  UPDATE public.case_counselor_dispatches d
  SET dispatch_status = 'taken_by_other',
      withdrawn_reason = 'withdrawn_coverage',
      responded_at = pg_catalog.now()
  WHERE d.counselor_user_id = v_membership.user_id
    AND d.dispatch_status = 'pending'
    AND (v_membership.institution_id IS NULL OR d.institution_id = v_membership.institution_id);

  FOR v_case IN
    SELECT *
    FROM public.cases c
    WHERE c.assigned_counselor_id = v_membership.user_id
      AND c.status <> 'closed'::public.case_status
      AND (v_membership.institution_id IS NULL OR c.institution_id = v_membership.institution_id)
    FOR UPDATE
  LOOP
    v_reassigned_count := v_reassigned_count + 1;
    IF p_reassign_to_user_id IS NOT NULL THEN
      UPDATE public.cases
      SET assigned_counselor_id = p_reassign_to_user_id,
          concurrency_version = concurrency_version + 1
      WHERE id = v_case.id;

      INSERT INTO public.case_events (
        case_id, institution_id, event_type, from_status, to_status,
        actor_user_id, actor_role, reason
      )
      VALUES (
        v_case.id, v_case.institution_id, 'counselor_assigned',
        v_case.status, v_case.status, v_uid, 'mined_supervisor', v_reason
      );
    ELSE
      UPDATE public.cases
      SET assigned_counselor_id = NULL,
          status = 'received'::public.case_status,
          concurrency_version = concurrency_version + 1
      WHERE id = v_case.id;

      INSERT INTO public.case_events (
        case_id, institution_id, event_type, from_status, to_status,
        actor_user_id, actor_role, reason
      )
      VALUES (
        v_case.id, v_case.institution_id, 'status_changed',
        v_case.status, 'received'::public.case_status, v_uid, 'mined_supervisor', v_reason
      );
    END IF;
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'membership_id', v_membership.id,
    'affected_cases_count', v_reassigned_count
  );
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_staff_membership_and_reassign(uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.revoke_staff_membership_and_reassign(uuid, uuid, text) TO authenticated;

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
        'staff_tier', COALESCE(sp.staff_tier, CASE
          WHEN sm.role = 'mined_supervisor'::public.staff_role THEN 'mined_central'
          WHEN sm.role = 'school_director'::public.staff_role THEN 'school_director'
          WHEN sm.institution_id IS NULL THEN 'external_network'
          ELSE 'school_plant'
        END),
        'institution_id', sm.institution_id,
        'institution_public_code', i.public_code,
        'institution_name', i.name,
        'scope_label', COALESCE(i.name, 'Ámbito central MINED / Red externa')
      )
      ORDER BY sm.role ASC, i.name ASC NULLS FIRST
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.staff_memberships sm
  LEFT JOIN public.staff_profiles sp ON sp.user_id = sm.user_id
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

CREATE OR REPLACE FUNCTION public.get_my_staff_profile()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_email text;
  v_email_confirmed timestamptz;
  v_profile public.staff_profiles%ROWTYPE;
  v_supervisor_name text;
  v_memberships jsonb;
  v_assigned_schools jsonb := '[]'::jsonb;
  v_available_schools jsonb := '[]'::jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  PERFORM private.expire_temporary_external_coverages();

  SELECT u.email, u.email_confirmed_at
  INTO v_email, v_email_confirmed
  FROM auth.users u
  WHERE u.id = v_uid;

  SELECT *
  INTO v_profile
  FROM public.staff_profiles sp
  WHERE sp.user_id = v_uid;

  IF v_profile.supervisor_user_id IS NOT NULL THEN
    SELECT NULLIF(pg_catalog.btrim(COALESCE(sup.first_name, '') || ' ' || COALESCE(sup.last_name, '')), '')
    INTO v_supervisor_name
    FROM public.staff_profiles sup
    WHERE sup.user_id = v_profile.supervisor_user_id;
  END IF;

  v_memberships := public.get_my_staff_memberships();

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'institution_id', i.id,
        'public_code', i.public_code,
        'name', i.name,
        'coverage_active_now', private.is_school_external_coverage_active(i.id),
        'external_support_mode', i.external_support_mode,
        'external_support_until', i.external_support_until
      )
      ORDER BY i.name ASC
    ),
    '[]'::jsonb
  )
  INTO v_assigned_schools
  FROM public.external_counselor_school_assignments a
  JOIN public.institutions i ON i.id = a.institution_id AND i.active = true
  WHERE a.counselor_user_id = v_uid
    AND a.active = true
    AND a.revoked_at IS NULL;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'institution_id', i.id,
        'public_code', i.public_code,
        'name', i.name,
        'coverage_active_now', private.is_school_external_coverage_active(i.id),
        'external_support_mode', i.external_support_mode,
        'external_support_until', i.external_support_until
      )
      ORDER BY i.name ASC
    ),
    '[]'::jsonb
  )
  INTO v_available_schools
  FROM public.institutions i
  WHERE i.active = true
    AND NOT EXISTS (
      SELECT 1
      FROM public.external_counselor_school_assignments a
      WHERE a.counselor_user_id = v_uid
        AND a.institution_id = i.id
        AND a.active = true
        AND a.revoked_at IS NULL
    );

  RETURN pg_catalog.jsonb_build_object(
    'user_id', v_uid,
    'email', v_email,
    'email_confirmed', v_email_confirmed IS NOT NULL,
    'first_name', v_profile.first_name,
    'last_name', v_profile.last_name,
    'staff_tier', v_profile.staff_tier,
    'supervisor_user_id', v_profile.supervisor_user_id,
    'supervisor_name', v_supervisor_name,
    'is_available', COALESCE(v_profile.is_available, true),
    'notify_new_alerts', COALESCE(v_profile.notify_new_alerts, true),
    'notify_new_messages', COALESCE(v_profile.notify_new_messages, true),
    'memberships', v_memberships,
    'assigned_schools', v_assigned_schools,
    'available_schools', v_available_schools
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_staff_profile() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_staff_profile() TO authenticated;

CREATE OR REPLACE FUNCTION public.list_assignable_counselors(
  p_institution_id uuid DEFAULT NULL
)
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
        'institution_id', sm.institution_id,
        'first_name', sp.first_name,
        'last_name', sp.last_name,
        'staff_tier', COALESCE(sp.staff_tier, CASE WHEN sm.institution_id IS NULL THEN 'external_network' ELSE 'school_plant' END),
        'is_available', COALESCE(sp.is_available, true)
      )
      ORDER BY COALESCE(sp.first_name, u.email) ASC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.staff_memberships sm
  JOIN auth.users u ON u.id = sm.user_id
  LEFT JOIN public.staff_profiles sp ON sp.user_id = sm.user_id
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
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_op_id text;
  v_guidance text;
  v_closed_reason text;
  v_case public.cases%ROWTYPE;
  v_profile public.staff_profiles%ROWTYPE;
  v_sup_name text;
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

  -- Si actúa un practicante de 5.º año, su supervisor asignado recibe solo un aviso (no bloqueante).
  SELECT *
  INTO v_profile
  FROM public.staff_profiles sp
  WHERE sp.user_id = v_uid;

  IF FOUND AND v_profile.staff_tier = 'practicante_5to' AND v_profile.supervisor_user_id IS NOT NULL THEN
    SELECT COALESCE(
      NULLIF(pg_catalog.btrim(COALESCE(sup.first_name, '') || ' ' || COALESCE(sup.last_name, '')), ''),
      'Supervisor asignado'
    )
    INTO v_sup_name
    FROM public.staff_profiles sup
    WHERE sup.user_id = v_profile.supervisor_user_id;

    INSERT INTO public.practicante_supervisor_notices (
      case_id,
      institution_id,
      practicante_user_id,
      supervisor_user_id,
      human_level,
      reason
    )
    VALUES (
      v_case.id,
      v_case.institution_id,
      v_uid,
      v_profile.supervisor_user_id,
      p_human_level,
      pg_catalog.left(
        'Aviso informativo para supervisor (' || COALESCE(v_sup_name, 'Supervisor') || '): practicante valoró Nivel ' || p_human_level::text,
        500
      )
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

CREATE OR REPLACE FUNCTION public.list_my_supervisor_notices()
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
        'event_id', n.id,
        'case_id', n.case_id,
        'reference_code', c.reference_code,
        'institution_name', i.name,
        'situation_type', c.situation_type,
        'human_level', n.human_level,
        'practicante_name', NULLIF(pg_catalog.btrim(COALESCE(sp.first_name, '') || ' ' || COALESCE(sp.last_name, '')), ''),
        'reason', n.reason,
        'created_at', n.created_at
      )
      ORDER BY n.created_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.practicante_supervisor_notices n
  JOIN public.cases c ON c.id = n.case_id
  JOIN public.institutions i ON i.id = n.institution_id
  LEFT JOIN public.staff_profiles sp ON sp.user_id = n.practicante_user_id
  WHERE n.supervisor_user_id = v_uid
    AND private.has_staff_role('counseling_desk'::public.staff_role, n.institution_id);

  RETURN v_rows;
END;
$$;

REVOKE ALL ON FUNCTION public.list_my_supervisor_notices() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_my_supervisor_notices() TO authenticated;
