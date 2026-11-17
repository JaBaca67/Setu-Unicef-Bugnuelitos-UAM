# Landing page de SéTú

La carpeta `landing/` contiene la página estática (HTML, CSS y JS sin dependencias) publicada con GitHub Pages
desde `main` por el workflow `.github/workflows/deploy-landing.yml`. Todo lo que esté dentro de `landing/` queda público, así que la documentación vive aquí y no en esa carpeta.

## Marca

- Paleta y tipografías del Manual de Identidad Gráfica: #0C62EB, #FF0092, #FFE000, #00C642, #FFFFFF y #000000.
- Poppins (licencia OFL) se sirve desde `landing/assets/fonts/`.
- Clayful tiene licencia de uso personal, así que **no se sube el archivo de la fuente**: los titulares en Clayful están incrustados en `landing/index.html` como trazos SVG.

## Diseño vigente · 17 de noviembre de 2026 (ronda de auditoría)

- Base visual: frame de Figma «SéTú · Landing conectada con la app» (archivo `8TbZNgIetXg3O5f7Cba2vh`, nodo `196:1797`), mejorada tras una auditoría de marca, diseño, accesibilidad/rendimiento y móvil/textos. Respaldo visual previo en `docs/diseno/landing-respaldo-2026-11-17/`.
- Orden: portada → datos clave → problema → «Así funciona» (4 pasos) → privacidad → Explorá → franja «¿Querés probarla?» → videos → campaña, valores y kit → instituciones → preguntas → descarga → pie.
- Marca (Manual de Marca): cinta-pieza con muesca y flor como rótulo de cada sección (pp. 4–22), flores numeradas, flores/espirales/piezas a sangre en las esquinas, valores (p. 6) y los cuatro colores en equilibrio. El fondo de ondas solo se usa en la portada y en privacidad (viene del arte de campaña del equipo).
- Mockups del equipo en `landing/assets/app/` (WebP 360/720 px con `srcset`): celular fijo que cambia de pantalla en «Así funciona» (escritorio) o tarjetas deslizables (celular), mosaico de Explorá y trío en abanico en la descarga. Videos nuevos a 720p en `landing/assets/demo/`.
- Textos en voseo y sin promesas absolutas (anonimato, entrega, respuesta); la campaña y el kit se presentan como propuesta.
- Contraste: el texto pequeño sobre magenta, verde o amarillo va en negro (AA); el blanco sobre magenta solo en texto grande y en negrita.
- Movimiento: entrada escalonada de la portada, aparición al hacer scroll (también escalonada en listas), celular fijo, alerta animada en el mapa de la red, flores que giran, piezas y mockups que flotan y efectos al pasar el cursor; todo se desactiva con «reducir movimiento».
- Segunda auditoría (17-nov): la mesa de escucha siempre como propuesta; se retiraron los videos `flujo-alerta` (prometía la entrega) e `informacion-app` (mostraba el reproductor retirado en ADR 0026); animaciones corregidas con `rotate`/`translate` y solo dos bucles continuos; mockups con sombra en tres capas, brillo de vidrio recortado con la silueta del teléfono y versiones de 1080 px para pantallas de alta densidad; puntos en todos los carruseles y botón de play propio en los videos.
- Sin números de ayuda (17-nov): por decisión del equipo para la presentación, la landing ya no muestra la franja «¿Estás en peligro ahora?», el aviso de la portada ni el enlace del menú con el 118 y el 133. Las líneas verificadas siguen en la pestaña Ayuda de la app (ADR 0025). Se pueden restaurar desde el commit anterior a `812f3b0`.
- Barra de navegación con isotipo + logotipo (pedido del equipo; el manual no fija una versión horizontal, conviene validarla con Diseño). Título de la página y de las vistas previas al compartir: «Solamente SéTú».
- Recorrido automático (17-nov): botón flotante «Recorrido automático» que desplaza la página despacio y vuelve al inicio al final; se detiene con la rueda, el toque o el teclado. Con `?auto` (o `#auto`) en la URL arranca solo y se reanuda tras 25 s sin interacción, pensado para la pantalla del stand: `https://jabaca67.github.io/Setu-Unicef-Bugnuelitos-UAM/?auto`.

## Probar en local
    cd landing
    python3 -m http.server 8000
Abre http://localhost:8000 (con file:// el navegador bloquea las fuentes).

## Pulido para el stand · 16 de noviembre de 2026

- Fuente visual: archivo Figma `8TbZNgIetXg3O5f7Cba2vh`, landing `114:26`; Manual de Marca final de Drive y copia PDF aportada por el usuario. Poppins y trazos Clayful existentes; no se usa Nunito.
- Hero con CTA al APK de Drive del 16-nov (`1WmzyJUg0ABflmlN6s4Q4G6YVK37buif4`), recursos, QR a la URL pública de GitHub Pages y video de Inicio. Se conserva el APK fuera de Git (194 MB, compilación de prueba).
- Información, Cuidarme/Actividades, las tres superficies y campaña/kit presencial se explican por separado. Se explicitan condiciones de mesh, chat por internet, datos de prueba y límites de privacidad.
- Recursos reales: Manual de Marca (`11vE2_hviWBnT79giw6Y8mgofxUckyae6`) y carpeta de manuales (`1i3h6JxUnx_VdSernXpXU_yz06C6tu-jQ`). Los tres destinos tienen permiso `anyone/reader`, comprobado mediante metadatos de Drive.
- Los cuatro MP4 fueron aportados por el usuario; las copias para web conservan proporción y contenido, sin audio, a 1280 px. Pesan aproximadamente 4 MB en conjunto. `preload="none"`, controles nativos, sin reproducción automática, portadas WebP y descripciones en texto evitan descargar todos los videos al entrar. Las imágenes del teléfono son demostraciones de interfaz, no botones interactivos.
- El QR usa `https://jabaca67.github.io/Setu-Unicef-Bugnuelitos-UAM/#descargar`; debe comprobarse sobre el despliegue final después de integrar la rama. No es el QR de acceso a un colegio.
- Metadatos Open Graph/Twitter con URLs absolutas y favicon SVG oficial. No se incorporan paquetes al sitio estático.
- Verificación local: Chromium/Playwright a 360, 390, 768, 1024, 1440 y 1920 px; carga de imágenes, destinos de anclas, ausencia de desbordamientos de textos y botones, menú con Escape y FAQ. La prueba local no verifica instalación del APK ni transporte mesh físico.
- (Histórico, 16-nov) Las líneas de ayuda seguían la actualización más reciente de ADR 0025: Policía 118 y orientación del Ministerio de la Familia 133, con fuente MINED. Territorio Nicaragua; verificados el 16-nov-2026; responsable editorial Bugñuelitos. El catálogo se describe según ADR 0026 (adaptaciones UNICEF/MINED pendientes de revisión profesional); la versión del APK puede anteceder a esos cambios.

La landing se publica al integrar cambios en `main`; una rama o un PR no actualiza GitHub Pages. El Figma se edita directamente y conserva el resto de pantallas de la app.

Verificación adicional: los cuatro videos se reproducen en Chromium a 1280 × 720 sin errores. Axe no detecta violaciones automáticas WCAG A/AA/2.1 AA en 390 y 1440 px. Esto no sustituye pruebas manuales con tecnologías de apoyo.
