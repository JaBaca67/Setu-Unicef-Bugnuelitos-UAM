# Flujo de datos y red mesh de SéTú

**Estado:** especificación propuesta, 2026-11-09. ADR 0005 decide el modo sin internet; este documento concreta opciones técnicas para revisión. No hay red mesh implementada ni autorización para recibir casos reales.

## 1. Datos que viajan

Se separan tres productos de información:

- **Alerta mínima institucional:** tipo de situación, rol de víctima/testigo y hora declarada, más referencia técnica e institución validada. Puede ser visible al MINED y dirección autorizados; no es información pública.
- **Relato y conversación:** contenido reservado al estudiante y mesa de escucha asignada. Ni el colegio ni MINED lo reciben. Los tres manuales de uso precisan que **el chat necesita internet**; mesh transporta la alerta, no una conversación remota.
- **Ficha y actuaciones:** la ficha la prepara el profesional después de valorar y lleva tipo, rol, hora y nivel; sin relato ni capturas. Dirección documenta acciones y envía propuesta de cierre al MINED. No se genera una ficha clínica automáticamente a partir de chips.

La capa de transporte solo necesita sobres cifrados y metadatos mínimos. No descubre el tipo de acoso para decidir una ruta o prioridad. No transporta sesiones Supabase, PIN, claves privadas ni una lista de nombres/dispositivos vecinos persistida.

## 2. Ruta con internet

App → API de recepción → validación y persistencia central → recibo estable. Desde esa recepción se publican proyecciones: aviso mínimo a MINED/dirección y acceso reservado para la escucha. Chat y notas no forman parte de la notificación.

La ficha posterior va del circuito profesional al MINED y al colegio autorizado. Las actuaciones vuelven a supervisión y a una respuesta estudiantil separada. La simultaneidad de avisos significa publicación desde una recepción central; no garantiza que dos pantallas se actualicen al mismo milisegundo.

## 3. Ruta sin internet y ambigüedad pendiente

Drive describe estudiante → celulares → teléfono puente → dirección, seguido de sincronización con MINED al volver internet. Su manual de despliegue restringe la alerta local a tipo, rol y hora y dice que el puente solo retransmite. Se requiere confirmar cómo se conserva esa separación criptográfica.

| Opción por revisar | Qué puede ocurrir offline | Consecuencia |
| --- | --- | --- |
| Sobre solo para receptor central | Puente conserva ciphertext hasta sincronizar | Menor superficie local, pero no permite que dirección lea la alerta antes de internet. No cumple por sí sola toda la ruta local descrita. |
| Alerta mínima local separada | Dirección autenticada descifra solo esa proyección; relato queda reservado | Requiere claves por destinatario y alta confiable de dirección/puente, más conciliación central. Es la opción recomendada para discusión. |
| Ficha local autorizada | Dirección recibe una ficha emitida por un profesional habilitado | Requiere atención y firma profesional offline; no equivale a inferir una ficha automáticamente. Mayor alcance. |

Ninguna opción concede al teléfono de un compañero acceso al contenido. La selección queda pendiente; los diagramas señalan el contrato local como tal. Si el centro está implicado, resolver la ruta alternativa antes de notificarlo.

La entrega mínima local a dirección ya está descrita como comportamiento de producto en la reunión de la tarde y los manuales; lo pendiente es su contrato técnico, destinatarios, autenticación y claves. La opción de solo custodia central se conserva para comparar sus límites, sin sustituir esa decisión de producto por conveniencia de implementación.

## 4. Preparación previa

Para emitir offline de forma segura, el teléfono necesita configuración escolar y claves públicas auténticas. Propuestas: configuración precargada en una demo; o QR firmado validable contra raíz pública confiable. Un QR con un simple código público no suministra por sí solo claves confiables ni autorización de lectura.

Resolver primer uso desconectado, caducidad, rotación y revocación. Una configuración validada antes de perder internet puede estar desactualizada. No descargar una clave ofrecida por cualquier vecino y tratarla como oficial. Nunca incluir claves privadas de recepción central/dirección en el APK estudiantil.

## 5. Sobre de transporte propuesto

Contrato conceptual; formato binario/JSON, algoritmo de sobre y versiones quedan por aprobar. El límite debe incluir cifrado y metadatos, no solo el relato.

