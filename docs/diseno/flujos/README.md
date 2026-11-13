# Diagramas vigentes de SéTú

**Revisión:** 2026-11-12. Producto según ADR 0005; contratos y transiciones como propuestas de ADR 0006; navegación estudiantil sin seguimiento de casos según [ADR 0013](../../decisiones/0013-inicio-estudiantil-e03.md) (fuentes `.mmd` 02/08/13 actualizadas; los SVG vigentes `08` y `13` quedan pendientes de regenerar). No son evidencia de implementación. [Especificación técnica](../../../README.md) · [Pantallas](../../08-especificacion-funcional-setu.md) · [Datos y mesh](../../10-flujo-datos-y-red-mesh.md).

Las fuentes Mermaid de esta carpeta son la versión vigente. La entrega local offline conserva la indicación de contrato pendiente; no concede acceso al chat a dirección o puente. Los seis nombres se usan como propuesta de prototipo y necesitan validación institucional. La derivación urgente no fuerza Escalado, que el manual MINED reserva a falta de respuesta. MINED y dirección nunca ven chat/relato; el chat necesita internet.

Las imágenes `01`–`04` PNG/SVG y los HTML generados antes de esta revisión son históricos y no deben usarse para implementar. El generador Python conserva el modelo anterior y no debe ejecutarse sobre estas fuentes; su modificación no forma parte del bloque autorizado. Los **SVG `06` y `08`–`15` son nuevos y vigentes** para esta revisión documental. Los `.mmd` conservan el modelo editable; los DFD SVG ofrecen la notación de almacén abierto y una disposición legible, con entidades/almacenes repetidos por ID. No se instalaron dependencias del producto ni se modificó el generador histórico.

## Accesos por tipo de modelo

| Modelo | Fuente editable | Vista ampliable |
| --- | --- | --- |
| Recorrido de las tres superficies | [08 · Usuarios](08-recorrido-usuarios.mmd) | [SVG vigente](08-recorrido-usuarios.svg) |
| DFD de atención: contexto | [09 · Contexto](09-dfd-contexto.mmd) | [SVG vigente](09-dfd-contexto.svg) |
| DFD de atención: diagrama 0 | [10 · Diagrama 0](10-dfd-diagrama-0.mmd) | [SVG vigente](10-dfd-diagrama-0.svg) |
| DFD de transporte: contexto M0 | [11 · Contexto mesh](11-dfd-mesh-contexto.mmd) | [SVG vigente](11-dfd-mesh-contexto.svg) |
| DFD de transporte: diagrama 0 M1–M5 | [12 · Mesh lógico](12-dfd-mesh-logico.mmd) | [SVG vigente](12-dfd-mesh-logico.svg) |
| Ruta física de transporte y fallos | [06 · Ejecución mesh](06-mesh.mmd) | [SVG vigente](06-mesh.svg) |
| Información: curiosidad, comprensión y espera | [13 · Recorrido informativo](13-flujo-informacion.mmd) | [SVG vigente](13-flujo-informacion.svg) |
| DFD editorial: contexto I0 | [14 · Contexto informativo](14-dfd-informacion-contexto.mmd) | [SVG vigente](14-dfd-informacion-contexto.svg) |
| DFD editorial: diagrama 0 I1–I3 | [15 · Publicación, catálogo y recurso](15-dfd-informacion-logico.mmd) | [SVG vigente](15-dfd-informacion-logico.svg) |

[Diccionario, alcance, balance F01–F14/T01–T10 y método Kendall y Kendall](../../12-modelado-dfd-kendall.md). El flujo `05` de componentes/destinatarios que aparece abajo es una vista de arquitectura; no sustituye los DFD `09`–`12`.

[Información confirmada, referente Netflix y balance editorial C01–C06](../../14-espacio-informativo-y-referente-netflix.md). El catálogo público no consulta expedientes; abrir un recurso durante la espera no cambia el caso o el transporte.

El [README principal](../../../README.md) reúne la especificación técnica; las secciones siguientes conservan los flujos funcionales de detalle.

## Acceso sin cuentas

[Fuente editable](01-acceso.mmd)

