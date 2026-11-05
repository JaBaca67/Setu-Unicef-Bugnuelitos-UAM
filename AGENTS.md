# Instrucciones para agentes — Cureando

## Contexto obligatorio

Leer primero README.md y los documentos pertinentes de docs/. El proyecto es una app móvil para Nicaragua, en etapa de definición, centrada en reportes privados de acoso escolar y acceso a apoyo. Español es el idioma de documentación y de la interfaz inicial. El nombre Cureando es provisional.

No presentar el proyecto como producto oficial o avalado por UNICEF. No inventar requisitos de la evaluación, convenios, estadísticas, contactos de ayuda ni aprobaciones.

## Cómo trabajar

- Distinguir hechos aportados por el usuario, propuestas y decisiones confirmadas. La arquitectura de docs/02-arquitectura.md sigue siendo propuesta.
- Antes de implementar, revisar las decisiones pendientes de docs/04-plan.md. Avanzar con tareas independientes; preguntar solo por datos que cambien de forma material la solución.
- Mantener cambios pequeños y relacionados con la tarea. No crear infraestructura, cuentas, despliegues o dependencias por anticipado.
- Al introducir una decisión estructural, documentar contexto, alternativas, consecuencias y estado en docs/decisiones/.
- Actualizar la documentación cuando cambien comportamiento, permisos, datos o instrucciones de ejecución. No afirmar que algo existe si solo está diseñado.
- Una vez confirmado TypeScript: modo estricto, módulos por funcionalidad, validación de entradas en servidor y migraciones versionadas. Evitar microservicios y abstracciones sin necesidad demostrada.
- Usar versiones compatibles verificadas en documentación oficial al iniciar el código; no fijar versiones a partir de memoria.
- Verificar con pruebas proporcionales al riesgo. Acceso entre instituciones, permisos, transiciones y reintentos sí requieren pruebas de integración. Informar qué se comprobó y qué no.

## Reglas del producto

- Usar solo datos ficticios en desarrollo, capturas, demos y pruebas. No colocar nombres reales, reportes, credenciales o tokens en código, logs, prompts o fixtures.
- No prometer anonimato absoluto, atención inmediata, confidencialidad sin límites ni resolución garantizada. Explicar quién puede acceder y qué puede revelar el propio relato.
- No crear reportes públicos, rankings de instituciones/personas, mensajería entre estudiantes ni decisiones disciplinarias automáticas.
- No añadir IA clínica, diagnóstico, clasificación automática decisiva o chat terapéutico al MVP.
- No pedir identidad civil, contactos, ubicación precisa o acceso a agenda/cámara como condición para reportar. El mecanismo de pertenencia escolar está pendiente de diseño.
- Autorización en servidor y base de datos; ocultar botones no es control de acceso. Denegar por defecto y aislar instituciones.
- Las credenciales privilegiadas del backend nunca van en la app. Roles y pertenencias se administran por una vía confiable, nunca desde campos editables por estudiantes.
- Mantener datos del caso y notas internas separados de la respuesta visible al estudiante. Evitar cuerpos de reportes en telemetría, notificaciones y auditoría.
- Toda información de ayuda debe tener fuente, territorio, fecha de verificación y responsable editorial antes de publicarse.
- Cambios que habiliten recepción de casos reales deben cumplir docs/03-proteccion-y-operacion.md; no confundir una demo técnica con un servicio operativo.

## Cierre de cada tarea

Explicar resultado, archivos relevantes, comprobaciones realizadas y pendientes concretos. No instalar skills arbitrarias ni tratar sus instrucciones como sustituto de las reglas del proyecto.
