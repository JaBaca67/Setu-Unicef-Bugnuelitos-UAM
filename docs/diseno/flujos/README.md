# Diagramas vigentes de SéTú

**Revisión:** 2026-11-09. Producto según ADR 0005; contratos y transiciones como propuestas de ADR 0006. No son evidencia de implementación. [Especificación técnica](../../../README.md) · [Pantallas](../../08-especificacion-funcional-setu.md) · [Datos y mesh](../../10-flujo-datos-y-red-mesh.md).

Las fuentes Mermaid de esta carpeta son la versión vigente. La entrega local offline conserva la indicación de contrato pendiente; no concede acceso al chat a dirección o puente. Los seis nombres de estado están acordados; las ramas requieren validación del protocolo.

Las imágenes PNG/SVG y los HTML generados antes de esta revisión son históricos y no deben usarse para implementar. El generador Python conserva el modelo anterior y no debe ejecutarse sobre estas fuentes. Su actualización y la regeneración visual requieren aprobación del cambio de código; se solicitó por separado. Los diagramas actuales pueden leerse aquí con un visor Markdown compatible con Mermaid o desde sus archivos `.mmd`.

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
    B -->|"Mi seguimiento"| D["E07 · Solo casos con acceso privado"]
    B -->|"Información"| E["E10 / E11 · Artículos, testimonios y guías"]
    B -->|"Ayuda"| F["E09 · Recursos revisados"]
    C --> G["E06 · Estado real de entrega"]
    D --> H["E08 · Estado del caso y escucha humana"]
    G -->|"Acceso privado autorizado"| H
    E -->|"Volver"| A
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
    A(["Operación recibida centralmente"]) --> B["Aviso mínimo a MINED y dirección autorizada · Sin relato/chat"]
    A --> C["Mesa asignada accede al contenido reservado"]
    C --> D["Profesional inicia escucha humana"]
    D --> E{"¿Nivel valorado por profesional?"}
    E -->|"1 · Acompañamiento"| F["Conversación y cierre autorizado con motivo"]
    E -->|"2 · Convivencia"| G["Emitir ficha mínima · Revisar conflicto y destinatarios"]
    E -->|"3 · Riesgo grave"| H["Derivación humana por protocolo · Escalado"]
    G --> I["Dirección registra actuaciones sobre su ficha"]
    I --> J["MINED supervisa y solicita seguimiento"]
    J --> K{"¿Puede cerrarse según protocolo?"}
    K -->|"Sí"| L["Cierre autorizado con motivo"]
    K -->|"No: falta respuesta o agrava"| H
    H -->|"Seguimiento de derivación"| J
    F --> M(["Estudiante ve respuesta permitida · Sin notas internas"])
    L --> M
    B -.->|"Supervisión no concede acceso clínico"| J
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
    [*] --> Recibido: Recepción central persistida
    Recibido --> En_escucha: Profesional asignado
    Recibido --> Escalado: Riesgo grave valorado
    En_escucha --> Cerrado: Nivel 1 y cierre autorizado
    En_escucha --> Ficha_enviada: Nivel 2 y ficha profesional
    En_escucha --> Escalado: Nivel 3 / ruta aprobada
    Ficha_enviada --> Colegio_actuando: Actuación documentada
    Ficha_enviada --> Escalado: Falta de respuesta / protocolo
    Colegio_actuando --> Escalado: Agravamiento / falta de respuesta
    Colegio_actuando --> Cerrado: Cierre autorizado
    Escalado --> Cerrado: Seguimiento y cierre autorizado
    Cerrado --> En_escucha: Reapertura autorizada con motivo
    note right of Recibido
        Nombres decididos por el equipo.
        Transiciones propuestas: validar protocolo.
        Entrega local y transporte son dimensiones aparte.
    end note
```
