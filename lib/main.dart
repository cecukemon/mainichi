import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capture/capture_providers.dart';
import 'capture/screens/photo_import_screen.dart';
import 'capture/screens/triage_screen.dart';
import 'data/connection.dart';
import 'data/database.dart';
import 'reading/screens/furigana_preview_screen.dart';
import 'settings/api_key_store.dart';
import 'settings/screens/settings_screen.dart';
import 'settings/settings_providers.dart';

void main() {
  final database = AppDatabase(connectDb());
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        apiKeyStoreProvider.overrideWithValue(SecureApiKeyStore()),
      ],
      child: const MainichiApp(),
    ),
  );
}

class MainichiApp extends StatelessWidget {
  const MainichiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mainichi',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mainichi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () {
                // Fixture demo flow (capture-loop.md §4) — TriageScreen shows
                // a spinner until this finishes loading.
                ref.read(captureQueueProvider.notifier).loadDemoFixture();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TriageScreen()),
                );
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('New import'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PhotoImportScreen()),
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('New import from photo'),
            ),
            const SizedBox(height: 12),
            // Rendering-spike preview; replaced by the real reading screen.
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FuriganaPreviewScreen()),
              ),
              icon: const Icon(Icons.translate_outlined),
              label: const Text('Furigana preview (spike)'),
            ),
          ],
        ),
      ),
    );
  }
}
