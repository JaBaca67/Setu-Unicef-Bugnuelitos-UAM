-- Migración M6 / Bloque A: Perfil de personal, alta post-verificación de correo,
-- gobernanza de invitaciones, auditoría sin códigos en texto plano y ayuda de acceso.

CREATE TABLE IF NOT EXISTS public.staff_profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name text NOT NULL CHECK (char_length(btrim(first_name)) BETWEEN 2 AND 80),
  last_name text NOT NULL CHECK (char_length(btrim(last_name)) BETWEEN 2 AND 80),
  staff_tier text NOT NULL DEFAULT 'school_plant' CHECK (
    staff_tier IN (
      'school_plant',
      'external_network',
      'practicante_5to',
      'mined_central',
      'school_director'
    )
  ),
  supervisor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  is_available boolean NOT NULL DEFAULT true,
  notify_new_alerts boolean NOT NULL DEFAULT true,
  notify_new_messages boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT staff_profiles_practicante_requires_supervisor CHECK (
    staff_tier <> 'practicante_5to' OR supervisor_user_id IS NOT NULL
  )
);

CREATE INDEX IF NOT EXISTS idx_staff_profiles_supervisor
  ON public.staff_profiles (supervisor_user_id)
  WHERE supervisor_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_staff_profiles_availability_tier
  ON public.staff_profiles (is_available, staff_tier);

ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_profiles FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.staff_profiles FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.staff_profiles TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'staff_profiles' AND policyname = 'staff_profiles_select_own'
  ) THEN
    CREATE POLICY staff_profiles_select_own
      ON public.staff_profiles
      FOR SELECT
      TO authenticated
      USING (user_id = (SELECT auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'staff_profiles' AND policyname = 'staff_profiles_select_mined'
  ) THEN
    CREATE POLICY staff_profiles_select_mined
      ON public.staff_profiles
      FOR SELECT
      TO authenticated
      USING ((SELECT private.has_staff_role('mined_supervisor'::public.staff_role, NULL)));
  END IF;
END $$;

ALTER TABLE public.staff_activation_invites
  ADD COLUMN IF NOT EXISTS full_name text CHECK (
    full_name IS NULL OR char_length(btrim(full_name)) BETWEEN 2 AND 160
  ),
  ADD COLUMN IF NOT EXISTS staff_tier text NOT NULL DEFAULT 'school_plant' CHECK (
    staff_tier IN (
      'school_plant',
      'external_network',
      'practicante_5to',
      'mined_central',
      'school_director'
    )
  ),
  ADD COLUMN IF NOT EXISTS supervisor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS request_status text NOT NULL DEFAULT 'approved' CHECK (
    request_status IN (
      'pending_approval',
      'approved',
      'rejected',
      'replacement_requested'
    )
  ),
  ADD COLUMN IF NOT EXISTS requested_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS requester_program_label text CHECK (
    requester_program_label IS NULL OR char_length(btrim(requester_program_label)) <= 160
  ),
  ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS revoked_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS revoked_reason text CHECK (
    revoked_reason IS NULL OR char_length(btrim(revoked_reason)) <= 300
  ),
  ADD COLUMN IF NOT EXISTS replaced_by_invite_id uuid REFERENCES public.staff_activation_invites(id) ON DELETE SET NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.staff_activation_invites'::regclass
      AND conname = 'staff_activation_invites_practicante_requires_supervisor'
  ) THEN
    ALTER TABLE public.staff_activation_invites
      ADD CONSTRAINT staff_activation_invites_practicante_requires_supervisor
      CHECK (
        request_status IN ('rejected', 'replacement_requested')
        OR staff_tier <> 'practicante_5to'
        OR supervisor_user_id IS NOT NULL
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_staff_invites_institution_created
  ON public.staff_activation_invites (institution_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_staff_invites_status_created
  ON public.staff_activation_invites (request_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_staff_invites_email_created
  ON public.staff_activation_invites ((pg_catalog.lower(pg_catalog.btrim(institutional_email))), created_at DESC);

CREATE TABLE IF NOT EXISTS public.staff_invite_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invite_id uuid NOT NULL REFERENCES public.staff_activation_invites(id) ON DELETE CASCADE,
  institution_id uuid REFERENCES public.institutions(id) ON DELETE SET NULL,
  event_type text NOT NULL CHECK (
    event_type IN (
      'requested',
      'approved_and_issued',
      'revoked',
      'replaced',
      'redeemed',
      'replacement_requested'
    )
  ),
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  details text NOT NULL CHECK (char_length(btrim(details)) BETWEEN 2 AND 300),
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now()
);

CREATE INDEX IF NOT EXISTS idx_staff_invite_events_invite_created
  ON public.staff_invite_events (invite_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_staff_invite_events_institution_created
  ON public.staff_invite_events (institution_id, created_at DESC);

ALTER TABLE public.staff_invite_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_invite_events FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.staff_invite_events FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.staff_invite_events TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'staff_invite_events' AND policyname = 'staff_invite_events_select_mined'
  ) THEN
    CREATE POLICY staff_invite_events_select_mined
      ON public.staff_invite_events
      FOR SELECT
      TO authenticated
      USING ((SELECT private.has_staff_role('mined_supervisor'::public.staff_role, NULL)));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'staff_invite_events' AND policyname = 'staff_invite_events_select_director'
  ) THEN
    CREATE POLICY staff_invite_events_select_director
      ON public.staff_invite_events
      FOR SELECT
      TO authenticated
      USING (
        institution_id IS NOT NULL
        AND (SELECT private.has_staff_role('school_director'::public.staff_role, institution_id))
      );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION private.generate_staff_activation_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_alphabet CONSTANT text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_bytes bytea := extensions.gen_random_bytes(8);
  v_code text := '';
  v_idx integer;
BEGIN
  FOR i IN 0..7 LOOP
    v_idx := (pg_catalog.get_byte(v_bytes, i) % 32) + 1;
    v_code := v_code || pg_catalog.substr(v_alphabet, v_idx, 1);
  END LOOP;

  RETURN 'SETU-' || pg_catalog.substr(v_code, 1, 4) || '-' || pg_catalog.substr(v_code, 5, 4);
END;
$$;

REVOKE ALL ON FUNCTION private.generate_staff_activation_code() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.assert_real_institutional_email(p_email text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_email text;
BEGIN
  v_email := pg_catalog.lower(pg_catalog.btrim(COALESCE(p_email, '')));
  IF v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
     OR pg_catalog.char_length(v_email) < 5
     OR pg_catalog.char_length(v_email) > 254 THEN
    RAISE EXCEPTION 'invalid_institutional_email'
      USING ERRCODE = '22023';
  END IF;

  IF v_email LIKE '%@setu.test' THEN
    RAISE EXCEPTION 'fake_test_email_not_allowed'
      USING ERRCODE = '22023';
  END IF;

  RETURN v_email;
END;
$$;

REVOKE ALL ON FUNCTION private.assert_real_institutional_email(text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.issue_bootstrap_staff_invite(
  p_institutional_email text,
  p_role public.staff_role,
  p_institution_id uuid DEFAULT NULL,
  p_staff_tier text DEFAULT 'school_plant',
  p_scope_label text DEFAULT NULL,
  p_full_name text DEFAULT NULL,
  p_supervisor_user_id uuid DEFAULT NULL,
  p_expires_in_hours integer DEFAULT 72
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_email text;
  v_code text;
  v_hash text;
  v_school public.institutions%ROWTYPE;
  v_scope text;
  v_invite_id uuid;
  v_expires_at timestamptz;
BEGIN
  v_email := private.assert_real_institutional_email(p_institutional_email);

  IF p_role = 'school_director'::public.staff_role AND p_institution_id IS NULL THEN
    RAISE EXCEPTION 'director_requires_institution'
      USING ERRCODE = '22023';
  END IF;

  IF p_staff_tier NOT IN (
    'school_plant',
    'external_network',
    'practicante_5to',
    'mined_central',
    'school_director'
  ) THEN
    RAISE EXCEPTION 'invalid_staff_tier'
      USING ERRCODE = '22023';
  END IF;

  IF p_staff_tier = 'practicante_5to' AND NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = p_supervisor_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'practicante_requires_active_supervisor'
      USING ERRCODE = '22023';
  END IF;

  IF p_institution_id IS NOT NULL THEN
    SELECT *
    INTO v_school
    FROM public.institutions i
    WHERE i.id = p_institution_id
      AND i.active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'institution_not_found'
        USING ERRCODE = 'P0002';
    END IF;
  END IF;

  v_scope := NULLIF(pg_catalog.btrim(COALESCE(p_scope_label, '')), '');
  IF v_scope IS NULL THEN
    v_scope := COALESCE(
      v_school.name,
      CASE
        WHEN p_role = 'mined_supervisor'::public.staff_role THEN 'MINED central'
        ELSE 'Red externa nacional'
      END
    );
  END IF;

  v_code := private.generate_staff_activation_code();
  v_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(public.normalize_activation_code(v_code), 'UTF8')),
    'hex'
  );
  v_expires_at := pg_catalog.now() + pg_catalog.make_interval(hours => GREATEST(COALESCE(p_expires_in_hours, 72), 1));

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
    approved_at
  )
  VALUES (
    v_email,
    p_role,
    p_institution_id,
    v_scope,
    v_hash,
    v_expires_at,
    NULLIF(pg_catalog.btrim(COALESCE(p_full_name, '')), ''),
    p_staff_tier,
    p_supervisor_user_id,
    'approved',
    pg_catalog.now()
  )
  RETURNING id INTO v_invite_id;

  INSERT INTO public.staff_invite_events (
    invite_id,
    institution_id,
    event_type,
    details
  )
  VALUES (
    v_invite_id,
    p_institution_id,
    'approved_and_issued',
    'Invitación inicial emitida con correo real'
  );

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'invite_id', v_invite_id,
    'activation_code', v_code,
    'institutional_email', v_email,
    'role', p_role,
    'staff_tier', p_staff_tier,
    'institution_id', p_institution_id,
    'scope_label', v_scope,
    'expires_at', v_expires_at
  );
