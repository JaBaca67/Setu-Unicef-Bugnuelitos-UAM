# Plan y decisiones pendientes

## Fases sin fechas comprometidas

| Fase | Resultado | Criterio de salida |
| --- | --- | --- |
| 0. Acordar bases | Alcance, equipo, población y rúbrica | Prioridades y stack confirmados |
| 1. Diseñar recorrido | Pantallas y protocolo simulado | Se entiende privacidad, envío y seguimiento |
| 2. Prototipo móvil | Reporte → bandeja → respuesta con datos ficticios | Recorrido funciona en dispositivo Android |
| 3. Verificar | Permisos, red, accesibilidad y guion | Fallos críticos corregidos y evidencias registradas |
| 4. Preparar evaluación | Demo reproducible y presentación | Requisitos de rúbrica trazables a evidencia |
| 5. Evaluar piloto | Acuerdos y operación | Cumplimiento de docs/03-proteccion-y-operacion.md |

No estimar fechas antes de conocer disponibilidad, habilidades y fecha límite. Evaluación del prototipo y piloto real son entregas distintas.

## Preguntas que cambian la solución

| Prioridad | Decisión | Estado |
| --- | --- | --- |
| Antes de código | Experiencia del equipo: JavaScript/TypeScript, Dart u otra | Pendiente |
| Antes de código | Integrantes, disponibilidad, fecha y rúbrica oficial | Pendiente |
| Antes de código | Android únicamente para demo o también iOS | Pendiente |
| Antes de backend real | Presupuesto, hosting, titularidad de cuentas | Pendiente |
| Antes de identidad | Edades, centros y mecanismo seguro de pertenencia | Pendiente |
| Antes de piloto | Quién atiende, horarios, escalamiento y conflictos | Pendiente |
| Antes de piloto | Revisión local, consentimiento/base jurídica y retención | Pendiente |
| Antes de publicación | Contactos de Nicaragua y contenidos revisados | Pendiente |

## Primer backlog propuesto

1. Confirmar decisiones de fase 0 y actualizar ADR 0001.
2. Diseñar cinco vistas: bienvenida/privacidad, inicio, reporte, seguimiento y bandeja de responsable. Añadir ayuda y autocuidado simples.
3. Crear estructura móvil y scripts reproducibles; documentar requisitos y arranque reales.
4. Definir contrato de permisos y esquema con datos ficticios; implementar pruebas de aislamiento antes de ampliar funciones.
5. Conectar el recorrido mínimo y simular red fallida, sesión perdida, ausencia de responsable y reapertura.
6. Preparar guion de evaluación y límites conocidos; registrar resultados sin inventar impacto.

## Definición de terminado para funcionalidades

Cumple criterios acordados, contempla carga/error/sin conexión cuando corresponda, no filtra datos, respeta permisos, funciona en el dispositivo objetivo y mantiene documentación coherente. Pruebas proporcionales al riesgo; no exigir métricas de cobertura artificiales. Ninguna demo usa reportes reales.
