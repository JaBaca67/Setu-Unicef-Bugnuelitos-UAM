# 0013 · Inicio estudiantil E03 sin seguimiento de casos para el estudiante

**Fecha:** 2026-11-12 · **Estado:** aceptada e implementada como corte de demostración.

## Contexto

El equipo aprobó una imagen de referencia para la pantalla principal del
estudiante (E03): cabecera con patrón azul de campaña, saludo «¡Hola! ·
¿Qué querés hacer hoy?», acceso a un avatar virtual, acción principal
«Pedir apoyo», franja compacta de racha y XP, sección «Explorá a tu ritmo»
con tarjetas de Información, bloque «Actividades» y navegación inferior de
cuatro destinos. La decisión más reciente del equipo es que **el estudiante
no tendrá una sección de seguimiento de casos**; el seguimiento interno se
conserva para los roles autorizados (mesa de escucha, MINED y dirección).

## Decisión

1. **Ruta `/inicio` (E03)** conectada al botón «Continuar» del acceso
   escolar E02, con el tema, el router y las transiciones existentes
   (movimiento reducido incluido). Implementada en
   `apps/mobile/lib/features/home/`.
2. **Navegación inferior de cuatro destinos:** Inicio, Información,
   Actividades y Ayuda. Inicio reúne adelantos y accesos directos de las
   otras secciones. Sustituye la propuesta anterior «Inicio, Mi
   seguimiento, Información y Ayuda» de docs/06.
3. **Sin vista estudiantil de seguimiento:** se elimina E07 «Mi seguimiento
   privado» del recorrido estudiantil. Dentro de «Pedir apoyo», la
   experiencia prevista es que, después de enviar una alerta, el estudiante
   pueda **recibir un aviso cuando una persona autorizada esté disponible
   para conversar**; el aviso abre el chat humano (E08) y no incluye datos
   del caso. E06 (estado real de entrega) se mantiene como honestidad de
   transporte. El historial y el estado interno del caso quedan solo en las
   vistas de los roles autorizados (M/L/D).
4. **Gamificación limitada:** racha y XP se vinculan únicamente a
   actividades educativas voluntarias (leer una guía, ver un video,
   responder la pregunta del día sobre el contenido). Los «3 días»,
   «120 XP» y «+10 XP» son valores de ejemplo y se etiquetan así. Sin
   rankings públicos, puntajes emocionales ni recompensas por enviar
   alertas. Apoyo, chat, Información y Ayuda disponibles con cualquier
   progreso.
5. **Avatar ilustrado configurable** mediante opciones gráficas (figuras de
   marca y colores de la paleta). No pide foto, nombre, iniciales, contacto
   ni cuenta; la elección vive en memoria durante la sesión.
6. **Vistas de muestra identificadas** para lo no implementado: Pedir apoyo
   (E04/E05), chat humano (E08), recursos E11 (guía propia y video con
   resumen textual mientras no haya empaquetado) y actividades. El espacio
   Información se organiza por tema y formato tomando como referencia
   https://www.wannatalkaboutit.com/, con contenidos propios de muestra,
   sin importar su catálogo ni sus contactos.
7. **Dado de emociones** adaptado como muestra digital del material impreso
   del equipo («Dado Muestra.pdf»); invita a reconocer emociones sin
   registrar respuestas. El semáforo y otros materiales quedan en
   adaptación. La selección final de caras requiere revisión con diseño.

## Alternativas consideradas

- Mantener «Mi seguimiento» con estados limitados: descartada por decisión
  del equipo; expone estado interno del caso al dispositivo estudiantil.
- Pestañas como rutas separadas de go_router: pospuesto; el estado interno
  de pestañas basta para la demo y no fija contratos de navegación.
- Persistir avatar y XP localmente: descartado por anticipado; no se crean
  almacenes ni contratos nuevos antes de aprobarse.

## Consecuencias

- docs/06, docs/08, README, diagramas y flujos deben dejar de mencionar el
  seguimiento estudiantil E07; las referencias se actualizan con este ADR.
  Los SVG de `docs/diseno/flujos/` quedan pendientes de regenerar.
- El aviso de disponibilidad requiere diseño técnico posterior (backend y
  notificaciones están fuera del corte actual); no se muestran avisos
  ficticios como atención real.
- Pruebas: 32 en total (`flutter analyze` limpio); cubren navegación entre
  pestañas, muestras identificadas, avatar, texto al 200 % en pantalla
  chica y movimiento reducido.

## Pendientes

- Formulario real E04/E05, envío y aviso de disponibilidad.
- Catálogo editorial con fuente, revisión y derechos; video empaquetado.
- Validación de las actividades y del dado con el equipo de diseño y por
  grupo de edad.
