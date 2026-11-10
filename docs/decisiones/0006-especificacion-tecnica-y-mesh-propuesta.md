# ADR 0006 — Especificación técnica y transporte mesh propuestos

- **Fecha:** 2026-11-09.
- **Estado:** Propuesto. No autoriza código, dependencias, migraciones, despliegues ni recepción de casos reales.
- **Base aceptada:** ADR 0005 y fuentes de Drive inventariadas en docs/09.

## Contexto

El equipo amplió SéTú a tres superficies, acceso sin cuentas, escucha humana y alertas offline por teléfonos puente. El código M1 conserva el modelo local anterior. El README y los diagramas necesitan explicar la nueva visión sin presentar decisiones técnicas pendientes como implementaciones.

## Propuesta documental y técnica

1. README como especificación principal; arquitectura, pantallas y flujos alineados con producto vigente.
2. Separar alerta mínima, relato/chat, ficha, actuaciones y notas por destinatario y permisos.
3. Distinguir estado de transporte y estado institucional; recepción local no equivale a recepción central.
4. Evaluar almacenamiento y reenvío oportunista con Nearby Connections como transporte candidato. Sin plugin elegido ni pruebas físicas efectuadas.
5. Sobres cifrados hasta el destinatario, no claves comunes en el APK. Puente/retransmisor sin acceso al relato. Acuses auténticos, identidad propia del emisor y deduplicación entre rutas.
6. Acceso privado de caso independiente del código público del colegio; mecanismo de continuidad por aprobar.
7. Conservar los seis estados acordados, proponiendo ramas para nivel 1 y riesgo grave en vez de forzar una secuencia universal.

## Alternativas pendientes

| Decisión | Alternativas | Consecuencia |
| --- | --- | --- |
| Continuidad estudiantil | Sesión técnica sin formulario; capacidad privada por caso; combinación | Recuperación, uso compartido y primer ingreso offline distintos. |
| Destino offline | Solo sobre central; alerta mínima local separada; ficha local autorizada | Cambian claves, exposición y capacidad de actuar sin supervisión central. |
| Transporte | Nearby Connections; implementación nativa BLE/Wi-Fi; conexión directa como etapa de prueba | Compatibilidad, costo de desarrollo y prueba real de varios saltos. |
| Panel sin internet | Vista nativa local; cliente previamente disponible con servicio LAN autenticado | Hosting cloud por sí solo no resuelve lectura local. |
| Credenciales de personal | Código privado como canje hacia sesión atribuible; acceso compartido temporal de demo | Revocación y auditoría individual deben resolverse antes de casos reales. |

## Consecuencias y aprobación

La especificación puede orientar revisión y wireframes; las interfaces y el modelo propuestos no deben copiarse a migraciones sin revisión. Se mantienen ADR 0002/0004 como historia del código existente y ADR 0003 como superado.

Para aceptar un bloque de desarrollo: acordar destinatarios y recuperación; cerrar claves/credenciales y límites de transporte; definir pruebas; obtener aprobación explícita del paso actual conforme a AGENTS.md. La aprobación de documentación o de un generador de diagramas no aprueba la arquitectura de seguridad.

## Aclaración de las propuestas por los manuales operativos

ADR 0007 precisa que MINED no lee chat/relato y el chat requiere internet. El alcance de alertas locales es decisión de producto; falta el contrato técnico. La derivación urgente no fuerza el estado Escalado por falta de respuesta, y el cierre habitual lo realiza MINED tras documentación del colegio. Esta aclaración sustituye cualquier interpretación incompatible de las alternativas anteriores.
