# Cureando — Diagramas de flujo para diseño

Estado: propuesta. Estos diagramas describen pantallas y navegación, no estructura de carpetas.

[Abrir versión visual](index.html). Hay imágenes PNG para compartir y SVG para escalar sin perder calidad.

El acceso estudiantil propuesto es por invitación y sesión privada, no por correo/contraseña; recuperación pendiente. El personal usa cuentas asignadas. Ver [contenido de cada pantalla](../pantallas-explicadas.md).

## 1. Acceso y primer ingreso

Propuesta actual: registro por invitación, sin correo ni contraseña del estudiante. Recuperación pendiente.

![Diagrama de flujo](01-acceso.png)

```mermaid
flowchart TD
    start(["Inicio: abrir Cureando"])
    session{"¿Sesión estudiantil · válida?"}
    welcome["E01 · Bienvenida · Qué hace la app y privacidad · Botón: Entrar a mi centro"]
    invite["E02 · Primer ingreso / registro · Campo: invitación del centro · Botón: Comprobar invitación"]
    valid{"¿Invitación válida y · centro disponible?"}
    invalid["Mostrar el problema · Revisar invitación / Reintentar · También puede ir a Ayuda"]
    school["E02 · Confirmar centro · Mostrar nombre encontrado · Botón: Entrar a este centro"]
    recognize{"¿Reconoce el centro · y confirma entrar?"}
    register["Activar acceso privado al centro · Crear sesión sin nombre civil · No es un formulario adicional"]
    home(["E03 · Inicio / Home · Continuar al diagrama 2"])
    help["E09 · Ayuda sin iniciar sesión · Volver a la pantalla anterior"]
    start --> session
    session -->|"No"| welcome
    session -->|"Sí: acceso habitual"| home
    welcome -->|"Entrar"| invite
    welcome -->|"Buscar ayuda"| help
    invite --> valid
    valid -->|"No"| invalid
    invalid -->|"Corregir"| invite
    valid -->|"Sí"| school
    school --> recognize
    recognize -->|"No: otra invitación"| invite
    recognize -->|"Sí"| register
    register --> home
    classDef plain fill:#fff,stroke:#000,color:#000,stroke-width:2px;
    class start,session,welcome,invite,valid,invalid,school,recognize,register,home,help plain;
```

## 2. Distribución de la app del estudiante

Esta es la distribución de pantallas y navegación para diseño; no representa carpetas del código.

![Diagrama de flujo](02-distribucion.png)

```mermaid
flowchart TD
    home(["E03 · Inicio / Home · Centro + privacidad y sesión · Pedir apoyo + accesos principales"])
    choice{"¿Qué quiere hacer?"}
    report["Pedir apoyo · E04 · Contar lo ocurrido · Continuar al diagrama 3"]
    reports["Mis reportes · E07 · Lista propia: referencia, fecha, · estado y respuesta nueva"]
    help["Ayuda · E09 · Recursos locales verificados · Fuente, horario y contacto"]
    care["Cuidarme · E10 · Actividades opcionales · Título y descripción breve"]
    detail["Seguimiento · E08 · Estado + relato + conversación · Enviar mensaje de seguimiento"]
    contact["Contacto externo · Confirmar destino antes de · llamar o abrir un sitio"]
    activity["Actividad · E11 · Instrucciones revisadas · Terminar o salir libremente"]
    back(["Volver a Inicio / cambiar de sección · Barra inferior: Inicio | Mis reportes | Ayuda | Cuidarme"])
    home --> choice
    choice -->|"Reportar"| report
    choice -->|"Consultar"| reports
    choice -->|"Buscar ayuda"| help
    choice -->|"Autocuidado"| care
    report -->|"Al salir del recorrido"| back
    reports -->|"Abrir un reporte"| detail
    help -->|"Elegir recurso"| contact
    care -->|"Elegir actividad"| activity
    detail --> back
    contact --> back
    activity --> back
    classDef plain fill:#fff,stroke:#000,color:#000,stroke-width:2px;
    class home,choice,report,reports,help,care,detail,contact,activity,back plain;
```

## 3. Crear reporte y consultar respuesta

Si el envío no está confirmado, no mostrar éxito. Comprobar o reintentar sin duplicar el caso.

![Diagrama de flujo](03-reporte.png)

```mermaid
flowchart TD
    start(["Desde Inicio: Pedir apoyo"])
    form["E04 · Contar lo ocurrido · Me pasó / Lo presencié + relato · Lugar y momento: opcionales"]
    complete{"¿Completó las opciones · y el relato?"}
    fix["Señalar lo que falta · Sin borrar el texto escrito"]
    review["E05 · Revisar reporte · Resumen + destinatario + horario · Botones: Editar / Enviar reporte"]
    confirm{"¿Confirma enviar?"}
    send["Enviar reporte · Mostrar: Enviando… · Evitar pulsaciones repetidas"]
    received{"¿Recepción confirmada?"}
    retry["Mostrar pendiente / error · Conservar texto en pantalla · Comprobar y reintentar"]
    receipt["E06 · Reporte recibido · Referencia + siguiente paso · Botón: Ver seguimiento"]
    detail["E08 · Estado y conversación · Con respuesta: leer y contestar · Sin respuesta: explicar la espera"]
    finish(["Fin del recorrido · Volver a Mis reportes o Inicio"])
    start --> form
    form --> complete
    complete -->|"No"| fix
    fix -->|"Corregir"| form
    complete -->|"Sí"| review
    review --> confirm
    confirm -->|"No: editar"| form
    confirm -->|"Sí"| send
    send --> received
    received -->|"No / incierto"| retry
    retry -->|"Reintentar"| send
    received -->|"Sí"| receipt
    receipt --> detail
    detail --> finish
    classDef plain fill:#fff,stroke:#000,color:#000,stroke-width:2px;
    class start,form,complete,fix,review,confirm,send,received,retry,receipt,detail,finish plain;
```

## 4. Login y atención del personal

Cuenta asignada por la institución. No hay registro público del personal ni acceso a otros centros.

![Diagrama de flujo](04-personal.png)

```mermaid
flowchart TD
    start(["E01: Acceso del personal"])
    login["R01 · Iniciar sesión · Correo institucional + contraseña · Botón: Iniciar sesión"]
    valid{"¿Acceso validado y · cuenta autorizada?"}
    error["Mostrar error de acceso · Corregir / pedir ayuda al centro"]
    inbox["R02 · Bandeja autorizada · Centro + filtros por estado · Referencia, fecha y mensaje nuevo"]
    cases{"¿Hay un caso que abrir?"}
    empty["Mostrar bandeja vacía · Volver o consultar más tarde"]
    case["R03 · Atender caso · Leer relato y conversación · Responder / registrar atención"]
    answer["Enviar respuesta visible · Actualizar estado con permiso · Notas internas: sección separada"]
    student["E08 · El estudiante consulta · Solo la respuesta visible · Nunca las notas internas"]
    finish(["Fin de la atención actual · Volver a bandeja R02"])
    start --> login
    login --> valid
    valid -->|"No"| error
    error -->|"Reintentar"| login
    valid -->|"Sí"| inbox
    inbox --> cases
    cases -->|"No"| empty
    empty -->|"Volver"| inbox
    cases -->|"Sí"| case
    case --> answer
    answer -->|"Si responde"| student
    answer --> finish
    classDef plain fill:#fff,stroke:#000,color:#000,stroke-width:2px;
    class start,login,valid,error,inbox,cases,empty,case,answer,student,finish plain;
```
