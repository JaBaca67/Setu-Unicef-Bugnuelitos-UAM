# ADR 0020 — Alta post-verificación, gobernanza de invitaciones y cobertura de Red externa

- **Estado:** Aprobado (en implementación)
- **Fecha:** 2026-11-15
- **Supersede parcialmente:** [ADR 0017](0017-activacion-personal-mesa-y-cliente-remoto.md) (orden de activación antes vs. después de confirmar el correo y uso de cuentas `@setu.test` en `seed.sql`) y amplía [ADR 0019](0019-sesion-bloqueada-qr-oficial-y-despacho-en-la-app.md).

## Contexto

Para operar con cuentas reales de personal en Nicaragua sin exponer invitaciones ni permisos de colegio antes de verificar la identidad institucional del usuario, fue necesario ajustar el orden de alta implementado en M4, formalizar quién solicita/emite/revoca códigos, definir la supervisión de practicantes de 5.º año, separar las facultades entre MINED y Dirección sobre la cobertura de Red externa por colegio, y eliminar por completo los correos ficticios `@setu.test`.

## Decisiones aprobadas

### 1. Orden obligatorio de alta y bloqueo con 0 membresías activas
1. La persona crea su cuenta en Supabase Auth con **correo institucional real y funcional** y contraseña (`signUp`), sin consultar ni previsualizar el código previamente.
2. Confirma su correo mediante el enlace enviado por Supabase Auth (`email_confirmed_at IS NOT NULL`).
3. Vuelve a SéTú (o inicia sesión), ingresa su código individual de un solo uso y completa `nombre` (`first_name`) y `apellidos` (`last_name`).
4. `preview_staff_activation_code` y `redeem_staff_activation_code` exigen sesión autenticada con correo verificado y coincidencia exacta (sin distinción de mayúsculas) entre el correo autenticado y `institutional_email` de la invitación.
5. `redeem_staff_activation_code` consume el código, actualiza `staff_profiles` (`first_name`, `last_name`, `staff_tier`, `supervisor_user_id`), activa `staff_memberships` y registra el evento `redeemed` en `staff_invite_events` **en una misma transacción**.
6. Una cuenta con correo confirmado pero con **0 membresías activas** en `staff_memberships` no puede ingresar a ninguna bandeja ni consultar casos; el enrutamiento la restringe al flujo de activación y ayuda de acceso.

### 2. Gobernanza de invitaciones, historial y ayuda con el acceso

| Acción | Dirección (`school_director`) | Responsable de programa / prácticas | MINED (`mined_supervisor`) |
| --- | --- | --- | --- |
| Solicitar invitación | Sí, solo personal de planta (`counseling_desk` / `school_plant`) en su propio colegio | Presenta solicitud ante MINED para Red externa / practicante | Sí (todos los colegios y ámbitos) |
| Aprobar y emitir código | No | No | Sí (todos los roles y ámbitos) |
| Revocar / Reponer código | No (puede consultar estado de su colegio) | No | Sí |
| Consultar estado y auditoría | Solicitudes e invitaciones de su propio colegio | A través de MINED | Todos los colegios y ámbitos |

- El servidor genera un código aleatorio (`SETU-XXXX-XXXX`), almacena únicamente su verificador SHA-256 (`verifier_hash`), lo entrega de forma privada al correo institucional vinculado y nunca guarda el código en texto plano en `staff_activation_invites` ni en `staff_invite_events`.
- La app ofrece **«Necesito ayuda con mi acceso»** con tres rutas explícitas:
  1. Reenviar enlace de confirmación de correo (`OtpType.signup`).
  2. Solicitar reposición de invitación si el código se perdió, venció o se emitió a otro correo (`request_staff_invite_replacement`), sin revelar si existe una invitación previa.
  3. Restablecer contraseña mediante el flujo oficial de Supabase Auth cuando la cuenta ya está activa.

### 3. Supervisión de practicantes de 5.º año (`practicante_5to`)
- Toda invitación con nivel `practicante_5to` exige un `supervisor_user_id` activo con rol `counseling_desk`.
- El practicante autorizado puede valorar casos (niveles 1–3, referencia urgente y cierre de Nivel 1) y emitir fichas de acción directamente sin bloqueo por cofirma.
- Como mecanismo de supervisión confirmado, al registrar la valoración o ficha el servidor inserta un **aviso no bloqueante** (`event_type = 'practicante_supervisor_notice'`) en `case_events` con referencia al supervisor asignado (**solo aviso**, sin detener la atención ni el flujo).

