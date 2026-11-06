# Cureando — Guía de pantallas para diseño

**Estado M1:** implementados `CureandoTheme`, Poppins local, isotipo de tres piezas con las coordenadas de este documento y motivos de rompecabezas/flor/espiral. La pantalla M1 permite revisar identidad, lectura Normal/Grande y protección de capturas. Formularios completos posteriores. Los renders se revisaron con la fuente real; las combinaciones blanco/azul y texto oscuro/rosa/amarillo/verde se probaron para contraste de texto normal, sin atribuir certificación AA/AAA a toda la app.

**Actualización vigente (2026-11-05):** cuenta estudiantil por alias, solicitudes de seguimiento y persistencia protegida local aprobadas en [ADR 0003](decisiones/0003-cuenta-alias-y-persistencia-local.md). Los diagramas e inventario antiguos no incluyen todavía el nuevo registro; son referencias históricas hasta actualizarse. El plan vigente está en docs/07. No implementar un acceso basado únicamente en invitación ni descartar casos guardados al cerrar la app.

**Diagramas históricos:** [flujos clásicos](diseno/flujos/index.html), disponibles como [imágenes y fuentes](diseno/flujos/README.md). Conservan la versión anterior y necesitan actualizarse con ADR 0003 antes de implementar.

**Entrega simplificada para compartir:** [pantallas explicadas una por una](diseno/pantallas-explicadas.html), con [fuente Markdown](diseno/pantallas-explicadas.md). Esta entrega es independiente de Figma y desarrolla el inventario de esta guía. No hace falta completar el widget de FigJam para comenzar.

Fecha: 2026-11-04. Estado: propuesta de experiencia para el MVP, no pantallas implementadas. Destinatario: persona encargada del diseño en Figma.

## Qué diseñar primero

**P0: pedir apoyo y recibir seguimiento.** Diseñar primero E03 → E04 → E05 → E06 → E07 → E08; después completar entrada E01/E02 y atención R01/R02/R03. Las 11 pantallas P0 permiten demostrar el ciclo completo. P1 añade ayuda y autocuidado: E09/E10/E11. No esperar a terminar P1 para probar el recorrido principal.

P0/P1 indican orden de diseño. La ayuda local verificada y la ruta alternativa de protección son necesarias antes de recibir casos reales, aunque su detalle visual se diseñe después del recorrido principal.

Abrir [el mapa visual en el navegador](diseno/flujo-pantallas.html) o importar [el SVG](diseno/flujo-pantallas.svg) a Figma como referencia visual. El SVG no incluye conexiones de prototipo. [Fuente Mermaid](diseno/flujo-pantallas.mmd) para mantener el diagrama. El FigJam editable requiere completar la selección de equipo en el widget de Figma.

## Referencia de Andrea, contexto de Nicaragua y adaptación

