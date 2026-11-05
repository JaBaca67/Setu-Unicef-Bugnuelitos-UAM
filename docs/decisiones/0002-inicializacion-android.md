# ADR 0002 — Inicialización Android de M0

- Fecha: 2026-11-05.
- Estado: aceptado por aprobación explícita del usuario en esta sesión.

## Alcance autorizado

Crear la base Flutter, verificar análisis y pruebas, compilar un APK debug e instalarlo por USB si aparece un teléfono autorizado. M0 no implementa E01–E09, contratos, simulador ni backend. Las siguientes fases conservan su compuerta de aprobación.

## Decisiones

- Proyecto Dart `cureando_mobile` en `apps/mobile/`, solo plataforma Android por ahora.
- Nombre visible `Cureando Demo`, application ID provisional `dev.cureando.mockup`. El namespace Kotlin generado es `dev.cureando.cureando_mobile`; es independiente del application ID.
- Navegación declarativa con `go_router`, única dependencia externa directa de ejecución. La versión compatible resuelta es 18.1.3 y se registra en `pubspec.lock`.
- `ChangeNotifier` nativo para controladores posteriores. El botón de M0 usa estado efímero de widget; no crear un controlador sin necesidad.
- Material 3, tema claro provisional de verde sobrio, tipografía del sistema y contenido adaptable a texto ampliado. No se afirma aplicar todavía el manual de identidad que el usuario añadió.
- `FLAG_SECURE` en toda la actividad Android desde M0; se sacrifica la captura normal de pantallas en el dispositivo. No habilitar excepciones sin una decisión posterior.
- APK debug con firma local de desarrollo. No publicar en tiendas ni crear una firma de producción en esta fase.
- Sin persistencia de relatos ni datos personales; la pantalla no ofrece recepción de casos reales.

## Entorno encontrado

Flutter 3.44.5 stable y Dart 3.12.2 instalados; Android SDK 36.1.0 y JDK 21 de Android Studio. No se actualizó Flutter ni se cambió el PATH global. `flutter doctor -v` informa licencias Android pendientes; comprobar su efecto sobre la compilación antes de afirmar que el entorno está completamente listo.

## Validación

El resultado final de análisis, pruebas, compilación e instalación se registra en `apps/mobile/README.md`. Una compilación exitosa no equivale a prueba en teléfono; reportar ambas por separado. Sin capturas de reportes reales ni datos de dispositivos en archivos versionados.
