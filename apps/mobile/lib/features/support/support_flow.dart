import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/local/encrypted_local_store.dart';
import '../../shared/theme/app_theme.dart';

/// Situaciones que el estudiante puede elegir al enviar una alerta. El nivel
/// de alerta lo asigna después una persona profesional, nunca la app.
enum Situation {
  physical('Acoso físico', Icons.back_hand_rounded, Color(0xFFF5B800)),
  verbal('Acoso verbal', Icons.sms_rounded, CureandoTheme.pink),
  social('Acoso social', Icons.group_rounded, CureandoTheme.green),
  cyber('Ciberacoso', Icons.laptop_mac_rounded, CureandoTheme.blue),
  sexual('Violencia sexual', Icons.gpp_maybe_rounded, CureandoTheme.pink),
  talk('Necesito hablar', Icons.favorite_rounded, CureandoTheme.blue);

  const Situation(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum Participation {
  own('Me pasó a mí'),
  witness('Lo vi o supe de alguien');

  const Participation(this.label);
  final String label;
}

/// Entrega de la alerta. «Recibida» es el acuse de la plataforma: no dice
/// nada sobre el avance del caso.
enum AlertDelivery { none, pending, received }

@immutable
class ChatMessage {
  const ChatMessage(this.text, {required this.fromStudent});
  final String text;
  final bool fromStudent;
}

/// Estado del recorrido «Pedir apoyo» (pantallas 1–8).
///
/// DEMOSTRACIÓN: todavía no hay backend ni mesa de escucha conectada. La
/// alerta se guarda cifrada en el teléfono y el acuse de entrega y el aviso
/// de disponibilidad se simulan con temporizadores ([ackDelay], [teamDelay]).
/// Solo deben usarse datos ficticios.
class SupportFlow extends ChangeNotifier {
  SupportFlow({
    Future<LocalStorePersistence> Function()? openStore,
    this.ackDelay = const Duration(seconds: 3),
    this.teamDelay = const Duration(seconds: 8),
  }) : _openStore = openStore ?? _onDevice;

  static const String teamGreeting = 'Hola. Soy parte del equipo de escucha.';
  static const int maxDetails = 1000;

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_support_alert.enc',
        keyName: 'setu.support.master.v1',
      );

  final Future<LocalStorePersistence> Function() _openStore;
  final Duration ackDelay;
  final Duration teamDelay;
  LocalStorePersistence? _store;
  Future<void>? _opening;
  Timer? _timer;
  bool _disposed = false;
  Map<String, Object?>? _alert;
  final List<ChatMessage> _sent = <ChatMessage>[];

  Situation? situation;
  Participation? participation;
  String details = '';

  AlertDelivery _delivery = AlertDelivery.none;
  AlertDelivery get delivery => _delivery;

  bool _chatAvailable = false;
  bool get chatAvailable => _chatAvailable;

  List<ChatMessage> get messages => <ChatMessage>[
    if (_chatAvailable) const ChatMessage(teamGreeting, fromStudent: false),
    ..._sent,
  ];
  bool get studentWrote => _sent.isNotEmpty;

  Future<void> open() =>
      _store != null ? Future<void>.value() : _opening ??= _load();

  Future<void> _load() async {
    try {
      final LocalStorePersistence store =
          await Future<LocalStorePersistence>.sync(_openStore);
      final Map<String, Object?>? data = await store.load();
      if (data != null && data['version'] == 1) {
        _alert = (data['alert'] as Map<Object?, Object?>?)
            ?.cast<String, Object?>();
        _chatAvailable = data['chatAvailable'] == true;
        if (_alert != null) {
          _delivery = data['received'] == true
              ? AlertDelivery.received
              : AlertDelivery.pending;
        }
      }
      _store = store;
      _schedule();
    } on Object {
      // Sin almacén no se puede guardar: [send] lo informa sin falso éxito.
    } finally {
      _opening = null;
      _notify();
    }
  }

  void selectSituation(Situation value) {
    situation = value;
    _notify();
  }

  void selectParticipation(Participation value) {
    participation = value;
    _notify();
  }

  /// Guarda la alerta en el teléfono. Devuelve false si no pudo guardarse.
  Future<bool> send() async {
    final Situation? type = situation;
    final Participation? role = participation;
    if (type == null || role == null) return false;
    await open();
    final LocalStorePersistence? store = _store;
    if (store == null) return false;
    final Map<String, Object?> alert = <String, Object?>{
      'situation': type.name,
      'participation': role.name,
      'details': details.trim(),
    };
    try {
      await store.save(
        _snapshot(alert, received: false, chatAvailable: false),
      );
    } on Object {
      return false;
    }
    _alert = alert;
    _delivery = AlertDelivery.pending;
    _chatAvailable = false;
    _sent.clear();
    situation = null;
    participation = null;
    details = '';
    _schedule();
    _notify();
    return true;
  }

  Map<String, Object?> _snapshot(
    Map<String, Object?>? alert, {
    required bool received,
    bool? chatAvailable,
  }) => <String, Object?>{
    'version': 1,
    'alert': alert,
    'received': received,
    'chatAvailable': chatAvailable ?? _chatAvailable,
  };

  void _schedule() {
    _timer?.cancel();
    if (_disposed) return;
    if (_delivery == AlertDelivery.pending) {
      _timer = Timer(ackDelay, () {
        _delivery = AlertDelivery.received;
        _persist();
        _schedule();
        _notify();
      });
    } else if (_delivery == AlertDelivery.received && !_chatAvailable) {
      _timer = Timer(teamDelay, () {
        _chatAvailable = true;
        _persist();
        _notify();
      });
    }
  }

  void _persist() {
    _store
        ?.save(_snapshot(_alert, received: _delivery == AlertDelivery.received))
        .catchError((Object _) {});
  }

  void sendMessage(String text) {
    final String clean = text.trim();
    if (clean.isEmpty || !_chatAvailable) return;
    _sent.add(ChatMessage(clean, fromStudent: true));
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
