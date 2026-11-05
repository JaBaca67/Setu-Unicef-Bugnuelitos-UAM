# Visión y alcance

Estado: borrador de trabajo. Fuente principal: planteamiento del equipo el 2026-11-04.

## Problema y propósito

Estudiantes que sufren o presencian acoso pueden evitar pedir ayuda por miedo a represalias, estigma o falta de confianza en la respuesta escolar. Cureando busca facilitar una solicitud privada de apoyo y conectar esa solicitud con una persona capacitada que pueda actuar.

Hipótesis a validar: un canal comprensible, discreto y con seguimiento ayuda a pedir apoyo. No se ha validado aún con estudiantes ni se ha demostrado una reducción del acoso.

## Personas y responsabilidades

| Persona | Necesidad | Límite |
| --- | --- | --- |
| Estudiante afectado o testigo | Reportar y consultar seguimiento | No accede a casos ajenos |
| Responsable de atención | Revisar, responder y coordinar apoyo | Solo instituciones y casos autorizados |
| Administrador institucional | Gestionar personal y configuración | No recibe acceso automático a relatos |
| Operador técnico | Mantener el sistema | Acceso a contenido no habilitado por defecto; soporte excepcional auditado |

Edades, tipos de centro, municipios, participación de familias y criterios de acceso pendientes. No asumir que el centro es siempre un destinatario seguro: debe existir un procedimiento alternativo cuando esté implicado su personal.

## MVP propuesto

1. Explicación breve de privacidad, límites del servicio y horarios reales de atención.
2. Acceso a institución piloto mediante mecanismo pendiente de validar.
3. Reporte textual como afectado o testigo: qué ocurrió, contexto suficiente y fecha aproximada opcional. No exigir identificar a la persona afectada.
4. Confirmación de recepción y consulta de estado mediante sesión seudónima protegida.
5. Bandeja restringida para una persona responsable, respuesta asíncrona y registro de cambios. Una vista mínima dentro de la app puede servir a la demo; un panel web operativo se evaluará después.
6. Directorio de ayuda local con contactos verificados. Durante la demo, indicar que es ilustrativo si no están validados; nunca inventar números.
7. Pocas actividades breves de autocuidado con contenido revisado, voluntarias, sin guardar estados emocionales en servidor.

La respuesta asíncrona no implica chat en vivo. Evitar pedir detalles repetidos o material que exponga innecesariamente a otras personas.

## Fuera del MVP

Red social, publicaciones públicas, chats entre estudiantes, adjuntos multimedia, geolocalización, grabaciones, diagnósticos, terapia mediante IA, investigación automática, sanciones y promesas de atención 24/7. Tampoco se incluyen pagos, integración con expedientes escolares o despliegue nacional.

## Recorrido de referencia

Estudiante comprende límites → selecciona centro autorizado → escribe y revisa → envía → recibe confirmación real del servidor → consulta estado/respuesta. Responsable entra con su cuenta → revisa su bandeja → evalúa según protocolo humano → responde o deriva → documenta cierre.

Si no hay conexión, mostrar que **no se ha enviado**. No guardar relatos sensibles localmente por defecto ni mostrar un éxito falso.

## Criterios de aceptación iniciales

- El estudiante puede completar el recorrido sin exponer su reporte a otros estudiantes.
- El personal de un centro no puede leer ni modificar casos de otro, ni alterando solicitudes.
- Solo personal autorizado puede cambiar estado o escribir respuestas institucionales.
- Una falla de red permite reintentar sin duplicar el reporte.
- Estados, errores y límites se explican en español sencillo; navegación accesible y sin depender únicamente del color.
- El directorio muestra procedencia y fecha de revisión; un contacto sin validar no se presenta como disponible.

## Evaluación del proyecto

Proponer demostración de utilidad, facilidad de uso, acceso seguro y viabilidad operativa; solicitar la rúbrica oficial antes de prometer alineación. Medir con datos ficticios tasa de finalización, comprensión de privacidad y funcionamiento del seguimiento. En un piloto, cualquier métrica y recolección deben ser aprobadas y minimizar datos; más reportes no equivale por sí solo a más acoso ni a fracaso.
