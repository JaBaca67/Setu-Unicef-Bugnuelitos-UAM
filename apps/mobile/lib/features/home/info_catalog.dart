import 'package:flutter/material.dart';

import 'student_preview_cards.dart';

/// Catálogo inicial verificado el 16 nov 2026 (ADR 0026).
/// Resúmenes adaptados por SéTú; pendiente revisión profesional.
enum InfoTopic {
  acoso('Acoso escolar', 'Acoso escolar'),
  ansiedad('Ansiedad', 'Ansiedad'),
  depresion('Depresión', 'Depresión'),
  ciberacoso('Ciberacoso', 'Ciberacoso'),
  emociones('Emociones', 'Emociones'),
  apoyo('Apoyo', 'Apoyo');

  const InfoTopic(this.label, this.chip);
  final String label;
  final String chip;
}

enum InfoFormat {
  guide('Guía'),
  video('Video'),
  story('Historia ilustrada'),
  quiz('Pregunta');

  const InfoFormat(this.label);
  final String label;
}

@immutable
class InfoPoint {
  const InfoPoint(this.title, this.body, [this.icon = Icons.lightbulb_outline]);
  final String title;
  final String body;
  final IconData icon;
}

@immutable
class InfoResource {
  const InfoResource({
    required this.id,
    required this.format,
    required this.topic,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.points,
    this.offline = true,
    this.thumbAsset,
    this.cardAsset,
    this.bannerAsset,
    this.caption,
    this.options = const <String>[],
    this.correct = 0,
    this.organization = '',
    this.url = '',
    this.verified = false,
    this.notes = '',
    this.optionFeedback = const <String>[],
  });

  final String id;
  final InfoFormat format;
  final InfoTopic topic;
  final String title;
  final String summary;
  final int? minutes;
  final List<InfoPoint> points;

  /// Empaquetado en la app (texto). Los videos requieren conexión.
  final bool offline;
  final String? thumbAsset;
  final String? cardAsset;
  final String? bannerAsset;

  /// Pregunta de cierre de una ruta.
  final String? caption;
  final List<String> options;
  final int correct;
  final String organization;
  final String url;
  final bool verified;

  /// Notas editoriales de la fuente de desarrollo; no son revisión profesional.
  final String notes;
  final List<String> optionFeedback;

  String get route => '/inicio/recurso/$id';
  bool get isVideo => format == InfoFormat.video;
  bool get isQuiz => format == InfoFormat.quiz;
  String get availability => offline ? 'Sin internet' : 'Con internet';
  String get meta => isVideo ? 'Video' : '${format.label} · $minutes min';
  StudentCover get cover => isVideo ? StudentCover.video : StudentCover.guide;
}

const String _info = 'assets/home/info';

