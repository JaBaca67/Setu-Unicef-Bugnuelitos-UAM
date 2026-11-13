# Especificación funcional de SéTú

**Revisión:** 2026-11-13. Alcance vigente ADR 0005 y contratos técnicos propuestos en ADR 0006. E01 abre la app y lleva a la demostración escolar E02, a la vista de muestra E09 o al ingreso de personal autorizado M01 ([ADR 0017](decisiones/0017-activacion-personal-mesa-y-cliente-remoto.md)); E02 conecta con el inicio estudiantil E03 ([ADR 0013](decisiones/0013-inicio-estudiantil-e03.md)). Los demás recorridos se describen como diseño. [Bienvenida E01](diseno/plan-arranque-bienvenida-setu.md).

[Recorrido integrado de usuarios](diseno/flujos/08-recorrido-usuarios.svg) · [DFD lógico y diccionario](12-modelado-dfd-kendall.md) · [Recursos de app y paneles](13-recursos-tecnicos.md). ADR 0008 propone el cliente React/TypeScript/Vite para M/L/D, con permisos separados; no cambia pantallas o facultades de producto ni autoriza implementarlas.

## Estudiante

| ID | Pantalla y finalidad | Entradas y acciones | Salida y límites |
| --- | --- | --- | --- |
| E01 | Bienvenida y privacidad | Entender quién recibe qué; entrar con el código del colegio, consultar ayuda o ingresar como personal autorizado | E02, E09 o M01. Información (E10) se abre desde E03. Sin promesa de anonimato absoluto. |
| E02 | Colegio | QR/código público, confirmar centro; pedir cámara solo para escanear | La demo usa QR y GPS con un código de prueba y un punto público local. La simulación de cercanía se identifica en pantalla. Validación institucional y primer ingreso offline pendientes. [Demostración E02](diseno/plan-acceso-escolar-e02.md). |
| E03 | Inicio y Mi racha | Pedir apoyo como acción principal; avatar ilustrado configurable; adelantos de Información, Actividades y Ayuda; tarjeta semanal que abre el calendario mensual | Racha y XP educativos cifrados por instalación, desde cero. Una pregunta correcta al día da 10 XP y la primera lectura confirmada de cada recurso, 5 XP. Repetir una lectura otro día marca el día sin otorgar XP adicionales. Sin puntajes emocionales ni seguimiento estudiantil de casos. [ADR 0014](decisiones/0014-progreso-educativo-local.md). |
| E04 | Solicitud en tres pasos | Tipo de situación; víctima/Testigo Solidario; detalles opcionales | E05. No exigir relato para una alerta mínima válida. |
| E05 | Revisión y envío | Revisar destinatarios, límites y contenido; editar o confirmar | Operación guardada y protegida; E06 muestra entrega real. |
| E06 | Estado de entrega | Ver guardado, transferencia, custodia, recepción local/central; comprobar/reintentar; abrir Información mientras espera | Volver conserva operación y estado. No mostrar recibido central por un acuse de vecino ni reenviar al volver. |
| E07 | Aviso de disponibilidad | Tras enviar una alerta, recibir un aviso cuando una persona autorizada esté disponible para conversar; el aviso abre E08 | El aviso no incluye datos del caso y no se simula como atención real. El estudiante no tiene vista de historial ni de estado interno del caso: ese seguimiento queda en los roles autorizados (M/L/D). Mecanismo técnico pendiente (ADR 0013). |
| E08 | Caso y escucha humana | Estado visible, conversación propia por internet y tarjetas rompehielos; solicitar revisión | Sin chat por mesh. Sin notas internas ni datos del personal innecesarios. Horarios reales cuando existan. |
| E09 | Ayuda | Recursos revisados, territorio, fuente, fecha y horarios; confirmar destino externo | Accesible sin reportar; no presentar contactos de borrador como operativos. |
| E10 | Información | Catálogo por temas y formatos: artículos, videos, testimonios editoriales y guías; disponibilidad real; entrada desde E01/E03 y espera E06/E08 | E11. Parte confirmada de la solución, sin reporte/QR obligatorio para leer. Catálogo, revisión, derechos y diseño final pendientes. |
| E11 | Recurso o guía | Leer/ver voluntariamente con controles, subtítulos/transcripción, fuente y revisión; volver al origen, consultar Ayuda o pedir apoyo | Sin diagnóstico, puntuación emocional o lectura obligatoria. Volver no modifica el caso. Pedir apoyo verifica colegio si hace falta y no envía automáticamente. |

