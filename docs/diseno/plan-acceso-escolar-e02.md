# E02 · Propuesta visual de acceso escolar

**12 de noviembre de 2026.** Maqueta para revisión antes de programar. Usa el patrón, el isotipo y la tipografía de la bienvenida de SéTú.

![Maqueta del acceso escolar con elección de método, visor QR, código manual, comprobación de ubicación y dos resultados simulados.](wireframe-e02-acceso-escolar.png)

## Recorrido de la prueba

| Vista | Acción y resultado |
| --- | --- |
| Confirmá tu colegio | Desde la bienvenida, elegir **Escanear QR** o **Escribir código**. Información también queda accesible desde esta entrada. |
| Escaneá el QR | Mostrar el recuadro y ofrecer **Simular escaneo**. La alternativa manual sigue visible. |
| Escribí el código | Mostrar un campo editable y el código ficticio `AULA-24` como ejemplo de la maqueta. **Continuar** abre la misma revisión del colegio que el QR. El formato definitivo del código sigue por definir. |
| Comprobá si estás cerca | Mostrar el colegio identificado por el código. Explicar que la ubicación se usaría una vez para comprobar cercanía a ese colegio y que la ubicación exacta no se guardaría. El estudiante decide cuándo tocar **Comprobar cercanía**. **Ahora no** vuelve a la entrada escolar. |
| Colegio confirmado | Mostrar el resultado de muestra y una continuación de demostración al inicio estudiantil. |
| Cercanía sin confirmar | Mostrar un ejemplo de comprobación fallida con **Reintentar**, **Explorar Información** y **Ayuda**. La prueba puede representar distancia o ubicación no disponible. |

La siguiente integración propuesta usa un colegio ficticio y resultados en memoria. El visor y la cercanía serán simulados. Los permisos de Android, la lectura de cámara, los datos de ubicación y la validación real del código quedan para un bloque propio. La cercanía futura solo describe la proximidad al colegio asociado al código. El radio, la precisión, el primer ingreso offline y el acceso fuera del centro siguen por resolver. [Especificación funcional](../08-especificacion-funcional-setu.md) · [Arquitectura del acceso](../02-arquitectura.md) · [Permisos de ubicación Android](https://developer.android.com/develop/sensors-and-location/location/permissions).

## Barra de estado y capturas locales

- **Barra de estado.** Prolongar el fondo de la cabecera debajo de la hora y las notificaciones en E01 y E02. Conservar el margen del sistema para los controles táctiles y ajustar el color de los indicadores a cada fondo. La maqueta muestra el patrón azul detrás de los indicadores blancos. [Dibujo bajo las barras del sistema en Android](https://developer.android.com/develop/ui/views/layout/edge-to-edge).
- **Capturas para revisión de diseño.** Probar un modo local explícito en compilaciones de depuración que permita capturar las pantallas de demostración con datos ficticios. La compilación habitual sigue usando la protección de Android. Como vía disponible en el repositorio, `flutter run --dart-define=SETU_M1_QA=true` abre la pantalla técnica con el control **Proteger pantalla**. Después de confirmar **Permitir**, se puede volver a la bienvenida y capturar durante esa sesión. [Ejecución Android](../../apps/mobile/README.md) · [Protección de pantalla en Android](https://developer.android.com/security/fraud-prevention/activities#flag_secure).

El usuario revisará la maqueta antes de aprobar la integración de E02, el ajuste de la barra y el modo local de capturas.
