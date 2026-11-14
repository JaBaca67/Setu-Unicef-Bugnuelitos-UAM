# 0017 · Activación individual de personal, escucha previa a la valoración y cliente remoto `supabase_flutter`

**Fecha:** 2026-11-13 · **Estado:** aprobado e implementado en backend (`supabase/` y proyecto `rliiwzovgpnxhrkdkmus`) y capa cliente remota (`apps/mobile/lib/shared/remote/`). Amplía [ADR 0005](0005-alineacion-con-decisiones-del-equipo-drive.md), [ADR 0015](0015-mi-pieza-y-pedir-apoyo.md) y [ADR 0016](0016-esquema-supabase-rls-y-acceso-privado-caso.md).

## Contexto

Con el esquema base de dominios (`D1`–`D4` y `D8`) desplegado en [ADR 0016](0016-esquema-supabase-rls-y-acceso-privado-caso.md), faltaban cuatro piezas para habilitar el recorrido real entre la app móvil, MINED central, Mesa de Escucha y Dirección:

1. Incorporación segura de personal autorizado sin selector editable de roles ni alta abierta.
2. Flujo clínico real donde la alerta llega asignada sin nivel previo y la conversación humana puede preceder a la clasificación de riesgo.
3. Persistencia de la pieza simbólica estudiantil (`student_piece`) asociada al caso para acompañar visualmente la conversación en Mesa y en «Pedir apoyo» sin cuentas estudiantiles.
4. Capa remota en Flutter (`supabase_flutter`) reutilizable tanto por la interfaz móvil como por los contratos compartidos.

## Decisiones

### 1. Activación individual de personal autorizado (`staff_activation_invites`)

- Se agrega la tabla `public.staff_activation_invites` con `FORCE ROW LEVEL SECURITY` y política de denegación directa (`staff_activation_invites_deny_all`), accesible únicamente mediante RPCs `SECURITY DEFINER`.
- Cada invitación emitida por una vía administrativa confiable queda vinculada antes de entregarse a:
  - `institutional_email`,
  - `role` (`mined_supervisor`, `counseling_desk`, `school_director`),
  - `institution_id` (opcional para ámbito central, obligatorio para `school_director`) y `scope_label`,
  - hash `SHA-256` del código normalizado (`normalize_activation_code`, sin espacios ni guiones y en mayúsculas),
  - expiración (`expires_at`), revocación (`revoked_at`), uso único (`redeemed_at`, `redeemed_by`) y bloqueo tras `5` intentos fallidos durante `15` minutos (`failed_attempts`, `locked_until`).
- Flujo de primer ingreso:
  1. `preview_staff_activation_code(p_activation_code, p_institutional_email)`: confirma colegio o ámbito asignado antes de crear la cuenta.
  2. La persona crea su cuenta en Supabase Auth con su correo institucional y verifica el correo (`email_confirmed_at IS NOT NULL`).
  3. `redeem_staff_activation_code(p_activation_code)`: exige sesión autenticada, correo verificado y coincidencia exacta de correo; bloquea con `pg_advisory_xact_lock` y fila `FOR UPDATE`, consume la invitación una sola vez e inserta la membresía en `public.staff_memberships` con unicidad nulo-segura (`staff_memberships_user_role_scope_uniq_idx`) para evitar duplicados ante reintentos o concurrencia.
- Después de activar la membresía, el personal inicia sesión con correo y contraseña y consulta únicamente los ámbitos autorizados por `get_my_staff_memberships()`.

### 2. Escucha humana previa a la valoración del nivel

