# Referencia de investigación aportada por el equipo

Texto extraído del contenido de seis respuestas del export de Gemini, sin scripts, datos de cuenta ni metadatos de sesión del navegador. Fuente aportada por el usuario, no validación independiente ni regla de implementación. Las decisiones vigentes se rigen por ADR 0003 y docs/07; las afirmaciones sobre salud, servicios, horarios y eficacia necesitan fuentes primarias antes de publicarse. El HTML original se conserva solo localmente y está excluido de Git.

## Respuesta 1

Andrea App es una plataforma socioeducativa española diseñada por el estudio de innovación Néctar junto a instituciones educativas para prevenir, detectar y mediar en situaciones de acoso escolar (bullying) y ciberacoso, mejorando la convivencia en centros de primaria y secundaria.   Nectar Estudio

Su éxito no radica únicamente en la tecnología, sino en cómo integra la psicología del desarrollo adolescente y la mediación escolar.

Metodología Central: El Enfoque de Mediación y Convivencia

La figura del "Espectador Activo" (Bystander Intervention):

En la mayoría de los casos de acoso, la víctima no denuncia por miedo o vergüenza, y los testigos no actúan por temor a represalias o por ser tildados de "delatores". La metodología de Andrea se centra en activar a los observadores, permitiendo que cualquier estudiante que presencie una conducta inapropiada pueda alertar de forma segura sin exponerse.   Andrea App

Anonimato bidireccional controlado:   Nectar Estudio

El alumno accede mediante un código único de su colegio (sin registrar nombres, correos o números de teléfono personales que los expongan ante sus profesores directos). Esto rompe la barrera del miedo a hablar con la dirección o los tutores escolares.   Andrea App+ 1

Intervención temprana y no punitiva:   www.soyandrea.es

El objetivo principal no es castigar de inmediato, sino abrir un canal de mediación y diálogo antes de que los conflictos escalen. Conecta en tiempo real al alumno con el equipo de orientación o profesionales capacitados del colegio.   www.soyandrea.es+ 1

Estrategias de Producto y UX aplicadas a Jóvenes

EstrategiaCómo se implementaObjetivo psicológico/conductual

UX de Mensajería FamiliarLa interfaz replica aplicaciones de mensajería instantánea habituales entre adolescentes (burbujas de chat, soporte para capturas de pantalla/fotos).Reduce la fricción cognitiva; no se siente como un formulario burocrático formal, sino como una conversación cotidiana.

Categorización Guiada de AlertasOpciones predeterminadas y lenguaje adaptado a su edad para describir lo ocurrido (exclusión social, burlas continuas, agresiones físicas, difusión de imágenes privadas).Ayuda a que los alumnos identifiquen y nombren conductas dañinas que muchas veces tienen normalizadas.

Disponibilidad y Tiempos de RespuestaLa app indica si hay orientadores o profesionales disponibles en ese momento para atender el chat.Gestiona la ansiedad del menor al saber cuándo esperarse una respuesta y refuerza la confianza en el sistema.

Branding Empático y No EstigmatizanteTono visual cálido, ilustraciones amigables y un nombre humano ("Andrea") en vez de siglas frías o alarmistas.Normaliza el uso de la app; tenerla instalada no señala a nadie como "problemático" o "víctima".

Aspectos clave a tener en cuenta para tu propia app

Protocolos de triaje de emergencias: Debes definir qué ocurre si un estudiante reporta una situación de autolesión, violencia física grave o ideación suicida fuera de horario escolar.

Modelo B2B2C (Centro educativo como intermediario): Andrea no funciona como una red abierta al público; los colegios contratan el servicio y asignan a su propio gabinete de orientación o psicología para responder los chats.

Cumplimiento de privacidad: El manejo de datos de menores exige anonimización total de metadatos (como IPs o identificadores de hardware) para evitar rastreos involuntarios dentro del centro escolar.

## Respuesta 2

Para entender cómo opera una herramienta como Andrea en la vida real, hay que mirarla como un engranaje socioeducativo donde la app es el puente seguro y el protocolo humano del colegio es el motor de resolución.

