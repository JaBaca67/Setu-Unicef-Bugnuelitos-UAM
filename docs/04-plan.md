# Plan y decisiones pendientes

## Fechas oficiales de evaluación (Jornada UAM - UNICEF 2026)

| Hito oficial | Fecha | Peso en rúbrica | Formato / requisito clave |
| --- | --- | --- | --- |
| **Reporte Pautado** | **10 nov 2026** | **50 % (50 pts)** | Problema y evidencia (10), Población y derechos (10), Solución e innovación (12), Impacto e indicadores (8), Viabilidad y riesgos (6), Fuentes y transparencia (4) |
| **Prototipo funcional** | **17 nov 2026** | **30 % (30 pts)** | **2 minutos de demo en vivo**: Coherencia y recorrido completo (10), Desarrollo y calidad tangible en APK (10), Adecuación a 12–17 años, inclusión y accesibilidad (10) |
| **Elevator Pitch + Jurado** | **17 nov 2026** | **20 % (20 pts)** | **3 minutos de pitch + 1 min de preguntas**: Síntesis (5), Problema/solución (5), Valor y derechos (5), Comunicación y defensa (5) |

Evaluación del prototipo académico (con datos ficticios) y un eventual piloto real en un centro educativo siguen siendo entregas distintas.

## Preguntas que cambian la solución

**Decisiones nuevas confirmadas:** cuenta por alias, solicitudes de seguimiento y datos funcionales persistentes en el teléfono (ADR 0003). ADR 0004 aprobó y M1 implementó credenciales, paquetes y almacén cifrado; análisis limpio y 18 pruebas aprobadas. Pantallas completas M2–M4 pendientes.

| Prioridad | Decisión | Estado |
| --- | --- | --- |
| Antes de código | Stack móvil y experiencia: **Flutter + Dart** (experiencia previa confirmada) | Confirmado (2026-11-05) |
| Antes de código | Plataforma inicial: **Android mediante APK instalable** (`E01`–`E08` + Modo Demo Jurado) | Confirmado (2026-11-05) |
| M0 | Base: `go_router`, controladores posteriores con `ChangeNotifier`, `FLAG_SECURE` global, APK debug e instalación USB | Verificado en teléfono USB por ADB (instalación, botón, `FLAG_SECURE` y fuente 200%) (2026-11-05) |
| Antes de código | Fecha y rúbrica oficial: **Jornada UAM - UNICEF 2026 (10 nov Reporte / 17 nov Pitch y Prototipo)** | Confirmado (2026-11-05) |
| Antes de código | Población destinataria: **Adolescentes de secundaria en Nicaragua (12–17 años, 7.º a 11.º grado, afectados y testigos)** | Confirmado (2026-11-05) |
| Antes de backend real | Presupuesto, hosting, titularidad de cuentas en Supabase | Pendiente |
| Antes de identidad | Centros y mecanismo seguro de pertenencia para piloto | Pendiente; edades del prototipo ya confirmadas |
| Antes de piloto | Quién atiende, horarios, escalamiento y conflictos | Pendiente |
| Antes de piloto | Revisión local, consentimiento/base jurídica y retención | Pendiente |
| Antes de publicación | Contactos de Nicaragua y contenidos revisados | Pendiente |

## Primer backlog propuesto

1. Completar M0: base Flutter, análisis, pruebas, APK debug y validación USB; registrar evidencia real.
2. M1 implementado: contratos, cuenta por alias/PIN y LocalCureandoGateway cifrado; mock solo para pruebas. APK compilado e instalación física pendiente. Presentar el siguiente bloque de pantallas M2 para aprobación.
3. Seguir M2–M4 para registro/acceso por alias, inicio, ayuda informativa, reporte guardado localmente y solicitudes de seguimiento. Los detalles de atención local y herramientas de presentación requieren propuesta; no son un servicio institucional conectado.
4. Completar M5 y guion de evaluación. Autocuidado y backend real quedan fuera de M0.

## Definición de terminado para funcionalidades

Cumple criterios acordados, contempla carga/error/sin conexión cuando corresponda, no filtra datos, respeta permisos, funciona en el dispositivo objetivo y mantiene documentación coherente. Pruebas proporcionales al riesgo; no exigir métricas de cobertura artificiales. Ninguna demo usa reportes reales.
