# CLAUDE.md — SéTú (repo: Setu-Unicef-Bugnuelitos-UAM)

Las reglas del proyecto viven en `AGENTS.md` y son obligatorias. Este archivo
solo añade el estado de trabajo para Claude Code.

@AGENTS.md

## Estado al 16 de noviembre de 2026

- Último commit en `main`: `15f97e4` (merge de `feature/mesh-auto`). El cambio
  real es `654a39a`, «feat(mesh): envío automático por red mesh cuando no hay
  internet» (20 archivos, +793/−176).
- Evento central UAM - UNICEF: **martes 17 de noviembre de 2026**. Priorizar lo
  que afecte la demo del APK y el pitch.

## Tarea pendiente 1: landing page de SéTú (autorizada por el usuario)

El usuario pidió explícitamente subir la landing y desplegarla en GitHub Pages
(16 nov 2026). Esto cuenta como aprobación del bloque «landing + deploy»; lo
demás sigue requiriendo aprobación previa según `AGENTS.md`.

1. Aplicar el parche preparado (verificado limpio sobre `15f97e4`):
   `git am parche/0001-landing-setu.patch`
   Agrega `landing/` (HTML/CSS/JS sin dependencias, 34 archivos) y
   `.github/workflows/deploy-landing.yml`. Alternativa equivalente: descomprimir
   `recibidos/lote-3-landing/setu-landing.zip` en la raíz del repo.
2. Revisar el diff, confirmar y hacer push a `main`. No usar `git add .`.
3. Paso manual del usuario (una sola vez): GitHub → Settings → Pages →
   Source: **GitHub Actions**. Sin esto el workflow falla.
4. Verificar que el job «Deploy landing to GitHub Pages» termine en verde.
   URL esperada: `https://jabaca67.github.io/Setu-Unicef-Bugnuelitos-UAM/`
5. Probar en local: `cd landing && python3 -m http.server 8000`
   (con `file://` el navegador bloquea las fuentes).

Notas de la landing:
- Paleta `#0C62EB`, `#FF0092`, `#FFE000`, `#00C642`, blanco y negro; Poppins
  (OFL) en `landing/assets/fonts/`. Clayful NO se sube (licencia personal); los
  titulares en Clayful van como trazos SVG dentro de `index.html`.
- El pie usa el logo de UNICEF y menciona «UAM y UNICEF Nicaragua». Confirmar
  con el equipo que el uso del logo está permitido y que el texto no presenta
  el proyecto como producto oficial o avalado por UNICEF (regla de `AGENTS.md`).
- Contiene un `mailto:` a un correo del equipo y enlaces `tel:118` y `tel:133`.
  Verificar que los números de ayuda tengan fuente y fecha de verificación
  antes de publicar (regla de información de ayuda en `AGENTS.md`).

## Tarea pendiente 2: revisión del commit `654a39a` (mesh)

Hallazgos de revisión, ninguno corregido todavía. Proponer arreglos y pedir
aprobación antes de implementar:

1. **Prueba de entrega desde un puente.** En `_handleIncomingBytes`
   (`mesh_relay_service.dart`) el recibo se genera con
   `_schoolKeyPair ?? await _getBridgeKeyPair()`. Si la clave de puente puede
   abrir sobres del colegio, un puente emitiría «entregada» sin que llegue al
   personal, y además podría leer la alerta (contradice el E2EE). Verificar y,
   si aplica, generar el recibo solo con `_schoolKeyPair`.
2. **Recibos sobrescribibles en relés.** Con `expected == null` se acepta
   cualquier `proof` de 44 caracteres y se reemplaza uno previo distinto. No
   sobrescribir un recibo ya guardado en nodos intermedios.
3. **Tráfico y batería.** `retryPending()` corre cada 15 s y
   `_flushQueuedToPeer` reenvía todos los recibos y paquetes a cada vecino.
   `_deliveryReceipts` y `_expectedDeliveryProofs` no se podan. Reenviar solo a
   vecinos nuevos y expirar entradas viejas o ya sincronizadas.
4. **Fallo cacheado en `prepareSchoolReceiver`.** El future fallido queda
   guardado por scope y no se reintenta. Limpiar `_preparingReceiver` en error.
5. **Duplicados tras timeout de 8 s** en `SupportFlow.submitAlert`: si el
   servidor recibió la alerta, también sale por mesh. Confirmar deduplicación
   por `client_operation_id` en Supabase.
6. Menores: `directorAlerts` se persiste pero ya no se carga (alertas
   descifradas en disco sin uso); el snackbar «Nueva alerta recibida» puede
   saltar por alertas viejas al iniciar sesión (`_lastMeshAlertCount = 0`);
   el parámetro `endpointName` quedó sin efecto en Dart y Kotlin.

## Recursos gráficos recibidos (carpeta `recibidos/`)

Los lotes 1 y 2 llegaron con **nombres que no coinciden con su contenido**. No
copiarlos al repo con esos nombres. La versión correcta y ordenada ya está en
`setu-landing.zip` (`landing/assets/`). Mapa del contenido real:

| Archivo recibido | Contenido real |
|---|---|
| lote-1 `elemento-02-pieza-amarilla.svg` | Texto del README de la landing (no es SVG) |
| lote-1 `poppins-medium.woff2` | Isotipo SéTú blanco (SVG) |
| lote-1 `poppins-regular.woff2` | Imagotipo SéTú blanco (SVG) |
| lote-1 `poppins-semibold.woff2` | Imagotipo SéTú azul (SVG) |
| lote-1 `redes-1/2/3.webp` | SVG de una forma (rosa, verde, azul) |
| lote-1 resto de `elemento-*` | Elementos válidos pero con colores cruzados respecto al nombre |
| lote-2 `setu-imagotipo-azul.svg` | WebP post «Ellos merecen ser escuchados» |
| lote-2 `setu-imagotipo-blanco.svg` | WebP post «Tu salud mental sí importa» |
| lote-2 `setu-isotipo-blanco.svg` | WebP post «No te quedes callado» |
| lote-2 `setu-isotipo-azul.svg` | Logotipo «SéTú» azul |
| lote-2 `setu-logotipo-azul.svg` | Espiral amarilla |
| lote-2 `setu-logotipo-blanco.svg` | Logo UNICEF blanco |

`ManualDeIdentidad_gráfica_cureando.pdf` es la versión inicial del manual; la
final está en Drive (ver `AGENTS.md`).
