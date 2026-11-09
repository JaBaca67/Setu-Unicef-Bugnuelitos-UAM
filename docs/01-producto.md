# Visión y alcance

> **Aviso (2026-11-09):** partes de este documento quedaron superadas por [ADR 0005](decisiones/0005-alineacion-con-decisiones-del-equipo-drive.md): acceso sin cuentas por código del colegio (no alias + PIN), población de 3.º a 11.º grado, tres superficies (alumno, MINED, dirección), envío entre dispositivos con modo sin conexión por red mesh y paleta del Manual de Marca final. Ante conflicto, prevalece ADR 0005.

Estado: borrador de trabajo. Fuente principal: planteamiento del equipo el 2026-11-04.

**Decisiones vigentes del 2026-11-05:** cuenta por alias, solicitudes de seguimiento y persistencia protegida local, según [ADR 0003](decisiones/0003-cuenta-alias-y-persistencia-local.md). La app funcional se desarrolla primero en un teléfono; el modelo exclusivamente en memoria se descarta como aplicación principal. La implementación actual sigue limitada a M0.

## Problema y propósito

Estudiantes que sufren o presencian acoso pueden evitar pedir ayuda por miedo a represalias, estigma o falta de confianza en la respuesta escolar. Cureando busca facilitar una solicitud privada de apoyo y conectar esa solicitud con una persona capacitada que pueda actuar.

Hipótesis a validar: un canal comprensible, discreto y con seguimiento ayuda a pedir apoyo. No se ha validado aún con estudiantes ni se ha demostrado una reducción del acoso.

## Personas y población destinataria

- **Población objetivo principal (confirmada para el prototipo):** Adolescentes de educación secundaria en Nicaragua (**12 a 17 años, 7.º a 11.º grado**), tanto quienes sufren directamente situaciones de acoso escolar o ciberacoso (**afectados**) como quienes las observan y desean pedir apoyo sin exponerse a represalias (**testigos**).
- **Enfoque de derechos:** Alineado con el derecho de niñas, niños y adolescentes a una educación libre de violencia, a la integridad física y psíquica, a ser escuchados de forma segura y a la protección de su vida privada y datos personales (referencia inicial: Ley n.º 787 de Nicaragua).

| Persona | Necesidad | Límite |
| --- | --- | --- |
| Estudiante afectado o testigo (12–17 años) | Reportar con lenguaje claro, sin exigir identidad civil, y consultar seguimiento | No accede a casos ajenos |
| Responsable de atención (orientación/psicología) | Revisar, responder y coordinar apoyo | Solo instituciones y casos autorizados |
| Supervisor / Ruta alternativa | Atender casos donde esté implicado personal del centro | Aislado del receptor ordinario en conflicto |
| Administrador institucional | Gestionar personal, invitaciones y configuración | No recibe acceso automático a relatos |
| Operador técnico | Mantener el sistema | Acceso a contenido no habilitado por defecto; soporte excepcional auditado |

Tipos de centro, municipios, participación de familias y criterios de acceso definitivos para piloto siguen pendientes. No asumir que el centro es siempre un destinatario seguro: debe existir un procedimiento alternativo cuando esté implicado su personal.

## MVP y alcance funcional para el Prototipo Ganador (Rúbrica 100 pts)

1. **Bienvenida, límites claros y cultura de "Testigo Solidario" (`E01`):**
   - Explicación breve de privacidad, quién recibe el reporte (Consejería de la Comunidad Educativa / orientación del centro) y horarios reales de atención.
   - Mensaje empático que distingue entre delatar por daño y actuar como **compañero/testigo solidario** para cuidar la integridad de alguien en riesgo.
2. **Cuenta por alias y vinculación escolar sin exigir identidad civil (`E02`):**
   - Registro/acceso principal mediante cuenta por alias; contraseña y recuperación por concretar. El código de invitación vincula la cuenta al centro. QR escolar continúa como propuesta de simulación explícita, no como lector de cámara implementado.
   - Compatible con el uso desde teléfonos propios o tabletas compartidas de **Aulas Digitales Móviles (ADM)**.
3. **Reporte guiado con chips, prevención de crisis y ruta alternativa (`E04`–`E05`):**
   - Selección de rol: **persona afectada ("Me pasó a mí")** o **testigo solidario ("Lo presencié")**.
   - **Categorización guiada mediante chips seleccionables** para reducir el bloqueo ante la hoja en blanco: tipo de situación (*Burlas constantes, Exclusión o aislamiento, Agresión física, Ciberacoso / redes sociales, Otra situación*) y lugar aproximado (*Aula, Recreo / canchas, Baños, Salida del colegio, WhatsApp / redes, Otro*), más relato libre y fecha aproximada opcional.
   - **Detección preventiva local de palabras de riesgo vital:** Sin usar IA clínica ni perfilado en servidor, si el texto escrito contiene términos de riesgo vital inmediato (autolesión, suicidio o peligro físico inminente), la interfaz despliega al instante un aviso cálido con acceso directo a la **Línea 133 del MIFAM (24/7)** recordando que el colegio solo atiende en horario lectivo.
   - **Casilla de conflicto de interés (Ruta alternativa):** Permite indicar si hay personal del centro implicado para enrutar el caso a supervisión independiente y bloquear su lectura al receptor ordinario en conflicto.
4. **Confirmación idempotente y continuidad por Código/PIN de Seguimiento (`E06`–`E07`):**
   - Envío tolerante a fallas de red sin duplicar reportes.
   - La cuenta agrupa sus reportes guardados en el teléfono. Código de Caso + PIN es una vía complementaria por concretar, limitada a un caso y con solicitudes de seguimiento. Sin backend no permite recuperar datos desde otro teléfono o tableta.
