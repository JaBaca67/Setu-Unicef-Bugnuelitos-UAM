# E02 · Demostración de acceso escolar

**12 de noviembre de 2026.** Maqueta aprobada e integrada como demostración. Usa el patrón, el isotipo y la tipografía de la bienvenida de SéTú.

![Maqueta del acceso escolar con elección de método, visor QR, código manual, comprobación de ubicación y dos resultados simulados.](wireframe-e02-acceso-escolar.png)

## Recorrido de la prueba

| Vista | Acción y resultado |
| --- | --- |
| Confirmá tu colegio | Desde la bienvenida, elegir **Escanear QR** o **Escribir código**. Información también queda accesible desde esta entrada. |
| Escaneá el QR | Mostrar el recuadro y ofrecer **Simular escaneo**. La alternativa manual sigue visible. |
| Escribí el código | Campo editable. `AULA-24` simula cercanía confirmada y `AULA-00` deja la cercanía sin confirmar. **Continuar** abre la misma revisión del colegio que el QR. El formato definitivo del código sigue por definir. |
| Comprobá si estás cerca | Mostrar el colegio identificado por el código. Explicar que la ubicación se usaría una vez para comprobar cercanía a ese colegio y que la ubicación exacta no se guardaría. El estudiante decide cuándo tocar **Comprobar cercanía**. **Ahora no** vuelve a la entrada escolar. |
| Colegio confirmado | Mostrar el resultado de muestra y una continuación de demostración al inicio estudiantil. |
| Cercanía sin confirmar | Mostrar un ejemplo de comprobación fallida con **Reintentar**, **Explorar Información** y **Ayuda**. La prueba puede representar distancia o ubicación no disponible. |

La integración usa un colegio ficticio, un visor de muestra y resultados en memoria. Los permisos de Android, la lectura de cámara, los datos de ubicación y la validación real del código quedan para un bloque propio. La cercanía futura solo describe la proximidad al colegio asociado al código. El radio, la precisión, el primer ingreso offline y el acceso fuera del centro siguen por resolver. [Especificación funcional](../08-especificacion-funcional-setu.md) · [Arquitectura del acceso](../02-arquitectura.md) · [Permisos de ubicación Android](https://developer.android.com/develop/sensors-and-location/location/permissions).

## Transiciones, barra de estado y capturas locales

- **Transiciones.** Fundido y desplazamiento corto al navegar entre pantallas de estudiante. Duración de 260 ms al avanzar y 220 ms al volver. Con movimiento reducido, los cambios son inmediatos. [Preferencia de movimiento en Flutter](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html).
- **Barra de estado.** El patrón azul se prolonga debajo de la hora y las notificaciones en E01 y E02. El margen del sistema protege los controles táctiles. [Dibujo bajo las barras del sistema en Android](https://developer.android.com/develop/ui/views/layout/edge-to-edge).
- **Capturas para revisión de diseño.** Desde `apps/mobile/`, `flutter run --dart-define=SETU_DESIGN_CAPTURE=true` habilita las capturas durante una ejecución de depuración. La compilación habitual arranca con protección y Android rechaza desactivarla en compilaciones que carecen de la marca de depuración. [Ejecución Android](../../apps/mobile/README.md) · [Protección de pantalla en Android](https://developer.android.com/security/fraud-prevention/activities#flag_secure).

El usuario aprobó la maqueta de acceso escolar y pidió transiciones suaves en el chat. [Decisión de implementación](../decisiones/0011-acceso-escolar-demostracion.md).
