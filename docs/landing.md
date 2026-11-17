# Landing page de SéTú

La carpeta `landing/` contiene la página estática (HTML, CSS y JS sin dependencias) publicada con GitHub Pages
desde `main` por el workflow `.github/workflows/deploy-landing.yml`. Todo lo que esté dentro de `landing/` queda público, así que la documentación vive aquí y no en esa carpeta.

## Marca

- Paleta y tipografías del Manual de Identidad Gráfica: #0C62EB, #FF0092, #FFE000, #00C642, #FFFFFF y #000000.
- Poppins (licencia OFL) se sirve desde `landing/assets/fonts/`.
- Clayful tiene licencia de uso personal, así que **no se sube el archivo de la fuente**: los titulares en Clayful están incrustados en `landing/index.html` como trazos SVG.

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
- Los teléfonos de emergencia siguen ADR 0025: 118 y 128. Territorio Nicaragua; verificados el 16-nov-2026; responsable editorial Bugñuelitos. No se publica 133 sin validación vigente.

La landing se publica al integrar cambios en `main`; una rama o un PR no actualiza GitHub Pages. El Figma se edita directamente y conserva el resto de pantallas de la app.
