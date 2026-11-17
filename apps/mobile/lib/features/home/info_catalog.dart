import 'package:flutter/material.dart';

import 'student_preview_cards.dart';

/// Catálogo editorial de muestra del espacio Información (E10/E11, tablero 4
/// de Figma). Contenido propio y ficticio, en revisión editorial: no es un
/// catálogo clínico publicado ni procede de Wanna Talk About It?.
enum InfoTopic {
  acoso('Acoso escolar', 'Acoso escolar'),
  ciberacoso('Ciberacoso', 'Ciberacoso'),
  emociones('Emociones y convivencia', 'Emociones'),
  apoyo('Cómo pedir apoyo', 'Apoyo');

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
    this.feedback,
  });

  final String id;
  final InfoFormat format;
  final InfoTopic topic;
  final String title;
  final String summary;
  final int minutes;
  final List<InfoPoint> points;

  /// Empaquetado en la app (texto). Los videos requieren conexión.
  final bool offline;
  final String? thumbAsset;
  final String? cardAsset;
  final String? bannerAsset;

  /// Subtítulo de muestra del video.
  final String? caption;
  final List<String> options;
  final int correct;
  final String? feedback;

  String get route => '/inicio/recurso/$id';
  bool get isVideo => format == InfoFormat.video;
  bool get isQuiz => format == InfoFormat.quiz;
  String get availability => offline ? 'Sin internet' : 'Con internet';
  String get meta => '${format.label} · $minutes min';
  StudentCover get cover => isVideo ? StudentCover.video : StudentCover.guide;
}

const String _info = 'assets/home/info';

const List<InfoResource> infoCatalog = <InfoResource>[
  InfoResource(
    id: 'broma',
    format: InfoFormat.guide,
    topic: InfoTopic.acoso,
    title: '¿Es una broma o acoso?',
    summary: 'Cómo distinguir una broma de una situación que lastima.',
    minutes: 3,
    cardAsset: '$_info/e10a_featured_broma.png',
    bannerAsset: '$_info/e11a_banner_broma.png',
    points: <InfoPoint>[
      InfoPoint(
        'Fijate en cómo se siente la otra persona',
        'Una broma se disfruta en grupo. Si alguien se siente humillado o '
            'aislado, prestá atención.',
        Icons.groups_2_outlined,
      ),
      InfoPoint(
        'Si ves que molestan a alguien',
        'Podés acompañarle, no compartir burlas y hablar con una persona '
            'adulta de confianza.',
        Icons.volunteer_activism_outlined,
      ),
    ],
  ),
  InfoResource(
    id: 'testigo',
    format: InfoFormat.video,
    topic: InfoTopic.acoso,
    title: 'Cómo ser un testigo solidario',
    summary: 'Qué hacer cuando ves que molestan a alguien.',
    minutes: 2,
    offline: false,
    cardAsset: '$_info/e10a_card_testigo.png',
    caption: '«No tenés que enfrentar al grupo a solas: acercate.»',
    points: <InfoPoint>[
      InfoPoint(
        'Reconocé la señal',
        'Si alguien queda callado, aislado o se tensa con las risas, ya dejó '
            'de ser una broma.',
      ),
      InfoPoint(
        'Acompañá sin confrontar',
        'Invitale a sentarse con vos, cambiá de tema o caminá a su lado al '
            'salir del aula.',
      ),
      InfoPoint(
        'Cuándo buscar apoyo adulto',
        'Si el acoso se repite, hay golpes o circula en chats, hablá con '
            'consejería o Pedir apoyo.',
      ),
    ],
  ),
  InfoResource(
    id: 'quiz-acoso',
    format: InfoFormat.quiz,
    topic: InfoTopic.acoso,
    title: 'Poné a prueba lo aprendido',
    summary: 'Pregunta de cierre de la ruta.',
    minutes: 1,
    points: <InfoPoint>[],
    caption:
        'En el recreo, un grupo esconde la mochila de Luis todos los días y '
        'se ríe cuando él la busca. ¿Qué acción apoya mejor a Luis?',
    options: <String>[
      'Reírse un poco para no quedar fuera del grupo.',
      'Acercarse a Luis, ayudarlo a buscar apoyo adulto y no celebrar la '
          'burla.',
      'Grabar el momento y subirlo al chat del curso.',
    ],
    correct: 1,
    feedback:
        'Acompañar a quien es molestado y acudir a una persona adulta rompe '
        'el silencio sin exponerte a pelear.',
  ),
  InfoResource(
    id: 'pedir-apoyo',
    format: InfoFormat.guide,
    topic: InfoTopic.apoyo,
    title: 'Cómo pedir apoyo en SéTú',
    summary: 'Los pasos para enviar una alerta cuando lo necesites.',
    minutes: 3,
    cardAsset: '$_info/e10a_card_apoyo.png',
    points: <InfoPoint>[
      InfoPoint(
        'Elegí qué está pasando',
        'Marcá el tipo de situación y si te pasó a vos o lo viste. Contar '
            'detalles es opcional.',
      ),
      InfoPoint(
        'Revisá antes de enviar',
        'Podés corregir todo. Una persona del equipo de escucha te avisará '
            'cuando pueda conversar.',
      ),
    ],
  ),
  InfoResource(
    id: 'chat-grupo',
    format: InfoFormat.story,
    topic: InfoTopic.ciberacoso,
    title: 'Pasó en el chat del grupo',
    summary: 'Escena ficticia de muestra.',
    minutes: 4,
    thumbAsset: '$_info/e10b_thumb_chat.png',
    cardAsset: '$_info/e10a_banner_chat.png',
    points: <InfoPoint>[
      InfoPoint(
        'Viñeta 1 · La captura en el grupo',
        'Alguien subió un meme burlándose de Mateo en el chat del curso. '
            'Varios respondieron con risas.',
        Icons.phone_iphone_rounded,
      ),
      InfoPoint(
        'Viñeta 2 · Valeria decide frenar',
        'Valeria pensó: «Si lo reenvío, lo hago más grande». No compartió la '
            'foto y escribió en privado a Mateo.',
        Icons.block_rounded,
      ),
      InfoPoint(
        'Viñeta 3 · Pedir apoyo a tiempo',
        'Guardaron capturas sin seguir difundiéndolas y hablaron con '
            'consejería escolar para detener el acoso.',
        Icons.verified_user_outlined,
      ),
    ],
  ),
  InfoResource(
    id: 'en-linea',
    format: InfoFormat.guide,
    topic: InfoTopic.ciberacoso,
    title: 'Qué hacer si te molestan en línea',
    summary: 'No responder en caliente, guardar evidencia y bloquear.',
    minutes: 3,
    thumbAsset: '$_info/e10b_thumb_linea.png',
    points: <InfoPoint>[
      InfoPoint(
        'No respondas en caliente',
        'Tomate un momento. Responder con enojo puede hacerlo más grande.',
      ),
      InfoPoint(
        'Guardá evidencia y bloqueá',
        'Hacé capturas sin reenviarlas y bloqueá a quien te molesta.',
      ),
    ],
  ),
  InfoResource(
    id: 'emociones',
    format: InfoFormat.guide,
    topic: InfoTopic.emociones,
    title: 'Entendé tus emociones',
    summary: 'Cómo nombrar lo que sentís.',
    minutes: 3,
    thumbAsset: '$_info/e10b_thumb_emociones.png',
    bannerAsset: 'assets/home/banner-actividad-1.png',
    points: <InfoPoint>[
      InfoPoint(
        'Todas son válidas',
        'Las emociones son señales del cuerpo y de la mente: nos avisan que '
            'algo nos importa.',
      ),
      InfoPoint(
        'Ponerles nombre',
        'Nombrar lo que sentís —alegría, tristeza, enojo, miedo, sorpresa o '
            'calma— ayuda a que se sienta menos grande.',
      ),
      InfoPoint(
        'Cuando pesa mucho',
        'Podés respirar despacio, contarle a alguien de confianza o pedir '
            'apoyo desde esta app.',
      ),
    ],
  ),
  InfoResource(
    id: 'alerta',
    format: InfoFormat.guide,
    topic: InfoTopic.apoyo,
    title: 'Qué pasa al enviar una alerta en SéTú',
    summary: 'Quién recibe tu alerta y qué ocurre sin internet.',
    minutes: 2,
    thumbAsset: '$_info/e10b_thumb_alerta.png',
    points: <InfoPoint>[
      InfoPoint(
        'Quién la recibe',
        'Tu relato llega solo al equipo de escucha. El colegio y el MINED '
            'reciben avisos mínimos, sin tu relato.',
      ),
      InfoPoint(
        'Sin internet',
        'La alerta queda guardada cifrada y puede viajar por teléfonos '
            'cercanos hasta un teléfono puente. La entrega no es inmediata.',
      ),
    ],
  ),
];

