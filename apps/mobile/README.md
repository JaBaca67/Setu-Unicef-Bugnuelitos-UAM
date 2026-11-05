# Cureando Demo — M0

Base Android para comprobar el entorno, no recepción de reportes reales. Muestra un aviso de datos ficticios y un botón que confirma que la interfaz responde. No implementa todavía E01–E09, autenticación, backend ni almacenamiento de relatos.

## Entorno de referencia

- Flutter 3.44.5 stable, Dart 3.12.2.
- Android SDK 36.1.0; Java 21 incluido en Android Studio.
- `go_router` 18.1.3 (dependencia directa de ejecución), `flutter_lints` 6.0.0 y pruebas del SDK Flutter. Versiones resueltas en `pubspec.lock`.
- Nombre Android: **Cureando Demo**. Application ID: `dev.cureando.mockup`.
- APK con mínimo Android 7.0 (API 24), target API 36 y arquitecturas `arm64-v8a`, `armeabi-v7a`, `x86_64`.

No se actualizó el SDK Flutter existente. Las herramientas no están en el PATH de la terminal de esta sesión; pueden invocarse por su ruta completa, sin cambiar el PATH global.

## Ejecutar y verificar

Desde `apps/mobile/`, con Flutter disponible en el PATH:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

En esta computadora, el equivalente es `& C:\flutter\bin\flutter.bat --no-version-check analyze`, cambiando `analyze` por `test` o `build apk --debug` según la tarea.

Salida del APK: `build/app/outputs/flutter-apk/app-debug.apk`. Es una compilación de desarrollo con firma debug local, no una publicación ni firma de producción. El APK y las rutas locales del SDK no se versionan en Git.

## Instalar en teléfono por USB

1. Conectar un teléfono desbloqueado con cable de datos, activar depuración USB y aceptar personalmente la autorización de esta computadora.
2. Comprobar `adb devices -l`: debe aparecer como `device`, no `unauthorized` ni `offline`.
3. Si hay varios dispositivos, seleccionar explícitamente el teléfono con `adb -s <dispositivo> ...`.
4. Instalar: `adb -s <dispositivo> install -r build/app/outputs/flutter-apk/app-debug.apk`.
5. Abrir **Cureando Demo** y tocar **Comprobar funcionamiento**. Debe aparecer “¡Listo! La interfaz responde correctamente.”

ADB local: `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices -l`.

`FLAG_SECURE` se configura en toda la actividad Android: el sistema puede bloquear capturas y ocultar el contenido en recientes. Esto no garantiza protección absoluta en todos los dispositivos. Su comportamiento debe probarse en el teléfono; las pruebas de widgets no validan flags nativos.

## Estado de verificación

Verificación del 2026-11-05:

- `flutter analyze`: sin incidencias.
- `flutter test`: 2 pruebas aprobadas (aviso de demo/interacción y pantalla de 320 × 568 con texto al 200 %, sin desbordamiento).
- `flutter build apk --debug`: correcta, salida `build/app/outputs/flutter-apk/app-debug.apk`, 155 254 011 bytes (aprox. 148 MiB). Es un APK debug con tres arquitecturas, no una entrega optimizada.
- `aapt dump badging`: nombre, application ID, versión 0.1.0+1, mínimo API 24, target API 36 y arquitecturas verificados en el APK.
- SHA-256 de este APK: `5602F7CF019E00D59E63CB23D1B45108050F1A1D74DF8DB386C838E31E0DF056`.
- Teléfono: ADB todavía no detecta un dispositivo autorizado; instalación y prueba física pendientes.

No interpretar compilación o pruebas de widgets como instalación verificada en teléfono. `flutter doctor -v` detectó licencias Android pendientes y una advertencia de versiones XML de herramientas SDK; no bloquearon esta compilación. No se aceptaron licencias ni se actualizaron herramientas. `FLAG_SECURE` está implementado y compilado; su efecto físico sigue pendiente de comprobar.

## Límites de esta fase

Material 3 y tema claro provisional. La interacción local usa `setState`; `ChangeNotifier` está aprobado para controladores cuando sean necesarios. La ruta `/` usa `go_router`. No se han creado controladores, contratos o carpetas vacías de funcionalidades por anticipado.

La dirección del siguiente desarrollo está aprobada: cuenta por alias, solicitudes de seguimiento y datos locales persistentes; ver [ADR 0003](../../docs/decisiones/0003-cuenta-alias-y-persistencia-local.md). Todavía no están implementados. Archivos, credenciales y paquetes del bloque concreto necesitan propuesta previa. La identidad gráfica del manual todavía no se ha aplicado al tema provisional.