1. Ejemplo de uso real: De la alerta al cierre del caso

Paso 1: La alerta anónima (Perspectiva del estudiante)

Situación: Carlos (14 años) observa que en el grupo de WhatsApp de su clase están compartiendo memes ofensivos sobre Lucía y que en los recreos dos compañeros la empujan y la aíslan sistemáticamente. Carlos quiere ayudar, pero no se atreve a ir al despacho de jefatura de estudios por miedo a que lo vean y lo tilden de "chivato".

Acción en la app: Carlos abre la app, introduce el código de su centro (no necesita crear usuario con nombre ni poner su teléfono). Pulsa en "Crear alerta":   Andrea App

Selecciona el rol: "Soy testigo".

Tipo de situación: "Ciberacoso y exclusión física".   PDA Bullying

Curso aproximado: "2º de la ESO".

Mensaje: "En 2º B se están metiendo todos los días con Lucía en el patio trasero y pasaron fotos editadas de ella por WhatsApp". Puede adjuntar una captura si la tiene.

Paso 2: Recepción y gestión en el panel escolar (Perspectiva del personal)

La alerta entra en un panel web seguro administrado por la Comisión de Convivencia o el Departamento de Orientación / Psicología del colegio.

En la pantalla del orientador aparece un nuevo caso: Alerta #241 - Testigo - 2º ESO. No ven el nombre de Carlos, ni su IP, ni su número de teléfono.

Se abre un chat anónimo bidireccional dentro de la plataforma:   www.soyandrea.es

Orientador: "Hola. Gracias por escribirnos, has hecho lo correcto. Para poder intervenir discretamente sin exponer a nadie, ¿esto suele ocurrir en algún recreo o zona concreta?"

Carlos (Usuario Anónimo): "Sí, casi siempre en el segundo recreo, al lado de las pistas de baloncesto cubiertas".

Orientador: "Comprendido. Vamos a tomar medidas para supervisar la zona y hablar con los tutores sin mencionar este mensaje. Si ves algo más, avísanos por aquí".

Paso 3: Intervención en el plano físico (Cómo se resuelve sin romper el anonimato)

Supervisión encubierta: El equipo directivo refuerza la presencia de profesores de guardia en las pistas durante el segundo recreo de forma "rutinaria". Los docentes presencian directamente la conducta sin que los agresores sospechen de una denuncia.   Andrea App

Abordaje con la víctima (Lucía): El orientador no cita a Lucía de forma evidente; aprovecha una tutoría general de seguimiento académico para preguntarle cómo se siente en el grupo y abrir un espacio seguro donde ella confirme lo que está ocurriendo.

Activación de mediación / Protocolo: Si es un conflicto incipiente, se trabaja en círculos de convivencia y advertencias formales; si se confirma acoso sistemático, se abre formalmente el protocolo oficial del centro escolar (citación individual de familias, medidas disciplinarias y apoyo psicológico a la víctima).   Asociación REA

Cierre en la app: El orientador escribe a la Alerta #241: "Hemos tomado medidas y el caso ya está en seguimiento activo. Gracias por cuidar de tus compañeros". El caso se archiva.

2. Cómo se da a conocer en los colegios (Onboarding y cultura)

Si solo se publica un cartel en un corcho, la app fracasa. Los colegios implementan una estrategia de tres fases:   Asociación REA

Talleres y tutorías presenciales: A principio de curso se dedica una sesión de tutoría donde se explica el concepto de testigo activo. Se les enseña la diferencia entre ser un "chivato" (buscar beneficio perjudicando a otro) y ser un "compañero solidario" (proteger a alguien en peligro).   Asociación REA

El "Código de Centro" físico y digital: Cada alumno recibe un código alfanumérico genérico del colegio. Se proyecta en pantalla y se reparte en tarjetas de bolsillo. Al ser un código idéntico para todos los alumnos del colegio, nadie puede rastrear qué individuo se descargó la app.   Andrea App

Simulacro guiado: En clase se les pide a todos que descarguen la app a la vez para que no exista estigma de "la descargas porque tienes problemas". Se les muestra la pantalla principal y cómo escribiría un mensaje de prueba.