const List<InfoResource> infoCatalog = <InfoResource>[
  InfoResource(
    id: "acoso-guia-prevenir",
    title: "Qué es el acoso escolar y cómo se ve",
    summary:
        "Explica qué es el acoso escolar, sus formas (física, verbal, exclusión, en redes) y quiénes participan.",
    organization: "UNICEF Comité Español (publicada por UNICEF Ecuador)",
    url: "https://www.unicef.org/ecuador/media/14476/file",
    topic: InfoTopic.acoso,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "PDF de 24 páginas (2019) dirigido a madres y padres en España; se abrió y extrajo el texto. Puntos adaptados a lo que el estudiante puede hacer. Usa vocabulario de España ('colegio', 'móvil').",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_featured_broma.png',
    thumbAsset: '$_info/e11a_banner_broma.png',
    bannerAsset: '$_info/e11a_banner_broma.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El acoso escolar es cuando un estudiante molesta, humilla o lastima a otro una y otra vez a propósito, y quien lo sufre no logra defenderse.",
      ),
      InfoPoint(
        'Idea 2',
        "Puede ser con golpes o quitándote tus cosas, con insultos y rumores, dejándote fuera del grupo o por internet.",
      ),
      InfoPoint(
        'Idea 3',
        "No solo participan quien acosa y quien lo sufre: quien mira y se queda callado también influye en lo que pasa.",
      ),
      InfoPoint(
        'Idea 4',
        "Si te está pasando, no es tu culpa. Contáselo a una persona adulta de confianza y al personal del colegio para que actúen.",
      ),
    ],
  ),
  InfoResource(
    id: "acoso-protocolo-panama",
    title: "Tipos de acoso escolar y quiénes participan",
    summary:
        "Protocolo escolar que describe las condiciones del acoso, sus seis formas y el papel de quienes lo presencian.",
    organization: "Ministerio de Educación de Panamá y UNICEF Panamá",
    url: "https://www.unicef.org/panama/media/806/file",
    topic: InfoTopic.acoso,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Protocolo (2016) dirigido a docentes y directivos; se abrió y extrajo el texto. Puntos adaptados para estudiantes. Incluye directorio de contactos de Panamá que no se usa aquí.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_featured_broma.png',
    thumbAsset: '$_info/e11a_banner_broma.png',
    bannerAsset: '$_info/e11a_banner_broma.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Se habla de acoso cuando el maltrato se repite durante un tiempo, ocurre entre estudiantes y la persona afectada no logra detenerlo.",
      ),
      InfoPoint(
        'Idea 2',
        "Hay acoso verbal, psicológico, físico, no verbal (gestos, exclusión), sexual y cibernético; también dar 'me gusta' o reenviar burlas cuenta.",
      ),
      InfoPoint(
        'Idea 3',
        "Quienes miran pueden creer que burlarse es normal. Vos podés romper ese ciclo no apoyando las burlas y avisando a una persona adulta.",
      ),
      InfoPoint(
        'Idea 4',
        "Una persona adulta que te escucha debería tomarte en serio y no decirte 'no es para tanto'. Tenés derecho a un ambiente escolar sano.",
      ),
    ],
  ),
  InfoResource(
    id: "acoso-protocolo-mined",
    title: "Cómo actúa tu escuela ante el acoso en Nicaragua",
    summary:
        "Protocolo de las Consejerías de las Comunidades Educativas: qué es el acoso, sus tipos y los pasos que sigue la escuela.",
    organization: "MINED Nicaragua",
    url:
        "https://www.mined.gob.ni/biblioteca/wp-content/uploads/2024/09/protocolo-3-acoso-escolar.pdf",
    topic: InfoTopic.acoso,
    format: InfoFormat.guide,
    minutes: 3,
    verified: true,
    notes:
        "Protocolo dirigido a la comunidad educativa (docentes, dirección, consejerías); se abrió y extrajo el texto. La sección de señales de alerta tiene texto con codificación dañada y no se pudo leer completa. Puntos adaptados para estudiantes.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_featured_broma.png',
    thumbAsset: '$_info/e11a_banner_broma.png',
    bannerAsset: '$_info/e11a_banner_broma.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El acoso escolar es un maltrato constante entre estudiantes, con abuso de poder; puede pasar dentro o fuera de la escuela y por redes sociales.",
      ),
      InfoPoint(
        'Idea 2',
        "Puede ser físico, contra tus cosas, verbal (apodos, burlas, chantajes), psicológico (aislarte, la ley del hielo) o por internet.",
      ),
      InfoPoint(
        'Idea 3',
        "Cuando alguien de la comunidad educativa se entera, la dirección del centro debe ser informada y se busca a la familia.",
      ),
      InfoPoint(
        'Idea 4',
        "La escuela debe escucharte en un lugar privado, con respeto, sin culparte ni etiquetarte, y acompañarte o buscar apoyo especializado.",
      ),
    ],
  ),
  InfoResource(
    id: "acoso-modulo-hat",
    title: "Si te acosan, si acosás o si lo ves pasar",
    summary:
        "Módulo 19 de 'Ayudando a los adolescentes a prosperar': qué hacer según tu papel en una situación de acoso.",
    organization: "UNICEF (Adolescent Mental Health Hub)",
    url:
        "https://www.unicef.org/adolescentmentalhealthhub/media/1666/file/HAT-Facilitators-Guide-Spanish.pdf",
    topic: InfoTopic.acoso,
    format: InfoFormat.guide,
    minutes: 5,
    verified: true,
    notes:
        "Guía de 116 páginas para facilitadores que trabajan con adolescentes de 15 a 19 años; se usó el Módulo 19 (acoso escolar). Traducción al español con errores tipográficos. Puntos adaptados a lo que el estudiante puede hacer; para 3.º a 6.º grado conviene simplificar.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_featured_broma.png',
    thumbAsset: '$_info/e11a_banner_broma.png',
    bannerAsset: '$_info/e11a_banner_broma.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El acoso es cuando alguien, una y otra vez, hace o dice cosas para que otra persona se sienta herida, avergonzada o con miedo, en persona o en línea.",
      ),
      InfoPoint(
        'Idea 2',
        "Si te pasa a vos: no es tu culpa, nadie merece ese trato y no tenés que enfrentarlo solo o sola.",
      ),
      InfoPoint(
        'Idea 3',
        "Si estás molestando a alguien: es un comportamiento que se puede cambiar, y pedir apoyo para hacerlo es una muestra de fuerza.",
      ),
      InfoPoint(
        'Idea 4',
        "Si lo ves pasar: sos parte de la comunidad. Podés no sumarte, acompañar a quien lo sufre y buscar a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-como-gestionar",
    title: "Qué es la ansiedad y cómo calmarte",
    summary:
        "Explica la ansiedad, cómo se siente en el cuerpo y dos ejercicios sencillos para volver a la calma.",
    organization: "UNICEF América Latina y el Caribe",
    url:
        "https://www.unicef.org/lac/crianza/seguridad-proteccion/como-gestionar-ansiedad",
    topic: InfoTopic.ansiedad,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Artículo para madres, padres y personas cuidadoras; puntos adaptados para que el estudiante los aplique. No se incluye ningún diagnóstico.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Todas las personas sentimos preocupación o miedo a veces. Se vuelve un problema cuando no se va y te complica la escuela, la casa o el juego.",
      ),
      InfoPoint(
        'Idea 2',
        "Podés notarla en el cuerpo: corazón acelerado, dolor de estómago, sudor o problemas para dormir; también cuesta concentrarse.",
      ),
      InfoPoint(
        'Idea 3',
        "Probá el juego de los sentidos: nombrá 4 cosas que ves, 3 que oís, 2 que olés y 1 que saboreás.",
      ),
      InfoPoint(
        'Idea 4',
        "Respirá con la panza: poné una mano en el estómago, inflalo como un globo al tomar aire y soltalo despacio.",
      ),
      InfoPoint(
        'Idea 5',
        "Si la preocupación no se va, contáselo a una persona adulta de confianza; un profesional de salud puede ayudarte.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-el-salvador",
    title: "La ansiedad: señales y qué podés hacer",
    summary:
        "Describe señales físicas, emocionales y de conducta de la ansiedad y hábitos que ayudan a sentirse mejor.",
    organization: "UNICEF El Salvador",
    url: "https://www.unicef.org/elsalvador/historias/ansiedad",
    topic: InfoTopic.ansiedad,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Artículo (2023) dirigido a madres, padres y cuidadores; puntos adaptados para estudiantes. Contenido muy similar al de UNICEF LAC.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Un poco de ansiedad es normal y hasta te protege; preocupa cuando dura mucho o te impide hacer tus cosas.",
      ),
      InfoPoint(
        'Idea 2',
        "Puede sentirse como falta de aire, dolor de cabeza, inquietud, irritabilidad o pensar todo el tiempo en lo que va a pasar.",
      ),
      InfoPoint(
        'Idea 3',
        "Recordá que esa sensación pasa. Dormir lo suficiente y dejar el celular fuera del cuarto en la noche puede ayudarte.",
      ),
      InfoPoint(
        'Idea 4',
        "Hablá con una persona adulta de confianza sobre cuándo te pasa y cuánto dura. Solo un profesional de salud puede hacer un diagnóstico.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-crisis-chile",
    title: "Cuando las emociones te desbordan",
    summary:
        "Qué es una crisis de ansiedad o angustia y cómo una persona adulta puede acompañarte a calmarte.",
    organization: "UNICEF Chile",
    url:
        "https://www.unicef.org/chile/historias/%C2%BFc%C3%B3mo-ayudar-los-adolescentes-manejar-una-crisis-de-ansiedad-o-angustia",
    topic: InfoTopic.ansiedad,
    format: InfoFormat.guide,
    minutes: 2,
    verified: true,
    notes:
        "Artículo breve dirigido a madres, padres y personas adultas; puntos adaptados al estudiante. No indica cuándo buscar ayuda profesional.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Una crisis de ansiedad o angustia es cuando sentís que el miedo, la rabia o la frustración te desbordan.",
      ),
      InfoPoint(
        'Idea 2',
        "Ayuda ir a un lugar tranquilo con alguien de confianza y respirar despacio con la panza junto a esa persona.",
      ),
      InfoPoint(
        'Idea 3',
        "Tenés derecho a que te escuchen sin interrumpirte ni juzgarte. Buscá a una persona adulta que te dé esa calma.",
      ),
      InfoPoint(
        'Idea 4',
        "En los días tranquilos también vale la pena hablar de tu día, tus amistades, la escuela y lo que te pasa en internet.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-video-emociones-nicaragua",
    title: "La ansiedad y el estrés también les pasan a niñas y niños",
    summary:
        "Video de UNICEF Nicaragua sobre cuidar las emociones de niñas y niños ante situaciones nuevas.",
    organization: "UNICEF Nicaragua",
    url:
        "https://www.facebook.com/UNICEFNicaragua/videos/covid-19-cuido-de-emociones-de-ni%C3%B1os-y-ni%C3%B1as/896121294196673/",
    topic: InfoTopic.ansiedad,
    format: InfoFormat.video,
    minutes: null,
    verified: true,
    notes:
        "Video de Facebook que no se pudo ver; puntos basados solo en la descripción visible de la publicación. Contexto COVID-19 (fecha antigua) y dirigido a madres, padres y cuidadores. Revisar el video antes de publicarlo.",
    offline: false, // Video externo; su resumen sigue disponible sin internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La ansiedad y el estrés no son solo cosa de personas adultas: a niñas, niños y adolescentes también les pasa.",
      ),
      InfoPoint(
        'Idea 2',
        "Sentirte distinto o distinta cuando cambia todo a tu alrededor es normal.",
      ),
      InfoPoint(
        'Idea 3',
        "Las personas adultas que te cuidan pueden ayudarte; contales cómo te sentís.",
      ),
    ],
  ),
  InfoResource(
    id: "depresion-uruguay",
    title: "Tristeza que no se va: qué es la depresión",
    summary:
        "Explica la depresión, sus señales en niñas, niños y adolescentes y qué ayuda, sin reemplazar a un profesional.",
    organization: "UNICEF Uruguay",
    url:
        "https://www.unicef.org/uruguay/crianza/adolescencia/qu%C3%A9-es-la-depresi%C3%B3n-y-como-reconocerla-en-ni%C3%B1os-ni%C3%B1as-y-adolescentes",
    topic: InfoTopic.depresion,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Artículo (2024) dirigido a madres, padres, cuidadores y docentes; puntos adaptados al estudiante. La página incluye una línea telefónica de Uruguay que se omite a propósito.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Estar triste a veces es normal. La depresión es distinta: la tristeza o el enojo duran mucho y afectan tu día a día.",
      ),
      InfoPoint(
        'Idea 2',
        "Puede notarse en cansancio, cambios en el sueño o el apetito, perder interés en lo que te gustaba o alejarte de tus amistades.",
      ),
      InfoPoint(
        'Idea 3',
        "Solo un médico o un profesional de salud mental puede saber si es depresión. Tener una señal no significa que la tengas.",
      ),
      InfoPoint(
        'Idea 4',
        "Mantener rutinas de sueño y comida, moverte, dibujar o escribir lo que sentís puede ayudarte.",
      ),
      InfoPoint(
        'Idea 5',
        "Si pensás en hacerte daño, contáselo ya a una persona adulta de confianza o pedí ayuda en un centro de salud.",
      ),
    ],
  ),
  InfoResource(
    id: "depresion-el-salvador",
    title: "La depresión: señales y cómo pedir apoyo",
    summary:
        "Describe cómo puede verse la depresión en la niñez y adolescencia y por qué buscar ayuda temprano sirve.",
    organization: "UNICEF El Salvador",
    url: "https://www.unicef.org/elsalvador/historias/depresi%C3%B3n",
    topic: InfoTopic.depresion,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Artículo (2023) dirigido a madres, padres y cuidadores; puntos adaptados. Menciona ideas de suicidio y autolesiones: si se muestra a estudiantes, acompañarlo de la ruta de ayuda de la app.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La depresión no es solo estar triste un día: es un malestar que dura, quita las ganas y cambia cómo dormís, comés o pensás.",
      ),
      InfoPoint(
        'Idea 2',
        "A veces no se dice con palabras: se nota en dibujos, en la música que escuchás o en dejar de hacer lo que te gustaba.",
      ),
      InfoPoint(
        'Idea 3',
        "No tenés que hablar si no querés: dibujar, escribir o hacer algo creativo también te ayuda a sacar lo que sentís.",
      ),
      InfoPoint(
        'Idea 4',
        "La depresión se puede tratar y pedir ayuda temprano sirve. Contale a una persona adulta de confianza cómo te sentís.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-que-es",
    title: "Ciberacoso: qué es y cómo detenerlo",
    summary:
        "Preguntas y respuestas para adolescentes: cómo reconocer el ciberacoso, bloquear, reportar y pedir ayuda.",
    organization: "UNICEF",
    url:
        "https://www.unicef.org/es/end-violence/ciberacoso-que-es-y-como-detenerlo",
    topic: InfoTopic.ciberacoso,
    format: InfoFormat.guide,
    minutes: 5,
    verified: true,
    notes:
        "Artículo de preguntas y respuestas dirigido a adolescentes y jóvenes. Menciona líneas de ayuda nacionales de forma genérica; no se incluyen números.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_banner_chat.png',
    thumbAsset: '$_info/e10b_thumb_chat.png',
    bannerAsset: '$_info/e10b_thumb_chat.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El ciberacoso es molestar, asustar o humillar a alguien una y otra vez por redes, chats, juegos o el celular.",
      ),
      InfoPoint(
        'Idea 2',
        "Ya no es broma si te duele, si se ríen de vos y no con vos, o si siguen después de pedirles que paren.",
      ),
      InfoPoint(
        'Idea 3',
        "Guardá capturas de los mensajes, bloqueá a la persona y reportá la cuenta o publicación en la app.",
      ),
      InfoPoint(
        'Idea 4',
        "Contáselo a una persona adulta de confianza: tu familia, un docente o la consejería de tu escuela.",
      ),
      InfoPoint(
        'Idea 5',
        "Si le pasa a un amigo o amiga, escuchalo sin juzgar y animalo a contárselo a una persona adulta.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-convivencia-digital",
    title: "Convivencia digital: cuidarte y cuidar en internet",
    summary:
        "Guía para adolescentes sobre tipos de violencia digital y acciones para protegerte y cortar la cadena.",
    organization:
        "UNICEF Argentina y Ministerio Público Tutelar de Buenos Aires",
    url:
        "https://www.unicef.org/argentina/media/26526/file/GUIA%20de%20Convivencia%20Digital%20en%20la%20Adolescencia.pdf.pdf",
    topic: InfoTopic.ciberacoso,
    format: InfoFormat.guide,
    minutes: 6,
    verified: true,
    notes:
        "Guía (octubre 2025) escrita para adolescentes y ya en voseo rioplatense. Menciona leyes argentinas (grooming como delito) que no aplican tal cual a Nicaragua; no se usaron en los puntos.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_banner_chat.png',
    thumbAsset: '$_info/e10b_thumb_chat.png',
    bannerAsset: '$_info/e10b_thumb_chat.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Pensá antes de publicar: lo que subís deja huella y es muy difícil de borrar del todo.",
      ),
      InfoPoint(
        'Idea 2',
        "Poné tus cuentas en privado, usá contraseñas seguras y no compartas tu dirección, teléfono ni el nombre de tu escuela con desconocidos.",
      ),
      InfoPoint(
        'Idea 3',
        "No respondas a la agresión con más agresión: bloqueá, reportá y guardá capturas como prueba.",
      ),
      InfoPoint(
        'Idea 4',
        "Cortá la cadena: no compartas, comentes ni des 'me gusta' a publicaciones que se burlan de alguien.",
      ),
      InfoPoint(
        'Idea 5',
        "Si algo en internet te asusta o te hace sentir mal, no te lo guardés: contáselo a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-video-costa-rica",
    title: "Las palabras importan, también en línea",
    summary:
        "Video del Día Internacional contra la Violencia y el Acoso Escolar, incluido el ciberacoso.",
    organization: "UNICEF Costa Rica",
    url:
        "https://www.facebook.com/UNICEFCostaRica/videos/en-el-marco-del-d%C3%ADa-internacional-contra-la-violencia-y-el-acoso-escolar-incluid/1425434129259457/",
    topic: InfoTopic.ciberacoso,
    format: InfoFormat.video,
    minutes: null,
    verified: true,
    notes:
        "Video de Facebook que no se pudo ver; puntos basados solo en la descripción visible de la publicación. Revisar el video antes de publicarlo.",
    offline: false, // Video externo; su resumen sigue disponible sin internet.
    cardAsset: '$_info/e10a_banner_chat.png',
    thumbAsset: '$_info/e10b_thumb_chat.png',
    bannerAsset: '$_info/e10b_thumb_chat.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Antes de publicar, comentar o compartir, pensá cómo se puede sentir la otra persona.",
      ),
      InfoPoint(
        'Idea 2',
        "Lo que escribís en línea también puede lastimar: las palabras importan en internet igual que en persona.",
      ),
      InfoPoint(
        'Idea 3',
        "Podés ayudar a que internet sea un lugar más seguro eligiendo no sumarte al ciberacoso.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-video-huella-nicaragua",
    title: "El ciberacoso deja huella",
    summary:
        "Video de UNICEF Nicaragua sobre la huella emocional y digital del ciberacoso.",
    organization: "UNICEF Nicaragua",
    url:
        "https://www.facebook.com/UNICEFNicaragua/videos/el-ciberacoso-ocurre-a-menudo-y-deja-una-huella-emocional-en-la-salud-mental-y-d/866821897723238/",
    topic: InfoTopic.ciberacoso,
    format: InfoFormat.video,
    minutes: null,
    verified: true,
    notes:
        "Video de Facebook que no se pudo ver; puntos basados solo en la descripción visible (campaña #EnMiMente, Día del Internet Seguro). Revisar el video antes de publicarlo.",
    offline: false, // Video externo; su resumen sigue disponible sin internet.
    cardAsset: '$_info/e10a_banner_chat.png',
    thumbAsset: '$_info/e10b_thumb_chat.png',
    bannerAsset: '$_info/e10b_thumb_chat.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El ciberacoso pasa seguido y puede afectar cómo te sentís y tu salud mental.",
      ),
      InfoPoint(
        'Idea 2',
        "Lo que pasa en línea deja huella digital: esos registros pueden servirte como prueba para reportar.",
      ),
      InfoPoint(
        'Idea 3',
        "Guardar esa prueba y contárselo a alguien de confianza es una forma de pedir ayuda.",
      ),
    ],
  ),
  InfoResource(
    id: "emociones-cuidar-tu-salud-mental",
    title: "Cómo cuidar tu salud mental",
    summary:
        "Consejos para adolescentes: aceptar lo que sentís, cuidar tu cuerpo, darte tiempo y pedir ayuda.",
    organization: "UNICEF México",
    url: "https://www.unicef.org/mexico/como-cuidar-tu-salud-mental",
    topic: InfoTopic.emociones,
    format: InfoFormat.guide,
    minutes: 3,
    verified: true,
    notes: "Artículo dirigido directamente a adolescentes.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Ninguna emoción es 'buena' o 'mala': el miedo, la tristeza, la frustración y la alegría te dicen algo sobre lo que te pasa.",
      ),
      InfoPoint(
        'Idea 2',
        "Dormí bien, comé variado y movete al menos 15 minutos al día; tu cuerpo y tus emociones están conectados.",
      ),
      InfoPoint(
        'Idea 3',
        "Hacé cosas que disfrutás, pasá tiempo con amistades y familia, y tomá pausas de las redes. Escribir un diario también ayuda.",
      ),
      InfoPoint('Idea 4', "Hablate con cariño y tené paciencia con vos."),
      InfoPoint(
        'Idea 5',
        "Si una emoción pesa mucho o dura demasiado, no tenés que cargarla solo o sola: buscá a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "emociones-ponerles-nombre",
    title: "Ponerle nombre a lo que sentís",
    summary:
        "Tres ideas para expresar emociones: buscar empatía, nombrarlas con precisión y usar formas sin palabras.",
    organization: "UNICEF Perú",
    url:
        "https://www.unicef.org/peru/tres-maneras-de-ayudar-tu-hijo-adolescente-expresar-sus-emociones",
    topic: InfoTopic.emociones,
    format: InfoFormat.guide,
    minutes: 2,
    verified: true,
    notes:
        "Artículo dirigido a madres, padres y cuidadores de adolescentes; puntos adaptados a lo que el estudiante puede hacer.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Expresar lo que sentís es sano. Muchas veces primero necesitás que te comprendan y después los consejos.",
      ),
      InfoPoint(
        'Idea 2',
        "Intentá ser específico o específica: no es lo mismo estar frustrado, nervioso o preocupado. Ponerle nombre exacto puede aliviarte.",
      ),
      InfoPoint(
        'Idea 3',
        "Si no querés hablar, también está bien: moverte, llorar, escuchar música o dibujar son formas sanas de sacar lo que sentís.",
      ),
    ],
  ),
  InfoResource(
    id: "emociones-acompanar-sin-juicios",
    title: "Técnicas para calmarte y cuidarte",
    summary:
        "Reconocer y expresar emociones como parte de la salud mental, con ejercicios de respiración y de los cinco sentidos.",
    organization: "UNICEF México",
    url:
        "https://www.unicef.org/mexico/historias/salud-mental-adolescente-c%C3%B3mo-acompa%C3%B1ar-con-empat%C3%ADa-y-sin-juicios",
    topic: InfoTopic.emociones,
    format: InfoFormat.guide,
    minutes: 5,
    verified: true,
    notes:
        "Artículo (octubre 2025) dirigido a madres, padres, cuidadores y amistades de adolescentes; puntos adaptados al estudiante.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10b_thumb_emociones.png',
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: '$_info/e10b_thumb_emociones.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Reconocer y expresar lo que sentís es una señal de buena salud mental, no de debilidad.",
      ),
      InfoPoint(
        'Idea 2',
        "Respiración para calmarte: tomá aire contando hasta 4, sostené 2 y soltalo despacio contando hasta 6.",
      ),
      InfoPoint(
        'Idea 3',
        "Ejercicio 5-4-3-2-1: buscá 5 cosas que ves, 4 que oís, 3 que tocás, 2 que olés y 1 que saboreás.",
      ),
      InfoPoint(
        'Idea 4',
        "Rutinas, buen sueño, menos redes y actividades como el arte, la escritura o el deporte te ayudan a prevenir el malestar.",
      ),
      InfoPoint(
        'Idea 5',
        "Si el malestar dura más de dos semanas o te cuesta hacer tus cosas, contáselo a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-yo-apoyo-a-mis-amigos",
    title: "Yo apoyo a mis amigos: observar, escuchar y conectar",
    summary:
        "Cómo acompañar a un amigo o amiga que la está pasando mal, sin cargar con todo y sabiendo cuándo buscar a una persona adulta.",
    organization: "UNICEF Uruguay",
    url: "https://www.unicef.org/uruguay/media/13716/file",
    topic: InfoTopic.apoyo,
    format: InfoFormat.guide,
    minutes: 5,
    verified: true,
    notes:
        "Guía conceptual (2025) del programa 'Yo apoyo a mis amigos' (UNICEF, Save the Children, OMS), dirigida a personas adultas que forman a adolescentes; puntos adaptados para estudiantes. URL limpia sin parámetros de rastreo.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_card_apoyo.png',
    thumbAsset: '$_info/e10b_thumb_alerta.png',
    bannerAsset: '$_info/e10b_thumb_alerta.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Podés apoyar a un amigo o amiga con tres pasos: observar cómo está, escucharlo con atención y conectarlo con ayuda.",
      ),
      InfoPoint(
        'Idea 2',
        "Escuchar sin juzgar y mostrar que entendés ya es un gran apoyo; no tenés que resolverlo todo.",
      ),
      InfoPoint(
        'Idea 3',
        "Buscá a una persona adulta si tu amigo o amiga está en peligro, sufre abuso, piensa en hacerse daño o en dañar a otros.",
      ),
      InfoPoint(
        'Idea 4',
        "Cuidarte también importa: si te sentís sin fuerzas o no estás preparado o preparada, está bien pedir ayuda y poner límites.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-se-juega-en-equipo",
    title: "La salud mental también se juega en equipo",
    summary:
        "Campaña que recuerda que el bienestar se construye con familia, escuela y comunidad, y que pedir ayuda es cuidarte.",
    organization: "UNICEF Uruguay",
    url: "https://www.unicef.org/uruguay/la-salud-mental-se-juega-en-equipo",
    topic: InfoTopic.apoyo,
    format: InfoFormat.guide,
    minutes: 2,
    verified: true,
    notes:
        "Campaña dirigida principalmente a personas adultas; puntos adaptados para estudiantes.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_card_apoyo.png',
    thumbAsset: '$_info/e10b_thumb_alerta.png',
    bannerAsset: '$_info/e10b_thumb_alerta.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Pedir ayuda es parte de cuidar tu salud mental, no una señal de debilidad.",
      ),
      InfoPoint(
        'Idea 2',
        "Una persona adulta de confianza no necesita tener todas las respuestas: basta con que te escuche sin juzgar.",
      ),
      InfoPoint(
        'Idea 3',
        "Tu bienestar se cuida en equipo: familia, escuela, club y barrio pueden acompañarte.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-hablar-con-confianza",
    title: "Hablar con alguien de confianza alivia",
    summary:
        "Cómo cuidarte cuando las noticias o las redes te agobian y por qué compartir lo que sentís ayuda.",
    organization: "UNICEF México",
    url:
        "https://www.unicef.org/mexico/historias/informar-y-cuidar-la-salud-mental-de-las-juventudes",
    topic: InfoTopic.apoyo,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Artículo dirigido a periodistas, familias y jóvenes; incluye una estadística de una encuesta que no se usa aquí. Puntos centrados en lo que el estudiante puede hacer.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_card_apoyo.png',
    thumbAsset: '$_info/e10b_thumb_alerta.png',
    bannerAsset: '$_info/e10b_thumb_alerta.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Sentir enojo, ansiedad o agobio por lo que ves en noticias o redes es una reacción válida.",
      ),
      InfoPoint(
        'Idea 2',
        "Tomá pausas, desactivá notificaciones que no necesitás y desconectate antes de dormir.",
      ),
      InfoPoint(
        'Idea 3',
        "Contarle a una amistad, a tu familia o a otra persona de confianza cómo te sentís aligera la carga.",
      ),
      InfoPoint(
        'Idea 4',
        "Si la preocupación te supera, pedir ayuda es un acto de valentía. Una persona adulta puede ayudarte a buscar apoyo profesional.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-consejeria-mined",
    title: "La consejería de tu escuela te acompaña",
    summary:
        "Guía de acompañamiento socioemocional de las Consejerías de las Comunidades Educativas del MINED.",
    organization: "MINED Nicaragua y World Vision Nicaragua",
    url:
        "https://www.mined.gob.ni/biblioteca/wp-content/uploads/2024/07/Guia-Acompanamiento-Socioemocional-final-para-reproduccion-020221.pdf",
    topic: InfoTopic.apoyo,
    format: InfoFormat.guide,
    minutes: 3,
    verified: true,
    notes:
        "Guía (diciembre 2020) dirigida a docentes, dirección y enlaces de consejería, no a estudiantes; puntos adaptados. Aclara que el acompañamiento no es atención psicológica ni terapia. Prohíbe reproducir el documento sin autorización del MINED: enlazar, no copiar.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_card_apoyo.png',
    thumbAsset: '$_info/e10b_thumb_alerta.png',
    bannerAsset: '$_info/e10b_thumb_alerta.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "En tu escuela, las Consejerías de las Comunidades Educativas pueden acompañarte cuando algo afecta cómo te sentís.",
      ),
      InfoPoint(
        'Idea 2',
        "Quien te acompaña debe escucharte con respeto, sin juzgarte y sin decirte 'no es para tanto'.",
      ),
      InfoPoint(
        'Idea 3',
        "Te pueden ayudar a ponerle nombre a lo que sentís y a hablar o escribir sobre eso.",
      ),
      InfoPoint(
        'Idea 4',
        "Si hace falta, la escuela coordina con instituciones especializadas para que recibás más apoyo.",
      ),
    ],
  ),
];

