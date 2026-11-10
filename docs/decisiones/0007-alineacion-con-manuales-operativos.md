# ADR 0007 — Alineación con manuales operativos de uso

- **Fecha:** 2026-11-09.
- **Estado:** registro documental de las versiones de trabajo del equipo. Validación institucional y aprobación de implementación pendientes.
- **Fuentes:** manuales de mesa de escucha, colegio y MINED de Drive (D11–D13 en docs/09) y reunión del 9 nov por la tarde.

## Contexto

La primera especificación técnica se redactó sin los tres manuales de uso y permitía estudiar una excepción de lectura clínica para supervisión MINED. También proponía usar Escalado ante riesgo grave y no tenía el registro de avisos docentes. Los manuales nuevos precisan esas reglas y declaran pendientes sus plazos, responsables y validación.

## Alineación del diseño

1. MINED y colegio no leen chat ni relato. La mesa asignada y el estudiante son sus destinatarios. Se retira la excepción propuesta para supervisión institucional.
2. El chat requiere internet. Sin internet se transmite alerta mínima cifrada hasta dirección; el contrato técnico, claves y canal local siguen pendientes.
3. La ficha lleva tipo, rol, hora y nivel profesional, sin relato/capturas. El nivel no se inventa en una alerta aún sin valorar.
4. Dirección registra avisos docentes preservando origen y actor institucional. Los docentes no reciben acceso a la app.
5. Dirección documenta y propone cierre al MINED; el cierre habitual corresponde al MINED. Cierre de nivel 1 sin ficha y reapertura requieren completar el contrato.
6. Escalado corresponde a falta de respuesta según el manual. Derivación por riesgo grave es un evento urgente independiente y no espera una transición del rastreador.
7. El contacto familiar se propone bloqueado mientras siga activo el anonimato. Responsables, doble autorización, datos y excepciones de protección necesitan validación antes de implementarlo.
8. Los seis nombres de estado se usan para prototipo y siguen pendientes de ajuste institucional. No se inventan plazos de atención, escalamiento o respuesta.

## Alternativas y consecuencias

Se descarta compartir chat con MINED para simplificar supervisión: contradice los manuales. Se descarta crear un usuario estudiantil ficticio para un aviso docente: altera origen y propiedad. Se mantiene separada la derivación de riesgo del escalamiento por demora para que la interfaz no equipare ambos acontecimientos.

El modelo conceptual necesita origen de alerta, facultades por actor, eventos de derivación y autorizaciones registradas. Eso no constituye un esquema SQL aprobado. Los borradores operativos no son certificación de cumplimiento legal ni clínico. Contradicciones o huecos restantes se conservan como decisiones abiertas en docs/04 y docs/09.

## Documentos afectados

README, docs/01–04, 06–10 y diagramas Mermaid. El corte móvil M1 sigue sin modificarse. Los bloques de código, migraciones, dependencias y generador visual conservan aprobación previa según AGENTS.md.
