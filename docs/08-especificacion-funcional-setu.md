# Especificación funcional de SéTú

**Revisión:** 2026-11-09. Alcance vigente ADR 0005; contratos técnicos propuestos ADR 0006. Los IDs son referencias de diseño, no pantallas ya implementadas ni marcos oficiales de Figma. Código actual: base M1 local con modelo anterior.

[Recorrido integrado de usuarios](diseno/flujos/08-recorrido-usuarios.svg) · [DFD lógico y diccionario](12-modelado-dfd-kendall.md) · [Recursos de app y paneles](13-recursos-tecnicos.md). ADR 0008 propone el cliente React/TypeScript/Vite para M/L/D, con permisos separados; no cambia pantallas o facultades de producto ni autoriza implementarlas.

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
| E08 | Caso y escucha humana | Estado visible, conversación propia por internet y tarjetas rompehielos; solicitar revisión | Sin chat por mesh. Sin notas internas ni datos del personal innecesarios. Horarios reales cuando existan. |
| E09 | Ayuda | Recursos revisados, territorio, fuente, fecha y horarios; confirmar destino externo | Accesible sin reportar; no presentar contactos de borrador como operativos. |
| E10 | Información | Artículos, testimonios y guías; indicar qué está descargado | E11. Contenido híbrido decidido, catálogo y derechos pendientes. |
| E11 | Contenido o guía | Leer, reproducir si está disponible, volver libremente | Sin historial clínico, diagnóstico ni obligación de completar. Actividades digitales adicionales por priorizar. |

### Detalle del reporte

Tipos acordados: acoso físico, verbal, social, ciberacoso, violencia sexual y necesidad de hablar. Selección de rol identifica cómo participa quien pide ayuda, no una identidad civil. Relato, fecha o lugar adicionales no se exigen por defecto. Adjuntos no aprobados para el corte mesh.

Antes de confirmar: explicar aviso mínimo para instituciones y contenido reservado a escucha. No copiar el texto al aviso. Proponer indicación opcional de conflicto para una ruta independiente, pendiente de validación del flujo y destinatarios.

Detalles se conservan en errores/reintentos según política aprobada. No escribir plaintext a temporales. Si no hay claves/configuración confiables, no enviar al vecino ni inventar verificación escolar; explicar qué falta y permitir ayuda.

## Mesa de escucha y MINED

Son funciones diferenciadas de atención y supervisión dentro de la segunda superficie. Los nuevos manuales excluyen chat y relato de todo acceso institucional MINED; la asignación profesional de escucha es independiente.

| ID | Vista | Acciones autorizadas propuestas | Límites |
| --- | --- | --- | --- |
| M01 | Acceso de personal | Sesión institucional con rol/ámbito dados por vía confiable | No alta pública con rol editable. Método por cerrar. |
| M02 | Bandeja MINED | Avisos/fichas del ámbito, filtros por nivel, tipo y colegio, rastreador y agregados | No mostrar relato/chat en listados ni detalle. Nivel ausente hasta valoración humana. |
| M03 | Ficha y supervisión | Pedir y exigir actuaciones, escalar por falta de respuesta y revisar el cierre enviado por dirección | MINED cierra según manual; plazos e instancia de escalamiento pendientes. No cierre automático por timeout. |
| L01 | Bandeja de escucha | Casos asignados y disponibilidad del profesional | Practicantes bajo supervisión por definir. |
| L02 | Conversación profesional | Chat humano, valoración de nivel, nota interna, emisión de ficha/derivación | Mensaje visible, nota y ficha son acciones distintas. |

La ficha deriva de valoración profesional y solo lleva tipo, rol, hora y nivel; no relato ni capturas. Nivel 1 se resuelve en escucha sin ficha, con facultad de cierre por conciliar; nivel 2 genera ficha; nivel 3 registra derivación urgente sin esperar los pasos del colegio. Esa derivación no es el estado Escalado, reservado en el manual a falta de respuesta institucional. Transiciones propuestas en docs/02.

## Dirección y enlace

| ID | Vista | Acciones | Límites |
| --- | --- | --- | --- |
| D01 | Acceso privado | Validar/canjear código privado conforme al mecanismo aprobado | Sin guardarlo en claro; alta, rotación, revocación y atribución por definir. |
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
| Seguimiento | Sin casos accesibles, acceso privado perdido, sesión caducada, error, respuesta pendiente y cerrado. |
| Personal | Sin permiso, rol revocado, ficha fuera de ámbito, concurrencia y conflicto de interés. |
| Editorial | Contenido no descargado, sin fuente vigente o contacto pendiente de validar. |

Los textos de error nunca incluyen relatos, tokens, códigos privados o datos de otra institución. Estados con texto e iconos, no solo color. Ayuda y contenidos no se bloquean por no crear un reporte.

## Aceptación

Ver matriz de aceptación del README. Una maqueta prueba navegación/comprensión; integración prueba permisos y duplicados; equipos físicos prueban radio. Identificar qué capa se verificó sin atribuirle evidencia de las otras. Nada de lo aquí descrito, salvo el corte M1 documentado, se presenta como ya implementado.
