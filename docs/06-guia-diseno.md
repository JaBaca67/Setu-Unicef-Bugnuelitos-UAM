# Guía de diseño de SéTú

**Revisión:** 2026-11-09. Marca final de Drive y alcance ADR 0005. Inventario funcional en [docs/08](08-especificacion-funcional-setu.md). No corresponde al modelo anterior por alias/PIN.

## Autoridad visual

[Manual final](https://drive.google.com/file/d/11vE2_hviWBnT79giw6Y8mgofxUckyae6/view): 32 páginas. [SVG oficiales](https://drive.google.com/drive/folders/16XnURY24OzDCv9UqPX7VS9Bx4QxwfzsZ): 36 variantes, equivalentes al conjunto PNG. Usar el activo apropiado con/sin fondo, isotipo, logotipo o composición; no reconstruir las curvas del manual inicial como autoridad final.

Nombre **SéTú**, con tildes. Valores: Valentía, Empatía, Confianza, Respeto y Compromiso. Mascota denominada Pulgin/Tapudín en las notas; confirmar denominación final. Motivos: rompecabezas, flor de 12 puntas y espiral. No deformar, inclinar, degradar o recombinar el logo. Respetar protección según manual y evitar composiciones institucionales que sugieran un convenio inexistente.

## Colores y tipografía

| Token | Valor | Uso propuesto de interfaz |
| --- | --- | --- |
| Azul de marca | `#0C62EB` | Acción principal y elementos de marca. |
| Rosa de marca | `#FF0092` | Acentos de apoyo; no es clasificador clínico automático. |
| Amarillo de marca | `#FFE000` | Acentos cálidos y avisos con texto oscuro. |
| Verde de marca | `#00C642` | Apoyo y confirmación, siempre con descripción textual. |
| Fondo | `#F8FAFC` | Propuesta UI, no color adicional del manual. |
| Tarjeta | `#FFFFFF` | Propuesta UI. |
| Texto principal | `#0F172A` | Propuesta UI sobre superficies claras. |
| Texto secundario | `#475569` | Propuesta UI; comprobar contraste real. |

Poppins para interfaz; Clayful para marca y acentos breves, sin imponerla a relatos extensos. Poppins ya está empaquetada en M1. Clayful no se da por instalada, licenciada o integrada en el código por figurar en el manual.

Propuesta tipográfica general: cuerpo 16 sp, títulos 22–24 sp y controles adaptables al escalado del sistema. E01 usa la paleta final y títulos de campaña. [Diseño de bienvenida](diseno/plan-arranque-bienvenida-setu.md).

## Navegación y jerarquía

Entrada: bienvenida → QR/código público → confirmar colegio → inicio. No formularios de alias/PIN. Ayuda y contenidos disponibles sin iniciar una solicitud. Navegación vigente del estudiante ([ADR 0013](decisiones/0013-inicio-estudiantil-e03.md), 2026-11-12): **Inicio, Información, Actividades y Ayuda**. El estudiante no tiene una sección de seguimiento de casos: tras pedir apoyo puede recibir un aviso, sin datos del caso, que abre su chat humano; el historial y el estado interno quedan en los roles autorizados. La organización final necesita validación con primaria y secundaria.

La tarjeta semanal de Inicio presenta la racha y los XP reales del dispositivo. Abre «Mi racha», con calendario mensual, contorno para hoy y marca de actividad completada. Un perfil nuevo empieza en cero. El fondo azul de campaña se reutiliza como widget independiente; las tarjetas de recursos y actividades comparten esquinas, sombra y superficie táctil. La racha y los XP solo acompañan aprendizaje voluntario, sin puntajes emocionales, recompensas por alertas ni bloqueo de apoyo. El avatar sigue siendo ilustrado, sin foto, nombre ni cuenta. [Reglas de progreso](decisiones/0014-progreso-educativo-local.md).

E01 y la demostración E02 prolongan la cabecera debajo de la barra de estado. El desplazamiento y fundido entre pantallas se desactivan al pedir movimiento reducido. [Diseño de acceso escolar](diseno/plan-acceso-escolar-e02.md).

**Información es un destino confirmado** ([ADR 0009](decisiones/0009-espacio-informativo-confirmado.md)), también desde bienvenida antes del QR y desde entrega/espera. E10 presenta temas y formatos; E11 muestra artículo, video, testimonio editorial o guía con fuente/revisión y salida fácil. La forma final de tarjetas, filtros o búsqueda se prototipa por etapa escolar. [Recorrido y referente](14-espacio-informativo-y-referente-netflix.md).

Para videos: reproducción voluntaria, controles comprensibles y subtítulos/transcripción. Texto ampliable y alternativas disponibles con poco consumo de datos. Diferenciar recurso descargado de no disponible; volver al seguimiento conserva operación y estado. No exigir lecturas, presentar puntajes emocionales o cambiar el nivel de un caso por el tema consultado. Mantener las acciones Información, Ayuda y Pedir apoyo diferenciadas.

Reporte: tipo → rol → detalles opcionales → revisión → estado real de entrega. Los pasos pueden agruparse visualmente si no perjudica comprensión. El estudiante decide cuánto narrar; el campo libre vacío no impide un aviso válido con tipo/rol.

Seguimiento interno: el historial y el estado interno del caso se muestran solo a los roles autorizados (mesa de escucha, MINED y dirección). El estudiante ve el estado real de entrega (E06) y recibe, cuando corresponda, un aviso de disponibilidad que abre su chat; el aviso no lleva datos del caso. Estado de entrega separado del estado del caso.

MINED y dirección tienen vistas distintas. Dirección y MINED ven aviso mínimo/ficha/actuaciones; nunca burbujas de chat, relato o notas internas. El chat necesita internet. Dirección incluye registro de avisos docentes sin acceso para docentes. La mesa de escucha se identifica como humana y con horario real cuando esté acordado.

## Estados y mensajes

| Situación | Diseño requerido |
| --- | --- |
| Sin internet | Guardado local, búsqueda y entrega pendiente sin falso éxito. |
| Puente recibió | Confirmación local de custodia; sincronización MINED diferenciada. |
| Resultado incierto | Explicar incertidumbre y permitir comprobar/reintentar sin duplicación. |
| Permiso QR/radios denegado | Explicar para qué sirve y alternativa disponible, sin insistencia coercitiva. |
| Configuración desconocida offline | No afirmar pertenencia validada; ofrecer ayuda/contenidos disponibles. |
| Chat sin internet o sin profesional disponible | Mensaje de espera y límites; no indicador ficticio de atención en vivo. |
| Caso cerrado | Motivo visible permitido y solicitud de revisión sin reapertura automática. |
| Error de autorización | Sin datos ajenos, códigos privados o detalles internos en el mensaje. |

Textos propuestos: “Pedir apoyo”, “Cuéntanos lo que quieras compartir”, “Guardado en este teléfono”, “Falta confirmar la entrega”, “La plataforma recibió tu aviso”. Evitar “100 % anónimo”, “siempre respondemos”, “nadie sabrá” o “resuelto” solo por recibir un paquete.

## Accesibilidad y validación

No usar color como único indicador de nivel/estado. Incluir texto, iconos comprensibles, foco y etiquetas de lector de pantalla. Comprobar objetivos táctiles, teclado, mensajes junto al campo y contraste de cada combinación real; el manual de marca no certifica WCAG.

Mantener escalado Android; M1 ofrece Normal/Grande +20 %. Comprobar pantallas pequeñas y texto grande sin cortar acciones. Diseñar lenguaje y ayuda para primaria, sin pedir audio o imágenes como solución automática. Validar comprensión de privacidad, Testigo Solidario, destinatarios y estados de entrega por grupo de edad.

## Figma

Propuesta de páginas: alcance y fuentes; estudiante; mesa/MINED; dirección; componentes/estados; prototipo. Los IDs de docs/08 son referencias de trabajo, no marcos oficiales ya creados en Figma ni correspondencias garantizadas con el manual. Diseñar ramas sin internet y permisos denegados junto al camino principal.

Ayuda necesita fuente, territorio, fecha y responsable antes de publicar. Videos/testimonios requieren derechos, revisión y protección de personas. Material ficticio en prototipos; sin nombres, casos reales, códigos privados o credenciales.

## Corte de muestra E10/E11 (16 nov 2026)

La implementación aprobada sigue las referencias Figma E10-A–D y E11-A–F con ilustraciones exportadas en `assets/home/info/`, Poppins y los tokens existentes. Biblioteca ofrece búsqueda local y filtros sobre 21 recursos de seis temas; Rutas presenta cuatro recorridos activos de tres pasos. Las rutas públicas permiten explorar sin colegio. Los videos se abren fuera de la app con internet y conservan texto adaptado sin conexión (ADR 0026). El modal de fuente declara la revisión pendiente sin atribuir validación institucional. El cierre de ruta concede +10 XP una vez por ruta, separado de la pregunta diaria; se mantienen +5 XP por primera lectura (ADR 0014). Se conserva la barra compartida `SetuBottomNav` de la app.

El pulido visual aprobado para la demo comparte el fondo de campaña de Inicio con la cabecera de Información, muestra completo `e10a_header_figures.png` y conserva la misma fila de símbolos SéTú/UNICEF. El título se dibuja directamente sobre el banner con la sombra de texto de Inicio; ambas cabeceras terminan en el mismo corte recto de la hoja blanca. La búsqueda tiene superficie blanca, borde azul de 2 px, radio de 18 px y altura base de 44 px que crece con el texto; no lleva contador. Las categorías forman un carrusel horizontal y mantienen su color aun sin seleccionar: Todos/Apoyo azul y blanco, Acoso escolar amarillo y rosa, Ciberacoso rosa y blanco, Emociones verde y blanco; borde y marca de selección complementan el color. Las tarjetas separan el espacio de texto del arte y crecen con el contenido. La portada omite resúmenes; el catálogo compacto muestra una línea por recurso. Se conserva la declaración de muestra/revisión pendiente en el modal E11-F «Fuente y revisión».

Inicio presenta `banner-pregunta-del-dia.png` y `banner-dado-emociones.png` en dos tarjetas contiguas con radio de 18 px y proporción 495:261. El texto forma parte de las imágenes; las etiquetas y el estado de la pregunta se mantienen en Semantics. Actividades conserva sus formularios interactivos, que no comparten estas tarjetas. «Mi racha» comparte el fondo `CampaignBackground` de Inicio (`campaign-pattern.png`) y superpone `banner-racha-figures.png`, transparente, con encuadre 600:268. Usa la misma fila SéTú/UNICEF de Inicio (símbolo de 28 px, margen izquierdo de 18 px y superior de 8 px), regreso y título blanco, sin subtítulo; mantiene resumen, calendario con etiquetas accesibles por día y CTA «Ir a Actividades».

El carrusel de categorías oculta inmediatamente los chips que no caben completos en su viewport y los muestra con un fundido breve al desplazarse. Conserva sus etiquetas y acciones para lectores de pantalla; las etiquetas se ajustan al ancho máximo disponible con texto ampliado, sin mostrar chips cortados. La cápsula seleccionada de la barra usa un resaltado más tenue, manteniendo el vidrio translúcido; el icono y la etiqueta activos usan azul de marca pleno y mayor peso en la etiqueta.

Las cuatro pestañas de Inicio se desplazan mediante `PageView` y comparten un Scaffold con barra flotante. La cápsula escucha `PageController.page` y sigue su posición fraccionaria sin una animación adicional retrasada. El vidrio usa blanco translúcido más luminoso y etiquetas de 11 sp, una línea y ajuste al espacio disponible, conservando el escalado del sistema y las etiquetas accesibles completas. El perfil estudiantil comparte esta barra y deja el espacio inferior correspondiente; su salida sigue llamándose «Salir del colegio». «Cerrar sesión» pertenece al perfil del personal. El editor de pieza/nombre conserva el CTA fijo sobre el área segura.

`CampaignScreen` reserva al final del desplazamiento el alto real de la barra flotante informado por el `Scaffold`, o el margen inferior del sistema si es mayor, más 16 px. `FlowScaffold` conserva área segura y 16 px bajo los CTA; sus grupos de acciones permiten desplazamiento cuando no caben. Los compositores de chat mantienen también 16 px sobre el área segura. La verificación de widget cubre anchos de 360/412 px, alturas de 560/850 px, márgenes Android de 0/24/48 px y acciones con texto ampliado.

## Simplificación de Información (17 nov 2026)

Los títulos tienen hasta seis palabras, los resúmenes hasta 70 caracteres y cada recurso presenta hasta tres ideas de 90 caracteres. El JSON conserva la versión verificada completa. Tarjetas y lector evitan resúmenes, introducciones y metadatos repetidos; la fuente queda visible en una línea con enlace original y el modal editorial completo. Ansiedad y Depresión conservan la tarjeta de seguridad y el acceso a Ayuda. Cada tema usa ilustraciones distintas; los stickers transparentes llevan fondo de marca y padding.

«Elegí tu ruta» usa cuatro tarjetas de color con sticker, esquinas de 24 px, Poppins bold, estado y tres piezas de progreso. La selección activa tiene borde e ícono; +10 XP indica el cierre y una medalla lo distingue al completarlo. La cuadrícula 2×2 cambia a una columna con texto ampliado. El mapa usa piezas por paso y muestra los XP educativos ganados, sin cambiar sus reglas ni condicionar el acceso a apoyo.

Biblioteca distingue la portada E10-A del catálogo E10-B. La portada muestra un destacado azul con «Leer», bloques por tema con dos tarjetas ilustradas contiguas y un banner para la tercera pieza (o una pieza única). Cada bloque ofrece «Ver catálogo ›», que activa el filtro de ese tema. Las búsquedas y categorías usan tarjetas compactas con miniatura, disponibilidad verde, título, tema/formato/duración y resumen de una línea; «+5 XP» aparece solo mientras la lectura no esté registrada. Se omite la duración cuando no está verificada. «Todos» limpia tema y búsqueda y vuelve a la portada. Con texto ampliado, las tarjetas en pares pasan a una columna y los textos compactos pueden crecer.

Los primeros chips son Todos, Acoso escolar, Emociones y Ciberacoso: caben completos a 360–412 px con Poppins bold de 12 sp, separación de 6 px y padding horizontal adaptado al ancho. La selección se identifica por borde oscuro de 2 px y estado accesible; no reserva espacio para un checkmark. Con texto al 200 % pueden verse menos de cuatro chips completos.


## Actividades E06 y personajes de apoyo (17 nov 2026)

El bloque aprobado implementa cinco entradas: Rompecabezas del buen trato, Semáforo de emociones, Dados emocionales, Pregunta libre y Dibujo libre. La portada comparte el fondo, las figuras transparentes y la fila SéTú/UNICEF de Información; Ayuda ya utiliza esa misma composición sobre `CampaignBackground`. Las rutas viven bajo `/inicio/actividades/` y conservan área segura inferior y desplazamiento. Con texto ampliado, las tarjetas de la portada pasan a una columna.

La pregunta educativa diaria sigue disponible desde su banner de Inicio en `/inicio/actividades/diaria`, con las mismas reglas de XP y racha de ADR 0014. Las cinco actividades nuevas no conceden XP ni modifican `LearningProgress`. Las selecciones, emociones al azar, respuestas libres y trazos viven solo en memoria durante la actividad; no se guardan ni se envían. Cambiar la pregunta libre limpia su respuesta anterior. El borrador de dibujo limpia el lienzo completo con confirmación; Deshacer elimina el último trazo.

El rompecabezas ofrece tres escenas, reintentos con explicación amable y opciones con la misma silueta original, diferenciadas por color y texto. `PuzzleBoard` aísla los estados `disconnected`/`connected`; la composición final de piezas conectadas queda para la segunda pasada visual acordada.

El flujo de apoyo utiliza los PNG rasterizados de los SVG originales en `assets/brand/png/` para sus personajes decorativos. Paso 2 presenta `personaje-08` para «Me pasó a mí» y `personaje-14` para «Lo vi o supe de alguien», con etiquetas accesibles y chip «Testigo solidario» en una línea. «Mi pieza» y su personalización mantienen su representación propia.
