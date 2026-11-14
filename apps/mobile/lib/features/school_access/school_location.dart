import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

const String demoSchoolCode = 'AULA24';
const double demoSchoolRadiusMeters = 150;

String normalizeSchoolCode(String code) {
  final String normalized = code.trim().toUpperCase();
  if (normalized.length == 7 && normalized[4] == '-') {
    return normalized.substring(0, 4) + normalized.substring(5);
  }
  return normalized;
}

/// Código público de un colegio leído de un QR o de un enlace. Acepta el
/// código directo (`AULA26`, `aula-26`), el enlace de la app
/// (`setu://colegio/AULA26`) y cualquier URI con `?code=AULA26`. Devuelve
/// null si la lectura no tiene forma de código de colegio.
String? extractSchoolCode(String raw) {
  final String text = raw.trim();
  String candidate = text;
  final Uri? uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) {
    final String? query = uri.queryParameters['code'];
    if (query != null) {
      candidate = query;
    } else if (uri.scheme.toLowerCase() == 'setu' &&
        uri.host.toLowerCase() == 'colegio' &&
        uri.pathSegments.isNotEmpty) {
      candidate = uri.pathSegments.first;
    } else {
      return null;
    }
  } else if (text.toLowerCase().startsWith('?code=')) {
    candidate = text.substring(6);
  }
  final String code = normalizeSchoolCode(candidate);
  return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code) ? code : null;
}

/// Contenido del QR oficial de un colegio.
String schoolQrLink(String publicCode) => 'setu://colegio/$publicCode';

enum SchoolProximity {
  nearby('La lectura de ubicación coincide con la zona de tu colegio.'),
  simulated(
    'Este resultado es simulado. Podés mostrar el recorrido desde cualquier lugar.',
  ),
  outside('Acercate a tu colegio para intentarlo de nuevo.'),
  imprecise(
    'La lectura de ubicación es imprecisa. Probá de nuevo en un lugar abierto.',
  ),
  notConfigured(
    'Esta compilación necesita un punto de referencia para comprobar la cercanía.',
  ),
  locationDisabled('Activá la ubicación del teléfono y volvé a intentarlo.'),
  permissionDenied('Permití el acceso a la ubicación al volver a intentarlo.'),
  permissionBlocked('Podés permitir la ubicación desde los ajustes de la app.'),
  permissionApproximate(
    'La app tiene acceso a la ubicación aproximada. Podés habilitar la ubicación precisa desde los ajustes.',
  ),
  unavailable(
    'No obtuvimos una lectura actual. Probá de nuevo en un lugar abierto.',
  );

  const SchoolProximity(this.message);

  final String message;

  bool get canContinue => this == nearby || this == simulated;

  String get title => switch (this) {
    nearby => 'Colegio confirmado',
    simulated => 'Cercanía simulada',
    outside => 'Fuera de la zona del colegio',
    _ => 'Cercanía sin confirmar',
  };
}

SchoolProximity classifySchoolDistance({
  required double distanceMeters,
  required double accuracyMeters,
}) {
  if (!distanceMeters.isFinite ||
      distanceMeters < 0 ||
      !accuracyMeters.isFinite ||
      accuracyMeters <= 0 ||
      accuracyMeters > demoSchoolRadiusMeters / 2) {
    return SchoolProximity.imprecise;
  }
  if (distanceMeters + accuracyMeters <= demoSchoolRadiusMeters) {
    return SchoolProximity.nearby;
  }
  if (distanceMeters - accuracyMeters > demoSchoolRadiusMeters) {
    return SchoolProximity.outside;
  }
  return SchoolProximity.imprecise;
}

Future<SchoolProximity> checkSchoolLocation() async {
  // Referencia pública del campus, no datos de ubicación de estudiantes.
  final double? latitude = double.tryParse(
    const String.fromEnvironment(
      'SETU_DEMO_LATITUDE',
      defaultValue: '12.098062',
    ),
  );
  final double? longitude = double.tryParse(
    const String.fromEnvironment(
      'SETU_DEMO_LONGITUDE',
      defaultValue: '-86.2641465',
    ),
  );
  if (latitude == null ||
      !latitude.isFinite ||
      latitude.abs() > 90 ||
      longitude == null ||
      !longitude.isFinite ||
      longitude.abs() > 180) {
    return SchoolProximity.notConfigured;
  }

  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return SchoolProximity.locationDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.deniedForever:
        return SchoolProximity.permissionBlocked;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return SchoolProximity.permissionDenied;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
    }
    if (await Geolocator.getLocationAccuracy() ==
        LocationAccuracyStatus.reduced) {
      return SchoolProximity.permissionApproximate;
    }

    final DateTime startedAt = DateTime.now();
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,
        timeLimit: const Duration(seconds: 25),
      ),
    );
    if (position.timestamp.isBefore(
      startedAt.subtract(const Duration(seconds: 5)),
    )) {
      return SchoolProximity.unavailable;
    }
    return classifySchoolDistance(
      distanceMeters: Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      ),
      accuracyMeters: position.accuracy,
    );
  } on LocationServiceDisabledException {
    return SchoolProximity.locationDisabled;
  } on PermissionDeniedException {
    return SchoolProximity.permissionDenied;
  } on TimeoutException {
    return SchoolProximity.unavailable;
  } on PlatformException {
    return SchoolProximity.unavailable;
  } on MissingPluginException {
    return SchoolProximity.unavailable;
  }
}
