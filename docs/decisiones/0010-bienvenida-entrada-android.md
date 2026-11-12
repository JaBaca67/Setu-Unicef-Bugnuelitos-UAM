# ADR 0010 — Bienvenida E01 como entrada Android

**Fecha:** 2026-11-12. **Estado:** aceptado e implementado. El usuario aprobó en el chat la maqueta de campaña y pidió integrarla directamente en la app, con la flor amarilla desplazada hacia la derecha.

## Contexto y alternativas

La ruta inicial abría la pantalla técnica de M1. Mantener ese arranque y habilitar una ruta de demostración habría separado la maqueta del recorrido de instalación habitual. La decisión aprobada es abrir directamente E01 y conservar la verificación técnica mediante un argumento de compilación.

## Decisión y consecuencias

- `/` abre E01 estática. Colegio, Información y Ayuda abren vistas identificadas como demostración. Privacidad se presenta en un panel dentro de E01.
- El ícono y el arranque nativo usan el isotipo oficial blanco sobre azul. Los recursos del lanzador son adaptativos en Android 8 o superior y tienen variantes para versiones anteriores. Android 12 o superior usa los atributos nativos de arranque.
- `--dart-define=SETU_M1_QA=true` abre la verificación de M1. El arranque estudiantil funciona con los recursos empaquetados. El código nativo activa `FLAG_SECURE` en cada arranque.
- La aprobación se limita a navegación de muestra e identidad. El escaneo, catálogo editorial, envío de alertas y comunicación entre dispositivos conservan sus bloques de desarrollo.

[Plan y arte de bienvenida](../diseno/plan-arranque-bienvenida-setu.md) · [Ejecución Android](../../apps/mobile/README.md).
