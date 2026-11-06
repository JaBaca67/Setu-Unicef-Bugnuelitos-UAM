# Protección de estudiantes y operación

Estado: requisitos de diseño propuestos; no certificación legal, clínica ni institucional.

## Condición para usar casos reales

Una demo usa información ficticia. Un piloto con estudiantes necesita una institución responsable, personal capacitado, protocolo aprobado y revisión local de protección de menores y datos. Estas condiciones forman parte de la capacidad del servicio, no solo de la implementación técnica.

La [Ley n.º 787, disponible en la OEA](https://www.oas.org/es/sla/ddi/docs/N3%20Ley%20de%20Proteccion%20de%20Datos%20Personales.pdf), es una referencia inicial sobre tratamiento de datos en Nicaragua. No se ha comprobado aquí el conjunto de normas aplicables, reformas, interpretación ni su cumplimiento por el proyecto. Revisión local pendiente: edades y representación, base de tratamiento, avisos comprensibles, datos de terceros, deberes de protección, alojamiento internacional y ejercicio de derechos. No asumir que una casilla de consentimiento resuelve estos puntos.

## Protocolo mínimo a acordar

1. Nombrar responsable de recepción, suplente y supervisor con límites de acceso.
2. Establecer horario y tiempos de revisión realistas; no prometer atención continua.
3. Definir evaluación humana de riesgo, derivación y seguimiento, incluida una ruta alternativa si el personal escolar está implicado.
4. Precisar cuándo puede compartirse información, con quién y cómo se registra. No avisar automáticamente a familiares o personas señaladas sin evaluación del riesgo.
5. Definir cómo manejar errores, reportes repetidos, abuso y falta de información sin desacreditar automáticamente al estudiante.
6. Acordar cierre, reapertura, quejas, incidentes de privacidad y retirada de accesos.

La interfaz debe indicar que no es un servicio de emergencias y ofrecer vías locales verificadas de ayuda. No publicar teléfonos, disponibilidad o servicios sin confirmarlos.

## Riesgos y controles previstos

| Riesgo | Control propuesto | Verificación |
| --- | --- | --- |
| Represalias o identificación | Minimización, acceso restringido, notificaciones discretas | Revisar contenido y experiencia con especialistas |
| Filtración entre centros | RLS, privilegios y validación de referencias | Probar lectura/escritura cruzada con dos centros |
| Personal abusivo o implicado | Asignación limitada, auditoría y vía alternativa | Simular conflicto de interés |
| Dispositivo compartido o perdido | Cuenta por alias/PIN, cierre de sesión, persistencia cifrada y aislamiento de casos | Motor probado en M1; validar formularios y comportamiento nativo al instalar M1, sin asumir protección absoluta |
| Suplantación o spam | Ingreso controlado, cuotas en servidor y revisión humana | Probar revocación, abuso y errores sin bloquear ayuda arbitrariamente |
| Expectativa de respuesta inmediata | Horarios y estado claros; responsable suplente | Validar comprensión y simulacro de ausencia |
| Datos en logs o soporte | Telemetría mínima, sin cuerpos ni secretos | Inspeccionar errores, logs y exportaciones |
| Contactos desactualizados | Responsable editorial, verificación y retiro al vencer | Comprobar procedencia y fecha antes de publicar |

## Datos y retención

Para el desarrollo local se aprobó conservar datos funcionales ficticios después de cerrar la app (ADR 0003/0004). M1 implementa archivo AES-GCM-256 y clave protegida por Keystore, PBKDF2 para credenciales y separación entre notas internas y modelos estudiantiles; no autoriza datos reales ni recepción institucional. Borradores descartados siguen siendo temporales, credenciales nunca en texto plano y datos del teléfono fuera de Git. Recuperación de PIN solo con respaldo y datos existentes en el mismo teléfono. Desinstalación, pérdida de clave o borrado de datos pueden impedir recuperar los casos; el respaldo de cuenta no sustituye un backup cifrado. Plazos de retención y derechos para el piloto siguen pendientes.

No solicitar fecha de nacimiento completa, cédula, dirección, GPS o contactos por defecto. El relato libre puede contener datos sensibles incluso sin campos de identidad; advertir con lenguaje amable y permitir revisión antes del envío.

Retención pendiente: acordar plazos por tipo de dato, finalidad, acceso, eliminación, respaldos y excepciones documentadas. No conservar indefinidamente ni borrar automáticamente expedientes sin un protocolo aprobado. Definir cómo una sesión seudónima ejerce derechos sin revelar identidad innecesariamente.

## Autocuidado y lenguaje

Contenido breve y opcional, revisado por personal competente; sin puntuaciones diagnósticas ni promesas terapéuticas. Evitar culpabilizar: reportar es pedir apoyo, no acusar públicamente. No mostrar nombres de personas señaladas en notificaciones o listados generales.

## Lista de preparación del piloto

- [ ] Institución, responsable del tratamiento y responsables de atención identificados.
- [ ] Edades, mecanismo de ingreso y recuperación de sesión validados.
- [ ] Protocolo de protección, riesgo y conflicto de interés aprobado y ensayado.
- [ ] Revisión legal local y avisos para estudiantes completados.
- [ ] Retención, borrado, copias, restauración y respuesta a incidentes definidos.
- [ ] Permisos, aislamiento, autenticación del personal y revocación probados.
- [ ] Directorio y contenidos revisados por responsables identificados.
- [ ] Pruebas de usabilidad y accesibilidad planificadas con participación segura.
- [ ] Costos, soporte, disponibilidad y límites del piloto acordados.

Esta lista no está completada y no constituye una autorización para operar.
