import 'package:mainichi/settings/api_key_store.dart';

/// In-memory [ApiKeyStore] for tests — the real one needs the Keychain
/// platform channel, which isn't available under `flutter test`.
class FakeApiKeyStore implements ApiKeyStore {
  FakeApiKeyStore([this._value]);

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String key) async => _value = key;

  @override
  Future<void> clear() async => _value = null;
}
