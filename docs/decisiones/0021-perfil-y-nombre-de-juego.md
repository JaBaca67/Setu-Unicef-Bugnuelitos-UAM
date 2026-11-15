# ADR 0021 · Rediseño de «Mi perfil», «Mi pieza» y nombre de juego de catálogo

- **Estado:** aceptada (15 nov 2026), tras aprobación de la propuesta del bloque.
- **Ajusta:** [ADR 0015](0015-mi-pieza-y-pedir-apoyo.md) («Mi pieza») y [ADR 0018](0018-sesion-escolar-y-perfil-estudiantil.md) (apodo libre en perfil y alertas).

## Contexto

El apodo de «Mi pieza» usaba un campo de texto libre (`TextField`), por lo que la app no podía impedir que un estudiante escribiera su nombre real y lo enviara en `student_piece.displayName` al pedir apoyo. Además, «Mi perfil» mezclaba en una misma vista las pestañas internas «Resumen» / «Mi pieza» y requería alinear la presentación visual con la maqueta aprobada.

## Decisión

- **Catálogo cerrado de nombre de juego (`piece_name_catalog.dart`).** Se reemplaza el campo de texto libre por dos selectores de palabras predefinidas (**Nombre** + **Apodo**, 12 × 12 = 144 combinaciones con concordancia automática de género: *Chispa Cósmica* / *Cometa Cósmico*) y el botón **«Al azar»**. Se excluyen nombres de pila comunes y adjetivos físicos o negativos. Pendiente de revisión de copy por Psicología antes de piloto real.
- **Migración de perfiles anteriores.** Al abrir `setu_student_session.enc`, si el `displayName` guardado coincide con una combinación del catálogo (incluido `Pulgin Valiente`, valor inicial en el primer ingreso), se conserva como `PieceName`. Si es un apodo de texto libre fuera del catálogo, se preserva forma, color, accesorios y `LearningProgress`, se limpia el texto libre del almacén local y `displayName` pasa a `null`.
- **«Mi perfil» (`/inicio/pieza`) rediseñado.** Conserva el acceso desde el avatar de Inicio y muestra:
  1. Escenario ilustrado con el fondo azul y motivos de SéTú, el nombre de juego o la acción **«Elegí un nombre de juego»** si falta uno válido, y el botón **«Personalizar mi pieza»**.
  2. **«Lo que lleva»:** tarjetas solo para los accesorios equipados (ilustración y nombre), que abren el editor en «Accesorios»; sin accesorios ofrece **«Probar accesorios»**.
  3. **«Mi aprendizaje»:** racha actual, XP totales, barra de nivel con el umbral vigente (`50 XP` por nivel en `LearningProgress`) y acceso **«Ver mi racha»** al calendario actual (`/inicio/racha`).
  4. **«Mi colegio y ajustes»** al final, desplegable con el colegio activo y **«Salir del colegio»** con confirmación.
- **Editor «Mi pieza» (`/inicio/pieza/editar?pestana=forma|color|accesorios|nombre`).** Trabaja sobre un borrador: vista previa en vivo de personaje y nombre, cuatro pestañas (`Forma`, `Color`, `Accesorios`, `Nombre`), reacción visual breve (`PieceHop`) al equipar un accesorio respetando movimiento reducido y aviso visible en texto (`Semantics(liveRegion: true)`). **«Guardar mi pieza»** persiste el borrador en `setu_student_session.enc`; volver atrás descarta los cambios no guardados.
- **Qué se conserva al salir del colegio.** `StudentSession.leaveSchool()` borra únicamente `school` de `setu_student_session.enc`. Se conservan la pieza (forma, color, accesorios), el nombre de juego y todo `LearningProgress` (racha, XP, nivel e historial).
- **Qué datos acompañan una alerta.** En nuevas alertas (`SupportFlow.send`), `student_piece` envía `shape`, `color`, `accessories` y `displayName` únicamente cuando el estudiante tiene un nombre de juego válido del catálogo; si `name == null`, `displayName` se omite. La racha, los XP y el nivel nunca salen del perfil local. Las alertas ya guardadas o enviadas (`delivery['piece']` y casos en Supabase) no se modifican ni se reinterpretan al reintentar la entrega.

## Consecuencias y pendientes

- El riesgo de incluir un nombre civil en `displayName` queda eliminado por diseño en la UI estudiantil nueva, manteniendo compatibilidad con el contrato `student_piece` (`jsonb`) del servidor.
- Falta validación editorial/psicológica de la lista final de palabras del catálogo y verificación manual en dispositivo físico Android.