| Campo lógico | Visibilidad | Regla propuesta |
| --- | --- | --- |
| Versión | Transporte | Rechazar versiones no soportadas sin descartar el original silenciosamente. |
| ID aleatorio de sobre | Transporte | Deduplicación sin contener identidad o texto del caso. |
| Destino y versión de clave opacos | Transporte | Lo mínimo para entrega; evitar nombrar al estudiante o el problema. |
| Tamaño y vigencia | Transporte | Límites verificables y coherentes; vencimiento no significa atención ni cierre. |
| Payload cifrado y etiqueta de integridad | Solo destinatario | Cifra contenido y autentica los campos que deban permanecer inmutables. |
| Operación y prueba del emisor | Dentro del contenido protegido o mecanismo aprobado | Permite autorizar/idempotencia central sin usar la identidad del puente. |
| Límite de saltos y presupuesto de reenvío | Transporte local | Reducir bucles y consumo. No confiar solo en un contador modificable por vecinos. |

Si hay dos destinatarios, el diseño puede usar sobres separados o claves de contenido envueltas por destinatario, pero **el relato no se cifra para dirección**. No se selecciona un esquema criptográfico artesanal: elegir un mecanismo revisado y compatible, con revisión técnica antes de código.

AES-GCM-256 de M1 protege un archivo local; no es un protocolo de intercambio de claves. El cifrado de Nearby protege el enlace entre vecinos, pero el sobre debe seguir protegido después de que un vecino termine ese enlace.

## 6. Ciclo de almacenamiento y reenvío

1. Emisor prepara operación y sobre, guarda en cola cifrada y conserva acceso privado/clave propia.
2. Descubre vecinos compatibles, autentica la sesión de transporte según el SDK y negocia versiones/límites. No se aceptan emparejamientos como prueba de rol institucional.
3. Intercambia identificadores o inventarios acotados para evitar repetir todos los sobres; los propios inventarios también pueden revelar patrones y deben minimizarse.
4. Receptor valida tamaño/formato/vigencia y cuotas antes de almacenar. Persistencia atómica protegida antes del acuse de custodia.
5. Receptor reenvía solo a vecinos aptos, con caché de vistos y presupuesto de copias. El emisor no borra su única copia porque un vecino diga que la tiene.
6. Puente persiste y entrega al canal local autorizado si existe; registra confirmación local distinta de la custodia.
7. Con internet, reintenta subir con la misma operación; servidor valida y devuelve un recibo central persistido.
8. Recibo auténtico vuelve al emisor por una ruta disponible; limpieza según política de retención y confirmaciones, nunca por una promesa de entrega.

La red propuesta es oportunista: los teléfonos pueden moverse y las rutas cambiar. No se inventa un protocolo de enrutamiento ni se garantiza red mallada permanente por usar Cluster.

## 7. Estados de transporte y mensajes de interfaz

| Estado lógico propuesto | Qué demuestra | Texto posible |
| --- | --- | --- |
| Preparado localmente | Escritura protegida propia | “Guardado en este teléfono. Aún no se ha confirmado la entrega.” |
| Pendiente de vecino | No hay ruta próxima disponible | “Sin conexión disponible. Conservamos tu aviso para reintentar.” |
| En transferencia | Intento activo | “Intentando enviar tu aviso.” |
| Custodia intermedia | Otro dispositivo guardó ciphertext | “Tu aviso sigue en camino; falta confirmar recepción.” |
| Recibido por puente | Puente guardó el sobre | “Llegó al teléfono puente. Aún falta confirmar recepción central.” |
| Recibido localmente por dirección | Receptor institucional local confirmó | “Dirección recibió el aviso mínimo; la sincronización con MINED está pendiente.” |
| Recibido centralmente | Servidor persistió la operación | “La plataforma recibió tu aviso.” |
| Resultado incierto | Falló el retorno del acuse | “Aún no podemos confirmar. Puedes comprobar y reintentar sin duplicarlo.” |
| Vencido / requiere intervención | Se agotó la política acordada | “No pudimos confirmar la entrega. Revisa otras opciones de apoyo.” |

Son textos propuestos para validar por edad. No se dice “te están atendiendo” por recibir un paquete. Si el emisor no recibe el acuse local/central, no muestra esa confirmación por inferencia. `Recibido` del caso y recepción de transporte no se almacenan como el mismo dato.

## 8. Acuses y ruta de retorno

| Acuse | Emisor legítimo | Qué permite afirmar |
| --- | --- | --- |
| Custodia | Vecino o puente que almacenó | Existe otra copia; no asegura llegada final. |
| Entrega local | Receptor institucional local autenticado | Llegó la alerta mínima al receptor local; no llegó aún necesariamente al MINED. |
| Recepción central | Servidor autorizado | Operación persistida de forma única; no acredita lectura humana. |
| Actuación/lectura | Circuito autorizado de aplicación | Acontecimiento institucional distinto del transporte. |

La demo debe fijar qué equipo puede emitir cada acuse y cómo se verifica. IDs y firmas no deben revelar claves o capacidades privadas. Un intermediario malicioso no puede fabricar recepción central aceptable. El retorno mesh requiere su propia cola, caducidad y deduplicación; puede fallar aunque la alerta haya llegado.

