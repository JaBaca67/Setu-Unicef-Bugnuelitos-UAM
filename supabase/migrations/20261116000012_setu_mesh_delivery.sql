-- Solo demo ficticia. No se aplica al remoto desde este bloque.
-- Custodia opaca para puentes sin clave; claves privadas solo en el receptor.
CREATE TABLE public.mesh_recipient_keys (
  key_id text PRIMARY KEY CHECK (key_id ~ '^[0-9a-f]{64}$'),
  owner_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  institution_id uuid REFERENCES public.institutions(id) ON DELETE CASCADE,
  public_key_base64 text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  refreshed_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.mesh_envelope_custody (
  packet_id text PRIMARY KEY CHECK (packet_id ~ '^[0-9a-f]{32}$'),
  recipient_key_id text NOT NULL REFERENCES public.mesh_recipient_keys(key_id),
  envelope jsonb NOT NULL CHECK (pg_column_size(envelope) <= 8192),
  fingerprint text NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);
CREATE INDEX mesh_envelope_recipient_pending_idx
  ON public.mesh_envelope_custody(recipient_key_id, received_at) WHERE completed_at IS NULL;
ALTER TABLE public.mesh_recipient_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesh_recipient_keys FORCE ROW LEVEL SECURITY;
ALTER TABLE public.mesh_envelope_custody ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesh_envelope_custody FORCE ROW LEVEL SECURITY;
-- Sin acceso directo: incluso SELECT requiere RPC y comprobación del rol vigente.
REVOKE ALL ON public.mesh_recipient_keys, public.mesh_envelope_custody FROM PUBLIC, anon, authenticated;

CREATE FUNCTION private.mesh_key_owner_active(p_owner uuid, p_institution uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.staff_memberships sm
    WHERE sm.user_id = p_owner AND sm.active AND sm.revoked_at IS NULL
      AND sm.institution_id IS NOT DISTINCT FROM p_institution
      AND (sm.role IN ('counseling_desk', 'mined_supervisor')
        OR (sm.role = 'school_director' AND p_institution IS NOT NULL))
  );
$$;
REVOKE ALL ON FUNCTION private.mesh_key_owner_active(uuid, uuid) FROM PUBLIC, anon, authenticated;

CREATE FUNCTION public.register_mesh_recipient(p_public_school_code text, p_public_key_base64 text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_uid uuid := (SELECT auth.uid());
  v_school uuid;
  v_key bytea;
  v_id text;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication_required' USING ERRCODE = '42501'; END IF;
  IF p_public_school_code IS NOT NULL THEN
    SELECT id INTO v_school FROM public.institutions
      WHERE public_code = public.normalize_school_code(p_public_school_code) AND active;
    IF NOT FOUND THEN RAISE EXCEPTION 'school_not_found_or_inactive' USING ERRCODE = '22023'; END IF;
  END IF;
  IF NOT private.mesh_key_owner_active(v_uid, v_school) THEN
    RAISE EXCEPTION 'forbidden_mesh_recipient_scope' USING ERRCODE = '42501';
  END IF;
  IF p_public_key_base64 IS NULL OR length(p_public_key_base64) <> 44 THEN
    RAISE EXCEPTION 'invalid_mesh_public_key' USING ERRCODE = '22023';
  END IF;
  v_key := pg_catalog.decode(p_public_key_base64, 'base64');
  IF length(v_key) <> 32 OR v_key = pg_catalog.decode(repeat('00', 32), 'hex') THEN
    RAISE EXCEPTION 'invalid_mesh_public_key' USING ERRCODE = '22023';
  END IF;
  v_id := pg_catalog.encode(pg_catalog.sha256(v_key), 'hex');
  INSERT INTO public.mesh_recipient_keys(key_id, owner_user_id, institution_id, public_key_base64)
  VALUES (v_id, v_uid, v_school, pg_catalog.encode(v_key, 'base64'))
  ON CONFLICT (key_id) DO UPDATE SET refreshed_at = pg_catalog.now()
    WHERE mesh_recipient_keys.owner_user_id = v_uid
      AND mesh_recipient_keys.institution_id IS NOT DISTINCT FROM v_school;
  IF NOT FOUND THEN RAISE EXCEPTION 'mesh_key_scope_conflict' USING ERRCODE = '42501'; END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.register_mesh_recipient(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_mesh_recipient(text, text) TO authenticated;

CREATE FUNCTION public.list_mesh_recipient_public_keys(p_public_school_code text, p_involves_staff boolean)
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT COALESCE(pg_catalog.jsonb_agg(keys.public_key_base64 ORDER BY keys.key_id), '[]'::jsonb)
  FROM (
    SELECT DISTINCT k.key_id, k.public_key_base64
    FROM public.mesh_recipient_keys k
    JOIN public.institutions i ON i.public_code = public.normalize_school_code(p_public_school_code) AND i.active
    JOIN public.staff_memberships sm ON sm.user_id = k.owner_user_id
      AND sm.institution_id IS NOT DISTINCT FROM k.institution_id
      AND sm.active AND sm.revoked_at IS NULL
    WHERE
      -- Planta y Dirección solo reciben avisos sin conflicto de su propio centro.
      (NOT COALESCE(p_involves_staff, true) AND k.institution_id = i.id
        AND sm.role IN ('school_director', 'counseling_desk'))
      OR (k.institution_id = i.id AND sm.role = 'mined_supervisor')
      OR (k.institution_id IS NULL AND sm.role = 'mined_supervisor')
      OR (k.institution_id IS NULL AND sm.role = 'counseling_desk'
        AND private.is_school_external_coverage_active(i.id)
        AND EXISTS (SELECT 1 FROM public.external_counselor_school_assignments a
          WHERE a.institution_id = i.id AND a.counselor_user_id = sm.user_id
            AND a.active AND a.revoked_at IS NULL))
  ) keys;
$$;
REVOKE ALL ON FUNCTION public.list_mesh_recipient_public_keys(text, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_mesh_recipient_public_keys(text, boolean) TO anon, authenticated;

CREATE FUNCTION public.relay_mesh_envelope(p_envelope jsonb)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_packet text;
  v_key_id text;
  v_canonical jsonb;
  v_fingerprint text;
BEGIN
  IF p_envelope IS NULL OR jsonb_typeof(p_envelope) <> 'object'
    OR octet_length(p_envelope::text) > 4096
    OR p_envelope->>'kind' IS DISTINCT FROM 'envelope'
    OR p_envelope->>'v' IS DISTINCT FROM '1'
    OR COALESCE(p_envelope->>'ttl', '') !~ '^[0-5]$' THEN
    RAISE EXCEPTION 'invalid_mesh_envelope' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM jsonb_object_keys(p_envelope) k
    WHERE k NOT IN ('kind', 'v', 'id', 'ttl', 'epk', 'n', 'm', 'c', 'recipient_key')) THEN
    RAISE EXCEPTION 'invalid_mesh_envelope_fields' USING ERRCODE = '22023';
  END IF;
  v_packet := p_envelope->>'id';
  v_key_id := p_envelope->>'recipient_key';
  IF COALESCE(v_packet, '') !~ '^[0-9a-f]{32}$' OR COALESCE(v_key_id, '') !~ '^[0-9a-f]{64}$'
    OR length(decode(COALESCE(p_envelope->>'epk', ''), 'base64')) <> 32
    OR length(decode(COALESCE(p_envelope->>'n', ''), 'base64')) <> 12
    OR length(decode(COALESCE(p_envelope->>'m', ''), 'base64')) <> 16
    OR length(decode(COALESCE(p_envelope->>'c', ''), 'base64')) NOT BETWEEN 1 AND 3000 THEN
    RAISE EXCEPTION 'invalid_mesh_envelope_crypto' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.mesh_recipient_keys k WHERE k.key_id = v_key_id
    AND private.mesh_key_owner_active(k.owner_user_id, k.institution_id)) THEN
    RAISE EXCEPTION 'unknown_mesh_recipient' USING ERRCODE = '42501';
  END IF;
  -- TTL cambia por ruta y nunca forma parte de la identidad del sobre cifrado.
  v_canonical := p_envelope - 'ttl';
  v_fingerprint := encode(sha256(convert_to(v_canonical::text, 'UTF8')), 'hex');
  PERFORM pg_catalog.pg_advisory_xact_lock(hashtext('mesh_packet'), hashtext(v_packet));
  IF EXISTS (SELECT 1 FROM public.mesh_envelope_custody c WHERE c.packet_id = v_packet
    AND c.fingerprint <> v_fingerprint) THEN
    RAISE EXCEPTION 'idempotency_conflict' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.mesh_envelope_custody(packet_id, recipient_key_id, envelope, fingerprint)
    VALUES (v_packet, v_key_id, p_envelope, v_fingerprint) ON CONFLICT (packet_id) DO NOTHING;
END;
$$;
REVOKE ALL ON FUNCTION public.relay_mesh_envelope(jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.relay_mesh_envelope(jsonb) TO anon, authenticated;

CREATE FUNCTION public.list_my_mesh_envelopes()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT COALESCE(jsonb_agg(q.envelope ORDER BY q.received_at), '[]'::jsonb) FROM (
    SELECT c.envelope, c.received_at FROM public.mesh_envelope_custody c
    JOIN public.mesh_recipient_keys k ON k.key_id = c.recipient_key_id
    WHERE k.owner_user_id = (SELECT auth.uid()) AND c.completed_at IS NULL
      AND private.mesh_key_owner_active(k.owner_user_id, k.institution_id)
    ORDER BY c.received_at LIMIT 100
  ) q;
$$;
REVOKE ALL ON FUNCTION public.list_my_mesh_envelopes() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_my_mesh_envelopes() TO authenticated;

CREATE FUNCTION public.complete_mesh_envelope(p_packet_id text, p_client_operation_id text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN RAISE EXCEPTION 'authentication_required' USING ERRCODE = '42501'; END IF;
  UPDATE public.mesh_envelope_custody c SET completed_at = COALESCE(c.completed_at, pg_catalog.now())
  FROM public.mesh_recipient_keys k
  WHERE k.key_id = c.recipient_key_id AND c.packet_id = p_packet_id
    AND k.owner_user_id = (SELECT auth.uid())
    AND private.mesh_key_owner_active(k.owner_user_id, k.institution_id)
    AND EXISTS (SELECT 1 FROM public.inbound_operations io JOIN public.cases ca ON ca.id = io.case_id
      WHERE io.client_operation_id = p_client_operation_id
        AND io.operation_scope = 'student_alert:' || ca.institution_id::text
        AND (k.institution_id IS NULL OR k.institution_id = ca.institution_id));
  -- Un sobre recibido directamente por Nearby puede no haber pasado por custodia.
END;
$$;
REVOKE ALL ON FUNCTION public.complete_mesh_envelope(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_mesh_envelope(text, text) TO authenticated;

-- Conservar contratos públicos existentes; las implementaciones previas quedan
-- privadas. Ambos tamaños de llamada comparten la misma operación por colegio.
ALTER FUNCTION public.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb) SET SCHEMA private;
ALTER FUNCTION public.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb,text) SET SCHEMA private;
REVOKE ALL ON FUNCTION private.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb,text) FROM PUBLIC, anon, authenticated;

ALTER TABLE public.cases ADD COLUMN client_operation_id text;
UPDATE public.cases c SET client_operation_id = io.client_operation_id
FROM public.inbound_operations io WHERE io.case_id = c.id
  AND io.operation_scope = 'student_alert:' || c.institution_id::text;
CREATE UNIQUE INDEX cases_institution_client_operation_idx
  ON public.cases(institution_id, client_operation_id) WHERE client_operation_id IS NOT NULL;

CREATE FUNCTION public.submit_student_alert(
  p_client_operation_id text, p_public_school_code text,
  p_situation_type public.case_situation_type, p_student_role public.student_case_role,
  p_origin public.alert_origin, p_involves_staff boolean, p_declared_at timestamptz,
  p_capability_verifier_hash text, p_narrative_text text, p_location_text text,
  p_approx_date_text text, p_student_piece jsonb, p_installation_verifier_hash text
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_school uuid;
  v_op text := btrim(COALESCE(p_client_operation_id, ''));
  v_cap text := lower(btrim(COALESCE(p_capability_verifier_hash, '')));
  v_existing public.inbound_operations%ROWTYPE;
  v_case public.cases%ROWTYPE;
  v_receipt jsonb;
BEGIN
  IF length(v_op) NOT BETWEEN 8 AND 128 OR v_cap !~ '^[0-9a-f]{64}$'
    OR p_origin IS NULL OR p_origin NOT IN ('online', 'mesh')
    OR p_situation_type IS NULL OR p_student_role IS NULL OR p_declared_at IS NULL
    OR length(COALESCE(p_narrative_text, '')) > 4000
    OR length(COALESCE(p_location_text, '')) > 500
    OR length(COALESCE(p_approx_date_text, '')) > 200
    OR (p_student_piece IS NOT NULL AND jsonb_typeof(p_student_piece) <> 'object')
    OR (p_installation_verifier_hash IS NOT NULL AND p_installation_verifier_hash !~ '^[0-9a-f]{64}$') THEN
    RAISE EXCEPTION 'invalid_student_alert' USING ERRCODE = '22023';
  END IF;
  IF p_origin = 'mesh' AND (NULLIF(btrim(COALESCE(p_narrative_text, '')), '') IS NOT NULL
    OR NULLIF(btrim(COALESCE(p_location_text, '')), '') IS NOT NULL
    OR NULLIF(btrim(COALESCE(p_approx_date_text, '')), '') IS NOT NULL
    OR p_student_piece IS NOT NULL) THEN
    RAISE EXCEPTION 'mesh_origin_cannot_carry_narrative' USING ERRCODE = '22023';
  END IF;
  SELECT id INTO v_school FROM public.institutions
    WHERE public_code = public.normalize_school_code(p_public_school_code) AND active;
  IF NOT FOUND THEN RAISE EXCEPTION 'school_not_found_or_inactive' USING ERRCODE = 'P0002'; END IF;
  PERFORM pg_advisory_xact_lock(hashtext('student_alert:' || v_school::text), hashtext(v_op));
  SELECT * INTO v_existing FROM public.inbound_operations
    WHERE operation_scope = 'student_alert:' || v_school::text AND client_operation_id = v_op;
  IF FOUND THEN
    SELECT * INTO STRICT v_case FROM public.cases WHERE id = v_existing.case_id;
    IF v_case.situation_type IS DISTINCT FROM p_situation_type
      OR v_case.student_role IS DISTINCT FROM p_student_role
      OR v_case.involves_staff IS DISTINCT FROM COALESCE(p_involves_staff, false)
      OR v_case.declared_at IS DISTINCT FROM p_declared_at
      OR NOT EXISTS (SELECT 1 FROM public.case_private_capabilities
        WHERE case_id = v_case.id AND capability_verifier_hash = v_cap) THEN
      RAISE EXCEPTION 'idempotency_conflict' USING ERRCODE = '23505';
    END IF;
    IF v_case.origin <> p_origin THEN
      -- Dos proyecciones de la misma operación: jamás crear otro caso ni
      -- sobrescribir relato/pieza con la proyección mínima del puente.
      RETURN v_existing.receipt_json;
    END IF;
  END IF;
  IF p_installation_verifier_hash IS NULL THEN
    v_receipt := private.submit_student_alert(v_op,p_public_school_code,p_situation_type,p_student_role,
      p_origin,p_involves_staff,p_declared_at,v_cap,p_narrative_text,p_location_text,p_approx_date_text,p_student_piece);
  ELSE
    v_receipt := private.submit_student_alert(v_op,p_public_school_code,p_situation_type,p_student_role,
      p_origin,p_involves_staff,p_declared_at,v_cap,p_narrative_text,p_location_text,p_approx_date_text,
      p_student_piece,p_installation_verifier_hash);
  END IF;
  UPDATE public.cases SET client_operation_id = v_op WHERE id = (v_receipt->>'case_id')::uuid;
  RETURN v_receipt;
END;
$$;
REVOKE ALL ON FUNCTION public.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb,text) TO anon, authenticated;

CREATE FUNCTION public.submit_student_alert(
  p_client_operation_id text, p_public_school_code text,
  p_situation_type public.case_situation_type, p_student_role public.student_case_role,
  p_origin public.alert_origin, p_involves_staff boolean, p_declared_at timestamptz,
  p_capability_verifier_hash text, p_narrative_text text, p_location_text text,
  p_approx_date_text text, p_student_piece jsonb
)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path = '' AS $$
  SELECT public.submit_student_alert(p_client_operation_id,p_public_school_code,p_situation_type,p_student_role,
    p_origin,p_involves_staff,p_declared_at,p_capability_verifier_hash,p_narrative_text,p_location_text,
    p_approx_date_text,p_student_piece,NULL::text);
$$;
REVOKE ALL ON FUNCTION public.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_student_alert(text,text,public.case_situation_type,public.student_case_role,
  public.alert_origin,boolean,timestamptz,text,text,text,text,jsonb) TO anon, authenticated;
