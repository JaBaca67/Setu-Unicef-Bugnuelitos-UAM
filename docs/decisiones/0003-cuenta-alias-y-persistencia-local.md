# ADR 0003 — Cuenta por alias, seguimiento y persistencia local

- Fecha: 2026-11-05.
- Estado: aceptado; detalles técnicos concretados y aprobados por ADR 0004. M1 implementa contratos y persistencia; pantallas completas pendientes. Las preguntas históricas siguientes se resuelven en ADR 0004.

## Contexto

El usuario solicita una aplicación funcional que pueda probar en su teléfono y conservar los casos. Un adaptador exclusivamente en memoria no cumple esa necesidad. También pide versionar los avances mediante commits incrementales y push.

## Decisiones confirmadas

1. Cuenta estudiantil por alias, sin exigir nombre civil. ADR 0004 reemplazó la propuesta de contraseña por PIN numérico de 4–6 dígitos y código de respaldo local con derivaciones PBKDF2.
2. Permitir solicitudes de seguimiento; no limitar el acceso al caso a solo lectura. ADR 0004 aprobó Código de Caso + PIN de 4 dígitos como acceso complementario limitado a un caso y seguimiento, no equivalente al acceso completo de la cuenta.
3. Persistir localmente los datos funcionales de prueba: cuentas, centros, reportes, mensajes, notas internas separadas, estados y solicitudes. Cerrar/reabrir el proceso no debe eliminarlos. No significa guardar contraseñas en texto plano, logs con relatos o borradores descartados.
4. Adaptador objetivo `LocalCureandoGateway` detrás de `CureandoGateway`; Supabase continúa como backend futuro. Un mock puede servir para pruebas automáticas, no como almacenamiento principal de la app.
5. Identidad visual basada en el logo original y tipografía del manual de marca. No reemplazar el isotipo por uno inventado.
6. Ayuda con información real y fuentes revisadas, sin llamadas ni derivaciones efectivas en el corte local. No atribuir convenios o disponibilidad no verificados.
7. Commits pequeños por avance revisado y comprobado; push al repositorio al cerrar bloques autorizados. La autorización de guardado no autoriza automáticamente nuevas implementaciones.

## Consecuencias y límites

- Datos disponibles solo en el teléfono donde fueron creados; no hay comunicación real entre estudiante y centro hasta conectar un backend.
- La pantalla debe distinguir guardado local de envío institucional. Una respuesta escrita desde el perfil local de orientación no debe atribuirse a un servicio remoto real.
- Borrar los datos de la app o desinstalarla puede eliminar el contenido local; no prometer recuperación o sincronización inexistentes.
- Mantener la separación de cuentas, casos y notas internas también en la capa de datos, no solo en los widgets.
- ADR 0004 aprobó el diseño y paquetes de persistencia, claves, credenciales y respaldo, implementados en M1. La migración futura a Supabase aún requiere diseño propio. No trasladar automáticamente casos a la nube cuando se integre Supabase.
- Seguir usando datos ficticios; un piloto con menores requiere docs/03-proteccion-y-operacion.md.

## Sustitución de propuestas anteriores

Reemplaza la propuesta de sesión exclusivamente anónima como acceso principal, el motor en memoria como aplicación principal y la pérdida de casos al cerrar el proceso. Los diagramas, HTML y fuentes previos son referencias históricas hasta su actualización; prevalecen esta decisión, ADR 0004 y el plan vigente. La versión histórica M0 no incluía cuentas ni persistencia; M1 ya implementa sus contratos y motor local, con formularios pendientes de integrar.
