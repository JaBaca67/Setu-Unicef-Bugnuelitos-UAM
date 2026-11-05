# Cureando: qué debe llevar cada pantalla

Guía para comenzar el diseño móvil. Propuesta del MVP, pendiente de validar con el equipo. No es una aplicación funcionando. Los textos entre corchetes se completarán cuando se confirmen los datos.

## Cómo leer esta guía

Cada ficha explica una pantalla de arriba hacia abajo. Diseñar primero en gris, comprobar que se entiende el recorrido y después definir colores e ilustraciones. Los botones indican su destino con el mismo nombre e identificador que la ficha.

**Primer bloque:** E01 Bienvenida → E02 Acceso del estudiante → E03 Inicio. **Segundo bloque:** E04 Contar → E05 Revisar → E06 Recibido → E08 Seguimiento. E07 permite volver a encontrar los reportes. **Tercer bloque:** R01 Acceso del personal → R02 Bandeja → R03 Atención. **Después:** E09 Ayuda, E10 Cuidarme y E11 Actividad.

Con una sesión estudiantil válida, abrir directamente E03. Ayuda puede abrirse sin entrar al centro. El personal tiene una entrada independiente. No diseñar registro con nombre, correo o foto para estudiantes por ahora: se propone una sesión sin nombre civil y acceso por invitación, cuyo funcionamiento final sigue pendiente.

## E01 · Bienvenida

- **Para qué sirve:** explicar qué es Cureando antes de entrar.
- **Arriba:** nombre o logotipo provisional de Cureando. No usar logotipo de UNICEF sin autorización.
- **Título:** “Pedir ayuda es un primer paso”.
- **Texto principal:** “Aquí puedes contar una situación de acoso que te pasó o que presenciaste, consultar respuestas y encontrar apoyo”.
- **Bloque de privacidad:** “Tu reporte no se publica. Lo revisará el equipo autorizado de tu centro. Lo que escribas puede identificarte; evita datos que no sean necesarios”.
- **Aviso breve:** “No es un servicio de emergencias. La atención depende del horario del equipo”.
- **Botón principal:** “Entrar a mi centro” → E02.
- **Botón secundario:** “Buscar ayuda” → E09, sin iniciar sesión.
- **Enlace discreto al pie:** “Acceso del personal” → R01.
- **Qué probar:** el estudiante puede explicar quién recibe el reporte. La información de privacidad permanece disponible desde Inicio.

## E02 · Acceso del estudiante — el login propuesto

- **Para qué sirve:** entrar al espacio del centro correcto sin pedir nombre civil.
- **Arriba:** flecha Volver → E01 y título “Entra a tu centro”.
- **Explicación:** “Usa la invitación que te entregó tu centro. Si no la tienes, puedes consultar las opciones de ayuda”. El centro todavía no tiene un proceso real de entrega aprobado.
- **Campo único:** etiqueta “Invitación de acceso”; ejemplo visual “Escribe tu invitación”. No fijar longitud ni formato hasta definir el mecanismo. Teclado compatible con letras y números.
- **Primer botón:** “Comprobar invitación”. Mientras consulta: “Comprobando…”, sin permitir otra pulsación.
- **Después de comprobar:** mostrar “Centro encontrado: [nombre del centro]” y una breve explicación de privacidad de la sesión. El estudiante debe confirmar que reconoce el centro.
- **Segundo botón, en ese estado:** “Entrar a este centro” → E03 si el acceso se valida. Si no reconoce el centro, “Usar otra invitación” limpia la comprobación.
- **Enlace secundario:** “No tengo invitación / Necesito ayuda” → E09.
- **Errores:** vacío: “Escribe tu invitación”; no válida o vencida: “No pudimos validar esta invitación. Revísala o pide ayuda”; sin conexión: “No pudimos comprobarla. Revisa tu conexión y vuelve a intentar”.
- **Si el centro no está operativo:** explicar que no puede recibir reportes por ahora y ofrecer Ayuda; no dar acceso a un envío sin destinatario.
- **No incluir:** registro por redes sociales, nombre completo, foto, cédula o recuperación por nombre. La recuperación de sesión se definirá aparte.
- **Qué probar:** entrada correcta, invitación rechazada y centro equivocado. Esta ficha propone la experiencia; una invitación no es por sí sola garantía de pertenencia escolar.

## E03 · Inicio — la home

