# ADR 0024 — Capturas de pantalla permitidas salvo en el chat

**Estado:** aceptada (2026-11-16). Supera la regla de ADR 0002 («`FLAG_SECURE` en toda la actividad») y el comportamiento por defecto descrito en ADR 0004 §2.1 y ADR 0010.

## Contexto

Desde M0 la actividad Android activaba `FLAG_SECURE` en cada arranque, lo que dejaba en negro capturas, grabaciones y miniaturas de recientes en toda la app. Para la presentación UAM–UNICEF del 17-nov-2026 el equipo necesita capturar pantallas (manual de marca, reporte, pitch) y el contenido general (Inicio, Información, Actividades, Ayuda, acceso escolar) no contiene datos sensibles. El usuario pidió explícitamente: «desactivar el que no se pueda tomar captura de pantalla en la app; únicamente no se puede en el chat».

## Decisión

- `MainActivity` ya **no** activa `FLAG_SECURE` al arrancar.
- `SecureScreenGuard` (`lib/shared/platform/secure_screen_guard.dart`) activa `FLAG_SECURE` mientras está montado y lo retira al salir. Envuelve las dos pantallas de chat:
  - chat del estudiante (`/inicio/apoyo/chat`, `SupportChatScreen`);
  - chat de la Mesa de Escucha (`/personal/mesa/caso/:id/chat`, `DeskChatScreen`).
- El canal `dev.cureando.app/screen_security` permite `setSecureScreen(false)` también en release (antes solo en depuración), para que la protección pueda retirarse al cerrar el chat.

## Alternativas consideradas

- Mantener `FLAG_SECURE` global con excepción solo en depuración: impide capturar en el APK release de la demo.
- Proteger también relato, revisión de alerta y ficha: más protección, pero el usuario restringió el bloqueo al chat. Queda como mejora a evaluar antes de casos reales (docs/03).

## Consecuencias

- Fuera del chat se pueden tomar capturas y aparecen miniaturas en recientes. Las pantallas de relato/revisión de alerta y de caso de personal **no** están protegidas; con datos ficticios de demo es aceptable, pero debe revisarse antes de recibir casos reales.
- Prueba: `test/secure_screen_guard_test.dart` (activa al entrar, retira al salir). Falta verificación física de que el chat sale en negro en una captura.
