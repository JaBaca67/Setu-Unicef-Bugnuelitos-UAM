-- Migración 9: Finalizar conversación sin cerrar el expediente, borrador de ficha
-- y cupo de tres alertas activas por instalación.

-- ---------------------------------------------------------------------------
-- 1. Columnas en cases, evento conversation_ended y estado previo en cerrados
-- ---------------------------------------------------------------------------

ALTER TABLE public.cases
  ADD COLUMN IF NOT EXISTS conversation_ended_at timestamptz,
  ADD COLUMN IF NOT EXISTS conversation_ended_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS cases_conversation_ended_by_idx
  ON public.cases (conversation_ended_by);

UPDATE public.cases
SET conversation_ended_at = COALESCE(closed_at, pg_catalog.now()),
    conversation_ended_by = COALESCE(conversation_ended_by, assigned_counselor_id),
    chat_available_notice = false
WHERE status = 'closed'::public.case_status
  AND conversation_ended_at IS NULL;

ALTER TABLE public.case_events
  DROP CONSTRAINT IF EXISTS case_events_event_type_check;

ALTER TABLE public.case_events
  ADD CONSTRAINT case_events_event_type_check
  CHECK (
    event_type IN (
      'alert_received',
      'teacher_notice_recorded',
      'counselor_assigned',
      'level_assessed',
      'sheet_issued',
      'school_action_recorded',
      'urgent_referral',
      'status_changed',
      'conversation_ended'
    )
  );