5. **Seguimiento conversacional, Cita Discreta y Modo Demo Jurado 2 Minutos (`E08` + `R02`–`R03`):**
   - Vista de conversación asíncrona clara, sin exponer jamás notas internas ni la identidad personal del funcionario.
   - **Opción voluntaria de "Solicitar cita discreta en persona" (`E08`):** Botón para que el estudiante acuerde voluntariamente con orientación un encuentro seguro y discreto (ej. en biblioteca o tutoría general) sin ser llamado frente a su salón.
   - **Modo Demo Jurado 2 Minutos y Triage Pedagógico:** Conmutador instantáneo `Estudiante ↔ Orientador` dentro del APK con plantillas de **Triage Pedagógico** (respuesta cálida de acompañamiento y respuesta educativa frente a mensajes de prueba/broma), permitiendo demostrar en vivo en menos de 2 minutos el ciclo completo.
6. **Directorio de ayuda articulado con Nicaragua (`E09`, accesible con y sin sesión):**
   - Incluye referencias contextualizadas para Nicaragua (marcadas claramente como demostrativas hasta su verificación editorial antes de un piloto): **Línea 133 del MIFAM (atención gratuita 24/7)**, **118 Emergencias**, **Consejerías de las Comunidades Educativas (CCE - MINED)**, **Centros de Atención Psicosocial (CAPS - MINSA)** y opción de canalización a **clínicas psicológicas universitarias aliadas (ej. UAM / UNAN)**.
7. **Autocuidado breve y educación socioemocional (`E10`–`E11`):**
   - Actividades breves y voluntarias de regulación emocional (respiración guiada, pausa en momentos de tensión y cápsula de convivencia solidaria), sin diagnósticos clínicos ni almacenamiento de estados emocionales en el servidor.

La respuesta asíncrona no implica chat en vivo 24/7. Evitar pedir detalles repetidos o material que exponga innecesariamente a otras personas.

## Fuera del MVP

Red social, publicaciones públicas, chats entre estudiantes, adjuntos multimedia, geolocalización, grabaciones, diagnósticos, terapia mediante IA, investigación automática, sanciones y promesas de atención 24/7. Tampoco se incluyen pagos, integración con expedientes escolares o despliegue nacional.

## Recorrido de referencia

Estudiante comprende límites → accede con alias → vincula centro → escribe y revisa → guarda localmente → recibe confirmación local → consulta estado y solicitudes. Atención local de prueba: acceso autorizado → revisión → respuesta → seguimiento. En la etapa futura con Supabase se distinguirán guardado local, envío y recepción institucional, sin simular esa entrega como real.

Si no hay backend o conexión, mostrar que **no se ha enviado al centro**, aunque pueda estar guardado localmente. Persistencia protegida aprobada para datos ficticios; no mostrar un éxito institucional falso.

## Criterios de aceptación iniciales

- El estudiante puede completar el recorrido sin exponer su reporte a otros estudiantes.
- El personal de un centro no puede leer ni modificar casos de otro, ni alterando solicitudes.
- Solo personal autorizado puede cambiar estado o escribir respuestas institucionales.
- Una falla de red permite reintentar sin duplicar el reporte.
- Estados, errores y límites se explican en español sencillo; navegación accesible y sin depender únicamente del color.
- El directorio muestra procedencia y fecha de revisión; un contacto sin validar no se presenta como disponible.

## Evaluación oficial del proyecto (Rúbrica UAM - UNICEF 2026)

De acuerdo con los documentos de la **Jornada Académica y Social para el Cumplimiento de los Derechos de la Niñez y Adolescencia (UAM - UNICEF 2026)** incorporados al repositorio:

1. **Reporte Pautado (50 puntos — Entrega: 10 de noviembre de 2026):**
   - Descripción del problema y evidencia contextualizada (10 pts).
   - Población (12–17 años, secundaria) y enfoque de derechos / barreras de inclusión (10 pts).
   - Solución y grado de innovación: cuenta por alias vinculada al centro, persistencia local protegida y ruta alternativa ante conflicto de interés, envío idempotente y separación de notas internas (12 pts).
   - Impacto social e indicadores observables (8 pts): tasa de finalización del reporte, comprensión de límites de privacidad, tiempo hasta primera respuesta humana y proporción de casos con seguimiento documentado (aclarando que más reportes refleja confianza en el canal, no necesariamente más acoso).
   - Viabilidad técnica/operativa, matriz de riesgos y sostenibilidad (6 pts).
   - Calidad de sustento, redacción y fuentes verificables (4 pts).
2. **Elevator Pitch en vivo (20 puntos — 17 de noviembre de 2026, 3 minutos + 1 min de preguntas):**
   - Síntesis y estructura (5 pts), claridad del problema y solución (5 pts), propuesta de valor y enfoque de derechos (5 pts), comunicación y respuestas fundamentadas al jurado (5 pts).
3. **Prototipo demostrable (30 puntos — 17 de noviembre de 2026, demostración en vivo de 2 minutos):**
   - Coherencia y recorrido de usuario completo desde la necesidad hasta el resultado esperado (10 pts).
   - Nivel de desarrollo y demostración tangible en APK Android (10 pts), incluyendo **Modo Demo Jurado 2 Minutos** (conmutador instantáneo `Estudiante ↔ Orientador` para mostrar envío, recepción, respuesta y lectura en vivo).
   - Inclusión y accesibilidad adecuadas a adolescentes de 12–17 años, lenguaje claro y acceso a ayuda sin sesión (10 pts).
