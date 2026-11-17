# ADR 0026 — Catálogo inicial con fuentes UNICEF/MINED

- **Fecha:** 2026-11-16.
- **Estado:** integración aprobada expresamente por el usuario e implementada; pendiente revisión profesional (Psicología).
- Amplía [ADR 0009](0009-espacio-informativo-confirmado.md) y [ADR 0014](0014-progreso-educativo-local.md).

## Contexto

La Biblioteca E10/E11 usaba siete recursos ficticios y una sola ruta activa con video simulado. El usuario entregó `.content/catalogo_informacion.json`, generado y revisado, con `verifiedAt: 2026-11-16`, 25 recursos y cuatro rutas, y aprobó integrar únicamente los 21 con `verified == true`. La verificación de la entrada editorial no equivale a revisión clínica ni aval institucional; este bloque no realizó una verificación web independiente.

## Decisión

- Copiar los 21 recursos verificados como constantes Dart: conservar exactamente título, resumen y puntos clave, con organización y URL. Excluir los cuatro no verificados. No leer ni empaquetar el JSON en ejecución. Reutilizar las ilustraciones existentes por tema.
- Seis temas: Acoso escolar, Ansiedad, Depresión, Ciberacoso, Emociones y Apoyo. Inicio abre una guía sobre acoso y otra sobre emociones conservando sus dos imágenes.
- Los textos son **resúmenes adaptados por el equipo SéTú a partir de la fuente; no reemplazan la fuente original**. Responsable editorial: Equipo SéTú (Bugñuelitos, UAM). Territorio mostrado: «Contenido de UNICEF/MINED; adaptado para estudiantes de Nicaragua». Revisión: «Verificado el 16 de noviembre de 2026 · Pendiente revisión profesional (Psicología)».
- El lector muestra resumen, tarjetas de puntos clave y fuente. En ansiedad/depresión añade el aviso aprobado de peligro/autolesión y acceso a la pestaña Ayuda, sin añadir ni modificar contactos.
- Los videos se abren **fuera de la app**, con conexión, mediante `Intent.ACTION_VIEW`. El texto adaptado sigue disponible sin internet. Se retira el reproductor simulado; no se descargan ni empaquetan videos ni se añade una dependencia.
- El canal Android `dev.cureando.app/links` acepta `open(url)`: exige HTTPS y hosts permitidos (UNICEF y sus subdominios; MINED, incluido `www.mined.gob.ni` presente en la fuente; youtube.com, youtu.be, facebook.com, www.facebook.com). Rechaza credenciales, puertos ajenos a HTTPS, espacios y barras inversas. Dart presenta un SnackBar si el canal o la app externa fallan.
- Cuatro rutas activas (acoso escolar, ansiedad, depresión, ciberacoso): dos recursos verificados del tema más pregunta A/B/C, índice correcto y retroalimentación por opción del JSON. Todas sus referencias ya están verificadas; no se requirió sustitución.
- +5 XP por primera lectura confirmada; +10 XP por cierre correcto confirmado, una vez por cada ruta. No depende de abrir o reproducir el enlace. El almacén cifrado `setu_learning_progress.enc`, su clave y versión 1 se conservan. El identificador histórico `acoso` permanece; recursos retirados y XP anteriores siguen contando. `routes` continúa siendo opcional al leer registros antiguos. No se guardan las respuestas elegidas.
- La **Guía de acompañamiento socioemocional del MINED** solo se enlaza: no se copia, redistribuye ni empaqueta su PDF. El lector presenta exclusivamente el resumen adaptado aprobado de la entrada editorial, identificado como tal.

## Fuentes del catálogo inicial

