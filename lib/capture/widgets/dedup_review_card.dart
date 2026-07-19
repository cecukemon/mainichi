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
                Text(
                  match.kanji.isNotEmpty ? '${match.kanji}  ${match.kana}' : match.kana,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(match.meaning ?? '', style: Theme.of(context).textTheme.bodyMedium),
                if (match.exampleSentences.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${match.exampleSentences.length} existing example sentence${match.exampleSentences.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final sentence in match.exampleSentences) Text(sentence),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _MatchSummary(item: item, match: match),
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

/// Field-by-field comparison between the new and existing entries — the
/// false-match guard the spec calls for (capture-loop.md §3): kana alone
/// isn't proof of a match, so this makes the actual per-field agreement
/// visible rather than implying the merge is automatically safe.
class _MatchSummary extends StatelessWidget {
  const _MatchSummary({required this.item, required this.match});

  final VocabDraftItem item;
  final ExistingWordMatch match;

  @override
  Widget build(BuildContext context) {
    final readingMatches = item.kana == match.kana;
    final meaningMatches = item.meaning.trim().toLowerCase() == (match.meaning ?? '').trim().toLowerCase();
    final roleMatches = item.role == match.role;
    final allMatch = readingMatches && meaningMatches && roleMatches;

    final color = allMatch ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(allMatch ? Icons.check_circle : Icons.info_outline, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                allMatch ? 'Reading, meaning & role all match' : 'Some fields differ — check before merging',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FieldRow(label: 'Reading', left: item.kana, right: match.kana, matches: readingMatches, color: color),
          _FieldRow(label: 'Meaning', left: item.meaning, right: match.meaning ?? '', matches: meaningMatches, color: color),
          _FieldRow(label: 'Role', left: item.role.name, right: match.role.name, matches: roleMatches, color: color),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.left, required this.right, required this.matches, required this.color});

  final String label;
  final String left;
  final String right;
  final bool matches;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.75))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              matches ? '$left = $right' : '$left ≠ $right',
              style: TextStyle(fontSize: 12, color: color),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
