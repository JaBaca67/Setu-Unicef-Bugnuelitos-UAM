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

Propuesta tipográfica: cuerpo 16 sp, títulos 22–24 sp y controles adaptables al escalado del sistema. El código M1 conserva algunos colores anteriores: su actualización es un bloque de código pendiente, no un cambio hecho por editar esta guía.

## Navegación y jerarquía

Entrada: bienvenida → QR/código público → confirmar colegio → inicio. No formularios de alias/PIN. Ayuda y contenidos disponibles sin iniciar una solicitud. Navegación propuesta: Inicio, Mi seguimiento, Información y Ayuda. La organización final necesita validación con primaria y secundaria.

Reporte: tipo → rol → detalles opcionales → revisión → estado real de entrega. Los pasos pueden agruparse visualmente si no perjudica comprensión. El estudiante decide cuánto narrar; el campo libre vacío no impide un aviso válido con tipo/rol.

Seguimiento privado: mostrar únicamente casos accesibles mediante mecanismo privado aprobado; código escolar no abre una lista común. Estado de entrega separado del estado del caso.

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