### Recorrido informativo confirmado

[Origen en Meet, referente Netflix y alcance](14-espacio-informativo-y-referente-netflix.md) · [ADR 0009](decisiones/0009-espacio-informativo-confirmado.md) · [Flujo ampliable](diseno/flujos/13-flujo-informacion.svg).

E01/E03 → E10 → elegir tema/recurso → E11. Desde E06/E08 puede abrirse el mismo espacio durante la espera y regresar sin perder operación, redacción o estado real. También puede explorarse por curiosidad o para comprender situaciones/emociones sin querer recibir atención. No se toma un tema leído como diagnóstico o nivel de alerta.

Si un video no está disponible sin internet, se indica y se ofrece solo texto/transcripción realmente disponible; no prometer que todo el catálogo está descargado. No autoplay, cuestionarios diagnósticos o publicación de relatos privados como testimonios. La consulta de contenidos es independiente de la autorización privada de los casos.

### Detalle del reporte

Tipos acordados: acoso físico, verbal, social, ciberacoso, violencia sexual y necesidad de hablar. Selección de rol identifica cómo participa quien pide ayuda, no una identidad civil. Relato, fecha o lugar adicionales no se exigen por defecto. Adjuntos no aprobados para el corte mesh.

Antes de confirmar: explicar aviso mínimo para instituciones y contenido reservado a escucha. No copiar el texto al aviso. Proponer indicación opcional de conflicto para una ruta independiente, pendiente de validación del flujo y destinatarios.

Detalles se conservan en errores/reintentos según política aprobada. No escribir plaintext a temporales. Si no hay claves/configuración confiables, no enviar al vecino ni inventar verificación escolar; explicar qué falta y permitir ayuda.

## Mesa de escucha y MINED

Son funciones diferenciadas de atención y supervisión dentro de la segunda superficie. Los nuevos manuales excluyen chat y relato de todo acceso institucional MINED; la asignación profesional de escucha es independiente.

| ID | Vista | Acciones autorizadas propuestas | Límites |
| --- | --- | --- | --- |
| M01 | Acceso de personal | Correo institucional, contraseña y código de activación individual (`CCA-DIR-2026`, etc.) | No alta pública con rol editable. Activación de un solo uso con verificación de correo y bloqueo tras intentos fallidos ([ADR 0017](decisiones/0017-activacion-personal-mesa-y-cliente-remoto.md)). |
| M02 | Bandeja MINED | Avisos/fichas del ámbito, filtros por nivel, tipo y colegio, asignación manual a Mesa de Escucha y supervisión | No mostrar relato/chat/notas en listados ni detalle. Nivel ausente hasta valoración humana. |
| M03 | Ficha y supervisión | Pedir y exigir actuaciones, escalar por falta de respuesta y revisar el cierre enviado por dirección | MINED cierra según manual; plazos e instancia de escalamiento pendientes. No cierre automático por timeout. |
| L01 | Bandeja de escucha | «Por revisar» (llega «Sin valorar»), «En conversación» y aviso en vivo dentro de la app («Tenés una alerta asignada») | Practicantes bajo supervisión por definir. La asignación permanece en bandeja aunque falle el aviso. |
| L02 | Conversación profesional | Leer relato opcional y pieza estudiantil; habilitar chat humano antes o después de valorar; nota interna aparte; valorar (1/2/3) y emitir ficha mínima | Conversar primero permite reunir contexto y clasificar después. Mensaje visible, nota interna y ficha son acciones distintas. |

