/// Storage for the user's Anthropic API key (project-status.md Bugs: "iOS API
/// key delivery is unaddressed" — the CLI tools read `~/.config/anthropic/key`,
/// which doesn't exist on a phone).
///
/// Kept behind an interface, same pattern as the DB connection and the
/// extraction/generation HTTP calls, so the real Keychain-backed
/// implementation can be swapped for a fake in tests.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ApiKeyStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> clear();
}

/// Thrown by any live API service when no key is configured — distinct from a
/// model refusal or a transport error, so the UI can point the user at
/// Settings specifically rather than showing a generic failure.
class ApiKeyMissing implements Exception {
  ApiKeyMissing([this.service = 'Anthropic']);

  final String service;

  @override
  String toString() => 'ApiKeyMissing: no $service API key configured';
}

/// Keychain-backed on iOS (Keystore on Android, for parity — this app is
/// iOS-only per CLAUDE.md, but `flutter_secure_storage` requires no extra
/// setup to also work there). `first_unlock` accessibility keeps the key
/// readable for background work after the device has been unlocked once,
/// without requiring it to stay unlocked.
///
/// One instance per credential slot: [SecureApiKeyStore.anthropic] for the
/// Claude calls, [SecureApiKeyStore.google] for Cloud TTS (and later STT).
class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore.anthropic() : _storageKey = 'anthropic_api_key';
  SecureApiKeyStore.google() : _storageKey = 'google_api_key';

  final String _storageKey;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  @override
  Future<String?> read() => _storage.read(key: _storageKey);

  @override
  Future<void> write(String key) =>
      _storage.write(key: _storageKey, value: key);

  @override
  Future<void> clear() => _storage.delete(key: _storageKey);
}
