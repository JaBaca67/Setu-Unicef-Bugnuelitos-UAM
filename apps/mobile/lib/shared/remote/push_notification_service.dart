import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'setu_remote_gateway.dart';

@pragma('vm:entry-point')
Future<void> setuFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } on Object {
    // En segundo plano el sistema muestra la notificación neutra recibida por FCM.
  }
}

/// Coordina la inicialización de Firebase Cloud Messaging y el registro de tokens
/// hacia Supabase sin exponer datos de casos en el dispositivo.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  String? _currentToken;
  String? _lastSyncedStaffUserId;
  String? _lastSyncedStudentKey;
  SetuRemoteGateway? _gateway;
  VoidCallback? _onForegroundEvent;
  VoidCallback? _onTokenChanged;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    _ => 'android',
  };

  /// Inicializa Firebase y solicita permiso de notificaciones. Es seguro en
  /// entornos de prueba o plataformas sin configuración nativa.
  Future<void> initialize({
    required SetuRemoteGateway gateway,
    VoidCallback? onForegroundEvent,
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
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _tokenRefreshSub = messaging.onRegistered.listen((String newToken) {
        _currentToken = newToken;
        _lastSyncedStaffUserId = null;
        _lastSyncedStudentKey = null;
        _onTokenChanged?.call();
      });
      _foregroundSub = FirebaseMessaging.onMessage.listen((_) {
        _onForegroundEvent?.call();
      });
      await messaging.register();
    } on Object {
      // Sin Google Play Services o en pruebas de widget, la app sigue operando.
    }
  }

  /// Actualiza los callbacks llamados cuando llega un aviso o un nuevo token FCM.
  void setListeners({
    VoidCallback? onForegroundEvent,
    VoidCallback? onTokenChanged,
  }) {
    _onForegroundEvent = onForegroundEvent;
    _onTokenChanged = onTokenChanged;
  }

  /// Registra el token FCM del personal autenticado cuando cambia la sesión o el token.
  Future<void> syncStaff({required bool hasActiveSession}) async {
    final SetuRemoteGateway? gateway = _gateway;
    if (gateway == null) return;
    final String? userId = gateway.currentStaffUserId;
    if (!hasActiveSession || userId == null) {
      final String? previousToken = _currentToken;
      if (_lastSyncedStaffUserId != null && previousToken != null) {
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
    if (token == null || token.isEmpty) return;
    final String cacheKey = '$userId:$token';
    if (_lastSyncedStaffUserId == cacheKey) return;
    try {
      await gateway.registerStaffPushToken(
        fcmToken: token,
        platform: _platform,
      );
      _lastSyncedStaffUserId = cacheKey;
    } on Object {
      // Se reintentará en el siguiente cambio de estado.
    }
  }

  /// Registra el token FCM del estudiante para su caso activo actual.
  Future<void> syncStudentCase({
    required String? caseId,
    required String? capabilityToken,
    required bool active,
  }) async {
    final SetuRemoteGateway? gateway = _gateway;
    if (gateway == null || !active || caseId == null || capabilityToken == null) {
      return;
    }
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
    } on Object {
      // Se reintentará en la siguiente actualización de soporte.
    }
  }

  Future<String?> _ensureToken() async {
    if (_currentToken != null && _currentToken!.isNotEmpty) {
      return _currentToken;
    }
    try {
      await FirebaseMessaging.instance.register();
      return _currentToken;
    } on Object {
      return null;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
  }
}