La ficha deriva de valoración profesional y solo lleva tipo, rol, hora y nivel; no relato ni capturas. Nivel 1 se resuelve en escucha sin ficha, con facultad de cierre por conciliar; nivel 2 genera ficha; nivel 3 registra derivación urgente sin esperar los pasos del colegio. Esa derivación no es el estado Escalado, reservado en el manual a falta de respuesta institucional. Transiciones propuestas en docs/02.

## Dirección y enlace

| ID | Vista | Acciones | Límites |
| --- | --- | --- | --- |
| D01 | Acceso privado | En la app móvil, cuenta institucional activada por invitación individual, igual que M01 ([ADR 0017](decisiones/0017-activacion-personal-mesa-y-cliente-remoto.md)) | El código privado del centro sigue guardado solo como hash; rotación y revocación por definir. |
| D02 | Avisos y fichas del centro | Ver alerta mínima, recepción local/central, fichas y pendientes | Nunca chat/relato/notas; ruta por conflicto puede restringir destinatarios. |
| D03 | Actuación escolar | Registrar los cinco pasos y proponer cierre con “Documentar y enviar al MINED” | No definir nivel clínico ni cerrar globalmente. Contacto familiar sujeto al procedimiento validado de reserva/autorización. |
| D04 | Registrar alerta de docente | Dirección registra el aviso con origen docente y actor institucional | Docentes fuera de la app; no crear una conversación o identidad estudiantil ficticia. Formulario y campos mínimos por aprobar. |

El panel puede recibir una alerta mínima antes de internet solo si se implementa el contrato local aprobado. Un panel alojado en la nube no funciona por sí solo cuando el colegio está sin internet.

Dirección ve tipo, rol cuando corresponda, hora, estado de reserva y ruta de llegada. El manual propone el paso de contacto familiar bloqueado mientras siga activo el anonimato, sustituyéndolo por acción grupal; su validación de protección y las excepciones quedan pendientes. El registro docente no incorpora chat ni obliga a usar todos los pasos de un reporte estudiantil.

## Teléfono puente y retransmisión

B01 es una referencia propuesta de estado técnico para operador: configuración ficticia de demo, radio/conectividad, cantidad de sobres pendientes y última sincronización. No muestra contenido de los casos, nombres de estudiantes o claves. No es una cuarta superficie clínica ni un acceso para docentes.

Reenviar no permite chatear con otros estudiantes. Publicidad de vecinos e inventarios no exponen el tipo de situación. Detalles de custodia, sobres y acuses en docs/10.

## Variantes obligatorias de diseño

| Contexto | Variantes |
| --- | --- |
| Acceso | Código vacío/incorrecto, QR no legible, permiso denegado, configuración vencida o desconocida offline. |
| Redacción | Teclado, texto grande, detalles vacíos válidos, límite de longitud, volver/descartar sin pérdida accidental. |
| Transporte | Sin vecino, radios apagados, puente offline, acuse perdido, reintento, vencimiento y recepción central tardía. |
| Aviso y chat del estudiante | Sin internet, persona no disponible, aviso perdido o tardío; el aviso nunca lleva datos del caso. El historial y el estado interno del caso son de los roles autorizados. |
| Personal | Sin permiso, rol revocado, ficha fuera de ámbito, concurrencia y conflicto de interés. |
| Editorial | Contenido no descargado, sin fuente vigente o contacto pendiente de validar. |

Los textos de error nunca incluyen relatos, tokens, códigos privados o datos de otra institución. Estados con texto e iconos, no solo color. Ayuda y contenidos no se bloquean por no crear un reporte.

## Aceptación

Ver matriz de aceptación del README. Una maqueta prueba navegación/comprensión; integración prueba permisos y duplicados; equipos físicos prueban radio. El corte Android actual implementa E01, la demostración escolar E02, el inicio estudiantil E03 con vistas de muestra identificadas, E04–E08 sobre el cliente remoto, las superficies móviles M01, M02 (lista y asignación), L01, L02 y D02–D04, y la verificación técnica M1. En la app, M03 queda pendiente y D04 funciona solo en la demostración en memoria. [Pruebas del corte Android](../apps/mobile/README.md).