3. Cómo se promueve el buen uso y se evita el troleo (Falsas denuncias)

El mayor temor de un colegio al adoptar este software son las bromas pesadas o reportes falsos. Para mitigarlo se aplican varias capas:

Triage pedagógico humano: Los profesionales del colegio están entrenados para leer entre líneas. Si entra un mensaje como "Fulanito huele mal jajaja", el orientador responde educando: "Este canal está reservado exclusivamente para la seguridad física y emocional de los alumnos. El mal uso de esta herramienta satura la atención a compañeros que realmente lo necesitan".   PDA Bullying

Límites técnicos anti-spam: Rate limiting (límite de mensajes por minuto), filtros automáticos de palabras clave ofensivas y sistemas para silenciar dispositivos temporalmente si envían ráfagas repetidas sin sentido.

Corresponsabilidad comunitaria: Cuando los estudiantes ven que la app realmente resuelve problemas de fondo sin montar escándalos ni delatar a nadie, el respeto hacia la herramienta sube orgánicamente y la tasa de bromas disminuye drásticamente tras las dos primeras semanas.

Aspectos esenciales para tu arquitectura

Gestión de horarios y expectativas: Debe haber un banner visible que aclare: "Este chat no es una línea de emergencias 24/7. Se atiende de lunes a viernes de 8:00 a 15:00. Si estás en peligro fuera de este horario, llama al 112 o al teléfono de ayuda a la infancia".

Panel multi-rol para el centro: El colegio necesita roles diferenciados (por ejemplo: el director tiene vista estadística de cuántos casos hay, pero solo el psicólogo/orientador puede leer los chats para preservar el secreto profesional).

## Respuesta 3

Este es mi plan para abordar el tema. Dime si quieres que haga algún cambio.
 Salud Mental Escolar en Nicaragua Investigar sitios web(1) Investigar aplicaciones móviles, plataformas digitales, líneas de asistencia o iniciativas comunitarias existentes en Nicaragua enfocadas en salud mental, acoso escolar y bienestar emocional en jóvenes.
(2) Analizar los programas oficiales y protocolos gubernamentales en Nicaragua vinculados a la convivencia y bienestar estudiantil:
   (a) programas del Ministerio de Educación (MINED), incluyendo las Consejerías de las Comunidades Educativas
   (b) servicios y programas de salud mental del Ministerio de Salud (MINSA) y del Ministerio de la Familia (MIFAM)
   (c) iniciativas psicosociales de organizaciones y organismos internacionales presentes en el país
(3) Identificar redes y entidades profesionales en Nicaragua viables para la derivación y atención directa de casos estudiantiles:
   (a) clínicas psicológicas universitarias de atención a la comunidad
   (b) asociaciones o colegios de profesionales de la salud mental
   (c) centros de apoyo psicológico comunitarios y líneas telefónicas de crisis
(4) Evaluar la viabilidad técnica y el contexto de conectividad en los colegios públicos de Nicaragua:
   (a) disponibilidad de dispositivos móviles y cobertura de internet en estudiantes de secundaria y primaria
   (b) requerimientos técnicos de bajo consumo de datos y compatibilidad con dispositivos de gama de entrada
(5) Diseñar estrategias pedagógicas y de concienciación para centros educativos:
   (a) actividades y talleres para educar a los jóvenes en la seriedad del cuidado de la salud mental
   (b) medidas educativas y de moderación para prevenir bromas, saturación o reportes falsos
(6) Estructurar el protocolo de operación del chat y la gestión de casos:
   (a) niveles de anonimato y confidencialidad para la protección del menor
   (b) mecanismos de alerta temprana y triaje para situaciones graves o de riesgo vital
(7) Proponer una estrategia de articulación interinstitucional para presentar e implementar el proyecto en escuelas públicas y privadas de Nicaragua.MoreAnalizar resultadosCrear informeEstará lista en unos minutos Modificar plan  Empezar la investigación

## Respuesta 4