// Preguntas de cierre: no forman parte de los 21 recursos de Biblioteca.
const List<InfoResource> routeQuestions = <InfoResource>[
  InfoResource(
    id: 'quiz-acoso',
    format: InfoFormat.quiz,
    topic: InfoTopic.acoso,
    title: 'Poné a prueba lo aprendido',
    summary: 'Pregunta de cierre de la ruta.',
    minutes: 1,
    points: <InfoPoint>[],
    caption:
        "Ves que a un compañero le esconden la mochila y se burlan de él todos los días. ¿Qué es lo más seguro que podés hacer?",
    options: <String>[
      "A) Reírte también para que no te molesten a vos.",
      "B) No sumarte a las burlas y contárselo a una persona adulta de confianza.",
      "C) Pelearte con quienes lo molestan para defenderlo.",
    ],
    correct: 1,
    optionFeedback: <String>[
      "Entendemos el miedo, pero reírte suma a las burlas y hace que tu compañero se sienta más solo.",
      "¡Bien! No sumarte y avisar a una persona adulta de confianza ayuda sin ponerte en peligro.",
      "Querés ayudar y eso vale mucho, pero pelear puede lastimarte. Mejor buscá a una persona adulta.",
    ],
  ),
  InfoResource(
    id: 'quiz-ansiedad',
    format: InfoFormat.quiz,
    topic: InfoTopic.ansiedad,
    title: 'Poné a prueba lo aprendido',
    summary: 'Pregunta de cierre de la ruta.',
    minutes: 1,
    points: <InfoPoint>[],
    caption:
        "Antes de un examen sentís el corazón acelerado y no podés dejar de preocuparte. ¿Qué podés probar primero?",
    options: <String>[
      "A) Respirar despacio con la panza o nombrar cosas que ves y oís a tu alrededor.",
      "B) Guardártelo y no decirle a nadie nunca.",
      "C) Pensar que algo está muy mal en vos.",
    ],
    correct: 0,
    optionFeedback: <String>[
      "¡Bien! Respirar despacio y usar tus sentidos ayuda a tu cuerpo a calmarse. Si se repite seguido, contáselo a alguien de confianza.",
      "No tenés que cargarlo solo o sola. Si la preocupación se repite, hablar con una persona adulta de confianza ayuda.",
      "Sentir nervios es algo que nos pasa a todas las personas; no significa que algo esté mal en vos.",
    ],
  ),
  InfoResource(
    id: 'quiz-depresion',
    format: InfoFormat.quiz,
    topic: InfoTopic.depresion,
    title: 'Poné a prueba lo aprendido',
    summary: 'Pregunta de cierre de la ruta.',
    minutes: 1,
    points: <InfoPoint>[],
    caption:
        "Hace semanas te sentís sin ganas y dejaste de hacer lo que te gustaba. ¿Qué es lo más útil que podés hacer?",
    options: <String>[
      "A) Esperar a que se pase solo, sin contarle a nadie.",
      "B) Buscar en internet si tenés depresión y sacar tu propia conclusión.",
      "C) Contarle a una persona adulta de confianza cómo te sentís para buscar apoyo.",
    ],
    correct: 2,
    optionFeedback: <String>[
      "A veces el malestar no se va solo. No tenés que esperar ni cargarlo solo o sola.",
      "Internet no puede decirte qué te pasa: solo un profesional de salud puede hacerlo. Hablar con alguien de confianza es el primer paso.",
      "¡Bien! Contarlo es un acto de valentía y ayuda a que te acompañen a buscar apoyo.",
    ],
  ),
  InfoResource(
    id: 'quiz-ciberacoso',
    format: InfoFormat.quiz,
    topic: InfoTopic.ciberacoso,
    title: 'Poné a prueba lo aprendido',
    summary: 'Pregunta de cierre de la ruta.',
    minutes: 1,
    points: <InfoPoint>[],
    caption:
        "En un grupo de chat comparten una foto tuya para burlarse y no paran aunque les pediste. ¿Qué hacés?",
    options: <String>[
      "A) Responder con insultos para que aprendan.",
      "B) Guardar capturas, bloquear y reportar, y contárselo a una persona adulta de confianza.",
      "C) Borrar todo y hacer como si no hubiera pasado.",
    ],
    correct: 1,
    optionFeedback: <String>[
      "Es normal sentir rabia, pero responder con agresión puede empeorar las cosas.",
      "¡Bien! Las capturas sirven como prueba, bloquear y reportar te protege, y una persona adulta puede ayudarte a frenarlo.",
      "Borrar quita la prueba y te deja solo o sola con el problema. Guardá capturas y pedí ayuda.",
    ],
  ),
];

