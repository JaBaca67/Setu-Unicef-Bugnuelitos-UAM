# SéTú — Bloque M1: identidad, protección y persistencia local

> **Aviso (2026-11-09):** partes de este documento quedaron superadas por [ADR 0005](../../docs/decisiones/0005-alineacion-con-decisiones-del-equipo-drive.md): acceso sin cuentas por código del colegio (no alias + PIN), población de 3.º a 11.º grado, tres superficies (alumno, MINED, dirección), envío entre dispositivos con modo sin conexión por red mesh y paleta del Manual de Marca final. Ante conflicto, prevalece ADR 0005.

Aplicación Android 0.2.0+2. M1 implementa la infraestructura de cuentas/casos y una pantalla de verificación de identidad, almacenamiento y privacidad. Los formularios completos E01–E11 y las vistas de atención se integran en fases posteriores: no se presentan como terminados.

## Qué está implementado

- Poppins Regular/Medium/SemiBold/Bold empaquetada con licencia OFL (fuente: repositorio oficial google/fonts, ofl/poppins). No hay descargas de fuentes en ejecución. Fallback del sistema y síntesis tipográfica si falta un peso solicitado.
- `CureandoTheme`, isotipo de tres piezas con las proporciones de docs/06, rompecabezas, flor de 12 pétalos y espiral; nombre e icono Android SéTú.
- Lectura Normal/Grande (+20 %) combinada con el escalado de Android sin limitarlo.
- Canal `dev.cureando.app/screen_security`, `setSecureScreen(bool)` e `isSecureScreenEnabled()`. Protección activa en cada arranque de la actividad, confirmación para desactivarla y estado visible. La preferencia desactivada no se persiste.
- `CureandoGateway`, modelos estudiantiles inmutables sin notas internas ni credenciales, y contrato separado `StaffCureandoGateway`.
- `LocalCureandoGateway`: alias de 3–24 letras/números/guion bajo, PIN numérico de 4–6 dígitos, respaldo `SETU-XXXX-XXXX`, centros ficticios Norte/Sur, interlocutor CCE/Psicología, chips, ruta alternativa, mensajes, solicitudes y estados.
- Código de caso opaco + PIN de 4 dígitos: acceso limitado a ese caso con mensajes y solicitudes, sin acceso al listado de la cuenta. La cuenta propietaria puede emitir/rotar ese PIN mediante `createCaseAccess`; se devuelve una sola vez en memoria y solo se guarda su derivación. No recupera datos desde otro teléfono.
- Cinco fallos de acceso bloquean durante cinco minutos. Contadores persistidos para PIN de cuenta, respaldo y PIN de caso. Acceso fallido no mantiene una sesión previa.
- Idempotencia por actor/operación/`clientRequestId`: misma entrada devuelve la misma referencia; contenido distinto con la misma clave se rechaza. Estado persistido antes de simular resultado incierto.

## Almacenamiento y límites de seguridad

Archivo privado `setu_local_store.enc`, JSON cifrado con AES-GCM-256, nonce nuevo de 96 bits en cada escritura y MAC de 128 bits. Versión autenticada mediante AAD. Clave aleatoria de 256 bits protegida por `flutter_secure_storage` (cifrado respaldado por Android Keystore; no es un PIN guardado como clave del archivo).

PIN, respaldo y PIN de caso se guardan como PBKDF2-HMAC-SHA256, 600 000 iteraciones, salt aleatorio independiente de 128 bits por credencial y separación por finalidad. Derivación fuera del hilo UI en un isolate. El mock de pruebas usa 1 000 iteraciones solo para velocidad; la app real no construye el mock.

Escritura serializada y transaccional: copia de estado → archivo temporal cifrado con flush → renombrado → publicación en memoria. Clave ausente, archivo alterado, versión incompatible o temporal huérfano se informan sin borrar ni reinicializar los casos. Nunca se escribe JSON de casos en claro. Las copias cloud y transferencias Android se excluyen explícitamente para no restaurar datos sin su clave.

