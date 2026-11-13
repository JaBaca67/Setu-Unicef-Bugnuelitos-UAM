# 0014 · Progreso educativo local y componentes de Inicio

**Estado:** aprobado por el usuario e implementado. Amplía [ADR 0013](0013-inicio-estudiantil-e03.md).

## Contexto

El diseño aprobado de Inicio usa un fondo de campaña y familias de tarjetas con ilustraciones distintas. La revisión incorpora una tarjeta semanal inspirada en la segunda referencia y un calendario mensual inspirado en la tercera. Un perfil recién instalado empieza en cero.

## Decisión

- Compartir el fondo de campaña y la superficie de tarjetas. Usar portada vertical para Guía y Video, y disposición horizontal para Pregunta del día y Dado de emociones.
- La tarjeta semanal abre «Mi racha» con la transición estudiantil existente, racha actual, XP acumulados y navegación entre el mes actual y los anteriores. La semana empieza el lunes. Un borde indica hoy y la marca de actividad distingue los días completados.
- Conceder 10 XP por una respuesta correcta a la pregunta del día, una vez por fecha. El catálogo local de preguntas rota sobre los contenidos disponibles. Conceder 5 XP la primera vez que se confirma la lectura de cada recurso. La tarjeta de Video abre el resumen de muestra y acredita su lectura. Repetir una lectura en otro día marca ese día sin volver a conceder XP.
- Contar días civiles consecutivos según la fecha del teléfono. Si hoy todavía no hay actividad, se conserva la racha que llega hasta ayer. Al pasar un día entero sin actividad, la racha vuelve a cero y se conservan los XP y el historial. El día se actualiza a medianoche y al regresar a la app.
- Mantener un perfil de progreso por instalación, sin cuenta. Guardar fechas completadas, fechas de preguntas e identificadores de recursos en un archivo cifrado propio, separado del almacén de casos, con clave propia. Derivar los XP del registro y publicar el cambio en pantalla después de guardarlo. El Dado de emociones, las alertas y el chat quedan fuera del puntaje.

## Alternativas y consecuencias

- La persistencia local permite avanzar sin backend ni registro personal. El avance depende del calendario del teléfono, se comparte si varias personas usan la misma instalación y se pierde al borrar los datos de la app.
- Se eligió acreditar la lectura con un botón al final del recurso. La reproducción y la acreditación de video quedan pendientes hasta contar con el reproductor y el catálogo editorial. El registro de aprendizaje no contiene respuestas, datos del avatar ni datos de casos.
