/// Pre-write checkpoint: nothing is saved to Bunko until this screen's commit
/// action (features/commit-screen.html; capture-loop.md §2 step 4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capture_providers.dart';
import '../commit_service.dart';
import 'done_screen.dart';

class CommitScreen extends ConsumerWidget {
  const CommitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureQueueProvider);
    final notifier = ref.read(captureQueueProvider.notifier);
    final draft = state.draft!;
    final preview = previewCommit(draft, state.skippedRefs);
    final totalToCommit = preview.newWordCount + preview.mergedCount + preview.newTemplateCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Queue complete')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ready to commit', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Nothing is saved to your Bunko until you commit.'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Stat(label: 'Approved', value: totalToCommit, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(label: 'Skipped', value: preview.skipped.length, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Will be written to your Bunko', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            _Row(label: 'New words', value: preview.newWordCount),
            _Row(label: 'Merged into existing', value: preview.mergedCount),
            if (preview.kanjiUpgradedCount > 0)
              _Row(label: 'Kanji added to existing words', value: preview.kanjiUpgradedCount),
            _Row(label: 'New templates', value: preview.newTemplateCount),
            if (preview.skipped.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('${preview.skipped.length} item(s) skipped won\'t be saved')),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Review')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await notifier.commit();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DoneScreen()),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: Text('Commit $totalToCommit items'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value'),
        ],
      ),
    );
  }
}
