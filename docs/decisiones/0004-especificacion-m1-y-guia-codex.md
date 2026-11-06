# ADR 0004 — Especificación técnica aprobada de M1 y guía de ejecución para Codex

- **Fecha:** 2026-11-05
- **Estado:** Aceptado (Decisiones explícitas aprobadas por el usuario tras la verificación física de M0 en el teléfono Android `SM-A566E`).

## 1. Contexto

Con la Fase `M0` verificada físicamente por USB/ADB (instalación del APK, transición de estado del botón, escalado de fuente al 200 % y comprobación de que `FLAG_SECURE` deja en negro las capturas de pantalla), el usuario aprobó las decisiones pendientes para iniciar el desarrollo pesado de `M1` (Identidad visual oficial + interruptor de `FLAG_SECURE` + contratos de dominio y persistencia local cifrada) mediante Codex.

## 2. Decisiones Técnicas Aprobadas para M1

### 2.1. Control de `FLAG_SECURE` mediante `MethodChannel`
- **Comportamiento por defecto:** `FLAG_SECURE` permanece **activo por defecto** al iniciar `MainActivity.kt` para proteger la pantalla del estudiante ante capturas y miniaturas en recientes.
- **Interruptor para capturas y demostración ante el jurado:** `MainActivity.kt` expondrá el canal `dev.cureando.app/screen_security` con los métodos:
  - `setSecureScreen(bool enabled)`: añade o quita `WindowManager.LayoutParams.FLAG_SECURE` en el hilo principal (`runOnUiThread`).
  - `isSecureScreenEnabled()`: devuelve el estado actual (`Boolean`).
- Esto permite pausar la protección desde la barra de demostración para tomar capturas reales del **Reporte Pautado (10 nov)** y proyectar la pantalla en vivo el **17 nov**.

### 2.2. Credenciales de Cuenta Estudiantil por Alias (Sin datos civiles)
- **Mecanismo principal (`E02`):**
  1. **Alias estudiantil** (ej. `SolAzul24`), validado para advertir que no se escriba nombre civil ni apellido.
  2. **PIN numérico de 4 a 6 dígitos**, rápido de ingresar durante la demostración de 2 minutos y cómodo en móvil.
  3. **Código de respaldo local** (ej. formato legible `SETU-XXXX-XXXX`), generado al crear la cuenta para restablecer el PIN en ese mismo teléfono si el estudiante lo olvida, dejando claro en la UI que sin backend el respaldo solo opera en ese dispositivo.
  4. **Vinculación escolar por código de invitación** (ej. `DEMO-NORTE`, `DEMO-SUR`) o simulación de lectura de QR del mural escolar.
- **Almacenamiento seguro de credenciales:** Ни el PIN ni el código de respaldo se almacenan en texto plano; se guarda únicamente su derivación `PBKDF2-HMAC-SHA256` con `salt` aleatorio por cuenta.
- **Acceso complementario por caso (`Código de Caso + PIN de 4 dígitos`):** Se mantiene como vía puntual para consultar un único reporte y enviar solicitudes de seguimiento desde tabletas escolares compartidas, sin exponer los demás reportes de una cuenta.

### 2.3. Paquetes y Persistencia Local Cifrada (`LocalCureandoGateway`)
- **Paquetes aprobados para `apps/mobile/pubspec.yaml`:**
  - `flutter_secure_storage`: para almacenar en el Keystore de Android la clave simétrica maestra de 256 bits.
  - `cryptography` (o `crypto`): para cifrado autenticado `AES-GCM` (256 bits, nonce aleatorio de 96 bits + MAC) del archivo local y derivación `PBKDF2-HMAC-SHA256` de PIN/código de respaldo.
  - `path_provider`: para ubicar el archivo cifrado `setu_local_store.enc` en el directorio privado de la aplicación (`getApplicationSupportDirectory()`).
- **Fuentes offline:** Empaquetar la familia `Poppins` (`Regular`, `Medium`, `SemiBold`, `Bold`) en `apps/mobile/assets/fonts/` para garantizar funcionamiento 100 % offline sin depender de descargas de red en el evento.

### 2.4. Identidad Visual Fiel al Manual (`ManualDeIdentidad gráfica_cureando.pdf`)
- Implementar `CureandoTheme` (`lib/shared/theme/app_theme.dart`) con los tokens exactos de `docs/06-guia-diseno.md` (`#0D61EB`, `#FF0091`, `#FFE100`, `#00C642` y superficies suaves `#EEF4FF`, `#FFF0F8`, `#FFFBEB`, `#ECFDF5`, `#F8FAFC`).
- Implementar los vectores originales en `lib/shared/widgets/setu_brand_mark.dart` usando las coordenadas matemáticas extraídas del PDF en `docs/06-guia-diseno.md`:
  1. **Isotipo de 3 piezas orgánicas** (`viewBox 87.6853 × 87.6853`, radio `R = 42.734`, canal `G = 2.2173`).
  2. **Pieza de rompecabezas redondeada** (insignia de *Testigo Solidario* y conexión).
  3. **Flor de 12 pétalos redondeados** y **Espiral orgánica** (ornamentos de cabecera y cápsulas de autocuidado).

