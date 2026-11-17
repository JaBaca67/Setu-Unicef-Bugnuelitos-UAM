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
    title: "¿Es una broma o acoso?",
    summary: "Aprendé a reconocer el acoso y a buscar apoyo.",
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
        "El acoso es lastimar a alguien a propósito muchas veces, sin que pueda defenderse.",
      ),
      InfoPoint(
        'Idea 2',
        "Puede pasar con golpes, insultos, rumores, exclusión o por internet.",
      ),
      InfoPoint(
        'Idea 3',
        "Si te pasa, no es tu culpa: contáselo a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "acoso-protocolo-panama",
    title: "Cómo ser un testigo solidario",
    summary: "Descubrí cómo ayudar sin sumarte a las burlas.",
    organization: "Ministerio de Educación de Panamá y UNICEF Panamá",
    url: "https://www.unicef.org/panama/media/806/file",
    topic: InfoTopic.acoso,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Protocolo (2016) dirigido a docentes y directivos; se abrió y extrajo el texto. Puntos adaptados para estudiantes. Incluye directorio de contactos de Panamá que no se usa aquí.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/e10a_card_testigo.png',
    thumbAsset: '$_info/e10a_card_testigo.png',
    bannerAsset: '$_info/e10a_card_testigo.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El acoso se repite y a quien lo sufre le cuesta detenerlo.",
      ),
      InfoPoint(
        'Idea 2',
        "No apoyés las burlas: avisale a una persona adulta de confianza.",
      ),
      InfoPoint(
        'Idea 3',
        "Tenés derecho a que te escuchen y tomen en serio lo que te pasa.",
      ),
    ],
  ),
  InfoResource(
    id: "acoso-protocolo-mined",
    title: "¿Cómo debe escucharte tu escuela?",
    summary: "Conocé cómo debe acompañarte tu colegio ante el acoso.",
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
    cardAsset: '$_info/stickers/sticker_rompecabezas.png',
    thumbAsset: '$_info/stickers/sticker_rompecabezas.png',
    bannerAsset: '$_info/stickers/sticker_rompecabezas.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El acoso es maltrato constante con abuso de poder, dentro o fuera del colegio.",
      ),
      InfoPoint(
        'Idea 2',
        "La dirección debe ser informada y se busca a la familia.",
      ),
      InfoPoint(
        'Idea 3',
        "Deben escucharte en privado, sin culparte, y acompañarte o buscar apoyo.",
      ),
    ],
  ),
  InfoResource(
    id: "acoso-modulo-hat",
    title: "Si ves acoso, ¿qué hacés?",
    summary: "Encontrá formas de actuar frente al acoso.",
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
    cardAsset: '$_info/stickers/sticker_pieza_azul.png',
    thumbAsset: '$_info/stickers/sticker_pieza_azul.png',
    bannerAsset: '$_info/stickers/sticker_pieza_azul.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Si te acosan, no es tu culpa y no tenés que enfrentarlo sin compañía.",
      ),
      InfoPoint(
        'Idea 2',
        "Si molestás a alguien, podés cambiar y pedir apoyo para hacerlo.",
      ),
      InfoPoint(
        'Idea 3',
        "Si lo ves, no te sumés: acompañá y buscá a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-como-gestionar",
    title: "¿Sentís nervios? Probá una pausa",
    summary: "Reconocé la ansiedad y una forma de volver a la calma.",
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
    cardAsset: '$_info/stickers/sticker_semaforo.png',
    thumbAsset: '$_info/stickers/sticker_semaforo.png',
    bannerAsset: '$_info/stickers/sticker_semaforo.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La preocupación necesita apoyo si no se va y te complica la vida diaria.",
      ),
      InfoPoint(
        'Idea 2',
        "Respirá con la panza: inflala al tomar aire y soltalo despacio.",
      ),
      InfoPoint(
        'Idea 3',
        "Si la preocupación sigue, contáselo a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-el-salvador",
    title: "¿Qué te dice tu cuerpo?",
    summary: "Conocé algunas señales de ansiedad y cuándo pedir apoyo.",
    organization: "UNICEF El Salvador",
    url: "https://www.unicef.org/elsalvador/historias/ansiedad",
    topic: InfoTopic.ansiedad,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Artículo (2023) dirigido a madres, padres y cuidadores; puntos adaptados para estudiantes. Contenido muy similar al de UNICEF LAC.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/stickers/sticker_cara_amarilla.png',
    thumbAsset: '$_info/stickers/sticker_cara_amarilla.png',
    bannerAsset: '$_info/stickers/sticker_cara_amarilla.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La ansiedad preocupa cuando dura mucho o te impide hacer tus cosas.",
      ),
      InfoPoint(
        'Idea 2',
        "Podés sentir falta de aire, dolor de cabeza o inquietud.",
      ),
      InfoPoint(
        'Idea 3',
        "Contá cuándo te pasa y cuánto dura; solo un profesional puede diagnosticar.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-crisis-chile",
    title: "Cuando todo te desborda",
    summary: "Buscá calma y compañía cuando las emociones te superan.",
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
    cardAsset: '$_info/stickers/sticker_pieza_amarilla.png',
    thumbAsset: '$_info/stickers/sticker_pieza_amarilla.png',
    bannerAsset: '$_info/stickers/sticker_pieza_amarilla.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "En una crisis podés sentir que el miedo, la rabia o la frustración te superan.",
      ),
      InfoPoint(
        'Idea 2',
        "Buscá un lugar tranquilo y respirá despacio con alguien de confianza.",
      ),
      InfoPoint(
        'Idea 3',
        "Tenés derecho a que te escuchen sin interrumpirte ni juzgarte.",
      ),
    ],
  ),
  InfoResource(
    id: "ansiedad-video-emociones-nicaragua",
    title: "¿Los cambios te dan nervios?",
    summary: "Descubrí por qué los cambios pueden mover tus emociones.",
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
    cardAsset: '$_info/stickers/sticker_dado.png',
    thumbAsset: '$_info/stickers/sticker_dado.png',
    bannerAsset: '$_info/stickers/sticker_dado.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La ansiedad y el estrés también les pasan a niñas, niños y adolescentes.",
      ),
      InfoPoint(
        'Idea 2',
        "Es normal sentirte diferente cuando cambia todo a tu alrededor.",
      ),
      InfoPoint(
        'Idea 3',
        "Contales cómo te sentís a las personas adultas que te cuidan.",
      ),
    ],
  ),
  InfoResource(
    id: "depresion-uruguay",
    title: "Cuando la tristeza no se va",
    summary: "Conocé señales de depresión y cómo buscar apoyo.",
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
    cardAsset: '$_info/stickers/sticker_cara_roja.png',
    thumbAsset: '$_info/stickers/sticker_cara_roja.png',
    bannerAsset: '$_info/stickers/sticker_cara_roja.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La depresión puede ser tristeza o enojo que duran mucho y afectan tu día a día.",
      ),
      InfoPoint(
        'Idea 2',
        "Solo un profesional puede saber si es depresión; una señal no la confirma.",
      ),
      InfoPoint(
        'Idea 3',
        "Si pensás en hacerte daño, contáselo ya a una persona adulta de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "depresion-el-salvador",
    title: "¿Llevás días sin ganas?",
    summary: "Expresá lo que sentís y buscá compañía para pedir apoyo.",
    organization: "UNICEF El Salvador",
    url: "https://www.unicef.org/elsalvador/historias/depresi%C3%B3n",
    topic: InfoTopic.depresion,
    format: InfoFormat.guide,
    minutes: 4,
    verified: true,
    notes:
        "Artículo (2023) dirigido a madres, padres y cuidadores; puntos adaptados. Menciona ideas de suicidio y autolesiones: si se muestra a estudiantes, acompañarlo de la ruta de ayuda de la app.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/stickers/sticker_dibujo.png',
    thumbAsset: '$_info/stickers/sticker_dibujo.png',
    bannerAsset: '$_info/stickers/sticker_dibujo.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La depresión es un malestar que dura y cambia tus ganas, sueño o apetito.",
      ),
      InfoPoint(
        'Idea 2',
        "Si no querés hablar, podés dibujar o escribir lo que sentís.",
      ),
      InfoPoint(
        'Idea 3',
        "Pedir ayuda temprano sirve: contale cómo te sentís a un adulto de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-que-es",
    title: "Si te molestan en línea",
    summary: "Reconocé el ciberacoso y conocé cómo buscar ayuda.",
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
    cardAsset: '$_info/e10b_thumb_chat.png',
    thumbAsset: '$_info/e10b_thumb_chat.png',
    bannerAsset: '$_info/e10b_thumb_chat.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El ciberacoso es asustar o humillar muchas veces por redes, chats o juegos.",
      ),
      InfoPoint(
        'Idea 2',
        "Guardá capturas, bloqueá y reportá la cuenta o publicación en esa plataforma.",
      ),
      InfoPoint(
        'Idea 3',
        "Contáselo a una persona adulta de confianza, de tu familia o colegio.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-convivencia-digital",
    title: "Pasó en el chat del grupo",
    summary: "Cuidate en internet y ayudá a cortar las burlas.",
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
    cardAsset: '$_info/stickers/sticker_pregunta.png',
    thumbAsset: '$_info/stickers/sticker_pregunta.png',
    bannerAsset: '$_info/stickers/sticker_pregunta.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Pensá antes de publicar: lo que subís deja huella y cuesta borrarlo.",
      ),
      InfoPoint(
        'Idea 2',
        "Poné tus cuentas en privado y no compartás datos personales con desconocidos.",
      ),
      InfoPoint(
        'Idea 3',
        "No compartás ni apoyés publicaciones que se burlan de alguien.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-video-costa-rica",
    title: "Tus palabras también cuentan",
    summary: "Pensá cómo puede sentirse quien lee lo que escribís.",
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
    cardAsset: '$_info/e10b_thumb_linea.png',
    thumbAsset: '$_info/e10b_thumb_linea.png',
    bannerAsset: '$_info/e10b_thumb_linea.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Antes de publicar o compartir, pensá cómo puede sentirse la otra persona.",
      ),
      InfoPoint(
        'Idea 2',
        "Lo que escribís en línea también puede lastimar, igual que en persona.",
      ),
      InfoPoint(
        'Idea 3',
        "Ayudá a que internet sea más seguro: no te sumés al ciberacoso.",
      ),
    ],
  ),
  InfoResource(
    id: "ciberacoso-video-huella-nicaragua",
    title: "Lo que pasa en línea importa",
    summary: "Conocé la huella que puede dejar el ciberacoso.",
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
    cardAsset: '$_info/stickers/sticker_pieza_verde_misma.png',
    thumbAsset: '$_info/stickers/sticker_pieza_verde_misma.png',
    bannerAsset: '$_info/stickers/sticker_pieza_verde_misma.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "El ciberacoso puede afectar cómo te sentís y tu salud mental.",
      ),
      InfoPoint(
        'Idea 2',
        "Lo que pasa en línea deja registros que pueden servir como prueba.",
      ),
      InfoPoint(
        'Idea 3',
        "Guardá esas pruebas y contáselo a alguien de confianza para pedir ayuda.",
      ),
    ],
  ),
  InfoResource(
    id: "emociones-cuidar-tu-salud-mental",
    title: "Cuidá lo que sentís",
    summary: "Dale espacio a tus emociones y cuidate cada día.",
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
        "Cada emoción te dice algo sobre lo que te pasa; ninguna es buena o mala.",
      ),
      InfoPoint('Idea 2', "Hablate con cariño y tené paciencia con vos."),
      InfoPoint(
        'Idea 3',
        "Si una emoción pesa mucho o dura demasiado, buscá a un adulto de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "emociones-ponerles-nombre",
    title: "Ponele nombre a lo que sentís",
    summary: "Descubrí distintas formas de expresar tus emociones.",
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
    cardAsset: '$_info/stickers/sticker_cara_verde.png',
    thumbAsset: '$_info/stickers/sticker_cara_verde.png',
    bannerAsset: '$_info/stickers/sticker_cara_verde.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Buscá que te comprendan: a veces necesitás eso antes que consejos.",
      ),
      InfoPoint(
        'Idea 2',
        "Nombrá lo que sentís: ¿frustración, nervios o preocupación?",
      ),
      InfoPoint(
        'Idea 3',
        "Si no querés hablar, podés moverte, llorar, escuchar música o dibujar.",
      ),
    ],
  ),
  InfoResource(
    id: "emociones-acompanar-sin-juicios",
    title: "Date un momento para cuidarte",
    summary: "Reconocé tus emociones y probá una pausa.",
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
    cardAsset: '$_info/stickers/sticker_dibujo.png',
    thumbAsset: '$_info/stickers/sticker_dibujo.png',
    bannerAsset: '$_info/stickers/sticker_dibujo.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Expresar lo que sentís es parte de cuidar tu salud mental.",
      ),
      InfoPoint(
        'Idea 2',
        "Tomá aire contando hasta 4, sostené 2 y soltalo despacio contando hasta 6.",
      ),
      InfoPoint(
        'Idea 3',
        "Si el malestar dura o te cuesta hacer tus cosas, contáselo a un adulto de confianza.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-yo-apoyo-a-mis-amigos",
    title: "¿Cómo acompañás a una amistad?",
    summary: "Escuchá y conectá con ayuda sin cargar con todo.",
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
    thumbAsset: '$_info/e10a_card_apoyo.png',
    bannerAsset: '$_info/e10a_card_apoyo.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Observá cómo está tu amistad, escuchala y ayudala a conectar con apoyo.",
      ),
      InfoPoint('Idea 2', "Escuchá sin juzgar: no tenés que resolverlo todo."),
      InfoPoint(
        'Idea 3',
        "Buscá a un adulto si hay peligro, abuso o ideas de hacerse daño o dañar a otros.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-se-juega-en-equipo",
    title: "Armá tu equipo de apoyo",
    summary: "Recordá que podés cuidar tu bienestar en compañía.",
    organization: "UNICEF Uruguay",
    url: "https://www.unicef.org/uruguay/la-salud-mental-se-juega-en-equipo",
    topic: InfoTopic.apoyo,
    format: InfoFormat.guide,
    minutes: 2,
    verified: true,
    notes:
        "Campaña dirigida principalmente a personas adultas; puntos adaptados para estudiantes.",
    offline: true, // Resumen local; la fuente y el video requieren internet.
    cardAsset: '$_info/stickers/sticker_rompecabezas.png',
    thumbAsset: '$_info/stickers/sticker_rompecabezas.png',
    bannerAsset: '$_info/stickers/sticker_rompecabezas.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Pedir ayuda es una forma de cuidarte, no una señal de debilidad.",
      ),
      InfoPoint(
        'Idea 2',
        "Buscá a una persona adulta que te escuche sin juzgar.",
      ),
      InfoPoint(
        'Idea 3',
        "Tu familia, escuela, club y barrio pueden acompañarte.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-hablar-con-confianza",
    title: "Hablá con alguien de confianza",
    summary: "Compartí lo que sentís cuando las redes te agobian.",
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
    cardAsset: '$_info/stickers/sticker_pregunta.png',
    thumbAsset: '$_info/stickers/sticker_pregunta.png',
    bannerAsset: '$_info/stickers/sticker_pregunta.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "Es válido sentir enojo, ansiedad o agobio por las noticias o redes.",
      ),
      InfoPoint('Idea 2', "Tomá pausas y desconectate antes de dormir."),
      InfoPoint(
        'Idea 3',
        "Si la preocupación te supera, un adulto puede ayudarte a buscar apoyo profesional.",
      ),
    ],
  ),
  InfoResource(
    id: "apoyo-consejeria-mined",
    title: "Tu escuela puede acompañarte",
    summary: "Conocé el apoyo de la consejería de tu colegio.",
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
    cardAsset: '$_info/stickers/sticker_pieza_azul.png',
    thumbAsset: '$_info/stickers/sticker_pieza_azul.png',
    bannerAsset: '$_info/stickers/sticker_pieza_azul.png',
    points: <InfoPoint>[
      InfoPoint(
        'Idea 1',
        "La consejería de tu escuela puede acompañarte cuando algo afecta cómo te sentís.",
      ),
      InfoPoint(
        'Idea 2',
        "Tenés derecho a que te escuchen con respeto, sin juzgarte.",
      ),
      InfoPoint(
        'Idea 3',
        "Si hace falta, la escuela coordina con instituciones para darte más apoyo.",
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
