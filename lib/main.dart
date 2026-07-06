import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capture/capture_providers.dart';
import 'capture/screens/triage_screen.dart';
import 'data/connection.dart';
import 'data/database.dart';

void main() {
  final database = AppDatabase(connectDb());
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('mainichi')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TriageScreen()),
          ),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('New import'),
        ),
      ),
    );
  }
}
