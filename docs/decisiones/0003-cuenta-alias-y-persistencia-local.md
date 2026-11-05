# ADR 0003 — Cuenta por alias, seguimiento y persistencia local

- Fecha: 2026-11-05.
- Estado: decisiones de producto aceptadas por el usuario; implementación pendiente de propuesta técnica.

## Contexto

El usuario solicita una aplicación funcional que pueda probar en su teléfono y conservar los casos. Un adaptador exclusivamente en memoria no cumple esa necesidad. También pide versionar los avances mediante commits incrementales y push.

## Decisiones confirmadas

1. Cuenta estudiantil por alias, sin exigir nombre civil. La contraseña fue propuesta junto al alias; sus reglas, recuperación, alcance y protección todavía deben concretarse antes de implementar.
2. Permitir solicitudes de seguimiento; no limitar el acceso al caso a solo lectura. El detalle de cómo conviven la cuenta y Código de Caso + PIN debe aprobarse: no asumir que ambos son credenciales equivalentes.
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
- Persistencia protegida, gestión de claves, credenciales, respaldo, esquema, paquetes y migración futura requieren diseño y aprobación antes de implementarse. No trasladar automáticamente casos a la nube cuando se integre Supabase.
- Seguir usando datos ficticios; un piloto con menores requiere docs/03-proteccion-y-operacion.md.

## Sustitución de propuestas anteriores

Reemplaza la propuesta de sesión exclusivamente anónima como acceso principal, el motor en memoria como aplicación principal y la pérdida de casos al cerrar el proceso. Los diagramas, HTML y fuentes previos son referencias históricas hasta su actualización; prevalecen esta decisión y el plan vigente. El APK M0 existente conserva su comportamiento documentado: no implementa aún cuentas ni persistencia.
