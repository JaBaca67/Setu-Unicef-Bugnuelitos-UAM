# Plan y decisiones pendientes

## Fechas oficiales de evaluación (Jornada UAM - UNICEF 2026)

| Hito oficial | Fecha | Peso en rúbrica | Formato / requisito clave |
| --- | --- | --- | --- |
| **Reporte Pautado + Manual de Marca** | **10 nov 2026 (12:00 m.)** | **50 % (50 pts)** | Problema y evidencia (10), Población y derechos (10), Solución e innovación (12), Impacto e indicadores (8), Viabilidad y riesgos (6), Fuentes y transparencia (4) |
| **Prototipo funcional** | **17 nov 2026** | **30 % (30 pts)** | **2 minutos de demo en vivo**: Coherencia y recorrido completo (10), Desarrollo y calidad tangible en APK (10), Adecuación a 12–17 años, inclusión y accesibilidad (10) |
| **Elevator Pitch + Jurado** | **17 nov 2026** | **20 % (20 pts)** | **3 minutos de pitch + 1 min de preguntas**: Síntesis (5), Problema/solución (5), Valor y derechos (5), Comunicación y defensa (5) |

Evaluación del prototipo académico (con datos ficticios) y un eventual piloto real en un centro educativo siguen siendo entregas distintas.

## Preguntas que cambian la solución

**Decisiones vigentes (2026-11-09):** [ADR 0005](decisiones/0005-alineacion-con-decisiones-del-equipo-drive.md) alinea el repositorio con Drive: acceso sin cuentas por código del colegio, tres superficies (alumno, MINED, dirección), mesa de escucha humana, protocolo de 3 niveles y 6 estados, modo sin internet por red mesh y población de 3.º a 11.º grado. La cuenta por alias de ADR 0003 queda superada; el almacén cifrado de M1 (ADR 0004) sigue implementado.

| Prioridad | Decisión | Estado |
| --- | --- | --- |
| Antes de código | Stack móvil y experiencia: **Flutter + Dart** (experiencia previa confirmada) | Confirmado (2026-11-05) |
| Antes de código | Plataforma inicial: **Android mediante APK instalable** | Confirmado (2026-11-05) |
| MVP 17 nov | Caso en vivo entre **tres superficies** (celular del alumno, panel MINED, panel de dirección) con **modo sin conexión por red mesh** | Decidido por el equipo (Drive, ADR 0005); implementación no iniciada |
| Acceso | **Código público del colegio (QR)** para estudiantes y **código privado** para dirección/enlace; sin cuentas | Decidido (ADR 0005); reemplaza alias + PIN |
| M0 | Base: `go_router`, controladores posteriores con `ChangeNotifier`, `FLAG_SECURE` global, APK debug e instalación USB | Verificado en teléfono USB por ADB (instalación, botón, `FLAG_SECURE` y fuente 200%) (2026-11-05) |
| Antes de código | Fecha y rúbrica oficial: **Jornada UAM - UNICEF 2026 (10 nov Reporte / 17 nov Pitch y Prototipo)** | Confirmado (2026-11-05) |
| Antes de código | Población destinataria: **estudiantes de 3.º a 11.º grado (víctimas y Testigos Solidarios)**, Fase 1 en colegios públicos del casco urbano de Managua | Decidido (Drive, ADR 0005); adaptar interfaz a primaria pendiente |
| Antes de backend real | Presupuesto estimado: USD 25.93/mes (Supabase Pro + dominio), USD 1,336.16 el primer año con 5 teléfonos puente | Estimado (hoja *SeTu_Costos_App*); titularidad de cuentas y costo del personal de escucha pendientes |
| Antes de piloto | 5 colegios del piloto y validación de la ruta con el MINED | Pendiente (alianza por validar) |
| Antes de piloto | Quién atiende: psicólogos de planta, alianza MINSA y practicantes de 5.º año; escalamiento por 3 niveles | Modelo decidido (ADR 0005); horarios, convenios y conflictos pendientes |
| Antes de piloto | Revisión local, consentimiento/base jurídica y retención | Pendiente |
| Antes de publicación | Contactos de Nicaragua y contenidos revisados | Pendiente |

## Backlog vigente

1. M0 y M1 completados (base Flutter, identidad, protección de pantalla, almacén cifrado). Prueba física de M1 pendiente.
2. Proponer y aprobar el bloque del MVP del 17 de noviembre: acceso por código de colegio, flujo de reporte (tipo, rol, detalles), paneles del MINED y de dirección, envío entre dispositivos y modo sin conexión (red mesh + teléfono puente). Evaluar primero la viabilidad técnica de la red mesh en Android.
3. Chat de mesa de escucha, sección informativa y estados del caso según el tiempo disponible.
4. Guion de la demo de 2 minutos y del Pitch; alinear colores del código con el Manual de Marca final.

## Definición de terminado para funcionalidades

Cumple criterios acordados, contempla carga/error/sin conexión cuando corresponda, no filtra datos, respeta permisos, funciona en el dispositivo objetivo y mantiene documentación coherente. Pruebas proporcionales al riesgo; no exigir métricas de cobertura artificiales. Ninguna demo usa reportes reales.
