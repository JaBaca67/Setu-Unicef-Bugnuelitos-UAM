# 0016 · Esquema Supabase por dominios de confidencialidad, RLS y acceso privado por caso

**Fecha:** 2026-11-12 · **Estado:** aprobado e implementado en la Oleada 1 (`supabase/migrations/` y proyecto `rliiwzovgpnxhrkdkmus`). Amplía [ADR 0005](0005-alineacion-con-decisiones-del-equipo-drive.md), [ADR 0009](0009-espacio-informativo-confirmado.md) y [ADR 0013](0013-inicio-estudiantil-e03.md).

## Contexto

La app estudiantil ya opera localmente el acceso escolar (`E02`), el inicio (`E03`) sin seguimiento de casos (`E07`) y el recorrido local de «Pedir apoyo» ([ADR 0015](0015-mi-pieza-y-pedir-apoyo.md)). Para conectar el backend en Supabase/PostgreSQL 17 sin exponer relatos clínicos ni estados internos entre actores, hacía falta materializar la separación de almacenes lógicos (`D1`–`D4` y `D8`), políticas RLS estrictas y funciones RPC transaccionales con idempotencia.

## Decisión

1. **Separación física por confidencialidad (`20261112000001_setu_core_schema.sql`):**
   - **D1 (`institutions`, `institution_access_verifiers`, `staff_memberships`):** validación pública de centros activos y membresías de personal con roles separados (`mined_supervisor`, `counseling_desk`, `school_director`), sin almacenar códigos privados en claro (solo hashes `SHA-256`).
   - **D2 (`cases`, `case_private_capabilities`, `case_events`, `inbound_operations`):** alerta mínima sin relato ni chat, seis estados (`received`, `in_listening`, `sheet_sent`, `school_acting`, `escalated`, `closed`), nivel humano opcional (`1..3`), bandera independiente de derivación urgente (`urgent_referral_triggered`), bandera de disponibilidad de chat (`chat_available_notice`), versión de concurrencia e idempotencia por `(operation_scope, client_operation_id)` y huella `SHA-256`. Llaves foráneas compuestas `(case_id, institution_id)` impiden cruzar fichas o actuaciones entre centros distintos.
   - **D3 (`case_narratives`, `case_messages`, `case_internal_notes`):** relato opcional, mensajes del chat humano (`E08`) y notas internas clínicas en tablas separadas de `cases`.
   - **D4 (`case_action_sheets`, `school_actions`):** ficha mínima emitida por Mesa (niveles 2 y 3, sin relato ni chat) y actuaciones escolares de los 5 pasos del manual.
   - **D8 (`editorial_resources`, `help_resources`):** catálogo público de Información y líneas de ayuda con fuente, territorio, fecha de verificación y responsable editorial, completamente desacoplado de casos e instituciones.

2. **Credencial privada por caso sin cuentas estudiantiles:**
   - El estudiante no crea cuenta ni alias/PIN. Al enviar una alerta (`submit_student_alert`), el cliente genera una capacidad privada aleatoria de 256 bits por caso, conserva el secreto localmente y envía únicamente su hash `SHA-256` (`p_capability_verifier_hash`) hacia `case_private_capabilities`.
   - Este diseño funciona tanto en envío directo `online` como a través de un teléfono puente `mesh` (el puente no recibe el token en claro ni adquiere permisos de lectura; además, el origen `mesh` rechaza relatos en `submit_student_alert`).
   - El chat humano (`get_student_chat_session` y `send_student_chat_message`) valida el token contra `case_private_capabilities`, requiere `chat_available_notice = true` para escribir y devuelve únicamente mensajes, sin exponer `status`, `human_level` ni `case_internal_notes`.

3. **Políticas RLS y funciones transaccionales (`20261112000002_setu_rls_policies.sql`, `20261112000003_setu_rpc_functions.sql`):**
   - `ENABLE` y `FORCE ROW LEVEL SECURITY` en todas las tablas; tablas internas (`institution_access_verifiers`, `case_private_capabilities`, `inbound_operations`) sin acceso directo desde `anon` o `authenticated`.
   - **Aislamiento D3:** ni `anon`, ni `mined_supervisor`, ni `school_director` tienen políticas de lectura sobre `case_narratives`, `case_messages` o `case_internal_notes`. Solo la Mesa de Escucha asignada (`cases.assigned_counselor_id = auth.uid()`) accede por RLS a D3.
   - **Aislamiento entre centros y conflicto de interés:** `school_director` solo lee y actúa sobre casos de su institución con `involves_staff = false` y fichas con `omit_school_due_to_conflict = false`. `record_school_action` bloquea el contacto familiar individual (`notify_family_or_group` con `is_group_action = false`) mientras `identity_reserved = true`.

## Consecuencias y pendientes

- Las migraciones y semillas ficticias (`supabase/seed.sql` con `AULA24` y `AULA25`) quedaron aplicadas y verificadas en el proyecto Supabase `rliiwzovgpnxhrkdkmus`.
- Pendiente para la **Oleada 2** (requiere aprobación explícita): agregar `supabase_flutter` y la capa de cliente remoto en `apps/mobile/lib/shared/` sin alterar la UI de `features/home/`, `welcome/` ni `school_access/`, ni romper las pruebas locales de M1.
- Pendiente antes de cualquier piloto real: habilitar protección de contraseñas filtradas en Supabase Auth (`auth_leaked_password_protection`), definir RPCs completas de panel MINED/Mesa (asignación, ficha, escalamiento, cierre) y validar contactos de ayuda institucionales.