END;
$$;

REVOKE ALL ON FUNCTION private.issue_bootstrap_staff_invite(text, public.staff_role, uuid, text, text, text, uuid, integer)
  FROM PUBLIC, anon, authenticated;

-- Reemplazar preview_staff_activation_code manteniendo la firma para PostgREST
-- pero exigiendo sesión autenticada con correo verificado e ignorando p_institutional_email.
CREATE OR REPLACE FUNCTION public.preview_staff_activation_code(
  p_activation_code text,
  p_institutional_email text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
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
  v_school public.institutions%ROWTYPE;
  v_next_attempts integer;
  v_locked_until timestamptz;
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
    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'invalid_activation_code'
    );
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
      AND i.request_status = 'approved'
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

  IF v_invite.request_status <> 'approved' THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_not_approved');
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
    'staff_tier', v_invite.staff_tier,
    'supervisor_user_id', v_invite.supervisor_user_id,
    'institution_id', v_invite.institution_id,
    'institution_public_code', v_school.public_code,
    'institution_name', v_school.name,
    'scope_label', v_invite.scope_label,
    'expires_at', v_invite.expires_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.preview_staff_activation_code(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.preview_staff_activation_code(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.redeem_staff_activation_code_with_profile(
  p_activation_code text,
  p_first_name text,
  p_last_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_user_email text;
  v_email_confirmed timestamptz;
  v_first_name text;
  v_last_name text;
  v_norm_code text;
  v_code_hash text;
  v_invite public.staff_activation_invites%ROWTYPE;
  v_active_invite public.staff_activation_invites%ROWTYPE;
  v_other_invite public.staff_activation_invites%ROWTYPE;
  v_school public.institutions%ROWTYPE;
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

  v_first_name := pg_catalog.btrim(COALESCE(p_first_name, ''));
  v_last_name := pg_catalog.btrim(COALESCE(p_last_name, ''));
  IF pg_catalog.char_length(v_first_name) NOT BETWEEN 2 AND 80
     OR pg_catalog.char_length(v_last_name) NOT BETWEEN 2 AND 80 THEN
    RETURN pg_catalog.jsonb_build_object(
      'ok', false,
      'error', 'full_name_required'
    );
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
      AND i.request_status = 'approved'
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

  IF v_invite.request_status <> 'approved' THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'activation_code_not_approved');
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

  IF v_invite.staff_tier = 'practicante_5to' AND NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_invite.supervisor_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'supervisor_inactive_or_missing');
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

  INSERT INTO public.staff_profiles (
    user_id,
    first_name,
    last_name,
    staff_tier,
    supervisor_user_id
  )
  VALUES (
    v_uid,
    v_first_name,
    v_last_name,
    v_invite.staff_tier,
    v_invite.supervisor_user_id
  )
  ON CONFLICT (user_id) DO UPDATE
  SET first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      staff_tier = EXCLUDED.staff_tier,
      supervisor_user_id = COALESCE(EXCLUDED.supervisor_user_id, public.staff_profiles.supervisor_user_id),
      updated_at = pg_catalog.now();

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

  INSERT INTO public.staff_invite_events (
    invite_id,
    institution_id,
    event_type,
    actor_user_id,
    details
  )
  VALUES (
    v_invite.id,
    v_invite.institution_id,
    'redeemed',
    v_uid,
    'Correo verificado, perfil completado y membresía activada'
  );

  IF v_invite.institution_id IS NOT NULL THEN
    SELECT *
    INTO v_school
    FROM public.institutions inst
    WHERE inst.id = v_invite.institution_id;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'membership_id', v_membership_id,
    'role', v_invite.role,
    'staff_tier', v_invite.staff_tier,
    'supervisor_user_id', v_invite.supervisor_user_id,
    'institution_id', v_invite.institution_id,
    'institution_public_code', v_school.public_code,
    'institution_name', v_school.name,
    'scope_label', v_invite.scope_label,
    'first_name', v_first_name,
    'last_name', v_last_name
  );
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_staff_activation_code_with_profile(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.redeem_staff_activation_code_with_profile(text, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.redeem_staff_activation_code(p_activation_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_profile public.staff_profiles%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_profile
  FROM public.staff_profiles sp
  WHERE sp.user_id = v_uid;

  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'error', 'full_name_required');
  END IF;

  RETURN public.redeem_staff_activation_code_with_profile(
    p_activation_code,
    v_profile.first_name,
    v_profile.last_name
  );
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_staff_activation_code(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.redeem_staff_activation_code(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_my_staff_availability_and_notices(
  p_is_available boolean,
  p_notify_new_alerts boolean,
  p_notify_new_messages boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_profile public.staff_profiles%ROWTYPE;
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
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'forbidden_staff_membership_required'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.staff_profiles
  SET is_available = COALESCE(p_is_available, is_available),
      notify_new_alerts = COALESCE(p_notify_new_alerts, notify_new_alerts),
      notify_new_messages = COALESCE(p_notify_new_messages, notify_new_messages),
      updated_at = pg_catalog.now()
  WHERE user_id = v_uid
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'staff_profile_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'user_id', v_profile.user_id,
    'is_available', v_profile.is_available,
    'notify_new_alerts', v_profile.notify_new_alerts,
    'notify_new_messages', v_profile.notify_new_messages,
    'updated_at', v_profile.updated_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.update_my_staff_availability_and_notices(boolean, boolean, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_my_staff_availability_and_notices(boolean, boolean, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.request_staff_activation_invite(
  p_institutional_email text,
  p_role public.staff_role,
  p_institution_id uuid DEFAULT NULL,
  p_staff_tier text DEFAULT 'school_plant',
  p_full_name text DEFAULT NULL,
  p_requester_program_label text DEFAULT NULL,
  p_supervisor_user_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_email text;
  v_is_mined boolean := false;
  v_is_director boolean := false;
  v_school public.institutions%ROWTYPE;
  v_scope text;
  v_invite_id uuid;
  v_placeholder_hash text;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

  v_email := private.assert_real_institutional_email(p_institutional_email);

  v_is_mined := private.has_staff_role('mined_supervisor'::public.staff_role, NULL);
  IF NOT v_is_mined THEN
    v_is_director := p_institution_id IS NOT NULL
      AND private.has_staff_role('school_director'::public.staff_role, p_institution_id);
    IF NOT v_is_director THEN
      RAISE EXCEPTION 'forbidden_invite_requester_required'
        USING ERRCODE = '42501';
    END IF;

    IF p_role <> 'counseling_desk'::public.staff_role
       OR p_staff_tier <> 'school_plant'
       OR p_supervisor_user_id IS NOT NULL THEN
      RAISE EXCEPTION 'forbidden_director_plant_only'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  IF p_role = 'school_director'::public.staff_role AND p_institution_id IS NULL THEN
    RAISE EXCEPTION 'director_requires_institution'
      USING ERRCODE = '22023';
  END IF;

  IF p_staff_tier NOT IN (
    'school_plant',
    'external_network',
    'practicante_5to',
    'mined_central',
    'school_director'
  ) THEN
    RAISE EXCEPTION 'invalid_staff_tier'
      USING ERRCODE = '22023';
  END IF;

  IF p_staff_tier = 'practicante_5to' AND NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = p_supervisor_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'practicante_requires_active_supervisor'
      USING ERRCODE = '22023';
  END IF;

  IF p_institution_id IS NOT NULL THEN
    SELECT *
    INTO v_school
    FROM public.institutions i
    WHERE i.id = p_institution_id
      AND i.active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'institution_not_found'
        USING ERRCODE = 'P0002';
    END IF;
  END IF;

  v_scope := COALESCE(
    v_school.name,
    CASE
      WHEN p_role = 'mined_supervisor'::public.staff_role THEN 'MINED central'
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
    p_institution_id,
    v_scope,
    v_placeholder_hash,
    pg_catalog.now() + interval '14 days',
    NULLIF(pg_catalog.btrim(COALESCE(p_full_name, '')), ''),
    p_staff_tier,
    p_supervisor_user_id,
    'pending_approval',
    v_uid,
    NULLIF(pg_catalog.btrim(COALESCE(p_requester_program_label, '')), '')
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
    p_institution_id,
    'requested',
    v_uid,
    CASE
      WHEN v_is_director THEN 'Solicitud de alta de planta registrada por Dirección'
      ELSE 'Solicitud de invitación registrada para aprobación MINED'
    END
  );

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'invite_id', v_invite_id,
    'request_status', 'pending_approval',
    'institutional_email', v_email,
    'role', p_role,
    'staff_tier', p_staff_tier,
    'institution_id', p_institution_id,
    'scope_label', v_scope
  );
END;
$$;

REVOKE ALL ON FUNCTION public.request_staff_activation_invite(text, public.staff_role, uuid, text, text, text, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_staff_activation_invite(text, public.staff_role, uuid, text, text, text, uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.issue_staff_activation_invite(
  p_institutional_email text DEFAULT NULL,
  p_role public.staff_role DEFAULT NULL,
  p_institution_id uuid DEFAULT NULL,
  p_staff_tier text DEFAULT NULL,
  p_scope_label text DEFAULT NULL,
  p_full_name text DEFAULT NULL,
  p_supervisor_user_id uuid DEFAULT NULL,
  p_expires_in_hours integer DEFAULT 72,
  p_pending_invite_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_email text;
  v_role public.staff_role;
  v_inst_id uuid;
  v_tier text;
  v_supervisor uuid;
  v_full_name text;
  v_scope text;
  v_school public.institutions%ROWTYPE;
  v_existing public.staff_activation_invites%ROWTYPE;
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

  IF p_pending_invite_id IS NOT NULL THEN
    SELECT *
    INTO v_existing
    FROM public.staff_activation_invites i
    WHERE i.id = p_pending_invite_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'invite_not_found'
        USING ERRCODE = 'P0002';
    END IF;

    IF v_existing.revoked_at IS NOT NULL OR v_existing.redeemed_at IS NOT NULL THEN
      RAISE EXCEPTION 'invite_not_approvable'
        USING ERRCODE = '22023';
    END IF;

    v_email := COALESCE(
      CASE WHEN p_institutional_email IS NOT NULL THEN private.assert_real_institutional_email(p_institutional_email) ELSE NULL END,
      private.assert_real_institutional_email(v_existing.institutional_email)
    );
    v_role := COALESCE(p_role, v_existing.role);
    v_inst_id := COALESCE(p_institution_id, v_existing.institution_id);
    v_tier := COALESCE(NULLIF(pg_catalog.btrim(COALESCE(p_staff_tier, '')), ''), v_existing.staff_tier);
    v_supervisor := COALESCE(p_supervisor_user_id, v_existing.supervisor_user_id);
    v_full_name := COALESCE(NULLIF(pg_catalog.btrim(COALESCE(p_full_name, '')), ''), v_existing.full_name);
    v_scope := COALESCE(NULLIF(pg_catalog.btrim(COALESCE(p_scope_label, '')), ''), v_existing.scope_label);
  ELSE
    v_email := private.assert_real_institutional_email(p_institutional_email);
    IF p_role IS NULL THEN
      RAISE EXCEPTION 'role_required'
        USING ERRCODE = '22023';
    END IF;
    v_role := p_role;
    v_inst_id := p_institution_id;
    v_tier := COALESCE(NULLIF(pg_catalog.btrim(COALESCE(p_staff_tier, '')), ''), 'school_plant');
    v_supervisor := p_supervisor_user_id;
    v_full_name := NULLIF(pg_catalog.btrim(COALESCE(p_full_name, '')), '');
    v_scope := NULLIF(pg_catalog.btrim(COALESCE(p_scope_label, '')), '');
  END IF;

  IF v_role = 'school_director'::public.staff_role AND v_inst_id IS NULL THEN
    RAISE EXCEPTION 'director_requires_institution'
      USING ERRCODE = '22023';
  END IF;

  IF v_tier NOT IN (
    'school_plant',
    'external_network',
    'practicante_5to',
    'mined_central',
    'school_director'
  ) THEN
    RAISE EXCEPTION 'invalid_staff_tier'
      USING ERRCODE = '22023';
  END IF;

  IF v_tier = 'practicante_5to' AND NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_supervisor
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'practicante_requires_active_supervisor'
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

  IF v_scope IS NULL THEN
    v_scope := COALESCE(
      v_school.name,
      CASE
        WHEN v_role = 'mined_supervisor'::public.staff_role THEN 'MINED central'
        ELSE 'Red externa nacional'
      END
    );
  END IF;

  v_code := private.generate_staff_activation_code();
  v_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(public.normalize_activation_code(v_code), 'UTF8')),
    'hex'
  );
  v_expires_at := pg_catalog.now() + pg_catalog.make_interval(hours => GREATEST(COALESCE(p_expires_in_hours, 72), 1));

  IF p_pending_invite_id IS NOT NULL THEN
    UPDATE public.staff_activation_invites
    SET institutional_email = v_email,
        role = v_role,
        institution_id = v_inst_id,
        scope_label = v_scope,
        full_name = v_full_name,
        staff_tier = v_tier,
        supervisor_user_id = v_supervisor,
        verifier_hash = v_hash,
        expires_at = v_expires_at,
        failed_attempts = 0,
        locked_until = NULL,
        issued_by = v_uid,
        approved_by = v_uid,
        approved_at = pg_catalog.now(),
        request_status = 'approved'
    WHERE id = v_existing.id
    RETURNING id INTO v_invite_id;
  ELSE
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
      v_supervisor,
      'approved',
      v_uid,
      v_uid,
      pg_catalog.now()
    )
    RETURNING id INTO v_invite_id;
  END IF;

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
    'Invitación aprobada y código individual emitido por MINED'
  );

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'invite_id', v_invite_id,
    'activation_code', v_code,
    'institutional_email', v_email,
    'role', v_role,
    'staff_tier', v_tier,
    'institution_id', v_inst_id,
    'scope_label', v_scope,
    'expires_at', v_expires_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.issue_staff_activation_invite(text, public.staff_role, uuid, text, text, text, uuid, integer, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.issue_staff_activation_invite(text, public.staff_role, uuid, text, text, text, uuid, integer, uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.revoke_staff_activation_invite(
  p_invite_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_reason text;
  v_invite public.staff_activation_invites%ROWTYPE;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('mined_supervisor'::public.staff_role, NULL) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  v_reason := COALESCE(
    NULLIF(pg_catalog.btrim(COALESCE(p_reason, '')), ''),
    'Invitación revocada por MINED'
  );
  IF pg_catalog.char_length(v_reason) > 300 THEN
    RAISE EXCEPTION 'invalid_revocation_reason'
      USING ERRCODE = '22023';
  END IF;

  SELECT *
  INTO v_invite
  FROM public.staff_activation_invites i
  WHERE i.id = p_invite_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_invite.redeemed_at IS NOT NULL THEN
    RAISE EXCEPTION 'invite_already_redeemed'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.staff_activation_invites
  SET revoked_at = COALESCE(revoked_at, pg_catalog.now()),
      revoked_by = v_uid,
      revoked_reason = v_reason,
      request_status = CASE
        WHEN request_status IN ('pending_approval', 'replacement_requested') THEN 'rejected'
        ELSE request_status
      END
  WHERE id = v_invite.id;

  INSERT INTO public.staff_invite_events (
    invite_id,
    institution_id,
    event_type,
    actor_user_id,
    details
  )
  VALUES (
    v_invite.id,
    v_invite.institution_id,
    'revoked',
    v_uid,
    v_reason
  );

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'invite_id', v_invite.id,
    'revoked_at', pg_catalog.now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_staff_activation_invite(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.revoke_staff_activation_invite(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.replace_staff_activation_invite(
  p_invite_id uuid,
  p_new_institutional_email text DEFAULT NULL,
  p_expires_in_hours integer DEFAULT 72,
  p_reason text DEFAULT 'Reposición autorizada por MINED'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_invite public.staff_activation_invites%ROWTYPE;
  v_email text;
  v_reason text;
  v_code text;
  v_hash text;
  v_new_id uuid;
  v_expires_at timestamptz;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.has_staff_role('mined_supervisor'::public.staff_role, NULL) THEN
    RAISE EXCEPTION 'forbidden_mined_supervisor_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_invite
  FROM public.staff_activation_invites i
  WHERE i.id = p_invite_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invite_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_invite.redeemed_at IS NOT NULL THEN
    RAISE EXCEPTION 'invite_already_redeemed'
      USING ERRCODE = '22023';
  END IF;

  v_email := COALESCE(
    CASE WHEN p_new_institutional_email IS NOT NULL THEN private.assert_real_institutional_email(p_new_institutional_email) ELSE NULL END,
    private.assert_real_institutional_email(v_invite.institutional_email)
  );
  v_reason := COALESCE(
    NULLIF(pg_catalog.btrim(COALESCE(p_reason, '')), ''),
    'Reposición autorizada por MINED'
  );
  IF pg_catalog.char_length(v_reason) > 300 THEN
    RAISE EXCEPTION 'invalid_replacement_reason'
      USING ERRCODE = '22023';
  END IF;

  IF v_invite.staff_tier = 'practicante_5to' AND NOT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = v_invite.supervisor_user_id
      AND sm.role = 'counseling_desk'::public.staff_role
      AND sm.active = true
      AND sm.revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'practicante_requires_active_supervisor'
      USING ERRCODE = '22023';
  END IF;

  v_code := private.generate_staff_activation_code();
  v_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(public.normalize_activation_code(v_code), 'UTF8')),
    'hex'
  );
  v_expires_at := pg_catalog.now() + pg_catalog.make_interval(hours => GREATEST(COALESCE(p_expires_in_hours, 72), 1));

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
    requester_program_label,
    approved_by,
    approved_at
  )
  VALUES (
    v_email,
    v_invite.role,
    v_invite.institution_id,
    v_invite.scope_label,
    v_hash,
    v_expires_at,
    v_uid,
    v_invite.full_name,
    v_invite.staff_tier,
    v_invite.supervisor_user_id,
    'approved',
    COALESCE(v_invite.requested_by, v_uid),
    v_invite.requester_program_label,
    v_uid,
    pg_catalog.now()
  )
  RETURNING id INTO v_new_id;

  UPDATE public.staff_activation_invites
  SET revoked_at = COALESCE(revoked_at, pg_catalog.now()),
      revoked_by = COALESCE(revoked_by, v_uid),
      revoked_reason = COALESCE(revoked_reason, v_reason),
      replaced_by_invite_id = v_new_id
  WHERE id = v_invite.id;

  INSERT INTO public.staff_invite_events (
    invite_id,
    institution_id,
    event_type,
    actor_user_id,
    details
  )
  VALUES
    (
      v_invite.id,
      v_invite.institution_id,
      'replaced',
      v_uid,
      v_reason
    ),
    (
      v_new_id,
      v_invite.institution_id,
      'approved_and_issued',
      v_uid,
      'Código emitido por reposición autorizada'
    );

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'replaced_invite_id', v_invite.id,
    'invite_id', v_new_id,
    'activation_code', v_code,
    'institutional_email', v_email,
    'role', v_invite.role,
    'staff_tier', v_invite.staff_tier,
    'institution_id', v_invite.institution_id,
    'scope_label', v_invite.scope_label,
    'expires_at', v_expires_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.replace_staff_activation_invite(uuid, text, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.replace_staff_activation_invite(uuid, text, integer, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.request_staff_invite_replacement(
  p_institutional_email text,
  p_reason_code text,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_email text;
  v_notes text;
  v_prior public.staff_activation_invites%ROWTYPE;
  v_target_id uuid;
  v_reason_text text;
  v_placeholder_hash text;
BEGIN
  v_uid := (SELECT auth.uid());
  v_email := private.assert_real_institutional_email(p_institutional_email);

  IF p_reason_code NOT IN ('lost_code', 'expired_code', 'wrong_email') THEN
    RAISE EXCEPTION 'invalid_replacement_reason_code'
      USING ERRCODE = '22023';
  END IF;

  v_notes := NULLIF(pg_catalog.btrim(COALESCE(p_notes, '')), '');
  IF v_notes IS NOT NULL AND pg_catalog.char_length(v_notes) > 220 THEN
    RAISE EXCEPTION 'invalid_notes'
      USING ERRCODE = '22023';
  END IF;

  v_reason_text := CASE p_reason_code
    WHEN 'lost_code' THEN 'Reposición solicitada: código extraviado o no recibido'
    WHEN 'expired_code' THEN 'Reposición solicitada: código vencido'
    ELSE 'Reposición solicitada: código emitido a otro correo'
  END;
  IF v_notes IS NOT NULL THEN
    v_reason_text := pg_catalog.left(v_reason_text || ' — ' || v_notes, 300);
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('staff_replacement:' || v_email));

  SELECT *
  INTO v_prior
  FROM public.staff_activation_invites i
  WHERE pg_catalog.lower(pg_catalog.btrim(i.institutional_email)) = v_email
    AND i.redeemed_at IS NULL
  ORDER BY i.created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    v_target_id := v_prior.id;
    UPDATE public.staff_activation_invites
    SET request_status = CASE
      WHEN revoked_at IS NULL AND request_status = 'approved' THEN 'replacement_requested'
      ELSE request_status
    END
    WHERE id = v_prior.id;
  ELSE
    v_placeholder_hash := pg_catalog.encode(extensions.gen_random_bytes(32), 'hex');
    INSERT INTO public.staff_activation_invites (
      institutional_email,
      role,
      institution_id,
      scope_label,
      verifier_hash,
      expires_at,
      staff_tier,
      request_status,
      requested_by,
      requester_program_label
    )
    VALUES (
      v_email,
      'counseling_desk'::public.staff_role,
      NULL,
      'Solicitud de reposición de acceso',
      v_placeholder_hash,
      pg_catalog.now() + interval '14 days',
      'external_network',
      'replacement_requested',
      v_uid,
      'Ayuda con mi acceso'
    )
    RETURNING id INTO v_target_id;
  END IF;

  INSERT INTO public.staff_invite_events (
    invite_id,
    institution_id,
    event_type,
    actor_user_id,
    details
  )
  VALUES (
    v_target_id,
    v_prior.institution_id,
    'replacement_requested',
    v_uid,
    v_reason_text
  );

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'message', 'Si existe una incorporación pendiente para ese correo, el equipo autorizado revisará la solicitud y enviará un nuevo código privado.'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.request_staff_invite_replacement(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_staff_invite_replacement(text, text, text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.list_staff_activation_invites(
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
  v_is_mined boolean := false;
  v_is_director boolean := false;
  v_rows jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required'
      USING ERRCODE = '42501';
  END IF;

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
    RAISE EXCEPTION 'forbidden_invite_viewer_required'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'invite_id', i.id,
        'institutional_email', i.institutional_email,
        'full_name', i.full_name,
        'role', i.role,
        'staff_tier', i.staff_tier,
        'institution_id', i.institution_id,
        'institution_name', inst.name,
        'scope_label', i.scope_label,
        'request_status', i.request_status,
        'requester_program_label', i.requester_program_label,
        'supervisor_user_id', i.supervisor_user_id,
        'supervisor_name', NULLIF(pg_catalog.btrim(COALESCE(sup.first_name, '') || ' ' || COALESCE(sup.last_name, '')), ''),
        'requested_by', i.requested_by,
        'approved_by', i.approved_by,
        'approved_at', i.approved_at,
        'expires_at', i.expires_at,
        'revoked_at', i.revoked_at,
        'revoked_by', i.revoked_by,
        'revoked_reason', i.revoked_reason,
        'redeemed_at', i.redeemed_at,
        'replaced_by_invite_id', i.replaced_by_invite_id,
        'created_at', i.created_at,
        'events', COALESCE(
          (
            SELECT pg_catalog.jsonb_agg(
              pg_catalog.jsonb_build_object(
                'id', e.id,
                'event_type', e.event_type,
                'actor_user_id', e.actor_user_id,
                'details', e.details,
                'created_at', e.created_at
              )
              ORDER BY e.created_at DESC
            )
            FROM public.staff_invite_events e
            WHERE e.invite_id = i.id
          ),
          '[]'::jsonb
        )
      )
      ORDER BY i.created_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM public.staff_activation_invites i
  LEFT JOIN public.institutions inst ON inst.id = i.institution_id
  LEFT JOIN public.staff_profiles sup ON sup.user_id = i.supervisor_user_id
  WHERE (
    v_is_mined AND (p_institution_id IS NULL OR i.institution_id = p_institution_id)
  ) OR (
    NOT v_is_mined
    AND v_is_director
    AND i.institution_id IS NOT NULL
    AND (p_institution_id IS NULL OR i.institution_id = p_institution_id)
    AND private.has_staff_role('school_director'::public.staff_role, i.institution_id)
  );

  RETURN v_rows;
END;
$$;

REVOKE ALL ON FUNCTION public.list_staff_activation_invites(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_staff_activation_invites(uuid) TO authenticated;
