# ADR 0028 — Relato y pieza por red mesh, dentro del sobre cifrado

**Estado:** aceptada · **Fecha:** 17 de noviembre de 2026 · **Aprobada por:** el usuario («Sí, relato + pieza»)

## Contexto

Durante la prueba del 17 nov, una alerta enviada sin internet llegó al panel de Mesa de Escucha sin el relato y sin la pieza: la ficha mostraba un ícono genérico. En Supabase, los casos `origin = mesh` tenían `student_piece = null` y no tenían `case_narratives`. La causa era doble:

1. ADR 0016 definía una carga mesh mínima: solo tipo de situación, rol y verificador.
2. `submit_student_alert` rechazaba con `mesh_origin_cannot_carry_narrative` cualquier alerta mesh que trajera relato o pieza.

## Decisión

- `MeshMinimalAlertPayload` suma dos campos opcionales: `narrative_text` y `student_piece`. Los dos van **dentro** del sobre X25519 + AES-GCM-256. Los teléfonos intermedios y la custodia del servidor solo ven el texto cifrado.
- Esos campos solo se llenan cuando el sobre va sellado para claves de personal autorizado (directorio `list_mesh_recipient_public_keys`). La proyección simulada con la clave escolar derivable (`MeshSchoolKeys`, solo para pruebas en memoria) usa `withoutPrivateFields()` y nunca los lleva.
- El relato por mesh se recorta a 1500 bytes en UTF-8 (`fitNarrative`, termina en «…»). Así el sobre nunca supera los 4 KB, aunque el texto tenga emojis.
- La migración `20261117000001_setu_mesh_narrative_and_piece` quita la guarda solo para relato y pieza en las cuatro versiones de `submit_student_alert`. El lugar y la fecha aproximada siguen prohibidos por mesh.
- Si una alerta llega sin pieza (de una versión anterior o con la pieza dañada), el panel muestra una **pieza base**: un rompecabezas azul sin accesorios, con la etiqueta «Pieza base».

## Consecuencias

- El psicólogo ve el comentario con la pieza real del estudiante tanto si la alerta llegó por internet como si llegó por mesh.
- Riesgo residual: un teléfono puente con la app modificada no puede leer el relato, porque no tiene la clave privada. El servidor guarda el relato igual que en las alertas en línea.
- Las alertas mesh anteriores a este cambio siguen sin relato. No se pueden recuperar.
