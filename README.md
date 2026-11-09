# SéTú (Cureando) — Proyecto UAM & UNICEF 2026

**Equipo:** Bugñuelitos (Universidad Americana - UAM)  
**Temática oficial:** Apoyo a la Salud Mental de Niñas, Niños y Adolescentes (prevención del acoso escolar y acompañamiento socioemocional)
**Fechas de entrega:** Reporte Pautado y Manual de Marca: **10 de noviembre de 2026** (12:00 m.) | Prototipo y Pitch: **17 de noviembre de 2026**

SéTú es un puente confidencial hacia la ayuda para que niñas, niños y adolescentes de **3.º a 11.º grado** en Nicaragua sean escuchados y protegidos dentro y fuera de su colegio. Combina una **aplicación móvil ligera** y una **campaña permanente de sensibilización**, con el **Ministerio de Educación (MINED) como primer intermediario** de cada reporte para que ningún caso dependa de la capacidad o la voluntad de un solo colegio. La Fase 1 se plantea en colegios públicos del casco urbano de Managua.

El proyecto es una propuesta académica y de innovación social para la **Jornada Académica y Social para el Cumplimiento de los Derechos de la Niñez y Adolescencia (UAM - UNICEF 2026)**. No se presenta como producto oficial ni avalado por UNICEF ni por el MINED; las alianzas institucionales están por validar.

**Actualizado:** 2026-11-09. Las decisiones de producto vienen de los documentos del equipo en Google Drive y se registran en [ADR 0005](docs/decisiones/0005-alineacion-con-decisiones-del-equipo-drive.md). Ante conflicto con documentos anteriores del repositorio, prevalece ADR 0005.

## Propuesta (decisiones del equipo)

- **Acceso sin cuentas ni perfiles:** el estudiante entra con el código público de su colegio (cartel QR en el centro). Dirección y persona de enlace usan un código privado.
- **Pedir ayuda en tres pasos:** tipo de situación (acoso físico, verbal, social, ciberacoso, violencia sexual o necesidad de hablar), rol (**Víctima** o **Testigo Solidario**) y detalles opcionales. Líneas de ayuda siempre visibles.
- **Mesa de escucha humana:** chat confidencial con psicólogos de planta, alianza con MINSA y practicantes de Psicología de 5.º año, con filtro de vocabulario y tarjetas rompehielos. Sin chatbot ni IA. El anonimato solo se levanta por protección de la vida, con doble autorización, registro y aviso al estudiante.
- **Protocolo de 3 niveles:** Acompañamiento, Convivencia (acoso) y Riesgo grave (derivación a MIFAN, MINSA y Policía). **Estados del caso:** Recibido → En escucha → Ficha enviada → Colegio actuando → Escalado → Cerrado.
- **Tres superficies:** celular del alumno, panel del MINED y panel de dirección del colegio. El colegio no ve el chat; recibe una ficha de actuación y estadísticas anonimizadas.
- **Modo sin internet:** la alerta viaja cifrada de celular en celular (red mesh) hasta un teléfono puente del colegio y se sincroniza con el MINED al recuperar conexión.
- **Sección informativa** con testimonios, artículos y guías paso a paso, útil aun sin enviar un reporte.
- **Campaña:** Instagram y TikTok para jóvenes; Facebook y WhatsApp para familias; radio local; dinámicas de aula de 5 a 10 minutos guiadas por docentes, que **no usan la app**.

**MVP objetivo para el 17 de noviembre:** un caso viajando en vivo entre las tres superficies, con el modo sin conexión como demostración central.

**Costos estimados del piloto** (5 colegios, ~1,750 estudiantes): USD 25.93 al mes; USD 1,336.16 el primer año con 5 teléfonos puente; USD 0 para colegios y estudiantes. No incluye el personal de la mesa de escucha. Detalle en la hoja *SeTu_Costos_App* de Drive.

## Estado del código

El APK actual (0.2.0+2, bloque **M1**) implementa identidad visual SéTú, protección de capturas conmutable, contratos y un almacén local cifrado (AES-GCM-256) con cuentas por alias + PIN. Análisis limpio, 18 pruebas aprobadas; M0 verificado en teléfono y M1 pendiente de prueba física.

**Brecha con la propuesta:** el acceso por alias + PIN quedó reemplazado por el código del colegio; no existen todavía el envío entre dispositivos, los paneles del MINED y de dirección, el chat ni la red mesh. El almacén cifrado puede reutilizarse para alertas pendientes sin conexión. Cada bloque nuevo requiere propuesta y aprobación previa ([AGENTS.md](AGENTS.md)). La paleta del código (`app_theme.dart`) aún usa los colores del manual inicial.

Desde `apps/mobile/`: `flutter pub get`, `flutter analyze`, `flutter test` y `flutter build apk --debug`. Ver [la guía móvil](apps/mobile/README.md).

## Identidad e investigación

- **Manual de Marca final:** `Manual de Marca.pdf` en la carpeta *Diseño e Identidad Visual* de Drive (el PDF del repositorio es la versión inicial). Paleta `#0C62EB`, `#FF0092`, `#FFE000`, `#00C642`; Poppins y Clayful. Valores: Valentía, Empatía, Confianza, Respeto y Compromiso.
- **Investigación de campo:** entrevista de validación con la Lic. María Paola Castro Pérez (psicóloga, 8 nov 2026) y encuesta a estudiantes y familias (28 respuestas al 9 nov: 24 estudiantes y 4 familias; meta 40–50). Documentos en *Investigación y Campo* de Drive.

## Documentación del proyecto

- [ADR 0005 — Alineación con las decisiones del equipo](docs/decisiones/0005-alineacion-con-decisiones-del-equipo-drive.md): **fuente vigente**.
- [Plan y decisiones pendientes](docs/04-plan.md): fechas, rúbrica y preguntas abiertas.
- [Protección y operación](docs/03-proteccion-y-operacion.md): privacidad, atención humana y requisitos para un piloto.
- [Investigación y skills](docs/05-investigacion-y-skills.md) y [referencia de investigación aportada](docs/referencia-investigacion-gemini.md) (sus afirmaciones requieren verificación).
- Documentos con partes superadas por ADR 0005 (alias + PIN, solo local, 12–17 años), pendientes de reescritura: [visión y alcance](docs/01-producto.md), [arquitectura](docs/02-arquitectura.md), [guía de diseño](docs/06-guia-diseno.md), [plan de app local](docs/07-plan-mockup-y-codex.md), [especificación funcional E01–E11](docs/08-especificacion-funcional-setu.md), [diagramas de flujo](docs/diseno/flujos/index.html) y [fichas de pantallas](docs/diseno/pantallas-explicadas.html).
- Decisiones históricas: [ADR 0001](docs/decisiones/0001-base-propuesta.md), [ADR 0002 — M0](docs/decisiones/0002-inicializacion-android.md), [ADR 0003 — alias y persistencia local](docs/decisiones/0003-cuenta-alias-y-persistencia-local.md) (superado), [ADR 0004 — M1](docs/decisiones/0004-especificacion-m1-y-guia-codex.md).
- [Instrucciones para agentes](AGENTS.md).

## Versiones y guardado incremental

Cada avance coherente y verificado debe quedar en un commit pequeño y descriptivo. Separar cambios de código, documentación y referencias cuando sea útil; revisar lo incluido y registrar las comprobaciones. Sincronizar los commits con GitHub al cerrar cada bloque autorizado e informar sus hashes. No versionar APK, claves, bases de datos locales, cachés ni datos de estudiantes. Los commits no sustituyen la aprobación previa para implementar cada fase.
