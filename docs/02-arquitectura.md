# Arquitectura base propuesta

Estado: propuesta, no implementada ni confirmada. Ver [decisión 0001](decisiones/0001-base-propuesta.md).

## Selección inicial

| Capa | Propuesta | Motivo / condición |
| --- | --- | --- |
| App móvil | React Native, Expo, TypeScript | Una base para Android e iOS; confirmar experiencia del equipo |
| Navegación | Expo Router | Organización por rutas sin ubicar reglas de negocio en pantallas |
| Backend | Supabase: Auth y PostgreSQL | Reducir operación inicial y expresar permisos en datos |
| Operaciones sensibles | Funciones de servidor / funciones SQL restringidas | Validar pertenencia, cuotas, envío idempotente y transiciones |
| Datos | PostgreSQL con RLS y privilegios mínimos | Aislar instituciones y sesiones |
| Panel de atención | Vista mínima por rol para demo; web por decidir | Evitar dos productos completos desde el inicio |

No seleccionar todavía bibliotecas adicionales, versiones, proveedores de analítica o planes de pago. React Native y Expo permiten desarrollo multiplataforma según sus [documentaciones](https://docs.expo.dev/tutorial/introduction/). Supabase documenta [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security); habilitarla no reemplaza diseñar y probar políticas.

## Flujo y límites de confianza

App no confiable → autenticación → API/operaciones autorizadas → PostgreSQL con RLS. La identidad y la institución se derivan de la sesión y pertenencias verificadas, no de valores aceptados sin validación desde el dispositivo.

Lecturas mínimas pueden usar la API de Supabase con RLS. Envíos, respuestas, asignaciones y cambios de estado pasan por operaciones controladas y transaccionales. Si se usa una credencial que evita RLS, la función debe verificar explícitamente actor, institución y permisos; nunca exponerla al cliente.

## Organización futura, no creada todavía

```text
apps/mobile/             # Pantallas y funcionalidades móviles
  src/features/         # reports, help, wellbeing, staff
  src/shared/           # UI accesible y utilidades realmente compartidas
supabase/migrations/    # Esquema, privilegios y políticas versionados
supabase/functions/     # Solo operaciones que necesiten servidor
tests/                  # Integración de permisos y recorridos críticos
docs/                   # Contexto y decisiones
```

Separar presentación, casos de uso y acceso a datos dentro de cada funcionalidad. No crear paquetes compartidos ni microservicios hasta que exista una necesidad concreta.

## Identidad y confidencialidad

Se propone una sesión seudónima sin exigir nombre civil al estudiante. El proveedor, operadores y metadatos podrían permitir correlaciones; no es anonimato absoluto. La autenticación anónima de un proveedor tampoco concede por sí sola derecho a entrar a una institución.

Antes del piloto definir invitaciones no enumerables, vigencia, revocación y prevención de abuso. Un código escolar compartido no demuestra pertenencia. Recuperar acceso puede comprometer privacidad: no diseñar recuperación por nombre; validar si se acepta pérdida de acceso tras perder la sesión o se ofrece otro mecanismo seguro.

Personal con cuentas individuales; autenticación reforzada para acceso a casos reales. Las pertenencias y roles solo cambian desde operaciones administrativas confiables.

## Modelo conceptual

| Entidad | Datos mínimos y finalidad |
| --- | --- |
| institutions | Identificador, nombre y estado operativo |
| memberships | Sujeto autenticado, institución, rol, estado; sin autoasignación |
| reports | Institución, sesión creadora, relato, estado, clave de idempotencia, fechas |
| report_assignments | Personal autorizado asignado; actor y fecha |
| report_messages | Reporte, autor y mensaje visible al estudiante y personal autorizado |
| case_notes | Notas internas separadas; nunca accesibles al estudiante |
| report_events | Cambios de estado y actores sin duplicar relatos |
| help_resources | Territorio, contacto, horarios, fuente, revisión y estado editorial |
| wellbeing_content | Contenido revisado, responsable y versión; sin perfil emocional |
| audit_events | Acción, recurso, actor y fecha; sin texto del caso ni secretos |

Los identificadores son opacos. Las referencias entre tablas deben impedir vincular asignaciones, mensajes o pertenencias a instituciones distintas. No es todavía un esquema listo para migrar.

## Matriz mínima de autorización

| Recurso | Estudiante | Responsable autorizado | Administrador |
| --- | --- | --- | --- |
| Reporte | Crear propio y leer propio | Leer casos autorizados de su centro | Sin lectura de contenido por defecto |
| Respuestas visibles | Leer propias y enviar seguimiento limitado | Leer/escribir en casos autorizados | Sin acceso por defecto |
| Notas internas | Ninguno | Leer/escribir según asignación | Sin acceso por defecto |
| Estado/asignación | Solo lectura del estado propio | Cambiar según protocolo y facultades | Configuración, no cierre de casos por defecto |
| Roles/pertenencias | Sin edición | Sin autoasignación | Gestionar dentro de su ámbito, sin elevar su propio rol |

Cualquier rol acumulado requiere concesión explícita y auditoría. Personal no asignado: denegado salvo función de recepción autorizada para la bandeja institucional.

## Estados propuestos

`recibido → en_revision → en_acompanamiento → cerrado`. `en_revision → cerrado` requiere motivo. Reapertura `cerrado → en_revision` solo por personal autorizado y con motivo. La derivación se registra como evento con seguimiento; no debe cerrar automáticamente un caso. Urgencia es una evaluación humana separada del estado. Registrar transición y actor en una transacción; no permitir al cliente escribir directamente el estado.

## Conectividad y operación

Sin persistencia local de relatos por defecto. Conservar solo lo indispensable para autenticación en almacenamiento seguro del sistema, con política de expiración. Un reintento reutiliza una clave aleatoria de idempotencia, única por sesión/operación; crear reporte y recibo en una transacción.

TLS en tránsito; verificar protección del almacenamiento y copias con el proveedor. No prometer cifrado de extremo a extremo: el personal autorizado necesita leer el caso. Notificaciones opcionales y genéricas; revisar exposición en pantalla bloqueada antes de habilitarlas.

Entornos de desarrollo, demo y eventual producción separados. Migraciones reproducibles y pruebas de restauración antes del piloto. Definir retención también para copias de seguridad. Presupuesto, región de alojamiento, egreso, disponibilidad y recuperación siguen pendientes.
