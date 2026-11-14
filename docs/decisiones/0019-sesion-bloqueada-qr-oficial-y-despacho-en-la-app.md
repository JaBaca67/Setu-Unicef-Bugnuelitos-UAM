# ADR 0019 · Sesión bloqueada, QR oficial del colegio y despacho en la app

- **Estado:** aceptada (13 nov 2026), a pedido del responsable del producto.
- **Ajusta:** ADR 0018 (sesión escolar y perfil) y ADR 0017 (superficies de personal).
- **Depende de:** migración `20261114000005_setu_counselor_dispatch_and_claim.sql` y los métodos de despacho de `SetuRemoteGateway`, ya publicados.

## Decisión

- **Solo vertical.** La app fija la orientación vertical en `main.dart` y en el manifiesto de Android. No hay proyecto iOS en el repositorio.
- **Bienvenida sin subtítulos.** Quedan «Ingreso estudiantil» y «Personal autorizado» sin la línea explicativa bajo cada botón.
- **Una sesión a la vez, sin cambio de código ni de rol.**
  - Con un colegio confirmado, la guía de rutas lleva a `/inicio` cualquier intento de abrir `/`, `/colegio*` o `/personal*`. Solo «Salir del colegio» en Mi perfil lo libera.
  - Al abrir la app, si el servidor conserva la sesión de personal, se recuperan sus membresías y se entra directo a su superficie (o al selector de centro si tiene varias). Mientras dure, no se abre `/`, `/colegio*` ni `/inicio`; elegido un centro no se cambia sin «Cerrar sesión».
  - Sigue siendo guía de navegación, no control de acceso: los permisos los aplica el servidor.
- **QR oficial.** El cartel lleva `setu://colegio/CODIGO` y se genera en la app con `qr_flutter`. El lector acepta el código directo, ese enlace y cualquier URI con `?code=`. Dirección abre el cartel de su colegio; la demostración muestra el de `AULA26`.
- **QR válido entra sin GPS.** Escanear un QR de un colegio registrado (o abrir su enlace) confirma el colegio y entra al inicio. La comprobación de cercanía queda solo para quien escribe el código a mano.
- **Despacho en Mesa de Escucha.** La bandeja muestra «Alertas por tomar» con el nivel (equipo de planta o red externa) y los botones «Tomar alerta» y «Declinar» (motivo opcional). Si otra persona la tomó antes, se informa sin error. La bandeja se actualiza en vivo. «Mis casos» lista solo lo que la persona atiende.
- **Historial en MINED.** Cada alerta abre su historial de despacho: a quién se ofreció, nivel, estado, motivo de declinación y quién la atiende. No incluye relato ni conversación.

## Consecuencias y pendientes

- **El QR ya no prueba presencia.** Sin GPS, quien tenga una foto del cartel o el enlace entra al espacio de ese colegio desde cualquier lugar. Se aceptó para la demostración; antes de un piloto real hay que decidir si el QR rota, si el GPS vuelve a ser requisito o si se asume ese riesgo.
- **Enlace desde fuera de la app sin probar en teléfono.** El filtro de intención `setu://colegio` y su redirección están implementados y la ruta interna tiene pruebas, pero abrir el enlace desde la cámara de Android no se verificó en un dispositivo.
- **El centro elegido no se guarda.** Quien tiene varios centros vuelve a elegir al reabrir la app.
- **Sin red al abrir.** Si no se pueden leer las membresías, la app queda en la bienvenida aunque el servidor conserve la sesión.
- **Captura del cartel.** La pantalla protegida bloquea capturas fuera del modo de captura de diseño; el cartel se muestra en pantalla, no se exporta ni se comparte.
- **Sin probar contra Supabase real.** Tomar, declinar, historial y avisos en vivo se probaron sobre la demostración en memoria.