I've completed your research. Feel free to ask me follow-up questions or request changes.
Salud Mental Escolar en NicaraguaOct 30, 9:34 PMOpen

## Respuesta 5

La solución completa consiste en un puente digital seguro y confidencial adaptado a la realidad de Nicaragua, que conecta a los estudiantes con las Consejerías de las Comunidades Educativas (CCE) de sus colegios y con redes profesionales externas. Su propósito es romper la cultura del silencio, permitir que los compañeros que ven abusos actúen como testigos solidarios sin miedo a represalias, y ofrecer apoyo emocional temprano antes de que una situación escale a crisis.

A continuación se detalla la solución dividida por áreas, organizada como una lista de verificación (checklist) para el diseño y desarrollo de tu prototipo:

1. Módulo del Estudiante: Reporte y Mediación Escolar (Canal Anónimo)

[ ] Acceso sin datos personales: Ingreso mediante un código único de centro educativo (por ejemplo, COLEGIO-MANAGUA-01), sin requerir nombres, correos personales ni números de teléfono.

[ ] Selección de rol: Opción para identificarse como víctima o como observador/testigo solidario.

[ ] Formulario de reporte guiado: Menú estructurado que ayuda al joven a clasificar la situación (burlas constantes, agresión física, exclusión, ciberacoso) e indicar ubicación aproximada (patio, baños, redes sociales), reduciendo mensajes impulsivos o falsos.

[ ] Adjuntos probatorios: Posibilidad opcional de subir capturas de pantalla de chats o imágenes si se trata de ciberacoso.

