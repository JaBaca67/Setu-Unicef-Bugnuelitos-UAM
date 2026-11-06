# Arquitectura base

Estado: stack móvil (Flutter/Dart) y backend objetivo (Supabase/PostgreSQL) confirmados; modelo de datos y políticas en fase de diseño previo a implementación. Ver [decisión 0001](decisiones/0001-base-propuesta.md).

**Actualización vigente:** [ADR 0003](decisiones/0003-cuenta-alias-y-persistencia-local.md) aprueba cuenta por alias, solicitudes de seguimiento y almacenamiento protegido local. M1 ya implementa el adaptador local y sus contratos según ADR 0004; las pantallas completas y el backend siguen pendientes.

## Selección técnica

| Capa | Selección / Propuesta | Motivo / condición |
| --- | --- | --- |
| App móvil | Flutter + Dart | Experiencia previa en el equipo, UI consistente con Material 3 y compilación directa de APK en Android (`flutter build apk`) |
| Navegación | `go_router`, aprobado en M0 | Organización por pantallas; M0 solo tiene la ruta de comprobación `/` |
| Estado móvil | `ChangeNotifier` nativo para futuros controladores | M0 usa estado efímero de widget para el botón de comprobación, sin crear controladores vacíos |
| Persistencia inicial | Almacenamiento local protegido mediante `LocalCureandoGateway` | Implementado en M1: archivo AES-GCM-256, clave protegida por Keystore, credenciales PBKDF2; ADR 0004 |
| Backend | Supabase: Auth y PostgreSQL (`supabase_flutter`) | Reducir operación inicial, tipado claro y expresar permisos en datos |
| Operaciones sensibles | Funciones SQL restringidas (`RPC`) / servidor | Validar pertenencia, cuotas, envío idempotente y transiciones en una sola transacción |
| Datos | PostgreSQL con RLS y privilegios mínimos | Aislar instituciones y sesiones |
| Panel de atención | Vista mínima por rol para demo; web por decidir | Evitar dos productos completos desde el inicio |

