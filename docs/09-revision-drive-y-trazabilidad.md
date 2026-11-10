# Revisión de Drive y trazabilidad

**Corte:** 9 nov 2026. **Método:** listado público de carpetas y exportación de documentos compartidos, sin modificar Drive. El Resumen General consultado indica actualización a las 4:12 p. m. de ese día. Los archivos pueden cambiar después de esta revisión.

Esta revisión sustenta el README, la especificación funcional y el diseño de datos/mesh. No copia identificaciones, correos, conversaciones ajenas al proyecto ni respuestas individuales al repositorio. Las notas automáticas de reuniones pueden contener errores de transcripción; se contrastan con documentos consolidados.

## Cobertura y límites

Se recuperaron **18 archivos de contenido**: dos documentos raíz, nueve minutas/transcripciones, dos documentos de investigación, una hoja de cálculo, dos PDF y dos manuales SVG. Se descargaron además **72 variantes de logo** (36 PNG y 36 SVG); se inspeccionó visualmente el conjunto PNG y se localizaron los SVG equivalentes. El archivo editable `logos.ai` se identificó en el índice, pero no se analizó su estructura de Illustrator. Desarrollo aparecía vacío en el listado público.

Se leyeron los documentos consolidados, las conclusiones de la entrevista, la estructura de las encuestas y los acuerdos/resúmenes de reuniones; se buscaron menciones técnicas y de alcance en sus transcripciones. No se atribuye valor de decisión a conversaciones personales o académicas no relacionadas con SéTú.

El Manual de Marca se extrajo y revisó visualmente en sus 32 páginas mediante una hoja de contacto. El Lean Canvas se revisó como página completa. Los manuales SVG contienen 15 y 12 páginas anidadas: se inspeccionaron por separado porque su composición se superponía al renderizarla con la herramienta utilizada. No se corrigieron los originales de Drive.

