import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainichi/settings/screens/settings_screen.dart';
import 'package:mainichi/settings/settings_providers.dart';

import 'fake_api_key_store.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Widgets inside the section headed by [title] — the screen now has one
/// section per key slot (Anthropic, Google), structurally identical.
Finder _inSection(String title, Finder finder) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(Column)),
      matching: finder,
    );

const _anthropic = 'Anthropic API key';
const _google = 'Google Cloud API key';

Future<(FakeApiKeyStore, FakeApiKeyStore)> _pump(
  WidgetTester tester, {
  String? anthropicKey,
  String? googleKey,
}) async {
  final anthropicStore = FakeApiKeyStore(anthropicKey);
  final googleStore = FakeApiKeyStore(googleKey);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiKeyStoreProvider.overrideWithValue(anthropicStore),
        googleApiKeyStoreProvider.overrideWithValue(googleStore),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return (anthropicStore, googleStore);
}

void main() {
  testWidgets(
      'shows entry form with no saved key, then the saved state after Save',
      (tester) async {
    final (store, _) = await _pump(tester);

    expect(_inSection(_anthropic, find.byType(TextField)), findsOneWidget);
    expect(find.text('Key saved'), findsNothing);

    await tester.enterText(
        _inSection(_anthropic, find.byType(TextField)), 'sk-ant-mykey123');
    await _tap(tester, _inSection(_anthropic, find.text('Save key')));

    expect(find.text('Key saved'), findsOneWidget);
    expect(find.text('sk-a…y123'), findsOneWidget);
    expect(await store.read(), 'sk-ant-mykey123');
  });

  testWidgets('shows an error instead of saving when the field is blank',
      (tester) async {
    final (store, _) = await _pump(tester);

    await _tap(tester, _inSection(_anthropic, find.text('Save key')));

    expect(find.text('Enter a key first.'), findsOneWidget);
    expect(await store.read(), isNull);
  });

  testWidgets(
      'starts in the saved state and Remove clears it back to the entry form',
      (tester) async {
    final (store, _) = await _pump(tester, anthropicKey: 'sk-ant-existingkey');

    expect(find.text('Key saved'), findsOneWidget);

    await _tap(tester, _inSection(_anthropic, find.text('Remove key')));

    expect(find.text('Key saved'), findsNothing);
    expect(_inSection(_anthropic, find.byType(TextField)), findsOneWidget);
    expect(await store.read(), isNull);
  });

  testWidgets('the Google slot saves independently of the Anthropic one',
      (tester) async {
    final (anthropicStore, googleStore) =
        await _pump(tester, anthropicKey: 'sk-ant-existingkey');

    expect(find.text('Key saved'), findsOneWidget); // Anthropic only

    await tester.enterText(
        _inSection(_google, find.byType(TextField)), 'AIza-google-key');
    await _tap(tester, _inSection(_google, find.text('Save key')));

    expect(find.text('Key saved'), findsNWidgets(2));
    expect(await googleStore.read(), 'AIza-google-key');
    expect(await anthropicStore.read(), 'sk-ant-existingkey');
  });
}
