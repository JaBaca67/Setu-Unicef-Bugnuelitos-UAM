# Investigación inicial y skills

Antecedentes consultados el 2026-11-04. La revisión vigente de Drive y fuentes técnicas está en [docs/09](09-revision-drive-y-trazabilidad.md), 2026-11-09. Este documento conserva investigación histórica y no fija el alcance actual.

## Referentes y evidencia

| Fuente primaria | Hallazgo acotado | Implicación para Cureando |
| --- | --- | --- |
| [Andrea: sitio oficial](https://www.soyandrea.es/) y [funcionamiento](https://www.soyandrea.es/por-que-andrea/) | Presenta reportes anónimos y comunicación con profesionales de centros inscritos | Inspiración funcional; no prueba de eficacia, acceso a su tecnología o equivalencia de privacidad |
| [UNICEF Nicaragua: prevención y respuesta a la violencia](https://www.unicef.org/nicaragua/prevenci%C3%B3n-y-respuesta-la-violencia-abuso-y-explotaci%C3%B3n) | Describe trabajo de prevención y respuesta a la violencia contra la niñez | El acompañamiento humano y la articulación institucional importan; no implica aval al proyecto |
| [Ley n.º 787 en OEA](https://www.oas.org/es/sla/ddi/docs/N3%20Ley%20de%20Proteccion%20de%20Datos%20Personales.pdf) | Texto de referencia sobre protección de datos personales | Requiere revisión local de aplicabilidad y vigencia; no concluir cumplimiento |
| [Flutter: documentación oficial](https://docs.flutter.dev/) | Framework multiplataforma en Dart con compilación nativa a APK en Android y sistema de diseño Material 3 integrado | Seleccionado para la app móvil por experiencia previa del desarrollador, rapidez visual y generación directa de APK |
| [Supabase: RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) y [protección de datos](https://supabase.com/docs/guides/database/secure-data) | Controles de acceso a datos y relación con autenticación (`supabase_flutter`) | Diseñar políticas y pruebas, no depender de configuración implícita |

No se adoptan cifras de prevalencia como actuales sin identificar estudio, población y fecha. No se han verificado contactos de ayuda, costos, rúbrica de evaluación ni condiciones de tiendas móviles.

## Adaptación a Nicaragua: hipótesis por validar

Lenguaje comprensible localmente; dispositivos y conectividad disponibles; confianza en destinatarios; mecanismos de ingreso sin exclusión; participación apropiada de familias; capacidad real de atención y rutas locales de protección. Son temas de investigación, no características ya demostradas de la población.

## Skills consultadas y disponibles

Se consultó el catálogo curado de [openai/skills](https://github.com/openai/skills/tree/main/skills/.curated) mediante la skill-installer local. No se instalaron nuevas skills. El catálogo puede cambiar; no se identificó allí una skill específica para Flutter/Dart.

| Capacidad | Utilidad | Momento / límite |
| --- | --- | --- |
| security-threat-model | Estructurar amenazas y límites de confianza | Tras concretar identidad y flujo de datos; candidata a instalar |
| security-best-practices | Revisar prácticas del código | Al existir implementación; candidata a instalar |
| Figma y sus skills disponibles | Diseñar pantallas y traducir diseños | Si se decide trabajar en Figma; no necesario para iniciar documentación |
| Playwright | Probar un eventual panel web | No sustituye pruebas de la aplicación nativa; candidata futura |
| Presentations / PDF disponibles | Preparar material de evaluación | Cuando exista rúbrica y evidencia |
| skill-creator disponible | Crear una skill reutilizable si surge un flujo repetido | AGENTS.md y docs bastan para reglas propias iniciales |

Las skills no sustituyen conocimientos de desarrollo móvil, accesibilidad, protección infantil, revisión legal ni personal de atención. No instalar paquetes de fuentes desconocidas solo por mencionar móvil o UNICEF. Revisar procedencia, instrucciones y compatibilidad con el stack antes de adoptar una skill.

## Investigación siguiente

Guía y rúbrica oficiales ya presentes y revisadas el 9 nov; entrevistar responsables institucionales; validar el recorrido con participación segura de estudiantes; revisar marco local con una persona competente; verificar directorio de ayuda; medir conectividad y dispositivos del piloto. Registrar fecha, método y límites de cada hallazgo, evitando datos identificables en este repositorio.
