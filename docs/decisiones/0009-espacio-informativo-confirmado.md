# ADR 0009 — Espacio informativo confirmado como parte de SéTú

- **Fecha:** 2026-11-09.
- **Estado:** Aceptado como decisión de producto; implementación técnica pendiente de aprobación.
- **Base:** acuerdo de Meet del 9 nov, Resumen General de Drive y confirmación explícita del usuario en esta sesión.

## Contexto

ADR 0005 ya recogía información híbrida, pero el README la presentaba de forma secundaria y podía confundirse con una ampliación opcional. El usuario confirma que es parte integral de la solución y pide documentar origen, referente, recorridos e integración.

La [sesión de las 13:33 CST](https://docs.google.com/document/d/1c6E9dED-tzHSSu2ciC-TWYNtGH2fxLXYpq14DAt0Eeg/edit) registra la propuesta desde 01:21:40 bajo la etiqueta Andrea Juárez y menciona expresamente lectura durante la espera desde 01:23:49. La atribución y los límites de la nota automática se explican en [docs/14](../14-espacio-informativo-y-referente-netflix.md). El usuario aporta el enlace de Netflix y una copia HTML local como referente de información y acompañamiento.

## Decisión de producto

SéTú combina solicitudes/atención con una biblioteca **Información**, accesible desde bienvenida/inicio y desde la espera de atención. Artículos, videos, testimonios editoriales y guías ayudan a conocer temas, comprender situaciones/emociones y explorar posibilidades de apoyo, incluso sin reportar. Entradas E10/E11, ayuda E09 y retorno al seguimiento permanecen diferenciados.

Consultar no requiere cuenta o caso ni convierte a la persona en paciente; no genera diagnóstico, perfil emocional o nivel de alerta. No es necesario completar contenido para pedir apoyo. Abrir/cerrar un recurso no confirma recepción o atención de una alerta, ni altera su estado. El contenido editorial no reutiliza relatos privados ni publica testimonios estudiantiles enviados a la plataforma.

## Alternativas consideradas

- **Solo reportes/chat:** no cubre el acuerdo de acceso autónomo y acompañamiento durante la espera; se descarta como descripción completa de la solución.
- **Solo enlazar el portal externo:** no proporciona por sí solo un espacio propio, adecuado al territorio/etapa escolar y consistente con la app. El portal es referente, sin API, catálogo o contactos importados automáticamente.
- **Espacio propio de información y orientación:** decisión confirmada. La selección/publicación del catálogo y su entrega técnica requieren revisión específica.

## Consecuencias y límites

Actualizar README, producto, pantallas, diseño, plan, arquitectura/recursos, flujos y contexto de agentes. Añadir un DFD editorial independiente evita vincular lectura con casos o llevar multimedia por mesh. No cambia los permisos de MINED, dirección o mesa.

Catálogo JSON/recursos Flutter, `video_player` candidato y distribución editorial futura son propuestas; no se instalan dependencias, crean carpetas, implementan pantallas o publican recursos en este bloque documental. Textos por edad, derechos, revisión profesional, accesibilidad, vigencia y disponibilidad offline se resuelven antes de publicar. «Híbrido» significa información más atención, sin prometer todo el multimedia sin conexión.

No se modifican los originales de Drive. Se registran aquí los acuerdos y la especificación que debe reflejarse en manuales del producto y entregables del equipo. El código M1 permanece sin cambios.
