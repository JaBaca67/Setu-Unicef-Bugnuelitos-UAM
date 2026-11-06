import 'dart:convert';
import '../local/credential_hasher.dart';
import '../local/encrypted_local_store.dart';
import '../local/local_cureando_gateway.dart';

/// Fast, deterministic persistence boundary for widget tests only.
/// The real app never constructs this adapter.
class MockCureandoGateway extends LocalCureandoGateway {
  MockCureandoGateway()
    : super(
        persistence: MemoryTestStore(),
        hasher: CredentialHasher(iterations: 1000),
      );
}

class MemoryTestStore implements LocalStorePersistence {
  Map<String, Object?>? _state;
  @override
  Future<Map<String, Object?>?> load() async => _state == null
      ? null
      : jsonDecode(jsonEncode(_state)) as Map<String, Object?>;
  @override
  Future<void> save(Map<String, Object?> value) async {
    _state = jsonDecode(jsonEncode(value)) as Map<String, Object?>;
  }
}