No seleccionar todavía bibliotecas secundarias innecesarias, proveedores de analítica o planes de pago. Flutter permite compilar APK nativo para Android desde el inicio según su [documentación oficial](https://docs.flutter.dev/). Supabase documenta [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security); habilitarla no reemplaza diseñar y probar políticas.

## Flujo y límites de confianza

App no confiable → autenticación → API/operaciones autorizadas → PostgreSQL con RLS. La identidad y la institución se derivan de la sesión y pertenencias verificadas, no de valores aceptados sin validación desde el dispositivo.

Lecturas mínimas pueden usar la API de Supabase con RLS o vistas con `security_invoker = true` que oculten columnas internas (como el identificador individual del personal frente al estudiante). Envíos, lecturas auditadas del detalle de un caso, respuestas, asignaciones y cambios de estado pasan por operaciones controladas y transaccionales (RPC / funciones restringidas). Si se usa una función `SECURITY DEFINER` o credencial que evita RLS, debe fijar explícitamente `search_path` y verificar actor, institución, pertenencia activa, cuotas y permisos; nunca exponer credenciales privilegiadas al cliente.

## Organización objetivo y estado de implementación

M1 incluye arranque, pantalla de verificación, tema, widgets de marca, plataforma, contratos, modelos, adaptador local y mock solo para pruebas. Las funcionalidades E01–E11 y Supabase del árbol siguiente son objetivo de fases posteriores, no implementaciones existentes. Ver [ADR 0002](decisiones/0002-inicializacion-android.md).

```text
apps/mobile/                  # Proyecto Flutter (Android prioritario)
  lib/
    features/                 # auth, home, reports, help, wellbeing, staff, dev_simulator
    shared/                   # contracts, local, theme, widgets; mock solo para pruebas
  test/                       # Pruebas de widgets, contratos e idempotencia
supabase/migrations/          # Esquema, privilegios y políticas versionados
supabase/functions/           # Solo operaciones externas que necesiten Edge Runtime
tests/                        # Integración de permisos y recorridos críticos de BD
docs/                         # Contexto y decisiones
```

Separar presentación, casos de uso y acceso a datos dentro de cada funcionalidad. No crear paquetes compartidos ni microservicios hasta que exista una necesidad concreta.

## Identidad, pertenencia y dispositivos compartidos

Acceso principal aprobado: cuenta estudiantil por alias, sin exigir nombre civil. ADR 0004 fija PIN de cuenta de 4–6 dígitos, respaldo local SETU-XXXX-XXXX y vinculación ficticia DEMO-NORTE/DEMO-SUR. Las credenciales se derivan con PBKDF2 y salts independientes. Reglas del piloto institucional todavía pendientes. La invitación vincula al centro; no sustituye la credencial de la cuenta. El alias no garantiza anonimato absoluto y no prueba pertenencia escolar. Código de Caso + PIN de 4 dígitos está implementado como acceso complementario limitado a un caso y sus solicitudes; nunca al listado de la cuenta. Solo opera con los datos del mismo teléfono.

Antes del piloto definir invitaciones no enumerables, vigencia, límite de usos, revocación y prevención de abuso. Un código escolar compartido no demuestra pertenencia por sí solo; las invitaciones deben almacenarse como hash (`code_hash`) y validarse en servidor con límite de intentos.

Recuperar acceso y usar teléfonos compartidos presentan riesgos opuestos (perder el seguimiento si se borra la app vs. que otro usuario del teléfono abra `Mis reportes`):
- No diseñar recuperación por nombre civil, correo ni teléfono.
- Evaluar como propuesta complementar la sesión con un código de recibo de alta entropía por reporte o con bloqueo local opcional (PIN ligero / biometría del sistema) antes de mostrar el historial en dispositivos compartidos.

Personal con cuentas individuales; autenticación reforzada para acceso a casos reales. Las pertenencias y roles solo cambian desde operaciones administrativas confiables.

## Modelo conceptual

| Entidad | Datos mínimos y finalidad |
| --- | --- |
| institutions | Identificador, nombre y estado operativo |
| institution_invites | Institución, hash de invitación, vigencia, límite/contador de usos, revocación y creador |
| memberships | Sujeto autenticado, institución, rol, estado; sin autoasignación |
| reports | Institución, sesión creadora, código de referencia, relato, estado, indicador de ruta alternativa (conflicto de interés), marcas de lectura (`student_last_read_at`, `staff_last_read_at`), marca de seguimiento en cierre (`reopen_requested_at`), clave de idempotencia y fechas |
| report_assignments | Institución, reporte, personal autorizado asignado, actor y fecha |
| report_messages | Institución, reporte, rol visible del autor (`student` / `staff`), referencia interna del actor (oculta al estudiante), mensaje visible, clave de idempotencia y fecha |
| case_notes | Institución, reporte, autor del personal y nota interna separada; nunca accesible al estudiante |
| report_events | Institución, reporte, cambios de estado/derivación, motivo cuando aplique y actor sin duplicar relatos |
| help_resources | Territorio, contacto, horarios, fuente, revisión y estado editorial |
| wellbeing_content | Contenido revisado, responsable y versión; sin perfil emocional |
| audit_events | Institución, acción (incluyendo apertura de caso por personal), recurso, actor y fecha; sin texto del caso ni secretos |

Los identificadores son opacos. Para impedir por motor de base de datos cruzar datos entre centros (*cross-tenant*), las tablas dependientes incluyen `institution_id` y usan claves foráneas compuestas (`UNIQUE (id, institution_id)` y `FOREIGN KEY (..., institution_id)`). Además, se aplican límites de longitud de texto y cuotas por ventana de tiempo en servidor. No es todavía un esquema listo para migrar.

## Matriz mínima de autorización y conflicto de interés

| Recurso | Estudiante | Responsable autorizado | Supervisor / Ruta alternativa | Administrador |
| --- | --- | --- | --- | --- |
| Reporte ordinario | Crear propio y leer propio | Leer casos autorizados de su centro | Según protocolo de escalamiento | Sin lectura de contenido por defecto |
| Reporte con conflicto de interés | Crear propio y leer propio | Denegado si está marcado para ruta alternativa | Leer y atender casos derivados por conflicto en su ámbito | Sin lectura de contenido por defecto |
| Respuestas visibles | Leer propias y enviar seguimiento (con cuota e idempotencia) | Leer/escribir en casos autorizados | Leer/escribir en casos de ruta alternativa | Sin acceso por defecto |
| Notas internas | Ninguno | Leer/escribir según asignación | Leer/escribir en casos bajo su supervisión | Sin acceso por defecto |
| Estado/asignación | Solo lectura del estado propio (puede solicitar seguimiento si está cerrado) | Cambiar según protocolo y facultades | Cambiar/reasignar en casos con conflicto | Configuración, no cierre de casos por defecto |
| Roles/pertenencias/invitaciones | Sin edición | Sin autoasignación | Sin autoasignación | Gestionar dentro de su ámbito, sin elevar su propio rol |

Cualquier rol acumulado requiere concesión explícita y auditoría. Personal no asignado: denegado salvo función de recepción autorizada para la bandeja institucional (excluyendo casos marcados con conflicto de interés). La lectura del detalle de un reporte por parte del personal debe quedar registrada en `audit_events`.

## Estados propuestos

`recibido → en_revision → en_acompanamiento → cerrado`. `en_revision → cerrado` requiere motivo. Reapertura `cerrado → en_revision` solo por personal autorizado y con motivo. Si un estudiante envía un mensaje de seguimiento sobre un caso `cerrado`, el caso no cambia de estado automáticamente, pero activa `reopen_requested_at` para destacarlo en la bandeja del personal autorizado. La derivación se registra como evento con seguimiento; no debe cerrar automáticamente un caso. Urgencia es una evaluación humana separada del estado. Registrar transición y actor en una transacción; no permitir al cliente escribir directamente el estado.

## Conectividad y operación

Se aprueba persistencia protegida de casos y datos funcionales de prueba en el teléfono, conservándolos al reiniciar el proceso. Implementado en M1 con AES-GCM-256, clave protegida por flutter_secure_storage y archivo privado obtenido con path_provider; ADR 0004. Escrituras transaccionales serializadas y temporales cifrados. Errores de clave/integridad no borran ni reinicializan el almacén. Los borradores sin guardar siguen siendo temporales y se limpian al descartarlos; las credenciales no deben guardarse en texto plano. Desinstalar o borrar datos puede eliminar los casos locales. Sin Supabase no hay sincronización, entrega a otro teléfono ni respuesta institucional remota. La interfaz debe diferenciar guardado local de envío al centro.

En M1 `FLAG_SECURE` está activo en cada arranque de la actividad. El interruptor confirmado mediante MethodChannel permite pausarlo tras un diálogo y muestra el estado; no persiste la desactivación. El nuevo comportamiento debe validarse físicamente al instalar M1.

Un reintento de reporte o de mensaje reutiliza una clave aleatoria de idempotencia única por sesión y operación: si la operación ya fue registrada previamente, el servidor devuelve de forma transaccional el mismo recibo o confirmación sin duplicar filas ni devolver un error ambiguo al usuario.

TLS en tránsito; verificar protección del almacenamiento y copias con el proveedor. No prometer cifrado de extremo a extremo: el personal autorizado necesita leer el caso. Notificaciones opcionales y genéricas; revisar exposición en pantalla bloqueada antes de habilitarlas.

Entornos de desarrollo, demo y eventual producción separados. Migraciones reproducibles y pruebas de restauración antes del piloto. Definir retención también para copias de seguridad. Presupuesto, región de alojamiento, egreso, disponibilidad y recuperación siguen pendientes.
