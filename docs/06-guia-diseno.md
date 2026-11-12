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

Racha y XP acompañan solo actividades educativas voluntarias (leer una guía, ver un video, responder la pregunta del día sobre el contenido) y en la demo llevan valores de ejemplo etiquetados. Sin rankings públicos, puntajes emocionales ni recompensas por enviar alertas; apoyo, chat, Información y Ayuda disponibles con cualquier progreso. El avatar del estudiante es ilustrado y se configura con opciones gráficas, sin foto, nombre ni cuenta.

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
