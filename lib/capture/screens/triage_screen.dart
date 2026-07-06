/// Landing screen after extraction returns (features/triage-screen.html;
/// capture-loop.md §2 step 2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capture_providers.dart';
import '../widgets/worksheet_crop_placeholder.dart';
import 'commit_screen.dart';
import 'review_queue_screen.dart';

class TriageScreen extends ConsumerWidget {
  const TriageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureQueueProvider);
    final draft = state.draft;

    return Scaffold(
      appBar: AppBar(title: const Text('New import')),
      body: draft == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WorksheetCropPlaceholder(label: 'worksheet photo', height: 118),
                  const SizedBox(height: 14),
                  Text(draft.worksheetTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(draft.worksheetTopic, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${draft.vocabulary.length} vocab · ${draft.templates.length} templates · '
                    '${draft.vocabulary.where((v) => v.isPictureDerived).length} picture words',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _CountCard(
                          label: 'High-confidence',
                          count: draft.highConfidenceCount,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CountCard(
                          label: 'Needs review',
                          count: draft.needsReviewCount + draft.dedupCandidateCount,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Needs review breakdown', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  _BreakdownRow(icon: Icons.abc, label: 'Vocabulary', count: draft.vocabReviewCount),
                  _BreakdownRow(
                    icon: Icons.image_outlined,
                    label: 'Picture words',
                    count: draft.pictureWordReviewCount,
                  ),
                  _BreakdownRow(
                    icon: Icons.short_text,
                    label: 'Templates',
                    count: draft.templateReviewCount,
                  ),
                  _BreakdownRow(
                    icon: Icons.merge_type,
                    label: 'Possible merges',
                    count: draft.dedupCandidateCount,
                  ),
                  const SizedBox(height: 24),
                  if (state.bulkApproveStaged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${draft.highConfidenceCount} high-confidence staged',
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green),
                                ),
                                Text(
                                  'not saved yet — commits with the rest',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.read(captureQueueProvider.notifier).undoBulkApprove(),
                            child: const Text('Undo'),
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => ref.read(captureQueueProvider.notifier).approveAllHighConfidence(),
                      icon: const Icon(Icons.check),
                      label: Text('Approve all high-confidence (${draft.highConfidenceCount})'),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      final needsQueue = draft.needsReviewCount + draft.dedupCandidateCount > 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => needsQueue ? const ReviewQueueScreen() : const CommitScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('Review queue (${draft.needsReviewCount + draft.dedupCandidateCount})'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9))),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.icon, required this.label, required this.count});

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text('$count', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
