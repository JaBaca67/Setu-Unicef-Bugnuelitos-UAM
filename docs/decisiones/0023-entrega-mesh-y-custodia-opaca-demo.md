# ADR 0023 — Entrega mesh y custodia opaca de demostración

**Fecha:** 2026-11-16. **Estado:** bloque de implementación aprobado expresamente por el usuario; archivos locales, sin aplicar migraciones remotas ni hacer commits/push. Solo datos ficticios.

## Contexto y diagnóstico

`submit_student_alert` ya admite `origin='mesh'`, valida el colegio, guarda capacidades y llama a `private.dispatch_case_to_counselors`. No faltaba una RPC de alta desde cero. Sí faltaban la custodia para puentes sin clave y un directorio de destinatarios. El par demo contenía una semilla de menos de 32 bytes y fallaba al recortarla; además, derivar claves privadas compartidas dentro del APK permitía a terceros descifrar.

Mesh y envío directo también producían fingerprints distintos para el mismo `clientOperationId` por origen, relato y pieza. Las bandejas consultaban casos antes de sincronizar y descartaban avisos parecidos por tipo/hora, aunque podían ser operaciones diferentes. En la prueba de Mesa, el aviso se buscaba sin abrir «Por tomar» y había trabajo asíncrono pendiente al cerrar.

## Decisión implementada localmente

- Cada receptor staff genera X25519 en su dispositivo, por usuario y ámbito escolar. La clave privada permanece en `flutter_secure_storage`; el código público del colegio no permite derivarla. Los pares de prueba son aleatorios por proceso y no aprovisionan dispositivos reales.
- El receptor publica solo la clave pública mediante `register_mesh_recipient`. El servidor exige una membresía activa del ámbito exacto. `list_mesh_recipient_public_keys` devuelve únicamente claves públicas de los destinatarios autorizados; excluye planta/dirección si `involvesStaff=true` y respeta la cobertura externa.
- El estudiante prepara una caché por colegio y por ruta de conflicto mediante HTTPS. `SupportFlow` cifra un sobre por destinatario con X25519, HKDF-SHA256 y AES-GCM-256. Tipo, rol, colegio, operación y verificador van dentro del cifrado; el exterior solo añade el fingerprint de la clave destinataria.
- Un puente genérico guarda/retransmite ciphertext y lo sube a `relay_mesh_envelope` sin descifrar. `mesh_envelope_custody` no es un caso ni implica atención. Solo el dueño vigente de la clave obtiene sus sobres con `list_my_mesh_envelopes`.
- El receptor descifra, llama a `submit_student_alert` y confirma el procesamiento con `complete_mesh_envelope`. Si el propio teléfono del psicólogo recibe Nearby, usa la misma ruta sin necesitar custodia remota previa. La asignación la decide el servidor; el teléfono puente no se convierte en propietario del caso.
- `20261116000012_setu_mesh_delivery.sql` conserva las firmas públicas de alta y restringe las implementaciones anteriores al esquema privado. Un bloqueo transaccional por colegio/operación evita duplicados. Dos proyecciones online/mesh con los mismos campos mínimos, fecha y verificador reciben el mismo recibo; cambios de esos campos se rechazan. Los reintentos de una misma proyección conservan la comprobación de fingerprint original.
- Si mesh llegó primero, el reintento online recupera el caso existente sin sobrescribirlo. El relato/pieza que no viajó por mesh permanece en el teléfono; no se agrega automáticamente al caso. Puede compartirse posteriormente mediante el chat humano autorizado. No se afirma entrega de ese relato por mesh.
- `cases.client_operation_id` permite reconciliar la bandeja por operación exacta. La sincronización precede a la consulta. El nodo reintenta cada 15 segundos mientras está activo y al volver a primer plano; no se implementa un servicio Android de ejecución permanente.
- Los ACK de vecinos solo acreditan custodia. La recepción central se acepta desde HTTPS; no se acepta un `centrallySynced` sin autenticar como prueba del servidor. No existe todavía retorno mesh firmado de recibos centrales al emisor.

## Alternativas y consecuencias

Se descarta compartir claves privadas en el APK y descifrar en cualquier puente. Un único receptor central sin proyección local no cubría la entrega offline acordada. La custodia opaca permite que el receptor profesional esté en otra ubicación, pero necesita conectarse para procesar los sobres; antes de ese procesamiento no existe caso en la bandeja central.

Un primer uso totalmente desconectado sin claves públicas preparadas conserva la solicitud local y no inventa un destinatario. La demo necesita preparar los teléfonos. Rotación, caducidad de cachés, revocación offline, cuotas de custodia, limpieza y resistencia a abuso continúan pendientes para operación real.

## Preparación y verificación de la demo

1. La migración 0012 debe estar aplicada en el entorno de prueba por un bloque separado autorizado. Este trabajo no la aplicó a ningún proyecto remoto.
2. Abrir primero la sesión staff del colegio con internet para publicar su clave. Preparar también un receptor MINED o externo autorizado para las alertas que involucren personal.
3. Después abrir/reabrir la app estudiantil con internet y su colegio confirmado para cachear ambas listas públicas. Si se preparó antes que el receptor, repetir esta apertura.
4. Conceder permisos Nearby y activar radios en los equipos. Mantener la app en primer plano. Un puente con permisos ya concedidos arranca al abrir/reanudar; la pantalla `/prueba-mesh` sigue siendo diagnóstico y muestra claves públicas para copia manual.
5. Desconectar internet del emisor, enviar una alerta ficticia y comprobar «Por tomar» en la Mesa. Con un puente genérico, mantener/reabrir la Mesa online para recuperar custodia; el intervalo de reintento es 15 segundos. Al reconectar el emisor, su reintento obtiene el mismo caso.

Pruebas automatizadas cubren cifrado, dos saltos simulados, persistencia/reintento, puente sin clave, recuperación staff, deduplicación local y rechazo de ACK central falsificado. `supabase/tests/mesh_delivery_test.sql` prepara pruebas transaccionales locales de aislamiento, permisos, custodia, idempotencia y despacho por colegio. Requiere PostgreSQL/Supabase local y no se ha ejecutado en esta sesión. Una simulación no verifica Nearby/Kotlin, dos teléfonos físicos, segundo plano ni despliegue remoto.

Referencias técnicas: [funciones y privilegios Supabase](https://supabase.com/docs/guides/database/functions), [bloqueos transaccionales PostgreSQL](https://www.postgresql.org/docs/current/explicit-locking.html#ADVISORY-LOCKS).

Verificación final desde `apps/mobile`: Flutter analyze sin incidencias (11,0 s), suite completa con 112 pruebas aprobadas (44 s) y `git diff --check` limpio. Se invocó la CLI Flutter desde una copia temporal del SDK porque el original no permite escribir sus cachés en este entorno; no se instalaron dependencias nuevas. No se compiló APK/Kotlin ni se ejecutó la prueba SQL o una prueba entre teléfonos. No se hicieron commits, push ni comandos contra Supabase remoto.