- Cuando MINED central asigna un caso (`assign_case_counselor`), el caso pasa a `in_listening` manteniendo **`human_level IS NULL` («Sin valorar»)**.
- Acuerdo funcional y clínico registrado: **el profesional de Mesa de Escucha puede leer el relato opcional (`case_narratives`) y habilitar el chat humano (`enable_case_chat`) antes de valorar el nivel del caso**. Conversar primero permite reunir contexto suficiente en ambiente seguro, registrar notas clínicas privadas (`save_case_internal_note`, visibles exclusivamente al profesional en `case_internal_notes`) y clasificar después (`assess_case_and_issue_sheet`) en:
  - Nivel `1` Acompañamiento (no emite ficha escolar; habilita cierre conciliado),
  - Nivel `2` Convivencia (emite ficha mínima opcional hacia Dirección/MINED sin relato, mensajes ni notas),
  - Nivel `3` Riesgo grave (emite ficha mínima y permite activar `urgent_referral_triggered = true` de forma independiente al estado `escalated` por demora institucional).
- Al habilitarse el chat (`chat_available_notice = true`), el estudiante ve el aviso de disponibilidad dentro de «Pedir apoyo» (`get_student_chat_session`) y conversa en ambas direcciones (`send_student_chat_message` ↔ `send_counselor_chat_message`) con el token privado por caso, sin exponer `status` ni `human_level`.

### 3. Pieza estudiantil (`cases.student_piece`) y colegio demo `AULA26`

- Se añade la columna `cases.student_piece jsonb` (con validación `object`) y la sobrecarga de 12 argumentos de `submit_student_alert(..., p_student_piece jsonb)`, conservando la de 11 argumentos para compatibilidad con semillas previas.
- `get_student_chat_session` y las consultas autorizadas de Mesa devuelven `student_piece` junto con el caso para mostrar la pieza elegida al reabrir la conversación.
- Se añade **Colegio Centro América — Demo (`AULA26`)** en `supabase/seed.sql` junto con usuarios ficticios de prueba e invitaciones activas, vencidas y revocadas de demostración (`CCA-DIR-2026`, `CCA-MESA-2026`, `CCA-EXP-2026`, `CCA-REV-2026`).

### 4. Capa cliente remota Flutter (`apps/mobile/lib/shared/remote/`) y aviso en vivo

- Se integra `supabase_flutter: ^2.18.3` en `apps/mobile/pubspec.yaml` con tres módulos aislados de la UI:
  - `case_capability_crypto.dart`: generación de token aleatorio de 256 bits (64 hex), cálculo local de `SHA-256` e identificadores de idempotencia.
  - `setu_remote_models.dart`: modelos inmutables y enumeraciones alineadas al esquema PostgreSQL.
  - `setu_remote_gateway.dart`: contrato `SetuRemoteGateway`, implementación `SupabaseSetuRemoteGateway` y configuración pública `SetuSupabaseConfig` (solo URL + llave pública `publishable`, nunca `service_role`).
- Se habilita Supabase Realtime sobre `public.cases` y `public.case_messages` (`supabase_realtime`) para emitir dentro de la app el aviso **«Tenés una alerta asignada»** (`watchAssignedCaseNotices`). La asignación queda persistida y visible en la bandeja aunque la entrega del aviso falle.

### 5. Superficies móviles de personal (`/personal/*`) y puertos de interfaz

Confirmado por el usuario el 13 nov 2026: el alumnado sigue sin cuentas (código público del colegio y capacidad privada por caso); el personal autorizado usa cuenta institucional activada por invitación de un solo uso y opera desde la app móvil, sobre el mismo backend que usará la futura web. Esto ajusta, solo para el personal, el «acceso sin cuentas» de [ADR 0005](0005-alineacion-con-decisiones-del-equipo-drive.md) y suma superficies móviles a los paneles web propuestos en ADR 0008.

