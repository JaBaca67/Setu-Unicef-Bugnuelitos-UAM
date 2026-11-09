# Producto y alcance de SéTú

**Vigente:** 2026-11-09, ADR 0005 y Drive. Especificación principal en [README](../README.md); trazabilidad en [docs/09](09-revision-drive-y-trazabilidad.md).

SéTú busca facilitar solicitudes privadas de apoyo ante acoso, violencia o malestar emocional y unirlas con escucha humana y seguimiento institucional. Combina app, campaña y rutinas presenciales. No se ha demostrado aún reducción del acoso ni impacto clínico.

## Población y territorio

Estudiantes de 3.º a 11.º grado, como víctimas o Testigos Solidarios. Fase 1 propuesta en colegios públicos del casco urbano de Managua; rural posterior. El material rural de Drive no cambia esa delimitación. Instrumentos de secundaria y familias no sustituyen pruebas de comprensión con estudiantes de primaria.

## Decisiones vigentes

- Entrada por código público escolar/QR, sin crear cuentas o perfiles. Código privado para dirección/enlace. QR/GPS aparece como intención; sus límites y alternativa siguen pendientes.
- Tres superficies: celular estudiantil, panel MINED y panel de dirección. MINED como primer intermediario institucional, con alianza por validar.
- Solicitud en tres pasos: tipo, rol y detalles opcionales. Tipos: acoso físico, verbal, social, ciberacoso, violencia sexual o necesidad de hablar.
- Mesa humana: profesionales de planta y propuesta de articulación MINSA/practicantes de 5.º año; sin chatbot. Tarjetas rompehielos y filtro de vocabulario sin clasificación decisiva.
- Aviso mínimo tipo/rol/hora; relato/chat reservados a escucha. Colegio recibe ficha autorizada y agregados, nunca el chat.
- Tres niveles: acompañamiento, convivencia y riesgo grave. Seis estados: Recibido, En escucha, Ficha enviada, Colegio actuando, Escalado y Cerrado.
- Alertas cifradas por red mesh hasta teléfono puente cuando falta internet. Recepción local y central diferentes; contrato de acceso local pendiente.
- Sección híbrida de testimonios, artículos y guías. Publicación y disponibilidad offline requieren revisión editorial y derechos de uso.
- Campaña para jóvenes y familias; docentes aplican rutinas impresas de 5–10 minutos y no usan la app.

## MVP y límites

Objetivo del 17 nov: un caso ficticio entre tres superficies con demostración de mesh. No afirmar que el código actual cumple ese recorrido. Las ampliaciones y bloques requieren aprobación previa.

No hay reportes públicos, rankings, chat entre estudiantes, diagnóstico, decisiones disciplinarias automáticas o terapia por IA. Adjuntos, actividades digitales adicionales y certificados institucionales no se agregan al MVP por aparecer en investigación/costos. No prometer anonimato absoluto, atención inmediata, confidencialidad ilimitada o resolución garantizada.

## Decisiones técnicas todavía abiertas

Continuidad privada por caso sin cuenta visible; recuperación/pérdida; credenciales individuales del personal; primer ingreso desconectado; destinatarios/claves de alerta local; transporte y permisos; protocolo humano y conflictos. Ver [plan](04-plan.md), [arquitectura](02-arquitectura.md) y [mesh](10-flujo-datos-y-red-mesh.md).

El código público no autoriza leer un caso. El sistema no tiene una identidad civil oculta que revelar. La ayuda publicada necesita fuente, territorio, fecha y responsable; los teléfonos de los borradores no se presentan como verificados.

## Evaluación y evidencia

La guía oficial fija 50 puntos para Reporte Pautado, 20 para Pitch y 30 para Prototipo, con adecuación por edad y accesibilidad. La guía permite evidencia tangible de distintos tipos: el APK es elección del equipo. No atribuir a la rúbrica funcionalidades, edad exclusiva 12–17 o una tecnología que no exige.

Éxito técnico: recorrido comprensible, datos separados, entrega verificable, reintentos sin duplicados y permisos probados. Éxito social: indicadores observables con línea base y responsables, sin presentar metas del Canvas como resultados o tiempos de respuesta garantizados.