- **Para qué sirve:** que el estudiante sepa qué puede hacer sin buscar entre muchos botones.
- **Arriba:** Cureando, “[nombre del centro]” y acceso a “Privacidad y sesión”. No mostrar nombre o foto del estudiante.
- **Título:** “¿Cómo podemos apoyarte?”.
- **Tarjeta principal, la más visible:** título “Pedir apoyo”; texto “Cuéntanos algo que te pasó o que presenciaste”; botón “Contar lo ocurrido” → E04.
- **Segunda tarjeta:** “Mis reportes”; texto “Consulta el estado y las respuestas”; botón “Ver mis reportes” → E07. Si hay respuestas nuevas, usar una marca discreta sin mostrar el relato.
- **Acceso de ayuda:** “Buscar ayuda” → E09. Debe ser fácil de encontrar, aunque todavía no haya reportes.
- **Acceso de bienestar:** “Cuidarme” → E10. Se puede añadir en la segunda entrega de diseño.
- **Aviso de atención:** “[Equipo responsable por confirmar] · [Horario por confirmar]”. No inventar tiempos de respuesta.
- **Barra inferior propuesta:** Inicio / Mis reportes / Ayuda / Cuidarme. Cada opción abre E03 / E07 / E09 / E10. La opción actual debe distinguirse con texto e indicador, además del color.
- **Panel o modal de privacidad y sesión:** resumen de quién accede, enlace a información completa dentro del panel y acción “Cerrar sesión”. Advertir antes de cerrar que podría perder acceso al seguimiento si no existe recuperación aprobada. Cancelar mantiene la sesión; confirmar vuelve a E01. No prometer borrar el reporte al cerrar sesión.
- **Qué probar:** encontrar Pedir apoyo y Mis reportes sin instrucciones. Mostrar el mismo inicio con y sin respuestas nuevas.

## E04 · Contar lo ocurrido

- **Para qué sirve:** redactar un reporte con calma.
- **Arriba:** Volver → E03 y título “Cuéntanos qué pasó”.
- **Primera pregunta:** “¿Cómo te relacionas con lo ocurrido?”. Dos opciones: “Me pasó a mí” / “Lo presencié”. No seleccionar ninguna por defecto.
- **Campo principal obligatorio:** “¿Qué pasó?”. Caja de varias líneas. Ayuda: “Escribe lo que te parezca importante. No necesitas saber cómo llamarlo”.
- **Campo opcional:** “¿Dónde ocurrió?”. Ejemplo: “En el aula, en el recreo o en internet”. Texto libre; no solicitar GPS.
- **Campo opcional:** “¿Cuándo ocurrió aproximadamente?”. Permitir una descripción breve sin exigir fecha exacta.
- **Recordatorio:** “Evita compartir teléfonos, direcciones u otros datos que no hagan falta”.
- **Botón principal:** “Revisar antes de enviar” → E05. Si faltan las opciones o el relato, señalar el campo con una frase sencilla.
- **Al volver con texto escrito:** modal “Tu reporte todavía no se ha enviado”; botones “Seguir escribiendo” y “Salir sin enviar”. Al salir, no conservar el relato localmente por defecto.
- **No incluir:** fotos, audios, archivos, nombres obligatorios ni mensajes que culpen al estudiante.
- **Qué probar:** teclado abierto, texto largo y errores visibles junto a su campo.

## E05 · Revisar antes de enviar

- **Para qué sirve:** revisar el texto y conocer el destinatario.
- **Arriba:** Volver → E04 y título “Revisa tu reporte”. Conservar el contenido mientras se edita dentro del recorrido.
- **Resumen:** relación con lo ocurrido, relato, lugar y fecha aproximada si se escribieron.
- **Enlace:** “Editar” → E04 sin perder lo escrito.
- **Bloque destacado:** “Lo recibirá [equipo autorizado] de [centro]”. Si el destinatario no está definido, el prototipo lo señala y una aplicación real no debe aceptar el reporte.
- **Aviso:** “[Horario por confirmar]. Enviar un reporte no garantiza una respuesta inmediata”.
- **Botón principal:** “Enviar reporte”. Mientras envía: “Enviando…”, desactivar pulsaciones repetidas.
- **Éxito:** solo después de confirmar recepción → E06.
- **Error confirmado antes del envío:** “No se pudo enviar. Intenta de nuevo”. Mantener el texto en la pantalla mientras permanezca abierta.
- **Resultado incierto:** “No pudimos confirmar si se recibió. Vuelve a comprobarlo”. Botón “Comprobar y reintentar”; el sistema debe evitar crear un reporte duplicado.
- **Qué probar:** editar, enviar, falta de conexión y resultado incierto. No mostrar una confirmación falsa.

## E06 · Reporte recibido

- **Para qué sirve:** dar tranquilidad sobre la recepción y explicar el siguiente paso.
- **Arriba:** icono sencillo de confirmación y título “Tu reporte fue recibido”.
- **Texto:** “El equipo autorizado podrá revisarlo. Puedes consultar el estado y las respuestas en Mis reportes”.
- **Referencia:** “[Referencia del reporte]”; no usar un nombre de persona ni un título sensible.
- **Información de atención:** “[Equipo y horario confirmados antes del piloto]”.
- **Botón principal:** “Ver seguimiento” → E08 del reporte recién creado.
- **Botón secundario:** “Volver al inicio” → E03.
- **Recordatorio:** “El acceso a tus reportes depende de tu sesión. [Explicación de recuperación por definir]”. No prometer acceso desde cualquier dispositivo.
- **Qué probar:** queda claro que recibido no significa resuelto.

