# ADR 0018 · Sesión escolar persistente y perfil estudiantil local

- **Estado:** aceptada (13 nov 2026), a pedido del responsable del producto.
- **Ajusta:** ADR 0005 (acceso sin cuentas ni perfiles) y ADR 0015 («Mi pieza» vive mientras la app está abierta).

## Contexto

El acceso escolar E02 validaba un único código en el teléfono (`AULA24`) y lo pedía en cada ingreso; las alertas salían siempre hacia ese centro. «Mi pieza» se perdía al cerrar la app.

## Decisión

- **Dos puertas en la bienvenida.** «Ingreso estudiantil» y «Personal autorizado» (ADR 0019 quitó la línea explicativa bajo cada botón).
- **Código validado en la plataforma.** E02 consulta `resolve_public_school` por el cliente remoto. El catálogo local (`AULA24`, `AULA25`, `AULA26`) se usa solo si la plataforma no pudo responder; si respondió que el código no existe, no se acepta.
- **Sesión escolar en el teléfono.** El colegio confirmado (`id`, `publicCode`, `name`, `municipality`, `department`) se guarda cifrado (`setu_student_session.enc`). Con un colegio guardado, la app abre en `/inicio`. Las alertas usan el código del colegio activo.
- **Perfil local, no cuenta.** «Mi perfil» reúne la pieza, su apodo, el colegio, el nivel y las estadísticas de `LearningProgress`. Sigue sin haber nombre real, correo, foto ni identificador de persona: nada del perfil viaja a la plataforma, salvo la pieza y su apodo cuando el estudiante envía una alerta (`student_piece.displayName`), para que la Mesa de Escucha reconozca la conversación.
- **Niveles.** 50 XP por nivel (Curioso, Explorador, Constructor, Guía, Referente). Es una escala de lectura simple, sin validación pedagógica todavía.
- **Salir del colegio.** Desde el perfil, con confirmación. Borra solo el colegio activo; pieza, racha y XP quedan en el teléfono.

## Consecuencias y pendientes

- **El apodo es texto libre que llega a la Mesa de Escucha.** El campo pide no usar el nombre real, pero la app no puede impedirlo. Queda por validar con el equipo si conviene una lista cerrada de apodos.
- **Teléfonos compartidos.** La sesión persiste entre aperturas: quien use después el mismo teléfono entra al mismo colegio y ve la misma pieza. No expone relato ni chat nuevos, pero el aviso de chat de una alerta anterior sigue en el teléfono como antes.
- **Actualizado por ADR 0019:** la sesión bloquea el regreso a la bienvenida y el cambio de rol, y un QR válido entra sin comprobación de cercanía.
- **Cercanía.** La comprobación sigue usando el punto de referencia de la compilación (`SETU_DEMO_LATITUDE/LONGITUDE`), no las coordenadas del colegio resuelto.
- **Escudo.** Solo el Colegio Centro América tiene escudo empaquetado (`assets/schools/`); su uso debe contar con el visto bueno del colegio antes de una versión pública.
- La conexión real con Supabase de este recorrido no se probó desde un teléfono.