```mermaid
flowchart TD
    A(["Abrir SéTú"]) --> B["E01 · Privacidad, ayuda e información"]
    B -->|"Entrar al colegio"| C["E02 · Escanear QR o escribir código público"]
    B -->|"Ayuda o información"| H["E09 / E10 · Sin reportar"]
    C --> D{"¿Configuración escolar validable?"}
    D -->|"No"| X["Explicar error o falta de configuración offline"]
    X -->|"Corregir o reintentar"| C
    X -->|"Consultar recursos"| H
    D -->|"Sí"| E["Confirmar colegio · QR/GPS y alternativas por cerrar"]
    E --> F["Acceso sin cuenta visible · Continuidad privada por caso pendiente"]
    F --> G(["E03 · Inicio"])
```

## Navegación estudiantil

[Fuente editable](02-distribucion.mmd)

```mermaid
flowchart TD
    A(["E03 · Inicio · Colegio activo"]) --> B{"¿Qué necesita hacer?"}
    B -->|"Pedir apoyo"| C["E04 / E05 · Tipo, rol y detalles opcionales"]
    B -->|"Actividades"| ACT["Actividades educativas voluntarias · XP locales"]
    B -->|"Racha semanal"| CAL["Mi racha · Calendario de aprendizaje"]
    B -->|"Información"| E["E10 / E11 · Artículos, videos, testimonios y guías"]
    B -->|"Ayuda"| F["E09 · Recursos revisados"]
    C --> G["E06 · Estado real de entrega"]
    G -->|"Aviso de disponibilidad · sin datos del caso"| H["E08 · Escucha humana por internet"]
    G -->|"Información durante la espera"| E
    H -->|"Información voluntaria"| E
    E -->|"Volver"| R(["Regresar al origen · E03/E06/E08 · Conservar operación y estado"])
    ACT -->|"Volver"| A
    F -->|"Volver"| A
    H -->|"Volver"| A
    G -->|"Pendiente o incierto: comprobar sin duplicar"| G
```

## Solicitud y confirmación de entrega

[Fuente editable](03-reporte.mmd)

```mermaid
flowchart TD
    A(["Pedir apoyo"]) --> B["E04 · Tipo de situación y rol · Detalles opcionales"]
    B --> C["E05 · Revisar contenido, destinatarios y límites"]
    C --> D{"¿Confirma enviar?"}
    D -->|"No: editar"| B
    D -->|"Sí"| E["Crear operación estable · Guardar cola protegida"]
    E --> F{"¿Hay recepción central por internet?"}
    F -->|"Sí"| G["E06 · Servidor recibió · Recibo persistido"]
    F -->|"No o incierto"| H["Intentar mesh si hay configuración y radios"]
    H --> I{"¿Existe acuse auténtico?"}
    I -->|"No"| J["Pendiente / incierto · Conservar y reintentar misma operación"]
    J --> F
    I -->|"Solo custodia o entrega local"| K["Mostrar ámbito local · MINED pendiente"]
    K -->|"Sincronización y retorno central"| G
    I -->|"Central"| G
    G --> L(["E08 · Seguimiento privado · No implica lectura humana"])
```

## Escucha, MINED y dirección

[Fuente editable](04-personal.mmd)

```mermaid
flowchart TD
    T["Dirección registra aviso docente · Sin cuenta docente ni autoría estudiantil"] --> A
    A(["Operación recibida centralmente"]) --> B["Aviso mínimo a MINED y dirección autorizada · Sin relato/chat"]
    A --> C["Mesa asignada accede al contenido reservado"]
    C --> D["Profesional inicia escucha humana por internet"]
    D --> E{"¿Nivel valorado por profesional?"}
    E -->|"1 · Acompañamiento"| F["Se resuelve en chat sin ficha · Facultad de cierre por conciliar"]
    E -->|"2 · Convivencia"| G["Ficha mínima · Tipo, rol, hora y nivel · Revisar conflicto"]
    E -->|"3 · Riesgo grave"| H["Derivación urgente registrada · No fuerza estado Escalado"]
    G --> I["Dirección documenta pasos permitidos · Familia según autorización validada"]
    I --> J["MINED exige respuesta y supervisa"]
    J --> K{"¿Actuación y cierre documentados?"}
    K -->|"Sí"| L["Dirección envía · MINED verifica y cierra"]
    K -->|"No"| N["MINED requiere actuación · Escala por demora según protocolo"]
    N --> J
    H -->|"Seguimiento de derivación"| J
    F --> M(["Estudiante ve respuesta propia · MINED y colegio no ven chat/relato"])
    L --> M
    B -.->|"Supervisión institucional"| J
```

