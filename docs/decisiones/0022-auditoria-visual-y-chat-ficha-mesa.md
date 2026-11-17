# ADR 0022 · Auditoría visual de textos y flujo Alerta–Chat–Ficha en Mesa de Escucha

- **Estado:** aceptada (15 nov 2026), tras aprobación de la propuesta de auditoría y rediseño.
- **Ajusta:** [ADR 0019](0019-sesion-bloqueada-qr-oficial-y-despacho-en-la-app.md) (detalle y chat de Mesa de Escucha) y vistas estudiantiles/personal con subheadlines redundantes.

## Contexto

Varias pantallas acumulaban subheadlines y párrafos explicativos que repetían lo que ya mostraban el título y los controles, cargando la lectura móvil. Además, en Mesa de Escucha la valoración profesional y las notas internas estaban separadas del flujo principal de conversación, y la pantalla de la alerta no mostraba a la pieza del estudiante contando el relato compartido.

## Decisión

- **Limpieza general de subheadlines redundantes:**
  - En Inicio estudiantil (`student_home_screen.dart`), se quitan los subheadlines de `Información`, `Actividades` y `Ayuda` en `_SectionHeader`.
  - En acceso escolar (`school_access_screen.dart` y `school_qr_poster.dart`), se eliminan subtítulos redundantes en el encabezado azul (`method`, `scan`, `proximity` y `Cartel QR`).
  - En el chat estudiantil (`support_screens.dart`), se quita el subtítulo `Chat privado` bajo `Equipo de escucha`.
  - En bandejas de personal (`staff_inbox_screens.dart` y `staff_director_screens.dart`), se eliminan los párrafos explicativos repetitivos bajo `Alertas recibidas`, `Avisos y fichas` y el subtítulo `Mesa de escucha` en `DeclinedDispatchesScreen`.
- **Vista «Alerta» (`DeskCaseScreen`, `/personal/mesa/caso/:id`):**
  - Encabezado azul con marca `SéTú`, acceso a perfil, `Alerta <código>` y etiqueta de estado/nivel (`Sin valorar` o nivel asignado).
  - Tarjeta **«Comentario de la alerta»** donde la pieza del estudiante (`PieceFigure` + nombre de juego si existe) presenta el relato compartido en un globo de diálogo.
  - Tarjeta **«Datos de la alerta»** (`Colegio`, `Tipo`, `Participación`, `Recibida`).
  - Acción principal **`Atender por chat`** (habilita el chat si aún no está activo y entra directo a la conversación) y acceso secundario **`Abrir ficha sin chat`** (`/personal/mesa/caso/:id/chat?apartado=ficha`).
- **Vista «Chat» y conmutador «Ficha» (`DeskChatScreen`, `/personal/mesa/caso/:id/chat`):**
  - Encabezado compacto con `PieceBadge`, nombre de juego (o código de referencia), código y nivel, más el botón **`Ficha` ↔ `Chat`** para alternar dentro del mismo estado sin perder borradores.
  - En **Chat**: separadores por día (`Hoy`, `Ayer` o fecha), burbujas del estudiante acompañadas por su pieza y hora debajo de cada mensaje.
  - En **Ficha**: datos mínimos y comentario de la alerta, sección de **Notas privadas de escucha** (`backend.notes` / `saveNote`), selector de nivel (1–3), **Comentarios para la ficha** (o motivo de cierre en Nivel 1), **`Guardar borrador`** (`sheetDraft` / `saveSheetDraft` en `StaffBackend`, respaldado por `get_case_sheet_draft` / `save_case_sheet_draft` de la migración `20261116000009`) y cierre final con confirmación:
    - Niveles 2–3: **`Enviar reporte y cerrar chat`** (`assess(..., issueSheet: true)` + `endConversation(...)`, manteniendo el expediente abierto para Dirección).
    - Nivel 1: **`Cerrar caso y chat`** (`assess(..., closeCase: true)`).

## Consecuencias y pendientes

- La conversación finalizada queda en solo lectura tanto en el teléfono del estudiante como en Mesa de Escucha, mientras el borrador privado y las notas internas siguen restringidos a la persona asignada.
- Las pruebas unitarias y de widgets pasan sobre `DemoStaffBackend`; queda pendiente la verificación manual en dispositivo físico contra Supabase real con la migración `20261116000009` aplicada.
