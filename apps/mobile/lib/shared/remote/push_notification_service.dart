import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'setu_remote_gateway.dart';

typedef ForegroundPushCallback = void Function(String? title, String? body);

/// Estado visible del registro push del personal en este teléfono. No guarda
/// el token ni datos del caso; solo el resultado del último intento.
enum StaffPushStatus {
  unknown,
  registering,
  registered,
  noSession,
  noToken,
  failed,
}

@pragma('vm:entry-point')
Future<void> setuFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp();
  } on Object {
    // En segundo plano el sistema muestra la notificación neutra recibida por FCM.
  }
}

/// Coordina la inicialización de Firebase Cloud Messaging y el registro de tokens
/// hacia Supabase sin exponer datos de casos en el dispositivo.
class PushNotificationService {
  @visibleForTesting
  PushNotificationService.forTesting({
    required SetuRemoteGateway gateway,
    required Future<String?> Function() fetchToken,
  }) : this._(gateway: gateway, fetchToken: fetchToken);

  PushNotificationService._({
    this._gateway,
    Future<String?> Function()? fetchToken,
  }) : _fetchTokenOverride = fetchToken;

  static final PushNotificationService instance = PushNotificationService._();

  final Future<String?> Function()? _fetchTokenOverride;
  bool _initialized = false;
  String? _currentToken;
  String? _lastSyncedStaffUserId;
  String? _lastSyncedStudentKey;
  SetuRemoteGateway? _gateway;
  ForegroundPushCallback? _onForegroundEvent;
  VoidCallback? _onTokenChanged;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Resultado del último registro del personal, para mostrarlo en el perfil.
  final ValueNotifier<StaffPushStatus> staffStatus =
      ValueNotifier<StaffPushStatus>(StaffPushStatus.unknown);

  /// Tipo del último error de registro (sin mensajes ni datos sensibles).
  String? lastStaffErrorType;