InfoResource? infoResourceById(String? id) {
  for (final InfoResource r in infoCatalog) {
    if (r.id == id) return r;
  }
  return null;
}

/// Recursos de la portada de Inicio («Explorá a tu ritmo»).
final List<InfoResource> homeResources = <InfoResource>[
  infoResourceById('broma')!,
  infoResourceById('testigo')!,
];

@immutable
class InfoRoute {
  const InfoRoute(this.topic, this.steps, this.description);
  final InfoTopic topic;
  final List<String> steps;
  final String description;

  bool get ready => steps.isNotEmpty;
  String get id => topic.name;
}

const List<InfoRoute> infoRoutes = <InfoRoute>[
  InfoRoute(
    InfoTopic.acoso,
    <String>['broma', 'testigo', 'quiz-acoso'],
    'Guía ¿Es una broma o acoso? + Video testigo solidario + Pregunta '
    '(+10 XP)',
  ),
  InfoRoute(
    InfoTopic.ciberacoso,
    <String>[],
    '2 piezas en Biblioteca: historia ilustrada y guía breve en línea',
  ),
  InfoRoute(
    InfoTopic.emociones,
    <String>[],
    'Guía Entendé tus emociones en Biblioteca; video en revisión editorial',
  ),
  InfoRoute(
    InfoTopic.apoyo,
    <String>[],
    'Guías para hablar con una persona adulta y entender qué pasa al alertar',
  ),
];

/// Ruta a la que pertenece un recurso, si forma parte de una.
InfoRoute? routeOf(String id) {
  for (final InfoRoute route in infoRoutes) {
    if (route.steps.contains(id)) return route;
  }
  return null;
}
