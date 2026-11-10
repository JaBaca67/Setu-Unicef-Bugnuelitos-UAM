# Lenguajes, recursos e integraciones técnicas

**Revisión:** 2026-11-09. [ADR 0008](decisiones/0008-stack-web-y-modelado-logico-propuesto.md): propuesta para revisión, sin instalación, cuentas, despliegues o cambios de código. [README](../README.md#stack).

## 1. Matriz completa por superficie

| Superficie o capa | Lenguajes | Recursos | Estado y alcance |
| --- | --- | --- | --- |
| App estudiantil Android | Dart; Kotlin para integración nativa | Flutter, `go_router`, `cryptography`, `flutter_secure_storage`, `path_provider`, Poppins local | Base local M1 existente. QR, acceso nuevo, backend, chat remoto y mesh pendientes. |
| Información E10/E11 | Dart y recursos JSON/texto/video | Widgets Flutter; catálogo versionado/recursos empaquetados propuestos; `video_player` como candidato; distribución editorial futura separada | Función de producto confirmada por ADR 0009; nada instalado. Entrada sin reporte y durante la espera, con retorno sin cambiar una alerta. |
| QR escolar | Dart y cámara Android | **Candidato:** `mobile_scanner`; entrada manual como alternativa | No instalado. Probar QR auténtico/configuración, errores, permiso denegado y equipos sin Google Play services según modo del escáner. Escanear no autentica al dueño del caso. |
| Comprobación de cercanía | Dart y API Android | **Candidato condicionado:** `geolocator` | Intención de producto; no instalar hasta acordar finalidad, permisos, alternativa y uso fuera del centro. No guardar ubicación precisa ni seguimiento continuo. |
| Panel MINED | TypeScript/TSX, HTML semántico, CSS | **Propuesta:** React, Vite, React Router, `@supabase/supabase-js` | Cola de avisos/fichas, filtros del ámbito, requerimientos, escalamiento y cierre. Sin relato/chat. |
| Mesa de escucha en la web | TypeScript/TSX, HTML, CSS | Mismo cliente React; rutas, contratos y permisos propios | Casos asignados, conversación humana conectada, valoración y ficha mínima. Ser usuario MINED no concede este rol. |
| Panel de instituciones | TypeScript/TSX, HTML, CSS | Mismo cliente React, componentes compartidos y proyección escolar | Datos del centro, ficha, pasos autorizados, aviso docente y propuesta de cierre. Sin relato/chat ni permisos de otras instituciones. |
| Cliente móvil de backend | Dart | **Propuesta:** `supabase_flutter` | Sesión técnica/acceso privado aún sin elegir. API, RPC y actualizaciones autorizadas. No incluir `service_role` o clave secreta. |
| Identidad y autorización | Configuración Auth; SQL/PLpgSQL | Supabase Auth para personal, RLS, privilegios y funciones transaccionales | Alta confiable, ámbito, asignación, revocación y pruebas. La continuidad privada estudiantil es una decisión independiente pendiente. |
| Datos y contratos | SQL/PLpgSQL; JSON validado | PostgreSQL; migraciones versionadas futuras; API/RPC Supabase | Supabase/PostgreSQL confirmado como objetivo. Tablas, políticas, endpoints y migraciones no implementados. |
| Operaciones confiables | TypeScript sobre Deno, cuando haga falta | **Propuesta:** Supabase Edge Functions | Validar/canjear acceso institucional o integrar una operación sensible, sin reemplazar transacciones de BD por escrituras parciales. No hay servidor Node propio. |
| Actualizaciones y chat | Dart/TypeScript; SQL | **Propuesta:** Supabase Realtime con mensajes persistidos y autorización por caso/asignación | Internet obligatorio para chat. Realtime no sustituye persistencia, RLS, control de canales o comprobación de revocación. |
| Proximidad | Dart + Kotlin | **Candidato:** canal de plataforma Flutter → SDK Android Nearby Connections de Google Play services, estrategia Cluster | Un enlace entre vecinos no implementa retransmisión multisalto. Probar dependencias GMS, radios, autenticación y restricciones Android. |
| Sobres y protocolo mesh | Dart/Kotlin; formato por aprobar | Cola local protegida, sello por destinatario, deduplicación, caducidad y acuses | Propuesto. Biblioteca/algoritmo de sobre, firma, claves, límites y reenvío pendientes; no extrapolar AES local a E2EE ya resuelto. |
| Puente | Dart/Kotlin sobre Android | Mismo motor de transporte con función/credencial restringida | Custodia y envío central; no es autor de casos ni receptor clínico por defecto. No se promete esta función en un navegador web. |
| Receptor local de dirección | Tecnología sin seleccionar | Vista nativa autorizada **o** servicio LAN seguro más cliente previamente disponible | Bloqueo de diseño abierto: HTTPS/autenticación, claves, instalación, sincronización y disponibilidad offline. Cloudflare/Supabase cloud no cubren solos este enlace. |
| Alojamiento web | Archivos HTML/CSS/JS generados | **Propuesta:** Cloudflare Pages para el build estático de Vite | No hay sitio publicado, dominio ni integración Git creada en este bloque. No habilita recepción local sin internet. |
| Marca y contenidos | SVG, fuentes, texto y recursos editoriales | SVG oficial del repositorio, Poppins y tokens del manual final | Clayful pendiente de disponibilidad/licencia en paquete. Materiales y ayuda necesitan fuente, vigencia y responsable; ningún stock de ayuda inventado. |
| Pruebas y calidad | Dart, TypeScript y SQL según capa | Flutter analyze/test existentes; **propuestos:** TypeScript estricto, ESLint, Vitest + React Testing Library, Playwright e integración SQL/RLS | Sin suites web/BD nuevas. Probar datos y permisos reales del contrato con fixtures ficticios, no solo botones ocultos. |
| Construcción y control de versiones | PowerShell/comandos CLI; YAML si se aprueba CI | Git/GitHub, SDK Flutter/Android/JDK; **propuestos:** Node.js compatible con Vite y npm con lockfile | Node es herramienta de build de la web. CI, contenedores y nuevos archivos de infraestructura no creados. |

No se agregan por defecto Firebase, FCM, mapas, analítica, IA, almacenamiento de evidencias, librería de gráficos ni framework CSS. Si más adelante se aprueban, deben tener finalidad y contrato propios. La campaña/sitio público editorial no implica un cuarto cliente privado ni un CMS ya implementado.

## 2. Organización prevista de la web

Una SPA privada con tres áreas de trabajo: supervisión MINED, escucha asignada y dirección. La sesión determina las áreas permitidas desde un rol y ámbito administrados de forma confiable. La URL, un selector de institución o un campo de formulario nunca concede facultades. Un mismo profesional con varias funciones deberá usar contextos explícitos y auditables.

Se propone React Router para navegación, hooks/contexto para el estado de interfaz y CSS con variables de marca. No hace falta introducir estado global adicional al inicio. Los datos de servidor se solicitan con proyecciones explícitas; evitar descargar un expediente completo y luego ocultarlo en React.

Se conservan las identificaciones funcionales de [docs/08](08-especificacion-funcional-setu.md): M01–M03, L01–L02 y D01–D04. Son pantallas de especificación, no rutas desplegadas. Las tablas presentan estados vacíos, acceso denegado, error, reconexión y confirmación pendiente. El color nunca es la única señal.

No se crea todavía un directorio web, `package.json`, instalación npm o pipeline. El nombre de carpeta y las versiones exactas pertenecen al bloque de implementación que se apruebe.

## Información y recursos multimedia

[ADR 0009](decisiones/0009-espacio-informativo-confirmado.md) confirma un espacio propio de Información; Netflix es un referente, sin API, catálogo o rastreadores integrados. La [especificación editorial](14-espacio-informativo-y-referente-netflix.md) define E10/E11, entradas, metadatos y DFD separados de casos.

Para una primera muestra se propone catálogo JSON versionado y texto/recursos autorizados en el paquete Flutter. [`video_player`](https://docs.flutter.dev/cookbook/plugins/play-video) es el candidato para reproducción nativa de video local o de red; requiere aprobar dependencia, versión, permisos y formatos. [Flutter permite empaquetar JSON y recursos](https://docs.flutter.dev/ui/assets/assets-and-images). Supabase podría distribuir futuras versiones publicadas; no se crea un CMS o cuarto panel ahora.

Video no implica adjuntos de casos o payload mesh. Offline solo se ofrece lo realmente disponible, con alternativa textual/transcripción y estado explícito. Autoplay, perfil de intereses/salud, identificación del caso en consultas o importación de contactos extranjeros no forman parte de esta integración.

## 3. Contratos que deben aprobarse antes de conectar

| Contrato lógico | Responsabilidad y comprobación |
| --- | --- |
| Configuración escolar | Centro y claves públicas auténticas, versión/caducidad; no basta confiar en datos de cualquier vecino. |
| Recepción de alerta | Identificador estable, centro validado, prueba del emisor, separación del relato y persistencia antes del recibo; reintento idempotente. |
| Consulta privada | Prueba de posesión/permiso del caso propio; otro estudiante con el mismo QR queda excluido. |
| Avisos y fichas | Proyección mínima por ámbito y conflicto; probar ausencia de chat en respuesta, caché y canales. |
| Conversación | Estudiante y mesa asignada, internet, mensajes persistidos e idempotencia; notas internas por separado. |
| Actuación y transición | Actor y facultad verificables; dirección propone cierre y MINED valida. No automatizar decisiones clínicas o disciplinarias. |
| Custodia y recepción | Acuse de vecino, local y central distintos, verificables y vinculados a operación; el puente no suplanta al emisor. |
| Contenido editorial | Publicación validada, territorio, fecha y responsable; consulta informativa sin crear un caso. |

No se inventan nombres de endpoints ni esquemas definitivos. El diccionario del [DFD](12-modelado-dfd-kendall.md) describe información, no autoriza estas APIs.

## 4. Configuración y recursos de operación

M1 funciona localmente sin `.env`, Supabase o Firebase. Para el sistema futuro, una URL de proyecto y clave pública/publicable de Supabase podrán configurar clientes; esa clave no es la autorización del usuario. Roles, RLS y sesiones deben proteger cada recurso. Claves secretas/`service_role`, códigos privados, firmas de recepción y claves de descifrado de destinatario permanecen fuera del cliente y de Git.

En Vite, las variables expuestas al bundle son públicas; no guardar secretos en variables `VITE_*`. En Flutter, `dart-define` tampoco convierte un secreto incrustado en seguro. No se agregan variables concretas antes de cerrar contratos y despliegue. Referencia: [variables de Vite](https://vite.dev/guide/env-and-mode).

La web necesita HTTPS y navegador soportado; el puente requiere Android compatible, batería, almacenamiento y permisos concedidos. Primera carga offline, caché del cliente, cifrado del navegador, cierre de sesión/borrado y terminal compartida requieren diseño. No conservar casos por defecto en `localStorage` o una caché PWA; no asumir que IndexedDB es cifrado de extremo a extremo.

El backend requiere proyecto/región, responsables, políticas, respaldo, retención y respuesta a incidentes. Alojar un prototipo de datos ficticios no implica autorización para recibir casos reales. No se crean cuentas o recursos cloud por documentarlos.

## 5. Verificación y versiones

Las versiones existentes se comprueban en `apps/mobile/pubspec.yaml`, `pubspec.lock`, Android y bitácora M1. Las integraciones nuevas se contrastaron con fuentes primarias el **9 nov 2026**, pero **no se verificó una combinación instalada** de React/Vite/Node/Supabase/Nearby ni una prueba física. Evitar fijar números de versiones de memoria; al aprobar un bloque, resolver compatibilidad conjunta, registrar versiones y conservar lockfiles.

Fuentes primarias: [React/TypeScript](https://react.dev/learn/typescript), [Vite](https://vite.dev/guide/), [React Router](https://reactrouter.com/start/declarative/installation), [Supabase JS](https://supabase.com/docs/reference/javascript/introduction), [Flutter SDK Supabase](https://supabase.com/docs/reference/dart/introduction), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Edge Functions](https://supabase.com/docs/guides/functions), [Realtime](https://supabase.com/docs/guides/realtime), [Cloudflare Pages/React](https://developers.cloudflare.com/pages/framework-guides/deploy-a-react-site/), [canales Flutter](https://docs.flutter.dev/platform-integration/platform-channels), [Nearby Android](https://developers.google.com/nearby/connections/android/get-started), [Cluster](https://developers.google.com/nearby/connections/strategies), [mobile_scanner](https://github.com/juliansteenbakker/mobile_scanner), [geolocator](https://github.com/Baseflow/flutter-geolocator), [Vitest](https://vitest.dev/guide/), [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/) y [Playwright](https://playwright.dev/docs/intro).
