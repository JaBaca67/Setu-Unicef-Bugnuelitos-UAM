import 'dart:io';

import 'package:cureando_mobile/features/home/learning_progress.dart';
import 'package:cureando_mobile/shared/local/encrypted_local_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fecha civil, escrituras repetidas y reapertura cifrada', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'setu-learning-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final File file = File('${directory.path}/progress.enc');
    final _MemoryVault vault = _MemoryVault();
    final EncryptedLocalStore storage = EncryptedLocalStore(
      file: file,
      vault: vault,
    );
    DateTime now = DateTime(2026, 12, 31, 23, 59);
    LearningProgress progress = LearningProgress(
      openStore: () async => storage,
      now: () => now,
    );
    await progress.open();
    expect(progress.streak, 0);
    expect(progress.xp, 0);

    final DateTime first = progress.today;
    expect(
      await Future.wait(<Future<int>>[
        progress.completeQuestion(first),
        progress.completeQuestion(first),
        progress.completeResource('emociones'),
        progress.completeResource('emociones'),
      ]),
      <int>[10, 0, 5, 0],
    );
    expect(progress.streak, 1);
    expect(progress.xp, 15);
    expect(await file.readAsString(), isNot(contains('emociones')));
    progress.dispose();

    now = DateTime(2027, 1, 1, 8);
    progress = LearningProgress(
      openStore: () async => EncryptedLocalStore(file: file, vault: vault),
      now: () => now,
    );
    addTearDown(progress.dispose);
    await progress.open();
    expect(progress.streak, 1);
    expect(progress.answeredToday, isFalse);
    expect(await progress.completeQuestion(first), 0);
    expect(await progress.completeResource('emociones'), 0);
    expect(progress.streak, 2);
    expect(progress.xp, 15);
    expect(progress.isActive(DateTime(2026, 12, 31)), isTrue);
    now = DateTime(2027, 1, 3, 0, 1);
    progress.refreshDay();
    expect(progress.streak, 0);
    expect(progress.xp, 15);
    expect(progress.isActive(DateTime(2027, 1, 1)), isTrue);
  });

  test('un error de guardado no concede XP y permite reintentar', () async {
    final _RetryStore storage = _RetryStore();
    final LearningProgress progress = LearningProgress(
      openStore: () async => storage,
      now: () => DateTime(2026, 11, 12),
    );
    addTearDown(progress.dispose);
    await progress.open();
    await expectLater(
      progress.completeQuestion(progress.today),
      throwsStateError,
    );
    expect(progress.xp, 0);
    expect(progress.streak, 0);
    expect(await progress.completeQuestion(progress.today), 10);
    expect(progress.streak, 1);
  });

  test(
    'almacén v1 antiguo conserva XP y el cierre es único incluso al reabrir',
    () async {
      final Directory qaRoot = await Directory('build').create(recursive: true);
      final Directory directory = await qaRoot.createTemp('setu-route-');
      addTearDown(() => directory.delete(recursive: true));
      final File file = File('${directory.path}/progress.enc');
      final _MemoryVault vault = _MemoryVault();
      final EncryptedLocalStore storage = EncryptedLocalStore(
        file: file,
        vault: vault,
      );
      await storage.save(<String, Object?>{
        'version': 1,
        'activeDays': <String>['2026-11-12'],
        'questionDays': <String>['2026-11-12'],
        'resources': <String>['emociones', 'convivencia'],
      });
      DateTime now = DateTime(2026, 11, 12);
      LearningProgress progress = LearningProgress(
        openStore: () async => storage,
        now: () => now,
      );
      await progress.open();
      expect(progress.ready, isTrue);
      expect(progress.xp, 20);
      expect(progress.completedResource('emociones'), isTrue);
      expect(
        await Future.wait(<Future<int>>[
          progress.completeRoute('acoso'),
          progress.completeRoute('acoso'),
        ]),
        <int>[10, 0],
      );
      expect(progress.xp, 30);
      expect(progress.answeredToday, isTrue);
      expect(await file.readAsString(), isNot(contains('acoso')));
      progress.dispose();
      now = DateTime(2026, 11, 13);
      progress = LearningProgress(
        openStore: () async => EncryptedLocalStore(file: file, vault: vault),
        now: () => now,
      );
      addTearDown(progress.dispose);
      await progress.open();
      expect(progress.completedRoute('acoso'), isTrue);
      expect(progress.answeredToday, isFalse);
      expect(await progress.completeRoute('acoso'), 0);
      expect(await progress.completeQuestion(progress.today), 10);
      expect(await progress.completeResource('emociones'), 0);
      expect(progress.xp, 40);
    },
  );

  test(
    'cierre de ruta con error de escritura permite reintentar sin duplicar XP',
    () async {
      final _RetryStore storage = _RetryStore();
      final LearningProgress progress = LearningProgress(
        openStore: () async => storage,
        now: () => DateTime(2026, 11, 12),
      );
      addTearDown(progress.dispose);
      await progress.open();
      await expectLater(progress.completeRoute('acoso'), throwsStateError);
      expect(progress.completedRoute('acoso'), isFalse);
      expect(progress.xp, 0);
      expect(await progress.completeRoute('acoso'), 10);
      expect(await progress.completeRoute('acoso'), 0);
      expect(progress.answeredToday, isFalse);
    },
  );
}

class _MemoryVault implements KeyVault {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String encodedKey) async => _value = encodedKey;
}

class _RetryStore implements LocalStorePersistence {
  bool _failed = false;

  @override
  Future<Map<String, Object?>?> load() async => null;

  @override
  Future<void> save(Map<String, Object?> value) async {
    if (_failed) return;
    _failed = true;
    throw StateError('Error de escritura');
  }
}
