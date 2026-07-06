/// Post-commit confirmation (features/done-screen.html; capture-loop.md §2
/// step 5). Skipped items stay visible here too, revisitable — but reopening
/// a skip after commit needs its own design pass (capture-loop.md §4), so
/// "Review" here only shows the item, it doesn't restart a commit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capture_providers.dart';

class DoneScreen extends ConsumerWidget {
  const DoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(captureQueueProvider).commitResult!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.green.withValues(alpha: 0.15),
                child: const Icon(Icons.check, color: Colors.green, size: 26),
              ),
              const SizedBox(height: 16),
              Text('Added to your Bunko', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                [
                  '${result.newWordCount} new words',
                  '${result.mergedCount} merged',
                  if (result.kanjiUpgradedCount > 0)
                    '${result.kanjiUpgradedCount} kanji added',
                  '${result.newTemplateCount} new templates',
                ].join(', '),
                textAlign: TextAlign.center,
              ),
              if (result.skipped.isNotEmpty) ...[
                const SizedBox(height: 20),
                for (final item in result.skipped)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('1 item left skipped'),
                              Text(
                                '${item.label} — ${item.reason}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(item.label),
                              content: Text(item.reason),
                            ),
                          ),
                          child: const Text('Review'),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Done'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Import another worksheet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
