import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/settings/settings_providers.dart';

import 'fake_api_key_store.dart';

void main() {
  test('loads no key by default', () async {
    final notifier = ApiKeyNotifier(FakeApiKeyStore());
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.hasKey, isFalse);
  });

  test('loads an existing key from the store', () async {
    final notifier = ApiKeyNotifier(FakeApiKeyStore('sk-ant-existing'));
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.hasKey, isTrue);
    expect(notifier.state.key, 'sk-ant-existing');
  });

  test('save trims whitespace and persists to the store', () async {
    final store = FakeApiKeyStore();
    final notifier = ApiKeyNotifier(store);
    await Future<void>.delayed(Duration.zero);

    await notifier.save('  sk-ant-newkey  ');

    expect(notifier.state.key, 'sk-ant-newkey');
    expect(await store.read(), 'sk-ant-newkey');
  });

  test('save ignores a blank key', () async {
    final store = FakeApiKeyStore();
    final notifier = ApiKeyNotifier(store);
    await Future<void>.delayed(Duration.zero);

    await notifier.save('   ');

    expect(notifier.state.hasKey, isFalse);
    expect(await store.read(), isNull);
  });

  test('clear removes the key from state and the store', () async {
    final store = FakeApiKeyStore('sk-ant-existing');
    final notifier = ApiKeyNotifier(store);
    await Future<void>.delayed(Duration.zero);

    await notifier.clear();

    expect(notifier.state.hasKey, isFalse);
    expect(await store.read(), isNull);
  });
}
