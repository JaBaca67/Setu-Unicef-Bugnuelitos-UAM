# SéTú (Cureando) — Proyecto UAM & UNICEF 2026

**Equipo:** Bugñuelitos (Universidad Americana - UAM)  
**Temática oficial:** Apoyo a la Salud Mental de Niñas, Niños y Adolescentes (Prevención del acoso escolar y acompañamiento socioemocional)  
**Fechas de entrega:** Reporte Pautado: **10 de noviembre de 2026** (12:00 m.) | Prototipo y Pitch: **17 de noviembre de 2026**

SéTú es una plataforma móvil para adolescentes de secundaria en Nicaragua (12 a 17 años) orientada a romper la cultura del silencio frente al acoso escolar y situaciones de vulnerabilidad, permitiendo a víctimas y testigos pedir apoyo privado, dar seguimiento continuo y acceder a recursos de bienestar y ayuda verificada.

El proyecto es una propuesta académica y de innovación social desarrollada para la **Jornada Académica y Social para el Cumplimiento de los Derechos de la Niñez y Adolescencia (UAM - UNICEF 2026)**. No se presenta como producto oficial ni avalado por UNICEF.

**Estado:** M1 implementado: identidad SéTú, protección de pantalla conmutable, contratos y persistencia local cifrada. Análisis limpio, 18 pruebas aprobadas y APK 0.2.0+2 compilado. M0 se verificó en teléfono; instalación y prueba física de M1 pendientes por ausencia de dispositivo ADB. Los formularios completos E01–E11 siguen en fases posteriores. **Actualizado:** 2026-11-05.

## Documentación del Proyecto

- **[Especificación Funcional Detallada SéTú](docs/08-especificacion-funcional-setu.md)**: bosquejo textual completo de pantallas (`E01`–`E11`), módulos incluidos, exclusiones explícitas y Modo Demo Jurado 2 Minutos para compartir con el equipo.
- [Diagramas de flujo históricos](docs/diseno/flujos/index.html): pendientes de actualizar para cuenta por alias y persistencia local; [fuentes e imágenes](docs/diseno/flujos/README.md).
- [Fichas anteriores de pantallas](docs/diseno/pantallas-explicadas.html): referencia visual histórica; usar el plan vigente para registro y datos. [Versión Markdown](docs/diseno/pantallas-explicadas.md).
- [Visión y alcance](docs/01-producto.md): problema, personas usuarias, MVP y exclusiones.
- [Arquitectura propuesta](docs/02-arquitectura.md): stack, módulos, datos y permisos.
- [Protección y operación](docs/03-proteccion-y-operacion.md): privacidad, atención humana y requisitos para un piloto.
- [Plan y decisiones pendientes](docs/04-plan.md): fases, criterios de entrega y preguntas abiertas.
- [Plan de app funcional local](docs/07-plan-mockup-y-codex.md): fases, contratos desacoplados, persistencia y aprobaciones.
- [Investigación y skills](docs/05-investigacion-y-skills.md): referencias, límites de la evidencia y herramientas.
- [Guía para diseño en Figma](docs/06-guia-diseno.md): pantallas prioritarias, contenido, estados y prototipo.
- [Mapa visual de pantallas](docs/diseno/flujo-pantallas.html): archivo autónomo para abrir y compartir; [SVG](docs/diseno/flujo-pantallas.svg) para importar a Figma.
- [Registro de decisiones](docs/decisiones/0001-base-propuesta.md) y [ADR 0002 — Inicialización Android M0](docs/decisiones/0002-inicializacion-android.md).
- [Decisiones de M0](docs/decisiones/0002-inicializacion-android.md): navegación, estado, identidad de la demo y protección de pantalla.
- [Cuenta por alias y datos locales](docs/decisiones/0003-cuenta-alias-y-persistencia-local.md): decisiones aprobadas y límites actuales.
- [Referencia de investigación aportada](docs/referencia-investigacion-gemini.md): contenido de Gemini sin metadatos de sesión; sus afirmaciones requieren verificación.
- [M1 aprobado y resultados](docs/decisiones/0004-especificacion-m1-y-guia-codex.md).
- [Proyecto móvil, seguridad y comprobaciones](apps/mobile/README.md).
- [Instrucciones para agentes](AGENTS.md): contexto y forma de trabajar en este repositorio.

## Punto de partida

Stack técnico confirmado para el prototipo: **Flutter + Dart** para la aplicación móvil (con prioridad en Android y generación directa de `.apk`) y **Supabase (Auth + PostgreSQL con RLS)** para el backend futuro. Población del prototipo: secundaria, 12–17 años. El calendario de evaluación está registrado en docs/04-plan.md; presupuesto e institución piloto siguen pendientes.

La siguiente entrega objetivo es una **app funcional local**: cuenta por alias, reportes y solicitudes de seguimiento guardados en el teléfono, incluso después de cerrar y abrir la app. El motor local ya implementa cuentas por alias + PIN, respaldo, casos y solicitudes con AES-GCM-256 y credenciales derivadas PBKDF2; sus formularios se conectarán en M2–M4. Las decisiones técnicas fueron aprobadas en ADR 0004. Supabase se conectará después mediante `CureandoGateway`. Guardar en el teléfono no equivale a enviar al centro ni permite consultar desde otro dispositivo. Solo datos ficticios hasta cumplir los requisitos de un piloto real.

La pantalla M1 muestra el isotipo original, Poppins y colores del manual, estado del almacén, protección de capturas y lectura Normal/Grande. Usa `go_router`, Material 3 y `ChangeNotifier`. El almacén persiste datos, pero las sesiones de acceso no se conservan. No hay backend ni formularios completos de reportes todavía.

Desde `apps/mobile/`: `flutter pub get`, `flutter analyze`, `flutter test` y `flutter build apk --debug`. Ver requisitos y rutas locales en [la guía móvil](apps/mobile/README.md). M1 ya está aprobado e implementado; el siguiente bloque de pantallas M2 requiere su propuesta y aprobación.

## Versiones y guardado incremental

Cada avance coherente y verificado debe quedar en un commit pequeño y descriptivo. Separar cambios de código, documentación y referencias cuando sea útil; revisar lo incluido y registrar las comprobaciones. Sincronizar los commits con GitHub al cerrar cada bloque autorizado e informar sus hashes. No versionar APK, claves, bases de datos locales, cachés ni datos de estudiantes. Los commits no sustituyen la aprobación previa para implementar cada fase.
