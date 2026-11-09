# Especificación Funcional Detallada — Plataforma SéTú (Cureando)

> **Aviso (2026-11-09):** partes de este documento quedaron superadas por [ADR 0005](decisiones/0005-alineacion-con-decisiones-del-equipo-drive.md): acceso sin cuentas por código del colegio (no alias + PIN), población de 3.º a 11.º grado, tres superficies (alumno, MINED, dirección), envío entre dispositivos con modo sin conexión por red mesh y paleta del Manual de Marca final. Ante conflicto, prevalece ADR 0005.

**Estado de implementación:** M1 completa identidad, canal de protección, contratos y motor local cifrado. Las pantallas E01–E11 descritas aquí son objetivo posterior; el APK actual muestra verificación de M1. Sin backend, Código/PIN y solicitudes solo operan en el mismo teléfono. No se han activado llamadas ni derivaciones externas.

**Documento para alineación del equipo Bugñuelitos y desarrollo del Prototipo UAM - UNICEF 2026**  
**Fecha de actualización:** 5 de noviembre de 2026  
**Autores/Equipo:** James Fernández, José Alfredo Baca, Fátima Moreira, María Cecilia Aguilera, Aaron Navarrete, Samantha Juárez.

---

## 1. Propósito y Enfoque del Proyecto

### 1.1. Propósito Central
**SéTú** (nombre clave de repositorio: *Cureando*) es una solución socioeducativa y tecnológica diseñada para adolescentes de secundaria en Nicaragua (**12 a 17 años**), tanto **víctimas** de acoso escolar y ciberacoso como **testigos solidarios** (*compañeros observadores*). Su objetivo es derribar las tres barreras que perpetúan el silencio:
1. **El miedo a represalias y el estigma social** (temor a ser llamado "soplón" o "chivato").
2. **La desconfianza en los canales tradicionales** (miedo a ser expuesto al ir a dirección o consejería).
3. **El tabú sobre la salud mental** (minimización de los problemas emocionales en el hogar y la escuela).

### 1.2. Principios de Diseño
- **No revictimizante:** El lenguaje de la interfaz es cálido, comprensible y horizontal. No juzga, no exige pruebas policiales ni interroga con frialdad.
- **Transparencia radical sobre los límites:** La app explica claramente quién leerá el caso, en qué horarios se atiende y que **no es una línea de emergencias 24/7**.
- **Privacidad y seudonimato:** No se solicita cédula, nombre civil, teléfono personal ni fotografías obligatorias.
- **Acceso universal sin barreras:** Los recursos de ayuda local (`E09`) y autocuidado (`E10`–`E11`) están disponibles incluso sin registrarse y sin conexión a internet.

### 1.3. Análisis Comparativo de Referentes Internacionales (Andrea App y b-resol) y Mejoras en SéTú
A partir del estudio funcional de **Andrea App** (España) y **b-resol** (plataforma escolar europea donde cerca del **80 % de las alertas las envían testigos u observadores**), **SéTú** integra sus mejores prácticas y las adapta a la realidad escolar y de conectividad de Nicaragua:

| Dimensión funcional | Cómo funciona en **Andrea App** / **b-resol** | Cómo lo supera / adapta **SéTú (Cureando)** para Nicaragua |
| --- | --- | --- |
| **Vinculación escolar** | El alumno ingresa un código único del centro educativo al instalar la app (*Andrea* y *b-resol*). | **Doble vía inclusiva (`E02`):** Cuenta estudiantil por **Alias + PIN numérico (4–6 dígitos) + código de respaldo** vinculada por código escolar (`DEMO-NORTE`) o QR simulado del mural, **más** consulta puntual por **Código de Caso + PIN** para alumnos sin celular propio que usan tabletas del Aula Digital Móvil (ADM). |
| **Activación del Testigo (80 % de los reportes)** | Canal anónimo para que los compañeros rompan la "ley del silencio" sin miedo a ser llamados "chivatos" (*b-resol*). | **Ruta de Testigo Solidario dedicada (`E01`, `E04`, `E10`):** Selector explícito *"Lo presencié (Compañero/Testigo solidario)"* con chips adaptados y micro-cápsula educativa sobre cómo apoyar sin ponerse en riesgo físico. |
| **Elección de interlocutor y conflicto de interés** | En *b-resol*, el estudiante ve los perfiles de orientación del colegio y elige a quién dirigir su alerta. | **Selector de destinatario + Salvaguarda de Conflicto de Interés (`E04`/`E05`):** El estudiante puede elegir a qué rol de orientación dirigir su caso (Consejería Escolar CCE, Psicología/Orientación) y marcar la casilla **Conflicto de Interés**, que excluye por autorización local el caso (el cifrado protege el archivo completo, no cada rol por separado) para el personal involucrado y lo desvía a una ruta alternativa. |
| **Alertas tempranas** | Avisos de conflicto inicial antes de que escalen a violencia grave (*Andrea App*). | **Nivel de momento / frecuencia percibida (`E04`):** Chips simples no clínicos (*"Empezó hace poco"*, *"Pasa casi todos los días"*, *"Necesito que alguien lo sepa hoy"*) para ayudar a orientación a priorizar sin usar IA clínica ni diagnósticos. |
| **Chat seguro y continuidad** | Chat bidireccional confidencial entre el menor y el orientador (*Andrea* y *b-resol*). | **Seguimiento asíncrono + Solicitudes estructuradas (`E08`):** Además del chat con separación estricta de notas internas, incorpora botones de 1 toque para **Solicitar cita discreta en persona** (evitando ser llamado frente al aula) y **Solicitar seguimiento** en casos cerrados. |