- **Bienvenida E01.** «Personal autorizado» reemplaza a «Explorar Información»; Información sigue en la navegación estudiantil de `/inicio`.
- **Rutas.** `/personal` (ingreso), `/personal/activar` (validar código, crear contraseña, «Revisá tu correo institucional» y canje), `/personal/ambito` (elegir centro con varias membresías), `/personal/mined`, `/personal/mesa`, `/personal/mesa/caso/:id`, `/personal/mesa/caso/:id/chat`, `/personal/direccion` y `/personal/direccion/caso/:id`.
- **Guía de rutas, no control de acceso.** El enrutador envía a cada persona a la superficie de su rol y al ingreso si no hay sesión. Los permisos los aplican RLS y los RPC; ocultar una pantalla no protege datos.
- **Puertos de interfaz.** Las pantallas dependen de `StaffBackend` (`features/staff/`) y `SupportBackend` (`features/support/`). Cada uno tiene una demostración en memoria con datos ficticios, usada en las pruebas de widgets, y un adaptador que delega en `SetuRemoteGateway`. `main.dart` inyecta los adaptadores; si el cliente remoto no puede prepararse, la app abre con la demostración y lo indica en pantalla.
- **Recorrido estudiantil.** `SupportFlow` genera con `CaseCapabilityCrypto` el secreto del caso y el identificador de operación, los guarda en el almacén cifrado y envía solo el verificador SHA-256 junto con la pieza. «Alerta recibida» aparece únicamente con el acuse de `submit_student_alert`; sin conexión la alerta sigue guardada y se reintenta la misma operación. El aviso de chat depende de `chat_available_notice` y los mensajes vienen de la plataforma; no se guardan en el teléfono.
- **Mesa de Escucha.** El chat puede habilitarse antes de valorar. La nota interna usa su propio espacio y su propia operación. La valoración muestra el nivel con texto (1 · Acompañamiento, 2 · Convivencia, 3 · Riesgo grave), la derivación urgente es un control aparte y la ficha mínima se revisa antes de enviarse.
- **Dirección.** Ve avisos mínimos y fichas autorizadas; registra los cinco pasos. El paso de familia se registra como acción grupal porque la identidad está reservada.
- **Reintentos.** Cada acción reutiliza su identificador de operación mientras el contenido no cambie, para que un reintento no la duplique.

## Consecuencias y pendientes

- Migraciones aplicadas y verificadas transaccionalmente (`BEGIN; ... ROLLBACK;`) en `rliiwzovgpnxhrkdkmus` y reflejadas en `supabase/migrations/20261113000004_setu_staff_activation_and_desk_workflow.sql`.
- Las pantallas de `apps/mobile/lib/features/staff/` y el recorrido estudiantil quedaron implementados y cubiertos con pruebas de widgets sobre la demostración en memoria. **La conexión real con Supabase no se probó desde la interfaz**: falta un recorrido en teléfono con las cuentas de `seed.sql`.
- **Contrato alineado en `shared/remote/` (13 nov 2026).** `SetuRemoteGateway.recordSchoolAction` y `recordTeacherNotice` envían ahora los parámetros de las funciones SQL `record_school_action` y `record_teacher_notice` (`p_action_sheet_id`, `p_expected_concurrency_version`, `p_institution_id`), y el adaptador de la interfaz delega en ellos. Sin probar todavía contra Supabase desde un teléfono.
- **Aviso docente conectado.** `StaffCaseSummary.studentRole` y `CaseActionSheetView.summaryRole` aceptan el valor nulo de un aviso docente y las bandejas muestran «Aviso docente». El botón «Registrar aviso docente» aparece también con el cliente remoto.
- **Nombres de centros.** `SetuRemoteGateway.listActiveInstitutionNames()` lee los centros activos; `main.dart` ya no consulta la tabla directamente.
- **Código del colegio en la alerta.** El acceso escolar E02 valida solo `AULA24` en el teléfono, así que la alerta se envía a ese centro. Para otro centro se compila con `--dart-define=SETU_SCHOOL_CODE=AULA26`; falta que E02 resuelva el código con `resolve_public_school`.
- MINED no tiene todavía en la app el seguimiento de supervisión (`mined_update_case_supervision`): escalar y cerrar quedan para un bloque posterior.
- El aviso nativo de Android en segundo plano o con pantalla bloqueada («Tenés una alerta asignada») queda en bloque posterior sujeto a aprobación explícita tras conectar la UI.
- Pendiente para producción real: activar *Leaked Password Protection* en Supabase Auth y sustituir usuarios/códigos ficticios de `seed.sql` por altas institucionales verificadas.
