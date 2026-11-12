# ADR 0012 — Cámara, cercanía local y capturas de presentación

**Fecha:** 2026-11-12. **Estado:** aceptado e implementado para la demostración. El usuario aprobó las seis casillas, los sensores y las capturas temporales. Eligió el Colegio Centro América de Managua como referencia pública y pidió poder mostrar el recorrido desde otro lugar.

## Contexto y alternativas

E02 usaba un visor simulado y códigos que decidían el resultado de cercanía. Se comparó mantener esa simulación como única ruta, pedir un servicio conectado o usar cámara y una lectura de ubicación con la referencia del centro incluida en el APK. Se eligió el acceso local con sensores y una acción separada para simular la cercanía en depuración.

## Decisión y consecuencias

- El código ficticio `AULA24` se escribe en seis casillas o se lee por cámara. La entrada manual y el QR consultan el mismo valor de prueba. El QR no aporta coordenadas ni abre enlaces. Se incluye el lector de Android de `mobile_scanner` 7.5.0. [Documentación del paquete](https://pub.dev/packages/mobile_scanner/versions/7.5.0).
- La acción GPS usa `geolocator` 14.1.2 con ubicación precisa en primer plano y un límite de 25 s. Calcula cercanía a un pin público del colegio dentro de un radio de prueba de 150 m. Se descarta la posición tras calcular el resultado. El margen horizontal de la lectura debe quedar dentro del radio para confirmar. [Documentación del paquete](https://pub.dev/packages/geolocator/versions/14.1.2) · [Referencia del colegio](https://www.openstreetmap.org/node/2339946939).
- **Simular cercanía para la demo** queda disponible en la compilación de depuración y presenta un resultado identificado como simulado. Esa acción omite la solicitud de ubicación. Se puede compilar en depuración con `SETU_DEMO_SIMULATION=false` para ocultarla.
- La protección contra captura y grabación se desactiva temporalmente por defecto en el APK de presentación en depuración. Para restaurarla en depuración, recompilar con `SETU_DESIGN_CAPTURE=false` y volver el valor predeterminado de ese argumento a `false` al cerrar este bloque de presentación. El canal nativo mantiene la protección en procesos sin marca de depuración.
- El punto de prueba se configura localmente y no autoriza casos, matrícula ni un piloto institucional. La publicación de colegios reales y la verificación institucional requieren contratos y aprobaciones propias.

[Recorrido y QR](../diseno/plan-acceso-escolar-e02.md) · [Notas de Android](../../apps/mobile/README.md).
