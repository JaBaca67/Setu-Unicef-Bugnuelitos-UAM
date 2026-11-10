# ADR 0008 — Stack web y modelado lógico del sistema ampliado

- **Fecha:** 2026-11-09.
- **Estado:** Propuesto. No aprobado para implementación.
- **Alcance autorizado:** documentación de lenguajes, recursos y flujos; no instalar dependencias, crear clientes web, desplegar o migrar datos.

## Contexto

La app Android usa Flutter/Dart; Supabase/PostgreSQL es el backend objetivo confirmado. Los manuales distinguen panel MINED, mesa asignada y dirección, con proyecciones de información distintas. Faltaba una propuesta concreta para construir los paneles y separar los DFD lógicos de la arquitectura y navegación. Mesh debe llevar una alerta mínima a dirección aun sin internet; una web cloud no resuelve ese enlace.

## Propuesta

1. Un único cliente web de paneles en **React + TypeScript estricto + Vite**, HTML semántico y CSS con tokens de marca; React Router para las vistas por función. Compartir componentes no comparte permisos. MINED, escucha y dirección reciben contratos de datos distintos, autorizados en servidor y base de datos.
2. `@supabase/supabase-js` en web y `supabase_flutter` en móvil como SDK propuestos. Auth para personal con alta confiable; acceso estudiantil aún por resolver. PostgreSQL, SQL/PLpgSQL, RLS y funciones transaccionales para permisos, transiciones y recepción única. Edge Functions TypeScript/Deno solo cuando una operación confiable lo requiera; no crear un servidor Node adicional por anticipado.
3. Cloudflare Pages como alojamiento estático propuesto del cliente web; Supabase conserva el backend. Node.js compatible con Vite y npm son herramientas de construcción, no el backend de los casos. Versiones y lockfile nuevos se fijarán después de aprobar y verificar la combinación.
4. Evaluar **Nearby Connections / Cluster** Android mediante **Kotlin + canal de plataforma Flutter**, para evitar seleccionar un plugin sin revisión. El protocolo propio de sobres, custodia, límites, deduplicación y acuses sigue en diseño. Google Play services y compatibilidad física deben verificarse. No seleccionar aún el algoritmo o biblioteca del sobre E2E.
5. Vitest para lógica web y Playwright para recorridos; Flutter conserva sus pruebas. Aislamiento, transiciones y reintentos requieren integración contra backend de prueba. No se añaden suites en este bloque documental.
6. Modelos DFD originales con contexto, diagrama 0 y diccionario/balance según el enfoque de Kendall y Kendall; vista lógica de transporte independiente de los dispositivos/radios. SVG legibles y fuentes Mermaid integradas en el README.

## Alternativas

| Alternativa | Ventaja | Motivo para preferir provisionalmente la propuesta |
| --- | --- | --- |
| Flutter Web para los paneles | Un lenguaje y parte de la experiencia móvil compartida | React/HTML facilita formularios y tablas de escritorio convencionales; el equipo debe valorar costo de aprender TypeScript frente a reutilizar Dart. |
| Next.js con React | Rutas, renderizado y capacidades de servidor integradas | Los paneles privados no tienen una necesidad demostrada de SEO/SSR; Vite + Supabase limita infraestructura inicial. Revisar si aparece una necesidad concreta. |
| Clientes web separados por institución/función | Publicaciones independientes | Duplica mantenimiento en el MVP; el aislamiento real debe permanecer en backend con cualquiera de las dos opciones. |
| Plugin Flutter de proximidad | Menos código nativo inicial | Hay que revisar mantenimiento, permisos y compatibilidad; el canal Kotlin es candidato para un experimento pequeño, no una implementación ya elegida. |

## Consecuencias y decisiones abiertas

Se añade TypeScript/HTML/CSS al trabajo del equipo y Kotlin al experimento de proximidad. Son necesarias pruebas web y revisión accesible. No se introducen frameworks CSS, estado global adicional, analítica o push sin una necesidad aprobada. Poppins local y SVG oficiales son recursos de interfaz; Clayful requiere revisar disponibilidad/licencia antes de empaquetarlo.

Quedan pendientes el acceso privado por caso, aprovisionamiento offline, altas/revocación de personal, custodia criptográfica y el enlace seguro puente–dirección. La recepción local podría requerir vista nativa autorizada o servicio LAN autenticado con cliente disponible offline; no se elige una de estas opciones por dibujarla. Una PWA o caché de archivos por sí sola tampoco proporciona receptor, claves o sincronización.

Esta propuesta **no cambia las decisiones de producto de ADR 0005/0007** ni habilita casos reales. [Plan](../04-plan.md), [arquitectura](../02-arquitectura.md), [catálogo técnico](../13-recursos-tecnicos.md), [DFD](../12-modelado-dfd-kendall.md) y [README](../../README.md) deben conservar el mismo estado.

## Referencias técnicas primarias

Consultadas el 9 nov 2026: [React con TypeScript](https://react.dev/learn/typescript), [Vite](https://vite.dev/guide/), [React Router](https://reactrouter.com/start/declarative/installation), [Supabase JS](https://supabase.com/docs/reference/javascript/introduction), [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Edge Functions](https://supabase.com/docs/guides/functions), [React en Pages](https://developers.cloudflare.com/pages/framework-guides/deploy-a-react-site/), [canales Flutter](https://docs.flutter.dev/platform-integration/platform-channels) y [Nearby Strategies](https://developers.google.com/nearby/connections/strategies).
