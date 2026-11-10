# Producto y alcance de SéTú

**Vigente:** 2026-11-09, ADR 0005 y Drive. Especificación principal en [README](../README.md); trazabilidad en [docs/09](09-revision-drive-y-trazabilidad.md).

SéTú busca facilitar solicitudes privadas de apoyo ante acoso, violencia o malestar emocional y unirlas con escucha humana y seguimiento institucional. Combina un espacio propio de información y orientación, solicitudes/atención, campaña y rutinas presenciales. Informarse también es una finalidad autónoma, sin necesidad de reportar. No se ha demostrado aún reducción del acoso ni impacto clínico.

## Población y territorio

Estudiantes de 3.º a 11.º grado, como víctimas o Testigos Solidarios. Fase 1 propuesta en colegios públicos del casco urbano de Managua; rural posterior. El material rural de Drive no cambia esa delimitación. Instrumentos de secundaria y familias no sustituyen pruebas de comprensión con estudiantes de primaria.

## Decisiones vigentes

- Entrada por código público escolar/QR, sin crear cuentas o perfiles. Código privado para dirección/enlace. QR/GPS aparece como intención; sus límites y alternativa siguen pendientes.
- Tres superficies: celular estudiantil, panel MINED y panel de dirección. MINED como primer intermediario institucional, con alianza por validar.
- Solicitud en tres pasos: tipo, rol y detalles opcionales. Tipos: acoso físico, verbal, social, ciberacoso, violencia sexual o necesidad de hablar.
- Mesa humana: profesionales de planta y propuesta de articulación MINSA/practicantes de 5.º año; sin chatbot. Tarjetas rompehielos y filtro de vocabulario sin clasificación decisiva.
- Aviso mínimo tipo/rol/hora; relato/chat reservados a escucha. Colegio y MINED reciben ficha autorizada y agregados, nunca chat ni relato. El chat necesita internet; la alerta sí puede viajar por mesh.
- Tres niveles: acompañamiento, convivencia y riesgo grave. Seis nombres de prototipo: Recibido, En escucha, Ficha enviada, Colegio actuando, Escalado y Cerrado; nombres finales por validar con MINED. Derivación urgente es un evento separado de Escalado por falta de respuesta.
- Alertas cifradas por red mesh hasta teléfono puente cuando falta internet. Recepción local y central diferentes; contrato de acceso local pendiente.
- **Información es parte confirmada de la solución**: artículos, videos, testimonios editoriales y guías para explorar por curiosidad, entender situaciones/emociones y acompañar la espera de atención. Accesible desde bienvenida/inicio y seguimiento, sin reporte o QR obligatorio para leer. [ADR 0009](decisiones/0009-espacio-informativo-confirmado.md) y [origen en Meet/referente Netflix](14-espacio-informativo-y-referente-netflix.md). No diagnostica, no publica casos privados y no cambia una alerta al consultar un recurso. Catálogo, revisión, derechos y disponibilidad offline por resolver.
- Campaña para jóvenes y familias; docentes aplican rutinas impresas de 5–10 minutos y no usan la app.

## MVP y límites

Objetivo del 17 nov: un caso ficticio entre tres superficies con demostración de mesh. No afirmar que el código actual cumple ese recorrido. Las ampliaciones y bloques requieren aprobación previa.

La propuesta y el prototipo deben representar también el recorrido de información independiente y su entrada durante la espera, con contenido de ejemplo identificado y límites del corte explícitos. El apartado no queda opcional por priorizar su implementación por bloques; no se promete un catálogo completo o videos offline ya operativos.

No hay reportes públicos, rankings, chat entre estudiantes, diagnóstico, decisiones disciplinarias automáticas o terapia por IA. Adjuntos, actividades digitales adicionales y certificados institucionales no se agregan al MVP por aparecer en investigación/costos. No prometer anonimato absoluto, atención inmediata, confidencialidad ilimitada o resolución garantizada.

## Decisiones técnicas todavía abiertas

Continuidad privada por caso sin cuenta visible; recuperación/pérdida; credenciales individuales del personal; primer ingreso desconectado; destinatarios/claves de alerta local; transporte y permisos; protocolo humano y conflictos. Ver [plan](04-plan.md), [arquitectura](02-arquitectura.md) y [mesh](10-flujo-datos-y-red-mesh.md).

El código público no autoriza leer un caso. El sistema no tiene una identidad civil oculta que revelar. La ayuda publicada necesita fuente, territorio, fecha y responsable; los teléfonos de los borradores no se presentan como verificados.

## Evaluación y evidencia

La guía oficial fija 50 puntos para Reporte Pautado, 20 para Pitch y 30 para Prototipo, con adecuación por edad y accesibilidad. La guía permite evidencia tangible de distintos tipos: el APK es elección del equipo. No atribuir a la rúbrica funcionalidades, edad exclusiva 12–17 o una tecnología que no exige.

Éxito técnico: recorrido comprensible, datos separados, entrega verificable, reintentos sin duplicados y permisos probados. Éxito social: indicadores observables con línea base y responsables, sin presentar metas del Canvas como resultados o tiempos de respuesta garantizados.
