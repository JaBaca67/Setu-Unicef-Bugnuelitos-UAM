# Cureando

Nombre provisional de una aplicación móvil para estudiantes en Nicaragua: reportar situaciones de acoso escolar, pedir apoyo y acceder a recursos de bienestar en un entorno privado y acompañado por personas responsables.

El equipo describe el proyecto como una propuesta que será evaluada en un contexto de UNICEF. No se ha acreditado patrocinio, aprobación institucional ni autorización para usar su marca.

**Estado:** definición inicial, sin aplicación implementada. **Actualizado:** 2026-11-04.

## Documentación

- **[Diagramas de flujo clásicos](docs/diseno/flujos/index.html)**: acceso, distribución de la app, reporte y atención, con decisiones y retornos; [fuentes Mermaid e imágenes](docs/diseno/flujos/README.md).
- **[Empezar aquí para diseñar: pantallas explicadas](docs/diseno/pantallas-explicadas.html)**: documento compartible con cada texto, campo, botón y destino; [versión Markdown](docs/diseno/pantallas-explicadas.md).
- [Visión y alcance](docs/01-producto.md): problema, personas usuarias, MVP y exclusiones.
- [Arquitectura propuesta](docs/02-arquitectura.md): stack, módulos, datos y permisos.
- [Protección y operación](docs/03-proteccion-y-operacion.md): privacidad, atención humana y requisitos para un piloto.
- [Plan y decisiones pendientes](docs/04-plan.md): fases, criterios de entrega y preguntas abiertas.
- [Investigación y skills](docs/05-investigacion-y-skills.md): referencias, límites de la evidencia y herramientas.
- [Guía para diseño en Figma](docs/06-guia-diseno.md): pantallas prioritarias, contenido, estados y prototipo.
- [Mapa visual de pantallas](docs/diseno/flujo-pantallas.html): archivo autónomo para abrir y compartir; [SVG](docs/diseno/flujo-pantallas.svg) para importar a Figma.
- [Registro de decisiones](docs/decisiones/0001-base-propuesta.md).
- [Instrucciones para agentes](AGENTS.md): contexto y forma de trabajar en este repositorio.

## Punto de partida

Propuesta pendiente de confirmar con el equipo: React Native + Expo + TypeScript para móvil y Supabase para autenticación y PostgreSQL. Prioridad inicial de validación en Android; iOS queda sujeto a recursos y requisitos. No hay presupuesto, cronograma, edades objetivo ni institución piloto confirmados.

La primera entrega debe demostrar el recorrido completo con datos ficticios: estudiante envía un reporte, responsable autorizado lo revisa y estudiante consulta una respuesta. No recibir casos reales antes de definir responsables y validar protección de menores y datos.

No hay comandos de instalación o pruebas todavía: se incorporarán cuando exista código y se haya confirmado el stack.
