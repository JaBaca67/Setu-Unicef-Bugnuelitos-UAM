-- Migración 1: Esquema estructural de SéTú separado por dominios de confidencialidad (D1, D2, D3, D4, D8).
-- Proyecto: SéTú (Jornada Académica y Social UAM - UNICEF 2026).

-- ---------------------------------------------------------------------------
-- 1. Tipos enumerados del protocolo vigente (ADR 0005 / ADR 0007 / ADR 0013)
-- ---------------------------------------------------------------------------

CREATE TYPE public.staff_role AS ENUM (
  'mined_supervisor',
  'counseling_desk',
  'school_director'
);

CREATE TYPE public.case_situation_type AS ENUM (
  'physical_bullying',
  'verbal_bullying',
  'social_bullying',
  'cyberbullying',
  'sexual_violence',
  'need_to_talk'
);

CREATE TYPE public.student_case_role AS ENUM (
  'victim',
  'solidarity_witness'
);

CREATE TYPE public.alert_origin AS ENUM (
  'online',
  'mesh',
  'teacher_notice'
);

CREATE TYPE public.case_status AS ENUM (
  'received',
  'in_listening',
  'sheet_sent',
  'school_acting',
  'escalated',
  'closed'
);

CREATE TYPE public.school_action_step AS ENUM (
  'identify',
  'notify_direction',
  'notify_family_or_group',
  'accompany',
  'follow_up'
);

CREATE TYPE public.editorial_resource_format AS ENUM (
  'article',
  'video',
  'testimony',
  'guide'
);

CREATE TYPE public.case_message_sender AS ENUM (
  'student',
  'counseling_desk'
);

-- ---------------------------------------------------------------------------
-- 2. D1 · Colegios y personal autorizado
-- ---------------------------------------------------------------------------

CREATE TABLE public.institutions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  public_code text NOT NULL UNIQUE CHECK (public_code ~ '^[A-Z0-9]{6}$'),
  name text NOT NULL CHECK (char_length(trim(name)) BETWEEN 3 AND 160),
  municipality text NOT NULL DEFAULT 'Managua',
  department text NOT NULL DEFAULT 'Managua',
  reference_lat double precision NOT NULL CHECK (reference_lat BETWEEN -90 AND 90),
  reference_lng double precision NOT NULL CHECK (reference_lng BETWEEN -180 AND 180),
  radius_meters integer NOT NULL DEFAULT 150 CHECK (radius_meters BETWEEN 50 AND 2000),
  config_version integer NOT NULL DEFAULT 1 CHECK (config_version >= 1),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.institution_access_verifiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  verifier_hash text NOT NULL CHECK (verifier_hash ~ '^[0-9a-f]{64}$'),
  label text NOT NULL CHECK (char_length(trim(label)) BETWEEN 2 AND 120),
  active boolean NOT NULL DEFAULT true,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.staff_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.staff_role NOT NULL,
  institution_id uuid REFERENCES public.institutions(id) ON DELETE RESTRICT,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  CONSTRAINT staff_memberships_director_requires_institution
    CHECK (role <> 'school_director' OR institution_id IS NOT NULL),
  UNIQUE (user_id, role, institution_id)
);

-- ---------------------------------------------------------------------------
-- 3. D2 · Caso mínimo, capacidades privadas, eventos e idempotencia
-- ---------------------------------------------------------------------------

CREATE TABLE public.cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  institution_id uuid NOT NULL REFERENCES public.institutions(id) ON DELETE RESTRICT,
  reference_code text NOT NULL UNIQUE CHECK (reference_code ~ '^SETU-[A-Z0-9]{4}-[A-Z0-9]{4}$'),
  situation_type public.case_situation_type NOT NULL,
  student_role public.student_case_role,
  origin public.alert_origin NOT NULL,
  status public.case_status NOT NULL DEFAULT 'received',
  human_level smallint CHECK (human_level IN (1, 2, 3)),
  involves_staff boolean NOT NULL DEFAULT false,
  identity_reserved boolean NOT NULL DEFAULT true,
  assigned_counselor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  chat_available_notice boolean NOT NULL DEFAULT false,
  urgent_referral_triggered boolean NOT NULL DEFAULT false,
  concurrency_version integer NOT NULL DEFAULT 1 CHECK (concurrency_version >= 1),
  declared_at timestamptz NOT NULL,
  received_centrally_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  closed_reason text CHECK (closed_reason IS NULL OR char_length(closed_reason) <= 500),
  CONSTRAINT cases_student_role_by_origin CHECK (
    (origin = 'teacher_notice' AND student_role IS NULL)
    OR (origin IN ('online', 'mesh') AND student_role IS NOT NULL)
  ),
  UNIQUE (id, institution_id)
);