InfoResource? infoResourceById(String? id) {
  for (final InfoResource resource in <InfoResource>[
    ...infoCatalog,
    ...routeQuestions,
  ]) {
    if (resource.id == id) return resource;
  }
  return null;
}

/// Recursos reales de Inicio; sus dos ilustraciones originales se conservan.
final List<InfoResource> homeResources = <InfoResource>[
  infoResourceById('acoso-guia-prevenir')!,
  infoResourceById('emociones-cuidar-tu-salud-mental')!,
];

@immutable
class InfoRoute {
  const InfoRoute(this.topic, this.steps, this.description);
  final InfoTopic topic;
  final List<String> steps;
  final String description;

  bool get ready => steps.length == 3;
  // «acoso» conserva el identificador del almacén v1 anterior al catálogo.
  String get id => topic.name;
}

const List<InfoRoute> infoRoutes = <InfoRoute>[
  InfoRoute(InfoTopic.acoso, <String>[
    "acoso-protocolo-panama",
    "acoso-modulo-hat",
    "quiz-acoso",
  ], "Entender el acoso y saber qué hacer"),
  InfoRoute(InfoTopic.ansiedad, <String>[
    "ansiedad-como-gestionar",
    "ansiedad-crisis-chile",
    "quiz-ansiedad",
  ], "Reconocer la ansiedad y volver a la calma"),
  InfoRoute(InfoTopic.depresion, <String>[
    "depresion-uruguay",
    "depresion-el-salvador",
    "quiz-depresion",
  ], "Cuando la tristeza no se va"),
  InfoRoute(InfoTopic.ciberacoso, <String>[
    "ciberacoso-que-es",
    "ciberacoso-video-huella-nicaragua",
    "quiz-ciberacoso",
  ], "Cuidarte en internet y frenar el ciberacoso"),
];

InfoRoute? routeOf(String id) {
  for (final InfoRoute route in infoRoutes) {
    if (route.steps.contains(id)) return route;
  }
  return null;
}
