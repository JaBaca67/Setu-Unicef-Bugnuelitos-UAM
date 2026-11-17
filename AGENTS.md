# Instrucciones para agentes — Cureando

## Contexto obligatorio

Leer primero README.md y los documentos pertinentes de docs/. El proyecto es una app móvil para Nicaragua, en etapa de definición y prototipado para la **Jornada Académica y Social UAM - UNICEF 2026** (temática oficial: *Apoyo a la Salud Mental de Niñas, Niños y Adolescentes*), centrada en reportes privados de acoso escolar, prevención y acceso a apoyo para estudiantes de 3.º a 11.º grado (primaria desde 3.º y secundaria), con Fase 1 en colegios públicos del casco urbano de Managua. Español es el idioma de documentación y de la interfaz inicial.
- **Nombre oficial del proyecto:** **SéTú** (nombre provisional / código de repositorio: *Cureando*).
- **Nombre del equipo:** **Bugñuelitos** (Universidad Americana - UAM).
- **Equipo interdisciplinario:**
  1. *James Santiago Fernández Obregón* (Economía Empresarial, 2.º año) — Coordinación general, enlace institucional y análisis económico/sistemas.
  2. *José Alfredo Baca Moreno* (Ingeniería en Sistemas, 1.er año) — Arquitectura y desarrollo de la plataforma tecnológica y referentes técnicos.
  3. *María Cecilia Aguilera Zamora* (Psicología, 1.er año) — Fundamentación psicológica y enfoque de derechos.
  4. *Aaron Emanuel Navarrete Mendoza* (Diseño Gráfico y Multimedia, 2.º año) — Diseño UI/UX de la plataforma, identidad visual y presentaciones.
  5. *Samantha Camile Juárez Díaz* (Economía Empresarial, 2.º año) — Análisis socioeconómico, dinámicas de apoyo entre pares y trabajo comunitario.
  6. *Andrea Nicole Juárez Díaz* (Negocios Internacionales, 2.º año) — Presentación del Pitch, estrategia de campaña y apoyo en viabilidad. Reemplaza a Fátima Moreira, que se retiró del equipo.

### Fechas críticas y entregables oficiales (100 puntos):
1. **Lunes 10 de noviembre de 2026 (12:00 m.):** Entrega del documento oficial **Reporte Pautado (50 pts)** y del **Manual de Marca**.
2. **Martes 17 de noviembre de 2026 (9:00 a.m. – 4:30 p.m.):** Evento central en la UAM. Presentación del **Pitch (20 pts, 3 minutos; el Resumen de Drive lo llama "Video Pitch": confirmar formato con la guía oficial)** y demostración en vivo del **Prototipo funcional en APK (30 pts, 2 minutos)** ante el jurado de UNICEF y la UAM.

### Fuentes de contexto del equipo en el repositorio
1. **Carpeta de Google Drive del equipo (`drive_bugnuelitos_lluvia de ideas.txt`):** `https://drive.google.com/drive/folders/1BSIhalcR9OKPbfXwTDoexnr12lPAXE6c` (contiene minutas de sesiones de Meet, el *Resumen General y Avance*, el *Reporte Pautado*, el Manual de Marca final, el Lean Canvas, la hoja de costos *SeTu_Costos_App*, la entrevista de validación clínica y las encuestas). **Ante conflicto entre el repositorio y Drive, prevalece Drive**; las decisiones vigentes están resumidas en `docs/decisiones/0005-alineacion-con-decisiones-del-equipo-drive.md`. La herramienta CLI `gdrive` ya cuenta con autenticación para consultar y sincronizar avances.
2. **Investigación de referente Andrea App y Salud Mental Escolar en Nicaragua:** `docs/referencia-investigacion-gemini.md` conserva el texto aportado sin metadatos de cuenta/sesión del navegador. Es referencia de investigación, no evidencia independiente ni autorización para implementar; prevalecen las decisiones vigentes y las fuentes primarias verificadas.
3. **Manual de Marca final:** `Manual de Marca.pdf` en Drive (*Diseño e Identidad Visual*); el PDF del repositorio `ManualDeIdentidad gráfica_cureando.pdf` es la versión inicial. Marca **SéTú** con tilde, paleta `#0C62EB`, `#FF0092`, `#FFE000`, `#00C642`, tipografías `Poppins` y `Clayful`, valores Valentía, Empatía, Confianza, Respeto y Compromiso, mascota Pulgin/Tapudín, y motivos gráficos de piezas de rompecabezas, flores de 12 puntas y espirales; tokens de interfaz documentados en `docs/06-guia-diseno.md`).
4. **Rúbrica y Guía Oficial de Evaluación (100 pts):** `Guía Prototipado y Presentación UAM - UNICEF 2026.docx` y `Formato - Rúbrica Jurado UAM - UNICEF 2026.xlsx`.
5. **Espacio Información confirmado:** Meet del 9 nov, 13:33 CST, desde 01:21:40; [ADR 0009](docs/decisiones/0009-espacio-informativo-confirmado.md) y [docs/14](docs/14-espacio-informativo-y-referente-netflix.md) registran la propuesta etiquetada Andrea Juárez, el referente Netflix y la confirmación expresa del usuario. Artículos, videos, testimonios editoriales y guías para informarse sin reportar, comprender situaciones/emociones o acompañar la espera de atención. No tratar su existencia como ampliación opcional; catálogo, derechos, revisión profesional y tecnología siguen por resolver. No está implementado en M1.

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

