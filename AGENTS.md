# Instrucciones para agentes — Cureando

## Contexto obligatorio

Leer primero README.md y los documentos pertinentes de docs/. El proyecto es una app móvil para Nicaragua, en etapa de definición y prototipado para la **Jornada Académica y Social UAM - UNICEF 2026**, centrada en reportes privados de acoso escolar y acceso a apoyo para adolescentes de secundaria (12 a 17 años). Español es el idioma de documentación y de la interfaz inicial. El nombre Cureando es provisional.

### Fuentes de contexto del equipo en el repositorio
1. **Carpeta de Google Drive del equipo (`drive_bugnuelitos_lluvia de ideas.txt`):** `https://drive.google.com/drive/folders/1BSIhalcR9OKPbfXwTDoexnr12lPAXE6c` (contiene grabaciones/notas de sesiones de Meet, lluvia de ideas y el documento entregable del **Reporte Pautado**). Si un agente cuenta con integración/acceso web o plugin de Google Drive habilitado y el usuario lo solicita, debe consultarlo para sincronizar avances.
2. **Investigación de referente Andrea App y Salud Mental Escolar en Nicaragua:** `docs/referencia-investigacion-gemini.md` conserva el texto aportado sin metadatos de cuenta/sesión del navegador. El export HTML original se mantiene solo localmente, excluido de Git. Es referencia de investigación, no evidencia independiente ni autorización para implementar; prevalecen las decisiones vigentes y las fuentes primarias verificadas.
3. **Manual de Identidad Gráfica inicial:** `ManualDeIdentidad gráfica_cureando.pdf` (isotipo azul `#0D61EB`, paleta `#0D61EB`, `#FF0091`, `#FFE100`, `#00C642`, tipografías `Poppins` y `Clayful`, y motivos gráficos de piezas de rompecabezas, flores de 12 puntas y espirales; tokens de interfaz documentados en `docs/06-guia-diseno.md`).
4. **Rúbrica y Guía Oficial de Evaluación (100 pts):** `Guía Prototipado y Presentación UAM - UNICEF 2026.docx` y `Formato - Rúbrica Jurado UAM - UNICEF 2026.xlsx` (Reporte Pautado 50 pts el 10/11/2026; Elevator Pitch 20 pts + Prototipo en vivo 30 pts en 2 minutos el 17/11/2026).

No presentar el proyecto como producto oficial o avalado por UNICEF. No inventar requisitos de la evaluación, convenios, estadísticas, contactos de ayuda ni aprobaciones.

## Cómo trabajar

- **Commits incrementales obligatorios:** Guardar cada avance coherente y verificado en un commit pequeño, con mensaje que describa el cambio. Separar código, documentación y referencias cuando tenga sentido. Revisar el diff y archivos incluidos antes de confirmar; no usar `git add .` a ciegas, no incluir secretos, APK, cachés, bases locales ni datos personales. No mezclar trabajo ajeno sin revisarlo. Hacer push al remoto del proyecto al cerrar el bloque autorizado, si está disponible; informar hash, comprobaciones y cualquier pendiente de sincronización. No reescribir historial ni hacer force push sin autorización explícita. Esta autorización de guardado no elimina la aprobación previa para implementar.
- **Revisión y aprobación previa obligatoria:** Ningún agente debe implementar código, migraciones, estructuras de carpetas ni instalar dependencias sin antes presentar la propuesta del paso actual, formular preguntas claras al usuario sobre las decisiones implicadas y recibir su aprobación explícita.
- **Recomendación de modelo según complejidad:** Los agentes deben evaluar la complejidad de cada tarea y recomendar proactivamente al usuario cambiar a un modelo más ligero/rápido para tareas mecánicas o sencillas (ej. ajustes de textos, estilos simples, formateo) o a un modelo de razonamiento más profundo para tareas críticas o complejas (ej. arquitectura de seguridad, políticas RLS, depuración difícil o diseño de contratos).
- Distinguir hechos aportados por el usuario, propuestas y decisiones confirmadas. Flutter/Dart, Supabase como backend futuro y las decisiones de M0 están confirmados; el modelo de datos y las políticas de docs/02-arquitectura.md siguen en diseño.
- Antes de implementar, revisar las decisiones pendientes de docs/04-plan.md. Avanzar con tareas independientes; preguntar solo por datos que cambien de forma material la solución.
- Mantener cambios pequeños y relacionados con la tarea. No crear infraestructura, cuentas, despliegues o dependencias por anticipado.
- Al introducir una decisión estructural, documentar contexto, alternativas, consecuencias y estado en docs/decisiones/.
- Actualizar la documentación cuando cambien comportamiento, permisos, datos o instrucciones de ejecución. No afirmar que algo existe si solo está diseñado.
- **Higiene documental contra alucinaciones:** Cada vez que se tome o cambie una decisión importante (stack, alcance, flujo o reglas), actualizar de inmediato todos los documentos afectados (`README.md`, `docs/`, `docs/decisiones/`) eliminando o reemplazando las propuestas obsoletas para que ningún agente recuerde ni aplique reglas descartadas.
- Con Flutter/Dart confirmado para móvil y Supabase/PostgreSQL para backend: tipado estricto y análisis estático en Dart (`analysis_options.yaml`), módulos por funcionalidad (`lib/features/`), validación de entradas en servidor y migraciones SQL versionadas. Evitar microservicios y abstracciones sin necesidad demostrada.
- Usar versiones compatibles verificadas en documentación oficial al iniciar el código; no fijar versiones a partir de memoria.
- Verificar con pruebas proporcionales al riesgo. Acceso entre instituciones, permisos, transiciones y reintentos sí requieren pruebas de integración. Informar qué se comprobó y qué no.

## Reglas del producto

- **Decisiones vigentes (2026-11-05):** construir una app funcional local, con cuenta estudiantil por alias (propuesta de contraseña y recuperación aún por concretar), solicitudes de seguimiento y persistencia protegida en el teléfono. Los casos guardados no se pierden al cerrar el proceso. `LocalCureandoGateway` es el adaptador objetivo; Supabase sigue como backend futuro. No volver al mock exclusivamente en memoria como aplicación principal. Los detalles de almacenamiento, cifrado y paquetes requieren propuesta y aprobación antes de implementarse. Ver ADR 0003.
- El almacenamiento local aprobado es para datos de prueba; no autoriza casos reales de menores. Los borradores sin enviar siguen siendo temporales; las credenciales nunca se guardan en texto plano. Sin Supabase no hay sincronización ni envío real a otros dispositivos.
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

Explicar resultado, archivos relevantes, comprobaciones realizadas, commits creados, estado del push y pendientes concretos. No instalar skills arbitrarias ni tratar sus instrucciones como sustituto de las reglas del proyecto.