## 9. Reintentos, duplicados y concurrencia

- Reintentar la misma operación con el mismo identificador y contenido autenticado, cualquiera que sea la ruta.
- Desduplicar en cola por sobre y en servidor por operación/emisor verificado. Dos sobres de una operación no crean dos casos.
- Misma operación con contenido distinto: rechazar conflicto; no sobrescribir el caso previo.
- Persistir caso y recibo en una transacción. Si se pierde la respuesta, devolver el mismo recibo al reintentar.
- Reintentos con espera creciente, variación aleatoria y límites; cifras de intervalos, TTL, copias y tamaño por definir con medición física.
- Dirección puede registrar una actuación offline solo bajo un contrato aprobado. La sincronización agrega eventos y verifica versión; no permite al puente imponer estado, nivel o propietario.
- Al vencer un sobre, no cerrar el caso ni borrar otras copias por inferencia. La política de limpieza y avisos debe aprobarse y probarse.

## 10. Puente y panel local

El puente se plantea fijo, con alimentación y configuración del centro, más responsable y suplente. Su pérdida o apagado no debe borrar las colas de los emisores. Custodia cifrada puede incluir contenido opaco aunque el manual diga “no guarda chat”: eso debe explicarse como ausencia de chat legible y acceso clínico, no como imposibilidad de conservar bytes cifrados.

Si dirección usa computadora sin internet, necesita un cliente ya disponible y un canal LAN autenticado y protegido, o una vista nativa en un dispositivo autorizado. Compartir Wi-Fi no acredita identidad institucional. Cloudflare Pages o un panel cloud no garantizan disponibilidad offline. Definir descubrimiento, confianza del servidor local, credenciales, acceso desde otros dispositivos y conciliación antes de implementarlo. No abrir un servidor HTTP anónimo de relatos en la red del colegio.

## 11. Restricciones y prueba de tecnología

[Nearby Connections](https://developers.google.com/nearby/connections/overview) ofrece transferencia cercana sin internet. [Cluster](https://developers.google.com/nearby/connections/strategies) es candidato para varios vecinos. No se ha elegido plugin Flutter ni se ha probado que los teléfonos objetivo sean compatibles.

Evaluar Google Play services, [permisos por versión](https://developers.google.com/nearby/connections/android/get-started), descubrimiento simultáneo, reinicio, radios, fallos y [trabajo en segundo plano](https://developer.android.com/develop/connectivity/bluetooth/ble/background). La documentación de Google también describe métricas de uso recogidas por su SDK: evaluarlas antes de seleccionar transporte para menores.

No fijar alcance, número máximo de vecinos, duración de batería o entrega con app cerrada sin evidencia. El TTL no puede depender ingenuamente del reloj no confiable de un estudiante. Definir tolerancias, tiempo de recepción y validación de caducidad contra configuración confiable.

## 12. Pruebas necesarias y demostración

| Prueba | Resultado verificable |
| --- | --- |
| Camino directo | App y puente transfieren offline; recibos diferenciados. Es una prueba inicial, no dos saltos. |
| Dos saltos | A alcanza B, B alcanza C; A no puede entregar directamente a C. Capturar evidencia técnica sin cuerpos ni IDs personales. |
| Custodia y reinicio | B confirma solo tras persistir; reinicia, recupera el sobre y reenvía sin pérdida. |
| Duplicados | A/B u otras rutas entregan simultáneamente; un caso y mismo recibo central. |
| Paquete alterado | Se rechaza integridad/formato sin revelar contenido. |
| Reenvío hostil | Bucles, exceso de copias, sobre grande, vencido y cuotas no agotan dispositivo. |
| Puente sin internet | Recibe sobre; no inventa recepción MINED. Entrega local solo con receptor autenticado. |
| Retorno perdido | Caso central recibido, emisor sin acuse; consulta/reintento resuelve incertidumbre sin duplicar. |
| Identidad | El puente no se convierte en dueño del caso ni consulta el relato al subirlo. |
| Separación | Dirección descifra solo la proyección mínima permitida; nunca relato/chat. |
| Fallos físicos | Bluetooth/Wi-Fi apagado, permisos denegados, batería, pantalla apagada y proceso terminado. |

Guion propuesto de 120 segundos: mostrar aviso ficticio sin internet, paso A→B→puente, recepción local mínima si está aprobada, restaurar conectividad, recepción MINED, acción autorizada y seguimiento del estudiante. Equipos aprovisionados y radios revisados antes de la demo. El número de equipos depende de si puente y panel comparten hardware; no afirmar dos saltos con dos teléfonos.

Si solo se logra guardar localmente, conectar directamente al puente o simular un tramo, describir exactamente ese resultado. No presentar una secuencia animada o un conmutador de roles como entrega inalámbrica real.