-- ---------------------------------------------------------------------------
-- 2. Borrador privado de «Nota para la ficha» (solo Mesa asignada, fuera de Realtime)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.case_sheet_drafts (
  case_id uuid PRIMARY KEY REFERENCES public.cases(id) ON DELETE CASCADE,
  author_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  guidance_draft text NOT NULL CHECK (char_length(guidance_draft) <= 1500),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS case_sheet_drafts_author_user_id_idx
  ON public.case_sheet_drafts (author_user_id);

REVOKE ALL ON TABLE public.case_sheet_drafts FROM PUBLIC, anon, authenticated;

ALTER TABLE public.case_sheet_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_sheet_drafts FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS case_sheet_drafts_deny_all ON public.case_sheet_drafts;
CREATE POLICY case_sheet_drafts_deny_all
  ON public.case_sheet_drafts
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE OR REPLACE FUNCTION public.save_case_sheet_draft(
  p_case_id uuid,
  p_guidance_draft text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_draft text;
  v_case public.cases%ROWTYPE;
  v_saved public.case_sheet_drafts%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_assigned_counselor(p_case_id) THEN
    RAISE EXCEPTION 'forbidden_assigned_counselor_required'
      USING ERRCODE = '42501';
  END IF;

  v_draft := pg_catalog.btrim(COALESCE(p_guidance_draft, ''));
  IF pg_catalog.char_length(v_draft) > 1500 THEN
    RAISE EXCEPTION 'invalid_guidance_notes'
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

  IF v_case.status = 'closed'::public.case_status THEN
    RAISE EXCEPTION 'case_closed_cannot_edit_sheet_draft'
      USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.case_sheet_drafts (
    case_id,
    author_user_id,
    guidance_draft,
    updated_at
  )
  VALUES (
    v_case.id,
    v_uid,
    v_draft,
    pg_catalog.now()
  )
  ON CONFLICT (case_id) DO UPDATE
    SET author_user_id = EXCLUDED.author_user_id,
        guidance_draft = EXCLUDED.guidance_draft,
        updated_at = pg_catalog.now()
  RETURNING * INTO v_saved;

  RETURN pg_catalog.jsonb_build_object(
    'case_id', v_saved.case_id,
    'guidance_draft', v_saved.guidance_draft,
    'updated_at', v_saved.updated_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.save_case_sheet_draft(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_case_sheet_draft(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_case_sheet_draft(
  p_case_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_saved public.case_sheet_drafts%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_assigned_counselor(p_case_id) THEN
    RAISE EXCEPTION 'forbidden_assigned_counselor_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_saved
  FROM public.case_sheet_drafts d
  WHERE d.case_id = p_case_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'case_id', v_saved.case_id,
    'guidance_draft', v_saved.guidance_draft,
    'updated_at', v_saved.updated_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_case_sheet_draft(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_case_sheet_draft(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Finalizar conversación sin cerrar el expediente y guardas de chat
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.end_case_conversation(
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
  v_ended_at timestamptz := pg_catalog.now();
  v_next_version integer;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
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

  SELECT *
  INTO v_case
  FROM public.cases c
  WHERE c.id = p_case_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'case_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_case.human_level IS NULL THEN
    RAISE EXCEPTION 'assessment_required_before_ending'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_case.conversation_ended_at IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object(
      'case_id', v_case.id,
      'conversation_ended_at', v_case.conversation_ended_at,
      'status', v_case.status,
      'concurrency_version', v_case.concurrency_version
    );
  END IF;

  v_next_version := v_case.concurrency_version + 1;

  UPDATE public.cases
  SET conversation_ended_at = v_ended_at,
      conversation_ended_by = v_uid,
      chat_available_notice = false,
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
    'conversation_ended',
    v_case.status,
    v_case.status,
    v_case.human_level,
    v_uid,
    'counseling_desk',
    'Conversación finalizada por Mesa de Escucha'
  );

  IF pg_catalog.to_regclass('public.push_device_tokens') IS NOT NULL THEN
    DELETE FROM public.push_device_tokens
    WHERE case_id = v_case.id;
  END IF;

  v_receipt := pg_catalog.jsonb_build_object(
    'case_id', v_case.id,
    'conversation_ended_at', v_ended_at,
    'status', v_case.status,
    'concurrency_version', v_next_version
  );

  v_scope := 'end_conversation:' || v_uid::text || ':' || v_case.id::text;
  v_canonical := pg_catalog.jsonb_build_object('case_id', v_case.id);
  v_fingerprint := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_canonical::text, 'UTF8')),
    'hex'
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
  )
  ON CONFLICT (operation_scope, client_operation_id) DO NOTHING;

  RETURN v_receipt;
END;
$$;

REVOKE ALL ON FUNCTION public.end_case_conversation(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.end_case_conversation(text, uuid) TO authenticated;

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
      conversation_ended_at = CASE
        WHEN COALESCE(p_close_case, false) OR v_next_status = 'closed'::public.case_status
          THEN COALESCE(conversation_ended_at, pg_catalog.now())
        ELSE conversation_ended_at
      END,
      conversation_ended_by = CASE
        WHEN COALESCE(p_close_case, false) OR v_next_status = 'closed'::public.case_status
          THEN COALESCE(conversation_ended_by, v_uid)
        ELSE conversation_ended_by
      END,
      chat_available_notice = CASE
        WHEN COALESCE(p_close_case, false) OR v_next_status = 'closed'::public.case_status THEN false
        ELSE chat_available_notice
      END,
      concurrency_version = v_next_version
  WHERE id = v_case.id;

  IF (COALESCE(p_close_case, false) OR v_next_status = 'closed'::public.case_status)
     AND pg_catalog.to_regclass('public.push_device_tokens') IS NOT NULL THEN
    DELETE FROM public.push_device_tokens
    WHERE case_id = v_case.id;
  END IF;

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

    DELETE FROM public.case_sheet_drafts
    WHERE case_id = v_case.id;

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

  IF v_case.status = 'closed'::public.case_status OR v_case.conversation_ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'chat_not_available'
      USING ERRCODE = 'P0001';
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
  v_status public.case_status;
  v_ended_at timestamptz;
  v_ended boolean;
  v_reference_code text;
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

  SELECT c.chat_available_notice, c.status, c.conversation_ended_at, c.reference_code, c.student_piece
  INTO v_chat_available, v_status, v_ended_at, v_reference_code, v_student_piece
  FROM public.cases c
  JOIN public.case_private_capabilities cpc
    ON cpc.case_id = c.id
  WHERE c.id = p_case_id
    AND cpc.capability_verifier_hash = v_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  v_ended := (v_ended_at IS NOT NULL OR v_status = 'closed'::public.case_status);

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
    'reference_code', v_reference_code,
    'chat_available_notice', (v_chat_available AND NOT v_ended),
    'conversation_ended', v_ended,
    'case_closed', (v_status = 'closed'::public.case_status),
    'student_piece', v_student_piece,
    'messages', v_messages
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_chat_session(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_chat_session(uuid, text) TO anon, authenticated;

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
  v_status public.case_status;
  v_ended_at timestamptz;
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

  SELECT c.chat_available_notice, c.status, c.conversation_ended_at
  INTO v_chat_available, v_status, v_ended_at
  FROM public.cases c
  JOIN public.case_private_capabilities cpc
    ON cpc.case_id = c.id
  WHERE c.id = p_case_id
    AND cpc.capability_verifier_hash = v_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  IF NOT v_chat_available OR v_ended_at IS NOT NULL OR v_status = 'closed'::public.case_status THEN
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

REVOKE ALL ON FUNCTION public.send_student_chat_message(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_student_chat_message(uuid, text, text, text) TO anon, authenticated;

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

  IF v_case.status = 'closed'::public.case_status OR v_case.conversation_ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'chat_not_available'
      USING ERRCODE = 'P0001';
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

-- ---------------------------------------------------------------------------
-- 4. Cupo de tres alertas activas por instalación
-- ---------------------------------------------------------------------------

ALTER TABLE public.case_private_capabilities
  ADD COLUMN IF NOT EXISTS installation_verifier_hash text;

ALTER TABLE public.case_private_capabilities
  DROP CONSTRAINT IF EXISTS case_private_capabilities_installation_verifier_hash_check;

ALTER TABLE public.case_private_capabilities
  ADD CONSTRAINT case_private_capabilities_installation_verifier_hash_check
  CHECK (installation_verifier_hash IS NULL OR installation_verifier_hash ~ '^[0-9a-f]{64}$');

CREATE INDEX IF NOT EXISTS case_private_capabilities_installation_hash_idx
  ON public.case_private_capabilities (installation_verifier_hash)
  WHERE installation_verifier_hash IS NOT NULL;

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
  p_student_piece jsonb,
  p_installation_verifier_hash text
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
  v_inst_hash text;
  v_narrative text;
  v_location text;
  v_approx_date text;
  v_school public.institutions%ROWTYPE;
  v_scope text;
  v_canonical jsonb;
  v_fingerprint text;
  v_existing public.inbound_operations%ROWTYPE;
  v_active_count integer;
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

  v_inst_hash := pg_catalog.lower(pg_catalog.btrim(COALESCE(p_installation_verifier_hash, '')));
  IF v_inst_hash !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'invalid_installation_verifier_hash'
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
    'installation_verifier_hash', v_inst_hash,
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

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('student_alert_installation'),
    pg_catalog.hashtext(v_inst_hash)
  );

  SELECT pg_catalog.count(*)::integer
  INTO v_active_count
  FROM public.case_private_capabilities cpc
  JOIN public.cases c
    ON c.id = cpc.case_id
  WHERE cpc.installation_verifier_hash = v_inst_hash
    AND c.conversation_ended_at IS NULL
    AND c.status <> 'closed'::public.case_status;

  IF v_active_count >= 3 THEN
    RAISE EXCEPTION 'active_alert_limit_reached'
      USING ERRCODE = 'P0001';
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
    capability_verifier_hash,
    installation_verifier_hash
  )
  VALUES (
    v_case_id,
    v_cap_hash,
    v_inst_hash
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
  jsonb,
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
  text,
  jsonb,
  text
) TO anon, authenticated;