Cuenta/casos sobreviven a cerrar y abrir la app; las sesiones de acceso no persisten. Borrar datos o desinstalar puede eliminar archivo y clave. La recuperación por respaldo solo restablece el PIN de una cuenta en el mismo teléfono; no recupera una clave Keystore perdida ni un archivo eliminado.

El cifrado es del archivo completo; la separación entre orientador/estudiante es por autorización y modelos, no por claves independientes para cada rol. Los perfiles de personal allowlisted en `staffForLocalTesting` son herramientas locales de prueba, no autenticación institucional ni permisos de Supabase. La app está limitada a datos ficticios. No hay servidor, notificaciones externas, llamadas, citas confirmadas o envío a centros reales.

Mantener una única instancia propietaria del almacén por proceso y compartirla con sus fachadas. El formato versionado no implementa migraciones arbitrarias: rechaza versiones desconocidas. No subir automáticamente estos datos al futuro backend.

## Herramientas y dependencias

Flutter 3.44.5 stable, Dart 3.12.2; Android SDK 36.1.0, JDK 21 de Android Studio. Dependencias directas de ejecución: `go_router` 18.1.3, `cryptography` 2.9.0, `flutter_secure_storage` 11.2.0 y `path_provider` 2.1.6. Resueltas en `pubspec.lock`. No se actualizó Flutter, Java, licencias ni el PATH global.

Nombre visible SéTú; application ID conservado `dev.cureando.mockup` para actualizar la instalación M0. Namespace Kotlin `dev.cureando.cureando_mobile`. APK debug universal: mínimo API 24, target API 36, arm64-v8a/armeabi-v7a/x86_64.

## Ejecutar, probar y compilar

Desde `apps/mobile/`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

En esta computadora puede usarse `& C:\flutter\bin\flutter.bat --no-version-check` en lugar de `flutter`. Las herramientas no necesitan estar en el PATH global.

APK: `build/app/outputs/flutter-apk/app-debug.apk`, firma debug local, excluido de Git. No publicar este corte como servicio para casos reales.

Para capturas de QA de widgets, con datos ficticios y fuente real:

```powershell
flutter test --dart-define=SETU_CAPTURE_QA=true test/app_test.dart
```

Se generan `build/qa/m1-home.png` y `m1-controls.png`, fuera de Git. No son capturas de un teléfono.

## Verificación M1 — 2026-11-05

- Análisis sin incidencias.
- 18 pruebas unitarias/widgets aprobadas: cifrado, alteraciones de nonce/MAC/ciphertext/versión, clave perdida, temporal huérfano, reapertura, credenciales/salts/recuperación, bloqueo persistente, aislamiento, interlocutor/conflicto, notas internas, no leídos, idempotencia/concurrencia, seguimiento/citas y rollback de disco; además interfaz, canal, contraste y texto Android al 200 % con Grande adicional.
- QA visual de logo, tipografía y controles mediante render de widgets con Poppins real. No certifica toda la app como WCAG AA/AAA.
- `flutter build apk --debug`: correcto, versión 0.2.0+2, 195 230 247 bytes (aprox. 186 MiB; debug universal sin optimización).
- SHA-256: `9D1622EB2797F2D442656C7E3CB36082E12E3327B3E69B517319501A31BE229F`.
- M0 sí fue instalado/verificado previamente. En este corte M1, ADB no detecta un teléfono: instalación, Keystore real y nuevo interruptor en dispositivo quedan pendientes. Los tests de plataforma simulan el canal; no sustituyen la prueba física.

## Instalación USB

Autorizar depuración USB personalmente en el teléfono. Comprobar `adb devices -l`; debe aparecer `device`. Si hay varios, seleccionar el correcto.

```powershell
adb -s <dispositivo> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <dispositivo> shell am start -W -n dev.cureando.mockup/dev.cureando.cureando_mobile.MainActivity
```

ADB local: `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"`. Comprobar almacenamiento listo, botón de interacción, protección activada por defecto, cancelación y confirmación del interruptor, capturas permitidas al pausarlo y protección restaurada tras reiniciar. Nunca guardar identificadores del teléfono o datos locales en commits.