## E07 · Mis reportes

- **Para qué sirve:** encontrar los reportes propios y volver a sus respuestas.
- **Arriba:** título “Mis reportes”. Mantener la barra inferior del estudiante.
- **Cada tarjeta:** referencia, fecha, estado escrito y marca “Respuesta nueva” cuando corresponda. No mostrar extractos del relato.
- **Estados visibles:** “Recibido”, “En revisión”, “En acompañamiento” y “Cerrado”. Incluir una explicación corta al abrir el reporte.
- **Al tocar una tarjeta:** abrir E08 de ese caso.
- **Si no hay reportes:** “Todavía no has enviado reportes”; botón “Pedir apoyo” → E04.
- **Si no carga:** mensaje “No pudimos cargar tus reportes” y botón “Reintentar”. No confundir error con lista vacía.
- **Si la sesión caduca:** informar antes de volver al acceso. No prometer recuperar reportes solo ingresando otra invitación.
- **Qué probar:** lista vacía, lista con casos y respuesta nueva.

## E08 · Estado y conversación

- **Para qué sirve:** consultar avances y comunicarse con el equipo autorizado.
- **Arriba:** Volver → E07, referencia del reporte y estado.
- **Resumen:** relato enviado, con opción de desplegarlo para evitar ocupar toda la pantalla.
- **Conversación:** mensajes del estudiante y del equipo claramente diferenciados, con fecha. Mostrar el nombre funcional del equipo, sin inventar profesionales.
- **Sin respuesta:** “Todavía no hay una respuesta. El equipo revisa los reportes en [horario confirmado]”.
- **Campo:** “Escribe un mensaje de seguimiento”; botón “Enviar mensaje”. No habilitar envío vacío.
- **Si falla el mensaje:** señalar “Pendiente” o “No enviado” según lo que se conozca y ofrecer reintento sin duplicar.
- **Si está cerrado:** mostrar explicación del cierre y botón “Solicitar seguimiento”. Abre un mensaje al equipo; no reabre automáticamente el caso. La reapertura la evalúa personal autorizado.
- **Acceso de apoyo:** Ayuda sigue disponible en la barra inferior.
- **No incluir:** “En línea”, “escribiendo…”, atención inmediata, notas internas o mensajes de otros estudiantes.
- **Qué probar:** sin respuesta, respuesta nueva, envío fallido y caso cerrado.

## R01 · Acceso del personal

- **Para qué sirve:** permitir que solo personal autorizado entre a la atención de casos.
- **Arriba:** Volver → E01 y título “Acceso del personal”.
- **Texto:** “Usa la cuenta que te asignó la institución”.
- **Campos propuestos:** “Correo institucional” y “Contraseña”, con control “Mostrar / Ocultar contraseña”. No rellenarlos con credenciales reales en la maqueta.
- **Botón:** “Iniciar sesión” → R02 si se valida. Un paso adicional de verificación puede ser necesario antes del piloto; no se ha definido su mecanismo.
- **Estados:** iniciando sesión, campos vacíos, credenciales no válidas, falta de conexión y cuenta sin autorización. El mensaje de error no debe revelar cuentas existentes.
- **Sin registro público:** las cuentas del personal se asignan mediante un proceso administrativo. No añadir “Crear cuenta” abierto a cualquiera.
- **Ayuda de acceso:** “Solicita apoyo al administrador de tu institución”. No poner un botón de recuperación que no tenga un proceso definido.
- **Qué probar:** el estudiante no entra a la bandeja usando su invitación; no basta con seleccionar un rol en la interfaz.

## R02 · Bandeja del responsable

- **Para qué sirve:** encontrar y revisar únicamente los casos autorizados.
- **Arriba:** “[Centro]”, título “Reportes” y menú de cuenta con “Cerrar sesión” → R01.
- **Filtros mínimos:** Todos los autorizados / Recibidos / En revisión / En acompañamiento / Cerrados.
- **Cada fila o tarjeta:** referencia, fecha, estado y marca de mensaje nuevo. No mostrar nombres de estudiantes ni relatos en el listado.
- **Al tocar un caso:** abrir R03. No ofrecer casos a los que la persona no tiene acceso.
- **Sin casos:** “No hay reportes en esta vista”.
- **Si falla:** “No pudimos cargar la bandeja” y botón “Reintentar”. Si caduca la sesión, solicitar nuevamente acceso.
- **Qué probar:** bandeja vacía, con casos, filtros y acceso denegado.

## R03 · Atender caso

