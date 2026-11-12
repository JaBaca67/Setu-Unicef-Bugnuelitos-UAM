# Fichas de pantallas vigentes

**Revisión:** 2026-11-09. Esta ficha sustituye la explicación anterior por alias/PIN y orientador escolar con acceso al chat.

La especificación de pantallas se mantiene en un único lugar: [docs/08 — Especificación funcional](../08-especificacion-funcional-setu.md). Allí están finalidad, entradas, acciones, salidas y límites de E01–E11 (estudiante), M01–M03 (MINED), L01–L02 (escucha) y D01–D04 (dirección). B01 identifica estado técnico propuesto del puente.

[Diagramas de flujo](flujos/README.md) · [Marca y accesibilidad](../06-guia-diseno.md) · [Transporte y datos](../10-flujo-datos-y-red-mesh.md).

La [bienvenida E01](plan-arranque-bienvenida-setu.md) abre el corte Android actual, con destinos de muestra para Colegio, Ayuda e Información. El código M1 conserva infraestructura del modelo anterior. No volver a usar alias/PIN como entrada vigente, ni entregar el chat al colegio, ni indicar recepción central cuando solo se guardó el aviso localmente.
