# Plan de aplicación Android funcional local e instrucciones para agentes

Actualizado el 2026-11-05. Decisiones vigentes: Flutter/Dart, cuenta por alias, solicitudes de seguimiento y persistencia protegida local. Supabase es el backend futuro. Ver [ADR 0003](decisiones/0003-cuenta-alias-y-persistencia-local.md).

## Reglas de trabajo

1. Antes de implementar, presentar archivos, diseño, dependencias y preguntas del bloque; esperar aprobación explícita. Aprobar una dirección de producto no equivale a aprobar cualquier paquete o esquema.
2. Explicar siempre los códigos de fase con su descripción. El usuario no ha aprobado todavía el orden concreto de los nuevos bloques.
3. Mantener sincronizados README, AGENTS, documentos de diseño y decisiones. Distinguir implementado, aprobado y propuesto.
4. Crear commits pequeños por avance revisado y verificado; separar código, documentación y referencias. Revisar el diff y hacer push al cerrar el bloque autorizado. Informar hashes y pendientes. No incluir datos locales, secretos, APK o cachés.
5. Usar razonamiento cuidadoso para contratos, permisos, persistencia e identidad visual; no introducir abstracciones sin necesidad.

## Objetivo y límites

Construir una app funcional que permita crear una cuenta con alias, redactar y guardar casos, consultar mensajes y realizar solicitudes de seguimiento. Los datos funcionales de prueba deben permanecer al cerrar/reabrir el proceso. El mecanismo concreto de persistencia protegida está pendiente de propuesta y aprobación.

Sin backend, los datos permanecen en un solo teléfono. Guardado local no significa envío al centro ni comunicación con otro dispositivo. La interfaz debe explicarlo y no atribuir respuestas locales a un servicio institucional conectado. Desinstalar o borrar datos puede eliminar el contenido; no prometer copias o recuperación inexistentes.

Se mantienen el enfoque de Testigo Solidario, chips guiados, conflicto de interés y ruta alternativa, cita discreta voluntaria y apoyo externo como alcance objetivo. No recibir casos reales de menores en esta etapa. Contactos de ayuda con datos reales contrastados, fuente y fecha de revisión, pero llamadas y derivaciones sin activar en el corte local. No afirmar disponibilidad 24/7 sin verificarla.

## Evaluación e identidad

Según el contexto del equipo y sus documentos de evaluación: Reporte Pautado (50 puntos) el 10 de noviembre de 2026; Pitch (20) y Prototipo (30) el 17 de noviembre. Preparar un recorrido de presentación de dos minutos sin prometer puntuación máxima ni convertir la interfaz principal en una galería de mockups.

Aplicar el logo original del manual de marca y Poppins para la interfaz. Colores exactos: azul #0D61EB, rosa #FF0091, amarillo #FFE100 y verde #00C642; superficies suaves y tokens en [la guía visual](06-guia-diseno.md). Verificar contraste por combinación y escalado de texto, sin afirmar cumplimiento AA/AAA de toda la app por usar una paleta. No reemplazar el logo por una invención ni reutilizar fuentes incrustadas sin contar con sus archivos y licencia adecuados.

## Arquitectura objetivo, todavía no implementada

- `CureandoGateway`: contrato para cuentas, reportes, conversación y solicitudes.
- `LocalCureandoGateway`: adaptador principal con persistencia protegida en el teléfono.
- Acceso de orientación separado del estudiantil; notas internas fuera de los modelos visibles al estudiante.
- `MockCureandoGateway`: solo para pruebas automáticas o simulación explícita; no será el almacenamiento principal de la aplicación.
- `SupabaseCureandoGateway`: futuro adaptador remoto. No subir datos locales automáticamente al incorporarlo.
- `lib/features/`: funcionalidades; `lib/shared/contracts/`, `lib/shared/local/`, `lib/shared/theme/` y widgets compartidos según necesidad. No crear carpetas vacías antes de aprobar el bloque.

## Fases con descripción y estado

### M0 — Base Android, compilación e instalación