El [funcionamiento público de Andrea](https://www.soyandrea.es/por-que-andrea/) y el [texto de investigación aportado](referencia-investigacion-gemini.md) aportan elementos para evaluar en Cureando; no sustituyen verificación primaria ni decisiones de producto:
- **Enfoque de Testigo Solidario (*Bystander Intervention*):** Desestigmatizar pedir ayuda mostrando que reportar una agresión hacia otro es ser un compañero solidario, no un "soplón".
- **Reporte guiado con chips (`E04`):** Ofrecer etiquetas seleccionables de tipo de situación y lugar aproximado para reducir la fricción de la hoja en blanco, más detección preventiva local de palabras de riesgo vital que sugiere al instante la **Línea 133 del MIFAM (24/7)**.
- **Acceso (`E02`) y continuidad:** cuenta por alias como acceso principal, invitación para vincular centro y QR simulado como propuesta auxiliar. Código de Caso + PIN sería complementario y limitado a un caso con solicitudes de seguimiento, con detalles pendientes. La consulta desde otra tableta requerirá backend; no está disponible con almacenamiento exclusivamente local.
- **Articulación local (`E08`/`E09`) y Triage Pedagógico:** Botón voluntario en `E08` para *"Solicitar cita discreta en el colegio"*, respuestas preconfiguradas de *Triage Pedagógico* para el orientador en el Modo Demo Jurado, y directorio `E09` articulado con **CCE-MINED, Línea 133 MIFAM, CAPS-MINSA y clínicas psicológicas universitarias (UAM/UNAN)**.

---

## Sistema de Diseño Visual y Tokens para Flutter (`CureandoTheme`)

Basado en el archivo `ManualDeIdentidad gráfica_cureando.pdf` y evolucionado para cumplir con el puntaje máximo de **Inclusión y Accesibilidad (10 pts de la Rúbrica UAM - UNICEF 2026)** y contraste **WCAG AA/AAA** en pantallas móviles para adolescentes de 12 a 17 años:

### 1. Paleta cromática oficial (Extraída del Manual + Superficies Accesibles UI)

Los colores vibrantes del manual se utilizan como **acentos de identidad, botones primarios, insignias e ilustraciones geométricas**, nunca como fondos masivos que fatiguen la lectura durante un reporte sensible:

| Token en Flutter | Hexadecimal | Origen / Uso en la interfaz |
| --- | --- | --- |
| `brandBlue` (Primary) | `#0D61EB` | **Azul Cureando (Manual PDF):** Isotipo, botón principal (*Pedir apoyo*, *Enviar*), encabezados clave y estado `En revisión`. |
| `brandBlueSoft` | `#EEF4FF` | Superficie suave para tarjetas destacadas de inicio, chips seleccionados y burbujas informativas del centro. |
| `brandPink` (Urgent/Help) | `#FF0091` | **Rosa/Magenta (Manual PDF):** Acento de atención inmediata, acceso rápido a `E09 Buscar ayuda` / Línea 133 y alertas de protección. |
| `brandPinkSoft` | `#FFF0F8` | Fondo suave para el bloque de emergencia / riesgo vital y tarjeta de ayuda sin sesión (con texto oscuro `#831843`). |
| `brandYellow` (Warmth) | `#FFE100` | **Amarillo Sol (Manual PDF):** Acento cálido para ornamentos (flores/espirales), avisos de horario y estado `Recibido`. |
| `brandYellowSoft` | `#FFFBEB` | Fondo cálido legible para bloques de privacidad, recordatorios antes de enviar (`E05`) e insignia `Recibido` (con texto `#92400E`). |
| `brandGreen` (Support) | `#00C642` | **Verde Esperanza (Manual PDF):** Confirmación de recepción (`E06`), estado `En acompañamiento`, cápsulas `Cuidarme` (`E10`–`E11`) y sello de *Testigo Solidario*. |
| `brandGreenSoft` | `#ECFDF5` | Fondo suave para confirmación de reporte enviado, tarjeta de *Compañero Solidario* y actividades de bienestar (con texto `#065F46`). |
| `surfaceBackground` | `#F8FAFC` | Fondo general limpio de las pantallas para descanso visual y máxima legibilidad. |
| `cardSurface` | `#FFFFFF` | Fondo de tarjetas, campos de texto y modales con borde sutil `#E2E8F0` y radio `16px`–`20px`. |
| `textPrimary` | `#0F172A` | Texto principal oscuro (contraste > 14:1 sobre blanco y > 10:1 sobre superficies suaves). |
| `textSecondary` | `#475569` | Subtítulos, ayudas de campo y marcas de tiempo. |

### 2. Tipografía y jerarquía legible (Escalable)

- **Fuente principal UI (`Poppins` — presente en el Manual PDF):**
  - Títulos de pantalla (`Headline`): `Poppins Bold`, `22–24 sp`, `height: 1.25`.
  - Subtítulos y títulos de tarjeta (`Title`): `Poppins SemiBold`, `16–18 sp`.
  - Cuerpo de lectura y relatos (`Body`): `Poppins Regular` / `Medium`, `15–16 sp`, `height: 1.45` (nunca menor a `14 sp`).
- **Acento de marca (`Clayful-Regular` — presente en el Manual PDF):** Reservado exclusivamente para el logotipo/encabezado de marca o numerales decorativos (`01`, `02`), nunca para párrafos largos ni formularios.
- **Control de accesibilidad visible para el jurado:** Incluir un control rápido de tamaño de lectura (`Normal` / `Texto grande +20%`) en la barra superior o perfil de sesión para demostrar en vivo el criterio de accesibilidad de la rúbrica.

### 3. Motivos gráficos del Manual integrados con sobriedad en Flutter (Coordenadas vectoriales exactas)

Extraídos directamente de los flujos vectoriales de `ManualDeIdentidad gráfica_cureando.pdf` (páginas 1 a 13) para que los agentes de desarrollo (Codex) dibujen los elementos originales con fidelidad matemática mediante `CustomPainter`:

1. **Isotipo Oficial SéTú / Cureando (Cuadrado de 3 piezas orgánicas en `#0D61EB`, Portada pág. 1):**
   - **Geometría exacta (`viewBox: 87.6853 × 87.6853`):**
     - Radio base de cada módulo: `R = 42.734` (`r = R / S = 0.487356` del lado total `S = 87.6853`).
     - Separación interna (canal entre columna izquierda y derecha, y entre pieza superior e inferior izquierda): `G = 2.2173` (`g = G / S = 0.025287`).
     - **Pieza 1 (Superior izquierda):** Sector de cuarto de círculo anclado en la esquina superior izquierda `(0, 0)` con bordes rectos hacia `(R, 0)` y `(0, R)`, y arco convexo de radio `R` desde `(R, 0)` hasta `(0, R)`.
     - **Pieza 2 (Inferior izquierda):** Sector de cuarto de círculo anclado en la esquina inferior izquierda `(0, S)` con bordes rectos hacia `(0, R + G)` y `(R, S)`, y arco convexo de radio `R` desde `(0, R + G)` hasta `(R, S)`.
     - **Pieza 3 (Columna derecha — Hoja vertical):** Ocupa `x ∈ [R + G, S]` y `y ∈ [0, S]` (ancho `R`, alto `S`). Esquina superior izquierda `(R + G, 0)` recta (90°); esquina superior derecha redondeada con radio `R` (de `(R + G, 0)` a `(S, R)`); borde derecho recto hasta la esquina inferior derecha `(S, S)` recta (90°); esquina inferior izquierda redondeada con radio `R` (de `(S, S)` a `(R + G, S - R)`); borde izquierdo recto de regreso a `(R + G, 0)`.
   - **Implementación exacta para Flutter (`lib/shared/widgets/setu_brand_mark.dart`):**
     ```dart
     class SetuBrandMarkPainter extends CustomPainter {
       const SetuBrandMarkPainter({this.color = const Color(0xFF0D61EB)});
       final Color color;

       @override
       void paint(Canvas canvas, Size size) {
         final double s = size.shortestSide;
         final double r = s * 0.487356; // 42.734 / 87.6853
         final double g = s - (2 * r);  // 2.2173 / 87.6853
         final Paint paint = Paint()
           ..color = color
           ..style = PaintingStyle.fill
           ..isAntiAlias = true;

         // 1. Pieza superior izquierda
         final Path topLeft = Path()
           ..moveTo(0, 0)
           ..lineTo(r, 0)
           ..arcToPoint(Offset(0, r), radius: Radius.circular(r), clockwise: true)
           ..close();

         // 2. Pieza inferior izquierda
         final Path bottomLeft = Path()
           ..moveTo(0, s)
           ..lineTo(0, r + g)
           ..arcToPoint(Offset(r, s), radius: Radius.circular(r), clockwise: true)
           ..close();

         // 3. Pieza derecha (hoja vertical con esquinas opuestas redondeadas)
         final double x0 = r + g;
         final Path rightLeaf = Path()
           ..moveTo(x0, 0)
           ..arcToPoint(Offset(s, r), radius: Radius.circular(r), clockwise: true)
           ..lineTo(s, s)
           ..arcToPoint(Offset(x0, s - r), radius: Radius.circular(r), clockwise: true)
           ..close();

         canvas.drawPath(topLeft, paint);
         canvas.drawPath(bottomLeft, paint);
         canvas.drawPath(rightLeaf, paint);
       }

       @override
       bool shouldRepaint(covariant SetuBrandMarkPainter oldDelegate) =>
           oldDelegate.color != color;
     }
     ```
2. **Pieza de rompecabezas redondeada (*Conexión, pertenencia y Testigo Solidario*, págs. 4–11 y 13):**
   - Cuadrado de esquinas redondeadas (`borderRadius: 0.18 * lado`) con muescas/pestañas circulares (`radio: 0.16 * lado`) en dos lados adyacentes o cinta horizontal con dos muescas circulares en el extremo izquierdo (como los encabezados de sección en págs. 4–11).
   - Se utiliza como insignia visual en la tarjeta de **Testigo Solidario**, en los encabezados de cápsulas y en el selector de perfil/orientador.
3. **Flor / Estrella de 12 pétalos redondeados (*Bienestar, escucha y comunidad*, págs. 1–13):**
   - Estrella radial simétrica de **12 puntas con extremos semicirculares** (`radio exterior R_out`, `radio interior R_in ≈ 0.58 * R_out`, 12 lóbulos cada `30°` con tapas redondeadas).
   - Se usa como ornamento suave en esquinas de tarjetas destacadas (`E01`, `E03`, `E10`) y como sello visual de confirmación (`E06`).
4. **Espiral orgánica de trazo grueso (*Acompañamiento continuo y desahogo*, págs. 1–12):**
   - Espiral arquimediana/logarítmica de 1.75 vueltas con `StrokeCap.round` y grosor `0.11 * ancho`, usada como ilustración de respiración guiada en `E11` y decoración sutil de cabeceras.

## Inventario de pantallas

| ID / prioridad | Pantalla y propósito | Contenido mínimo | Acción y destino |
| --- | --- | --- | --- |
| E01 · P0 | Bienvenida y privacidad: comprender el servicio | Qué permite hacer, quién recibe el reporte, límites de privacidad y atención; sin carrusel obligatorio | Continuar → E02; Buscar ayuda → E09 |
| E02 · P0 | Registro/acceso con alias y vinculación al centro | Alias, PIN de 4–6 dígitos, respaldo local y código escolar (ADR 0004); formularios por integrar, sin nombre civil | Acceso válido → E03; ayuda → E09 |
| E03 · P0 | Inicio: encontrar rápidamente qué hacer | Centro activo, botón principal Pedir apoyo, acceso a Mis reportes, Ayuda y Cuidarme | E04 / E07 / E09 / E10 |
| E04 · P0 | Contar lo ocurrido: redactar sin presión | Me pasa a mí / Lo presencié; relato; contexto y fecha aproximada opcionales; recordar no incluir datos innecesarios | Revisar → E05; volver con aviso si se perderá texto |
| E05 · P0 | Revisar reporte: decidir antes del envío | Resumen editable, destinatario real del centro, límites y horario; no exigir identificar a personas | Editar → E04; Enviar → estado de carga y E06 solo tras confirmación |
| E06 · P0 | Reporte recibido: confirmar recepción | Confirmación real, referencia del caso, siguiente paso, horario acordado y explicación de cómo volver a consultar | Ver seguimiento → E08; Inicio → E03 |
| E07 · P0 | Mis reportes: recuperar seguimiento | Casos de la cuenta autorizada guardados localmente; referencia, estado y señal de respuesta nueva | Abrir → E08; Pedir apoyo → E04 |
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
- No pedir nombre civil, foto, cédula, teléfono o ubicación para acceder. Aplicar cuenta Alias/PIN y recuperación local por respaldo de ADR 0004; Código/PIN de caso no equivale al acceso completo de la cuenta ni opera entre dispositivos sin backend.
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
