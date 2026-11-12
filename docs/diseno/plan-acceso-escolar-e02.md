# E02 · Demostración de acceso escolar

**12 de noviembre de 2026.** La prueba en Android usa la cámara y la ubicación del teléfono. El escenario y el código son de demostración. El Colegio Centro América de Managua aporta únicamente el punto público de referencia elegido por el usuario. [Colegio Centro América](https://cca.edu.ni/) · [Punto público en OpenStreetMap](https://www.openstreetmap.org/node/2339946939).

## Recorrido del APK de presentación

| Vista | Acción y resultado |
| --- | --- |
| Confirmá tu colegio | Desde la bienvenida, elegir **Escanear QR** o **Escribir código**. Información también queda accesible. |
| Escaneá el QR | Abrir la cámara y mostrar el visor. Al detectar `AULA24`, se cierra la cámara y se abre la revisión del colegio. Si se deniega la cámara o el QR no coincide, se puede escribir el código. [QR de demostración](qr-aula24.png). |
| Ingresá el código de tu colegio | Seis casillas con un solo teclado y foco visible. Permite pegar y corregir. `AULA24` y el formato anterior `AULA-24` abren la misma revisión del colegio. |
| Comprobá si estás cerca | Mostrar el centro de referencia. **Comprobar cercanía** pide ubicación en primer plano y toma una lectura actual. **Ahora no** vuelve a la entrada. |
| Colegio confirmado / fuera de la zona / sin confirmar | Distinguir una lectura dentro del radio, una lectura fuera y un resultado incierto. La recuperación ofrece reintento, ajustes cuando corresponde, Información y Ayuda. |
| Cercanía simulada | En depuración, **Simular cercanía para la demo** permite continuar desde otro lugar. Esa acción no pide ubicación y el resultado se identifica como simulado. |

El código de demostración apunta al pin público `12.098062, -86.2641465`. El cálculo se hace localmente y se descarta la ubicación del dispositivo. El radio de prueba es 150 m. Una lectura precisa confirma cercanía si el margen horizontal estimado queda dentro del radio. Si el margen cruza el límite o la lectura es imprecisa, queda sin confirmar. El margen es una estimación del dispositivo. La validación institucional y la pertenencia escolar permanecen en diseño. [Arquitectura de acceso](../02-arquitectura.md) · [Permisos de ubicación en Android](https://developer.android.com/develop/sensors-and-location/location/permissions).

El lector ML Kit va incluido en el APK, de modo que el reconocimiento del QR puede ejecutarse localmente. Una comprobación en modo avión depende de que el dispositivo consiga una lectura GPS actual. [Documentación de mobile_scanner](https://pub.dev/packages/mobile_scanner#android) · [Documentación de geolocator](https://pub.dev/packages/geolocator).

## Transiciones, barra de estado y capturas locales

- **Transiciones.** Fundido y desplazamiento corto de 260 ms al avanzar y 220 ms al volver. Con movimiento reducido, los cambios son inmediatos. [Preferencia de movimiento en Flutter](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html).
- **Barra de estado.** El patrón azul se prolonga debajo de la hora y las notificaciones en E01 y E02. El margen del sistema protege los controles táctiles. [Dibujo bajo las barras del sistema en Android](https://developer.android.com/develop/ui/views/layout/edge-to-edge).
- **Capturas temporales.** El APK de presentación en depuración permite captura y grabación durante este bloque. Se restaura la protección en depuración con `--dart-define=SETU_DESIGN_CAPTURE=false`. Las compilaciones sin marca de depuración mantienen `FLAG_SECURE`. [Notas del APK](../../apps/mobile/README.md#capturas-temporales-para-la-presentación).

[Maqueta anterior con sensores simulados](wireframe-e02-acceso-escolar.png) · [Decisión de implementación](../decisiones/0012-camara-ubicacion-y-presentacion.md).