### 4. Cobertura de Red externa por colegio, despacho y continuidad
- **Separación de facultades:**
  - **MINED** administra qué profesionales de la Red externa pueden atender cada colegio (`external_counselor_school_assignments`, vistas «Colegios disponibles» y «Colegios asignados») y controla la habilitación institucional (`institutions.mined_external_enabled`). **MINED prevalece sobre Dirección**: si MINED pausa `mined_external_enabled`, Dirección no puede activar ni extender el apoyo externo hasta que MINED lo habilite.
  - **Dirección** consulta y gestiona el estado operativo de su propio centro dentro del permiso de MINED en tres estados:
    1. `disabled` — *Apoyo externo desactivado*.
    2. `enabled` — *Apoyo externo habilitado*.
    3. `temporary_until` — *Apoyo temporal hasta [fecha y hora]* (`external_support_until`).
- **Despacho y vencimiento / pausa de cobertura:**
  - El despacho ofrece alertas únicamente a profesionales con membresía activa, `is_available = true`, asignación vigente al colegio (si es `external_pool`) y cobertura activa del centro, respetando las reglas de `school_plant` vs. `external_pool`. No clasifica el nivel de alerta.
  - Al pausar la cobertura o vencer `external_support_until`, el servidor retira las ofertas pendientes de `external_pool` en ese colegio marcándolas como `'withdrawn_coverage'` en `case_counselor_dispatches`, e impide tomarlas en `claim_case_counselor`.
  - **Continuidad garantizada:** los casos ya tomados (`assigned_counselor_id IS NOT NULL`) mantienen su atención e historial de conversación mientras la asignación siga autorizada. La revocación disciplinaria o de membresía se ejecuta por separado reasignando o devolviendo el caso a supervisión.
  - Si no hay personal de planta disponible y el apoyo externo está desactivado o no existen profesionales elegibles, la alerta permanece pendiente (`status = 'received'`, `assigned_counselor_id IS NULL`) visible para MINED. Se conserva `omit_school_due_to_conflict` cuando exista conflicto con el colegio.

### 5. Recuperación de alertas declinadas y alineación visual de interfaces
- La declinación mediante el diálogo *«¿Declinar esta alerta?»* registra `'declined'`, muestra un aviso transitorio con **«Deshacer»** (`recover_declined_case_dispatch`) y habilita la pantalla **«Declinadas recientes»** (`/personal/mesa/declinadas`), indicando si la alerta sigue `Disponible` (*«Volver a la bandeja»*) o si `Ya está en atención`.
- Las vistas de la app (`Mi perfil`, `Disponibilidad y avisos`, `Mesa de escucha`, `Conversación`, `Revisar ficha`, `¿Declinar esta alerta?` y `Declinadas recientes`) adoptan la presentación de las maquetas aprobadas conectándose exclusivamente a datos reales autorizados de Supabase.

### 6. Eliminación total de correos falsos `@setu.test`
- Queda prohibido el uso de cuentas y correos ficticios `@setu.test` en `supabase/seed.sql`, en la base remota y en las pruebas automatizadas del proyecto.
- `supabase/seed.sql` conserva únicamente colegios, verificadores de QR/aula, recursos editoriales y líneas de ayuda; las invitaciones iniciales para pruebas con Supabase real se crean con **correos institucionales reales y funcionales** mediante `private.issue_bootstrap_staff_invite(...)` o desde el panel de MINED.

## Consecuencias y verificación requerida
- Requiere las migraciones `20261115000007` (perfiles, invitaciones y ayuda de acceso) y `20261115000008` (cobertura externa por colegio, retiro por cobertura y avisos de supervisión).
- Todo esquema, RPC y aislamiento RLS debe validarse directamente contra el proyecto Supabase `rliiwzovgpnxhrkdkmus` dentro de transacciones `ROLLBACK` para no persistir usuarios de prueba falsos, además de ejecutar los asesores de seguridad y rendimiento (`get_advisors`) y la suite de pruebas de Flutter.