CREATE TABLE public.case_private_capabilities (
  case_id uuid PRIMARY KEY REFERENCES public.cases(id) ON DELETE CASCADE,
  capability_verifier_hash text NOT NULL CHECK (capability_verifier_hash ~ '^[0-9a-f]{64}$'),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.case_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL,
  institution_id uuid NOT NULL,
  event_type text NOT NULL CHECK (
    event_type IN (
      'alert_received',
      'teacher_notice_recorded',
      'counselor_assigned',
      'level_assessed',
      'sheet_issued',
      'school_action_recorded',
      'urgent_referral',
      'status_changed'
    )
  ),
  from_status public.case_status,
  to_status public.case_status,
  human_level smallint CHECK (human_level IN (1, 2, 3)),
  actor_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  actor_role text NOT NULL,
  reason text CHECK (reason IS NULL OR char_length(reason) <= 500),
  created_at timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (case_id, institution_id)
    REFERENCES public.cases(id, institution_id) ON DELETE CASCADE
);

CREATE TABLE public.inbound_operations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_scope text NOT NULL CHECK (char_length(trim(operation_scope)) BETWEEN 3 AND 128),
  client_operation_id text NOT NULL CHECK (char_length(trim(client_operation_id)) BETWEEN 8 AND 128),
  payload_fingerprint text NOT NULL CHECK (payload_fingerprint ~ '^[0-9a-f]{64}$'),
  case_id uuid REFERENCES public.cases(id) ON DELETE CASCADE,
  receipt_json jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (operation_scope, client_operation_id)
);

-- ---------------------------------------------------------------------------
-- 4. D3 · Ámbito clínico reservado (solo Mesa de Escucha asignada y dueño del caso vía RPC)
-- ---------------------------------------------------------------------------

CREATE TABLE public.case_narratives (
  case_id uuid PRIMARY KEY REFERENCES public.cases(id) ON DELETE CASCADE,
  narrative_text text NOT NULL CHECK (char_length(trim(narrative_text)) BETWEEN 1 AND 4000),
  location_text text NOT NULL DEFAULT '' CHECK (char_length(location_text) <= 500),
  approx_date_text text NOT NULL DEFAULT '' CHECK (char_length(approx_date_text) <= 200),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.case_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  sender_role public.case_message_sender NOT NULL,
  sender_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  body text NOT NULL CHECK (char_length(trim(body)) BETWEEN 1 AND 2000),
  client_operation_id text NOT NULL CHECK (char_length(trim(client_operation_id)) BETWEEN 8 AND 128),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (case_id, sender_role, client_operation_id)
);

CREATE TABLE public.case_internal_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
  author_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  note_body text NOT NULL CHECK (char_length(trim(note_body)) BETWEEN 1 AND 4000),
  client_operation_id text NOT NULL CHECK (char_length(trim(client_operation_id)) BETWEEN 8 AND 128),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (case_id, author_user_id, client_operation_id)
);

-- ---------------------------------------------------------------------------
-- 5. D4 · Actuación institucional (fichas sin relato ni chat y pasos escolares)
-- ---------------------------------------------------------------------------

CREATE TABLE public.case_action_sheets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL,
  institution_id uuid NOT NULL,
  version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
  issued_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  human_level smallint NOT NULL CHECK (human_level IN (2, 3)),
  summary_type public.case_situation_type NOT NULL,
  summary_role public.student_case_role,
  omit_school_due_to_conflict boolean NOT NULL DEFAULT false,
  guidance_notes text NOT NULL CHECK (char_length(trim(guidance_notes)) BETWEEN 1 AND 1500),
  issued_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (case_id, version),
  UNIQUE (id, case_id, institution_id),
  FOREIGN KEY (case_id, institution_id)
    REFERENCES public.cases(id, institution_id) ON DELETE CASCADE
);

