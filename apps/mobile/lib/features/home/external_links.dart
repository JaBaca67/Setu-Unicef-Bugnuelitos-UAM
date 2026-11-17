import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MethodChannel _links = MethodChannel('dev.cureando.app/links');

/// Android valida HTTPS/destino y abre la fuente en una app externa.
Future<void> openExternalLink(BuildContext context, String url) async {
  try {
    await _links.invokeMethod<void>('open', <String, String>{'url': url});
  } on PlatformException {
    if (context.mounted) _showFailure(context);
  } on MissingPluginException {
    if (context.mounted) _showFailure(context);
  }
}

void _showFailure(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo abrir el enlace. Probá de nuevo con internet.',
        ),
      ),
    );
