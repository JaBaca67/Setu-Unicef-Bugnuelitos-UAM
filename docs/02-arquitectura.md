# Arquitectura de SéTú

**Revisión:** 2026-11-09. Producto según ADR 0005 y Drive; contratos siguientes **propuestos**, pendientes de aprobación antes de implementar. README describe el estado real de M1. No hay backend ni RLS implementados.

## Componentes y confianza

El cliente Flutter no es una autoridad: puede ser modificado, perderse o compartir dispositivo. El servidor valida pertenencia, actor, cuotas, contenido y transiciones. PostgreSQL aplica privilegios y RLS por recurso. Operaciones sensibles pasan por funciones transaccionales controladas; si una función evita RLS, debe verificar explícitamente el actor y ámbito, limitar privilegios y fijar un `search_path` seguro.

Estudiante → API autorizada → datos de caso y proyecciones por destinatario. Alternativa offline: estudiante → retransmisores → puente → servidor. El puente es portador y no autor del reporte. Las fronteras de confidencialidad se mantienen cuando el transporte cambia.

Flutter/Dart y Supabase/PostgreSQL son decisiones confirmadas. `go_router`, `ChangeNotifier` para controladores posteriores y almacenamiento local corresponden al corte aprobado M0/M1. La tecnología de paneles, SDK de proximidad, biblioteca criptográfica del sobre y API definitiva requieren aprobación. No se fijan versiones nuevas en esta revisión.

## Acceso sin cuentas y autorización privada

### Código público de colegio

QR/código identifica el contexto escolar. No es contraseña, prueba de matrícula, clave de cifrado ni autorización para leer expedientes. El servidor obtiene el centro efectivo de una configuración validada y no acepta un `institution_id` arbitrario enviado por el cliente como prueba de pertenencia.

Una configuración escolar offline debería contener identificador, versión, caducidad, claves públicas de destinatarios y firma verificable contra una raíz confiable. Es una propuesta: el QR público simple de Drive no contiene por sí solo esos mecanismos. Revocación reciente no puede comprobarse sin conectividad; hay que definir el riesgo y el estado mostrado.

Geolocalización al QR es intención de producto; faltan condiciones de uso, alternativa y minimización. Validar cercanía no equivale a verificar matrícula. No guardar coordenadas precisas ni bloquear contenidos informativos por rechazar permisos.

### Propiedad y continuidad del caso

| Alternativa propuesta | Ventaja | Límite que debe resolverse |
| --- | --- | --- |
| Sesión técnica seudónima, sin formulario visible | Permite aislar datos mediante sujeto autenticado | Alta inicial necesita servidor; borrar datos o salir puede perder continuidad. |
| Capacidad privada de alta entropía por caso | Puede generarse antes de tener internet; lectura limitada al caso | Respaldo, pérdida, revocación y custodia en equipos compartidos. |
| Combinación | Vincula operación offline con sesión posterior | Mayor complejidad de prueba de posesión y recuperación. |