- **Para qué sirve:** leer, responder y registrar la atención.
- **Arriba:** Volver → R02, referencia, centro y estado actual.
- **Bloque del reporte:** relato, relación con lo ocurrido y contexto opcional.
- **Sección “Conversación con el estudiante”:** historial visible para ambos y campo “Respuesta para el estudiante”; botón “Enviar respuesta”. Explicar junto al botón: “El estudiante podrá leer este mensaje”.
- **Sección separada “Notas internas”:** campo y botón “Guardar nota interna”. Aviso “Solo personal autorizado”. No mezclarla con el campo de respuesta.
- **Sección de gestión:** responsable asignado y acción de asignación solo si tiene permiso. Si no lo tiene, mostrar el dato sin control de edición.
- **Acción “Cambiar estado”:** elegir transición permitida; pedir motivo cuando corresponda, confirmar y mostrar error si no se guarda. Cerrar requiere motivo. Reabrir requiere autorización y motivo.
- **Derivación:** registrar como parte del seguimiento interno según protocolo; no cerrar automáticamente por derivar. No inventar destinatarios externos.
- **Qué probar:** distinguir visualmente respuesta y nota interna; una respuesta enviada debe aparecer en E08 y una nota interna nunca debe aparecer allí.

## E09 · Buscar ayuda

- **Para qué sirve:** encontrar apoyo aunque no se pueda o no se quiera reportar.
- **Arriba:** título “Buscar ayuda” y Volver al lugar desde el que se abrió. Antes de entrar al centro, no mostrar barra inferior de sesión.
- **Aviso:** “Cureando no es un servicio de emergencias”. Las orientaciones y contactos locales deben revisarse antes de publicar.
- **Cada recurso:** nombre, para qué sirve, territorio, horario real, medio de contacto, fuente y fecha de verificación.
- **Botones:** “Llamar” o “Abrir sitio”, según recurso confirmado. Antes de salir de la app, mostrar el destino y permitir cancelar.
- **Ruta alternativa:** bloque “¿El problema involucra a alguien del centro?”. Mostrar la vía independiente validada cuando exista. En diseño usar “[Ruta alternativa por confirmar]”.
- **Sin recursos verificados:** informar que el directorio no está disponible; no simular números operativos.
- **Qué probar:** llegar desde bienvenida sin acceso escolar. Los contactos ilustrativos no deben poder llamarse en la demo.

## E10 · Cuidarme

- **Para qué sirve:** elegir una actividad breve y voluntaria.
- **Arriba:** título “Un momento para ti” y barra inferior del estudiante.
- **Texto:** “Puedes probar una actividad o salir cuando quieras”.
- **Tarjetas:** título, breve descripción y duración revisada. Para el wireframe usar “[Actividad revisada]” en vez de instrucciones terapéuticas inventadas.
- **Botón por tarjeta:** “Ver actividad” → E11.
- **Aviso breve:** “Estas actividades no sustituyen el apoyo profesional”.
- **No incluir:** rachas, premios, diagnóstico o preguntas obligatorias sobre el estado emocional.
- **Qué probar:** elegir una actividad sin registrarse de nuevo ni enviar información personal.

## E11 · Actividad

- **Para qué sirve:** seguir el contenido elegido, sin presión para terminar.
- **Arriba:** Volver → E10 y nombre de la actividad.
- **Contenido:** instrucciones previamente revisadas; si tiene pasos, mostrar uno a la vez con “Anterior” y “Siguiente”.
- **Botón al final:** “Terminar” → E10.
- **Salida disponible:** “Salir de la actividad” → E10, sin penalización ni confirmación culpabilizante.
- **No solicitar:** diagnóstico, puntuación emocional obligatoria o almacenamiento de respuestas íntimas.
- **Qué probar:** texto grande, lectura sencilla y salida en cualquier momento.

## Qué debe entregar el diseñador

Primera entrega: E01, E02 y E03 en baja fidelidad; verificar acceso y contenido del inicio antes de decorar. Segunda entrega: E04 a E08 con envío correcto y sin confirmación. Tercera: R01 a R03 para demostrar que alguien recibe y atiende el caso. Después: E09 a E11 y variantes restantes. Ayuda verificada es un requisito para operar con casos reales aunque su diseño detallado vaya en otro bloque.

Diseñar componentes reutilizables: encabezado, campo y error, botón normal/cargando/deshabilitado, tarjeta, etiqueta de estado, barra inferior, mensaje de conversación, aviso, estado vacío y modal de confirmación. Un estado no siempre necesita una pantalla nueva.

No hace falta definir hoy colores finales, ilustraciones, panel web, recuperación de sesión ni tecnología. Sí hay que mantener marcados los pendientes de invitaciones, horarios, destinatarios, protocolo y recursos locales. Todos los ejemplos deben ser ficticios.
