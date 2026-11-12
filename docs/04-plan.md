# Plan y decisiones pendientes

**Revisión:** 2026-11-09. Producto vigente: ADR 0005/0009. Propuestas técnicas: ADR 0006/0008; alineación de manuales de uso: ADR 0007. La documentación no autoriza implementación.

## Fechas y evaluación

| Hito | Fecha | Peso y condición |
| --- | --- | --- |
| Reporte Pautado y Manual de Marca | 10 nov 2026; mediodía según planificación del equipo | Reporte 50 puntos. |
| Pitch | 17 nov 2026 | 20 puntos; guía dice en vivo. Propuesta operativa: 3 min, sujeta a confirmación. |
| Prototipo | 17 nov 2026 | 30 puntos; propuesta de demo de 2 min y hasta 1 min de preguntas. APK elegido por el equipo. |

La guía no impone software a todas las propuestas ni limita el producto a 12–17 años. El 10 nov 2026 cae martes, aunque algunas minutas dicen lunes. Mantener fechas numéricas hasta conciliar comunicación organizativa. El resumen de Drive dice Video Pitch; la guía oficial local dice pitch en vivo.

## Estado real

M0/M1: base Flutter, marca inicial, protección de pantalla, contratos y persistencia cifrada con alias/PIN, modelo anterior. Verificación M1 registrada el 5 nov: análisis limpio y 18 pruebas; prueba física pendiente. No hay envío remoto, paneles, acceso nuevo o mesh implementados.

El 12 de noviembre se incorporó la [bienvenida E01](diseno/plan-arranque-bienvenida-setu.md) como pantalla inicial, con vistas de muestra y marca de arranque Android. Los siguientes bloques conectados y de transporte requieren propuesta y aprobación propias.

## Decisiones que cambian la solución

| Prioridad | Decisión | Estado |
| --- | --- | --- |
| Confirmado | Flutter/Dart Android y backend objetivo Supabase/PostgreSQL | ADR 0001/0002 y decisiones de equipo. |
| Confirmado | Código público del colegio, código privado dirección y sin cuentas visibles | ADR 0005; implementación pendiente. |
| Confirmado | Tres superficies, mesa humana, tres niveles y seis nombres de prototipo | Producto del equipo; nombres finales, contratos y facultades por validar con MINED. |
| Confirmado | 3.º–11.º, Fase 1 urbana pública Managua | Adaptación de comprensión para primaria pendiente. |
| Confirmado | Espacio Información propio, complementario a alertas/escucha | ADR 0009: artículos, videos, testimonios editoriales y guías; acceso autónomo y durante la espera. Existencia confirmada, sin código implementado. |
| Antes de código conectado | Continuidad privada por caso y recuperación sin cuenta | Comparar sesión técnica, capacidad por caso y combinación. |
| Antes de mesh | Destinatario offline: alerta mínima local o custodia central | Drive describe entrega mínima local; aprobar claves, receptor y alcance. Entrega mínima local confirmada en los manuales y reunión; contrato técnico y claves por aprobar. |
| Antes de mesh | Primer ingreso offline, configuración, firma y claves auténticas | No resuelto por código público simple. |
| Antes de mesh | Transporte, biblioteca/canal Flutter, versiones y permisos | ADR 0008 propone Nearby Connections/Cluster vía canal Kotlin; sin instalación ni prueba física. Criptografía del sobre aún sin seleccionar. |
| Antes de paneles | Aprobar tecnología del cliente web | ADR 0008 propone React + TypeScript + Vite, React Router y Supabase JS; una SPA con áreas de permisos separados. Alternativas Flutter Web/Next.js documentadas. |
| Antes de recepción local | Disponibilidad y autenticación del receptor sin internet | Una web cloud no basta; decidir vista nativa o servicio LAN seguro, cliente disponible, claves y conciliación. |
| Antes de backend | Alta de personal, asignaciones, código privado y revocación | Código compartido no da auditoría individual. |
| Antes de código | Registro de aviso docente por dirección, origen y propiedad | Descrito en el manual de colegio; formulario mínimo por aprobar. |
| Antes de protocolo | Cierre MINED, derivación separada de Escalado, contacto familiar, conflicto y revelación excepcional | Manuales operativos en versión de trabajo y propuestas en docs/02; aprobación institucional pendiente. |
| Antes de piloto | MINED, centros, atención MINSA/practicantes, horarios y suplencia | Alianzas por validar, no confirmadas. |
| Antes de piloto | Revisión local de datos, región, retención y derechos | Pendiente. |
| Antes de publicar | Primer catálogo de Información y Ayuda, revisión, derechos y accesibilidad | Fuente, territorio, fecha, vigencia, responsable, etapa escolar, subtítulos/transcripción y archivos realmente disponibles. Diseñar catálogo/lector, reproductor y distribución; no decidir de nuevo si el apartado forma parte del producto. |
| Antes de presupuesto operativo | Conciliar Canvas/costos e incluir personal | Estimaciones incompatibles; sin financiación confirmada. |

## Bloques propuestos de desarrollo

1. **Viabilidad:** aprobar experimento físico A→B→puente, sobres ficticios, permisos y criterios. No empezar creando paneles completos.
2. **Contratos mínimos:** acceso privado, recepción idempotente, aviso mínimo y permisos; pruebas de integración con dos centros.
3. **Recorrido conectado:** estudiante → recepción → MINED/dirección con datos separados; sin atribuir chat al colegio.
4. **Offline:** cola protegida, custodia, puente, entrega local aprobada, sincronización y retorno de acuses.
5. **Interfaz y demo:** marca final, primaria/secundaria, fallos y guion. Chat y contenidos según prioridad aprobada.

El espacio Información es un frente de producto confirmado: especificar E10/E11, entrada sin reporte y retorno desde espera; aprobar por separado el bloque técnico de catálogo/lectura/video y su muestra editorial. Puede diseñarse con independencia de la viabilidad radio. El catálogo completo y la distribución offline se dimensionan según el corte, sin omitir este componente de la propuesta.

Cada bloque necesita propuesta concreta, preguntas materiales y aprobación explícita antes de código, dependencias, migraciones o estructura. Cambiar el generador documental no aprueba ninguno de estos bloques.

## Definición de terminado

Resultado real observado, datos ficticios, límites y fallas claros, sin filtración, pruebas proporcionales y documentación coherente. Permisos, transiciones y reintentos necesitan integración. Mesh exige teléfonos físicos y evidencia de saltos; simulaciones identificadas. Commit pequeño revisado, comprobaciones registradas y push o pendiente concreto de sincronización.