[ ] Chat anónimo bidireccional: Canal de mensajería dentro de la app donde el orientador escolar puede hacer preguntas de seguimiento y el estudiante responder desde un seudónimo (ej. Alumno #45).

[ ] Opción de desanonimización acordada: Botón o protocolo dentro del chat para concertar voluntariamente una cita discreta con el orientador escolar (en biblioteca o consejería) sin exponer al alumno frente a su grupo.

2. Módulo de Red Externa: Apoyo Psicológico y Profesional

[ ] Canalización a apoyo universitario: Botón voluntario de "Quiero hablar con un profesional externo", que canaliza la conversación a consultorios y clínicas de psicología de universidades vinculadas (como la UNAN-Managua o la UNCSM) para primeros auxilios psicológicos.

[ ] Directorio georreferenciado de salud mental: Listado y ubicación de los Centros de Atención Psicosocial (CAPS) del MINSA para que los jóvenes y sus familias sepan a qué unidad de salud acudir en su municipio.

3. Módulo de Triaje de Emergencias y Crisis (24/7)

[ ] Filtro de palabras de alto riesgo: Detección de términos vinculados a riesgo vital o "Pérdida de Amor a la Vida" (autolesiones, ideación suicida) y abuso sexual.

[ ] Enlace de emergencia directo: Botón persistente con discado directo y enlace a WhatsApp de la Línea 133 del Ministerio de la Familia (MIFAM), activa las 24 horas.

[ ] Gestión de expectativas horarias: Aviso claro que indique que el chat escolar se atiende en jornada lectiva (lunes a viernes de 7:00 a.m. a 5:00 p.m.) y que en fines de semana o noches deben utilizarse los números de emergencia nacional (133 MIFAM y 118 Policía Nacional).

4. Módulo Preventivo y Socioemocional (Educación para la Vida)

[ ] Recursos socioemocionales interactivos: Guías cortas sobre manejo del estrés, autoestima y resolución pacífica de conflictos alineadas a la Estrategia de Acompañamiento Socioemocional (EAS) del MINED.

[ ] Termómetro / Diario de emociones: Herramienta sencilla para que el alumno registre cómo se siente en el día y reciba consejos breves de autorregulación.

[ ] Cápsulas pedagógicas sobre convivencia: Contenidos breves que explican la diferencia entre ser un "chivato" y ser un "compañero solidario", fomentando la empatía y la responsabilidad colectiva.

5. Panel Administrativo para Centros Educativos (Docentes y CCE)

[ ] Bandeja de gestión de incidencias: Tablero para clasificar reportes por estado (Nueva, En atención/mediación, Resuelta, Derivada).

[ ] Separación estricta de roles:

Los orientadores/enlaces de las CCE atienden los chats confidenciales.

La dirección del centro visualiza estadísticas generales del clima escolar sin vulnerar el secreto profesional.

[ ] Respuestas preconfiguradas ("Triage Pedagógico"): Mensajes tipo para responder con calidez a casos reales y educar a quienes envíen bromas, explicando la importancia de mantener la línea despejada para quienes sufren.

[ ] Generador de actas e informes: Registro formal de actuaciones para documentar los casos según los requerimientos de derivación del MINED y el MIFAM.

6. Especificaciones Técnicas y Adaptabilidad a Escuelas Públicas

[ ] PWA / APK ultraliviano: Aplicación Web Progresiva o instalador inferior a 10 MB para funcionar fluidamente en dispositivos Android de gama de entrada.

[ ] Modo desconectado (Offline-first): Capacidad de redactar un reporte o consultar recursos educativos sin saldo de internet, sincronizando automáticamente los datos al conectarse a una red Wi-Fi o datos móviles.

[ ] Compatibilidad con Aulas Digitales Móviles (ADM): Posibilidad de ser alojada en servidores locales de las escuelas para utilizarse desde las tabletas escolares del MINED.

[ ] Mecanismo anti-spam y rate-limiting: Algoritmo que limite el envío repetido de mensajes continuos y bloquee temporalmente el terminal ante spam deliberado, utilizando identificadores únicos de dispositivo sin registrar la identidad real del usuario.

## Respuesta 6

En el diseño de plataformas de convivencia y reporte seguro escolar existen diferentes mecanismos para autenticar que quien escribe pertenece a la comunidad educativa sin exigir datos personales ni depender exclusivamente de teclear un código alfanumérico.

A continuación se presentan los métodos más utilizados por aplicaciones internacionales (como STOPit, B-resol, Tootoot o plataformas de denuncia protegida tipo Whistleblowing) y cómo funcionan en la práctica:

1. Códigos QR en cartelería escolar (Scan & Report)

Cómo funciona: La institución coloca afiches informativos en puntos estratégicos del colegio (aulas, biblioteca, pasillos, baños). El estudiante simplemente escanea el QR con la cámara de su teléfono.

Mecanismo técnico: El código QR contiene un enlace profundo (deep-link) o una URL que precarga automáticamente el identificador del centro educativo en la aplicación o en la versión web (PWA), evitando que el alumno deba recordar, solicitar o escribir códigos manuales.

Ventajas: Máxima facilidad de uso, elimina la fricción de entrada y no requiere registro de correos ni números telefónicos.

2. Directorio o selector geográfico público (Search & Select)

Cómo funciona: En lugar de exigir un código secreto, la pantalla de inicio presenta un buscador directo donde el alumno selecciona su departamento/municipio y el nombre de su centro escolar desde una lista precargada y validada.

Mecanismo técnico: La aplicación consulta una base de datos pública de centros autorizados. Para evitar que personas ajenas envíen reportes desde cualquier lugar, se pueden activar confirmaciones contextuales simples (por ejemplo: seleccionar el turno al que asiste o responder una pregunta general sobre el colegio).

Ventajas: Utilizado extensamente por plataformas como STOPit en Estados Unidos; permite que los estudiantes o sus familiares reporten desde cualquier computadora o dispositivo sin depender de memorizar credenciales.

3. Tarjetas de tokens impresos aleatorios (Scratch-Cards anónimas)

Cómo funciona: Al inicio del ciclo escolar, durante una asamblea o tutoría general de las Consejerías de las Comunidades Educativas (CCE), se entregan tarjetas impresas al azar a todos los alumnos. Cada tarjeta contiene un identificador único alfanumérico (similar a una tarjeta prepago).

Mecanismo técnico: Las tarjetas no se asignan a ningún nombre en particular ni se registra quién recibió cuál. El token actúa como una "llave de acceso válida" por alumno. Al ser un token único por estudiante:

El sistema sabe con certeza matemática que quien escribe es un alumno real y activo del colegio.

Se evita que un mismo usuario envíe ráfagas masivas de spam desde múltiples cuentas falsas (se puede limitar la cantidad de casos abiertos por token).

La persona mantiene un anonimato absoluto porque ningún profesor ni directivo sabe qué número le tocó a quién.

4. Hash ciego del carnet o código de matrícula del estudiante

Cómo funciona: El alumno introduce su código escolar oficial (el código de estudiante registrado en el MINED).

Mecanismo técnico: La aplicación en el teléfono del usuario aplica inmediatamente una función criptográfica unidireccional con sal (One-Way Salted Hash, como SHA-256) antes de enviar cualquier dato al servidor:
Token Anoˊnimo=SHA-256(Coˊdigo Estudiante+Sal Secreta)\text{Token Anónimo} = \text{SHA-256}(\text{Código Estudiante} + \text{Sal Secreta})Token Anoˊnimo=SHA-256(Coˊdigo Estudiante+Sal Secreta)

El servidor solo almacena la cadena alfanumérica resultante, no el número de carnet original.

La base de datos puede contrastar si el hash pertenece a la lista de códigos válidos del colegio para autorizar el acceso, pero es imposible revertir la operación para saber qué estudiante específico escribió el mensaje.

5. Precarga en dispositivos de las Aulas Digitales Móviles (ADM) / Quioscos escolares

Cómo funciona: La aplicación se encuentra preinstalada o anclada en el navegador de las tabletas o computadoras portátiles pertenecientes a las Aulas Digitales Móviles (ADM) del colegio.

Mecanismo técnico: El software reconoce la dirección IP local de la red escolar o el perfil del dispositivo gestionado (Managed Device Profile). El alumno puede tomar una tableta en horario de receso o en la biblioteca, abrir la app y redactar su reporte sin necesidad de loguearse; el sistema ya sabe a qué centro educativo pertenece la máquina.

6. Sistema de "PIN de seguimiento" (Ticket ID sin contraseña)

Cómo funciona el seguimiento anónimo: Una de las mayores dudas al no usar cuentas personales es: ¿Cómo vuelve a entrar el alumno para leer lo que le respondió el orientador?

Mecanismo técnico: Al enviar el primer reporte, la aplicación genera un código de caso único de 4 a 6 dígitos o una frase de seguridad (por ejemplo: TICKET-8291 o sol-montaña-rio).

El estudiante solo debe guardar ese número o hacer una captura de pantalla.

Para revisar el estado de su caso o chatear con el docente orientador, solo abre la app e introduce ese PIN.

No necesita ingresar correos electrónicos, contraseñas personales ni validar cuentas por SMS.

Comparativa de Métodos

MétodoFacilidad de uso para el alumnoNivel de anonimato realProtección contra bromas y spam

Códigos QR en carteles físicos
Muy alta (solo escanear con la cámara).Total (no pide ningún identificador).Media (requiere moderación pedagógica).

Buscador de directorio escolar
Alta (buscar nombre del centro en lista).Total.Baja / Media (cualquiera puede seleccionar un colegio).

Tokens impresos aleatoriosAlta (introducir el token de la tarjeta).Total (distribución a ciegas).Muy alta (cada alumno tiene una sola llave de acceso).

Hash ciego de carnet estudiantilMedia (el alumno debe saber su código).Criptográfica (cero conocimiento).Muy alta (solo alumnos matriculados acceden).

Dispositivos ADM / Quioscos
Muy alta (equipo ya configurado).Total física y digitalmente.Alta (uso dentro del entorno escolar supervisado).

Recomendación de implementación

Para las escuelas en Nicaragua, la combinación más efectiva y de menor fricción suele ser un modelo híbrido:

Acceso rápido cotidiano: Códigos QR impresos en afiches de las CCE dentro de las escuelas combinados con el buscador de directorio para quienes usen computadoras.

Continuidad del chat: PIN de seguimiento (Ticket ID) para que el menor consulte las respuestas de la consejería con total privacidad desde cualquier dispositivo.

Would you like me to do a more in-depth research instead and propose a research plan?
