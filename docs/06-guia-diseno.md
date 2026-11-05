# Cureando — Guía de pantallas para diseño

**Diagrama visual vigente:** [flujos clásicos con decisiones y retornos](diseno/flujos/index.html), disponibles como [imágenes PNG y fuentes Mermaid](diseno/flujos/README.md). Reemplazan el mapa inicial de tarjetas como entrega principal del flujo. Las fichas siguientes siguen siendo la referencia de contenido.

**Entrega simplificada para compartir:** [pantallas explicadas una por una](diseno/pantallas-explicadas.html), con [fuente Markdown](diseno/pantallas-explicadas.md). Esta entrega es independiente de Figma y desarrolla el inventario de esta guía. No hace falta completar el widget de FigJam para comenzar.

Fecha: 2026-11-04. Estado: propuesta de experiencia para el MVP, no pantallas implementadas. Destinatario: persona encargada del diseño en Figma.

## Qué diseñar primero

**P0: pedir apoyo y recibir seguimiento.** Diseñar primero E03 → E04 → E05 → E06 → E07 → E08; después completar entrada E01/E02 y atención R01/R02/R03. Las 11 pantallas P0 permiten demostrar el ciclo completo. P1 añade ayuda y autocuidado: E09/E10/E11. No esperar a terminar P1 para probar el recorrido principal.

P0/P1 indican orden de diseño. La ayuda local verificada y la ruta alternativa de protección son necesarias antes de recibir casos reales, aunque su detalle visual se diseñe después del recorrido principal.

Abrir [el mapa visual en el navegador](diseno/flujo-pantallas.html) o importar [el SVG](diseno/flujo-pantallas.svg) a Figma como referencia visual. El SVG no incluye conexiones de prototipo. [Fuente Mermaid](diseno/flujo-pantallas.mmd) para mantener el diagrama. El FigJam editable requiere completar la selección de equipo en el widget de Figma.

## Referencia de Andrea y adaptación

