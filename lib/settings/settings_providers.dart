/// Riverpod wiring for the API key settings screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import 'api_key_store.dart';

/// Overridden at the app root with [SecureApiKeyStore], and in tests with an
/// in-memory fake.
final apiKeyStoreProvider = Provider<ApiKeyStore>(
  (ref) => throw UnimplementedError('apiKeyStoreProvider must be overridden'),
);

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, ApiKeyState>(
  (ref) => ApiKeyNotifier(ref.watch(apiKeyStoreProvider)),
);

@immutable
class ApiKeyState {
  const ApiKeyState({this.key, this.isLoading = true});

  /// The stored key, or null if none is set. Held in full so the settings
  /// screen can derive a masked display; never logged or shown verbatim.
  final String? key;
  final bool isLoading;

  bool get hasKey => key != null && key!.isNotEmpty;

  ApiKeyState copyWith({String? key, bool clearKey = false, bool? isLoading}) {
    return ApiKeyState(
      key: clearKey ? null : (key ?? this.key),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ApiKeyNotifier extends StateNotifier<ApiKeyState> {
  ApiKeyNotifier(this._store) : super(const ApiKeyState()) {
    _load();
  }

  final ApiKeyStore _store;

  Future<void> _load() async {
    final key = await _store.read();
    state = state.copyWith(key: key, isLoading: false);
  }

  Future<void> save(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    await _store.write(trimmed);
    state = state.copyWith(key: trimmed);
  }

  Future<void> clear() async {
    await _store.clear();
    state = state.copyWith(clearKey: true);
  }
}
