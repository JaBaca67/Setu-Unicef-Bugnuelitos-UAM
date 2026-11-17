# ADR 0027 — Colegio SéTú ficticio, banners de Información y QR estudiantil del personal

**Estado:** aceptada · **Fecha:** 17 de noviembre de 2026 · **Pedido por:** el usuario (correcciones previas al evento)

## Contexto

- `AULA26` se mostraba como «Colegio Centro América» con su escudo real. El equipo no quiere arriesgarse a usar el nombre y el logo de un colegio real sin permiso.
- Información mezclaba banners oficiales (fondo azul con un niño recortado) con stickers sobre fondos de color. Además, varias miniaturas de 108 px se estiraban como banner. Sobre el amarillo, el patrón de campaña hacía que el `#FFE000` se viera mostaza, que no es un color de la paleta.
- La tarjeta de Rutas usaba ese mismo fondo y unos personajes de piezas que no son los oficiales.
- Las cabeceras de Actividades y Ayuda tenían, alrededor de los niños, una línea blanca fina separada del borde en vez de un contorno grueso.
- Para probar el QR en la demo, el personal del colegio necesita mostrar el código desde su teléfono.

## Decisión

1. **Colegio ficticio.** `AULA26` pasa a llamarse **«Colegio SéTú»** en la app, en `supabase/seed.sql` y en la base remota (`institutions.name`), con un escudo de prueba genérico (`assets/schools/colegio_setu_prueba.png`, escudo azul con «CS · PRUEBA»). Se elimina el escudo real. La app sigue reconociendo el nombre anterior por si algún backend no se actualizó. El punto de referencia de cercanía no cambia.
2. **Banners de Información.** Todos los recursos usan banners 3:1 (1536 × 512) en `assets/home/info/banners/`, con fondo azul `#0C62EB`, un niño recortado con contorno blanco y elementos de la paleta. Tres salen de los posts oficiales de campaña (`docs/diseno/campana/Redes 1–3.png`) y el resto los generó Codex con el banner oficial como referencia. Son **imágenes generadas, no fotos de estudiantes reales**. Se conservan los banners oficiales de «¿Es una broma o acoso?» y del chat.
3. **Rutas.** Los temas ya no usan fondo amarillo: acoso, depresión y apoyo van en azul, ciberacoso en rosa y ansiedad y emociones en verde. Los stickers no oficiales se reemplazan por los personajes oficiales (flor azul y pieza amarilla) sobre una insignia blanca.
4. **Cabeceras de Actividades y Ayuda.** El contorno se rehízo como un borde blanco continuo de unos 7 px y se quitó la línea suelta.
5. **QR estudiantil.** «Mi perfil» del personal de un colegio incluye un interruptor **«QR estudiantil»**. Al activarlo, muestra el QR `setu://colegio/CODIGO` del centro activo. El estudiante lo escanea con «Escanear QR» y entra a ese colegio. El QR solo lleva el código público. El interruptor se recuerda mientras la app está abierta y no se guarda en el teléfono.

## Consecuencias

- Las imágenes generadas deben revisarse con el equipo de diseño antes de una versión pública. Si se prefieren fotos con derechos verificados, basta con reemplazar los archivos con el mismo nombre.
- `AULA24` todavía se llama «Colegio Público Demo Centro América — CCE». Conviene renombrarlo si se quiere quitar toda referencia.

## Segunda ronda (17 nov, antes del evento)

- **Pieza en «Pedir apoyo».** La pantalla de entrada, los pasos 2 y 3, la tarjeta «Me pasa a mí» y la revisión muestran la pieza que el estudiante armó en «Mi perfil» (`PieceFigure`), en lugar de un personaje fijo.
- **Avisos en el inicio.** El botón «Pedir apoyo» tiene una campana con contador. Suma 1 cuando la Mesa de Escucha activa el chat y 1 por cada mensaje nuevo del equipo. Al entrar a «Pedir apoyo» o al chat, el contador vuelve a 0. Lo revisado se guarda cifrado junto al caso (`chatSeen`, `staffSeen`). El contador no incluye el contenido de los mensajes.
- **Tabletas.** `TabletCanvas` dibuja la interfaz del teléfono con 430 dp de ancho y la escala a toda la pantalla cuando el lado corto mide 600 dp o más. Ya no queda una columna con bordes. La app sigue siendo solo vertical.
- **Mensajes emergentes.** Los avisos, diálogos y hojas inferiores usan el estilo SéTú: `buildSetuBottomAlertSnackBar` y el nuevo `shared/widgets/setu_dialog.dart`. Los migró Codex y se conservaron textos y comportamiento.
- **Bienvenida.** El titular alterna cada 4 s, con un fundido, entre «Simplemente #SoloSéTú» y «Todos podemos encajar». Este último se exportó del Figma de la landing (nodo `196:2105`) y su texto se pasó a blanco para el fondo azul. Con movimiento reducido, el cambio es inmediato.
- **Ayuda.** El título tiene 46 dp de sangría para no chocar con las líneas punteadas y la pieza verde del arte.