| Tema | Recurso adaptado | Fuente original |
| --- | --- | --- |
| acoso-escolar | Qué es el acoso escolar y cómo se ve | [UNICEF Comité Español (publicada por UNICEF Ecuador)](https://www.unicef.org/ecuador/media/14476/file) |
| acoso-escolar | Tipos de acoso escolar y quiénes participan | [Ministerio de Educación de Panamá y UNICEF Panamá](https://www.unicef.org/panama/media/806/file) |
| acoso-escolar | Cómo actúa tu escuela ante el acoso en Nicaragua | [MINED Nicaragua](https://www.mined.gob.ni/biblioteca/wp-content/uploads/2024/09/protocolo-3-acoso-escolar.pdf) |
| acoso-escolar | Si te acosan, si acosás o si lo ves pasar | [UNICEF (Adolescent Mental Health Hub)](https://www.unicef.org/adolescentmentalhealthhub/media/1666/file/HAT-Facilitators-Guide-Spanish.pdf) |
| ansiedad | Qué es la ansiedad y cómo calmarte | [UNICEF América Latina y el Caribe](https://www.unicef.org/lac/crianza/seguridad-proteccion/como-gestionar-ansiedad) |
| ansiedad | La ansiedad: señales y qué podés hacer | [UNICEF El Salvador](https://www.unicef.org/elsalvador/historias/ansiedad) |
| ansiedad | Cuando las emociones te desbordan | [UNICEF Chile](https://www.unicef.org/chile/historias/%C2%BFc%C3%B3mo-ayudar-los-adolescentes-manejar-una-crisis-de-ansiedad-o-angustia) |
| ansiedad | La ansiedad y el estrés también les pasan a niñas y niños | [UNICEF Nicaragua](https://www.facebook.com/UNICEFNicaragua/videos/covid-19-cuido-de-emociones-de-ni%C3%B1os-y-ni%C3%B1as/896121294196673/) |
| depresion | Tristeza que no se va: qué es la depresión | [UNICEF Uruguay](https://www.unicef.org/uruguay/crianza/adolescencia/qu%C3%A9-es-la-depresi%C3%B3n-y-como-reconocerla-en-ni%C3%B1os-ni%C3%B1as-y-adolescentes) |
| depresion | La depresión: señales y cómo pedir apoyo | [UNICEF El Salvador](https://www.unicef.org/elsalvador/historias/depresi%C3%B3n) |
| ciberacoso | Ciberacoso: qué es y cómo detenerlo | [UNICEF](https://www.unicef.org/es/end-violence/ciberacoso-que-es-y-como-detenerlo) |
| ciberacoso | Convivencia digital: cuidarte y cuidar en internet | [UNICEF Argentina y Ministerio Público Tutelar de Buenos Aires](https://www.unicef.org/argentina/media/26526/file/GUIA%20de%20Convivencia%20Digital%20en%20la%20Adolescencia.pdf.pdf) |
| ciberacoso | Las palabras importan, también en línea | [UNICEF Costa Rica](https://www.facebook.com/UNICEFCostaRica/videos/en-el-marco-del-d%C3%ADa-internacional-contra-la-violencia-y-el-acoso-escolar-incluid/1425434129259457/) |
| ciberacoso | El ciberacoso deja huella | [UNICEF Nicaragua](https://www.facebook.com/UNICEFNicaragua/videos/el-ciberacoso-ocurre-a-menudo-y-deja-una-huella-emocional-en-la-salud-mental-y-d/866821897723238/) |
| emociones | Cómo cuidar tu salud mental | [UNICEF México](https://www.unicef.org/mexico/como-cuidar-tu-salud-mental) |
| emociones | Ponerle nombre a lo que sentís | [UNICEF Perú](https://www.unicef.org/peru/tres-maneras-de-ayudar-tu-hijo-adolescente-expresar-sus-emociones) |
| emociones | Técnicas para calmarte y cuidarte | [UNICEF México](https://www.unicef.org/mexico/historias/salud-mental-adolescente-c%C3%B3mo-acompa%C3%B1ar-con-empat%C3%ADa-y-sin-juicios) |
| apoyo | Yo apoyo a mis amigos: observar, escuchar y conectar | [UNICEF Uruguay](https://www.unicef.org/uruguay/media/13716/file) |
| apoyo | La salud mental también se juega en equipo | [UNICEF Uruguay](https://www.unicef.org/uruguay/la-salud-mental-se-juega-en-equipo) |
| apoyo | Hablar con alguien de confianza alivia | [UNICEF México](https://www.unicef.org/mexico/historias/informar-y-cuidar-la-salud-mental-de-las-juventudes) |
| apoyo | La consejería de tu escuela te acompaña | [MINED Nicaragua y World Vision Nicaragua](https://www.mined.gob.ni/biblioteca/wp-content/uploads/2024/07/Guia-Acompanamiento-Socioemocional-final-para-reproduccion-020221.pdf) |

## Alternativas y consecuencias

Se descartan conservar las muestras ficticias, cargar el JSON en ejecución o incorporar un reproductor/SDK externo: el catálogo tipado permite leer las adaptaciones sin internet y evita dependencias nuevas. Abrir el navegador abandona temporalmente SéTú; la disponibilidad y privacidad del proveedor externo dependen de él. El catálogo no incorpora rastreadores ni envía datos de casos al enlace.

La fuente editorial marca tres videos como verificados, pero sus notas aclaran que no se pudo reproducir el video de Facebook y que los puntos se basan en su descripción visible; queda pendiente revisar los audiovisuales completos, junto con revisión profesional, derechos, accesibilidad y adecuación por edad antes de publicación operativa. No se afirma transcripción completa ni validación clínica. El catálogo educativo no habilita atención de casos reales ni cambia permisos o estados de apoyo.

## Verificación

Pruebas de integridad contra el JSON de desarrollo (21 entradas exactas y exclusión de las otras cuatro), temas/búsqueda, fuentes/puntos clave, aviso y navegación a Ayuda, cuatro rutas y retroalimentación, enlaces/fallback de Dart, XP únicos y reapertura de registros cifrados v1. Ejecutar `flutter analyze` y la suite completa `flutter test` desde `apps/mobile`. La apertura real del navegador Android requiere comprobación en un dispositivo; las pruebas Flutter simulan el canal nativo.
