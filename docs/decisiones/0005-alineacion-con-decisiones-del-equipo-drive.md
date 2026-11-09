# ADR 0005 — Alineación del repositorio con las decisiones del equipo (Drive, 9 nov 2026)

- **Fecha:** 2026-11-09
- **Estado:** Aceptado. Reemplaza en dirección de producto a [ADR 0003](0003-cuenta-alias-y-persistencia-local.md) y deja a [ADR 0004](0004-especificacion-m1-y-guia-codex.md) como registro técnico de lo ya implementado en M1.
- **Fuente:** documentos del equipo en la carpeta compartida de Google Drive (*Resumen General y Avance*, *Reporte Pautado Bugñuelitos UAM-UNICEF 2026*, *SeTu_Costos_App*, *Lean Canvas SéTú*, *Entrevista de validación clínica* y minutas de reuniones hasta el 9 de noviembre de 2026). El coordinador indicó que, ante cualquier conflicto entre el repositorio y Drive, prevalece Drive.

## Contexto

El repositorio documentaba al 5 de noviembre una app local con cuenta por alias + PIN, sin envío a otros dispositivos y con población de secundaria (12–17 años). Entre el 5 y el 9 de noviembre el equipo tomó en reuniones decisiones de producto distintas, registradas en Drive y en el Reporte Pautado que se entrega el 10 de noviembre. Este ADR las trae al repositorio para que la documentación no contradiga el reporte ni el pitch.

## Decisiones adoptadas (fuente: Drive)

1. **Acceso sin cuentas ni perfiles.** El estudiante entra con el **código público de su colegio** (cartel QR impreso en el centro). La dirección y la persona de enlace usan un **código privado** con correo registrado. El Reporte Pautado describe además una verificación por **geolocalización** al escanear el QR para confirmar pertenencia sin pedir nombre ni carnet. Sustituye la cuenta por alias + PIN de ADR 0003.
2. **Población:** estudiantes de **3.º a 11.º grado** (primaria desde 3.º grado y secundaria de 1.º a 5.º año). Fase 1 en colegios públicos del **casco urbano de Managua**; zonas rurales en una fase posterior.
3. **Tres superficies conectadas:** (a) celular del alumno, (b) panel del MINED como primer intermediario supervisor, (c) panel de dirección del colegio. El colegio nunca recibe el chat; recibe una ficha de actuación y estadísticas anonimizadas de su centro.
4. **Modo sin internet:** con conexión, la alerta viaja al servidor, al panel del MINED y al de dirección. Sin conexión, la alerta viaja **cifrada de celular en celular (red mesh)** hasta un **teléfono puente** del colegio y se sincroniza con el MINED al recuperar conexión.
5. **MVP para el 17 de noviembre:** un caso viajando en vivo entre las tres superficies, con el modo sin conexión (red mesh) como demostración central.
6. **Flujo del estudiante:** elegir tipo de situación (acoso físico, verbal, social, ciberacoso, violencia sexual o necesidad de hablar), rol (**Víctima** o **Testigo Solidario**) y detalles opcionales. Líneas de ayuda siempre visibles (133 MIFAN, 118 Policía Nacional; verificar antes de publicar).
7. **Mesa de escucha humana:** chat estilo WhatsApp con filtro de vocabulario y **tarjetas rompehielos**, atendido por psicólogos de planta, alianza con MINSA y practicantes de Psicología de 5.º año. Atención y revelación de identidad voluntarias; el anonimato solo se levanta por protección de la vida con doble autorización, registro y aviso al estudiante. Sin chatbot ni IA.
8. **Protocolo de 3 niveles de alerta:** Nivel 1 Acompañamiento (malestar emocional, se resuelve en el chat); Nivel 2 Convivencia (acoso; ficha al MINED y al colegio con 5 pasos: identificar, comunicar a dirección, comunicar a la familia, acompañar y dar seguimiento); Nivel 3 Riesgo grave (atentado contra la vida o abuso sexual; derivación a MIFAN, MINSA y Policía). Basado en los protocolos de Consejerías de las Comunidades Educativas del MINED.
9. **Seis estados del caso:** Recibido → En escucha → Ficha enviada → Colegio actuando → Escalado → Cerrado.
10. **Sección informativa híbrida** en la app (referencia: portal de temas sensibles de Netflix y app Flo): testimonios en video, artículos y guías paso a paso, útil aun sin enviar un reporte.
11. **Docentes fuera de la app.** Las rutinas de aula de 5 a 10 minutos y las dinámicas (semáforo emocional, dado de emociones, telaraña de la amistad, el mundo al revés, mi amigo de confianza) son material presencial de la campaña, articulado con los EPI del MINED.
12. **Campaña:** Instagram y TikTok para jóvenes, Facebook (y WhatsApp) para madres, padres y adultos, radio local y talleres o escuela para padres.
13. **Costos del piloto** (5 colegios, ~1,750 estudiantes): USD 25.93/mes (Supabase Pro + dominio); USD 1,336.16 el primer año incluyendo cuenta de Google Play y 5 teléfonos puente; USD 0 para colegios y estudiantes. Estimación de SROI 7.45x basada en supuestos (3 % de detección temprana). El costo del personal de la mesa de escucha no está incluido en la hoja.
14. **Identidad:** marca **SéTú** con tilde; Manual de Marca final en Drive (`Manual de Marca.pdf`); paleta `#0C62EB`, `#FF0092`, `#FFE000`, `#00C642`; misión, visión y valores (Valentía, Empatía, Confianza, Respeto y Compromiso). Mascota Pulgin/Tapudín.
15. **Equipo:** Fátima Moreira se retiró; **Andrea Nicole Juárez Díaz** la reemplaza en el Pitch y apoyo estratégico.

## Consecuencias

- El código de M1 (alias + PIN, almacén local cifrado AES-GCM) sigue en el repositorio y funciona, pero **ya no es la dirección de producto**. El almacén cifrado puede reutilizarse para guardar alertas pendientes del modo sin conexión; la autenticación por alias + PIN debe reemplazarse por el acceso con código de colegio.
- El MVP del 17 de noviembre requiere trabajo no iniciado: paneles del MINED y de dirección, envío real entre dispositivos y red mesh. Cada bloque sigue necesitando propuesta y aprobación antes de implementarse (AGENTS.md).
- Los documentos `docs/01`, `02`, `06`, `07`, `08`, `diseno/` y `apps/mobile/README.md` describen el modelo anterior en partes; llevan un aviso que remite a este ADR hasta su reescritura.
- `apps/mobile/lib/shared/theme/app_theme.dart` aún usa la paleta anterior (`#0D61EB`, `#FF0091`, `#FFE100`); cambiarla es una tarea de código pendiente.

## Puntos abiertos

- Rango de edad: el prototipo y la encuesta de estudiantes se diseñaron para secundaria; Drive fija 3.º a 11.º grado. Confirmar cómo se adapta la interfaz a primaria.
- Geolocalización: definir si se pide solo al escanear el QR y que no se guarde la ubicación precisa.
- Viabilidad técnica de la red mesh en Android antes del 17 de noviembre.
- Validación de la ruta de reportes con el MINED (alianza por validar).
- Financiamiento del personal de la mesa de escucha.
- Formato del Pitch: el repositorio decía elevator pitch en vivo de 3 minutos; el Resumen de Drive lo llama "Video Pitch". Confirmar con la guía oficial.
