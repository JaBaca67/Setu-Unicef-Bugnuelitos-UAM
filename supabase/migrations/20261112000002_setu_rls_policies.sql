-- Migración 2: Esquema privado de autorización, privilegios mínimos y políticas RLS.
-- Garantiza aislamiento entre instituciones y separación estricta de D3 (ámbito clínico).

-- ---------------------------------------------------------------------------
-- 1. Esquema privado y funciones auxiliares SECURITY DEFINER
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon;
GRANT USAGE ON SCHEMA private TO authenticated;

CREATE OR REPLACE FUNCTION private.has_staff_role(
  p_role public.staff_role,
  p_institution_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.staff_memberships sm
    WHERE sm.user_id = (SELECT auth.uid())
      AND sm.active = true
      AND sm.revoked_at IS NULL
      AND sm.role = p_role
      AND (
        p_institution_id IS NULL
        OR sm.institution_id IS NULL
        OR sm.institution_id = p_institution_id
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.is_assigned_counselor(p_case_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.cases c
    JOIN public.staff_memberships sm
      ON sm.user_id = (SELECT auth.uid())
     AND sm.role = 'counseling_desk'::public.staff_role
     AND sm.active = true
     AND sm.revoked_at IS NULL
     AND (sm.institution_id IS NULL OR sm.institution_id = c.institution_id)
    WHERE c.id = p_case_id
      AND c.assigned_counselor_id = (SELECT auth.uid())
  );
$$;

REVOKE ALL ON FUNCTION private.has_staff_role(public.staff_role, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.has_staff_role(public.staff_role, uuid) TO authenticated;

REVOKE ALL ON FUNCTION private.is_assigned_counselor(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.is_assigned_counselor(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. Privilegios mínimos y habilitación forzada de RLS en todas las tablas
-- ---------------------------------------------------------------------------

REVOKE ALL ON TABLE
  public.institutions,
  public.institution_access_verifiers,
  public.staff_memberships,
  public.cases,
  public.case_private_capabilities,
  public.case_events,
  public.inbound_operations,
  public.case_narratives,
  public.case_messages,
  public.case_internal_notes,
  public.case_action_sheets,
  public.school_actions,
  public.editorial_resources,
  public.help_resources
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.institutions TO anon, authenticated;
GRANT SELECT ON public.editorial_resources, public.help_resources TO anon, authenticated;
GRANT SELECT ON public.staff_memberships, public.cases, public.case_events, public.case_narratives TO authenticated;
GRANT SELECT, INSERT ON public.case_messages, public.case_internal_notes, public.case_action_sheets, public.school_actions TO authenticated;

ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institutions FORCE ROW LEVEL SECURITY;

ALTER TABLE public.institution_access_verifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.institution_access_verifiers FORCE ROW LEVEL SECURITY;

ALTER TABLE public.staff_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_memberships FORCE ROW LEVEL SECURITY;

ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cases FORCE ROW LEVEL SECURITY;

ALTER TABLE public.case_private_capabilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_private_capabilities FORCE ROW LEVEL SECURITY;

ALTER TABLE public.case_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_events FORCE ROW LEVEL SECURITY;

ALTER TABLE public.inbound_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inbound_operations FORCE ROW LEVEL SECURITY;

ALTER TABLE public.case_narratives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_narratives FORCE ROW LEVEL SECURITY;

ALTER TABLE public.case_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_messages FORCE ROW LEVEL SECURITY;

ALTER TABLE public.case_internal_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_internal_notes FORCE ROW LEVEL SECURITY;

ALTER TABLE public.case_action_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_action_sheets FORCE ROW LEVEL SECURITY;

ALTER TABLE public.school_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_actions FORCE ROW LEVEL SECURITY;

ALTER TABLE public.editorial_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.editorial_resources FORCE ROW LEVEL SECURITY;

ALTER TABLE public.help_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.help_resources FORCE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- 3. Políticas D1 · Colegios, verificadores y membresías
-- ---------------------------------------------------------------------------

CREATE POLICY institutions_public_read_active
  ON public.institutions
  FOR SELECT
  TO anon, authenticated
  USING (active = true);

CREATE POLICY institution_access_verifiers_deny_all
  ON public.institution_access_verifiers
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE POLICY staff_memberships_read_own
  ON public.staff_memberships
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ---------------------------------------------------------------------------
-- 4. Políticas D2 · Casos mínimos, capacidades, eventos e idempotencia
-- ---------------------------------------------------------------------------

CREATE POLICY cases_staff_read
  ON public.cases
  FOR SELECT
  TO authenticated
  USING (
    (SELECT private.has_staff_role('mined_supervisor'::public.staff_role, institution_id))
    OR (
      (SELECT private.has_staff_role('school_director'::public.staff_role, institution_id))
      AND NOT involves_staff
    )
    OR (SELECT private.is_assigned_counselor(id))
  );

CREATE POLICY case_private_capabilities_deny_all
  ON public.case_private_capabilities
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE POLICY case_events_staff_read
  ON public.case_events
  FOR SELECT
  TO authenticated
  USING (
    (SELECT private.has_staff_role('mined_supervisor'::public.staff_role, institution_id))
    OR (
      (SELECT private.has_staff_role('school_director'::public.staff_role, institution_id))
      AND EXISTS (
        SELECT 1
        FROM public.cases c
        WHERE c.id = case_events.case_id
          AND c.institution_id = case_events.institution_id
          AND NOT c.involves_staff
      )
    )
    OR (SELECT private.is_assigned_counselor(case_id))
  );

CREATE POLICY inbound_operations_deny_all
  ON public.inbound_operations
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

-- ---------------------------------------------------------------------------
-- 5. Políticas D3 · Ámbito clínico reservado (solo Mesa de Escucha asignada)
-- ---------------------------------------------------------------------------

CREATE POLICY case_narratives_counselor_read
  ON public.case_narratives
  FOR SELECT
  TO authenticated
  USING ((SELECT private.is_assigned_counselor(case_id)));

CREATE POLICY case_messages_counselor_read
  ON public.case_messages
  FOR SELECT
  TO authenticated
  USING ((SELECT private.is_assigned_counselor(case_id)));

CREATE POLICY case_messages_counselor_insert
  ON public.case_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT private.is_assigned_counselor(case_id))
    AND sender_role = 'counseling_desk'::public.case_message_sender
    AND sender_user_id = (SELECT auth.uid())
  );

CREATE POLICY case_internal_notes_counselor_read
  ON public.case_internal_notes
  FOR SELECT
  TO authenticated
  USING ((SELECT private.is_assigned_counselor(case_id)));

CREATE POLICY case_internal_notes_counselor_insert
  ON public.case_internal_notes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT private.is_assigned_counselor(case_id))
    AND author_user_id = (SELECT auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 6. Políticas D4 · Actuación institucional (fichas y pasos escolares)
-- ---------------------------------------------------------------------------

CREATE POLICY case_action_sheets_staff_read
  ON public.case_action_sheets
  FOR SELECT
  TO authenticated
  USING (
    (SELECT private.has_staff_role('mined_supervisor'::public.staff_role, institution_id))
    OR (SELECT private.is_assigned_counselor(case_id))
    OR (
      (SELECT private.has_staff_role('school_director'::public.staff_role, institution_id))
      AND NOT omit_school_due_to_conflict
    )
  );

CREATE POLICY case_action_sheets_counselor_insert
  ON public.case_action_sheets
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT private.is_assigned_counselor(case_id))
    AND issued_by = (SELECT auth.uid())
  );

CREATE POLICY school_actions_staff_read
  ON public.school_actions
  FOR SELECT
  TO authenticated
  USING (
    (SELECT private.has_staff_role('mined_supervisor'::public.staff_role, institution_id))
    OR (SELECT private.is_assigned_counselor(case_id))
    OR (
      (SELECT private.has_staff_role('school_director'::public.staff_role, institution_id))
      AND EXISTS (
        SELECT 1
        FROM public.cases c
        WHERE c.id = school_actions.case_id
          AND c.institution_id = school_actions.institution_id
          AND NOT c.involves_staff
      )
    )
  );

CREATE POLICY school_actions_director_insert
  ON public.school_actions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT private.has_staff_role('school_director'::public.staff_role, institution_id))
    AND recorded_by = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.cases c
      WHERE c.id = school_actions.case_id
        AND c.institution_id = school_actions.institution_id
        AND NOT c.involves_staff
    )
  );

-- ---------------------------------------------------------------------------
-- 7. Políticas D8 · Catálogo público (Información y Ayuda)
-- ---------------------------------------------------------------------------

CREATE POLICY editorial_resources_public_read
  ON public.editorial_resources
  FOR SELECT
  TO anon, authenticated
  USING (published = true);

CREATE POLICY help_resources_public_read
  ON public.help_resources
  FOR SELECT
  TO anon, authenticated
  USING (published = true);
