# Protección de estudiantes y operación

**Revisión:** 2026-11-09. Condiciones de diseño y operación por validar; no certificación legal, clínica o institucional. Alcance vigente según ADR 0005.

## Demo y recepción real

La demo solo usa información ficticia. No autoriza recibir casos de menores. Antes de un piloto se necesitan institución responsable, acuerdos de atención, profesionales capacitados, protocolo aprobado y revisión local de protección de menores/datos. La participación académica UAM–UNICEF no acredita aval ni convenio operativo.

La revisión local debe resolver base del tratamiento, información comprensible por edad, representación cuando corresponda, datos de terceros, deberes de protección, alojamiento, derechos y retención. No asumir que una casilla de consentimiento lo resuelve. Las referencias normativas anteriores son antecedentes, no un dictamen actualizado de cumplimiento.

## Responsabilidades por acordar

1. Responsable de recepción, suplencia, mesa profesional, supervisión de practicantes y alcance MINED/colegio.
2. Horarios y tiempos realistas, ausencia del equipo y contingencia sin internet; no prometer atención continua.
3. Valoración humana en tres niveles y procedimiento de derivación, incluida ruta alternativa por conflicto.
4. Información mínima que se comparte, destinatario, facultades offline y registro. No notificar automáticamente a familiares o personas señaladas sin valorar el riesgo.
5. Tratamiento de bromas, repetidos o información insuficiente sin desacreditar ni bloquear automáticamente ayuda.
6. Cierre, reapertura, quejas, incidentes, revocación y retirada de dispositivos/claves.

La interfaz explica que enviar un aviso no garantiza respuesta inmediata. Los recursos de ayuda deben estar verificados antes de presentarlos como disponibles.

## Confidencialidad y acceso

No hay cuentas visibles del estudiante; el código público solo identifica al colegio. Debe aprobarse un acceso privado por caso/sesión que impida lectura entre compañeros, incluso usando el mismo dispositivo. Recuperación, bloqueo local y pérdida siguen pendientes; no reintroducir alias + PIN como decisión vigente.

Dirección y MINED nunca reciben chat ni relato, según los manuales de uso revisados. Mesa y practicantes solo acceden a lo asignado y bajo facultades revisadas; los practicantes no se consideran habilitados por la simple propuesta de alianza. El chat requiere internet. El puente transporta sobres protegidos y no es un lector clínico.

Drive contempla revelación excepcional con doble autorización, registro y aviso al estudiante. No existe una identidad civil oculta en la app. El protocolo debe limitarse a datos ya aportados o contacto voluntario y definir quién autoriza, qué información se comparte y cómo se documenta. No usar GPS como identificación encubierta.

Los manuales proponen bloquear el contacto familiar mientras siga activo el anonimato y registrar acción grupal; aprobadores y datos compartibles siguen por definir. Debe validarse su relación con deberes de protección y contingencias antes de convertirlo en una regla automática. Dirección registra avisos docentes con ese origen sin crear accesos docentes o fingir autoría estudiantil. No adjudicar riesgo por el tipo de alerta sin valoración profesional.

## Datos y conectividad

Minimizar campos y advertir que el relato puede revelar identidades. No exigir nombre civil, carnet, contactos o agenda. La geolocalización de QR se limita a una decisión por resolver; no conservar posición precisa.

Separar alerta mínima, relato/chat, notas, ficha, actuación y respuesta visible. Evitar texto de casos en notificaciones, soporte, analítica y auditoría. Estadísticas con control de grupos pequeños; sin ranking público o incentivos al subregistro/cierre precipitado.

Mesh exige cifrado hasta destinatarios autorizados. Metadatos de tipo/rol/hora también son sensibles. Dispositivos de terceros no leen contenido; consentir retransmitir no los convierte en profesionales ni destinatarios. Evaluar patrones de proximidad, batería, abuso y métricas del SDK elegido.

## Persistencia y retención

M1 almacena datos ficticios en archivo AES-GCM-256 con clave protegida y formato previo por alias. El cifrado no elimina riesgos de acceso en un teléfono desbloqueado ni convierte la demo en servicio real. Borrar datos, perder la clave o desinstalar puede eliminar continuidad. No migrar o subir datos locales automáticamente.

Definir plazos por categoría: cola y copias en retransmisores, acuses, expedientes, notas, actuaciones, auditoría y respaldos. La caducidad de un sobre no cierra el caso. No conservar indefinidamente ni borrar expedientes sin protocolo aprobado. Resolver pérdida de acceso privado y ejercicio de derechos sin exigir identidad innecesaria.

## Contenido informativo y acompañamiento durante la espera

El [espacio Información](14-espacio-informativo-y-referente-netflix.md) es parte confirmada de SéTú. Contenidos adaptados a la etapa escolar requieren revisión profesional/editorial, fuente, vigencia, derechos y alternativa accesible antes de publicarse. Consultar un artículo o video no sustituye la escucha humana, no confirma atención y no determina si una persona necesita una derivación.

No extraer relatos privados para testimonios, habilitar publicación estudiantil o inferir diagnósticos a partir de lecturas. Ayuda territorial y contenido educativo son recursos distintos; los contactos extranjeros del referente no se importan como ayuda local. Videos/proveedores externos y cualquier conservación de consultas requieren revisión de privacidad, sin ID de caso, relatos o seguimiento sensible por defecto.

## Riesgos y comprobaciones

| Riesgo | Control por validar | Evidencia necesaria |
| --- | --- | --- |
| Represalias/identificación | Minimización, separación y notificaciones discretas | Revisión con especialistas y usuarios por edad. |
| Cruce entre colegios o estudiantes | Autorización por recurso y RLS | Integración con dos centros y dos estudiantes del mismo centro. |
| Dirección implicada | Ruta independiente y exclusión de destinatario en conflicto | Simulacro sin aviso identificable al señalado. |
| Teléfono compartido/perdido | Acceso privado protegido y política de recuperación | Pruebas de sesión, borrado y reinicio. |
| Falsa confirmación | Acuses por ámbito y estado incierto | Radio cortada, puente offline y respuesta perdida. |
| Retransmisor hostil | Sobre cifrado, autenticación, cuotas y deduplicación | Alteración, repetición, exceso y acuse falsificado. |
| Atención ausente | Horarios y suplencia institucional | Simulacro operativo y comprensión de límites. |
| Contactos vencidos | Responsable editorial y retiro | Fuente, territorio, fecha y vigencia comprobados. |

Antes de casos reales: aprobar estos puntos, probar operación y restauración, acordar atención de incidentes y conservar evidencia de aceptación institucional. Ninguno se da por cumplido con esta revisión documental.
