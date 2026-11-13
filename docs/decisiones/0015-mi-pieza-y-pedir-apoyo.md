# 0015 · «Mi pieza» y recorrido «Pedir apoyo» (pantallas 1–8)

**Estado:** pedido por el usuario con maquetas numeradas e implementado el 12 nov 2026. Amplía [ADR 0013](0013-inicio-estudiantil-e03.md) y reemplaza las vistas de muestra de «Pedir apoyo» y «Chat humano».

## Contexto

El usuario entregó la maqueta de «Mi pieza» y ocho pantallas numeradas del recorrido de apoyo, con la indicación de que queden iguales a la referencia. No hay backend, panel del MINED ni mesa de escucha conectados todavía.

## Decisión

- **Mi pieza (`/inicio/pieza`).** Reemplaza el avatar de motivo + color. El estudiante elige forma (6), color (6) y accesorios (gorra, lentes, corbatín), o «Al azar». Las piezas se dibujan en vector dentro de la app (`features/piece/`), sin fotos, nombres ni cuentas. La elección vive mientras la app está abierta. Azul y amarillo son de marca; verde claro, rosa, celeste y lima son tonos derivados tomados de la maqueta.
- **Pedir apoyo (`/inicio/apoyo`).** Pantalla 1: «Enviar una alerta» como acción principal, tarjeta del chat y «Ver recursos de ayuda» (abre la pestaña Ayuda). Conserva siempre esa primera pantalla tras enviar alertas y al volver desde «Pedir apoyo»; cuando llega el aviso de disponibilidad, la tarjeta del chat habilita «Abrir chat» allí mismo y cada nueva alerta reinicia su propio ciclo de entrega.
- **Alerta en tres pasos.** Situación (seis opciones, incluida «Necesito hablar»), relación con lo que pasó (título «¿Cómo te relacionás con lo que pasó?», con «Testigo solidario») y detalles opcionales. La revisión muestra quién recibe cada dato y permite editar.
- **Entrega y caso separados.** Al enviar, la alerta se guarda cifrada en un archivo propio (`setu_support_alert.enc`, clave propia). La pantalla 6 dice «Guardada en este teléfono. Falta confirmar la entrega.» hasta el acuse y recién entonces «Alerta recibida». Si no se puede guardar, se informa y no se avanza.
- **Chat humano (`/inicio/apoyo/chat`).** Las burbujas rompehielos pasan la frase al borrador; el estudiante la edita o envía. No hay respuestas automáticas.

## Simulación de la demostración

El acuse de entrega (3 s) y el aviso de disponibilidad (8 s después) se simulan con temporizadores en `SupportFlow`, y el saludo del equipo es un mensaje fijo. Solo datos ficticios. **Actualización 13 nov 2026 ([ADR 0017](0017-activacion-personal-mesa-y-cliente-remoto.md)):** la simulación pasó a `SimulatedSupportBackend`, que se usa en las pruebas y cuando el cliente remoto no está disponible. Con Supabase conectado, el acuse viene de `submit_student_alert` y el aviso de la Mesa de Escucha.

## Consecuencias y pendientes

- Los mensajes del chat no se guardan en el teléfono; con el backend conectado se envían y se leen de la plataforma. La pieza viaja con la alerta, pero no persiste entre aperturas de la app.
- Las pantallas no llevan la etiqueta «Vista de muestra» para respetar la maqueta; la condición de demostración queda en este documento y en el código.
- Pendiente: entrega real, modo sin conexión (mesh), límites de confidencialidad con revisión profesional del copy, y validación de las ilustraciones con diseño.