## Flujo de datos y destinatarios

[Fuente editable](05-datos.mmd)

```mermaid
flowchart LR
    A["Estudiante · Acceso privado del caso"] -->|"Tipo, rol y relato opcional"| Q["Preparación de sobres por destinatario"]
    Q -->|"Internet"| S["Recepción autorizada · Persistencia e idempotencia"]
    Q -->|"Ciphertext offline"| R["Retransmisores · Sin contenido legible"]
    R --> P["Puente · Custodia protegida"]
    P -->|"Internet recuperado"| S
    P -.->|"Alerta mínima local cifrada · Contrato pendiente"| D["Dirección · Su centro"]
    S -->|"Tipo, rol y hora"| M["MINED · Ámbito autorizado"]
    S -->|"Tipo, rol y hora"| D
    S -->|"Relato y chat reservados"| E["Mesa de escucha asignada"]
    E -->|"Ficha autorizada · Sin chat"| M
    M -->|"Ficha destinada al centro"| D
    D -->|"Actuaciones documentadas"| S
    E -->|"Respuesta visible permitida"| S
    S -->|"Estado y mensajes propios"| A
    E --> N["Notas internas separadas · Sin acceso estudiantil/escolar"]
```

## Transporte mesh y sincronización

[Fuente editable](06-mesh.mmd)

```mermaid
flowchart TD
    A(["Emisor con configuración y claves auténticas"]) --> B["Operación estable · Sobre cifrado · Cola local"]
    B --> C{"¿Vecino compatible disponible?"}
    C -->|"No"| W["Esperar encuentro · Sin promesa de entrega"]
    W --> C
    C -->|"Sí"| D["Retransmisor valida límites y duplicados · Persiste ciphertext"]
    D --> E["Acuse de custodia · No recepción MINED"]
    D --> F["Reenvío acotado a otro vecino o puente"]
    F --> G["Puente persiste sobre · No descifra relato"]
    G -.-> H["Entrega mínima local a dirección · Contrato y claves pendientes"]
    G --> I{"¿Puente tiene internet?"}
    I -->|"No"| J["Conservar cola protegida · MINED pendiente"]
    J --> I
    I -->|"Sí"| K["Servidor valida emisor, centro e integridad · Un caso por operación"]
    K --> L["Acuse central auténtico · Retorno por ruta disponible"]
    L --> M{"¿Emisor recibió acuse central?"}
    M -->|"No"| N["Resultado incierto · Consultar/reintentar misma operación"]
    N --> K
    M -->|"Sí"| O(["Mostrar recepción central · Limpieza según política"])
```

## Estados del caso

[Fuente editable](07-estados.mmd)

```mermaid
stateDiagram-v2
    state "En escucha" as En_escucha
    state "Ficha enviada" as Ficha_enviada
    state "Colegio actuando" as Colegio_actuando
    [*] --> Recibido: Recepción central y avisos autorizados
    Recibido --> En_escucha: Profesional asignado por internet
    En_escucha --> Cerrado: Nivel 1 sin ficha / facultad por conciliar
    En_escucha --> Ficha_enviada: Mesa emite ficha de nivel 2
    Ficha_enviada --> Colegio_actuando: Dirección registra actuación
    Ficha_enviada --> Escalado: MINED por falta de respuesta
    Colegio_actuando --> Escalado: MINED por falta de respuesta
    Colegio_actuando --> Cerrado: Dirección documenta y envía / MINED cierra
    Escalado --> Cerrado: MINED verifica y cierra
    Cerrado --> En_escucha: Reapertura y facultad por validar
    note right of Recibido
        Nombres de prototipo por validar con MINED.
        Transporte local y central se registran aparte.
        Derivación urgente es evento independiente:
        no espera ni fuerza el estado Escalado.
    end note
```
