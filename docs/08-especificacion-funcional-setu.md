# Especificación funcional de SéTú

**Revisión:** 2026-11-09. Alcance vigente ADR 0005; contratos técnicos propuestos ADR 0006. Los IDs son referencias de diseño, no pantallas ya implementadas ni marcos oficiales de Figma. Código actual: base M1 local con modelo anterior.

## Estudiante

| ID | Pantalla y finalidad | Entradas y acciones | Salida y límites |
| --- | --- | --- | --- |
| E01 | Bienvenida y privacidad | Entender quién recibe qué; entrar, consultar ayuda o información | E02, E09 o E10. Sin promesa de anonimato absoluto. |
| E02 | Colegio | QR/código público, confirmar centro; pedir cámara solo para escanear | Contexto escolar validado según configuración; sin cuenta/alias/PIN. GPS y primer ingreso offline pendientes. |
| E03 | Inicio | Pedir apoyo, seguimiento privado, información y ayuda | Destinos claros; centro activo sin datos civiles. |
| E04 | Solicitud en tres pasos | Tipo de situación; víctima/Testigo Solidario; detalles opcionales | E05. No exigir relato para una alerta mínima válida. |
| E05 | Revisión y envío | Revisar destinatarios, límites y contenido; editar o confirmar | Operación guardada y protegida; E06 muestra entrega real. |
| E06 | Estado de entrega | Ver guardado, transferencia, custodia, recepción local/central; comprobar/reintentar | No mostrar recibido central por un acuse de vecino. No crear otro caso al reintentar. |
| E07 | Mi seguimiento privado | Abrir solo casos accesibles con mecanismo privado aprobado | E08. El código escolar no lista casos de compañeros. Recuperación pendiente. |
| E08 | Caso y escucha humana | Estado visible, conversación propia y tarjetas rompehielos; solicitar revisión | Sin notas internas ni datos del personal innecesarios. Horarios reales cuando existan. |
| E09 | Ayuda | Recursos revisados, territorio, fuente, fecha y horarios; confirmar destino externo | Accesible sin reportar; no presentar contactos de borrador como operativos. |
| E10 | Información | Artículos, testimonios y guías; indicar qué está descargado | E11. Contenido híbrido decidido, catálogo y derechos pendientes. |
| E11 | Contenido o guía | Leer, reproducir si está disponible, volver libremente | Sin historial clínico, diagnóstico ni obligación de completar. Actividades digitales adicionales por priorizar. |

### Detalle del reporte

Tipos acordados: acoso físico, verbal, social, ciberacoso, violencia sexual y necesidad de hablar. Selección de rol identifica cómo participa quien pide ayuda, no una identidad civil. Relato, fecha o lugar adicionales no se exigen por defecto. Adjuntos no aprobados para el corte mesh.

Antes de confirmar: explicar aviso mínimo para instituciones y contenido reservado a escucha. No copiar el texto al aviso. Proponer indicación opcional de conflicto para una ruta independiente, pendiente de validación del flujo y destinatarios.

Detalles se conservan en errores/reintentos según política aprobada. No escribir plaintext a temporales. Si no hay claves/configuración confiables, no enviar al vecino ni inventar verificación escolar; explicar qué falta y permitir ayuda.

## Mesa de escucha y MINED

Son funciones de atención y supervisión dentro de la segunda superficie. Tener acceso al panel no concede acceso clínico universal.

| ID | Vista | Acciones autorizadas propuestas | Límites |
| --- | --- | --- | --- |
| M01 | Acceso de personal | Sesión institucional con rol/ámbito dados por vía confiable | No alta pública con rol editable. Método por cerrar. |
| M02 | Bandeja MINED | Avisos/fichas del ámbito, filtros y seguimiento | No mostrar relato/chat en listados de supervisión por defecto. |
| M03 | Ficha y supervisión | Solicitar actuaciones, revisar evidencia permitida, escalar/cerrar según facultad | No sanción automática ni cierre por timeout sin protocolo. |
| L01 | Bandeja de escucha | Casos asignados y disponibilidad del profesional | Practicantes bajo supervisión por definir. |
| L02 | Conversación profesional | Chat humano, valoración de nivel, nota interna, emisión de ficha/derivación | Mensaje visible, nota y ficha son acciones distintas. |

La ficha deriva de valoración profesional. Nivel 1 puede cerrar en escucha; nivel 2 puede generar ficha; nivel 3 requiere ruta de protección sin esperar que el colegio avance todos los pasos. Las transiciones propuestas se detallan en docs/02.

## Dirección y enlace

| ID | Vista | Acciones | Límites |
| --- | --- | --- | --- |
| D01 | Acceso privado | Validar/canjear código privado conforme al mecanismo aprobado | Sin guardarlo en claro; alta, rotación, revocación y atribución por definir. |
| D02 | Avisos y fichas del centro | Ver alerta mínima, recepción local/central, fichas y pendientes | Nunca chat/relato/notas; ruta por conflicto puede restringir destinatarios. |
| D03 | Actuación escolar | Registrar acción sobre ficha permitida y ver seguimiento/agregados | No definir nivel clínico, revelar identidad o cerrar globalmente sin facultad. |

El panel puede recibir una alerta mínima antes de internet solo si se implementa el contrato local aprobado. Un panel alojado en la nube no funciona por sí solo cuando el colegio está sin internet.

## Teléfono puente y retransmisión

B01 es una referencia propuesta de estado técnico para operador: configuración ficticia de demo, radio/conectividad, cantidad de sobres pendientes y última sincronización. No muestra contenido de los casos, nombres de estudiantes o claves. No es una cuarta superficie clínica ni un acceso para docentes.

Reenviar no permite chatear con otros estudiantes. Publicidad de vecinos e inventarios no exponen el tipo de situación. Detalles de custodia, sobres y acuses en docs/10.

## Variantes obligatorias de diseño

| Contexto | Variantes |
| --- | --- |
| Acceso | Código vacío/incorrecto, QR no legible, permiso denegado, configuración vencida o desconocida offline. |
| Redacción | Teclado, texto grande, detalles vacíos válidos, límite de longitud, volver/descartar sin pérdida accidental. |
| Transporte | Sin vecino, radios apagados, puente offline, acuse perdido, reintento, vencimiento y recepción central tardía. |
| Seguimiento | Sin casos accesibles, acceso privado perdido, sesión caducada, error, respuesta pendiente y cerrado. |
| Personal | Sin permiso, rol revocado, ficha fuera de ámbito, concurrencia y conflicto de interés. |
| Editorial | Contenido no descargado, sin fuente vigente o contacto pendiente de validar. |

Los textos de error nunca incluyen relatos, tokens, códigos privados o datos de otra institución. Estados con texto e iconos, no solo color. Ayuda y contenidos no se bloquean por no crear un reporte.

## Aceptación

Ver matriz de aceptación del README. Una maqueta prueba navegación/comprensión; integración prueba permisos y duplicados; equipos físicos prueban radio. Identificar qué capa se verificó sin atribuirle evidencia de las otras. Nada de lo aquí descrito, salvo el corte M1 documentado, se presenta como ya implementado.
