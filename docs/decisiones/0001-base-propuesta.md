# ADR 0001 — Base móvil y backend gestionado

- Fecha: 2026-11-04.
- Estado: propuesto; pendiente de confirmación del equipo.

## Contexto

Cureando necesita una app móvil para una evaluación y eventualmente un piloto de reportes escolares en Nicaragua. Repositorio inicialmente vacío. No se conocen habilidades, presupuesto, fecha, población exacta ni operación institucional.

## Propuesta

React Native + Expo + TypeScript, validación inicial en Android y backend Supabase con PostgreSQL/RLS. Primera demo con datos ficticios, reporte textual y seguimiento asíncrono. Evitar microservicios, adjuntos e IA clínica. Desarrollar una vista mínima de atención; evaluar panel web cuando se confirme la operación.

## Alternativas

- Flutter/Dart: reconsiderar si es la experiencia principal del equipo; no se ha hecho evaluación comparativa detallada.
- Android nativo: reconsiderar si Android es el único objetivo y el equipo domina Kotlin.
- Backend propio: aporta control pero exige operación y mantenimiento adicionales; considerar si los requisitos exceden la solución gestionada.
- PWA: posible complemento o prototipo web, pero no se adopta como sustituto automático de la app móvil solicitada.

## Consecuencias

Una base móvil compartida y menor infraestructura inicial. A cambio, dependencia de proveedor, necesidad de aprender y probar RLS, validar costos/región de datos y resolver identidad seudónima. iOS requiere su propia validación y recursos. La elección técnica no resuelve el protocolo humano de atención.

## Confirmación y revisión

Confirmar habilidades, plataformas, fecha y presupuesto antes de crear el scaffold. Actualizar a aceptado únicamente al contar con acuerdo del equipo; registrar motivo si cambia. Las reglas de minimización y protección no dependen de seleccionar este stack.
