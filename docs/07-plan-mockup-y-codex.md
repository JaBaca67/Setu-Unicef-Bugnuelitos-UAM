# Plan del prototipo y trabajo con agentes

**Revisión:** 2026-11-09. Sustituye el plan de app exclusivamente local con alias. Dirección de producto ADR 0005; especificación principal [README](../README.md). No autoriza nuevos bloques de código.

## Punto de partida

M1 ofrece infraestructura local cifrada, contratos anteriores, identidad y pantalla de verificación. No implementa recorrido estudiantil completo ni transporte, backend, paneles o chat remoto. Mantener su evidencia técnica en el README móvil y ADR 0004.

## Entrega prevista

El equipo busca demostrar un caso ficticio entre tres superficies y el tramo sin internet. El modo jurado anterior con conmutador estudiante/orientador en un solo APK no acredita ese objetivo y deja de ser la ruta principal de demostración.

Primero se necesita validar física y técnicamente la red. Un envío directo estudiante→puente es una etapa de prueba; dos saltos requieren un retransmisor distinto y excluir el contacto directo. No suponer que animar flechas demuestra radio o cifrado.

## Bloques propuestos

| Bloque | Resultado reviewable | Aprobación/pruebas |
| --- | --- | --- |
| Diseño previo | Acceso privado, claves/destinatarios, recepción local/central y contratos mínimos | Aprobación explícita; resolver preguntas de docs/04. |
| Experimento de proximidad | Transporte pequeño A→B→puente y recibos reales | Propuesta de dependencias/canal y equipos; prueba física. |
| Backend mínimo | Recepción idempotente y proyecciones separadas | Esquema/RLS aprobados; integración con dos centros y dos estudiantes. |
| Tres superficies | Reporte, aviso MINED, alerta/ficha dirección y actuación | Autorización real por recurso; sin selector público de roles privilegiados. |
| Cola y sincronización | Persistencia, custodia, reintentos y acuse central | Reinicio, duplicados, alteraciones y respuesta perdida. |
| Presentación | Marca final, accesibilidad y guion de 120 s | Revisión visual y evidencia de cada tramo. |

No crear carpetas futuras, servicios, dependencias, cuentas cloud o migraciones hasta aprobar el bloque correspondiente. Los datos locales M1 no se suben automáticamente.

## Guion propuesto de dos minutos

1. Estudiante confirma centro ficticio y prepara aviso como Testigo Solidario con detalles opcionales.
2. Sin internet, mostrar cola y transferencia por intermediario al puente; demostrar la separación del contenido.
3. Dirección ve solo alerta mínima local si su contrato técnico está aprobado/implementado; MINED aún figura pendiente. El chat requiere internet.
4. Restaurar internet del puente; un caso central pese a reintentos. MINED ve aviso/ficha correspondiente.
5. Mostrar acción humana autorizada y seguimiento privado del estudiante; MINED y dirección sin chat/relato/notas.

Preparar dispositivos, configuración, claves de demo y datos ficticios antes. Si mesa/chat no están implementados, delimitar esa parte del guion en vez de atribuir respuesta profesional a una plantilla automática.

## Trabajo con agentes

Leer README, docs/04, ADR 0005/0006 y documentos del bloque. Presentar alcance concreto, preguntas materiales y pruebas; obtener aprobación antes de código. Conservar cambios pequeños y actualizar documentos cuando cambien permisos, estados o datos.

Revisar diff antes de cada commit, seleccionar archivos expresamente y evitar APK, secretos y fuentes personales. Push al remoto al cerrar el bloque autorizado e informar hash, verificación y pendientes. No reescribir historia.
