# ADR 0025 — Contactos de ayuda verificados y números de confianza

**Estado:** aceptada (2026-11-16).

## Contexto

Cuando un estudiante envía una alerta sin internet o todavía no recibió respuesta, necesita una salida inmediata. El usuario descartó habilitar el chat por la red mesh (ver análisis del 16-nov) y pidió un atajo desde el seguimiento de la alerta hacia Ayuda con números de MINSA, Policía y UNICEF, más un espacio para anotar números personales de ayuda rápida. AGENTS.md exige que toda información de ayuda tenga fuente, territorio, fecha de verificación y responsable editorial, y prohíbe inventar contactos.

## Decisión

- **Líneas de ayuda verificadas (pestaña Ayuda, `EmergencyContactsCard`):** Policía Nacional **118** («si hay peligro o una agresión») y Ministerio de la Familia **133** («orientación y acompañamiento»). Fuente: MINED Nicaragua, cartilla «Mujer, Dignidad y Derechos», p. 29 (118 para denunciar; 133 para recibir orientación y acompañamiento). Territorio: Nicaragua. Verificado: 16-nov-2026. Responsable editorial: equipo SéTú (Bugñuelitos, UAM). *Actualización 16-nov:* el 128 (asistencia médica, fuente: guía de viaje de Canadá) se reemplazó por el 133 por pedido del usuario y por tener fuente nacional del MINED.
- **MINSA y UNICEF no se publican**: no se encontró una línea oficial vigente del MINSA para salud mental (la 132 fue telemedicina COVID-19 en 2020) ni una línea de atención de UNICEF Nicaragua (solo un teléfono de prensa). Se agregan cuando el equipo confirme una línea oficial con fuente.
- **Diseño de la pestaña Ayuda:** encabezado de campaña con logos SéTú + UNICEF; secciones «Líneas de ayuda», «Mis contactos de confianza» y «Preguntas frecuentes» (¿Quién puede leer mi alerta?, ¿Qué pasa después de enviar una alerta?, ¿Qué puedo hacer sin internet?), desplegables en la misma pantalla.
- **Atajo en el seguimiento de la alerta:** mientras el chat no está habilitado y el caso no cerró, la pantalla de apoyo muestra «¿Sin internet o todavía sin respuesta?» con el botón «Ir a contactos de ayuda».
- **Llamar:** canal nativo `dev.cureando.app/dialer` que abre el marcador con el número escrito (`ACTION_DIAL`, sin permiso de llamada; la persona confirma). Solo acepta dígitos y `+` inicial.
- **Mis números de confianza (`TrustedContactsSection`):** el estudiante puede anotar hasta 5 números (nombre corto + número) para llamar rápido. Son opcionales, se guardan cifrados solo en el teléfono (`setu_trusted_contacts.enc`, almacén AES-GCM de ADR 0004) y nunca se envían al servidor ni se piden como condición para reportar.

## Consecuencias

- Sin dependencia nueva (no `url_launcher`).
- Los números de confianza son datos personales locales; se pierden si se desinstala la app. No deben aparecer en logs ni telemetría.
- Pruebas: `test/help_contacts_test.dart` (normalización, persistencia, límite y alta desde la hoja). Pendiente: verificación física del marcador y revisión editorial profesional de los contactos.

## Actualización 17-nov-2026

- La línea gris de fuente bajo la tarjeta se quitó por pedido del usuario. Cada línea tiene ahora un desplegable «¿Cuándo llamar?» con un enunciado breve de uso (118: peligro, agresión o alguien te lastima; atiende 24 h. 133: orientación y acompañamiento) y, dentro, la fuente y la fecha de verificación («Fuente: MINED Nicaragua · Verificado: 16-nov-2026»), para seguir cumpliendo la regla de fuente visible.
- Los números de confianza aceptan una descripción opcional («¿Para qué le llamarías?», hasta 80 caracteres), cifrada junto al contacto y mostrada en un desplegable «¿Para qué?». Los contactos guardados antes siguen funcionando (campo opcional).