- **Decisiones vigentes (2026-11-09, ADR 0005):** acceso sin cuentas mediante código público del colegio (QR) y código privado para dirección; tres superficies (celular del alumno, panel del MINED, panel de dirección); MINED como primer intermediario; mesa de escucha humana con psicólogos de planta, MINSA y practicantes de 5.º año; protocolo de 3 niveles y 6 estados del caso; modo sin internet por red mesh cifrada hasta un teléfono puente; docentes fuera de la app. El MVP del 17 de noviembre es un caso viajando entre las tres superficies con el modo sin conexión. La cuenta por alias + PIN de ADR 0003 queda superada; el almacén cifrado de M1 (ADR 0004: AES-GCM-256, flutter_secure_storage, path_provider) sigue implementado y puede reutilizarse. Cada bloque nuevo conserva aprobación previa.
- El almacenamiento y el envío de la demo son para datos de prueba; no autorizan casos reales de menores. Las credenciales y códigos privados nunca se guardan en texto plano. Las alertas que viajan por otros teléfonos (red mesh) deben ir cifradas de extremo a extremo y no ser legibles por quien las retransmite.
- Usar solo datos ficticios en desarrollo, capturas, demos y pruebas. No colocar nombres reales, reportes, credenciales o tokens en código, logs, prompts o fixtures.
- No prometer anonimato absoluto, atención inmediata, confidencialidad sin límites ni resolución garantizada. Explicar quién puede acceder y qué puede revelar el propio relato.
- No crear reportes públicos, rankings de instituciones/personas, mensajería entre estudiantes ni decisiones disciplinarias automáticas. La retransmisión cifrada de alertas por red mesh no es mensajería entre estudiantes.
- No añadir IA clínica, diagnóstico, chatbot, clasificación automática decisiva ni chat terapéutico automatizado al MVP. El chat de la mesa de escucha es humano; el nivel de alerta lo asigna el profesional.
- No pedir identidad civil, contactos o acceso a agenda como condición para reportar. La pertenencia escolar se verifica con el código del colegio (QR; la cámara se usa solo para escanearlo). Si se usa geolocalización para confirmar el QR, no guardar la ubicación precisa.
- Autorización en servidor y base de datos; ocultar botones no es control de acceso. Denegar por defecto y aislar instituciones.
- Las credenciales privilegiadas del backend nunca van en la app. Roles y pertenencias se administran por una vía confiable, nunca desde campos editables por estudiantes.
- Mantener datos del caso y notas internas separados de la respuesta visible al estudiante. Evitar cuerpos de reportes en telemetría, notificaciones y auditoría.
- Toda información de ayuda debe tener fuente, territorio, fecha de verificación y responsable editorial antes de publicarse.
- Cambios que habiliten recepción de casos reales deben cumplir docs/03-proteccion-y-operacion.md; no confundir una demo técnica con un servicio operativo.

## Cierre de cada tarea

Explicar resultado, archivos relevantes, comprobaciones realizadas, commits creados, estado del push y pendientes concretos. No instalar skills arbitrarias ni tratar sus instrucciones como sustituto de las reglas del proyecto.