[Supabase documenta sesiones anónimas](https://supabase.com/docs/guides/auth/auth-anonymous) que funcionan como sujetos autenticados sin pedir correo o contraseña. No son el rol público `anon` y no resuelven automáticamente el ingreso offline ni la recuperación. Son una alternativa, no una selección aprobada.

La propuesta preferible para estudiar el primer envío offline es una capacidad privada o clave de dispositivo/caso y prueba de posesión al registrar la operación. La capacidad no viaja con el sobre reenviado; no se entrega al puente ni se deriva del código escolar. El protocolo concreto, respaldo y bloqueo local quedan abiertos. No se reutiliza el PIN corto M1 como autorización remota sin rediseño.

La sesión se guarda protegida. Bloqueo local opcional no es crear una cuenta por alias; no debe incorporarse como obligación de producto sin acuerdo. La consulta desde otro teléfono y recuperación tras desinstalar no se prometen.

### Dirección, MINED y mesa de escucha

Drive decide código privado para dirección y enlace, pero no define formato, entrega o recuperación. Propuesta: canjearlo mediante un alta confiable por una sesión restringida y revocable; nunca usar el código público ni guardar el privado en claro. Para casos reales se necesitan actores atribuibles, autenticación apropiada y auditoría individual. El acceso MINED/mesa y la supervisión de practicantes requieren diseño propio.

La función técnica de puente usa una credencial de dispositivo limitada a transportar. No obtiene credenciales de dirección ni poderes clínicos. Si comparte teléfono con una vista institucional, los contextos y secretos se separan.

## Modelo de datos conceptual propuesto

No define tablas definitivas ni autoriza migraciones.

| Entidad lógica | Finalidad y mínimos |
| --- | --- |
| Institución | ID opaco, nombre, municipio, estado y configuración vigente. |
| Acceso institucional | Verificador de código privado o alta, vigencia, revocación y registro de emisión; sin secreto en claro. |
| Actor y permiso institucional | Sujeto, función, ámbito, asignación y estado, administrados por vía confiable. |
| Acceso privado de caso | Verificador de capacidad o clave pública y su relación con el caso; sin capacidad reutilizable en logs. |
| Caso | ID, institución validada, referencia opaca, tipo, rol, estado, nivel humano opcional y fechas. |
| Contenido reservado | Relato opcional; separado de la alerta mínima y de proyecciones institucionales. |
| Mensaje de escucha | Caso, autor interno, rol visible, texto, operación idempotente y fechas. |
| Nota interna | Caso, profesional autorizado y nota; sin incluirla en vistas estudiantiles o escolares. |
| Asignación | Caso, actor o equipo autorizado, ámbito, inicio/fin y motivo de cambio. |
| Ficha de actuación | Caso, versión, autor profesional, destinatarios, datos mínimos y fecha de emisión. |
| Actuación escolar | Ficha, responsable autorizado, acción, fecha y evidencia documental de actuación permitida. |
| Evento del caso | Estado anterior/nuevo, nivel o derivación, actor, motivo y fecha; no duplicar relato. |
| Operación recibida | Identificador del emisor/operación, huella autenticada, resultado persistido y recibo estable. |
| Sobre y acuse | ID de transporte, destino opaco, versión, vigencia y confirmación de custodia/central; sin credenciales del estudiante. |
| Recurso editorial | Texto, territorio, responsable, fuente, revisión, vigencia y disponibilidad offline. |
| Auditoría | Actor, acción, recurso, ámbito y resultado; sin cuerpos ni secretos. |

En datos dependientes usar referencias que impidan enlazar un caso de A con una ficha de B, además de RLS. Una alternativa es incluir `institution_id` en claves compuestas y sus referencias. IDs opacos y verificación de relaciones en servidor; no confiar en filtros de pantalla. Reglas de retención, cifrado de campos, región, copias y eliminación deben cerrarse antes de un piloto.

## Matriz de autorización propuesta

| Recurso | Estudiante | Mesa de escucha | MINED supervisor | Dirección/enlace | Retransmisor/puente |
| --- | --- | --- | --- | --- | --- |
| Crear reporte | Propio y válido | No suplanta al estudiante | No suplanta al estudiante | No suplanta al estudiante | Solo entrega sobre ajeno |
| Alerta mínima | Propia | Caso asignado | Ámbito autorizado | Su centro, salvo restricción por conflicto | Solo ciphertext |
| Relato/chat | Propio | Casos asignados | Denegado por defecto; función excepcional por definir | Denegado | Denegado |
| Nota interna | Denegado | Según asignación | Solo concesión específica justificada | Denegado | Denegado |
| Ficha emitida | Solo resumen visible autorizado | Crear/versionar según facultad | Leer y gestionar en ámbito | Leer la destinada a su centro | Solo transporte cifrado |
| Actuación escolar | Resumen visible separado | Leer lo necesario | Leer/supervisar | Registrar sobre ficha autorizada | Sin acceso |
| Estado/nivel | Lectura visible; no edición | Según facultad humana | Según facultad y protocolo | Registrar actuación; no asignar nivel clínico ni cerrar globalmente por sí solo | Sin acceso |
| Agregados | Sin listado de casos ajenos | Según necesidad | Ámbito autorizado | Su centro, con control de grupos pequeños | Sin acceso |
| Roles y claves | No | Sin autoasignación | Administración solo si se concede aparte | Sin autoasignación | Sin autoasignación |

Los roles acumulados requieren concesión explícita; no asumir que MINED equivale a acceso clínico universal. Personal no asignado: denegado salvo función de recepción expresamente aprobada. Lecturas de contenido y cambios sensibles se auditan sin copiarlo.

### Conflicto de interés

Si el relato implica a dirección o personal del centro, la vía alternativa evita notificar a la persona implicada o entregarle una ficha identificable. Resolver qué aviso mínimo puede omitirse o diferirse y quién autoriza la excepción antes del piloto. La regla general de aviso simultáneo no puede convertirse en exposición automática al señalado. El formulario puede proponer una indicación opcional de conflicto; no se presenta como nueva decisión ya aprobada.

## Operaciones lógicas propuestas

| Operación | Validación y resultado |
| --- | --- |
| Validar contexto escolar | Configuración vigente, firma si opera offline y estado conocido; no concede lectura de casos. |
| Recibir sobre | Versión, tamaño, integridad, destino, prueba del emisor, institución, vigencia, cuotas e idempotencia. |
| Consultar recibo | Prueba privada del solicitante; devuelve resultado de su operación sin enumerar otros casos. |
| Abrir caso | Posesión de acceso privado o actor autorizado y asignación; proyección mínima y auditoría. |
| Enviar mensaje | Autor, caso, longitud/cuota y operación; no mezclar con nota interna. |
| Valorar nivel | Profesional autorizado; nivel permitido y registro de evaluación humana. |
| Emitir ficha | Autor, contenido mínimo, destinatario y conflicto; nueva versión auditable. |
| Registrar actuación | Dirección/enlace autorizado sobre ficha propia; validación y control de concurrencia. |
| Cambiar estado | Actor, transición, versión anterior y motivo en una transacción. |
| Revelación excepcional | Protocolo, motivo, dos autorizaciones distintas, alcance y aviso; no genera identidad inexistente. |

No son endpoints implementados. RPC, función de servidor o API directa con RLS se eligen según la operación. No exponer credenciales privilegiadas, secretos de descifrado institucional ni `service_role` en ningún cliente.

## Estados y transiciones propuestas

Los nombres provienen de Drive; las transiciones siguientes resuelven las ramas necesarias y **requieren validación del protocolo**.

| Desde | Hacia | Condición propuesta |
| --- | --- | --- |
| Sin recepción central | Recibido | Persistencia central válida y recibo emitido; recepción local se registra aparte. |
| Recibido | En escucha | Profesional asignado inicia atención; no por abrir un retransmisor. |
| Recibido o En escucha | Escalado | Valoración humana de riesgo grave o ruta especial aprobada; no esperar ficha escolar. |
| En escucha | Cerrado | Acompañamiento nivel 1 concluido con motivo y posibilidad de seguimiento. |
| En escucha | Ficha enviada | Profesional emite ficha de nivel 2 a destinatarios autorizados. |
| Ficha enviada | Colegio actuando | Actuación escolar documentada, validada y vinculada a la ficha. |
| Ficha enviada o Colegio actuando | Escalado | Falta de respuesta o situación agravada, según plazo/protocolo acordado; sin sanción automática. |
| Colegio actuando o Escalado | Cerrado | Responsable con facultad verifica cierre y registra motivo; derivar no equivale a cerrar. |
| Cerrado | En escucha | Reapertura autorizada con motivo; el mensaje del estudiante solo solicita revisión. |

Nivel de riesgo, transporte y estado son dimensiones separadas. El backend debe rechazar saltos no permitidos aunque el cliente muestre el botón. No asumir orden total de acontecimientos offline: distinguir hora declarada, recepción local y recepción central.

## Concurrencia y sincronización

El caso tiene una versión de concurrencia. Cambios con versión antigua se rechazan o requieren revisión; no usar última escritura gana para transiciones, notas o fichas. Actuaciones offline se suben como eventos con operación idempotente y origen/fecha local; el servidor valida sin reescribir silenciosamente su estado autoritativo.

Varias rutas pueden entregar el mismo sobre. Unicidad por operación/emisor autenticado, persistencia transaccional y recibo repetible. El puente no recibe permiso para consultar el caso por haberlo entregado. La retransmisión no puede reemplazar propietario ni institución.

## Persistencia actual y adaptación

M1 implementa archivo local AES-GCM-256, clave protegida con `flutter_secure_storage`, ruta privada mediante `path_provider`, escrituras serializadas y errores de integridad sin reinicialización destructiva. Alias/PIN y cuatro estados pertenecen al formato anterior.

Reutilizar el almacén exige diseñar cola, separación de secretos, cuotas y versión de formato. No convertir automáticamente cuentas locales en identidades remotas ni subir casos almacenados. Borrar app/datos puede perder clave y acceso. La prueba física de M1 sigue pendiente en la bitácora existente.

## Pruebas necesarias

Integración con al menos dos instituciones y dos estudiantes del mismo centro: lectura/escritura cruzadas, alteración de IDs, filtrado de columnas, sesión caducada, roles revocados, asignaciones y conflicto. Probar recepción paralela, misma operación con contenido distinto, acuse perdido y transición concurrente. La autorización de la entrega local debe probarse también sin servidor.

[Docs/10](10-flujo-datos-y-red-mesh.md) define las pruebas de radio, colas, sobres, custodia, caducidad y retorno de acuses. Nada de esto se certifica con las pruebas locales M1.
