import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tipos visuales de alertas inferiores unificadas bajo la identidad SéTú.
enum SetuAlertKind { info, success, warning, error }

/// Construye un `SnackBar` flotante coherente con la paleta y bordes de SéTú.
SnackBar buildSetuBottomAlertSnackBar({
  required String message,
  SetuAlertKind kind = SetuAlertKind.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final (Color bg, Color border, Color iconColor, IconData icon) =
      switch (kind) {
        SetuAlertKind.success => (
          CureandoTheme.greenSoft,
          const Color(0xFF4ADE80),
          const Color(0xFF008F30),
          Icons.check_circle_rounded,
        ),
        SetuAlertKind.warning => (
          CureandoTheme.yellowSoft,
          const Color(0xFFE5C100),
          const Color(0xFF9A6700),
          Icons.warning_amber_rounded,
        ),
        SetuAlertKind.error => (
          CureandoTheme.pinkSoft,
          const Color(0xFFF472B6),
          const Color(0xFFB80069),
          Icons.error_outline_rounded,
        ),
        SetuAlertKind.info => (
          CureandoTheme.blueSoft,
          const Color(0xFFA5C1EF),
          CureandoTheme.blue,
          Icons.info_rounded,
        ),
      };

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    duration: duration,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    backgroundColor: bg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: border, width: 1.5),
    ),
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: CureandoTheme.ink,
            ),
          ),
        ),
      ],
    ),
    action: actionLabel == null || onAction == null
        ? null
        : SnackBarAction(
            label: actionLabel,
            textColor: CureandoTheme.blue,
            onPressed: onAction,
          ),
  );
}

/// Muestra la alerta inferior unificada de SéTú usando el `BuildContext`.
void showSetuBottomAlert(
  BuildContext context,
  String message, {
  SetuAlertKind kind = SetuAlertKind.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  showSetuBottomAlertOnMessenger(
    messenger,
    message,
    kind: kind,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

/// Muestra la alerta inferior unificada sobre un `ScaffoldMessengerState` ya
/// capturado (por ejemplo tras navegar con `context.go`).
void showSetuBottomAlertOnMessenger(
  ScaffoldMessengerState? messenger,
  String message, {
  SetuAlertKind kind = SetuAlertKind.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      buildSetuBottomAlertSnackBar(
        message: message,
        kind: kind,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ),
    );
}
