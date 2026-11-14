-- Guarda el estado cerrado del caso en los RPCs del chat humano:
-- un caso cerrado conserva su historial de mensajes en lectura, pero impide nuevos envíos.

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

  SELECT c.chat_available_notice, c.status, c.student_piece
  INTO v_chat_available, v_status, v_student_piece
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
    'chat_available_notice', (v_chat_available AND v_status <> 'closed'::public.case_status),
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

  SELECT c.chat_available_notice, c.status
  INTO v_chat_available, v_status
  FROM public.cases c
  JOIN public.case_private_capabilities cpc
    ON cpc.case_id = c.id
  WHERE c.id = p_case_id
    AND cpc.capability_verifier_hash = v_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  IF NOT v_chat_available OR v_status = 'closed'::public.case_status THEN
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

  IF v_case.status = 'closed'::public.case_status THEN
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
