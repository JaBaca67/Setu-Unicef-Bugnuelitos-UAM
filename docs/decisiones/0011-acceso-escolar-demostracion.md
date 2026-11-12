# ADR 0011 — Acceso escolar simulado y capturas de diseño

**Fecha:** 2026-11-12. **Estado:** aceptado e implementado para la demostración. El usuario revisó la maqueta de E02 y pidió transiciones suaves, además de solicitar una barra de estado integrada y capturas para su revisión local.

## Contexto y alternativas

La bienvenida abría un único texto de muestra para Colegio. Integrar cámara, ubicación y validación real en este bloque habría requerido decidir permisos, alcance de cercanía y primer acceso desconectado. La demostración permite validar la comprensión de los dos métodos y el estado sin confirmar con datos ficticios.

Para compartir las pantallas se podía usar la verificación técnica de M1 o permitir capturas en todas las compilaciones. Se eligió un argumento explícito de depuración para abrir la app directamente en la bienvenida y conservar protección en el arranque habitual.

## Decisión y consecuencias

- El QR simulado y el código `AULA-24` muestran cercanía confirmada. `AULA-00` representa cercanía sin confirmar. Los resultados existen solo durante la navegación y se identifican como simulados.
- E01 y E02 comparten el fondo debajo de la barra de estado y respetan los márgenes del sistema. El avance y el regreso tienen transiciones breves que se desactivan con la preferencia de movimiento reducido.
- `SETU_DESIGN_CAPTURE=true` aplica únicamente a la ejecución de depuración. La ventana se protege al iniciar. Solo un proceso depurable puede desactivar esa protección mediante el canal de la app.
- La cámara, la ubicación, el backend y las decisiones reales de acceso escolar quedan para los bloques correspondientes.

[Maqueta y recorrido](../diseno/plan-acceso-escolar-e02.md) · [Ejecución Android](../../apps/mobile/README.md).