El proyecto de [Claude aportado](https://claude.ai/project/01a1b41d-594c-7496-bd53-327489cfccce) **no fue accesible mediante la herramienta web**. Su contenido no se utiliza ni se afirma revisado. El control de Chrome tampoco fue autorizado en esta sesión. La CLI `gdrive` mencionada en AGENTS.md no se encontró en las ubicaciones comprobadas de este entorno; se usó lectura HTTP pública, sin extraer credenciales del navegador.

## Fuentes principales

| ID | Archivo y acceso | Uso y observación |
| --- | --- | --- |
| D01 | [Resumen General y Avance](https://docs.google.com/document/d/1aKKx9jfSYpSilB3DdTapQAnF8TMX6NkWiBDbxQoIf4g/edit) | Alcance consolidado, código doble, tres superficies, mesh, información híbrida y reparto de tareas. Contiene datos de integrantes que no se reproducen. |
| D02 | [Reporte Pautado](https://docs.google.com/document/d/1dChZLsHbp_UAqRDTcwh1KIMmLzqQ_tyqO-V6d0HPYRI/edit) | Aviso mínimo tipo/rol/hora; chat reservado; valoración profesional y ficha. Apartados 2 y 6 aún incompletos en el corte consultado. |
| D03 | [Manual de Marca final](https://drive.google.com/file/d/11vE2_hviWBnT79giw6Y8mgofxUckyae6/view) | 32 páginas; SéTú, colores, tipografías, variantes, protección, usos y aplicaciones. |
| D04 | [Lean Canvas](https://drive.google.com/file/d/18SoTLtoQ6LC4-QTCFR4LhB01OhuZBgC6/view) | Propuesta de valor, segmentos, canales y metas; cifras y financiación necesitan conciliación. |
| D05 | [SeTu_Costos_App](https://docs.google.com/spreadsheets/d/1t4idB2KwksaVkriVMrovDxuk8UW-88fA3H6XVb04cSA/edit) | Tres hojas: costos mensuales, primer año y SROI. Se leyeron valores guardados; no se recalcularon ni actualizaron tarifas del proveedor. |
| D06 | [Manual de despliegue y teléfono puente](https://drive.google.com/file/d/1Y_xOdPk4CRbm9d8X78EVKEACfPp_YwAj/view) | 15 páginas; roles, dos códigos, alerta mínima local, enlace LAN y checklist. Declara pasos técnicos por validar. |
| D07 | [Guía fácil / rural](https://drive.google.com/file/d/1DWzt097dyQHqxZLCLQSTbIhGktKwh9BI/view) | 12 páginas; operación sencilla y registro sin nombres/chat. Su etiqueta rural no amplía la Fase 1 urbana. |
| D08 | [Encuestas de validación](https://docs.google.com/document/d/1I60UYurDleQ7GDf2byZrWbMwl6Oc4j0XqBFqhw9VoRI/edit) | Instrumentos para secundaria y familias de primaria, propuestas de formularios y lógica. No equivale a una base de respuestas ni habilita ejecutar los scripts incluidos. |
| D09 | [Entrevista de validación clínica](https://docs.google.com/document/d/1ZxH6jQLES9XSHnYsZ4QTQ15hn9WLaN0MW5SF4dSzEcU/edit) | Seis audios transcritos, recibidos el 8 nov. Destaca escucha humana, límites claros, seguimiento y herramientas lúdicas sin diagnóstico. No certifica el diseño criptográfico o institucional. |
| D10 | [Carpeta de logos](https://drive.google.com/drive/folders/17HiVXtSEsNpyKB_QzZnBMB_2E_gTije0) | Contiene el editable AI y subcarpetas [PNG](https://drive.google.com/drive/folders/1sRYsWKIQSeFDZpNhC8_umivLZkuOPaOt) y [SVG](https://drive.google.com/drive/folders/16XnURY24OzDCv9UqPX7VS9Bx4QxwfzsZ), 36 variantes de cada formato. |

## Reuniones localizadas

| Fecha | Fuente | Aporte pertinente y vigencia |
| --- | --- | --- |
| 20 oct | [Temáticas y propuesta preliminar](https://docs.google.com/document/d/1EEmXHIKxV9kRi3VumfyxvHjomspmuJ-ixvIlDD-Vp70/edit) | Exploración inicial; no fija arquitectura actual. |
| 21 oct | [Causa–efecto y propuesta híbrida](https://docs.google.com/document/d/1p-f6K_ycynaNZRgG3Ylwja9AVBWqxgt03YaBWnOcUhE/edit) | Plataforma más campaña; hipótesis del problema. |
| 30 oct | [QR y campaña](https://docs.google.com/document/d/1uG0__4k-lkXm6wZ9ygxYxOaruItO9Pdp1PM7qFCR4sM/edit) | Fase urbana, QR/GPS y materiales; stack y colores iniciales superados. |
| 2 nov | [Encuestas y especialistas](https://docs.google.com/document/d/1xXaUuLu-eQYMOIRhQHx-qKA_FEHz30K8o8yjgaOcTt4/edit) | Seguimiento de investigación; gran parte del archivo trata otros asuntos y no se incorpora a la especificación. |
| 4 nov | [Nombre y flujo](https://docs.google.com/document/d/1MToGcNAnrLrM_rGYXuH_BYertGe_KOLNPAFDzE6UP9A/edit) | Selección de marca, diagrama y organización; contrastar con manual final. |
| 5 nov | [Flutter, MINED y reporte](https://docs.google.com/document/d/1aIU82zKWvlUpAW__N-ayW02DqWOru_WKfCNjlpeJ-2Y/edit) | Flutter, chat humano, MINED intermediario, víctima/testigo y tarjetas; chatbot descartado. |
| 8 nov | [Marca, misión y Canvas](https://docs.google.com/document/d/1B0Pgw_xA_Bjf9aGpbVvRvGXl7Ydb5R8ufFsbm0l8510/edit) | Marca final, roles/datos relacionales, QR/GPS, mención de mesh. |
| 8 nov, sesión 2 | [Costos y mascota](https://docs.google.com/document/d/1q-vwMobFCWymUR92AOC7OyKe8SmlxqF1308oqSdlqA4/edit) | Organización de entregables, costos, identidad y mascota. |
| 9 nov, mañana | [Manuales, protocolo e indicadores](https://docs.google.com/document/d/1oJY-CpafZAqDWCqFdpV-ZlAVguUlPqYFazaj4FxkmUM/edit) | Especificación técnica asignada a José Alfredo; tres niveles, estados, manuales y campaña. |

La **décima sesión del 9 nov, 1:33–3:41 p. m.**, no apareció en el primer corte. En la revisión posterior se localizó y leyó su [documento independiente](https://docs.google.com/document/d/1c6E9dED-tzHSSu2ciC-TWYNtGH2fxLXYpq14DAt0Eeg/edit), incluidos sus acuerdos y menciones pertinentes de la transcripción: entrega local cuando falta internet, apartado informativo, acceso presencial inicial, doble código y tratamiento voluntario. Las alianzas MINSA/practicantes aparecen con viabilidad pendiente; no se presentan como convenios confirmados.

## Ampliación con manuales operativos y referencia Nikara

En la revisión posterior del mismo día se localizó [Manuales de uso/despliegue+](https://drive.google.com/drive/folders/1WxN3VZvNzXiitXJD6Jf8oe1Fdz4eiRyW), dentro de Investigación y Campo. Se descargaron y extrajeron cinco PDF: dos de despliegue equivalentes a los SVG ya revisados y tres manuales de uso nuevos. Los tres nuevos manuales se revisaron en texto completo y visualmente mediante sus páginas renderizadas. Se identifican como **versiones de trabajo para validar**, no como protocolos institucionales aprobados.

| ID | Fuente | Regla aportada |
| --- | --- | --- |
| D11 | [Manual de la Mesa de Escucha](https://drive.google.com/file/d/1-uMtjFXaxjJ10gGqRlBIPPmtCsGUEShD/view), 9 páginas | Mesa/estudiante como únicos lectores de chat y relato; chat con internet; ficha mínima; nivel humano; autorizaciones y responsables pendientes. |
| D12 | [Manual del Colegio](https://drive.google.com/file/d/1H3vYtqP63tAwYxJIToyJP8iOVseaWZoU/view), 10 páginas | Cinco pasos; registro de aviso docente por dirección; ruta de llegada y reserva de identidad; “Documentar y enviar al MINED”; contacto familiar condicionado a autorización validada. |
| D13 | [Manual del MINED](https://drive.google.com/file/d/1ZCCoqMQnfdud6HtrnH0NZhqlnV_zFd_m/view), 8 páginas físicas | Sin chat/relato; filtros por nivel/tipo/colegio; exigir, escalar por falta de respuesta y cerrar; plazos e instancia pendientes. La última página está numerada 9 en su pie. |
| D14 | [Guía rural PDF](https://drive.google.com/file/d/1TEZl0T0Uabc91ki9tAdZvDjLUmRa5AWC/view), 12 páginas | Versión PDF del material de despliegue, sin ampliar la Fase 1. |
| D15 | [Despliegue técnico PDF](https://drive.google.com/file/d/19wiXjoOEkp2F2mxH1k7GvEqaOuAoH0uO/view), 15 páginas | Configuración y operación de puente/colegio; tecnología y alcance por validar. |

El usuario aportó `C:\Users\Littl\Downloads\README.md`, del proyecto Nikara. Se leyó como referencia de **organización documental**: presentación, navegación, stack real, carpetas, instalación, comandos, configuración, pruebas y problemas frecuentes. No prueba ninguna capacidad de SéTú; no se copian sus integraciones de IA, mapas, perfiles públicos, credenciales, migraciones o plataformas.

La variante azul oficial `logos-22.svg` se copia sin modificar a `docs/diseno/setu-logo-azul.svg` para la cabecera del README; su origen es [el activo de Drive](https://drive.google.com/file/d/1b1CsZm1Z0LOOJ6CinFyll1FJkE-T30nS/view). El logotipo no implica aval institucional.

### Cambios y tensiones resueltos documentalmente

- Se elimina la posibilidad propuesta de que el supervisor MINED lea chat/relato: D11/D13 lo prohíben. La asignación profesional de escucha es un permiso diferente.
- El chat necesita internet. La decisión offline es entrega de alerta mínima local; autenticación, claves y retorno siguen pendientes de diseño.
- Ficha mínima: tipo, rol, hora y nivel. El nivel no existe hasta valoración humana; el aviso inicial no lo inventa.
- Registro docente: dirección registra el aviso con su actor y origen, sin acceso docente ni autoría estudiantil ficticia. Campos y tratamiento sin chat por cerrar.
- D12 propone contacto familiar bloqueado mientras haya anonimato. D11/D12 dejan aprobadores/datos por definir; requiere validación de protección y no se interpreta como regla legal ya aprobada.
- D13 reserva el estado Escalado a falta de respuesta institucional. La derivación urgente de riesgo se registra como evento independiente; se retira el salto automático propuesto de riesgo a Escalado.
- Cierre habitual: dirección documenta y envía, MINED cierra. El cierre de nivel 1 sin ficha y reapertura quedan abiertos; no se atribuye esa facultad a la mesa por inferencia.
- Nombres de estados: utilizados por el equipo para prototipo, pendientes de ajuste con MINED. No hay plazos institucionales fijados por estos manuales ni permiso para inventarlos.
- D11 describe filtro de vocabulario que bloquea mensajes; su comportamiento requiere validación para no suprimir una revelación. Rutas de violencia sexual, armas y sustancias siguen pendientes y no amplían automáticamente el MVP.

## Hallazgos que cambian la especificación

| Tema | Fuentes y discrepancia | Tratamiento en el repositorio |
| --- | --- | --- |
| Acceso | D01/D06: código público sin cuentas; M1 usa alias + PIN. | Flujo vigente por colegio; código anterior descrito solo como implementación histórica. Continuidad privada de caso pendiente. |
| Entrega offline | D01/D06/D07 describen alerta a dirección antes de sincronizar; MINED es primer intermediario. | Registrar recepción local y central distintas. Destinatario, claves y facultades locales por aprobar. No afirmar supervisión central sin conectividad. |
| Contenido local | D02/D06: tipo, rol y hora, sin relato ni capturas; chat nunca al colegio. | Alerta mínima separada de relato/chat; puente transporta ciphertext. Contrato local pendiente. |
| Geolocalización | D01/D02 proponen QR/GPS como verificación. | Registrar intención, sin afirmar prueba de matrícula. Resolver permisos, acceso remoto y falta de señal; no guardar coordenadas precisas. |
| Anonimato | D07 promete secreto y respuesta; D02 contempla revelación excepcional. No se recoge identidad civil. | Evitar anonimato absoluto y respuesta garantizada. No inventar una identidad oculta; protocolo excepcional pendiente. |
| Protocolo | Seis estados presentados linealmente y tres niveles con desenlaces distintos. | Conservar nombres; proponer ramas de cierre/escalamiento con aprobación humana. Transporte separado. |
| Presupuesto | D04: piloto USD 0 y escalabilidad USD 25/mes. D05: USD 25.93/mes y USD 1,336.16 año 1. | Citar D05 como estimación detallada; mantener conciliación abierta, sin redefinir cifras en Drive. |
| Financiadores | D04 muestra UNICEF y MINED; D01 dice alianza por validar. | Potenciales aliados, sin convenio, financiación o aval confirmados. |
| SROI y metas | D04 incluye objetivos numéricos; D05 calcula retorno con supuestos. | Proyecciones del equipo, no resultados medidos, SLA ni impactos demostrados. |
| Evidencias | D05 presupuesta archivos y D08 pregunta por capturas. | Sin alcance técnico aprobado para adjuntos; no incorporarlos por inferencia al paquete mesh. |
| Público | D07 dice rural; D01 delimita Fase 1 urbana. | No ampliar fase inicial por el título de un material. Primaria necesita validación de comprensión propia. |
| Reconocimientos | D01/D06 proponen certificados por gestión. | Sin rankings públicos ni incentivos por pocos reportes/cierres rápidos. Diseño de métrica pendiente. |
| Marca | PDF inicial local distinto de D03. | Referencia final de 32 páginas y 36 variantes SVG; código de colores anterior pendiente de cambio aprobado. |
| Pitch y evaluación | D01 dice Video Pitch; guía local dice pitch en vivo, tiempos sujetos a confirmación. | Dar prioridad a guía oficial para formato; confirmar cambios con organización. APK es decisión del equipo, no requisito universal de la guía. |
| Calendario | Algunas minutas llaman lunes al 10 nov 2026. | El 10 nov 2026 cae martes. Usar fecha numérica sin perpetuar el día erróneo. |

## Confirmación del espacio informativo y referente Netflix

La revisión dirigida del 9 nov volvió a consultar las diez sesiones inventariadas y el Resumen General. La propuesta explícita se localizó en la sesión de las 13:33 CST, bajo la etiqueta de transcripción **Andrea Juárez**, desde **01:21:40**. Desde **01:23:49** se describe leer mientras se espera al psicólogo o consultar información sin querer recibir atención; desde 01:26:40 se solicita adaptar el referente al móvil. Los acuerdos registran la sección informativa y el enfoque híbrido como aceptados.

El usuario aporta [Wanna Talk About It?](https://www.wannatalkaboutit.com/) y el HTML local de su portada y confirma expresamente que este espacio forma parte de la solución. [docs/14](14-espacio-informativo-y-referente-netflix.md) conserva marcas de tiempo, análisis del referente, límites de atribución y requisitos; [ADR 0009](decisiones/0009-espacio-informativo-confirmado.md) formaliza la confirmación. No se atribuye una identidad de voz con certeza a partir de una nota automática ni se copia la transcripción/HTML al repositorio. La referencia se adopta como patrón editorial, sin importar su catálogo, contactos o rastreadores.

## Verificación técnica externa

Consultada el 9 nov 2026 para fundamentar propuestas, no para alterar decisiones del equipo:

- [Nearby Connections](https://developers.google.com/nearby/connections/overview): conexión de proximidad sin internet, cifrado de enlace y modalidades de payload. No acredita el protocolo de reenvío de SéTú.
- [Estrategias](https://developers.google.com/nearby/connections/strategies): Cluster como candidato de múltiples vecinos; alcance real por medir.
- [Inicio y permisos Android](https://developers.google.com/nearby/connections/android/get-started): permisos y dependencia del SDK de Google Play services.
- [Bluetooth en segundo plano](https://developer.android.com/develop/connectivity/bluetooth/ble/background): límites de proceso, conexión y servicios.
- [Supabase: sesiones anónimas](https://supabase.com/docs/guides/auth/auth-anonymous): alternativa sin formulario de cuenta, con límites de recuperación; no resuelve el primer envío offline por sí sola.
- [Supabase: RLS](https://supabase.com/docs/guides/database/postgres/row-level-security): autorización de datos; requiere políticas y pruebas propias.

La guía DOCX y la rúbrica XLSX oficiales del repositorio se contrastan para evaluación. Esta revisión no valida fuentes legales/clínicas, horarios de ayuda, tarifas actuales, reducción del acoso, alianzas ni capacidades inalámbricas en dispositivos reales.