  String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    _ => 'android',
  };

  /// Inicializa Firebase y solicita permiso de notificaciones. Es seguro en
  /// entornos de prueba o plataformas sin configuración nativa.
  Future<void> initialize({
    required SetuRemoteGateway gateway,
    ForegroundPushCallback? onForegroundEvent,
  }) async {
    _gateway = gateway;
    _onForegroundEvent = onForegroundEvent;
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        setuFirebaseMessagingBackgroundHandler,
      );
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      // `push-dispatch` envía vía FCM HTTP v1 usando `message.token` (sin modo FID
      // en el manifiesto), por eso obtenemos el token FCM de registro estándar.
      // ignore: deprecated_member_use
      _tokenRefreshSub = messaging.onTokenRefresh.listen((String newToken) {
        if (newToken.isEmpty) return;
        _currentToken = newToken;
        _lastSyncedStaffUserId = null;
        _lastSyncedStudentKey = null;
        _onTokenChanged?.call();
      });
      _foregroundSub = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        final RemoteNotification? note = message.notification;
        _onForegroundEvent?.call(note?.title, note?.body);
      });
      await _refreshToken();
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('SéTú push: inicialización omitida (${error.runtimeType}).');
      }
    }
  }

  /// Actualiza los callbacks llamados cuando llega un aviso o un nuevo token FCM.
  void setListeners({
    ForegroundPushCallback? onForegroundEvent,
    VoidCallback? onTokenChanged,
  }) {
    _onForegroundEvent = onForegroundEvent;
    _onTokenChanged = onTokenChanged;
  }

  /// Notifica manualmente una rotación o recuperación de token en pruebas.
  @visibleForTesting
  void handleTokenRefresh(String newToken) {
    if (newToken.isEmpty) return;
    _currentToken = newToken;
    _lastSyncedStaffUserId = null;
    _lastSyncedStudentKey = null;
    _onTokenChanged?.call();
  }

  /// Da de baja el token del personal autenticado antes de cerrar sesión.
  Future<void> unregisterStaff() async {
    final SetuRemoteGateway? gateway = _gateway;
    _lastSyncedStaffUserId = null;
    if (gateway == null || gateway.currentStaffUserId == null) return;
    final String? token = _currentToken ?? await _ensureToken();
    if (token == null || token.isEmpty) return;
    try {
      await gateway.unregisterStaffPushToken(fcmToken: token);
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          'SéTú push: no se pudo retirar token de personal (${error.runtimeType}).',
        );
      }
    }
  }

  /// Fuerza el registro del token FCM del personal en este teléfono: vuelve a
  /// pedir el token a Firebase, ignora la caché y devuelve el resultado.
  Future<StaffPushStatus> registerStaffNow() async {
    final SetuRemoteGateway? gateway = _gateway;
    if (gateway == null || gateway.currentStaffUserId == null) {
      staffStatus.value = StaffPushStatus.noSession;
      return staffStatus.value;
    }
    staffStatus.value = StaffPushStatus.registering;
    if (_fetchTokenOverride == null && Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } on Object catch (error) {
        lastStaffErrorType = error.runtimeType.toString();
      }
    }
    _lastSyncedStaffUserId = null;
    final String? token = await _refreshToken();
    if (token == null || token.isEmpty) {
      staffStatus.value = StaffPushStatus.noToken;
      return staffStatus.value;
    }
    try {
      await gateway.registerStaffPushToken(
        fcmToken: token,
        platform: _platform,
      );
      _lastSyncedStaffUserId = '${gateway.currentStaffUserId}:$token';
      lastStaffErrorType = null;
      staffStatus.value = StaffPushStatus.registered;
    } on Object catch (error) {
      lastStaffErrorType = error.runtimeType.toString();
      staffStatus.value = StaffPushStatus.failed;
    }
    return staffStatus.value;
  }

  /// Registra el token FCM del personal autenticado cuando cambia la sesión o el token.
  Future<void> syncStaff({required bool hasActiveSession}) async {
    final SetuRemoteGateway? gateway = _gateway;
    if (gateway == null) return;
    final String? userId = gateway.currentStaffUserId;
    if (!hasActiveSession || userId == null) {
      final String? previousToken = _currentToken;
      if (_lastSyncedStaffUserId != null &&
          previousToken != null &&
          userId != null) {
        _lastSyncedStaffUserId = null;
        try {
          await gateway.unregisterStaffPushToken(fcmToken: previousToken);
        } on Object {
          // Mejor esfuerzo al cerrar sesión.
        }
      } else {
        _lastSyncedStaffUserId = null;
      }
      return;
    }

    final String? token = await _ensureToken();
    if (token == null || token.isEmpty) {
      staffStatus.value = StaffPushStatus.noToken;
      return;
    }
    final String cacheKey = '$userId:$token';
    if (_lastSyncedStaffUserId == cacheKey) return;
    try {
      await gateway.registerStaffPushToken(
        fcmToken: token,
        platform: _platform,
      );
      _lastSyncedStaffUserId = cacheKey;
      lastStaffErrorType = null;
      staffStatus.value = StaffPushStatus.registered;
    } on Object catch (error) {
      lastStaffErrorType = error.runtimeType.toString();
      staffStatus.value = StaffPushStatus.failed;
      if (kDebugMode) {
        debugPrint(
          'SéTú push: fallo al sincronizar personal (${error.runtimeType}).',
        );
      }
    }
  }

  /// Registra el token FCM del estudiante para su caso activo actual.
  Future<void> syncStudentCase({
    required String? caseId,
    required String? capabilityToken,
    required bool active,
  }) async {
    final SetuRemoteGateway? gateway = _gateway;
    if (!active || caseId == null || capabilityToken == null) {
      _lastSyncedStudentKey = null;
      return;
    }
    if (gateway == null) return;
    final String? token = await _ensureToken();
    if (token == null || token.isEmpty) return;
    final String cacheKey = '$caseId:$token';
    if (_lastSyncedStudentKey == cacheKey) return;
    try {
      await gateway.registerStudentPushToken(
        caseId: caseId,
        capabilityToken: capabilityToken,
        fcmToken: token,
        platform: _platform,
      );
      _lastSyncedStudentKey = cacheKey;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          'SéTú push: fallo al sincronizar estudiante (${error.runtimeType}).',
        );
      }
    }
  }

  Future<String?> _refreshToken() async {
    if (_fetchTokenOverride == null && Firebase.apps.isEmpty) {
      return _currentToken;
    }
    try {
      final String? token = _fetchTokenOverride != null
          ? await _fetchTokenOverride()
          // ignore: deprecated_member_use
          : await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        return token;
      }
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          'SéTú push: no se pudo obtener token FCM (${error.runtimeType}).',
        );
      }
    }
    return _currentToken;
  }

  Future<String?> _ensureToken() async {
    if (_currentToken != null && _currentToken!.isNotEmpty) {
      return _currentToken;
    }
    return _refreshToken();
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
  }
}
