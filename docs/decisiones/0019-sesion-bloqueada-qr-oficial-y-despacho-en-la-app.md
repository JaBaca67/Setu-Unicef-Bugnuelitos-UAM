# ADR 0019 · Sesión bloqueada, QR oficial del colegio y despacho en la app

- **Estado:** aceptada (13 nov 2026; actualizada 15 nov 2026 con persistencia de personal, arranque directo en superficie activa y bloqueo de botón Atrás), a pedido del responsable del producto.
- **Ajusta:** ADR 0018 (sesión escolar y perfil) y ADR 0017 (superficies de personal).
- **Depende de:** migración `20261114000005_setu_counselor_dispatch_and_claim.sql` y los métodos de despacho de `SetuRemoteGateway`, ya publicados.

## Decisión

- **Solo vertical.** La app fija la orientación vertical en `main.dart` y en el manifiesto de Android. No hay proyecto iOS en el repositorio.
- **Bienvenida sin subtítulos.** Quedan «Ingreso estudiantil» y «Personal autorizado» sin la línea explicativa bajo cada botón.
- **Una sesión a la vez, sin cambio de código ni de rol.**
  - Con un colegio confirmado, la guía de rutas lleva a `/inicio` cualquier intento de abrir `/`, `/colegio*` o `/personal*`. Solo «Salir del colegio» en Mi perfil lo libera.
  - Al iniciar sesión el personal, `StaffSession` guarda de forma cifrada en `setu_staff_session.enc` (clave `setu.staff.session.v1`) únicamente el identificador de usuario, sus membresías y el ámbito elegido (`activeMembershipId`), nunca contraseñas ni códigos privados. «Cerrar sesión» limpia ese almacén.
  - Antes de `runApp`, `main.dart` espera `StudentSession.open()`, `SupportFlow.open()` y `StaffSession.restore()`, y `CureandoApp` fija `initialLocation` directo en `/inicio`, `/personal/ambito` o la ruta activa del rol (`/personal/mined`, `/personal/mesa`, `/personal/direccion`), evitando volver a mostrar `/` o `/personal`.
  - Si ya hay una sesión guardada y al abrir ocurre un fallo transitorio de red al refrescar membresías, se conservan las membresías y el centro en caché (`preserveOnTransientError: true`); ante error de autenticación o revocación, se limpia el estado guardado y se redirige a `/personal`.
  - `/inicio`, `/personal/ambito`, `/personal/mined`, `/personal/mesa` y `/personal/direccion` viven como rutas de nivel superior en `GoRouter` y sus pantallas raíz usan `PopScope`, de modo que `context.go(...)` reemplaza la pila y el botón Atrás del dispositivo nunca regresa a `/` ni a `/personal`, manteniendo el retorno normal en subrutas (`cartel`, `caso/:id`, `chat`, `pieza`, etc.).
  - Sigue siendo guía de navegación, no control de acceso: los permisos los aplica el servidor.
- **QR oficial.** El cartel lleva `setu://colegio/CODIGO` y se genera en la app con `qr_flutter`. El lector acepta el código directo, ese enlace y cualquier URI con `?code=`. Dirección abre el cartel de su colegio; la demostración muestra el de `AULA26`.
- **QR válido entra sin GPS.** Escanear un QR de un colegio registrado (o abrir su enlace) confirma el colegio y entra al inicio. La comprobación de cercanía queda solo para quien escribe el código a mano.
- **Despacho en Mesa de Escucha.** La bandeja muestra «Alertas por tomar» con el nivel (equipo de planta o red externa) y los botones «Tomar alerta» y «Declinar» (motivo opcional). Si otra persona la tomó antes, se informa sin error. La bandeja se actualiza en vivo. «Mis casos» lista solo lo que la persona atiende.
- **Historial en MINED.** Cada alerta abre su historial de despacho: a quién se ofreció, nivel, estado, motivo de declinación y quién la atiende. No incluye relato ni conversación.

## Consecuencias y pendientes

- **El QR ya no prueba presencia.** Sin GPS, quien tenga una foto del cartel o el enlace entra al espacio de ese colegio desde cualquier lugar. Se aceptó para la demostración; antes de un piloto real hay que decidir si el QR rota, si el GPS vuelve a ser requisito o si se asume ese riesgo.
- **Enlace desde fuera de la app sin probar en teléfono.** El filtro de intención `setu://colegio` y su redirección están implementados y la ruta interna tiene pruebas, pero abrir el enlace desde la cámara de Android no se verificó en un dispositivo.
- **Primer ingreso sigue requiriendo red.** Una vez guardada la sesión y el centro elegido en `setu_staff_session.enc`, las reaperturas toleran fallos transitorios de conexión al refrescar membresías; la autenticación inicial y el cierre remoto siguen requiriendo conectividad (validado en `apps/mobile/test/session_lock_test.dart`).
- **Captura del cartel.** La pantalla protegida bloquea capturas fuera del modo de captura de diseño; el cartel se muestra en pantalla, no se exporta ni se comparte.
- **Sin probar contra Supabase real.** Persistencia cifrada al reabrir, bloqueo del botón Atrás, tomar, declinar, historial y avisos en vivo se probaron sobre la demostración en memoria y almacén en memoria en widget tests; falta verificar la persistencia real tras reiniciar la app Android con sesión Supabase activa.

> **Actualización ([ADR 0020](0020-alta-post-verificacion-y-cobertura-red-externa.md), 2026-11-15):** Se incorporan estados de cobertura de Red externa por colegio con precedencia de MINED, retiro automático de ofertas pendientes al pausar o vencer cobertura (`withdrawn_coverage`), recuperación de declinadas (*Deshacer* y *Declinadas recientes*) y pantalla de perfil/disponibilidad.