### 2.5. Mejoras Funcionales Incorporadas de los Referentes (*Andrea App* y *b-resol*)
- **Selección de interlocutor + Conflicto de interés (`E04`/`E05`):** El estudiante puede elegir a qué perfil del equipo de orientación del centro dirigir su reporte (ej. *Consejería Escolar CCE* o *Psicología Escolar*) y marcar la casilla de **Conflicto de interés**, lo que desvía el caso a la ruta alternativa (*Supervisión Externa*) y lo excluye de la bandeja del rol en conflicto.
- **Chips de momento / alerta temprana (`E04`):** Además de rol (*Afectado* / *Testigo Solidario*), tipo de situación y lugar, incluir selector opcional de momento/frecuencia (*"Empezó hace poco"*, *"Pasa seguido"*, *"Necesito apoyo pronto"*) sin puntuación clínica.
- **Separación estricta de notas internas (`R03` vs `E08`):** Los modelos visibles al estudiante (`StudentCaseDetailView`) no incluyen el campo `internalNotes` del orientador ni siquiera en memoria.

## 3. Resultado de implementación de M1 (2026-11-05)

Implementado en `apps/mobile/`: modelos y contratos, `LocalCureandoGateway`, archivo privado `setu_local_store.enc` autenticado con AES-GCM-256, clave en `flutter_secure_storage`, PBKDF2-HMAC-SHA256 (600 000 iteraciones, salts de 16 bytes independientes por credencial), y mock exclusivo de pruebas. La clave del archivo no deriva del PIN. Android excluye copias cloud y transferencia del contenido para no restaurarlo sin su clave local.

La cuenta puede emitir/rotar un PIN complementario de caso; solo su derivación se persiste y la credencial se devuelve una vez en memoria. No se incorpora el PIN al recibo idempotente de envío, para no conservar secretos en claro. Cinco fallos de credencial bloquean durante cinco minutos; el contador persiste. La recuperación con respaldo restablece el PIN de la cuenta, no una clave Keystore perdida. Sesiones en memoria; casos en disco.

La interfaz M1 incluye nombre/icono SéTú, isotipo con proporciones del manual, tres motivos, Poppins local con licencia, controles de lectura y protección de pantalla. La protección se activa al arrancar la actividad y solo se pausa tras confirmación; no se persiste la pausa. Los formularios E01–E11 se integran después, no están completos en esta entrega.

Verificado: análisis sin incidencias, 18 pruebas aprobadas, renders de widgets revisados con Poppins y APK debug 0.2.0+2 compilado. M0 se verificó físicamente; el teléfono no está conectado para instalar/verificar este M1. Resultados y SHA-256 en [la guía móvil](../../apps/mobile/README.md).

Separación de roles por autorización y DTO, no por cifrado individual de notas. Los perfiles de personal son allowlisted de prueba local, no autenticación de empleados. Sin backend no hay comunicación entre teléfonos, citas confirmadas o recepción institucional real. No se añadieron contactos activos ni contenido clínico.

## 4. Recomendación de Nivel de Intensidad / Modelo para Codex

| Bloque de trabajo | Modelo / Intensidad recomendada en Codex | Justificación técnica |
| --- | --- | --- |
| **Bloque M1 Completo (Contratos, cifrado `AES-GCM`, `LocalCureandoGateway`, aislamiento de roles/conflicto de interés, `MethodChannel` de `FLAG_SECURE` e identidad vectorial)** | **Intensidad Alta / Extra-Alta (`High` o `Extra High` reasoning effort)** | Involucra criptografía local (`AES-GCM` + `PBKDF2`), invariantes de seguridad (aislamiento entre instituciones, exclusión por conflicto de interés, separación de notas internas, idempotencia de envíos) y precisión geométrica en `CustomPainter`. |
| **Bloque M2–M3 (Pantallas `E01`–`E06` con validación de formularios y reintentos)** | **Intensidad Media-Alta (`High` reasoning effort)** | Requiere conectar controladores `ChangeNotifier` con estados de carga, error, resultado incierto e idempotencia sin duplicar reportes. |
| **Ajustes posteriores de textos, microcopys o estilos puntuales** | **Intensidad Media / Ligera (`Medium` o `Low`)** | Tareas mecánicas donde un esfuerzo menor ahorra tiempo y cuota. |