CREATE TABLE public.school_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL,
  institution_id uuid NOT NULL,
  action_sheet_id uuid,
  step public.school_action_step NOT NULL,
  is_group_action boolean NOT NULL DEFAULT false,
  action_notes text NOT NULL CHECK (char_length(trim(action_notes)) BETWEEN 1 AND 1500),
  proposes_closure boolean NOT NULL DEFAULT false,
  recorded_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  client_operation_id text NOT NULL CHECK (char_length(trim(client_operation_id)) BETWEEN 8 AND 128),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (case_id, recorded_by, client_operation_id),
  FOREIGN KEY (case_id, institution_id)
    REFERENCES public.cases(id, institution_id) ON DELETE CASCADE,
  FOREIGN KEY (action_sheet_id, case_id, institution_id)
    REFERENCES public.case_action_sheets(id, case_id, institution_id) ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------------
-- 6. D8 · Catálogo público (Información ADR 0009 y líneas de ayuda)
-- ---------------------------------------------------------------------------

CREATE TABLE public.editorial_resources (
  id text PRIMARY KEY CHECK (id ~ '^[a-z0-9_-]{2,64}$'),
  version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
  topic text NOT NULL,
  format public.editorial_resource_format NOT NULL,
  title text NOT NULL,
  summary text NOT NULL,
  body_paragraphs jsonb NOT NULL CHECK (jsonb_typeof(body_paragraphs) = 'array'),
  school_stage text NOT NULL DEFAULT '3.º a 11.º grado',
  duration_label text NOT NULL DEFAULT '3 min',
  source_name text NOT NULL,
  reviewer_name text NOT NULL,
  verified_at date NOT NULL,
  rights_notice text NOT NULL,
  accessible_alternative text NOT NULL,
  offline_packable boolean NOT NULL DEFAULT true,
  published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.help_resources (
  id text PRIMARY KEY CHECK (id ~ '^[a-z0-9_-]{2,64}$'),
  name text NOT NULL,
  phone_or_channel text NOT NULL,
  territory text NOT NULL DEFAULT 'Nicaragua',
  hours_label text NOT NULL,
  source_name text NOT NULL,
  editorial_responsible text NOT NULL,
  verified_at date NOT NULL,
  is_verified_for_pilot boolean NOT NULL DEFAULT false,
  display_order integer NOT NULL DEFAULT 10,
  published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 7. Índices explícitos sobre FKs y predicados RLS
-- ---------------------------------------------------------------------------

CREATE INDEX institutions_public_code_active_idx
  ON public.institutions (public_code)
  WHERE active = true;

CREATE INDEX institution_access_verifiers_institution_id_idx
  ON public.institution_access_verifiers (institution_id);

CREATE INDEX staff_memberships_user_id_active_idx
  ON public.staff_memberships (user_id)
  WHERE active = true;

CREATE INDEX staff_memberships_institution_id_idx
  ON public.staff_memberships (institution_id);

CREATE INDEX cases_institution_id_idx
  ON public.cases (institution_id);

CREATE INDEX cases_assigned_counselor_id_idx
  ON public.cases (assigned_counselor_id);

CREATE INDEX case_events_case_institution_idx
  ON public.case_events (case_id, institution_id);

CREATE INDEX case_events_actor_user_id_idx
  ON public.case_events (actor_user_id);

CREATE INDEX inbound_operations_case_id_idx
  ON public.inbound_operations (case_id);

CREATE INDEX case_messages_case_id_created_at_idx
  ON public.case_messages (case_id, created_at);

CREATE INDEX case_messages_sender_user_id_idx
  ON public.case_messages (sender_user_id);

CREATE INDEX case_internal_notes_case_id_idx
  ON public.case_internal_notes (case_id);

CREATE INDEX case_internal_notes_author_user_id_idx
  ON public.case_internal_notes (author_user_id);

CREATE INDEX case_action_sheets_case_institution_idx
  ON public.case_action_sheets (case_id, institution_id);

CREATE INDEX case_action_sheets_issued_by_idx
  ON public.case_action_sheets (issued_by);

CREATE INDEX school_actions_case_institution_idx
  ON public.school_actions (case_id, institution_id);

CREATE INDEX school_actions_sheet_idx
  ON public.school_actions (action_sheet_id, case_id, institution_id);

CREATE INDEX school_actions_recorded_by_idx
  ON public.school_actions (recorded_by);
