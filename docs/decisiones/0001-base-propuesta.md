# ADR 0001 — Base móvil en Flutter (Dart) y backend gestionado en Supabase

- Fecha original: 2026-11-04.
- Última actualización: 2026-11-05.
- Estado: **Aceptado**.

## Contexto

Cureando necesita una aplicación móvil para una evaluación y eventualmente un piloto de reportes escolares privados en Nicaragua. Se prioriza contar rápidamente con un prototipo funcional instalable como `.apk` en un teléfono Android real, con una interfaz cuidada, clara y accesible, y una arquitectura preparada para conectarse a un backend fuerte con aislamiento estricto entre instituciones educativas.

El desarrollador principal ya cuenta con experiencia previa trabajando con **Flutter y Dart** en otros proyectos.

## Decisión adoptada

1. **Aplicación móvil:** **Flutter + Dart**, priorizando compilación y validación directa en **Android (`.apk`)** y manteniendo compatibilidad multiplataforma si más adelante se requiere iOS.
2. **Arquitectura interna móvil:** Separación por funcionalidades (`lib/features/`) y contratos desacoplados (`lib/shared/contracts/`). Según ADR 0003, el objetivo vigente es `LocalCureandoGateway` con persistencia protegida y cuenta por alias; el mock en memoria queda para pruebas, no como aplicación principal. Implementación pendiente de propuesta técnica.
3. **Backend y persistencia:** **Supabase (Auth + PostgreSQL con RLS y funciones transaccionales `RPC`)**, consumido desde Dart mediante el SDK oficial `supabase_flutter` cuando se active la capa de red.
4. **Exclusiones mantenidas:** Evitar microservicios, adjuntos multimedia e IA clínica.

## Por qué se eligió Flutter + Dart frente a React Native + Expo

- **Curva de aprendizaje y velocidad real del equipo:** Ya existe experiencia práctica previa en Flutter/Dart, lo que reduce fricción, errores de configuración y tiempo de entrega.
- **Diseño visual consistente desde el primer día:** Flutter incluye el motor gráfico propio (Impeller/Skia) y componentes completos de Material 3 listos para personalizar (tarjetas, estados de carga, formularios accesibles, animaciones suaves) sin depender de ensamblar múltiples librerías de terceros ni lidiar con diferencias visuales entre versiones de Android.
- **Generación directa de APK en Android:** `flutter build apk` genera el instalador `.apk` de forma directa y predecible con el SDK local de Android, sin depender de colas de compilación en la nube (EAS) ni configuraciones intermedias de *prebuild*.
- **Integración fuerte con el backend:** `supabase_flutter` ofrece soporte oficial de primera clase en Dart para Auth, llamadas a funciones transaccionales PostgreSQL (`rpc()`) y manejo seguro de sesión.

## Alternativas descartadas

- **React Native + Expo + TypeScript (descartada el 2026-11-05):** Estuvo planteada como borrador inicial cuando se desconocía la experiencia del equipo, pero se descarta para aprovechar la experiencia existente en Flutter/Dart, la facilidad de diseño visual nativo en Flutter y el empaquetado directo de `.apk`. Ningún documento ni agente debe usar React Native/Expo en este repositorio.
- **Android nativo (Kotlin):** Descartado por ahora dado que ya se domina Flutter/Dart y Flutter permite construir la UI más rápido manteniendo la puerta abierta a otras plataformas.
- **Backend propio desde cero (Node/Python/Go + servidor gestionado):** Descartado para la etapa inicial porque exige mantener infraestructura adicional de autenticación y APIs que PostgreSQL + RLS + funciones `RPC` en Supabase resuelven con menor carga operativa.

## Consecuencias

- Base móvil tipada con análisis estático de Dart (`flutter analyze`) y pruebas de widgets/contratos (`flutter test`).
- El diseño de seguridad, aislamiento entre colegios (RLS + claves foráneas compuestas), idempotencia y protección del estudiante en `docs/02-arquitectura.md` se mantiene íntegro en PostgreSQL/Supabase, independientemente de que el cliente móvil sea Flutter.
