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