El [funcionamiento público de Andrea](https://www.soyandrea.es/por-que-andrea/), consultado el 2026-11-04, describe acceso mediante código de centro, alertas de víctimas/testigos y comunicación con profesionales educativos. Es referencia del recorrido general, no una inspección de su aplicación autenticada ni una copia de su navegación o diseño.

Para Cureando proponemos entrada a un centro, reporte privado y seguimiento con personal autorizado. Cambios propios: respuesta asíncrona, revisión antes de enviar, estados explícitos de envío y ayuda accesible sin reportar. No trasladar promesas de anonimato absoluto o chat en vivo. El mecanismo de acceso al centro sigue pendiente: diseñar el campo como invitación provisional, no como decisión técnica aprobada.

## Inventario de pantallas

| ID / prioridad | Pantalla y propósito | Contenido mínimo | Acción y destino |
| --- | --- | --- | --- |
| E01 · P0 | Bienvenida y privacidad: comprender el servicio | Qué permite hacer, quién recibe el reporte, límites de privacidad y atención; sin carrusel obligatorio | Continuar → E02; Buscar ayuda → E09 |
| E02 · P0 | Acceso al centro: entrar al espacio correcto | Invitación provisional, centro encontrado antes de confirmar, explicación de cómo obtener acceso | Entrar → E03; No puedo acceder → E09 |
| E03 · P0 | Inicio: encontrar rápidamente qué hacer | Centro activo, botón principal Pedir apoyo, acceso a Mis reportes, Ayuda y Cuidarme | E04 / E07 / E09 / E10 |
| E04 · P0 | Contar lo ocurrido: redactar sin presión | Me pasa a mí / Lo presencié; relato; contexto y fecha aproximada opcionales; recordar no incluir datos innecesarios | Revisar → E05; volver con aviso si se perderá texto |
| E05 · P0 | Revisar reporte: decidir antes del envío | Resumen editable, destinatario real del centro, límites y horario; no exigir identificar a personas | Editar → E04; Enviar → estado de carga y E06 solo tras confirmación |
| E06 · P0 | Reporte recibido: confirmar recepción | Confirmación real, referencia del caso, siguiente paso, horario acordado y explicación de cómo volver a consultar | Ver seguimiento → E08; Inicio → E03 |
| E07 · P0 | Mis reportes: recuperar seguimiento | Solo casos de la sesión actual, referencia discreta, fecha, estado y señal de respuesta nueva sin extractos sensibles | Abrir → E08; Pedir apoyo → E04 |
| E08 · P0 | Estado y conversación: recibir acompañamiento | Estado comprensible, relato propio, mensajes del personal, campo para seguimiento; sin indicador de atención en vivo | Enviar seguimiento → permanece; volver → E07 |
| R01 · P0 | Acceso del personal: entrada independiente | Cuenta individual y estados de autenticación; acceso del personal discreto, fuera del camino estudiantil | Acceso válido → R02 |
| R02 · P0 | Bandeja autorizada: revisar casos permitidos | Institución, referencia, fecha, estado, filtros mínimos; sin mostrar casos de otros centros | Abrir caso → R03 |
| R03 · P0 | Atender caso: responder y dar seguimiento | Relato, conversación visible, notas internas claramente separadas, estado, asignación y acciones autorizadas | Responder → actualiza E08; cambiar estado con motivo; volver → R02 |
| E09 · P1 | Ayuda verificada: encontrar apoyo sin reportar | Recursos locales, territorio, horario, fecha y fuente de verificación; ruta alternativa si el centro está implicado | Ver contacto y confirmar antes de abrir llamada/enlace externo |
| E10 · P1 | Autocuidado: elegir actividad opcional | Lista breve de actividades revisadas, descripción y duración editorialmente confirmada | Elegir → E11 |
| E11 · P1 | Actividad breve: completar o salir libremente | Instrucciones revisadas, controles sencillos, opción de salir sin penalización | Terminar o salir → E10 |

La confirmación E06 puede ser un estado dedicado de la pantalla de envío. El formulario E04 puede dividirse si las pruebas de comprensión lo justifican. Los IDs son referencias estables para conversar, no obligación de crear rutas independientes para cada variante.

## Estados que también deben diseñarse

| Dónde | Variantes necesarias |
| --- | --- |
| E02 | Invitación vacía, inválida o vencida; centro sin atención disponible; cargando; sin conexión |
| E04/E05 | Campos incompletos, teclado abierto, relato largo, edición, salida con texto sin enviar |
| Envío E05 | Enviando; envío fallido; resultado incierto; reintentar sin duplicar. No decir que falló definitivamente si solo se perdió la confirmación |
| E07 | Sin reportes, cargando, error y sesión caducada; no recuperar mediante nombre civil |
| E08 | Aún sin respuesta, respuesta nueva, mensaje enviando/fallido, caso cerrado con explicación de cómo solicitar seguimiento |
| R01/R02 | Acceso denegado, sesión caducada, bandeja vacía, carga y error |
| R03 | Respuesta visible frente a nota interna, cambio de estado con motivo y error al guardar; no reutilizar un envío ambiguo para ambos tipos de mensaje |
| E09 | Recurso sin verificar o vencido: no ofrecerlo como operativo; ruta alternativa pendiente señalada en maqueta |

No todas las variantes necesitan un frame completo; usar variantes de componentes y frames de los estados críticos del prototipo.

## Indicaciones de interfaz

- Diseñar móvil primero con un frame base acordado y comprobar pantallas pequeñas, texto ampliado y teclado abierto. R02/R03 pueden empezar también en móvil; no comprometer un panel web completo todavía.
- Navegación propuesta tras entrar: Inicio, Mis reportes, Ayuda y Cuidarme. Ayuda también accesible desde E01/E02 sin pertenencia escolar. Pedir apoyo es la acción principal de Inicio.
- Tono cálido, directo y sin culpabilizar. Ejemplos: “Pedir apoyo”, “Cuéntanos qué pasó”, “Revisa antes de enviar”, “Tu reporte fue recibido”, “Todavía no hay una respuesta”. Son textos propuestos para validar con estudiantes.
- No usar “100 % anónimo”, “nadie sabrá”, “resolveremos tu caso” ni un horario ficticio. En maqueta usar “[horario por confirmar]” y “[equipo responsable por confirmar]”.
- No pedir nombre, foto, cédula, teléfono o ubicación para completar el flujo de demo. No diseñar recuperación de sesión hasta decidir el mecanismo.
- Errores junto al campo y texto comprensible; contraste suficiente, foco visible, objetivos táctiles cómodos y estados que no dependan solo del color.
- No añadir adjuntos, rankings, muro público, chat entre alumnos, terapia con IA o gamificación del reporte.
- Datos de muestra completamente ficticios y breves, sin relatos gráficos ni nombres que parezcan personas reales.

## Cómo organizar el archivo de Figma

Propuesta de páginas: 00 · Flujo y alcance; 01 · Wireframes P0 estudiante; 02 · Wireframes P0 responsable; 03 · Apoyo P1; 04 · Componentes y estados; 05 · Prototipo. Nombrar frames con ID y nombre, por ejemplo `E05 / Revisar reporte / Base`.

Primera entrega: wireframes de baja fidelidad P0 y prototipo navegable de dos historias:

1. Estudiante entra, redacta como testigo, revisa, envía y consulta una respuesta simulada.
2. Responsable entra, abre el reporte ficticio, responde y actualiza su estado.

Añadir una rama de envío sin conexión y una bandeja vacía. En el prototipo todo es simulado; no implica backend existente. Conectar E06 a E08 y E07 a E08; no obligar al estudiante a repetir la bienvenida cada vez que regresa con sesión válida.

## Decisiones que no deben frenar los wireframes

Acceso escolar, recuperación de sesión, responsable concreto, horarios, teléfonos y ruta alternativa están pendientes. Se pueden diseñar su estructura y variantes con etiquetas explícitas. No cerrar los textos operativos ni activar un piloto hasta validarlos. La prioridad de esta entrega es comprobar que se entiende a quién se pide ayuda y cómo se consulta lo que ocurre después.