Implementado: proyecto en `apps/mobile/`, pantalla de comprobación, `go_router`, tema provisional, Dart estricto y `FLAG_SECURE` global. Análisis sin incidencias, dos pruebas aprobadas y APK debug compilado. Instalación USB exitosa, apertura en primer plano, transición del botón de prueba, escalado de fuente al 200 % y bloqueo de capturas (`FLAG_SECURE`) verificados en teléfono Android por ADB el 2026-11-05. Ver [guía móvil](../apps/mobile/README.md) y [ADR 0002](decisiones/0002-inicializacion-android.md).

Solicitado para una presentación: poder activar/desactivar la protección de pantalla. Su configuración concreta requiere aprobación antes de implementarse; el APK actual no tiene interruptor. No es necesario un modo demo como navegación principal.

### M1 visual — Identidad y componentes reutilizables

Propuesto: `CureandoTheme`, logo original, Poppins local, botones, campos, tarjetas, chips y estados accesibles. Usar estos componentes directamente en las pantallas funcionales. No hacer una galería de componentes como entrega principal. Archivos, dependencias y orden pendientes de aprobar.

### M1 datos — Cuenta por alias, contratos y persistencia protegida

Dirección aprobada: cuenta por alias, conservación de datos funcionales locales y solicitudes de seguimiento. Antes de implementar concretar contraseña y recuperación, esquema, cifrado, gestión de claves, paquetes y separación de permisos.

Persistir cuentas y centros de prueba, reportes guardados, mensajes, estados, solicitudes y notas internas separadas. No almacenar credenciales en texto plano, duplicar relatos en logs ni conservar borradores descartados.

Código de Caso + PIN puede mantenerse como acceso complementario a un único caso con solicitudes de seguimiento. Su convivencia con la cuenta por alias, formato, permisos y límites de intentos todavía deben concretarse. No presentar recuperación entre tabletas como disponible sin backend.

### M2 — Bienvenida, registro/acceso e Inicio funcionales

Objetivo: E01 con Testigo Solidario y límites; E02 con registro/acceso por alias y vinculación al centro; E03 con los reportes de la cuenta y accesos a ayuda. La invitación permite vincular centro, no sustituye el acceso a la cuenta. Mantener QR escolar como propuesta de simulación explícita para el recorrido de presentación, sin cámara todavía. Detalles de formularios pendientes de aprobación.

### M3 — Reporte guiado y guardado local idempotente

Objetivo: E04 con rol afectado/testigo, chips de tipo y lugar, relato, fecha aproximada opcional y conflicto de interés; E05 con revisión y destinatario previsto; E06 con confirmación de guardado local. Evitar presentar un caso local como recibido por una institución.

Reintentos sin duplicar. Pruebas de falla antes de guardar y resultado incierto después de guardar. Aviso de ayuda local por palabras de riesgo como propuesta a validar, sin diagnóstico, clasificación automática decisiva ni bloqueo del reporte. Ayuda siempre disponible aunque no se detecten palabras.

### M4 — Seguimiento, atención local y apoyo

Objetivo: E07/E08 con mensajes y solicitudes de seguimiento, cita discreta y apoyo externo. En caso cerrado, solicitar seguimiento no reabre automáticamente el estado. Atención local con respuestas manuales, notas internas separadas y autorización por cuenta/ámbito, incluida ruta alternativa por conflicto. El selector de perfiles de prueba no sustituye autenticación real ni permisos de servidor.

E09: información real verificada, servicios sin activar; E10/E11: cápsulas revisadas y opcionales. Si se conservan herramientas de simulación o respuesta automática, deben ser auxiliares de desarrollo y explícitas, no el funcionamiento principal.

### M5 — APK y validación del recorrido completo

Análisis, pruebas, instalación y verificación física. Comprobar conservación tras cerrar/reabrir, separación entre cuentas, notas internas, conflicto de interés y reintentos. Preparar el recorrido de presentación de dos minutos con los límites locales claramente entendidos.

## Siguiente paso

Presentar al usuario un bloque concreto con archivos, dependencias y preguntas de credenciales/persistencia antes de implementar. No asumir aprobado todo M1 por haber aprobado almacenar localmente. Documentar cada decisión y guardar el avance en commits incrementales.
