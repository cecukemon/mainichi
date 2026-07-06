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

void main() {
  testWidgets('shows entry form with no saved key, then the saved state after Save', (tester) async {
    final store = FakeApiKeyStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiKeyStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'API key'), findsOneWidget);
    expect(find.text('Key saved'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'API key'), 'sk-ant-mykey123');
    await _tap(tester, find.widgetWithText(FilledButton, 'Save key'));

    expect(find.text('Key saved'), findsOneWidget);
    expect(find.text('sk-a…y123'), findsOneWidget);
    expect(await store.read(), 'sk-ant-mykey123');
  });

  testWidgets('shows an error instead of saving when the field is blank', (tester) async {
    final store = FakeApiKeyStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiKeyStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.widgetWithText(FilledButton, 'Save key'));

    expect(find.text('Enter a key first.'), findsOneWidget);
    expect(await store.read(), isNull);
  });

  testWidgets('starts in the saved state and Remove clears it back to the entry form', (tester) async {
    final store = FakeApiKeyStore('sk-ant-existingkey');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiKeyStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Key saved'), findsOneWidget);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Remove key'));

    expect(find.text('Key saved'), findsNothing);
    expect(find.widgetWithText(TextField, 'API key'), findsOneWidget);
    expect(await store.read(), isNull);
  });
}