---

## 2. Mapa de Alcance: Qué VA y Qué NO VA en el Prototipo

Para asegurar una entrega exitosa y con alta calidad técnica para la **Jornada del 17 de noviembre de 2026** (donde el jurado evalúa una demostración en vivo de **2 minutos**), se establece un límite estricto de alcance:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        QUÉ SÍ VA EN EL PROTOTIPO                       │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Módulo del Estudiante:                                              │
│    - E01: Bienvenida con enfoque de "Testigo Solidario".              │
│    - E02: Cuenta por alias + vinculación por código/invitación.        │
│    - E03: Inicio (Home) con accesos directos y aviso de privacidad.    │
│    - E04: Reporte guiado por chips + relato libre + alerta preventiva. │
│    - E05: Revisión de reporte antes de enviar con aviso de horario.    │
│    - E06: Confirmación con Código de Caso + PIN de 4 dígitos.          │
│    - E07: Lista de reportes propios con badge "Respuesta nueva".       │
│    - E08: Conversación asíncrona + botón "Cita discreta en persona".   │
│ 2. Módulo de Ayuda y Bienestar:                                        │
│    - E09: Directorio de ayuda verificado en Nicaragua (sin login).     │
│    - E10-E11: Cápsulas breves de regulación y autocuidado socioemocional│
│ 3. Modo Demo Jurado 2 Minutos (Orientación CCE):                       │
│    - Conmutador instantáneo Estudiante <-> Orientador en el teléfono.  │
│    - Bandeja de casos del centro con filtros por estado.               │
│    - Lectura de caso con separación estricta de notas internas.        │
│    - Respuestas de "Triage Pedagógico" predefinidas y personalizadas.  │
│    - Simulación de corte de red e idempotencia (reintentos sin duplicar│
│ 4. Persistencia Local Protegida (LocalCureandoGateway):                │
│    - Los datos de prueba se guardan en el teléfono y no se borran al   │
│      cerrar o reiniciar la app.                                        │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│                  QUÉ NO VA EN EL PROTOTIPO (EXCLUSIONES)               │
├────────────────────────────────────────────────────────────────────────┤
│ - NO es una red social: no hay muros públicos ni chats entre alumnos.  │
│ - NO hay chat en vivo 24/7 (es mensajería asíncrona institucional).    │
│ - NO hay diagnósticos clínicos automatizados ni IA terapéutica.        │
│ - NO hay geolocalización continua por GPS ni acceso forzoso a cámara.  │
│ - NO hay subida masiva de archivos pesados o videos.                   │
│ - NO hay rankings de agresores, colegios ni sanciones automáticas.     │
│ - NO hay sincronización entre diferentes teléfonos (se añade después   │
│   con Supabase en la fase de backend cloud).                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Desglose Detallado de Pantallas y Funcionalidades

### Pantalla E01 · Bienvenida y Enfoque de Testigo Solidario
- **Objetivo:** Explicar con empatía qué es la plataforma y desestigmatizar el reporte antes de ingresar.
- **Elementos visuales y contenido:**
  - **Identidad:** Isotipo Cureando (`#0D61EB`) y nombre del proyecto **SéTú**.
  - **Titular:** *"Pedir apoyo y cuidar a los demás es el primer paso"*.
  - **Mensaje de Testigo Solidario:** *"Si estás viviendo una situación difícil o ves que alguien en tu colegio la está pasando mal, aquí puedes contarlo de forma privada y segura"*.
  - **Aviso de límites y privacidad:** *"Tu reporte no se publica. Lo revisa el equipo de orientación de tu centro educativo. No es un servicio de emergencias 24/7"*.
  - **Botones de acción:**
    - Botón principal (`FilledButton`, `#0D61EB`): *"Entrar a mi espacio"*.
    - Botón secundario (`OutlinedButton`): *"Buscar ayuda inmediata"* (abre `E09` sin requerir cuenta).

---

### Pantalla E02 · Acceso y Registro por Alias
- **Objetivo:** Permitir el ingreso sin exigir nombre civil, cédula ni datos que expongan al estudiante.
- **Elementos y funcionamiento:**
  - **Selector:** Pestañas *"Crear cuenta por alias"* y *"Ya tengo mi alias"*.
  - **Campos del formulario:**
    - **Alias de usuario:** Identificador elegido por el estudiante (ej. `SolAzul24`, `Companero_07`). No se permite nombre real.
    - **Código de invitación del centro:** Código alfanumérico entregado por la institución escolar (ej. `DEMO-NORTE` para el *Colegio Público Demo Norte*).
    - **Contraseña o PIN personal:** Clave local para proteger el acceso si el teléfono es compartido con hermanos o compañeros de clase.
  - **Botón secundario de simulación (Para el Pitch de 2 minutos):** *"Escanear QR del afiche escolar"* (precarga automáticamente el código del centro simulando la lectura de cartelería escolar).
  - **Acceso alternativo para tabletas compartidas (ADM):** Enlace *"Consultar reporte con Código + PIN de caso"* para estudiantes que no tienen celular y usan equipos compartidos.

---

### Pantalla E03 · Inicio (Home del Estudiante)
- **Objetivo:** Centro neurálgico donde el adolescente encuentra qué hacer sin perderse en menús complejos.
- **Elementos clave:**
  - **Encabezado:** Isotipo, saludo con su alias y nombre de su colegio activo.
  - **Control de Accesibilidad:** Botón visible para alternar tamaño de fuente (`Normal` / `Grande +20%`).
  - **Tarjeta Principal (Hero - `#EEF4FF`):**
    - Titular: *"Pedir apoyo escolar"*.
    - Subtítulo: *"Cuéntanos algo que te ocurrió a ti o que viste en el colegio"*.
    - Botón de acción: *"Contar lo ocurrido"* (navega a `E04`).
  - **Tarjeta Secundaria:**
    - Titular: *"Mis reportes y seguimiento"*.
    - Indicador de estado: Si hay respuestas del orientador sin leer, muestra un badge destacado: *"1 respuesta nueva"*.
    - Botón: *"Ver seguimiento"* (navega a `E07`).
  - **Accesos Rápidos Inferiores:**
    - Botón *"Buscar ayuda inmediata"* (`E09`).
    - Botón *"Cuidarme / Autocuidado"* (`E10`).
  - **Barra de Navegación Inferior:** *Inicio*, *Mis Reportes*, *Ayuda*, *Cuidarme*.

---

### Pantalla E04 · Redacción del Reporte (Guiado por Chips)
- **Objetivo:** Facilitar la narración de lo ocurrido sin generar bloqueo mental ("síndrome de la hoja en blanco").
- **Flujo y componentes guiados:**
  1. **Relación con lo ocurrido:** Dos botones estilo toggle:
     - `[ ] Me pasó a mí (Afectado directo)`
     - `[ ] Lo presencié (Compañero/Testigo solidario)`
  2. **Tipo de situación (Chips seleccionables de un toque):**
     - `Burlas o apodos constantes`
     - `Exclusión o aislamiento social`
     - `Agresión o empujones físicos`
     - `Ciberacoso / Memes en redes o WhatsApp`
     - `Otra situación`
  3. **Lugar aproximado (Chips seleccionables):**
     - `En el aula` | `En el recreo / canchas` | `En los baños` | `A la salida` | `Por internet / celular`
  4. **Relato libre:** Campo de texto amplio con sugerencia: *"Escribe lo que sientas necesario. No necesitas saber términos técnicos"*.
  5. **Detección Preventiva de Riesgo Vital (Filtro local):**
     - Si el alumno escribe términos vinculados a autolesión o ideación suicida, la pantalla despliega un banner cálido en tono rosa suave (`#FFF0F8`):
       > *"Tu vida y tu bienestar son lo más valioso. Si estás sintiendo un dolor muy grande en este momento, comunícate de inmediato con la Línea 133 del MIFAM (gratuita, 24 horas). Tu colegio atiende en horario de clases, pero esta línea te escucha ahora mismo."* (con botón directo de llamada).
  6. **Casilla de Conflicto de Interés (Ruta Alternativa):**
     - Casilla de verificación: `[ ] Esta situación involucra a personal de dirección u orientación del centro`.
     - *Efecto técnico:* Enruta el caso a supervisión independiente y lo oculta de la bandeja del orientador ordinario en conflicto.
  7. **Botón:** *"Revisar antes de enviar"* (navega a `E05`).

---

### Pantalla E05 · Revisión de Reporte y Destinatario
- **Objetivo:** Dar control total al estudiante antes de formalizar el reporte.
- **Contenido:**
  - Resumen visual de lo seleccionado (rol, categorías, lugar y texto escrito) con botón *"Editar"*.
  - **Destinatario explícito:** *"Este reporte será recibido por la Consejería de la Comunidad Educativa (CCE) de [Nombre del Centro]"* (o por *Supervisión Externa* si se marcó conflicto).
  - **Aviso de horario y expectativas:** *"Horario de atención: Lunes a viernes de 7:00 a.m. a 5:00 p.m. Enviar este reporte no genera una sanción automática ni una confrontación pública"*.
  - **Botón principal:** *"Enviar reporte ahora"*.
  - **Tolerancia a fallos de red:** Si no hay conexión o falla la confirmación, el sistema conserva el texto íntegro y ofrece *"Comprobar y reintentar"* con clave de idempotencia para no duplicar el caso.

---

### Pantalla E06 · Confirmación de Recepción y PIN de Caso
- **Objetivo:** Dar tranquilidad inmediata tras el envío y entregar credenciales de respaldo.
- **Contenido:**
  - Ilustración de confirmación en Verde Esperanza (`#00C642`).
  - Titular: *"Tu reporte fue recibido con éxito"*.
  - **Código de Caso:** Identificador opaco de 6 caracteres (ej. `CUR-8421`).
  - **PIN de Seguimiento de 4 dígitos:** Clave numérica (ej. `PIN: 5932`) que permite consultar este reporte específico en el mismo teléfono sin necesidad de tener abierta la cuenta principal; la consulta desde otro dispositivo requiere el backend futuro.
  - Explicación de los siguientes pasos: *"El equipo de orientación revisará tu caso en su horario de atención. Puedes revisar las respuestas en Mis reportes"*.
  - Botón: *"Ver seguimiento"* (navega a `E08`).

---

### Pantalla E07 · Mis Reportes
- **Objetivo:** Listar los casos del estudiante para consultar el historial y los avances.
- **Elementos de cada tarjeta de reporte:**
  - Código de caso (`CUR-8421`) y fecha de creación.
  - Etiqueta de estado visual con soporte textual:
    - `Recibido` (Amarillo `#FFE100`)
    - `En revisión` (Azul `#0D61EB`)
    - `En acompañamiento` (Verde `#00C642`)
    - `Cerrado / Concluido` (Gris neutral)
  - Insignia destacada: *"Respuesta nueva"* si el orientador contestó y el estudiante aún no abre el caso.

---

### Pantalla E08 · Seguimiento y Conversación Asíncrona
- **Objetivo:** Espacio de diálogo seguro entre el estudiante y el orientador asignado.
- **Componentes:**
  - **Resumen desplegable:** Qué se reportó originalmente.
  - **Historial de mensajes:** Burbujas de diálogo claramente diferenciadas:
    - Mensajes del estudiante (alineados a la derecha, tono azul).
    - Mensajes del orientador (alineados a la izquierda, etiqueta *"Equipo de Orientación Escolar"*, sin revelar el nombre personal del funcionario para proteger el marco institucional).
  - **Separación de Notas Internas:** Las notas de trabajo del orientador se guardan en una tabla independiente; **nunca** se incluyen en el modelo visible al estudiante; en este corte local el archivo cifrado conserva ambas clases de información con autorización separada.
  - **Botón voluntario "Solicitar cita discreta en el centro":**
    - Permite al estudiante solicitar acordar una fecha/hora presencial (ej. en biblioteca o consejería) de forma cuidada, evitando que el profesor lo llame frente a sus compañeros de aula.
  - **Casos Cerrados:** Si el caso está cerrado, se explica el motivo de cierre y se habilita el botón *"Solicitar nuevo seguimiento"*, que envía una notificación al orientador sin reabrir automáticamente el estado.

---

### Pantalla E09 · Directorio de Ayuda en Nicaragua (Accesible sin sesión)
- **Objetivo:** Brindar opciones de apoyo inmediatas y verificadas en el país, incluso si el joven no desea reportar a su colegio.
- **Instituciones y líneas articuladas (Datos contextualizados):**
  1. **Línea 133 — Ministerio de la Familia (MIFAM):** Atención gratuita, confidencial y 24/7 para niñas, niños y adolescentes en situaciones de riesgo o violencia.
  2. **Línea 118 — Policía Nacional / Comisaría de la Mujer:** Emergencias de seguridad física inmediata.
  3. **Consejerías de las Comunidades Educativas (CCE - MINED):** Red escolar de apoyo socioemocional y mediación pacífica en centros públicos.
  4. **Centros de Atención Psicosocial (CAPS - MINSA):** Unidades de salud mental comunitarias en municipios de Nicaragua.
  5. **Clínicas Psicológicas Universitarias (UAM / UNAN):** Servicios de atención a la comunidad y primeros auxilios psicológicos a bajo o nulo costo.
- **Protección antes de salir:** Cada tarjeta muestra horarios y fuente de verificación. Al presionar "Llamar", la app muestra un cuadro de confirmación indicando el número antes de abrir la aplicación de teléfono.

---

### Pantallas E10 y E11 · Módulo "Cuidarme" (Autocuidado Breve)
- **Objetivo:** Ofrecer pausas y regulación emocional sin diagnósticos clínicos ni perfilado de datos.
- **Contenido de las 3 cápsulas básicas:**
  1. **Pausa de respiración 4-4-4:** Ejercicio visual con un círculo que se expande y contrae para bajar la frecuencia cardíaca ante momentos de ansiedad o tensión.
  2. **Cápsula del Compañero Solidario:** Mensaje educativo breve que explica por qué no quedarse callado frente al acoso fortalece la convivencia escolar.
  3. **Momento de calma / Anclaje:** Guía rápida de 3 pasos para desconectarse de la saturación de redes sociales o comentarios hirientes.
- **Garantía ética:** La app no guarda "puntuaciones de tristeza", ni lleva diarios emocionales en la base de datos para no exponer la intimidad del menor.

---

### Módulo Especial: Modo Demo Jurado 2 Minutos (Orientación CCE)
- **Objetivo:** Permitir a José Alfredo y al equipo demostrar ante el jurado de UNICEF y UAM en 120 segundos cómo funciona el ciclo completo en vivo.
- **Cómo opera en el APK:**
  - Un botón discreto en la barra superior ("Modo Demostración") permite conmutar en un toque a la **Vista del Orientador Escolar** (`R02` / `R03`).
  - **Acciones demostrables en vivo ante los jueces:**
    1. El estudiante envía un reporte en vivo (`CUR-1024`).
    2. En 1 toque se cambia a la vista del orientador: el reporte aparece en la bandeja con su código y chips.
    3. El orientador selecciona una plantilla de **Triage Pedagógico** (*"Hola, gracias por tu confianza. Estamos dando seguimiento seguro..."*).
    4. El orientador escribe una **Nota Interna Privada** (*"Se revisará en receso con el docente de turno"*).
    5. Se cambia el estado a *"En acompañamiento"*.
    6. Se conmuta de vuelta al Estudiante: se ve la insignia de *"Respuesta nueva"*, se lee el mensaje de apoyo y se comprueba que **la nota interna nunca apareció**, demostrando en vivo la seguridad y confidencialidad del sistema.

---

## 4. Próximos Pasos Recomendados para el Equipo

1. **Compartir esta especificación:** Este documento (`docs/08-especificacion-funcional-setu.md`) sirve como el bosquejo base para que **James**, **Aaron**, **Fátima**, **María Cecilia** y **Samantha** validen el alcance y sepan con exactitud qué pantallas se están implementando.
2. **Coordinar con Aaron (UI/UX):** Los IDs de pantallas (`E01` a `E11`) corresponden exactamente con las secciones del manual de marca y los marcos de Figma.
3. **Avanzar con Codex:** Con este documento cerrado, Codex puede implementar directamente la **Fase M1** (`CureandoTheme` con los colores del PDF, widgets de identidad y la estructura de datos local en `LocalCureandoGateway`).
