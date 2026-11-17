# Landing page de SéTú

La carpeta `landing/` contiene la página estática (HTML, CSS y JS sin dependencias) publicada con GitHub Pages
desde `main` por el workflow `.github/workflows/deploy-landing.yml`. Todo lo que esté dentro de `landing/` queda público, así que la documentación vive aquí y no en esa carpeta.

## Marca

- Paleta y tipografías del Manual de Identidad Gráfica: #0C62EB, #FF0092, #FFE000, #00C642, #FFFFFF y #000000.
- Poppins (licencia OFL) se sirve desde `landing/assets/fonts/`.
- Clayful tiene licencia de uso personal, así que **no se sube el archivo de la fuente**: los titulares en Clayful están incrustados en `landing/index.html` como trazos SVG.

## Diseño

- Fuente visual: archivo de Figma del prototipo, frame «SéTú · Landing conectada con la app» (nodo `196:1797`, importado de la versión publicada con html.to.design).
- Los recursos exportados de Figma viven en `landing/assets/landing/` (WebP y SVG). Las pantallas de «Así funciona» son exportaciones 2x de los mockups de la app con datos ficticios.
- Los textos no se copian literalmente de Figma: donde el diseño prometía supervisión del MINED en cada caso, entrega garantizada sin internet, respuesta asegurada o mostraba logos institucionales, se conservan los textos alineados con los ADR vigentes.
- Contraste: el texto pequeño sobre magenta va en negro (AA); el blanco solo se usa en texto grande y en negrita.
- Pendiente: los números 118 y 133 necesitan fuente, territorio, fecha de verificación y responsable editorial antes de publicarse como información de ayuda.

## Probar en local
    cd landing
    python3 -m http.server 8000
Abre http://localhost:8000 (con file:// el navegador bloquea las fuentes).
