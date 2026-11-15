-- Migración 10: Notificaciones push con Firebase Cloud Messaging (FCM).
-- Tabla push_device_tokens, RPCs de registro/baja para estudiante y personal,
-- helper pg_net + Vault y disparadores sin datos sensibles en el payload.

CREATE EXTENSION IF NOT EXISTS pg_net;

-- ---------------------------------------------------------------------------
-- 1. Tabla de tokens FCM por dispositivo (RLS denegado por defecto)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.push_device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_scope text NOT NULL CHECK (role_scope IN ('student', 'staff')),
  user_id uuid NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  case_id uuid NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  fcm_token text NOT NULL CHECK (char_length(btrim(fcm_token)) BETWEEN 20 AND 512),
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT push_device_tokens_owner_check CHECK (
    (role_scope = 'staff' AND user_id IS NOT NULL AND case_id IS NULL)
    OR (role_scope = 'student' AND case_id IS NOT NULL AND user_id IS NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS push_device_tokens_staff_unique_idx
  ON public.push_device_tokens (user_id, fcm_token)
  WHERE role_scope = 'staff';

CREATE UNIQUE INDEX IF NOT EXISTS push_device_tokens_student_unique_idx
  ON public.push_device_tokens (case_id, fcm_token)
  WHERE role_scope = 'student';

CREATE INDEX IF NOT EXISTS push_device_tokens_user_id_idx
  ON public.push_device_tokens (user_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS push_device_tokens_case_id_idx
  ON public.push_device_tokens (case_id)
  WHERE case_id IS NOT NULL;

REVOKE ALL ON TABLE public.push_device_tokens FROM PUBLIC, anon, authenticated;

ALTER TABLE public.push_device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_device_tokens FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS push_device_tokens_deny_all ON public.push_device_tokens;
CREATE POLICY push_device_tokens_deny_all
  ON public.push_device_tokens
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

-- ---------------------------------------------------------------------------
-- 2. RPCs de registro y baja para personal autenticado
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.register_staff_push_token(
  p_fcm_token text,
  p_platform text DEFAULT 'android'
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_token text;
  v_platform text;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_uid
      AND sm.active = true
  ) THEN
    RAISE EXCEPTION 'forbidden_active_staff_membership_required'
      USING ERRCODE = '42501';
  END IF;

  v_token := pg_catalog.btrim(COALESCE(p_fcm_token, ''));
  IF pg_catalog.char_length(v_token) NOT BETWEEN 20 AND 512 THEN
    RAISE EXCEPTION 'invalid_fcm_token'
      USING ERRCODE = '22023';
  END IF;

  v_platform := pg_catalog.lower(pg_catalog.btrim(COALESCE(p_platform, 'android')));
  IF v_platform NOT IN ('android', 'ios') THEN
    RAISE EXCEPTION 'invalid_push_platform'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.push_device_tokens (
    role_scope,
    user_id,
    case_id,
    fcm_token,
    platform,
    updated_at
  )
  VALUES (
    'staff',
    v_uid,
    NULL,
    v_token,
    v_platform,
    pg_catalog.now()
  )
  ON CONFLICT (user_id, fcm_token) WHERE role_scope = 'staff' DO UPDATE
    SET platform = EXCLUDED.platform,
        updated_at = pg_catalog.now();

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'role_scope', 'staff',
    'platform', v_platform
  );
END;
$$;

REVOKE ALL ON FUNCTION public.register_staff_push_token(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_staff_push_token(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.unregister_staff_push_token(
  p_fcm_token text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_token text;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  v_token := pg_catalog.btrim(COALESCE(p_fcm_token, ''));
  IF pg_catalog.char_length(v_token) > 0 THEN
    DELETE FROM public.push_device_tokens
    WHERE role_scope = 'staff'
      AND user_id = v_uid
      AND fcm_token = v_token;
  END IF;

  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.unregister_staff_push_token(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.unregister_staff_push_token(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. RPCs de registro y baja para estudiante (autorizado por capability token)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.register_student_push_token(
  p_case_id uuid,
  p_capability_token text,
  p_fcm_token text,
  p_platform text DEFAULT 'android'
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_cap_token text;
  v_cap_hash text;
  v_token text;
  v_platform text;
  v_status public.case_status;
  v_ended_at timestamptz;
BEGIN
  v_cap_token := pg_catalog.btrim(COALESCE(p_capability_token, ''));
  IF p_case_id IS NULL OR pg_catalog.char_length(v_cap_token) < 32 THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  v_token := pg_catalog.btrim(COALESCE(p_fcm_token, ''));
  IF pg_catalog.char_length(v_token) NOT BETWEEN 20 AND 512 THEN
    RAISE EXCEPTION 'invalid_fcm_token'
      USING ERRCODE = '22023';
  END IF;

  v_platform := pg_catalog.lower(pg_catalog.btrim(COALESCE(p_platform, 'android')));
  IF v_platform NOT IN ('android', 'ios') THEN
    RAISE EXCEPTION 'invalid_push_platform'
      USING ERRCODE = '22023';
  END IF;

  v_cap_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_cap_token, 'UTF8')),
    'hex'
  );

  SELECT c.status, c.conversation_ended_at
  INTO v_status, v_ended_at
  FROM public.cases c
  JOIN public.case_private_capabilities cpc
    ON cpc.case_id = c.id
  WHERE c.id = p_case_id
    AND cpc.capability_verifier_hash = v_cap_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  IF v_status = 'closed'::public.case_status OR v_ended_at IS NOT NULL THEN
    RAISE EXCEPTION 'chat_not_available'
      USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.push_device_tokens (
    role_scope,
    user_id,
    case_id,
    fcm_token,
    platform,
    updated_at
  )
  VALUES (
    'student',
    NULL,
    p_case_id,
    v_token,
    v_platform,
    pg_catalog.now()
  )
  ON CONFLICT (case_id, fcm_token) WHERE role_scope = 'student' DO UPDATE
    SET platform = EXCLUDED.platform,
        updated_at = pg_catalog.now();

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'role_scope', 'student',
    'platform', v_platform
  );
END;
$$;

REVOKE ALL ON FUNCTION public.register_student_push_token(uuid, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_student_push_token(uuid, text, text, text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.unregister_student_push_token(
  p_case_id uuid,
  p_capability_token text,
  p_fcm_token text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_cap_token text;
  v_cap_hash text;
  v_token text;
BEGIN
  v_cap_token := pg_catalog.btrim(COALESCE(p_capability_token, ''));
  IF p_case_id IS NULL OR pg_catalog.char_length(v_cap_token) < 32 THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  v_cap_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_cap_token, 'UTF8')),
    'hex'
  );

  IF NOT EXISTS (
    SELECT 1
    FROM public.case_private_capabilities cpc
    WHERE cpc.case_id = p_case_id
      AND cpc.capability_verifier_hash = v_cap_hash
  ) THEN
    RAISE EXCEPTION 'invalid_case_capability'
      USING ERRCODE = '42501';
  END IF;

  v_token := pg_catalog.btrim(COALESCE(p_fcm_token, ''));
  IF pg_catalog.char_length(v_token) > 0 THEN
    DELETE FROM public.push_device_tokens
    WHERE role_scope = 'student'
      AND case_id = p_case_id
      AND fcm_token = v_token;
  END IF;

  RETURN pg_catalog.jsonb_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.unregister_student_push_token(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.unregister_student_push_token(uuid, text, text) TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Helper interno pg_net + Vault y disparadores de eventos
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.dispatch_push_notification(
  p_event_type text,
  p_target_user_id uuid DEFAULT NULL,
  p_target_case_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_base_url text;
  v_secret text;
BEGIN
  IF p_target_user_id IS NULL AND p_target_case_id IS NULL THEN
    RETURN;
  END IF;

  -- Si aún no hay secreto configurado en Vault, se omite sin bloquear la transacción principal.
  SELECT ds.decrypted_secret
  INTO v_secret
  FROM vault.decrypted_secrets ds
  WHERE ds.name = 'push_dispatch_secret'
  ORDER BY ds.created_at DESC
  LIMIT 1;

  IF v_secret IS NULL OR pg_catalog.btrim(v_secret) = '' THEN
    RETURN;
  END IF;

  SELECT ds.decrypted_secret
  INTO v_base_url
  FROM vault.decrypted_secrets ds
  WHERE ds.name = 'supabase_url'
  ORDER BY ds.created_at DESC
  LIMIT 1;

  v_base_url := COALESCE(
    NULLIF(pg_catalog.rtrim(pg_catalog.btrim(COALESCE(v_base_url, '')), '/'), ''),
    'https://rliiwzovgpnxhrkdkmus.supabase.co'
  );

  PERFORM net.http_post(
    url := v_base_url || '/functions/v1/push-dispatch',
    body := pg_catalog.jsonb_build_object(
      'event_type', p_event_type,
      'target_user_id', p_target_user_id,
      'target_case_id', p_target_case_id
    ),
    headers := pg_catalog.jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-dispatch-secret', v_secret
    )
  );
EXCEPTION
  WHEN OTHERS THEN
    -- Nunca abortar alertas ni mensajes si falla la cola HTTP asíncrona.
    RETURN;
END;
$$;

REVOKE ALL ON FUNCTION private.dispatch_push_notification(text, uuid, uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.trg_push_on_case_dispatch()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_notify boolean := true;
BEGIN
  IF NEW.dispatch_status <> 'pending' THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(sp.notify_new_alerts, true)
  INTO v_notify
  FROM public.staff_profiles sp
  WHERE sp.user_id = NEW.counselor_user_id;

  IF COALESCE(v_notify, true) THEN
    PERFORM private.dispatch_push_notification(
      'new_alert_dispatch',
      NEW.counselor_user_id,
      NULL
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_push_new_dispatch ON public.case_counselor_dispatches;
CREATE TRIGGER trg_push_new_dispatch
  AFTER INSERT ON public.case_counselor_dispatches
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_push_on_case_dispatch();

CREATE OR REPLACE FUNCTION private.trg_push_on_chat_enabled()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.chat_available_notice = true
     AND COALESCE(OLD.chat_available_notice, false) = false
     AND NEW.conversation_ended_at IS NULL
     AND NEW.status <> 'closed'::public.case_status THEN
    PERFORM private.dispatch_push_notification(
      'student_chat_enabled',
      NULL,
      NEW.id
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_push_chat_enabled ON public.cases;
CREATE TRIGGER trg_push_chat_enabled
  AFTER UPDATE OF chat_available_notice ON public.cases
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_push_on_chat_enabled();

CREATE OR REPLACE FUNCTION private.trg_push_on_case_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_counselor_id uuid;
  v_notify boolean := true;
BEGIN
  IF NEW.sender_role = 'counseling_desk'::public.case_message_sender THEN
    PERFORM private.dispatch_push_notification(
      'student_new_message',
      NULL,
      NEW.case_id
    );
  ELSIF NEW.sender_role = 'student'::public.case_message_sender THEN
    SELECT c.assigned_counselor_id
    INTO v_counselor_id
    FROM public.cases c
    WHERE c.id = NEW.case_id;

    IF v_counselor_id IS NOT NULL THEN
      SELECT COALESCE(sp.notify_new_messages, true)
      INTO v_notify
      FROM public.staff_profiles sp
      WHERE sp.user_id = v_counselor_id;

      IF COALESCE(v_notify, true) THEN
        PERFORM private.dispatch_push_notification(
          'staff_new_message',
          v_counselor_id,
          NULL
        );
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_push_new_message ON public.case_messages;
CREATE TRIGGER trg_push_new_message
  AFTER INSERT ON public.case_messages
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_push_on_case_message();
