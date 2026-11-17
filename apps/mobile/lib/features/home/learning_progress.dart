import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/local/encrypted_local_store.dart';

/// Civil dates use UTC only as a calendar coordinate, so a day is always one
/// step even when the device observes daylight saving time.
DateTime calendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

class LearningProgress extends ChangeNotifier {
  LearningProgress({
    Future<LocalStorePersistence> Function()? openStore,
    DateTime Function()? now,
  }) : _openStore = openStore ?? _onDevice,
       _now = now ?? DateTime.now,
       _trackMidnight = now == null;

  static const int questionXp = 10;
  static const int resourceXp = 5;
  static const int routeQuizXp = 10;

  static Future<LocalStorePersistence> _onDevice() =>
      EncryptedLocalStore.onDevice(
        fileName: 'setu_learning_progress.enc',
        keyName: 'setu.learning.master.v1',
      );

  final Future<LocalStorePersistence> Function() _openStore;
  final DateTime Function() _now;
  final bool _trackMidnight;
  LocalStorePersistence? _store;
  Future<void>? _opening;
  Future<void> _writes = Future<void>.value();
  Set<DateTime> _activeDays = <DateTime>{};
  Set<DateTime> _questionDays = <DateTime>{};
  Set<String> _resources = <String>{};
  Set<String> _routes = <String>{};
  bool _loadFailed = false;
  bool _disposed = false;
  Timer? _midnight;

  bool get ready => _store != null;
  bool get loadFailed => _loadFailed;
  DateTime get today => calendarDay(_now());
  int get xp =>
      _questionDays.length * questionXp +
      _resources.length * resourceXp +
      _routes.length * routeQuizXp;

  /// Cada nivel pide la misma cantidad de XP: una escala fácil de leer.
  static const int xpPerLevel = 50;
  static const List<String> levelTitles = <String>[
    'Curioso',
    'Explorador',
    'Constructor',
    'Guía',
    'Referente',
  ];

  int get level => xp ~/ xpPerLevel + 1;

  /// XP acumulados dentro del nivel actual.
  int get levelXp => xp % xpPerLevel;
  String get levelTitle =>
      levelTitles[level > levelTitles.length
          ? levelTitles.length - 1
          : level - 1];

  /// Preguntas respondidas y lecturas completadas.
  int get completedCount =>
      _questionDays.length + _resources.length + _routes.length;

  /// Racha más larga registrada en este teléfono.
  int get bestStreak {
    final List<DateTime> days = _activeDays.toList()..sort();
    int best = 0;
    int run = 0;
    DateTime? previous;
    for (final DateTime day in days) {
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  bool get answeredToday => _questionDays.contains(today);
  bool isActive(DateTime day) => _activeDays.contains(calendarDay(day));
  bool completedResource(String id) => _resources.contains(id);
  bool completedRoute(String id) => _routes.contains(id);
  bool canCompleteResource(String id) =>
      ready && (!completedResource(id) || !isActive(today));

  int get streak {
    DateTime day = today;
    const Duration oneDay = Duration(days: 1);
    if (!isActive(day)) day = day.subtract(oneDay);
    int days = 0;
    while (isActive(day)) {
      days++;
      day = day.subtract(oneDay);
    }
    return days;
  }

  Future<void> open() => ready ? Future<void>.value() : _opening ??= _load();

  Future<void> _load() async {
    _loadFailed = false;
    try {
      final LocalStorePersistence store =
          await Future<LocalStorePersistence>.sync(_openStore);
      final Map<String, Object?>? data = await store.load();
      if (data != null) {
        if (data['version'] != 1) {
          throw const FormatException('Versión de progreso no soportada');
        }
        final Set<DateTime> active = _readDays(data['activeDays']);
        final Set<DateTime> questions = _readDays(data['questionDays']);
        final Set<String> resources = Set<String>.from(
          data['resources'] as List<Object?>,
        );
        if (!active.containsAll(questions)) {
          throw const FormatException('Progreso inválido');
        }
        _activeDays = active;
        _questionDays = questions;
        _resources = resources;
        _routes = Set<String>.from(
          (data['routes'] as List<Object?>?) ?? const <Object?>[],
        );
      }
      _store = store;
    } on Object {
      _loadFailed = true;
    } finally {
      _opening = null;
      refreshDay();
    }
  }

  static Set<DateTime> _readDays(Object? value) =>
      (value as List<Object?>).cast<String>().map((String key) {
        final DateTime day = DateTime.parse('${key}T00:00:00Z');
        if (_dateKey(day) != key) throw const FormatException('Fecha inválida');
        return day;
      }).toSet();

  static String _dateKey(DateTime day) =>
      day.toIso8601String().substring(0, 10);

  Future<int> completeResource(String id) => _record(today, resource: id);

  Future<int> completeQuestion(DateTime questionDay) =>
      questionDay == today ? _record(questionDay) : Future<int>.value(0);

  /// Cierre de ruta: +10 XP una sola vez por ruta, separado de la pregunta diaria.
  Future<int> completeRoute(String id) => _record(today, route: id);

  Future<int> _record(DateTime day, {String? resource, String? route}) {
    final Future<int> result = _writes.then((_) async {
      final LocalStorePersistence? store = _store;
      if (store == null) throw StateError('Progreso no disponible');
      final Set<DateTime> active = <DateTime>{..._activeDays};
      final Set<DateTime> questions = <DateTime>{..._questionDays};
      final Set<String> resources = <String>{..._resources};
      final Set<String> routes = <String>{..._routes};
      final bool firstActivity = active.add(day);
      final bool firstCompletion = route != null
          ? routes.add(route)
          : resource == null
          ? questions.add(day)
          : resources.add(resource);
      if (!firstActivity && !firstCompletion) return 0;
      await store.save(<String, Object?>{
        'version': 1,
        'activeDays': active.map(_dateKey).toList(),
        'questionDays': questions.map(_dateKey).toList(),
        'resources': resources.toList(),
        'routes': routes.toList(),
      });
      _activeDays = active;
      _questionDays = questions;
      _resources = resources;
      _routes = routes;
      refreshDay();
      if (!firstCompletion) return 0;
      if (route != null) return routeQuizXp;
      return resource == null ? questionXp : resourceXp;
    });
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  void refreshDay() {
    if (_disposed) return;
    if (ready && _trackMidnight) {
      _midnight?.cancel();
      final DateTime now = _now();
      final DateTime nextDay = DateTime(now.year, now.month, now.day + 1);
      _midnight = Timer(nextDay.difference(now), refreshDay);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _midnight?.cancel();
    super.dispose();
  }
}
