# 0015 · «Mi pieza» y recorrido «Pedir apoyo» (pantallas 1–8)

**Estado:** pedido por el usuario con maquetas numeradas e implementado el 12 nov 2026. Amplía [ADR 0013](0013-inicio-estudiantil-e03.md) y reemplaza las vistas de muestra de «Pedir apoyo» y «Chat humano».

## Contexto

El usuario entregó la maqueta de «Mi pieza» y ocho pantallas numeradas del recorrido de apoyo, con la indicación de que queden iguales a la referencia. No hay backend, panel del MINED ni mesa de escucha conectados todavía.

## Decisión

- **Mi pieza (`/inicio/pieza`).** Reemplaza el avatar de motivo + color. El estudiante elige forma (6), color (6) y accesorios (gorra, lentes, corbatín), o «Al azar». Las piezas se dibujan en vector dentro de la app (`features/piece/`), sin fotos, nombres ni cuentas. La elección vive mientras la app está abierta. Azul y amarillo son de marca; verde claro, rosa, celeste y lima son tonos derivados tomados de la maqueta.
- **Pedir apoyo (`/inicio/apoyo`).** Pantalla 1: «Enviar una alerta» como acción principal, tarjeta del chat y «Ver recursos de ayuda» (abre la pestaña Ayuda). Pantalla 7: cuando llega el aviso de disponibilidad, la misma ruta ofrece «Abrir chat».
- **Alerta en tres pasos.** Situación (seis opciones, incluida «Necesito hablar»), relación con lo que pasó (título «¿Cómo te relacionás con lo que pasó?», con «Testigo solidario») y detalles opcionales. La revisión muestra quién recibe cada dato y permite editar.
- **Entrega y caso separados.** Al enviar, la alerta se guarda cifrada en un archivo propio (`setu_support_alert.enc`, clave propia). La pantalla 6 dice «Guardada en este teléfono. Falta confirmar la entrega.» hasta el acuse y recién entonces «Alerta recibida». Si no se puede guardar, se informa y no se avanza.
- **Chat humano (`/inicio/apoyo/chat`).** Las burbujas rompehielos pasan la frase al borrador; el estudiante la edita o envía. No hay respuestas automáticas.

## Simulación de la demostración

El acuse de entrega (3 s) y el aviso de disponibilidad (8 s después) se simulan con temporizadores en `SupportFlow`, y el saludo del equipo es un mensaje fijo. Nada sale del teléfono. Solo datos ficticios. Al conectar el backend, estos temporizadores se reemplazan por el acuse real de la plataforma y el aviso real de la mesa de escucha.

## Consecuencias y pendientes

- Los mensajes del chat no se guardan ni se envían. La pieza no persiste entre aperturas.
- Las pantallas no llevan la etiqueta «Vista de muestra» para respetar la maqueta; la condición de demostración queda en este documento y en el código.
- Pendiente: entrega real, modo sin conexión (mesh), límites de confidencialidad con revisión profesional del copy, y validación de las ilustraciones con diseño.
