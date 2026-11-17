# ADR 0025 — Contactos de ayuda verificados y números de confianza

**Estado:** aceptada (2026-11-16).

## Contexto

Cuando un estudiante envía una alerta sin internet o todavía no recibió respuesta, necesita una salida inmediata. El usuario descartó habilitar el chat por la red mesh (ver análisis del 16-nov) y pidió un atajo desde el seguimiento de la alerta hacia Ayuda con números de MINSA, Policía y UNICEF, más un espacio para anotar números personales de ayuda rápida. AGENTS.md exige que toda información de ayuda tenga fuente, territorio, fecha de verificación y responsable editorial, y prohíbe inventar contactos.

## Decisión

- **Contactos verificados (pestaña Ayuda, `EmergencyContactsCard`):** solo Policía Nacional **118** (24 h) y asistencia médica de emergencia **128**. Fuente: Policía Nacional de Nicaragua (118) y guía oficial de viaje del Gobierno de Canadá para Nicaragua (118 y 128). Territorio: Nicaragua. Verificado: 16-nov-2026. Responsable editorial: equipo SéTú (Bugñuelitos, UAM).
- **MINSA y UNICEF no se publican**: no se encontró una línea oficial vigente del MINSA para salud mental (la 132 fue telemedicina COVID-19 en 2020) ni una línea de atención de UNICEF Nicaragua (solo un teléfono de prensa). El usuario eligió mostrar solo lo verificado; se agregan cuando el equipo confirme una línea oficial con fuente.
- **Atajo en el seguimiento de la alerta:** mientras el chat no está habilitado y el caso no cerró, la pantalla de apoyo muestra «¿Sin internet o todavía sin respuesta?» con el botón «Ir a contactos de ayuda».
- **Llamar:** canal nativo `dev.cureando.app/dialer` que abre el marcador con el número escrito (`ACTION_DIAL`, sin permiso de llamada; la persona confirma). Solo acepta dígitos y `+` inicial.
- **Mis números de confianza (`TrustedContactsSection`):** el estudiante puede anotar hasta 5 números (nombre corto + número) para llamar rápido. Son opcionales, se guardan cifrados solo en el teléfono (`setu_trusted_contacts.enc`, almacén AES-GCM de ADR 0004) y nunca se envían al servidor ni se piden como condición para reportar.

## Consecuencias

- Sin dependencia nueva (no `url_launcher`).
- Los números de confianza son datos personales locales; se pierden si se desinstala la app. No deben aparecer en logs ni telemetría.
- Pruebas: `test/help_contacts_test.dart` (normalización, persistencia, límite y alta desde la hoja). Pendiente: verificación física del marcador y revisión editorial profesional de los contactos.
