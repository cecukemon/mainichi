/// Dedup-merge card: new item vs. existing Bunko entry, stacked for
/// comparison (features/review-queue-dedup-merge.html; capture-loop.md §2/3).
library;

import 'package:flutter/material.dart';

import '../models.dart';

class DedupReviewCard extends StatelessWidget {
  const DedupReviewCard({
    super.key,
    required this.item,
    required this.onMerge,
    required this.onNotAMatch,
    required this.onSkip,
  });

  final VocabDraftItem item;
  final VoidCallback onMerge;
  final VoidCallback onNotAMatch;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final match = item.existingMatch!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: const Text('Possible match in your Bunko'),
            backgroundColor: Colors.purple.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),
          Text('New from this worksheet', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.kanji.isNotEmpty ? '${item.kanji}  ${item.kana}' : item.kana,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(item.meaning, style: Theme.of(context).textTheme.bodyMedium),
                if (item.newExampleSentence != null) ...[
                  const SizedBox(height: 8),
                  Text('New example sentence', style: Theme.of(context).textTheme.bodySmall),
                  Text(item.newExampleSentence!),
                ],
              ],
            ),
          ),
          const Center(child: Icon(Icons.arrow_downward, size: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Already in your Bunko', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${match.kanji}  ${match.kana}', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Text(match.meaning ?? '', style: Theme.of(context).textTheme.bodyMedium),
                if (match.exampleSentences.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${match.exampleSentences.length} existing example sentence${match.exampleSentences.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(match.exampleSentences.first),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onSkip, child: const Text('Skip'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: onNotAMatch, child: const Text('Not a match'))),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMerge,
                  icon: const Icon(Icons.merge_type),
                  label: const Text('Merge'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
